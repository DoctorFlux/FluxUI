--[[
    Inventory/FluxItemClass.lua

    Per-itemID classification cache. Item stats never change during a session,
    so everything here is computed AT MOST ONCE per itemID and kept forever:

      * static info   (GetItemInfoInstant: class/subclass/equipLoc/icon)
      * full info     (GetItemInfo: quality/sellPrice/levels/stack/bind)
      * restore parse (tooltip: food/water/bandage restore values, conjured,
                       well-fed) - the single tooltip read per item, ever.

    Async: items not yet in the client cache are requested via
    C_Item.RequestLoadItemDataByID; FluxInv routes ITEM_DATA_LOAD_RESULT
    into OnItemDataLoaded so pending entries resolve without extra events.

    This replaces the expiring caches in ItemDetection (60s tooltip cache,
    invalidated on every bag pulse) that made tooltip parsing a recurring cost.
]]

FluxItemClass = FluxItemClass or {}
local IC = FluxItemClass

local GetItemInfoInstantCompat = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant

local function ParseItemInfoInstant(itemID)
    if not itemID or not GetItemInfoInstantCompat then
        return nil
    end
    local r1, itemType, itemSubType, equipLoc, icon, classID, subClassID = GetItemInfoInstantCompat(itemID)
    if type(r1) == "table" then
        local info = r1
        return {
            classID = info.classID or info.itemClassID,
            subClassID = info.subclassID or info.itemSubClassID,
            equipLoc = info.equipLoc or info.itemEquipLoc,
            icon = info.iconFileID or info.icon or info.itemIcon,
            itemType = info.itemType,
            itemSubType = info.itemSubType,
        }
    end
    if classID == nil and itemType == nil and type(r1) ~= "number" then
        return nil
    end
    return {
        classID = classID,
        subClassID = subClassID,
        equipLoc = equipLoc,
        icon = icon,
        itemType = itemType,
        itemSubType = itemSubType,
    }
end

local staticCache = {}   -- [itemID] = { classID, subClassID, equipLoc, icon }
local infoCache = {}     -- [itemID] = full info record (only once loaded)
local restoreCache = {}  -- [itemID] = restore record (ready=true) or false (retry)
local restoreRetries = {}
local MAX_RESTORE_RETRIES = 4

-- Per-frame tooltip scan budget (FluxBagLagProf is disabled in TOC; keep a
-- local gate so bag storms cannot synchronously parse hundreds of tooltips).
local TOOLTIP_SCANS_PER_FRAME = 8
local tooltipScanFrameToken = 0
local tooltipScansThisFrame = 0

local function TryConsumeTooltipScanBudget()
    local prof = _G.FluxBagLagProf
    if prof and prof.TryConsumeTooltipScan then
        return prof.TryConsumeTooltipScan()
    end
    local token = (GetTime and math.floor(GetTime() * 1000)) or 0
    if token ~= tooltipScanFrameToken then
        tooltipScanFrameToken = token
        tooltipScansThisFrame = 0
    end
    if tooltipScansThisFrame >= TOOLTIP_SCANS_PER_FRAME then
        return false
    end
    tooltipScansThisFrame = tooltipScansThisFrame + 1
    return true
end

-- ---------------------------------------------------------------------------
-- STATIC INFO (always available, even for uncached items)
-- ---------------------------------------------------------------------------

function IC.GetStatic(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    local rec = staticCache[itemID]
    if rec ~= nil then
        return rec or nil
    end
    local parsed = ParseItemInfoInstant(itemID)
    if not parsed or (parsed.classID == nil and parsed.itemType == nil) then
        staticCache[itemID] = false
        return nil
    end
    rec = {
        classID = parsed.classID,
        subClassID = parsed.subClassID,
        equipLoc = parsed.equipLoc,
        icon = parsed.icon,
        itemType = parsed.itemType,
        itemSubType = parsed.itemSubType,
    }
    staticCache[itemID] = rec
    return rec
end

-- ---------------------------------------------------------------------------
-- FULL INFO (async; nil until the client has the item data)
-- ---------------------------------------------------------------------------

local function BuildInfoRecord(itemID)
    local name, link, quality, itemLevel, minLevel, itemType, itemSubType,
        stackCount, equipLoc, icon, sellPrice, classID, subClassID, bindType
    if C_Item and C_Item.GetItemInfo then
        local info = C_Item.GetItemInfo(itemID)
        if type(info) == "table" then
            name = info.itemName or info.name
            link = info.itemLink or info.hyperlink
            quality = info.itemQuality or info.quality
            itemLevel = info.itemLevel
            minLevel = info.itemMinLevel or info.requiredLevel
            itemType = info.itemType
            itemSubType = info.itemSubType
            stackCount = info.stackCount or info.itemStackCount
            equipLoc = info.equipLoc or info.itemEquipLoc
            icon = info.iconFileID or info.itemIcon or info.iconID
            sellPrice = info.sellPrice
            classID = info.classID
            subClassID = info.subclassID
            bindType = info.bindType
        elseif info ~= nil then
            name, link, quality, itemLevel, minLevel, itemType, itemSubType,
                stackCount, equipLoc, icon, sellPrice, classID, subClassID, bindType = C_Item.GetItemInfo(itemID)
        end
    end
    if not name and GetItemInfo then
        name, link, quality, itemLevel, minLevel, itemType, itemSubType,
            stackCount, equipLoc, icon, sellPrice, classID, subClassID, bindType = GetItemInfo(itemID)
    end
    if not name then
        return nil
    end
    return {
        name = name,
        link = link,
        quality = quality,
        itemLevel = itemLevel or 0,
        minLevel = minLevel or 0,
        itemType = itemType,
        itemSubType = itemSubType,
        stackSize = stackCount or 1,
        equipLoc = equipLoc,
        icon = icon,
        sellPrice = sellPrice or 0,
        classID = classID,
        subClassID = subClassID,
        bindType = bindType,
    }
end

function IC.RequestLoad(itemID)
    itemID = tonumber(itemID)
    if not itemID then return end
    if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
    -- Classic can expose a modern loader before it has useful item metadata.
    -- The legacy query also requests the server record and emits its own event.
    if GetItemInfo then pcall(GetItemInfo, itemID) end
end

--- Full item info record, or nil when the item is not loaded yet (a load is
--- requested automatically; a later query will succeed).
function IC.GetInfo(itemID)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    local rec = infoCache[itemID]
    if rec then
        return rec
    end
    rec = BuildInfoRecord(itemID)
    if rec then
        infoCache[itemID] = rec
        return rec
    end
    IC.RequestLoad(itemID)
    return nil
end

function IC.IsLoaded(itemID)
    return IC.GetInfo(itemID) ~= nil
end

function IC.GetName(itemID)
    local rec = IC.GetInfo(itemID)
    return rec and rec.name or nil
end

function IC.GetLink(itemID)
    local rec = IC.GetInfo(itemID)
    if rec and rec.link then
        return rec.link
    end
    itemID = tonumber(itemID)
    if not itemID then
        return nil
    end
    local bank = (_G.FluxRestock and _G.FluxRestock.Inv and _G.FluxRestock.Inv.Bank)
        or (_G.FluxInv and _G.FluxInv.Bank)
    if bank and bank.GetItemLink then
        local link = bank.GetItemLink(itemID)
        if link then
            return link
        end
    end
    return "item:" .. itemID
end

function IC.GetQuality(itemID)
    local rec = IC.GetInfo(itemID)
    return rec and rec.quality or nil
end

function IC.GetSellPrice(itemID)
    local rec = IC.GetInfo(itemID)
    if rec then
        return rec.sellPrice or 0
    end
    -- Instant-info sometimes carries a sell price on modern clients.
    if C_Item and C_Item.GetItemInfoInstant then
        local info = C_Item.GetItemInfoInstant(itemID)
        if type(info) == "table" and info.sellPrice then
            return info.sellPrice
        end
    end
    return 0
end

function IC.GetStackSize(itemID)
    local rec = IC.GetInfo(itemID)
    return (rec and rec.stackSize) or 20
end

function IC.GetIcon(itemID)
    local static = IC.GetStatic(itemID)
    if static and static.icon then
        return static.icon
    end
    local rec = IC.GetInfo(itemID)
    return rec and rec.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function IC.GetClassID(itemID)
    local static = IC.GetStatic(itemID)
    return static and static.classID or nil
end

function IC.GetSubClassID(itemID)
    local static = IC.GetStatic(itemID)
    return static and static.subClassID or nil
end

function IC.GetEquipLoc(itemID)
    local static = IC.GetStatic(itemID)
    local loc = static and static.equipLoc
    if loc == "" then loc = nil end
    return loc
end

function IC.IsEquippable(itemID)
    if C_Item and C_Item.IsEquippableItem then
        return C_Item.IsEquippableItem(itemID) and true or false
    end
    if _G.IsEquippableItem then
        return _G.IsEquippableItem(itemID) and true or false
    end
    return IC.GetEquipLoc(itemID) ~= nil
end

-- ---------------------------------------------------------------------------
-- RESTORE PARSE (one tooltip read per itemID per session, ever)
-- ---------------------------------------------------------------------------

local scanTip

local function EnsureScanTooltip()
    if scanTip then return scanTip end
    scanTip = CreateFrame("GameTooltip", "FluxItemClassScanTooltip", UIParent, "GameTooltipTemplate")
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    return scanTip
end

local function CollectTooltipTextFromCTooltipInfo(getData, ...)
    if type(getData) ~= "function" then
        return nil
    end
    local ok, data = pcall(getData, ...)
    if not ok or not data or not data.lines then
        return nil
    end
    if TooltipUtil and TooltipUtil.SurfaceArgs then
        for _, line in ipairs(data.lines) do
            pcall(TooltipUtil.SurfaceArgs, line)
        end
    end
    local parts = {}
    for i = 2, math.min(#data.lines, 40) do
        local line = data.lines[i]
        local text = line and (line.leftText or line.rightText)
        if text and text ~= "" then
            parts[#parts + 1] = text:lower()
        end
    end
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, "\n")
end

local function CollectTooltipTextFromGameTooltip(itemLink, bag, slot)
    local tip = EnsureScanTooltip()
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    local ok = pcall(function()
        if bag ~= nil and slot ~= nil and tip.SetBagItem then
            tip:SetBagItem(bag, slot)
        else
            tip:SetHyperlink(itemLink)
        end
    end)
    if not ok then
        return nil
    end
    local parts = {}
    for i = 2, math.min(tip:NumLines() or 0, 40) do
        local left = _G["FluxItemClassScanTooltipTextLeft" .. i]
        local text = left and left:GetText()
        if text and text ~= "" then
            parts[#parts + 1] = text:lower()
        end
    end
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, "\n")
end

--- Lowercase multi-line tooltip text for an item, or nil if unavailable.
function IC.GetTooltipText(itemID, itemLink)
    -- Query the owned location as well as its hyperlink. Classic item IDs can
    -- already be counted while hyperlink tooltips are still empty after login.
    local Flux = _G.Flux
    local Inv = Flux and Flux.Inventory
    local location = Inv and Inv.GetFirst and Inv.GetFirst(itemID, {
        bags = true, bank = false, warband = false, equipped = false,
    })
    local text
    if location then
        text = CollectTooltipTextFromCTooltipInfo(C_TooltipInfo and C_TooltipInfo.GetBagItem, location.bag, location.slot)
        if text then return text end
    end
    itemLink = itemLink or IC.GetLink(itemID)
    if not itemLink then return nil end
    text = CollectTooltipTextFromCTooltipInfo(C_TooltipInfo and C_TooltipInfo.GetHyperlink, itemLink)
    if text then return text end
    if location then
        text = CollectTooltipTextFromGameTooltip(nil, location.bag, location.slot)
        if text then return text end
    end
    return CollectTooltipTextFromGameTooltip(itemLink)
end

--- Permanent restore record for an item:
---   { health, mana, conjured, bandage, wellFed, isFoodWater, ready }
--- ready=false means the item data was not loaded when parsed; the record is
--- re-parsed automatically after ITEM_DATA_LOAD_RESULT.
function IC.GetRestore(itemID, itemLink)
    itemID = tonumber(itemID)
    if not itemID then return nil end
    local cached = restoreCache[itemID]
    if cached and cached.ready then
        return cached
    end
    local retries = restoreRetries[itemID] or 0
    if retries >= MAX_RESTORE_RETRIES then
        return cached or nil
    end

    local Classify = _G.FluxConsumableClassify
    local nc = Classify or _G.FluxNCItemDetection
    local parseFn = (Classify and Classify.ParseFoodWaterRestore)
        or (nc and nc.ParseFoodWaterRestore)
    if not parseFn then
        return cached or nil
    end

    -- Cold cache (fresh login/reload): cap how many never-before-parsed
    -- items get a real tooltip scan per frame so a big bag+bank of unique
    -- consumables can't freeze the client in one synchronous pass. Throttled
    -- items are left unresolved (not cached, retries not incremented) so a
    -- later frame retries them for free.
    if not TryConsumeTooltipScanBudget() then
        return cached or nil
    end

    itemLink = itemLink or IC.GetLink(itemID)
    local name = IC.GetName(itemID)
    local text = IC.GetTooltipText(itemID, itemLink)
    if not text then
        restoreRetries[itemID] = retries + 1
        IC.RequestLoad(itemID)
        return cached or nil
    end

    local ok, parsed = pcall(parseFn, text, itemLink, name)
    if not ok or type(parsed) ~= "table" then
        restoreRetries[itemID] = retries + 1
        return cached or nil
    end

    local ready = IC.IsLoaded(itemID)
    if parsed.isBandage == true and (parsed.effectiveH or 0) <= 0 then
        ready = false
    end
    local rec = {
        health = parsed.effectiveH or 0,
        mana = parsed.effectiveM or 0,
        conjured = parsed.isConjured == true,
        bandage = parsed.isBandage == true,
        excludeFromFoodWater = parsed.excludeFromFoodWater == true,
        wellFed = parsed.isWellFed == true,
        isFoodWater = parsed.isFoodWater == true,
        ready = ready,
    }
    restoreCache[itemID] = rec
    if ready then
        restoreRetries[itemID] = nil
    else
        restoreRetries[itemID] = retries + 1
        IC.RequestLoad(itemID)
    end
    return rec
end

--- Drop all restore parses (rare: level-ups change percent-based restores).
function IC.InvalidateRestoreCache()
    wipe(restoreCache)
    wipe(restoreRetries)
    IC.InvalidateClassification()
    local Classify = _G.FluxConsumableClassify
    if Classify and Classify.InvalidateCache then
        Classify.InvalidateCache()
    end
end

-- ---------------------------------------------------------------------------
-- UNIFIED CONSUMABLE CLASSIFICATION (single authority for restock + EBS)
-- ---------------------------------------------------------------------------

local ITEM_CLASS_CONSUMABLE = 0
local kindCache = {}

local function FoodWaterAxisFromRestore(restore)
    if not restore or restore.bandage or restore.excludeFromFoodWater
        or restore.wellFed or not restore.isFoodWater then
        return 0, 0
    end
    -- Conjured food/water still report restore for Best/Tiers ranking;
    -- restock bag accounting excludes conjured separately.
    return restore.health or 0, restore.mana or 0
end

--- Multi-axis consumable classification for restock tiers and item buttons.
--- Returns { food, water, bandage, healPotion, manaPotion, conjured, wellFed, stable }
--- or nil when the item is not a tracked consumable.
function IC.ClassifyConsumable(itemID, itemLink)
    itemID = tonumber(itemID)
    if not itemID then return nil end

    local cached = kindCache[itemID]
    if cached ~= nil then
        return cached or nil
    end

    local static = IC.GetStatic(itemID)
    if static and static.classID ~= nil and static.classID ~= ITEM_CLASS_CONSUMABLE then
        kindCache[itemID] = false
        return nil
    end

    local Classify = _G.FluxConsumableClassify
    local combatDet = _G.FluxItemDetection
    itemLink = itemLink or IC.GetLink(itemID)
    local rec = {
        food = 0, water = 0, bandage = 0, healPotion = 0, manaPotion = 0,
        conjured = false, wellFed = false, stable = IC.IsLoaded(itemID),
    }
    local any = false

    local resolveAxes = (Classify and Classify.ResolveCombatTierAxes)
        or (combatDet and combatDet.ResolveCombatTierAxes)
    if resolveAxes then
        local healPotion, manaPotion, bandage = resolveAxes(itemID, itemLink)
        if healPotion > 0 then
            rec.healPotion = healPotion
            any = true
        end
        if manaPotion > 0 then
            rec.manaPotion = manaPotion
            any = true
        end
        if bandage > 0 then
            rec.bandage = bandage
            any = true
        end
    end

    if not any and combatDet and combatDet.ClassifyCombatConsumable then
        local axisKind, axisVal = combatDet.ClassifyCombatConsumable(itemID, itemLink)
        axisVal = tonumber(axisVal) or 0
        if axisKind == "healPotion" and axisVal > 0 then
            rec.healPotion = axisVal
            any = true
        elseif axisKind == "manaPotion" and axisVal > 0 then
            rec.manaPotion = axisVal
            any = true
        elseif axisKind == "bandage" and axisVal > 0 then
            rec.bandage = axisVal
            any = true
        end
    end

    if rec.bandage <= 0 and rec.healPotion <= 0 and rec.manaPotion <= 0 then
        local restore = IC.GetRestore(itemID, itemLink)
        if restore then
            if not restore.ready then
                rec.stable = false
            end
            local foodVal, waterVal = FoodWaterAxisFromRestore(restore)
            if foodVal > 0 or waterVal > 0 then
                rec.food = foodVal
                rec.water = waterVal
                rec.conjured = restore.conjured == true
                rec.wellFed = restore.wellFed == true
                any = true
            end
        else
            rec.stable = false
        end
    end

    local result = any and rec or false
    if rec.stable then
        kindCache[itemID] = result
    end
    return any and rec or nil
end

function IC.InvalidateClassification(itemID)
    itemID = tonumber(itemID)
    if itemID then
        kindCache[itemID] = nil
    else
        wipe(kindCache)
    end
end

-- ---------------------------------------------------------------------------
-- ASYNC RESOLUTION (driven by FluxInv's ITEM_DATA_LOAD_RESULT handler)
-- ---------------------------------------------------------------------------

function IC.OnItemDataLoaded(itemID)
    itemID = tonumber(itemID)
    if not itemID then return end
    -- Item data just arrived: allow one fresh parse/info build.
    if not infoCache[itemID] then
        local rec = BuildInfoRecord(itemID)
        if rec then
            infoCache[itemID] = rec
        end
    end
    local restore = restoreCache[itemID]
    if restore == nil or (restore and not restore.ready) then
        restoreRetries[itemID] = nil
        restoreCache[itemID] = nil
    end
    if staticCache[itemID] == false then
        staticCache[itemID] = nil
    end
    IC.InvalidateClassification(itemID)
    local Classify = _G.FluxConsumableClassify
    if Classify and Classify.InvalidateCache then
        Classify.InvalidateCache(itemID)
    end
    local fj = _G.FluxVendorJunk or _G.FluxJunk
    if fj and fj.OnItemDataLoaded then
        fj.OnItemDataLoaded(itemID)
    end
    local best = _G.FluxConsumableBest
    if best and best.Scan and best.Scan.OnItemDataLoaded then
        pcall(best.Scan.OnItemDataLoaded, itemID)
    end
    local isConsumable = false
    local rec = infoCache[itemID]
    if rec and rec.classID ~= nil then
        isConsumable = rec.classID == ITEM_CLASS_CONSUMABLE
    else
        local static = staticCache[itemID]
        isConsumable = static and static.classID == ITEM_CLASS_CONSUMABLE
    end
    if isConsumable then
        local det = _G.FluxItemDetection
        if det and det.InvalidateCombatCache then
            pcall(det.InvalidateCombatCache)
        end
        local nc = _G.FluxNCItemDetection
        if nc and nc.InvalidateFoodWaterCache then
            pcall(nc.InvalidateFoodWaterCache)
        end
    end
    local core = _G.FluxItemDetectionCore
    if core and core.InvalidateParsedItemCache then
        pcall(core.InvalidateParsedItemCache, itemID)
    end
end

_G.FluxItemClass = IC

do
    local f = CreateFrame("Frame")
    f:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    f:SetScript("OnEvent", function(_, event, itemID, success)
        itemID = tonumber(itemID)
        if not itemID then
            return
        end
        if event == "ITEM_DATA_LOAD_RESULT" and success == false then
            return
        end
        IC.OnItemDataLoaded(itemID)
    end)
end

return IC
