--[[
    Inventory/FluxConsumableBest/FluxConsumableBest.lua

    Public API + FluxInv listener registration.
]]

FluxConsumableBest = FluxConsumableBest or {}
local Best = FluxConsumableBest

local recomputePending = false
local pendingOpts = nil
local RECOMPUTE_DELAY = 0.3
local inventoryQueued = false
local inventoryOpts
local inventoryLastPulse = 0
local inventoryStarted = 0

-- Counts paint on the inventory pulse. Selection gets one scan after the burst,
-- with a bounded wait so continuous looting still promotes new consumables.
local function QueueInventoryScan(regions, addedItemIDs)
    if addedItemIDs and Best.MergePendingAdded then
        Best.MergePendingAdded(addedItemIDs)
    end
    local now = GetTime and GetTime() or 0
    inventoryLastPulse = now
    local bagsOnly = regions and regions.bags and not regions.bank and not regions.warband or false
    if not inventoryOpts then
        inventoryOpts = { reason = "inv", regions = regions, bagsOnly = bagsOnly, force = true, delay = 0 }
    elseif not bagsOnly then
        inventoryOpts.bagsOnly = false
        inventoryOpts.regions = regions
    end
    Best._dirty = true
    if inventoryQueued then
        return
    end
    inventoryQueued = true
    inventoryStarted = now
    local function Run()
        local time = GetTime and GetTime() or 0
        local remaining = inventoryLastPulse + 0.10 - time
        if remaining > 0.001 and time - inventoryStarted < 0.30 and C_Timer and C_Timer.After then
            C_Timer.After(math.min(remaining, 0.30 - (time - inventoryStarted)), Run)
            return
        end
        inventoryQueued = false
        local opts = inventoryOpts
        inventoryOpts = nil
        Best.RequestRecompute(opts)
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.10, Run)
    else
        Run()
    end
end

-- Must stay aligned with Scan.PENDING_ONLY_REASONS. Pending-only pulses skip the
-- unique bag walk; a login GET_ITEM_INFO storm must not rename an inv scan.
local PENDING_ONLY_REASONS = {
    classifyPendingOnly = true,
    classifyPending = true,
    classifyResume = true,
    itemData = true,
    orphanLoad = true,
}

local function ReasonIsPendingOnly(reason)
    if not reason then
        return false
    end
    local set = (Best.Scan and Best.Scan.PENDING_ONLY_REASONS) or PENDING_ONLY_REASONS
    return set[reason] == true
end

local function MergeRecomputeOpts(into, incoming)
    if not into or not incoming then
        return into or incoming
    end
    if incoming.force then
        into.force = true
    end
    if incoming.immediate then
        into.immediate = true
    end
    if incoming.regions then
        local regions = {}
        for region, enabled in pairs(into.regions or {}) do regions[region] = enabled end
        for region, enabled in pairs(incoming.regions) do regions[region] = enabled end
        into.regions = regions
    end
    if incoming.bagsOnly == false or (incoming.bagsOnly ~= nil and into.bagsOnly == nil) then
        into.bagsOnly = incoming.bagsOnly
    end
    local newReason = incoming.reason
    if not newReason then
        return into
    end
    local oldReason = into.reason
    if ReasonIsPendingOnly(newReason) and oldReason and not ReasonIsPendingOnly(oldReason) then
        return into
    end
    into.reason = newReason
    return into
end

function Best._notifyListeners()
    for key, fn in pairs(Best._listeners) do
        if type(fn) == "function" then
            pcall(fn, Best._generation, Best._runtime)
        end
    end
end

function Best.RegisterListener(key, fn)
    if type(key) ~= "string" or type(fn) ~= "function" then
        return
    end
    Best._listeners[key] = fn
end

function Best.UnregisterListener(key)
    Best._listeners[key] = nil
end

function Best.RequestRecompute(opts)
    opts = opts or {}
    if opts.addedItemIDs and Best.MergePendingAdded then
        Best.MergePendingAdded(opts.addedItemIDs)
    end
    local inv = _G.FluxInv
    if inv and inv.ShouldDeferHeavyWork and inv.ShouldDeferHeavyWork() and not opts.force then
        Best._dirty = true
        return
    end
    if inv and inv.IsAutomationQuiet and inv.IsAutomationQuiet() and not opts.force then
        Best._dirty = true
        return
    end
    -- Never sync-recompute on hot UI paths; always debounce unless force+immediate for login.
    if opts.immediate and opts.force then
        recomputePending = false
        pendingOpts = nil
        Best.Scan.Recompute(opts)
        return
    end
    Best._dirty = true
    if recomputePending then
        pendingOpts = MergeRecomputeOpts(pendingOpts, opts)
        return
    end
    recomputePending = true
    pendingOpts = opts
    local delay = opts.delay or RECOMPUTE_DELAY
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, function()
            recomputePending = false
            local run = pendingOpts or opts
            pendingOpts = nil
            Best.Scan.Recompute(run)
        end)
    else
        recomputePending = false
        pendingOpts = nil
        Best.Scan.Recompute(opts)
    end
end

function Best.GetBest(kind)
    if not Best.IsValidKind(kind) then
        return nil
    end
    if not Best.IsManaKindRelevant(kind) then
        return nil
    end
    -- Do not sync-recompute here (UI hitch). Return last runtime; schedule refresh if dirty.
    if Best._dirty then
        Best.RequestRecompute({ reason = "getBest" })
    end
    local rec = Best._runtime and Best._runtime[kind]
    if not rec then
        return nil
    end
    local out = {}
    for k, v in pairs(rec) do
        out[k] = v
    end
    return out
end

function Best.GetBestRef(kind)
    if not Best.IsValidKind(kind) then
        return nil
    end
    if not Best.IsManaKindRelevant(kind) then
        return nil
    end
    local ref = Best.Persist.GetRef(kind)
    if not ref then
        return nil
    end
    local out = {}
    for k, v in pairs(ref) do
        out[k] = v
    end
    return out
end

local function CopyRec(rec)
    if type(rec) ~= "table" then
        return nil
    end
    local out = {}
    for k, v in pairs(rec) do
        out[k] = v
    end
    return out
end

--- Ranked owned list for kind (bags). No vendor stubs.
--- opts.allowComboDrinks: water ladder also includes combo food scored on mana.
function Best.GetLadder(kind, opts)
    opts = opts or {}
    if not Best.IsValidKind(kind) then
        return {}
    end
    if not Best.IsManaKindRelevant(kind) then
        return {}
    end
    if Best._dirty then
        Best.RequestRecompute({ reason = "getLadder" })
    end
    local list
    if kind == "water" and opts.allowComboDrinks then
        list = {}
        local water = Best._ladders and Best._ladders.water or {}
        local combo = Best._laddersComboWater or {}
        for i = 1, #water do
            list[#list + 1] = water[i]
        end
        for i = 1, #combo do
            list[#list + 1] = combo[i]
        end
        local Score = Best.Score
        table.sort(list, function(a, b)
            if Score and Score.IsBetter then
                return Score.IsBetter(a, b, { preferConjured = true, allowComboDrinks = true })
            end
            return (a.effective or 0) > (b.effective or 0)
        end)
    else
        list = Best._ladders and Best._ladders[kind] or {}
    end
    local out = {}
    local api = _G.Flux and _G.Flux.Inventory
    for i = 1, #list do
        local rec = list[i]
        if rec and rec.itemID and (rec.source ~= "vendor") and (rec.source ~= "create") then
            local n = tonumber(rec.count) or 0
            if api and api.GetCount then
                n = api.GetCount(rec.itemID, { bags = true, bank = false, warband = false }) or 0
            end
            if n > 0 then
                local Score = Best.Score
                if Score and Score.IsBlockedForBest and Score.IsBlockedForBest(rec.itemID, kind) then
                    -- Skip items this character cannot use yet (level / skill).
                else
                    local copy = CopyRec(rec)
                    copy.count = n
                    out[#out + 1] = copy
                end
            end
        end
    end
    return out
end

--- Best currently owned bag item for kind (no vendor stubs).
function Best.GetBestOwned(kind, opts)
    local ladder = Best.GetLadder(kind, opts)
    for i = 1, #ladder do
        local rec = ladder[i]
        if rec and (tonumber(rec.count) or 0) > 0 then
            return rec
        end
    end
    local runtime = Best.GetBest(kind)
    if runtime and runtime.itemID and (runtime.source ~= "vendor") and (runtime.source ~= "create")
        and (tonumber(runtime.count) or 0) > 0 then
        local Score = Best.Score
        if not (Score and Score.IsBlockedForBest and Score.IsBlockedForBest(runtime.itemID, kind)) then
            return runtime
        end
    end
    return nil
end

function Best.GetAllBest()
    if Best._dirty then
        Best.RequestRecompute({ reason = "getAllBest" })
    end
    local out = {}
    for _, kind in ipairs(Best.KINDS) do
        if Best.IsManaKindRelevant(kind) then
            local rec = Best._runtime and Best._runtime[kind]
            if rec then
                local copy = {}
                for k, v in pairs(rec) do
                    copy[k] = v
                end
                out[kind] = copy
            end
        end
    end
    return out
end

function Best.FindStacks(kindOrItemID)
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    local itemID = tonumber(kindOrItemID)
    if not itemID and Best.IsValidKind(kindOrItemID) then
        local best = Best.GetBest(kindOrItemID)
        itemID = best and tonumber(best.itemID)
    end
    if not itemID then
        return {}
    end
    if api and api.Find then
        return api.Find(itemID, { bags = true, bank = false, warband = false, equipped = false })
    end
    return {}
end

local function OnInventoryPulse(info)
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    local regions = info and info.regions
    -- Mail / currency / guild: counts for those regions are not consumable identity.
    if regions and not regions.bags and not regions.bank and not regions.warband then
        return
    end
    -- Bank-only pulses while closed: ignore (live bank work is open-only).
    if regions and not regions.bags and (regions.bank or regions.warband) then
        local open = (api and api.IsBankOpen and api.IsBankOpen())
            or (_G.FluxInv and _G.FluxInv.IsBankOpen and _G.FluxInv.IsBankOpen())
        if not open then
            return
        end
    end
    local conjureArm = Best.IsConjureArmActive and Best.IsConjureArmActive()
    -- Ready after a load hold changes selection validity even with identical
    -- item IDs/counts. Keep this on the normal coalesced scan path.
    if info and info.changeKind == "countOnly" and not info.recovery and not conjureArm then
        -- Item-data/classify backlog has its own bounded resume callbacks.
        -- Ordinary stack updates must not restart those full scans or extend
        -- an already queued scan on every unrelated item change.
        local need = Best._dirty and not inventoryQueued and not recomputePending
        if not need and Best._runtime then
            for _, kind in ipairs(Best.KINDS or {}) do
                local rec = Best._runtime[kind]
                local id = rec and tonumber(rec.itemID)
                if id and (rec.source == "owned" or not rec.source) then
                    local n = 0
                    if api and api.GetCount then
                        n = api.GetCount(id, { bags = true, bank = false, warband = false }) or 0
                    end
                    if n <= 0 then
                        need = true
                        break
                    end
                end
            end
        end
        if need then
            QueueInventoryScan(regions, info and info.addedItemIDs)
        end
        return
    end
    if conjureArm then
        QueueInventoryScan(regions, info and info.addedItemIDs)
        return
    end
    if info and info.changeKind == "identityChanged" and not info.force and not info.recovery then
        local relevant = false
        -- Item class is a cached/static lookup, never a tooltip parse here.
        local IC = _G.FluxItemClass
        for id in pairs(info.addedItemIDs or {}) do
            local static = IC and IC.GetStatic and IC.GetStatic(id)
            if not static or static.classID == nil or static.classID == 0 then
                relevant = true
                break
            end
        end
        if not relevant then
            for _, rec in pairs(Best._runtime or {}) do
                if rec.itemID and info.removedItemIDs and info.removedItemIDs[rec.itemID]
                    and (rec.source == "owned" or not rec.source) then
                    relevant = true
                    break
                end
            end
        end
        if not relevant and (info.addedItemIDs or info.removedItemIDs) then
            return
        end
    end
    -- A slot move/restack changes neither ownership nor ranking. Unknown/full
    -- snapshots still scan, including recovery after a load-screen hold.
    if info and info.changedItemIDs and not next(info.changedItemIDs) and not info.force and not info.recovery and not Best._dirty then
        return
    end
    QueueInventoryScan(regions, info and info.addedItemIDs)
end

local function OnPlayerLevelUp()
    local IC = _G.FluxItemClass
    if IC and IC.InvalidateRestoreCache then
        IC.InvalidateRestoreCache()
    end
    if IC and IC.InvalidateClassification then
        IC.InvalidateClassification()
    end
    local Classify = _G.FluxConsumableClassify
    if Classify and Classify.InvalidateCache then
        Classify.InvalidateCache()
    end
    if Best.Score and Best.Score.InvalidateUsableCache then
        Best.Score.InvalidateUsableCache()
    end
    Best.RequestRecompute({ reason = "level", delay = 0.5, force = true })
end

function Best.Init()
    if Best._initialized then
        return
    end
    Best._initialized = true
    Best.Persist.GetRoot()

    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.Register then
        api.Register("FluxConsumableBest", OnInventoryPulse, {
            tier = "light",
            regions = { "bags", "bank", "warband" },
            sync = true,
        })
    elseif _G.FluxInv and _G.FluxInv.RegisterListener then
        _G.FluxInv.RegisterListener("FluxConsumableBest", OnInventoryPulse, {
            tier = "light",
            regions = { "bags", "bank", "warband" },
            sync = true,
        })
    end

    Best.VendorMemory.HookMerchantIndex()

    local sessionSawInitialPew = false
    local function IsLoginOrReloadPew(isInitialLogin, isReloadingUi)
        if isInitialLogin == true or isReloadingUi == true then
            return true
        end
        -- Classic / missing args: first PEW of the session only.
        if not sessionSawInitialPew then
            return true
        end
        return false
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_LEVEL_UP")
    f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    f:RegisterEvent("SKILL_LINES_CHANGED")
    f:RegisterEvent("UNIT_MAXHEALTH")
    f:RegisterEvent("UNIT_MAXPOWER")
    f:SetScript("OnEvent", function(_, event, arg1, arg2)
        if event == "PLAYER_LEVEL_UP" or event == "PLAYER_SPECIALIZATION_CHANGED"
            or event == "SKILL_LINES_CHANGED" then
            OnPlayerLevelUp()
            return
        end
        if event == "PLAYER_REGEN_ENABLED" then
            -- Combat caches IsUsableItem=false for food/water; Extra buttons
            -- must not keep that as "unowned" after regen.
            if Best.Score and Best.Score.InvalidateUsableCache then
                Best.Score.InvalidateUsableCache()
            end
            Best.RequestRecompute({ reason = "regen", delay = 0.05, force = true })
            return
        end
        if event == "UNIT_MAXHEALTH" or event == "UNIT_MAXPOWER" then
            if arg1 == "player" then
                Best.RequestRecompute({ reason = "pools", delay = 0.2 })
            end
            return
        end
        -- PLAYER_ENTERING_WORLD
        Best.VendorMemory.HookMerchantIndex()
        local isLogin = IsLoginOrReloadPew(arg1, arg2)
        sessionSawInitialPew = true
        if isLogin then
            if api and api.BeginLoginHold then
                api.BeginLoginHold()
            end
            -- Bag DELAYED pulse drives the first scan. Login-scan ticker
            -- retries every empty kind (food/water/pots/bandage/HS/gem).
            if Best.BeginLoginScan then
                Best.BeginLoginScan()
            end
        else
            -- Portal / zone: soft debounced refresh; arm soft-hold so buttons
            -- do not blank while bag counts flicker to 0.
            Best.ArmPortalSoftHold()
            Best.RequestRecompute({ reason = "zone", delay = 0.35 })
        end
    end)

    local function OnConjureCast(event, unit, a, b, c, d)
        if unit ~= "player" then
            if event == "player" then
                unit, a, b, c, d = event, unit, a, b, c
            else
                return
            end
        end
        local Spells = api and api.CreateSpells
        local function kindOf(spellID, spellName)
            local kind
            spellID = tonumber(spellID)
            if spellID and Spells and Spells.GetKindForSpell then
                kind = Spells.GetKindForSpell(spellID)
            end
            if (not kind or kind == "") and type(spellName) == "string" and Spells and Spells.GetKindForSpell then
                local id = spellName:match("^(%d+)$")
                if id then
                    kind = Spells.GetKindForSpell(tonumber(id))
                end
            end
            if kind == "food" or kind == "water" or kind == "refreshment" then
                return kind
            end
            if type(spellName) ~= "string" or spellName == "" then
                return nil
            end
            local function base(s)
                return s:lower():gsub("%s*%(.-%)%s*$", "")
            end
            local lower = base(spellName)
            if lower:find("conjure food", 1, true) or lower:find("conjure refreshment", 1, true) then
                return "food"
            end
            if lower:find("conjure water", 1, true) then
                return "water"
            end
            if lower:find("ritual of refreshment", 1, true) then
                return nil
            end
            if Spells and Spells.GetPreferredFoodConjureSpell then
                local foodName = Spells.GetPreferredFoodConjureSpell()
                if type(foodName) == "string" and base(foodName) == lower then
                    return "food"
                end
            end
            if Spells and Spells.GetPreferredWaterConjureSpell then
                local waterName = Spells.GetPreferredWaterConjureSpell()
                if type(waterName) == "string" and base(waterName) == lower then
                    return "water"
                end
            end
            return nil
        end
        local function spellNameFromID(spellID)
            spellID = tonumber(spellID)
            if not spellID then
                return nil
            end
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(spellID)
                if type(info) == "table" and info.name then
                    return info.name
                end
            end
            if GetSpellInfo then
                return GetSpellInfo(spellID)
            end
            return nil
        end
        local kind
        local args = { a, b, c, d }
        for i = 1, #args do
            local v = args[i]
            if type(v) == "number" then
                kind = kindOf(v, spellNameFromID(v))
            elseif type(v) == "string" then
                kind = kindOf(tonumber(v), v)
            end
            if kind == "refreshment" then
                local name = type(v) == "string" and v or spellNameFromID(v)
                if type(name) == "string" and name:lower():find("ritual", 1, true) then
                    kind = nil
                else
                    kind = "food"
                end
            end
            if kind then
                break
            end
        end
        if kind ~= "food" and kind ~= "water" then
            return
        end
        if Best.ArmConjureChase then
            Best.ArmConjureChase(kind)
        end
    end
    local conjureArmed = false
    if Flux and Flux.Events and Flux.Events.RegisterUnit then
        Best._conjureCastFrame = Flux.Events.RegisterUnit("UNIT_SPELLCAST_SUCCEEDED", "player", OnConjureCast)
        conjureArmed = Best._conjureCastFrame and true or false
    end
    if not conjureArmed then
        local castFrame = CreateFrame("Frame")
        Best._conjureCastFrame = castFrame
        pcall(function()
            castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        end)
        castFrame:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
            OnConjureCast(event, unit, castGUID, spellID)
        end)
    end
end

-- Auto-init after files load.
if C_Timer and C_Timer.After then
    C_Timer.After(0, function()
        Best.Init()
    end)
else
    Best.Init()
end

_G.FluxConsumableBest = Best
return Best
