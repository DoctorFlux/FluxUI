-- FluxRespec_Inv.lua
-- Respec gear facts from Flux.Inventory (Syndicator when loaded, else builtin).
local addonName, ns = ...
local Flux = ns.Flux

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.Inv = R.Inv or {}
local RI = R.Inv

local bankWatch = false
local lastBankOpen = nil
local respecListeners = {}

local function API()
    return Flux and Flux.Inventory
end

local function Containers()
    local api = API()
    return api and api.Containers
end

local function SkipBag(bag)
    local C = Containers()
    return C and C.SkipEquipCandidateBag and C.SkipEquipCandidateBag(bag) and true or false
end

function RI.API()
    return API()
end

function RI.IsReady()
    local api = API()
    return api and api.IsReady and api.IsReady() or false
end

function RI.IsBankOpen()
    local api = API()
    return api and api.IsBankOpen and api.IsBankOpen() or false
end

function RI.IsBankLive()
    local api = API()
    if api and api.IsBankLive then
        return api.IsBankLive() and true or false
    end
    return RI.IsBankOpen()
end

--- True when a click can pick up a bank item and equip it (at the banker).
function RI.CanTakeFromBank()
    local api = API()
    if api and api.CanTakeFromBank then
        return api.CanTakeFromBank() and true or false
    end
    return RI.IsBankLive()
end

--- Last-visit / Syndicator bank snapshot exists (counts or slot map).
function RI.HasCachedBank()
    local api = API()
    local snaps = api and api.snapshots
    if not snaps then
        return false
    end
    local function nonempty(snap)
        if type(snap) ~= "table" then
            return false
        end
        if snap.counts and next(snap.counts) then
            return true
        end
        if snap.byBag and next(snap.byBag) then
            return true
        end
        return false
    end
    return nonempty(snaps.bank) or nonempty(snaps.warband)
end

function RI.GetCachedBankCount(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return 0
    end
    local api = API()
    if not api or not api.GetCount then
        return 0
    end
    return api.GetCount(itemID, {
        bags = false,
        bank = true,
        warband = RI.HasWarband(),
        equipped = false,
    }) or 0
end

function RI.HasWarband()
    local api = API()
    return api and api.HasWarband and api.HasWarband() or false
end

function RI.GetBagIDs()
    local C = Containers()
    if C and C.GetCarriedBagIDs then
        return C.GetCarriedBagIDs()
    end
    return { 0, 1, 2, 3, 4 }
end

function RI.GetBankIDs()
    if not RI.IsBankOpen() then
        return {}
    end
    local C = Containers()
    if not C then
        return {}
    end
    local ids, seen = {}, {}
    local function append(list)
        if type(list) ~= "table" then
            return
        end
        for i = 1, #list do
            local bag = list[i]
            if bag ~= nil and not seen[bag] and not SkipBag(bag) then
                seen[bag] = true
                ids[#ids + 1] = bag
            end
        end
    end
    if C.GetCharacterBankIDs then
        append(C.GetCharacterBankIDs())
    end
    if RI.HasWarband() and C.GetWarbandBankIDs then
        append(C.GetWarbandBankIDs())
    end
    return ids
end

function RI.GetGeneration()
    local api = API()
    local bags = api and api.GetSnapshotGeneration and api.GetSnapshotGeneration("bags") or 0
    local bank = api and api.GetSnapshotGeneration and api.GetSnapshotGeneration("bank") or 0
    local warband = api and api.GetSnapshotGeneration and api.GetSnapshotGeneration("warband") or 0
    local open = RI.IsBankOpen() and 1 or 0
    return bags .. ":" .. bank .. ":" .. warband .. ":" .. open
end

function RI.GetBagGeneration()
    local api = API()
    if api and api.GetBagGeneration then
        return api.GetBagGeneration()
    end
    if api and api.GetSnapshotGeneration then
        return api.GetSnapshotGeneration("bags")
    end
    return 0
end

local function FindOpts(which)
    local bankOpen = RI.IsBankOpen()
    local canTake = RI.CanTakeFromBank()
    if which == "bags" then
        return { bags = true, bank = false, warband = false, equipped = false }
    end
    if which == "bank" then
        -- Live banker only: withdraw / equip from a flyout click.
        return {
            bags = false,
            bank = canTake,
            warband = canTake and RI.HasWarband() or false,
            equipped = false,
        }
    end
    if which == "bankCached" then
        -- Syndicator / last-visit snapshot, even while the bank is closed.
        return {
            bags = false,
            bank = true,
            warband = RI.HasWarband() or false,
            equipped = false,
        }
    end
    -- "all": bags plus bank UI that is actually shown (overlay buttons exist).
    return {
        bags = true,
        bank = bankOpen,
        warband = bankOpen and RI.HasWarband() or false,
        equipped = false,
    }
end

local function KeepLoc(loc)
    if not loc then
        return false
    end
    if loc.region == "bags" or loc.region == "bank" or loc.region == "warband" then
        if SkipBag(loc.bag) then
            return false
        end
    end
    return true
end

function RI.Find(itemID, which)
    local api = API()
    local out = {}
    itemID = tonumber(itemID)
    if not itemID or not api or not api.Find then
        return out
    end
    local locs = api.Find(itemID, FindOpts(which))
    for i = 1, #locs do
        local loc = locs[i]
        loc.itemID = loc.itemID or itemID
        if KeepLoc(loc) then
            out[#out + 1] = loc
        end
    end
    return out
end

function RI.ForEachLocation(fn, which)
    if type(fn) ~= "function" then
        return
    end
    local api = API()
    if not api or not api.ForEachLocation then
        return
    end
    api.ForEachLocation(function(loc)
        if KeepLoc(loc) then
            fn(loc)
        end
    end, FindOpts(which))
end

function RI.GetFirstFreeBagSlot()
    local api = API()
    if api and api.GetFirstFreeBagSlot then
        return api.GetFirstFreeBagSlot()
    end
    return nil, nil
end

local function SnapshotRec(bag, slot)
    local api = API()
    local snaps = api and api.snapshots
    if not snaps or bag == nil or not slot then
        return nil
    end
    local function from(region)
        local byBag = snaps[region] and snaps[region].byBag
        local slots = byBag and byBag[bag]
        return slots and slots[slot]
    end
    return from("bags") or from("bank") or from("warband")
end

function RI.GetItemID(bag, slot)
    local rec = SnapshotRec(bag, slot)
    if rec and rec.itemID then
        return rec.itemID
    end
    if Flux and Flux.Container and Flux.Container.GetItemID then
        return Flux.Container.GetItemID(bag, slot)
    end
    if R.Compat and R.Compat.GetContainerItemID then
        return R.Compat.GetContainerItemID(bag, slot)
    end
    return nil
end

function RI.GetItemLink(bag, slot)
    local rec = SnapshotRec(bag, slot)
    if rec and rec.link then
        return rec.link
    end
    if Flux and Flux.Container and Flux.Container.GetItemLink then
        return Flux.Container.GetItemLink(bag, slot)
    end
    if R.Compat and R.Compat.GetContainerItemLink then
        return R.Compat.GetContainerItemLink(bag, slot)
    end
    return nil
end

function RI.IsMerchantOpen()
    local mf = rawget(_G, "MerchantFrame")
    return mf and mf.IsShown and mf:IsShown() and true or false
end

--- Every respec listener is registered on the shared facts layer as well, so a
--- local loop here would run each of them a second time. Ask the facts layer for
--- a forced pulse instead and let it do the one fan-out.
local function FireRespec(ctx)
    local sched = Flux and Flux.Scheduler
    if not sched or not sched.Request then
        for _, fn in pairs(respecListeners) do
            if Flux and Flux.Safecall then
                Flux.Safecall(fn, ctx)
            else
                pcall(fn, ctx)
            end
        end
        return
    end
    local regions = (ctx and ctx.regions) or { bags = true }
    for _, token in ipairs({ "bags", "bank", "warband", "equip" }) do
        if regions[token] then
            sched.Request("inventory", token)
        end
    end
    if ctx == nil or ctx.force then
        sched.Request("inventory", "force")
    end
end

local function EnsureBankWatch()
    if bankWatch then
        return
    end
    bankWatch = true
    lastBankOpen = RI.IsBankOpen()
    local function ping()
        local open = RI.IsBankOpen()
        if open == lastBankOpen then
            return
        end
        lastBankOpen = open
        FireRespec({
            regions = { bank = true, warband = true },
            force = true,
        })
    end
    if Flux and Flux.Events and Flux.Events.Register then
        Flux.Events.Register("BANKFRAME_OPENED", ping)
        Flux.Events.Register("BANKFRAME_CLOSED", ping)
        Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", ping)
        Flux.Events.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", ping)
    end
end

--- opts (tier / regions / deferHeavy / sync) passes straight through to the
--- facts layer so gear-set rebuilds can be budgeted instead of inline.
function RI.Register(key, fn, opts)
    if type(key) ~= "string" or type(fn) ~= "function" then
        return
    end
    respecListeners[key] = fn
    local api = API()
    if api and api.Register then
        api.Register("FluxRespec_" .. key, fn, opts)
    end
    EnsureBankWatch()
end

function RI.Unregister(key)
    if type(key) ~= "string" then
        return
    end
    respecListeners[key] = nil
    local api = API()
    if api and api.Unregister then
        api.Unregister("FluxRespec_" .. key)
    end
end
