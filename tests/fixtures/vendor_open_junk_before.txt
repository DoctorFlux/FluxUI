--[[
    Restock/Junk/FluxJunk.lua

    Junk classification (Scrap model), rebuilt on the unified inventory core.

    Data:
      * settings.junkList[itemID] = true (junk) | false (protected) | nil
      * BASE_WHITELIST: default protection for non-gray items
      * inferiorSet[itemID]: tier-inferior / conjure-inferior consumables,
        maintained by FluxRestockTiers (pure itemID set, no scanning here)
      * ruleCache[itemID]: memoized automatic-rule verdict per rule generation
      * Manual restock targets (restockItems.targetQuantity > 0) skip auto-junk

    IsJunk(itemID) is O(1) after the first evaluation of an item: list lookups
    plus a memoized rule verdict. No bag walks, no tooltip reads (item facts
    come from FluxItemClass, cached forever).

    The global keeps the old FluxVendorJunk name so UI panels, the merchant
    button, and the options tab work unchanged.
]]

local Search = LibStub and LibStub("ItemSearch-1.3", true)

FluxJunk = FluxJunk or {}
local FJ = FluxJunk
FluxVendorJunk = FJ

local WEAPON = Enum.ItemClass.Weapon
local ARMOR = Enum.ItemClass.Armor
local CONSUMABLES = Enum.ItemClass.Consumable
local MISC = Enum.ItemClass.Miscellaneous
local COMPANION = Enum.ItemMiscellaneousSubclass.CompanionPet
local MOUNT = Enum.ItemMiscellaneousSubclass.Mount
local FISHING_POLE = Enum.ItemWeaponSubclass.Fishingpole

local POOR, UNCOMMON, RARE, EPIC = 0, 2, 3, 4

FJ.COIN_ICON = "Interface/Buttons/UI-GroupLoot-Coin-Up"

-- Default protection for non-gray items. Sellable gray items follow the gray
-- rule even when this legacy list includes them (for example Rabbit's Foot).
-- An explicit Useful mark still protects every quality.
local BASE_WHITELIST = {
    [90561] = false, [12709] = false, [2459] = false, [29532] = false, [29530] = false,
    [39878] = false, [40586] = false, [48954] = false, [48955] = false, [48956] = false,
    [48957] = false, [45688] = false, [45689] = false, [45690] = false, [45691] = false,
    [44934] = false, [44935] = false, [51560] = false, [51558] = false, [51559] = false,
    [51557] = false, [40585] = false, [43157] = false, [63206] = false, [63207] = false,
    [65274] = false, [63353] = false, [64402] = false, [64401] = false, [64400] = false,
    [63352] = false, [86143] = false, [92742] = false, [92741] = false, [92665] = false,
    [92675] = false, [92676] = false, [92677] = false, [92678] = false, [92679] = false,
    [92680] = false, [92681] = false, [92682] = false, [92683] = false, [33820] = false,
    [19969] = false, [89124] = false, [114131] = false, [114808] = false, [114129] = false,
    [114745] = false, [114128] = false, [120301] = false, [120302] = false, [114002] = false,
    [156631] = false, [24368] = false, [40772] = false, [114943] = false, [109253] = false,
    [67410] = false, [11406] = false, [11944] = false, [25402] = false, [3300] = false,
    [3670] = false, [6150] = false, [36812] = false, [62072] = false, [87216] = false,
    [6529] = false, [136377] = false, [160705] = false,
}

local listeners = {}
local visualListeners = {}

local inferiorSet = {}          -- [itemID] = true (tier/conjure inferior, owned)
local ruleCache = {}            -- [itemID] = true|false
local conjuredExemptCache = {}  -- [itemID] = true|false
local displayRuleCache = {}       -- fast overlay path (no bag walks / Search / journals)
local ruleGeneration = 0

local function Inv()
    return _G.FluxRestock and _G.FluxRestock.Inv
end

local function IC()
    return _G.FluxItemClass
end

local function GetSettings()
    return FluxRestockSettings.Get()
end

function FJ.Init()
    GetSettings()
end

function FJ.GetFilters()
    return GetSettings().junkFilters
end

function FJ.GetDisplay()
    return GetSettings().junkDisplay
end

-- ---------------------------------------------------------------------------
-- LIST STATE
-- ---------------------------------------------------------------------------

local function GetListValue(id)
    local list = GetSettings().junkList
    local v = list[id]
    if v == nil then
        v = list[tostring(id)]
    end
    return v
end

function FJ.IsExplicitUseful(id)
    id = tonumber(id)
    if not id then return false end
    return GetListValue(id) == false
end

function FJ.IsExplicitJunk(id)
    id = tonumber(id)
    if not id then return false end
    return GetListValue(id) == true
end

local function IsProtected(id, slotInfo)
    local v = GetListValue(id)
    if v == false then return true end
    if v == nil and BASE_WHITELIST[id] == false then
        local quality = slotInfo and slotInfo.quality
        local ic = IC()
        if quality == nil and ic and ic.GetQuality then quality = ic.GetQuality(id) end
        local secrets = _G.Flux and _G.Flux.Secrets
        if secrets and secrets.SafeGetNumber then
            quality = secrets.SafeGetNumber(quality, -1)
        elseif issecretvalue and issecretvalue(quality) then
            return true
        end
        return quality ~= POOR
    end
    return false
end

--- Manual restock targets are never auto-junked (rules / inferior).
--- Explicit junk marks still win in IsJunk.
local function IsManualRestockItem(id)
    id = tonumber(id)
    if not id then return false end
    local items = GetSettings().restockItems
    local entry = items and items[id]
    return type(entry) == "table" and (tonumber(entry.targetQuantity) or 0) > 0
end

function FJ.IsManualRestockItem(id)
    return IsManualRestockItem(id)
end

-- ---------------------------------------------------------------------------
-- INFERIOR SET (fed by FluxRestockTiers; pure itemID set)
-- ---------------------------------------------------------------------------

local function NotifyJunkAvailabilityChanged()
    FJ.InvalidateJunkSlotCount()
    local TiersMod = _G.FluxRestockTiers
    if TiersMod then
        if TiersMod.InvalidateTierQueryCache then
            TiersMod.InvalidateTierQueryCache()
        end
        if TiersMod.InvalidateTooltipDisplayCache then
            TiersMod.InvalidateTooltipDisplayCache()
        end
        if TiersMod.FlushTierCountRefresh then
            TiersMod.FlushTierCountRefresh()
        end
    end
    local ui = _G.FluxVendorAutoMerchantUI
    if not ui then
        return
    end
    if ui.MarkJunkStatsDirty then
        ui.MarkJunkStatsDirty()
    end
    if ui.ScheduleJunkUIRefresh then
        ui.ScheduleJunkUIRefresh(true)
    end
    -- Keep Restock need in sync when inferior marks change at the merchant.
    if MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown() then
        if ui.MarkRestockSettingsDirty then
            ui.MarkRestockSettingsDirty()
        end
        if ui.ScheduleMerchantUpdateImmediate then
            ui.ScheduleMerchantUpdateImmediate("data")
        elseif ui.ScheduleMerchantUpdate then
            ui.ScheduleMerchantUpdate("data")
        end
    end
end

--- Replace the inferior-consumable set. setTable: [itemID] = true.
--- opts.silent: skip FireListChanged / UI notify (caller paints once when ready).
function FJ.SetInferiorSet(setTable, opts)
    local changed = false
    setTable = setTable or {}
    -- Drop conjured food/water and manual restock targets — ForcePublish and
    -- stale passes must not keep them.
    local cleaned = {}
    for id in pairs(setTable) do
        local numeric = tonumber(id)
        if numeric and not FJ.IsConjuredConsumable(numeric) and not IsManualRestockItem(numeric) then
            cleaned[numeric] = true
        end
    end
    setTable = cleaned
    for id in pairs(setTable) do
        id = tonumber(id) or id
        if not inferiorSet[id] then changed = true break end
    end
    if not changed then
        for id in pairs(inferiorSet) do
            if not setTable[id] and not setTable[tostring(id)] then
                changed = true
                break
            end
        end
    end
    if not changed then
        return false
    end
    wipe(inferiorSet)
    for id in pairs(setTable) do
        inferiorSet[tonumber(id) or id] = true
    end
    FJ.InvalidateJunkTabListCache()
    if opts and opts.silent then
        -- Soft overlay refresh — no FireListChanged burst — but still nudge
        -- Sell Junk / Restock enable (pre-FluxInv silent behavior).
        local overlay = _G.FluxJunkOverlay
        if overlay and overlay.RepaintInferiorVisuals then
            local visible = true
            if overlay.ArePaintTargetsVisible then
                local ok, result = pcall(overlay.ArePaintTargetsVisible)
                visible = ok and result
            end
            if visible then
                pcall(overlay.RepaintInferiorVisuals)
            end
        end
        NotifyJunkAvailabilityChanged()
        return true
    end
    FJ.FireListChanged()
    NotifyJunkAvailabilityChanged()
    return true
end

function FJ.IsUpgradeInferior(itemID)
    itemID = tonumber(itemID)
    return itemID ~= nil and inferiorSet[itemID] == true
end

function FJ.MarkUpgradeInferior(itemID)
    itemID = tonumber(itemID)
    if not itemID or inferiorSet[itemID] then
        return false
    end
    if FJ.IsConjuredConsumable(itemID) or IsManualRestockItem(itemID) then
        return false
    end
    inferiorSet[itemID] = true
    local overlay = _G.FluxJunkOverlay
    if overlay and overlay.ArePaintTargetsVisible and overlay.ArePaintTargetsVisible() then
        if overlay.ScheduleInferiorRepaintBurst then
            overlay.ScheduleInferiorRepaintBurst()
        elseif overlay.RepaintInferiorVisuals then
            overlay.RepaintInferiorVisuals()
        end
    end
    -- Merchant open: keep Sell Junk reactive without FireListChanged.
    if MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown() then
        NotifyJunkAvailabilityChanged()
    end
    return true
end

function FJ.HasUpgradeInferiorEntries()
    return next(inferiorSet) ~= nil
end

--- True when at least one upgrade-inferior mark is actually in bags (sellable).
--- O(|inferiorSet|) with O(1) bag-count lookups — not a full bag walk.
function FJ.AnyUpgradeInferiorInBags()
    if not next(inferiorSet) then
        return false
    end
    local inv = Inv()
    local bags = inv and inv.Bags
    for id in pairs(inferiorSet) do
        id = tonumber(id)
        if id and not IsProtected(id) and not IsManualRestockItem(id) then
            if bags and bags.GetCount and bags.GetCount(id) > 0 then
                return true
            elseif (not bags or not bags.GetCount) and C_Item and C_Item.GetItemCount then
                if (C_Item.GetItemCount(id, false) or 0) > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function FJ.ForEachUpgradeInferiorItemID(callback)
    if type(callback) ~= "function" then return end
    for id in pairs(inferiorSet) do
        callback(id)
    end
end

function FJ.UnmarkUpgradeInferior(itemID)
    itemID = tonumber(itemID)
    if itemID and inferiorSet[itemID] then
        inferiorSet[itemID] = nil
        FJ.NotifyVisualRefresh(itemID)
        NotifyJunkAvailabilityChanged()
    end
end

function FJ.ClearUpgradeInferiorList()
    if next(inferiorSet) then
        wipe(inferiorSet)
        FJ.FireListChanged()
    end
end

-- ---------------------------------------------------------------------------
-- AUTOMATIC RULES (memoized per itemID per rule generation)
-- ---------------------------------------------------------------------------

function FJ.InvalidateRules()
    ruleGeneration = ruleGeneration + 1
    wipe(ruleCache)
    wipe(displayRuleCache)
    wipe(conjuredExemptCache)
    FJ.InvalidateJunkTabListCache()
end

function FJ.InvalidateItemRules(itemID)
    itemID = tonumber(itemID)
    if not itemID then return end
    ruleCache[itemID] = nil
    displayRuleCache[itemID] = nil
    conjuredExemptCache[itemID] = nil
end

--- Called when async item data arrives; refreshes overlay for one item only.
function FJ.OnItemDataLoaded(itemID)
    itemID = tonumber(itemID)
    if not itemID then return end
    FJ.InvalidateItemRules(itemID)
    FJ.InvalidateJunkSlotCount()
    FJ.InvalidateJunkTabListCache()
    FJ.NotifyVisualRefresh(itemID)
end

local function IsQuestItem(id)
    if C_Item and C_Item.IsQuestItem then
        local ok, result = pcall(C_Item.IsQuestItem, id)
        return ok and result or false
    end
    return false
end

local function GetItemLocation(id)
    local inv = Inv()
    if not inv or not ItemLocation then return nil end
    local bag, slot = inv.FindFirstBagSlot(id)
    if bag == nil or slot == nil then return nil end
    local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if C_Item and C_Item.DoesItemExist and C_Item.DoesItemExist(location) then
        return location
    end
    return nil
end

local function IsOwnedMount(id)
    if not (C_MountJournal and C_MountJournal.GetMountFromItem) then
        return false
    end
    local mount = C_MountJournal.GetMountFromItem(id)
    return mount and select(11, C_MountJournal.GetMountInfoByID(mount)) or false
end

local function IsOwnedCompanion(id)
    if not (C_PetJournal and C_PetJournal.GetPetInfoByItemID) then
        return false
    end
    local species = select(13, C_PetJournal.GetPetInfoByItemID(id))
    if species and C_PetJournal.GetNumCollectedInfo then
        local numCollected, limit = C_PetJournal.GetNumCollectedInfo(species)
        return numCollected == limit
    end
    return false
end

local function IsUncollectedAppearance(id, link)
    if not (link and Search and Search.IsUncollected) then
        return false
    end
    local ok, result = pcall(Search.IsUncollected, Search, id, link)
    return ok and result == true
end

--- Conjured food/water (and other conjured consumables) are often poor quality with a
--- vendor price — never treat them as automatic gray/consumable junk.
local function IsConjuredConsumableExempt(id, info)
    id = tonumber(id)
    if not id then
        return false
    end
    local cached = conjuredExemptCache[id]
    if cached ~= nil then
        return cached
    end

    local function finish(result)
        conjuredExemptCache[id] = result and true or false
        return conjuredExemptCache[id]
    end

    local classID = info and info.classID
    if classID ~= nil and classID ~= CONSUMABLES then
        return finish(false)
    end

    local ic = IC()
    local name = (info and info.name)
        or (ic and ic.GetName and ic.GetName(id))
        or ""
    if type(name) == "string" and name:lower():find("conjured", 1, true) then
        return finish(true)
    end

    local Classify = _G.FluxConsumableClassify
    if Classify and Classify.Classify then
        local cls = Classify.Classify(id)
        if cls and cls.isConjured then
            return finish(true)
        end
    end

    if ic and ic.GetRestore then
        local restore = ic.GetRestore(id)
        -- Accept conjured even when ready=false (partial parse already saw the flag).
        if restore and restore.conjured then
            return finish(true)
        end
    end

    if ic and ic.GetTooltipText then
        local text = ic.GetTooltipText(id)
        if type(text) == "string" and text ~= "" then
            local lower = text:lower()
            if lower:find("conjured", 1, true) then
                return finish(true)
            end
            local glob = _G.ITEM_CONJURED
            if type(glob) == "string" and glob ~= "" and lower:find(glob:lower(), 1, true) then
                return finish(true)
            end
        end
    end

    return finish(false)
end

--- Public: true when this consumable is conjured food/water/etc. (never auto-junk).
function FJ.IsConjuredConsumable(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        return false
    end
    local ic = IC()
    return IsConjuredConsumableExempt(itemID, ic and ic.GetInfo(itemID) or nil)
end

function FJ.IsLowConsumable(level)
    level = tonumber(level) or 0
    if level <= 1 then
        return false
    end
    local threshold = FJ.GetFilters().consumableLvl or 0.15
    return level < (UnitLevel("player") * threshold)
end

-- Automatic verdict from item facts alone (no lists). Returns true/false, plus
-- `unstable` when item data was not loaded (verdict not cached).
local function EvaluateRules(id)
    local ic = IC()
    if not ic then return false, true end

    local info = ic.GetInfo(id)
    if not info then
        return false, true -- not loaded; retry on a later query
    end
    if IsQuestItem(id) then
        return false
    end

    local filters = FJ.GetFilters()
    local quality = info.quality
    local classID = info.classID
    local subClassID = info.subClassID
    local equipLoc = info.equipLoc
    local sellPrice = info.sellPrice or 0
    local valuable = sellPrice > 0

    if quality == POOR then
        -- Sellable gray gear is junk at every level and bind type, matching
        -- the vendor coin and sell queue. Lists/restock/gear-set protections
        -- are checked by the callers before any sale.
        return valuable and not IsConjuredConsumableExempt(id, info)
    end

    if (classID == ARMOR or classID == WEAPON) and valuable
        and equipLoc ~= "INVTYPE_TABARD" and equipLoc ~= "INVTYPE_BODY"
        and subClassID ~= FISHING_POLE then
        if quality and quality >= UNCOMMON and quality <= EPIC and filters.unusable and Search then
            local location = GetItemLocation(id)
            local bound = location and C_Item and C_Item.IsBound and C_Item.IsBound(location)
            if bound then
                if IsUncollectedAppearance(id, info.link) then
                    return false
                end
                local equippable = ic.IsEquippable(id)
                local inSet = Search.BelongsToSet and Search:BelongsToSet(id)
                if equippable and not inSet then
                    local ok, unusable = pcall(Search.IsUnusable, Search, id)
                    if ok and unusable then
                        return true
                    end
                end
            end
        end
        return false
    end

    if classID == CONSUMABLES then
        if IsConjuredConsumableExempt(id, info) then
            return false
        end
        return valuable and filters.consumable ~= false and (quality or 1) < RARE
            and FJ.IsLowConsumable(info.itemLevel)
    end

    if classID == MISC then
        local location = GetItemLocation(id)
        local bound = location and C_Item and C_Item.IsBound and C_Item.IsBound(location)
        if bound then
            if subClassID == MOUNT then
                return IsOwnedMount(id)
            elseif subClassID == COMPANION then
                return IsOwnedCompanion(id)
            elseif C_ToyBox and C_ToyBox.GetToyInfo and C_ToyBox.GetToyInfo(id) then
                return PlayerHasToy and PlayerHasToy(id) or false
            end
        end
    end

    return false
end

--- Lightweight rule check for bag-slot overlays (no bag walks, Search, or journal APIs).
--- Second return is `unstable` when item data is not loaded (do not cache).
local function EvaluateRulesForDisplay(id)
    local ic = IC()
    if not ic then return false, true end
    local info = ic.GetInfo(id)
    if not info then
        return false, true
    end
    if IsQuestItem(id) then
        return false
    end

    local filters = FJ.GetFilters()
    local quality = info.quality
    local classID = info.classID
    local sellPrice = info.sellPrice or 0
    local valuable = sellPrice > 0

    if quality == POOR then
        return valuable and not IsConjuredConsumableExempt(id, info)
    end

    if classID == CONSUMABLES then
        if IsConjuredConsumableExempt(id, info) then
            return false
        end
        return valuable and filters.consumable ~= false and (quality or 1) < RARE
            and FJ.IsLowConsumable(info.itemLevel)
    end

    return false
end

local function DisplayRuleVerdict(id)
    local cached = displayRuleCache[id]
    if cached ~= nil then
        return cached
    end
    local verdict, unstable = EvaluateRulesForDisplay(id)
    if not unstable then
        displayRuleCache[id] = verdict and true or false
    end
    return verdict and true or false
end

local function RuleVerdict(id)
    local cached = ruleCache[id]
    if cached ~= nil then
        return cached
    end
    local verdict, unstable = EvaluateRules(id)
    if not unstable then
        ruleCache[id] = verdict and true or false
    end
    return verdict and true or false
end

function FJ.IsFiltered(id)
    id = tonumber(id)
    if not id then return false end
    return RuleVerdict(id)
end

-- ---------------------------------------------------------------------------
-- THE JUNK CHECK
-- ---------------------------------------------------------------------------

function FJ.IsJunk(id, slotInfo)
    id = tonumber(id)
    if not id then return false end
    if IsProtected(id, slotInfo) then
        return false
    end
    -- Explicit user junk still wins; never auto-junk conjured food/water
    -- or manual restock targets.
    if GetListValue(id) == true then
        return true
    end
    if FJ.IsConjuredConsumable(id) or IsManualRestockItem(id) then
        if inferiorSet[id] then
            inferiorSet[id] = nil
        end
        return false
    end
    if inferiorSet[id] then
        return true
    end
    return RuleVerdict(id) or FJ.IsBlizzardVendorJunk(id, slotInfo)
end

function FJ.IsJunkForDisplay(id, slotInfo)
    id = tonumber(id)
    if not id then return false end
    if IsProtected(id, slotInfo) then
        return false
    end
    if GetListValue(id) == true then
        return true
    end
    if FJ.IsConjuredConsumable(id) or IsManualRestockItem(id) then
        if inferiorSet[id] then
            inferiorSet[id] = nil
        end
        return false
    end
    if inferiorSet[id] then
        return true
    end
    if DisplayRuleVerdict(id) then
        return true
    end
    -- Live slot metadata can identify gray junk before item data is cached.
    return FJ.IsBlizzardVendorJunk(id, slotInfo)
end

FJ.IsJunkFast = FJ.IsJunk
FJ.IsJunkFastVisual = FJ.IsJunkForDisplay

local function SecretNumber(value, fallback)
    local n = tonumber(value)
    if n ~= nil then
        return n
    end
    local Secrets = _G.Flux and _G.Flux.Secrets
    if Secrets and Secrets.SafeGetNumber then
        n = Secrets.SafeGetNumber(value, fallback)
        if n ~= nil then
            return n
        end
    end
    return fallback
end

local function SlotHasNoValue(slotInfo)
    if not slotInfo then
        return nil
    end
    local raw = slotInfo.noValue
    if raw == nil then
        raw = slotInfo.hasNoValue
    end
    if raw == true then
        return true
    end
    if raw == false then
        return false
    end
    local Secrets = _G.Flux and _G.Flux.Secrets
    if raw ~= nil and Secrets and Secrets.SafeBooleanTest then
        return Secrets.SafeBooleanTest(raw, false) == true
    end
    return nil
end

--- Poor quality with a vendor price. Explicit "useful", restock targets,
--- quest items and conjured consumables remain protected from automatic sales.
function FJ.IsBlizzardVendorJunk(itemID, slotInfo)
    itemID = SecretNumber(itemID, 0)
    if not itemID or itemID <= 0 or IsProtected(itemID, slotInfo) then
        return false
    end
    if IsQuestItem(itemID) then return false end
    if GetListValue(itemID) ~= true and (IsManualRestockItem(itemID) or FJ.IsConjuredConsumable(itemID)) then
        return false
    end
    local quality = slotInfo and slotInfo.quality
    local noValue = SlotHasNoValue(slotInfo)
    local ic = IC()
    if quality == nil and ic and ic.GetQuality then
        quality = ic.GetQuality(itemID)
    end
    if SecretNumber(quality, -1) ~= POOR then
        return false
    end
    if noValue == true then
        return false
    end
    if noValue == nil and ic and ic.GetSellPrice then
        if (ic.GetSellPrice(itemID) or 0) <= 0 then
            return false
        end
    end
    return true
end

function FJ.NativeJunkCount()
    if not (C_MerchantFrame and C_MerchantFrame.GetNumJunkItems) then
        return 0
    end
    local raw = C_MerchantFrame.GetNumJunkItems()
    local Secrets = _G.Flux and _G.Flux.Secrets
    if Secrets and Secrets.SafeGetNumber then
        return Secrets.SafeGetNumber(raw, 0)
    end
    return tonumber(raw) or 0
end

function FJ.HasItemInPlayerBags(itemID)
    local inv = Inv()
    return inv and inv.GetCount(itemID) > 0 or false
end

function FJ.FindBagSlot(id, bag, slot)
    if bag ~= nil and slot ~= nil then
        return bag, slot
    end
    local inv = Inv()
    if not inv then return nil end
    return inv.FindFirstBagSlot(id)
end

-- ---------------------------------------------------------------------------
-- ITERATION / COUNTS / SELL STATS (snapshot reads + O(1) checks)
-- ---------------------------------------------------------------------------

local cachedJunkSlotCount = nil
local cachedJunkSlotGen = -1
local junkCountListeners = {}

local junkWorklists = {
    all = nil,
    inferiorOnly = nil,
}
local junkWorklistValid = {
    all = false,
    inferiorOnly = false,
}
local inferiorKindFilter = nil

local function BagSnapshotGen()
    local inv = Inv()
    return inv and inv.GetBagSnapshotGeneration and inv.GetBagSnapshotGeneration() or 0
end

local function RecordJunkScan(label)
    local prof = _G.FluxBagLagProf
    if prof and prof.Inc then
        prof.Inc(label or "junk:fullScan")
    end
end

local function NumericItemID(value)
    local n = tonumber(value)
    if n and n > 0 then
        return n
    end
    local Secrets = _G.Flux and _G.Flux.Secrets
    if Secrets and Secrets.SafeGetNumber then
        n = Secrets.SafeGetNumber(value, 0)
        if n and n > 0 then
            return n
        end
    end
    return nil
end

local function MakeBagSlotIterator(filterFn)
    local inv = Inv()
    if not inv or not inv.GetBagContainerIDs then
        return function() return nil end
    end
    local bags = inv.GetBagContainerIDs()
    local bagIdx = 1
    local slotIdx = 0
    return function()
        while bagIdx <= #bags do
            local bag = bags[bagIdx]
            local numSlots = inv.GetContainerNumSlots(bag) or 0
            for slot = slotIdx + 1, numSlots do
                slotIdx = slot
                local itemID = NumericItemID(inv.GetContainerItemID(bag, slot))
                if not itemID then
                    local info = inv.GetContainerItemInfo(bag, slot)
                    itemID = info and NumericItemID(info.itemID)
                end
                if itemID and filterFn(itemID, bag, slot) and not FJ.IsSlotProtectedFromSell(bag, slot) then
                    return bag, slot, itemID
                end
            end
            bagIdx = bagIdx + 1
            slotIdx = 0
        end
        return nil
    end
end

--- Iterator over junk slots: returns bag, slot, itemID per step (lazy walk).
function FJ.IterateJunk()
    local inv = Inv()
    return MakeBagSlotIterator(function(itemID, bag, slot)
        local info = inv and inv.GetContainerItemInfo(bag, slot)
        return FJ.IsJunk(itemID, info)
    end)
end

FJ.IterateJunkFast = FJ.IterateJunk

function FJ.IterateUpgradeInferiorFast()
    return MakeBagSlotIterator(function(itemID)
        if not inferiorSet[itemID] or IsProtected(itemID) or IsManualRestockItem(itemID) then
            return false
        end
        if inferiorKindFilter and next(inferiorKindFilter) then
            local Tiers = _G.FluxRestockTiers
            if not Tiers or not Tiers.ItemIsUpgradeInferiorForKinds
                or not Tiers.ItemIsUpgradeInferiorForKinds(itemID, inferiorKindFilter) then
                return false
            end
        end
        return true
    end)
end

function FJ.SetUpgradeInferiorKindFilter(kindFilter)
    inferiorKindFilter = kindFilter
    FJ.InvalidateJunkWorklist()
end

function FJ.ClearUpgradeInferiorKindFilter()
    inferiorKindFilter = nil
    FJ.InvalidateJunkWorklist()
end

function FJ.HasUpgradeInferiorForKinds(kindFilter)
    if not kindFilter or not next(kindFilter) then
        return FJ.GetUpgradeInferiorSlotCount() > 0
    end
    local Tiers = _G.FluxRestockTiers
    if Tiers and Tiers.HasUpgradeInferiorForKinds then
        return Tiers.HasUpgradeInferiorForKinds(kindFilter)
    end
    for _, _ in FJ.IterateUpgradeInferiorFast() do
        return true
    end
    return false
end

local function WorklistModeKey(mode)
    if mode == "inferiorOnly" then
        return "inferiorOnly"
    end
    return "all"
end

local function NotifyJunkCountListeners(count)
    for _, fn in ipairs(junkCountListeners) do
        pcall(fn, count)
    end
end

local function InvalidateJunkWorklist(force)
    local inv = Inv()
    if not force and inv and inv.IsAutomationQuiet and inv.IsAutomationQuiet() then
        if not FJ._quietWorklistInvalidatePending then
            FJ._quietWorklistInvalidatePending = true
            if inv.OnQuietSettled then
                inv.OnQuietSettled(function()
                    FJ._quietWorklistInvalidatePending = false
                    junkWorklistValid.all = false
                    junkWorklistValid.inferiorOnly = false
                    junkWorklists.all = nil
                    junkWorklists.inferiorOnly = nil
                    if FJ.InvalidateSellButtonStats then
                        FJ.InvalidateSellButtonStats()
                    end
                end)
            else
                FJ._quietWorklistInvalidatePending = false
            end
        end
        return
    end
    junkWorklistValid.all = false
    junkWorklistValid.inferiorOnly = false
    junkWorklists.all = nil
    junkWorklists.inferiorOnly = nil
    if FJ.InvalidateSellButtonStats then
        FJ.InvalidateSellButtonStats()
    end
end

function FJ.InvalidateJunkWorklist(force)
    InvalidateJunkWorklist(force == true)
end

function FJ.IsSlotProtectedFromSell(bag, slot)
    local lock = _G.FluxRespec and _G.FluxRespec.GearSetLock
    if lock and lock.IsSlotProtected then
        return lock.IsSlotProtected(bag, slot)
    end
    return false
end

--- One full bag scan; reused across sell pulses until invalidated.
function FJ.BuildJunkSlotWorklist(mode)
    mode = WorklistModeKey(mode)
    RecordJunkScan("junk:worklistBuild")
    local list = {}
    if mode == "inferiorOnly" then
        for bag, slot, itemID in FJ.IterateUpgradeInferiorFast() do
            list[#list + 1] = { bag = bag, slot = slot, itemID = itemID }
        end
    else
        for bag, slot, itemID in FJ.IterateJunk() do
            list[#list + 1] = { bag = bag, slot = slot, itemID = itemID }
        end
    end
    junkWorklists[mode] = list
    junkWorklistValid[mode] = true
    if mode == "all" then
        cachedJunkSlotCount = #list
        cachedJunkSlotGen = BagSnapshotGen()
        NotifyJunkCountListeners(cachedJunkSlotCount)
    end
    return list
end

function FJ.EnsureJunkWorklist(mode)
    mode = WorklistModeKey(mode)
    if junkWorklistValid[mode] and junkWorklists[mode] then
        return junkWorklists[mode]
    end
    return FJ.BuildJunkSlotWorklist(mode)
end

--- Iterator over a cached junk worklist (O(remaining) per sell pulse).
function FJ.IterateJunkWorklist(mode)
    local list = FJ.EnsureJunkWorklist(mode)
    local idx = 0
    local prof = _G.FluxBagLagProf
    if prof and prof.Inc then
        prof.Inc("junk:worklistIter", 1)
    end
    return function()
        idx = idx + 1
        local entry = list[idx]
        if not entry then
            return nil
        end
        return entry.bag, entry.slot, entry.itemID
    end
end

function FJ.RemoveJunkSlotFromWorklist(bag, slot, mode)
    mode = WorklistModeKey(mode or "all")
    local list = junkWorklists[mode]
    if not list then
        return false
    end
    for i = #list, 1, -1 do
        local e = list[i]
        if e.bag == bag and e.slot == slot then
            table.remove(list, i)
            if mode == "all" then
                FJ.AdjustJunkSlotCount(-1)
            end
            return true
        end
    end
    return false
end

function FJ.HasJunkWorklistRemaining(mode)
    mode = WorklistModeKey(mode)
    local list = junkWorklists[mode]
    return list ~= nil and #list > 0
end

function FJ.GetUpgradeInferiorSlotCount()
    local count = 0
    for _ in FJ.IterateUpgradeInferiorFast() do
        count = count + 1
    end
    return count
end

local function ScanJunkSlotCount()
    RecordJunkScan("junk:slotCountScan")
    local count = 0
    for _ in FJ.IterateJunk() do
        count = count + 1
    end
    cachedJunkSlotCount = count
    cachedJunkSlotGen = BagSnapshotGen()
    NotifyJunkCountListeners(count)
    return count
end

function FJ.InvalidateJunkSlotCount()
    cachedJunkSlotGen = -1
    InvalidateJunkWorklist()
end

function FJ.GetJunkSlotCount()
    return ScanJunkSlotCount()
end

function FJ.GetJunkSlotCountFast()
    local gen = BagSnapshotGen()
    if cachedJunkSlotCount ~= nil and cachedJunkSlotGen == gen then
        return cachedJunkSlotCount
    end
    return ScanJunkSlotCount()
end

function FJ.RefreshJunkSlotCountFast()
    return ScanJunkSlotCount()
end

function FJ.AdjustJunkSlotCount(delta)
    if cachedJunkSlotCount == nil then
        return
    end
    cachedJunkSlotCount = math.max(0, (cachedJunkSlotCount or 0) + (delta or 0))
    NotifyJunkCountListeners(cachedJunkSlotCount)
end

function FJ.RegisterJunkCountListener(fn)
    if type(fn) ~= "function" then return end
    junkCountListeners[#junkCountListeners + 1] = fn
end

function FJ.OnBagSnapshotDiff(ctx)
    if not ctx then return end
    if ctx.changeKind == "countOnly" and cachedJunkSlotCount ~= nil then
        return
    end
    FJ.InvalidateJunkSlotCount()
    if ctx.changeKind ~= "countOnly" then
        FJ.InvalidateJunkTabListCache()
    end
end

function FJ.AnyJunkInBags()
    for _ in FJ.IterateJunk() do
        return true
    end
    return false
end

function FJ.AnyExplicitJunkInBags()
    local list = GetSettings().junkList
    local inv = Inv()
    if not list or not inv or not inv.GetCount then
        return false
    end
    for id, val in pairs(list) do
        if val == true then
            local itemID = tonumber(id)
            if itemID and inv.GetCount(itemID) > 0 then
                return true
            end
        end
    end
    return false
end

function FJ.AnyBlizzardVendorJunkInBags()
    if FJ.NativeJunkCount() > 0 then
        return true
    end
    local inv = Inv()
    if not inv or not inv.GetBagContainerIDs then
        return false
    end
    for _, bag in ipairs(inv.GetBagContainerIDs()) do
        local numSlots = inv.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local info = inv.GetContainerItemInfo(bag, slot)
            if info and FJ.IsBlizzardVendorJunk(NumericItemID(info.itemID) or info.itemID, info) then
                return true
            end
        end
    end
    return false
end

function FJ.HasSellableJunkForButton(allowFullScan)
    -- Prefer O(1)/cached signals; never full-bag walk on vendor open by default.
    local gen = BagSnapshotGen()
    if cachedJunkSlotCount ~= nil and cachedJunkSlotGen == gen and cachedJunkSlotCount > 0 then
        return true
    end
    if MerchantFrame and MerchantFrame:IsShown() and FJ.NativeJunkCount() > 0 then
        return true
    end
    -- Inferior marks in the set do not imply bags still hold them.
    if FJ.AnyUpgradeInferiorInBags and FJ.AnyUpgradeInferiorInBags() then
        return true
    end
    if FJ.AnyExplicitJunkInBags and FJ.AnyExplicitJunkInBags() then
        return true
    end
    if FJ.AnyBlizzardVendorJunkInBags and FJ.AnyBlizzardVendorJunkInBags() then
        return true
    end
    if allowFullScan then
        return FJ.AnyJunkInBags()
    end
    return false
end

function FJ.RefreshSellableJunkButtonState()
    return FJ.HasSellableJunkForButton(false)
end

--- Sell stats for the merchant button tooltip: total value, slot count,
--- per-quality stack counts. Live container info only for junk slots.
local cachedSellButtonStats = nil
local cachedSellButtonStatsAt = 0

function FJ.GetSellButtonStats()
    local sj = _G.FluxSellJunk
    if sj and sj.IsSelling and sj.IsSelling() and cachedSellButtonStats then
        return cachedSellButtonStats
    end
    local inv = Inv()
    local ic = IC()
    local total = 0
    local slotCount = 0
    local qualities = {}
    if not inv then
        return { total = 0, slotCount = 0, hasAny = false, qualities = qualities }
    end
    for bag, slot, id in FJ.IterateJunk() do
        slotCount = slotCount + 1
        local info = inv.GetContainerItemInfo(bag, slot)
        if info and not info.locked then
            local unitPrice = ic and ic.GetSellPrice(info.itemID) or 0
            if unitPrice > 0 then
                local quality = info.quality or (ic and ic.GetQuality(info.itemID)) or 0
                qualities[quality] = (qualities[quality] or 0) + (info.count or 1)
                total = total + (info.count or 1) * unitPrice
            end
        end
    end
    local stats = {
        total = total,
        slotCount = slotCount,
        hasAny = slotCount > 0,
        qualities = qualities,
    }
    cachedSellButtonStats = stats
    cachedSellButtonStatsAt = GetTime()
    return stats
end

function FJ.InvalidateSellButtonStats()
    cachedSellButtonStats = nil
    cachedSellButtonStatsAt = 0
end

function FJ.GetSellReport()
    local stats = FJ.GetSellButtonStats()
    return stats.total, stats.qualities
end

-- ---------------------------------------------------------------------------
-- LIST MUTATION (UI contract preserved)
-- ---------------------------------------------------------------------------

local cachedExplicitJunkList = nil
local cachedUsefulList = nil
local junkListSettingsToken = 0

local function BumpJunkListSettingsToken()
    junkListSettingsToken = junkListSettingsToken + 1
    cachedExplicitJunkList = nil
    cachedUsefulList = nil
end

function FJ.FireListChanged(itemID)
    BumpJunkListSettingsToken()
    FJ.InvalidateJunkTabListCache()
    if itemID then
        FJ.InvalidateJunkSlotCount()
    else
        FJ.InvalidateJunkSlotCount()
    end
    for _, fn in pairs(listeners) do
        pcall(fn, itemID)
    end
    FJ.NotifyVisualRefresh(itemID)
end

function FJ.RegisterListChanged(callback)
    if type(callback) ~= "function" then return end
    listeners[#listeners + 1] = callback
end

function FJ.NotifyVisualRefresh(itemID)
    for _, fn in pairs(visualListeners) do
        pcall(fn, itemID)
    end
end

function FJ.RegisterVisualRefresh(callback)
    if type(callback) ~= "function" then return end
    visualListeners[#visualListeners + 1] = callback
end

function FJ.RefreshJunkVisuals()
    FJ.NotifyVisualRefresh()
end

local function ItemChatName(id)
    local ic = IC()
    local link = ic and ic.GetInfo(id)
    return (link and link.link) or ("item:" .. tostring(id))
end

function FJ.ToggleJunk(id)
    id = tonumber(id)
    if not id then return end
    local wasJunk = FJ.IsJunk(id)
    GetSettings().junkList[id] = not wasJunk
    if not wasJunk then
        inferiorSet[id] = nil
    end
    print(string.format("|cff00ffff[FluxUI]|r %s marked as %s.",
        ItemChatName(id), (not wasJunk) and "junk" or "useful"))
    FJ.FireListChanged(id)
end

function FJ.AddJunk(id)
    id = tonumber(id)
    if not id then return end
    GetSettings().junkList[id] = true
    FJ.FireListChanged(id)
end

function FJ.MarkUseful(id)
    id = tonumber(id)
    if not id then return end
    GetSettings().junkList[id] = false
    inferiorSet[id] = nil
    FJ.FireListChanged(id)
end

function FJ.ForgetJunk(id)
    id = tonumber(id)
    if not id then return end
    GetSettings().junkList[id] = nil
    inferiorSet[id] = nil
    FJ.FireListChanged(id)
end

FJ.RemoveJunk = FJ.ForgetJunk

function FJ.ClearAutoJunkMark(id)
    id = tonumber(id)
    if not id then return end
    -- Explicit protection is the reliable way to suppress an automatic mark.
    GetSettings().junkList[id] = false
    inferiorSet[id] = nil
    FJ.FireListChanged(id)
end

-- ---------------------------------------------------------------------------
-- LIST QUERIES (panels)
-- ---------------------------------------------------------------------------

local cachedJunkTabList = nil
local cachedJunkTabListGen = -1

local function JunkTabListCacheToken()
    return junkListSettingsToken * 1000000 + BagSnapshotGen() * 1000 + ruleGeneration
        + (next(inferiorSet) and 1 or 0)
end

function FJ.InvalidateJunkTabListCache()
    cachedJunkTabList = nil
    cachedJunkTabListGen = -1
end

local function SortByName(list)
    local ic = IC()
    table.sort(list, function(a, b)
        local nameA = (ic and ic.GetName(a)) or ""
        local nameB = (ic and ic.GetName(b)) or ""
        if nameA == nameB then
            return a < b
        end
        return nameA < nameB
    end)
    return list
end

function FJ.GetExplicitJunkList()
    if cachedExplicitJunkList then
        return cachedExplicitJunkList
    end
    local list = {}
    for id, val in pairs(GetSettings().junkList) do
        local numericID = tonumber(id)
        if numericID and val == true then
            list[#list + 1] = numericID
        end
    end
    cachedExplicitJunkList = SortByName(list)
    return cachedExplicitJunkList
end

function FJ.GetUsefulList()
    if cachedUsefulList then
        return cachedUsefulList
    end
    local list = {}
    for id, val in pairs(GetSettings().junkList) do
        local numericID = tonumber(id)
        if numericID and val == false then
            list[#list + 1] = numericID
        end
    end
    cachedUsefulList = SortByName(list)
    return cachedUsefulList
end

local function IsAutoJunkInBags(itemID, slotInfo)
    return not FJ.IsExplicitJunk(itemID) and FJ.IsJunk(itemID, slotInfo)
end

function FJ.GetAutoJunkList()
    local seen = {}
    local list = {}
    local inv = Inv()
    if not inv then
        return list
    end
    RecordJunkScan("junk:autoListScan")
    local iter = MakeBagSlotIterator(function(itemID, bag, slot)
        return IsAutoJunkInBags(itemID, inv.GetContainerItemInfo(bag, slot))
    end)
    for _, _, itemID in iter do
        if not seen[itemID] then
            seen[itemID] = true
            list[#list + 1] = itemID
        end
    end
    return SortByName(list)
end

--- Junk tab list: explicit junk + owned auto junk (inferior + rules).
function FJ.GetJunkTabList()
    local token = JunkTabListCacheToken()
    if cachedJunkTabList and cachedJunkTabListGen == token then
        return cachedJunkTabList
    end
    RecordJunkScan("junk:tabListBuild")
    local seen = {}
    local list = {}
    for _, id in ipairs(FJ.GetExplicitJunkList()) do
        if not seen[id] then
            seen[id] = true
            list[#list + 1] = id
        end
    end
    for _, id in ipairs(FJ.GetAutoJunkList()) do
        if not seen[id] then
            seen[id] = true
            list[#list + 1] = id
        end
    end
    cachedJunkTabList = SortByName(list)
    cachedJunkTabListGen = token
    return cachedJunkTabList
end

function FJ.RebuildJunkTabListCache()
    FJ.InvalidateJunkTabListCache()
    return FJ.GetJunkTabList()
end

function FJ.IsAutoJunk(id)
    id = tonumber(id)
    if not id or FJ.IsExplicitUseful(id) or FJ.IsExplicitJunk(id) then
        return false
    end
    if IsManualRestockItem(id) then
        return false
    end
    if not FJ.HasItemInPlayerBags(id) then
        return false
    end
    return FJ.IsJunk(id)
end

--- Called when a manual restock target changes so overlays / sell counts update.
--- While on the list: suppress auto-junk (drop inferior mark).
--- When removed / target 0: re-evaluate auto-junk and refresh UI.
function FJ.OnManualRestockChanged(itemID)
    itemID = tonumber(itemID)
    if not itemID then return end

    if IsManualRestockItem(itemID) then
        if inferiorSet[itemID] then
            inferiorSet[itemID] = nil
        end
    else
        -- Restock no longer protects this item — re-apply upgrade-inferior if needed.
        if inferiorSet[itemID] then
            inferiorSet[itemID] = nil
        end
        local Tiers = _G.FluxRestockTiers
        if Tiers and Tiers.ItemIsUpgradeInferiorForKinds and FJ.MarkUpgradeInferior then
            if Tiers.ItemIsUpgradeInferiorForKinds(itemID) then
                FJ.MarkUpgradeInferior(itemID)
            end
        elseif Tiers and Tiers.RequestRecompute then
            Tiers.RequestRecompute({ scope = "inferior", notify = true })
        end
    end

    FJ.FireListChanged(itemID)
    NotifyJunkAvailabilityChanged()
end

-- ---------------------------------------------------------------------------
-- CURSOR / DROP
-- ---------------------------------------------------------------------------

function FJ.GetItemIdFromCursor()
    if _G.FluxItemCurrencyTracking and _G.FluxItemCurrencyTracking.GetItemIdFromCursor then
        local id = _G.FluxItemCurrencyTracking.GetItemIdFromCursor()
        if id then return tonumber(id) end
    end
    local cursorType, itemID = GetCursorInfo()
    if cursorType == "item" then
        return tonumber(itemID)
    end
end

function FJ.HandleItemDrop(forceJunk)
    local itemID = FJ.GetItemIdFromCursor()
    if not itemID then
        return false
    end
    if forceJunk then
        FJ.AddJunk(itemID)
    else
        FJ.ToggleJunk(itemID)
    end
    ClearCursor()
    return true
end

-- ---------------------------------------------------------------------------
-- COMPAT SHIMS (old FluxVendorJunk surface that new code no longer needs)
-- ---------------------------------------------------------------------------

function FJ.WarmJunkDisplayCacheForBags() end
function FJ.WarmJunkDisplayCacheThoroughChunked(onComplete)
    if onComplete then onComplete() end
end
function FJ.IsJunkDisplayCacheWarm() return true end
function FJ.ResetJunkDisplayCacheWarm() end
function FJ.InvalidateJunkBag() end
function FJ.InvalidateAllJunkBags() end
function FJ.FlushDeferredJunkDisplayCaches() end
function FJ.RelocateBagJunkCache() end
function FJ.RefreshJunkDisplaySlot() end
function FJ.SetJunkDisplayCacheSlot() end
function FJ.BeginVisualPaint() end
function FJ.EndVisualPaint() end
function FJ.IsVisualPaintActive() return false end
function FJ.RescanAutoJunkRules() return false end
function FJ.SyncAutoJunkMarks() return false end
function FJ.ScheduleAutoJunkSync() end
local junkTabRefreshToken = 0
function FJ.ScheduleJunkTabAuthoritativeRefresh(opts)
    opts = type(opts) == "table" and opts or {}
    if opts.forceTierRefresh then
        local Tiers = _G.FluxRestockTiers
        if Tiers and Tiers.RequestRecompute then
            Tiers.RequestRecompute({ force = true })
        end
    end
    if not opts.refreshPanel or not (C_Timer and C_Timer.After) then
        return
    end
    junkTabRefreshToken = junkTabRefreshToken + 1
    local token = junkTabRefreshToken
    C_Timer.After(0.05, function()
        if token ~= junkTabRefreshToken then
            return
        end
        FJ.InvalidateJunkTabListCache()
        FJ.GetJunkTabList()
        if opts.notify ~= false then
            FJ.FireListChanged()
            return
        end
        local Panel = _G.FluxVendorJunkPanel
        local frame = _G.FluxVendorJunkPanelFrame
        if Panel and Panel.RefreshList and frame and frame:IsShown() then
            Panel:RefreshList()
        end
    end)
end
function FJ.PromoteMarkedInferiorToAutoJunk() return true end
function FJ.PromoteInferiorItemsToAutoJunk() return false end
function FJ.ReconcileUpgradeInferiorMarks() end
function FJ.EnsureInferiorConsumableMarked() return false end

function FJ.ScheduleConjureInferiorJunkSync(force)
    local Tiers = _G.FluxRestockTiers
    if Tiers and Tiers.RequestRecompute then
        Tiers.RequestRecompute(force and { force = true } or nil)
    end
end

function FJ.AppendTierReferenceRestoreLines(tooltip, tierKind)
    local Tiers = _G.FluxRestockTiers
    if Tiers and Tiers.AppendTierReferenceLines then
        Tiers.AppendTierReferenceLines(tooltip, tierKind)
    end
end

function FJ.HasConjureJunkFilterAvailable()
    local inv = Inv()
    local Spells = inv and inv.Spells
    if Spells then
        if Spells.HasConjureFood and Spells.HasConjureFood() then
            return true
        end
        if Spells.HasConjureWater and Spells.HasConjureWater() then
            return true
        end
        if Spells.HasConjureRefreshment and Spells.HasConjureRefreshment() then
            return true
        end
    end
    local Detection = _G.FluxNCItemDetection
    if not Detection then
        return false
    end
    return (Detection.HasConjureFood and Detection.HasConjureFood())
        or (Detection.HasConjureWater and Detection.HasConjureWater())
        or (Detection.HasConjureRefreshment and Detection.HasConjureRefreshment())
end

-- Legacy debug entry points (slash `/fluxvendor inferior`).
function FJ.ScanInferiorTierConsumables()
    local Tiers = _G.FluxRestockTiers
    if Tiers and Tiers.RequestRecompute then
        Tiers.RequestRecompute({ force = true })
    end
    local out = {}
    for id in pairs(inferiorSet) do
        out[#out + 1] = id
    end
    return out
end

function FJ.PrintInferiorTierScan()
    local ids = FJ.ScanInferiorTierConsumables()
    print(string.format("|cff00ffff[FluxUI]|r %d inferior-tier consumable(s) marked.", #ids))
    for _, id in ipairs(ids) do
        print("  - " .. ItemChatName(id))
    end
end

-- ---------------------------------------------------------------------------
-- EVENTS: rule invalidation only (no bag scanning here)
-- ---------------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        local inv = Inv()
        if inv and inv.RegisterListener then
            inv.RegisterListener("FluxJunkSlotCount", function(ctx)
                FJ.OnBagSnapshotDiff(ctx)
            end, { tier = "instant", sync = true })
        end
    elseif event == "PLAYER_LEVEL_UP" then
        -- Level-dependent rules (low-level consumables) change thresholds.
        FJ.InvalidateRules()
        FJ.FireListChanged()
    end
end)

_G.FluxJunk = FJ
_G.FluxVendorJunk = FJ
return FJ

