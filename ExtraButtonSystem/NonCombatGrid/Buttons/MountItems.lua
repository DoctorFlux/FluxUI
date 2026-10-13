--[[
    ExtraButtonSystem/NonCombatGrid/Buttons/MountItems.lua
    Bag mount-item path for clients without Mount Journal / companions
    (Classic Era / TBC). Owns bag list cache + modKey→favorite map.
]]

FluxNCMount = FluxNCMount or {}
local Module = FluxNCMount

FluxNCMountItems = FluxNCMountItems or {}
local Items = FluxNCMountItems

local MOUNT_PRIORITY_ORDER = { "nomod", "shift", "ctrl", "alt", "ctrl+shift", "shift+alt", "ctrl+alt", "ctrl+shift+alt" }
local BAG_LIST_CACHE_TTL = 5

-- Cached flyout rows (zone-filtered and unfiltered)
local bagListCache = nil
local bagListCacheAll = nil
local bagListCacheTime = 0
local bagListCacheBagsGen = -1
local bagListCacheInstanceID = -1
local bagListCacheLocationKey = nil
local bagSetCache = nil
local bagSetCacheAll = nil

-- Precomputed best mount per modifier (priority fallback already applied)
local favMap = nil
local favMapDirty = true

local function GetSpells()
    local Flux = _G.Flux
    local fly = Flux and Flux.Inventory and Flux.Inventory.Flyable
    if fly then
        return fly
    end
    return _G.FluxInv and _G.FluxInv.Spells
end

local function UniqueBagItems()
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.GetUniqueItems then
        return api.GetUniqueItems({ bags = true, bank = false, warband = false, equipped = false })
    end
    local bags = _G.FluxInv and _G.FluxInv.Bags
    if bags and bags.GetUniqueItems then
        return bags.GetUniqueItems()
    end
    return {}
end

local function IsBagMountItem(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return false
    end
    if C_MountJournal and C_MountJournal.GetMountFromItem then
        local ok, mountId = pcall(C_MountJournal.GetMountFromItem, itemId)
        if ok and mountId then
            return true
        end
    end
    local classId, subclassId
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemId)
        classId, subclassId = classID, subclassID
    elseif GetItemInfoInstant then
        local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemId)
        classId, subclassId = classID, subclassID
    end
    local miscClass = (Enum and Enum.ItemClass and Enum.ItemClass.Miscellaneous) or 15
    local mountSub = (Enum and Enum.ItemMiscellaneousSubclass and Enum.ItemMiscellaneousSubclass.Mount) or 5
    if classId == miscClass and subclassId == mountSub then
        return true
    end
    local IC = _G.FluxItemClass
    local text = IC and IC.GetTooltipText and IC.GetTooltipText(itemId)
    text = type(text) == "string" and text:lower() or ""
    if text == "" then
        return false
    end
    local companionHint = text:find("companion", 1, true) or text:find("critter", 1, true)
    local mountHint = text:find("mount", 1, true) or text:find("rideable", 1, true) or text:find("ridable", 1, true)
    if companionHint and not mountHint then
        return false
    end
    return text:find("flying mount", 1, true)
        or text:find("ground mount", 1, true)
        or text:find("very fast mount", 1, true)
        or (text:find("summon", 1, true) and mountHint)
end

local function ScanUniqueMounts()
    local unique = UniqueBagItems()
    local mounts, seen = {}, {}
    for itemId, rec in pairs(unique) do
        itemId = tonumber(itemId)
        if itemId and not seen[itemId] and IsBagMountItem(itemId) then
            seen[itemId] = true
            local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
            local getItemIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
            local name, _, quality, _, _, _, _, _, _, icon = getItemInfo(itemId)
            mounts[#mounts + 1] = {
                itemId = itemId,
                name = name or ("Item " .. tostring(itemId)),
                icon = icon or (getItemIcon and getItemIcon(itemId)),
                quality = quality or 1,
                bag = rec and rec.bag,
                slot = rec and rec.slot,
                ["$itemId"] = itemId,
                ["$name"] = name,
                ["$iconTexture"] = icon,
            }
        end
    end
    return mounts
end

local function ScanMountItems(forceRefresh)
    local Spells = GetSpells()
    if Spells and Spells.ScanBagsForAllMountItems then
        return Spells.ScanBagsForAllMountItems(forceRefresh) or {}
    end
    if FluxItemDetection and FluxItemDetection.ScanBagsForAllMountItems then
        return FluxItemDetection.ScanBagsForAllMountItems(forceRefresh) or {}
    end
    return ScanUniqueMounts()
end

local function GetNow()
    return (GetTime and GetTime()) or 0
end

local function IsMountUsableInZone(itemId)
    local Spells = GetSpells()
    if Spells and Spells.IsMountUsableInCurrentZone then
        return Spells.IsMountUsableInCurrentZone(itemId)
    end
    if FluxItemDetection and FluxItemDetection.IsMountUsableInCurrentZone then
        return FluxItemDetection.IsMountUsableInCurrentZone(itemId)
    end
    return true
end

-- Same flying typeIDs as Mount.lua GetAllUsableMounts (plus modern skyriding).
local FLYING_MOUNT_TYPE_IDS = {
    [247] = true, -- flying
    [248] = true, -- both (ground + flying)
    [402] = true, -- dragonriding
    [407] = true, -- skyriding
    [424] = true, -- dragonriding / skyriding
    [426] = true,
    [436] = true,
    [437] = true,
    [444] = true,
    [445] = true,
}

local function IsMountFlyingByJournal(itemId)
    if not itemId or not C_MountJournal then
        return false
    end
    local mountID = itemId
    if C_MountJournal.GetMountFromItem then
        local fromItem = C_MountJournal.GetMountFromItem(itemId)
        if fromItem then
            mountID = fromItem
        end
    end
    if not mountID or not C_MountJournal.GetMountInfoExtraByID then
        return false
    end
    local _, _, _, _, mountTypeID = C_MountJournal.GetMountInfoExtraByID(mountID)
    return mountTypeID and FLYING_MOUNT_TYPE_IDS[mountTypeID] and true or false
end

local function IsMountFlying(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return false
    end
    local Spells = GetSpells()
    if Spells and Spells.IsMountFlyingByRidingRequirement then
        if Spells.IsMountFlyingByRidingRequirement(itemId) then
            return true
        end
    end
    if FluxItemDetection and FluxItemDetection.IsMountFlyingByRidingRequirement then
        if FluxItemDetection.IsMountFlyingByRidingRequirement(itemId) then
            return true
        end
    end
    return IsMountFlyingByJournal(itemId)
end

local function IsFlyableHere()
    local Spells = GetSpells()
    -- Bag items cannot use [flyable]; PreferFlying uses continent+outdoors when the API is missing.
    if Spells and Spells.PreferFlying then
        return Spells.PreferFlying()
    end
    if Spells and Spells.CanPreferFlyingMountItem then
        return Spells.CanPreferFlyingMountItem()
    end
    if FluxItemDetection and FluxItemDetection.PreferFlying then
        return FluxItemDetection.PreferFlying()
    end
    if FluxItemDetection and FluxItemDetection.CanPreferFlyingMountItem then
        return FluxItemDetection.CanPreferFlyingMountItem()
    end
    if Spells and Spells.IsInMountRestrictedInstance and Spells.IsInMountRestrictedInstance() then
        return false
    end
    if Spells and Spells.IsOutlandContinent then
        return Spells.IsOutlandContinent()
            and (not IsOutdoors or IsOutdoors())
    end
    if Spells and Spells.IsOutlandOrNorthrendContinent then
        return Spells.IsOutlandOrNorthrendContinent()
            and ((IsFlyableArea and IsFlyableArea()) or (not IsOutdoors or IsOutdoors()))
    end
    if Spells and Spells.IsFlyableHere then
        return Spells.IsFlyableHere()
    end
    if FluxItemDetection and FluxItemDetection.IsFlyableHere then
        return FluxItemDetection.IsFlyableHere()
    end
    if IsFlyableArea and IsFlyableArea() then
        return true
    end
    return false
end

--- Same rules as ResolveBestForMod / zone bag filter: air-only mounts are
--- temporarily unusable outside flyable zones (type 248 "both" still works on ground).
local function IsAirOnlyMount(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return false
    end
    if C_MountJournal and C_MountJournal.GetMountFromItem and C_MountJournal.GetMountInfoExtraByID then
        local mountID = C_MountJournal.GetMountFromItem(itemId)
        if mountID then
            local _, _, _, _, mountTypeID = C_MountJournal.GetMountInfoExtraByID(mountID)
            if mountTypeID == 248 then
                return false -- ground + flying hybrid: usable on ground
            end
            if mountTypeID and FLYING_MOUNT_TYPE_IDS[mountTypeID] then
                return true
            end
            if mountTypeID == 230 then
                return false
            end
        end
    end
    return IsMountFlying(itemId)
end

local function IsTemporarilyDisabledMount(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return false
    end
    local allSet = Items.GetBagMountItemsSet(true)
    if not allSet or not allSet[itemId] then
        return false
    end
    local usableSet = Items.GetBagMountItemsSet(false)
    if not usableSet or not usableSet[itemId] then
        return true
    end
    if IsAirOnlyMount(itemId) and not IsFlyableHere() then
        return true
    end
    return false
end

local function BuildFlyoutRows(mountItems, includeAllIgnoringZoneFilter)
    local items = {}
    for _, item in ipairs(mountItems) do
        local itemId = item.itemId or item["$itemId"]
        if itemId then
            if includeAllIgnoringZoneFilter or IsMountUsableInZone(itemId) then
                local name = item.name or item["$name"]
                local icon = item.icon or item["$iconTexture"]
                if not name or not icon then
                    local n, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemId)
                    name = name or n
                    icon = icon or itemIcon
                end
                items[#items + 1] = {
                    ["type"] = "item",
                    ["item"] = itemId,
                    ["$itemId"] = itemId,
                    ["$name"] = name or ("Item " .. tostring(itemId)),
                    ["$iconTexture"] = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
                    ["$isEquipment"] = false,
                }
            end
        end
    end
    return items
end

local function BuildSetFromList(items)
    local inBagsSet = {}
    for _, item in ipairs(items) do
        local itemId = item["$itemId"]
        if itemId then
            inBagsSet[itemId] = item
        end
    end
    return inBagsSet
end

local function IsMountTraitUnknown(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return false
    end
    local Spells = GetSpells()
    if Spells and Spells.IsMountTraitUnknown then
        return Spells.IsMountTraitUnknown(itemId) and true or false
    end
    if FluxItemDetection and FluxItemDetection.IsMountTraitUnknown then
        return FluxItemDetection.IsMountTraitUnknown(itemId) and true or false
    end
    return false
end

local function PickFromItemsPreferGround(items, preferGround)
    if not items or #items == 0 then
        return nil
    end
    if preferGround then
        -- Prefer known ground mounts; skip known flyers and unknown (cold tooltip).
        for _, item in ipairs(items) do
            local id = item["$itemId"]
            if id and not IsMountFlying(id) and not IsMountTraitUnknown(id) then
                return item
            end
        end
        -- Fallback: unknown traits (keep button usable after dungeon exit) — still
        -- prefer non-flying when we can tell.
        for _, item in ipairs(items) do
            local id = item["$itemId"]
            if id and not IsMountFlying(id) then
                return item
            end
        end
        -- Flyer-only bags: keep the button populated (usability greys if needed).
        -- Empty nil emptied the ExtraButton after dungeon/teleport exits.
        return items[1]
    end
    return items[1]
end

local function ResolveBestForMod(requestedModKey, items, inBagsSet)
    if not items or #items == 0 then
        return nil
    end

    -- Outside open-world Outland/Northrend, never pick a flying mount item.
    local preferGround = not IsFlyableHere()

    local function fromItem(item, modKey)
        if not item then
            return nil
        end
        return {
            itemId = item["$itemId"],
            name = item["$name"],
            icon = item["$iconTexture"],
            modKey = modKey or "nomod",
        }
    end

    if not FluxFlyoutFavorites then
        return fromItem(PickFromItemsPreferGround(items, preferGround), "nomod")
    end

    requestedModKey = requestedModKey or "nomod"

    local function acceptFav(favId, foundModKey)
        if not favId or not inBagsSet[favId] then
            return nil
        end
        if preferGround and IsMountFlying(favId) then
            return nil
        end
        return fromItem(inBagsSet[favId], foundModKey)
    end

    if FluxFlyoutFavorites.GetBestAvailableFavorite then
        local favId, foundModKey = FluxFlyoutFavorites.GetBestAvailableFavorite("Mount", requestedModKey, inBagsSet)
        local hit = acceptFav(favId, foundModKey)
        if hit then
            return hit
        end
        -- Fav was flying outside flyable zone: walk priority for a ground favorite in bags
        if preferGround then
            for _, modKey in ipairs(MOUNT_PRIORITY_ORDER) do
                local id = FluxFlyoutFavorites.GetFavorite and FluxFlyoutFavorites.GetFavorite("Mount", modKey)
                local groundHit = acceptFav(id, modKey)
                if groundHit then
                    return groundHit
                end
            end
        end
    else
        local exactFavId = FluxFlyoutFavorites.GetFavorite("Mount", requestedModKey)
        local hit = acceptFav(exactFavId, requestedModKey)
        if hit then
            return hit
        end
        for _, modKey in ipairs(MOUNT_PRIORITY_ORDER) do
            local favId = FluxFlyoutFavorites.GetFavorite("Mount", modKey)
            local groundHit = acceptFav(favId, modKey)
            if groundHit then
                return groundHit
            end
        end
    end

    return fromItem(PickFromItemsPreferGround(items, preferGround), "nomod")
end

--- Clear bag list + favorite maps. Call on bag/zone changes.
function Items.InvalidateCache()
    bagListCache = nil
    bagListCacheAll = nil
    bagListCacheTime = 0
    bagListCacheBagsGen = -1
    bagListCacheInstanceID = -1
    bagListCacheLocationKey = nil
    bagSetCache = nil
    bagSetCacheAll = nil
    Items.InvalidateFavoriteMap()
    local Spells = GetSpells()
    if Spells and Spells.InvalidateMountItemsCache then
        Spells.InvalidateMountItemsCache()
    elseif FluxItemDetection and FluxItemDetection.InvalidateMountItemsCache then
        FluxItemDetection.InvalidateMountItemsCache()
    elseif FluxItemDetection and FluxItemDetection.InvalidateAllMountItemsCache then
        FluxItemDetection.InvalidateAllMountItemsCache()
    end
end

--- Settle pulse: clear list caches / classify, keep mount trait tooltips warm.
function Items.InvalidateCacheForSettle()
    bagListCache = nil
    bagListCacheAll = nil
    bagListCacheTime = 0
    bagListCacheBagsGen = -1
    bagListCacheInstanceID = -1
    bagListCacheLocationKey = nil
    bagSetCache = nil
    bagSetCacheAll = nil
    Items.InvalidateFavoriteMap()
    local Spells = GetSpells()
    if Spells and Spells.InvalidateMountItemsCacheForSettle then
        Spells.InvalidateMountItemsCacheForSettle()
    elseif FluxItemDetection and FluxItemDetection.InvalidateMountItemsCacheForSettle then
        FluxItemDetection.InvalidateMountItemsCacheForSettle()
    elseif Spells and Spells.InvalidateMountItemsCache then
        -- Fallback: still rescan, but prefer soft path above.
        Spells.InvalidateMountItemsCache()
    end
end

--- Favorites DB changed — rebuild map without forcing a bag rescan.
function Items.InvalidateFavoriteMap()
    favMap = nil
    favMapDirty = true
end

function Items.RebuildFavoriteMap()
    local items = Items.GetBagMountItems()
    local inBagsSet = Items.GetBagMountItemsSet()
    local map = {}
    for _, modKey in ipairs(MOUNT_PRIORITY_ORDER) do
        map[modKey] = ResolveBestForMod(modKey, items, inBagsSet)
    end
    favMap = map
    favMapDirty = false
    return map
end

local function EnsureFavoriteMap()
    if favMapDirty or not favMap then
        Items.RebuildFavoriteMap()
    end
    return favMap
end

--- @param includeAllIgnoringZoneFilter boolean|nil
--- @return table[] flyout action rows
function Items.GetBagMountItems(includeAllIgnoringZoneFilter)
    local now = GetNow()
    local bagsGen = 0
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.GetBagGeneration then
        bagsGen = api.GetBagGeneration() or 0
    else
        local bags = _G.FluxInv and _G.FluxInv.Bags
        if bags and bags.GetGeneration then
            bagsGen = bags.GetGeneration() or 0
        end
    end
    local Spells = GetSpells()
    local instanceID = 0
    if Spells and Spells.GetCurrentInstanceMapID then
        instanceID = Spells.GetCurrentInstanceMapID() or 0
    elseif GetInstanceInfo then
        instanceID = tonumber((select(8, GetInstanceInfo()))) or 0
    end
    -- Distinguish open world vs any instance even when map ID is 0 briefly after zoning.
    if Spells and Spells.IsInMountRestrictedInstance and Spells.IsInMountRestrictedInstance() then
        instanceID = instanceID > 0 and instanceID or -1
    end
    local locationKey = nil
    if Spells and Spells.GetMountItemLocationKey then
        locationKey = Spells.GetMountItemLocationKey()
    elseif FluxItemDetection and FluxItemDetection.GetMountItemLocationKey then
        locationKey = FluxItemDetection.GetMountItemLocationKey()
    end
    -- During post-teleport settle, never reuse a cached flyable list.
    if Spells and Spells.IsMountItemLocationSettling and Spells.IsMountItemLocationSettling() then
        locationKey = (locationKey or "") .. "|settling"
    end

    if includeAllIgnoringZoneFilter then
        if bagListCacheAll
            and bagListCacheBagsGen == bagsGen
            and bagListCacheInstanceID == instanceID
            and bagListCacheLocationKey == locationKey
            and (now - bagListCacheTime) < BAG_LIST_CACHE_TTL
        then
            return bagListCacheAll
        end
    else
        if bagListCache
            and bagListCacheBagsGen == bagsGen
            and bagListCacheInstanceID == instanceID
            and bagListCacheLocationKey == locationKey
            and (now - bagListCacheTime) < BAG_LIST_CACHE_TTL
        then
            return bagListCache
        end
    end

    local mountItems = ScanMountItems()
    local items = BuildFlyoutRows(mountItems, includeAllIgnoringZoneFilter)
    bagListCacheTime = now
    bagListCacheBagsGen = bagsGen
    bagListCacheInstanceID = instanceID
    bagListCacheLocationKey = locationKey
    if includeAllIgnoringZoneFilter then
        bagListCacheAll = items
        bagSetCacheAll = nil
    else
        bagListCache = items
        bagSetCache = nil
        -- Zone-filtered list change invalidates favorite map
        favMapDirty = true
    end
    return items
end

function Items.GetBagMountItemsSet(includeAllIgnoringZoneFilter)
    if includeAllIgnoringZoneFilter then
        if bagSetCacheAll then
            return bagSetCacheAll
        end
        bagSetCacheAll = BuildSetFromList(Items.GetBagMountItems(true))
        return bagSetCacheAll
    end
    if bagSetCache then
        return bagSetCache
    end
    bagSetCache = BuildSetFromList(Items.GetBagMountItems())
    return bagSetCache
end

function Items.GetBestAvailableMount(requestedModKey)
    local map = EnsureFavoriteMap()
    requestedModKey = requestedModKey or "nomod"
    local hit = map[requestedModKey] or map["nomod"]
    if hit then
        return hit
    end
    -- Zone filter emptied the usable list (dungeon / instance). Keep an item
    -- on the Extra button instead of falling through to the charger placeholder.
    local allItems = Items.GetBagMountItems(true)
    if allItems and #allItems > 0 then
        return ResolveBestForMod(requestedModKey, allItems, Items.GetBagMountItemsSet(true))
    end
    return nil
end

function Items.GetAvailableFavorites()
    local result = {}
    local inBagsSet = Items.GetBagMountItemsSet()
    if not FluxFlyoutFavorites then
        return result
    end
    for _, modKey in ipairs(MOUNT_PRIORITY_ORDER) do
        local favId = FluxFlyoutFavorites.GetFavorite("Mount", modKey)
        if favId and inBagsSet[favId] then
            local item = inBagsSet[favId]
            result[modKey] = {
                itemId = favId,
                name = item["$name"],
                icon = item["$iconTexture"],
            }
        end
    end
    return result
end

--- Favorites that are physically in bags, including mounts temporarily disabled for the
--- current zone (same rules as the Extra mount button). Used by Binding browser.
--- @return table rows { modKey, itemId, name, icon, temporarilyDisabled }
--- @return table|nil effectiveNomod GetBestAvailableMount("nomod")
function Items.GetBindingFavoriteMounts()
    local rows = {}
    local allSet = Items.GetBagMountItemsSet(true)
    local effective = Items.GetBestAvailableMount("nomod")
    if not FluxFlyoutFavorites or not allSet then
        return rows, effective
    end
    for _, modKey in ipairs(MOUNT_PRIORITY_ORDER) do
        local favId = FluxFlyoutFavorites.GetFavorite and FluxFlyoutFavorites.GetFavorite("Mount", modKey)
        favId = tonumber(favId) or favId
        if favId and allSet[favId] then
            local item = allSet[favId]
            rows[#rows + 1] = {
                modKey = modKey,
                itemId = favId,
                name = item["$name"],
                icon = item["$iconTexture"],
                isFlying = IsMountFlying(favId) and true or false,
                isAirOnly = IsAirOnlyMount(favId) and true or false,
                temporarilyDisabled = IsTemporarilyDisabledMount(favId),
            }
        end
    end
    return rows, effective
end

function Items.IsMountFlying(itemId)
    return IsMountFlying(itemId)
end

function Items.IsFlyableHere()
    return IsFlyableHere()
end

function Items.IsTemporarilyDisabledMount(itemId)
    return IsTemporarilyDisabledMount(itemId)
end

function Items.GetFavoriteMount()
    local modKey = "nomod"
    if IsControlKeyDown and IsControlKeyDown() then
        if IsShiftKeyDown and IsShiftKeyDown() then
            if IsAltKeyDown and IsAltKeyDown() then modKey = "ctrl+shift+alt" else modKey = "ctrl+shift" end
        elseif IsAltKeyDown and IsAltKeyDown() then modKey = "ctrl+alt" else modKey = "ctrl" end
    elseif IsShiftKeyDown and IsShiftKeyDown() then
        if IsAltKeyDown and IsAltKeyDown() then modKey = "shift+alt" else modKey = "shift" end
    elseif IsAltKeyDown and IsAltKeyDown() then
        modKey = "alt"
    end
    return Items.GetBestAvailableMount(modKey)
end

function Items.GetMountItemId(mountName)
    if not mountName then
        return nil
    end
    for _, item in ipairs(Items.GetBagMountItems()) do
        if item["$name"] == mountName then
            return item["$itemId"]
        end
    end
    return nil
end

function Items.BuildMountItemFlyoutActions()
    local actions = Items.GetBagMountItems()
    table.sort(actions, function(a, b)
        return (a["$name"] or "") < (b["$name"] or "")
    end)
    if FluxNCFlyoutOptions and FluxNCFlyoutOptions.ApplyMountItemActions then
        actions = FluxNCFlyoutOptions.ApplyMountItemActions(actions)
    end
    return actions
end

function Items.HasMountItemFlyout()
    local actions = Items.BuildMountItemFlyoutActions()
    return actions and #actions > 1
end

function Items.OnMountPickedFromFlyout(actionData)
    if not actionData then
        return
    end
    local name = actionData["$name"]
    if not name then
        return
    end
    local icon = actionData["$iconTexture"] or actionData["$icon"]
    if not icon and actionData["$itemId"] then
        icon = GetItemIcon and GetItemIcon(actionData["$itemId"])
    end
    if Module.LockToMount then
        Module.LockToMount(name, icon, nil)
    end
end

function Items.ShowMountItemFlyout()
    if Module.ClearMountButtonCheckedState then
        Module.ClearMountButtonCheckedState()
    end
    local btn = Module._button
    if not btn or not btn.Widget then
        return
    end
    local actions = Items.BuildMountItemFlyoutActions()
    if not actions or #actions <= 1 then
        return
    end
    if FluxFlyoutFrame and FluxFlyoutFrame.ShowFlyout then
        local config = {
            direction = "UP",
            onActionUse = Items.OnMountPickedFromFlyout,
        }
        if FluxGridFlyout and FluxGridFlyout.OpenForWidget then
            FluxGridFlyout.OpenForWidget(btn.Widget, actions, config)
        else
            FluxFlyoutFrame.ShowFlyout(btn.Widget, actions, config)
        end
    end
end

function Items.RefreshFlyoutIfOpen()
    local btn = Module._button
    if not btn or not btn.Widget then
        return
    end
    if not FluxFlyoutFrame or not FluxFlyoutFrame.IsFlyoutOpenFor then
        return
    end
    if not FluxFlyoutFrame.IsFlyoutOpenFor(btn.Widget) then
        return
    end
    local actions = Items.BuildMountItemFlyoutActions()
    if not actions or #actions <= 1 then
        FluxFlyoutFrame.CloseFlyoutFor(btn.Widget)
        return
    end
    FluxFlyoutFrame.CloseFlyoutFor(btn.Widget)
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, function()
            if InCombatLockdown() then
                return
            end
            FluxFlyoutFrame.ShowFlyout(btn.Widget, actions, {
                direction = "UP",
                onActionUse = Items.OnMountPickedFromFlyout,
            })
        end)
    else
        FluxFlyoutFrame.ShowFlyout(btn.Widget, actions, {
            direction = "UP",
            onActionUse = Items.OnMountPickedFromFlyout,
        })
    end
end

function Items.HasAnyMountInBags()
    local list = Items.GetBagMountItems(true)
    return list and #list > 0
end

-- Attach onto FluxNCMount so proxies / Mount.lua / options panel keep working
Module.GetBagMountItems = Items.GetBagMountItems
Module.GetMountItemId = Items.GetMountItemId
Module.BuildMountItemFlyoutActions = Items.BuildMountItemFlyoutActions
Module.HasMountItemFlyout = Items.HasMountItemFlyout
Module.OnMountPickedFromFlyout = Items.OnMountPickedFromFlyout
Module.ShowMountItemFlyout = Items.ShowMountItemFlyout
Module.RefreshFlyoutIfOpen = Items.RefreshFlyoutIfOpen
Module.GetBagMountItemsSet = Items.GetBagMountItemsSet
Module.GetBestAvailableMount = Items.GetBestAvailableMount
Module.GetAvailableFavorites = Items.GetAvailableFavorites
Module.GetBindingFavoriteMounts = Items.GetBindingFavoriteMounts
Module.GetFavoriteMount = Items.GetFavoriteMount
Module.HasAnyMountInBags = Items.HasAnyMountInBags
Module.InvalidateBagMountItemsCache = Items.InvalidateCache
Module.IsMountFlying = Items.IsMountFlying
Module.IsFlyableHere = Items.IsFlyableHere
Module.IsTemporarilyDisabledMount = Items.IsTemporarilyDisabledMount

_G.FluxNCMountItems = Items
_G.FluxNCMount = Module
return Items
