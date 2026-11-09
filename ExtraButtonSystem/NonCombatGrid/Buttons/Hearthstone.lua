--[[
    ExtraButtonSystem/NonCombatGrid/Buttons/Hearthstone.lua
    Hearthstone preset button module (FluxHearthConfig + optional teleport-item flyout)

    Classic mode (no matching teleport items in inventory):
    - Item/toy from FluxHearthConfig (6948 fallback)
    - Right-click: Toy Box when supported

    Teleport mode (cloak / other teleports + one configured hearthstone):
    - Config swaps the hearthstone option (does not add a flyout of all hearth toys)
    - Flyout (#items > 1): Right-click flyout; Middle-click Toy Box when supported
    - Single item (no flyout): Right-click Toy Box when supported
    - Mount-style macro modifiers, favorites, FLUXGRIDHEARTH keybind

    Compatible with all WoW versions via FluxAPICompat.lua
]]

-- Create namespace
FluxNCHearthstone = FluxNCHearthstone or {}
local Module = FluxNCHearthstone

local BAG_OWNED_OPTS = { bags = true, bank = false, warband = false, equipped = true }

local function ShouldHoldItemIdentity()
    local B = _G.FluxEBSConsumableBridge
    if B and B.ShouldHoldItemIdentity then
        return B.ShouldHoldItemIdentity() and true or false
    end
    local Best = _G.FluxConsumableBest
    if Best and Best.ShouldSoftHoldOwned then
        return Best.ShouldSoftHoldOwned() and true or false
    end
    local api = _G.Flux and _G.Flux.Inventory
    if api and api.SnapshotLooksCollapsed and api.SnapshotLooksCollapsed() then
        return true
    end
    return false
end

local function GetBagItemCount(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return 0
    end
    local api = _G.Flux and _G.Flux.Inventory
    if api and api.GetLiveCount then
        local n = api.GetLiveCount(itemId, BAG_OWNED_OPTS)
        if n and n > 0 then
            return n
        end
    end
    local inv = _G.FluxInv
    if inv then
        if inv.GetLiveCount then
            local n = inv.GetLiveCount(itemId, BAG_OWNED_OPTS)
            if n and n > 0 then
                return n
            end
        end
        if inv.GetCount then
            local n = inv.GetCount(itemId, BAG_OWNED_OPTS)
            if n and n > 0 then
                return n
            end
        end
        if inv.Bags and inv.Bags.GetCount then
            local n = inv.Bags.GetCount(itemId)
            if n and n > 0 then
                return n
            end
        end
    end
    if api and api.GetCount then
        local n = api.GetCount(itemId, BAG_OWNED_OPTS)
        if n and n > 0 then
            return n
        end
    end
    if C_Item and C_Item.GetItemCount then
        return C_Item.GetItemCount(itemId, false, false, false, false) or 0
    end
    if GetItemCount then
        return GetItemCount(itemId, false) or 0
    end
    return 0
end

local function IsItemEquippedLocal(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return false
    end
    if GetInventoryItemID then
        for slot = 1, 19 do
            if GetInventoryItemID("player", slot) == itemId then
                return true
            end
        end
    end
    local api = _G.Flux and _G.Flux.Inventory
    if api and api.GetCount then
        return (api.GetCount(itemId, { bags = false, bank = false, warband = false, equipped = true }) or 0) > 0
    end
    return false
end

-- FluxInv.Spells is unused; FluxNCItemDetection has no bag probe. Use Inventory + live counts.
local function PlayerHasItemInInventory(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return false
    end
    if IsItemEquippedLocal(itemId) then
        return true
    end
    if (GetBagItemCount(itemId) or 0) > 0 then
        return true
    end
    local api = _G.Flux and _G.Flux.Inventory
    if api and api.GetLiveCount then
        local n = api.GetLiveCount(itemId, BAG_OWNED_OPTS)
        if n and n > 0 then
            return true
        end
    end
    if C_Item and C_Item.GetItemCount then
        local n = C_Item.GetItemCount(itemId, false, false, false, false)
        if n and n > 0 then
            return true
        end
    elseif GetItemCount then
        local n = GetItemCount(itemId)
        if n and n > 0 then
            return true
        end
    end
    return false
end

-- Local references
local Detection = nil  -- FluxNCItemDetection soft-shim from FluxInv.Spells

-- Constants
Module.DEFAULT_ITEM_ID = 6948
Module.COLUMN_PRIORITY = 1
Module.ORDER = 1

-- State
Module._grid = nil
Module._button = nil
Module._registered = false
Module._teleportModeActive = false

-- Lock state (for sticky teleport item feature)
Module._lockedItem = nil         -- { itemId, name, icon, isEquipment, isEquipped }
Module._isLocked = false
Module._isCasting = false
Module._pendingEquipItemId = nil -- Item waiting to be equipped
Module._isEquipping = false
Module._pendingLockItem = nil    -- Item to lock to when cast starts { itemId, name, icon, isEquipment, isEquipped }
Module._pendingLockTimestamp = nil  -- Timestamp when pending lock was set (for timeout cleanup)
Module._pendingUnlock = false
Module._castLockSpellId = nil

-- Teleport items cache
Module._teleportItemsCache = nil
Module._teleportItemsCacheTime = 0
local TELEPORT_CACHE_DURATION = 5

-- Retail-style clients with toy box + mount journal: ring follows FluxHearthConfig character vs account (raw class vs no tint), not General → Appearance.
local function HasToyAndMountCollections()
    return FLUX_API and FLUX_API.hasToyBox and FLUX_API.hasC_MountJournal
end

local function ApplyHearthButtonVisualStyle(btn)
    if not btn then return end
    if HasToyAndMountCollections() and FluxButtonUtil and FluxButtonUtil.ApplyNonCombatSmartCollectionButtonStyle then
        local useChar = Module.IsCharacterSpecific and Module.IsCharacterSpecific() or false
        FluxButtonUtil:ApplyNonCombatSmartCollectionButtonStyle(btn, useChar)
        return
    end
    local scope = Module.IsCharacterSpecific() and "character" or "account"
    if FluxNonCombatGrid and FluxNonCombatGrid.ApplyButtonStyle then
        FluxNonCombatGrid.ApplyButtonStyle(btn, scope)
    elseif FluxButtonUtil and FluxButtonUtil.ApplyButtonStyle then
        FluxButtonUtil:ApplyButtonStyle(btn, scope)
    end
end

-- Icon protection state
local _iconManagedByModule = false
local _lastSetIcon = nil

-- Timer shim for legacy clients
local Timer = C_Timer or {}
if not Timer.After then
    function Timer.After(delay, cb)
        local f = CreateFrame("Frame")
        local t = 0
        f:SetScript("OnUpdate", function(self, dt)
            t = t + dt
            if t >= (tonumber(delay) or 0) then
                self:SetScript("OnUpdate", nil)
                pcall(cb)
                self:Hide()
            end
        end)
        return f
    end
end

-- ============================================================================
-- ITEM DETECTION
-- ============================================================================

-- Splinter of Atiesh is a quest fragment; Atiesh itself stays in the flyout.
local TELEPORT_ITEM_EXCLUDED_IDS = {
    [22726] = true, -- Splinter of Atiesh
}

local function IsExcludedTeleportItem(itemId, name)
    local Spells = _G.FluxInv and _G.FluxInv.Spells
    if Spells and Spells.IsExcludedTeleportItem then
        return Spells.IsExcludedTeleportItem(itemId, name)
    end
    itemId = tonumber(itemId)
    if itemId and TELEPORT_ITEM_EXCLUDED_IDS[itemId] then
        return true
    end
    if type(name) == "string" and name ~= "" then
        if string.lower(name):find("splinter of atiesh", 1, true) then
            return true
        end
    end
    return false
end

local function ScanTeleportItemsLocal(patterns)
    patterns = patterns or {
        "Atiesh",
        "Hearthstone of the Dawn",
        "Beacon of Hydraxis",
        "Aragriar's Whimsical World Warper",
        "Scroll of Liminal Passage",
        "Hearthstone",
    }
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    local unique = api and api.GetUniqueItems and api.GetUniqueItems({
        bags = true, bank = false, warband = false, equipped = true,
    }) or {}
    local out, seen = {}, {}
    local knownIds = {
        [243229] = true, -- Hearthstone of the Dawn (place teleport)
        [6948] = true,   -- Hearthstone
    }
    local hearthId = Module.GetHearthItemId and Module.GetHearthItemId()
    if hearthId then
        knownIds[hearthId] = true
    end
    for itemId, rec in pairs(unique) do
        itemId = tonumber(itemId)
        if itemId and not seen[itemId] then
            local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
            local getItemIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
            local name, _, _, _, _, _, _, _, _, icon = getItemInfo(itemId)
            if not IsExcludedTeleportItem(itemId, name) then
                local match = knownIds[itemId]
                if not match and name then
                    local lower = name:lower()
                    for i = 1, #patterns do
                        local lp = string.lower(patterns[i])
                        if lp == "atiesh" then
                            if not lower:find("splinter of atiesh", 1, true) and lower:find(lp, 1, true) then
                                match = true
                                break
                            end
                        elseif lower:find(lp, 1, true) then
                            match = true
                            break
                        end
                    end
                end
                if match then
                    seen[itemId] = true
                    out[#out + 1] = {
                        itemId = itemId,
                        name = name or ("item:" .. tostring(itemId)),
                        icon = icon or (getItemIcon and getItemIcon(itemId)) or "Interface\\Icons\\INV_Misc_QuestionMark",
                        isEquipment = (C_Item and C_Item.IsEquippableItem and C_Item.IsEquippableItem(itemId)) or false,
                        isEquipped = rec and rec.bag == nil,
                        bag = rec and rec.bag,
                        slot = rec and rec.slot,
                    }
                end
            end
        end
    end
    return out
end

-- Get ItemDetection module (always refresh reference to handle load order)
local function GetDetection()
    Detection = _G.FluxNCItemDetection
    if Detection and Detection.ScanForTeleportItems then
        Detection.PlayerHasItemInInventory = Detection.PlayerHasItemInInventory or PlayerHasItemInInventory
        Detection.IsItemEquipped = Detection.IsItemEquipped or IsItemEquippedLocal
        return Detection
    end
    local Spells = _G.FluxInv and _G.FluxInv.Spells
    if Spells and Spells.ScanForTeleportItems then
        Spells.PlayerHasItemInInventory = Spells.PlayerHasItemInInventory or PlayerHasItemInInventory
        Spells.IsItemEquipped = Spells.IsItemEquipped or IsItemEquippedLocal
        return Spells
    end
    return {
        ScanForTeleportItems = function(_, forceRefresh)
            return ScanTeleportItemsLocal()
        end,
        PlayerHasItemInInventory = PlayerHasItemInInventory,
        IsItemEquipped = IsItemEquippedLocal,
    }
end

-- Classic hearthstone item (when no teleport items are detected)
function Module.GetHearthItemId()
    if _G.FluxHearthConfig and _G.FluxHearthConfig.GetHearthItem then
        local ok, itemId = pcall(_G.FluxHearthConfig.GetHearthItem)
        if ok and tonumber(itemId) then
            return tonumber(itemId)
        end
    end
    return Module.DEFAULT_ITEM_ID
end

-- Owned as Toy Box entry (hearth toys are not bag items).
local function PlayerOwnsHearthToy(itemId)
    itemId = tonumber(itemId)
    if not itemId or not PlayerHasToy then
        return false
    end
    return PlayerHasToy(itemId) and true or false
end

-- Place-specific teleports that contain "Hearthstone" in the name but are NOT the
-- bindable hearth / hearth toys (must stay in the teleport flyout).
local PLACE_TELEPORT_ITEM_IDS = {
    [243229] = true, -- Hearthstone of the Dawn (SoD — Light's Hope Chapel)
}

-- Entries that config should replace (one hearthstone option, not a flyout of every toy).
local function IsReplaceableHearthstoneEntry(item)
    if not item then return false end
    local itemId = tonumber(item.itemId)
    -- Place teleports must never be treated as the configured hearth option.
    if itemId and PLACE_TELEPORT_ITEM_IDS[itemId] then
        return false
    end
    if item.isToy then
        return true
    end
    if itemId then
        if itemId == (Module.DEFAULT_ITEM_ID or 6948) or itemId == 6948 then
            return true
        end
        if _G.FluxHearthConfig and _G.FluxHearthConfig.IsHearthstoneToy
            and _G.FluxHearthConfig.IsHearthstoneToy(itemId) then
            return true
        end
        if PlayerOwnsHearthToy(itemId) then
            return true
        end
    end
    -- Exact name only — do NOT substring-match "Hearthstone of the Dawn" etc.
    local n = item.name and tostring(item.name):lower() or ""
    if n == "hearthstone" then
        return true
    end
    return false
end

local function ResolveHearthItemDisplay(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return nil, nil
    end
    local name, icon
    if C_ToyBox and C_ToyBox.GetToyInfo then
        -- Returns: itemID, toyName, icon, ...
        local ok, _, toyName, toyIcon = pcall(C_ToyBox.GetToyInfo, itemId)
        if ok and type(toyName) == "string" then
            name, icon = toyName, toyIcon
        end
    end
    if not name and GetItemInfo then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemId)
        name = itemName
        icon = icon or itemIcon
    end
    if not icon then
        icon = (GetItemIcon and GetItemIcon(itemId)) or "Interface\\Icons\\INV_Misc_Rune_01"
    end
    return name, icon
end

local function BuildConfiguredHearthEntry(hearthId, det)
    local defaultId = Module.DEFAULT_ITEM_ID or 6948
    hearthId = tonumber(hearthId) or defaultId
    local function owned(id)
        id = tonumber(id)
        if not id then
            return false, false
        end
        if PlayerOwnsHearthToy(id) then
            return true, true
        end
        if PlayerHasItemInInventory(id) then
            return true, false
        end
        if det and det.PlayerHasItemInInventory and det.PlayerHasItemInInventory(id) then
            return true, false
        end
        return false, false
    end
    local has, isToy = owned(hearthId)
    if not has and hearthId ~= defaultId then
        hearthId = defaultId
        has, isToy = owned(hearthId)
    end
    if not has then
        return nil
    end
    local name, icon = ResolveHearthItemDisplay(hearthId)
    if not name and GetItemInfo then
        name = GetItemInfo(hearthId)
    end
    if not name then
        name = (hearthId == defaultId) and "Hearthstone" or ("item:" .. tostring(hearthId))
    end
    local isEquipment = false
    if not isToy then
        if C_Item and C_Item.IsEquippableItem then
            isEquipment = C_Item.IsEquippableItem(hearthId) and true or false
        elseif IsEquippableItem then
            isEquipment = IsEquippableItem(hearthId) and true or false
        end
    end
    local equipped = false
    if not isToy then
        if det and det.IsItemEquipped then
            equipped = det.IsItemEquipped(hearthId) and true or false
        else
            equipped = IsItemEquippedLocal(hearthId)
        end
    end
    return {
        itemId = hearthId,
        name = name,
        icon = icon or (GetItemIcon and GetItemIcon(hearthId)) or "Interface\\Icons\\INV_Misc_Rune_01",
        isEquipment = isEquipment,
        isEquipped = equipped,
        isToy = isToy and true or false,
        bag = nil,
        slot = nil,
    }
end

function Module.IsCharacterSpecific()
    if _G.FluxHearthConfig and _G.FluxHearthConfig.IsUsingCharacterSpecific then
        return _G.FluxHearthConfig.IsUsingCharacterSpecific()
    end
    return true
end

-- Client has Toy Box / Collections journal
local function HasToyBoxUI()
    return FLUX_API and (FLUX_API.hasToyBox or FLUX_API.hasToggleCollectionsJournal)
end

-- Get all available teleport items
function Module.GetTeleportItems(forceRefresh)
    local det = GetDetection()
    if not det then
        if ShouldHoldItemIdentity() and Module._lastGoodTeleportItems and #Module._lastGoodTeleportItems > 0 then
            return Module._lastGoodTeleportItems
        end
        return {}
    end
    
    -- Check if function exists (load order safety)
    if not det.ScanForTeleportItems or type(det.ScanForTeleportItems) ~= "function" then
        if ShouldHoldItemIdentity() and Module._lastGoodTeleportItems and #Module._lastGoodTeleportItems > 0 then
            return Module._lastGoodTeleportItems
        end
        return {}
    end
    
    -- Check cache
    local now = GetTime()
    if not forceRefresh and Module._teleportItemsCache and 
       (now - Module._teleportItemsCacheTime) < TELEPORT_CACHE_DURATION then
        if #Module._teleportItemsCache > 0 then
            return Module._teleportItemsCache
        end
        if ShouldHoldItemIdentity() and Module._lastGoodTeleportItems and #Module._lastGoodTeleportItems > 0 then
            return Module._lastGoodTeleportItems
        end
        return Module._teleportItemsCache
    end
    
    local scanned = det.ScanForTeleportItems(nil, forceRefresh) or {}
    local hearthId = Module.GetHearthItemId()

    -- Drop bag/name hearthstones — config swaps in a single hearth option (no hearth flyout).
    local items = {}
    local seenIds = {}
    local droppedHearth = nil
    for _, it in ipairs(scanned) do
        if IsExcludedTeleportItem(it.itemId, it.name) then
            -- Splinter of Atiesh must never appear in the flyout or options list.
        elseif IsReplaceableHearthstoneEntry(it) then
            if not droppedHearth and it.itemId then
                droppedHearth = it
            end
        elseif it.itemId then
            if not seenIds[it.itemId] then
                table.insert(items, it)
                seenIds[it.itemId] = true
            end
        else
            table.insert(items, it)
        end
    end

    local hearthEntry = BuildConfiguredHearthEntry(hearthId, det)
    if not hearthEntry and droppedHearth then
        hearthEntry = droppedHearth
    end
    if hearthEntry and IsExcludedTeleportItem(hearthEntry.itemId, hearthEntry.name) then
        hearthEntry = nil
    end
    if hearthEntry and not seenIds[hearthEntry.itemId] then
        table.insert(items, 1, hearthEntry)
        seenIds[hearthEntry.itemId] = true
    elseif hearthEntry and seenIds[hearthEntry.itemId] then
        -- Already present as non-hearth scan hit (unlikely); move to front
        for i, item in ipairs(items) do
            if item.itemId == hearthEntry.itemId then
                if i > 1 then
                    local moved = table.remove(items, i)
                    table.insert(items, 1, moved)
                end
                break
            end
        end
    end
    
    if #items > 1 then
        -- Keep configured hearth first; sort the rest by name
        local frontId = (hearthEntry and hearthEntry.itemId) or hearthId
        local hearthFirst = nil
        local rest = {}
        for _, it in ipairs(items) do
            if frontId and it.itemId == frontId and not hearthFirst then
                hearthFirst = it
            else
                table.insert(rest, it)
            end
        end
        table.sort(rest, function(a, b)
            return (a.name or "") < (b.name or "")
        end)
        items = {}
        if hearthFirst then
            table.insert(items, hearthFirst)
        end
        for _, it in ipairs(rest) do
            table.insert(items, it)
        end
    end
    
    Module._teleportItemsCache = items
    Module._teleportItemsCacheTime = now
    if #items > 0 then
        Module._lastGoodTeleportItems = items
    elseif ShouldHoldItemIdentity() and Module._lastGoodTeleportItems and #Module._lastGoodTeleportItems > 0 then
        return Module._lastGoodTeleportItems
    end
    
    return items
end

-- Check if player has any teleport items
function Module.HasTeleportItems()
    local items = Module.GetTeleportItems()
    if items and #items > 0 then
        return true
    end
    if ShouldHoldItemIdentity() and Module._lastGoodTeleportItems and #Module._lastGoodTeleportItems > 0 then
        return true
    end
    return false
end

-- Get count of teleport items
function Module.GetTeleportItemCount()
    local items = Module.GetTeleportItems()
    return items and #items or 0
end

-- Invalidate teleport item cache
function Module.InvalidateTeleportCache()
    Module._teleportItemsCache = nil
    Module._teleportItemsCacheTime = 0
    
    local det = GetDetection()
    if det and det.InvalidateTeleportItemCache then
        det.InvalidateTeleportItemCache()
    end
end

-- Item spell id (Mount.lua / TeleportPortal.lua use spell id for overlays)
local function GetSpellIDForItem(itemId)
    if not itemId then return nil end
    if C_Item and C_Item.GetItemSpell then
        local _, sid = C_Item.GetItemSpell(itemId)
        return sid
    end
    if GetItemSpell then
        local _, _, sid = GetItemSpell(itemId)
        return sid
    end
    return nil
end

local function SetCastLockSpellId(spellID)
    Module._castLockSpellId = spellID
    local btn = Module._button
    local widget = btn and btn.Widget
    if widget then
        widget._fluxCastLockSpellId = spellID
    end
end

local function ClearCastLockSpellId()
    SetCastLockSpellId(nil)
end

local function ForceClearButtonCastVFX()
    local btn = Module._button
    local widget = btn and btn.Widget
    if not widget then return end
    local scf = widget.SpellCastAnimFrame
    if scf and scf:IsShown() then
        scf:Hide()
    end
    local intr = widget.InterruptDisplay
    if intr and intr:IsShown() then
        intr:Hide()
    end
    local trf = widget.TargetReticleAnimFrame
    if trf and trf:IsShown() then
        trf:Hide()
    end
end

-- TeleportPortal.lua: spell proc overlay on the main button while locked
local function HideTeleportButtonSpellOverlayGlow(btn)
    if not btn or not btn.Widget then return end
    if ActionButton_HideOverlayGlow then
        pcall(ActionButton_HideOverlayGlow, btn.Widget)
    end
    if LibStub then
        local LBG = LibStub("LibButtonGlow-1.0", true)
        if LBG and LBG.HideOverlayGlow then
            pcall(LBG.HideOverlayGlow, btn.Widget)
        end
    end
end

local function ApplyTeleportButtonSpellOverlayGlow(btn, itemId)
    if not btn or not btn.Widget or not itemId then return end
    local spellID = GetSpellIDForItem(itemId)
    if not spellID then return end
    if ActionButton_ShowOverlayGlow and btn.Widget.ShowOverlayGlow then
        if IsSpellOverlayed and IsSpellOverlayed(spellID) then
            ActionButton_ShowOverlayGlow(btn.Widget)
        end
    end
    if LibStub then
        local LBG = LibStub("LibButtonGlow-1.0", true)
        if LBG and LBG.ShowOverlayGlow then
            if IsSpellOverlayed and IsSpellOverlayed(spellID) then
                LBG.ShowOverlayGlow(btn.Widget)
            end
        end
    end
end

-- ============================================================================
-- LOCK SYSTEM (Combat & Equipment)
-- ============================================================================

-- Lock the button to a specific teleport item
function Module.LockToItem(itemId, itemName, itemIcon, isEquipment, isEquipped)
    if not itemId then return end
    local lockSpellId = GetSpellIDForItem(itemId)

    Module._lockedItem = {
        itemId = itemId,
        name = itemName,
        icon = itemIcon,
        isEquipment = isEquipment or false,
        isEquipped = isEquipped or false,
    }
    Module._isLocked = true
    Module._pendingEquipItemId = nil
    Module._pendingLockItem = nil  -- Clear pending lock when we actually lock
    SetCastLockSpellId(lockSpellId)
    
    -- Disable icon protection while locked
    _iconManagedByModule = false
    
    -- Update button immediately
    if not InCombatLockdown() then
        Module.UpdateLockedState()
    end
end

-- Flyout pick: FluxFlyoutFrame calls config.onActionUse (same pattern as Mount.lua OnMountPickedFromFlyout)
function Module.OnTeleportItemPickedFromFlyout(actionData)
    if not actionData or not Module.HasTeleportItems() then return end
    local id = actionData["$itemId"] or actionData["$itemID"]
    if not id then return end
    local name = actionData["$name"] or actionData.name
    local icon = actionData["$iconTexture"] or actionData.icon
    if not icon and GetItemIcon then
        icon = GetItemIcon(id)
    end
    local eq = actionData["$isEquipment"] or false
    local eqd = actionData["$isEquipped"] or false
    Module.LockToItem(id, name, icon, eq, eqd)
end

-- Unlock the button and restore normal behavior
function Module.Unlock()
    if not Module._isLocked then return end
    
    Module._lockedItem = nil
    Module._isLocked = false
    Module._isCasting = false
    Module._pendingEquipItemId = nil
    Module._isEquipping = false
    Module._pendingLockItem = nil
    Module._pendingLockTimestamp = nil
    Module._pendingUnlock = false
    ClearCastLockSpellId()
    
    -- Clear cached icon
    _lastSetIcon = nil
    
    local btn = Module._button
    HideTeleportButtonSpellOverlayGlow(btn)
    ForceClearButtonCastVFX()
    
    -- Update button immediately
    if not InCombatLockdown() then
        Module.Update()
    end
    
    Module.RefreshTooltip()
end

-- Check if button is locked
function Module.IsLocked()
    return Module._isLocked and Module._lockedItem ~= nil
end

-- Get locked item info
function Module.GetLockedItem()
    return Module._lockedItem
end

-- Update button to reflect locked state
function Module.UpdateLockedState()
    local btn = Module._button
    if not btn or not Module._isLocked or not Module._lockedItem then return end
    if InCombatLockdown() then return end
    
    local item = Module._lockedItem
    local itemId = item.itemId
    local itemName = item.name
    local itemIcon = item.icon
    local isEquipment = item.isEquipment
    local isEquipped = item.isEquipped
    
    -- Build macro based on equipment status (use item: format)
    local macroText
    if itemId then
        if isEquipment and not isEquipped then
            -- Equipment not equipped - macro to equip it
            macroText = string.format([[#showtooltip item:%d
/equip item:%d]], itemId, itemId)
        else
            -- Item is equipped or not equipment - use it
            macroText = string.format([[#showtooltip item:%d
/use item:%d]], itemId, itemId)
        end
    else
        if isEquipment and not isEquipped then
            macroText = string.format([[#showtooltip %s
/equip %s]], itemName, itemName)
        else
            macroText = string.format([[#showtooltip %s
/use %s]], itemName, itemName)
        end
    end
    
    if btn.SetAction then
        btn:SetAction("macrotext", macroText)
    elseif btn.Widget then
        btn.Widget:SetAttribute("type", "macro")
        btn.Widget:SetAttribute("macrotext", macroText)
    end
    
    -- Update texture (TeleportPortal.lua: match locked spell/item on main button)
    if itemIcon then
        _lastSetIcon = itemIcon
        btn.Texture = itemIcon
        if btn.WIcon then
            local savedManaged = _iconManagedByModule
            _iconManagedByModule = false
            btn.WIcon:SetTexture(itemIcon)
            btn.WIcon:SetDesaturated(isEquipment and not isEquipped)
            btn.WIcon:SetVertexColor(1, 1, 1, 1)
            btn.WIcon:Show()
            _iconManagedByModule = savedManaged
        end
        if btn.Widget and btn.Widget.icon then
            btn.Widget.icon:SetTexture(itemIcon)
            btn.Widget.icon:SetDesaturated(isEquipment and not isEquipped)
            btn.Widget.icon:Show()
        end
        if btn.Widget and btn.Widget.Icon then
            btn.Widget.Icon:SetTexture(itemIcon)
            btn.Widget.Icon:Show()
        end
    end
    
    if itemId then
        ApplyTeleportButtonSpellOverlayGlow(btn, itemId)
    end
    
    -- Update usability
    if btn.UpdateUsable then
        btn:UpdateUsable()
    end
    
    Module.RefreshTooltip()
end

-- ============================================================================
-- EQUIPMENT HANDLING
-- ============================================================================

-- Check if item is currently equipped
function Module.IsItemEquipped(itemId)
    if not itemId then return false end
    
    local det = GetDetection()
    if det and det.IsItemEquipped then
        return det.IsItemEquipped(itemId)
    end
    
    -- Fallback check
    for slot = 1, 19 do
        local equippedItemId = GetInventoryItemID("player", slot)
        if equippedItemId and equippedItemId == itemId then
            return true
        end
    end
    return false
end

-- Handle equip-before-use logic for equipment items
-- Returns true if we started equipping (caller should not use item yet)
function Module.HandleEquipmentClick(itemId, itemName, itemIcon)
    if not itemId then return false end
    
    -- Check if already equipped
    if Module.IsItemEquipped(itemId) then
        return false  -- Already equipped, can use directly
    end
    
    -- Need to equip first
    if InCombatLockdown() then
        print("|cff00ffffFluxUI:|r Cannot equip items in combat")
        return true  -- Block usage in combat
    end
    
    -- Set pending equip
    Module._pendingEquipItemId = itemId
    Module._isEquipping = true
    
    -- Lock to this item (shows it on button)
    Module.LockToItem(itemId, itemName, itemIcon, true, false)
    
    -- Equip the item
    EquipItemByName(itemName)
    
    return true  -- Equipping started, don't use yet
end

-- Called when equipment changes - check if pending equip completed
function Module.OnEquipmentChanged()
    if not Module._pendingEquipItemId or not Module._isEquipping then return end
    
    local itemId = Module._pendingEquipItemId
    
    -- Check if the item is now equipped
    if Module.IsItemEquipped(itemId) then
        Module._isEquipping = false
        
        -- Update locked state to reflect equipped status
        if Module._lockedItem and Module._lockedItem.itemId == itemId then
            Module._lockedItem.isEquipped = true
            if not InCombatLockdown() then
                Module.UpdateLockedState()
            end
        end
        
        -- Clear pending
        Module._pendingEquipItemId = nil
    end
end

-- ============================================================================
-- TELEPORT FLYOUT
-- ============================================================================

-- Build flyout actions for teleport items
function Module.BuildTeleportFlyoutActions(forceRefresh)
    local items = Module.GetTeleportItems(forceRefresh)
    local actions = {}
    
    for _, item in ipairs(items) do
        local action = {
            ["type"] = "item",
            ["item"] = item.itemId or item.name,
            ["$itemId"] = item.itemId,
            ["$name"] = item.name,
            ["$iconTexture"] = item.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
            ["$isEquipment"] = item.isEquipment or false,
            ["$isEquipped"] = item.isEquipped or false,
            ["$destination"] = item.destination,
            ["$source"] = item.source,
        }
        table.insert(actions, action)
    end

    if FluxNCFlyoutOptions and FluxNCFlyoutOptions.ApplyTeleportItemActions then
        actions = FluxNCFlyoutOptions.ApplyTeleportItemActions(actions)
    end
    
    return actions
end

function Module.HasTeleportItemFlyout()
    local actions = Module.BuildTeleportFlyoutActions()
    return actions and #actions > 1
end

-- Show teleport item flyout
function Module.ShowTeleportFlyout()
    if not Module.HasTeleportItems() then return end
    local btn = Module._button
    if not btn or not btn.Widget then return end

    if Module.ClearHearthButtonCheckedState then
        Module.ClearHearthButtonCheckedState()
    end
    
    -- Get flyout actions
    local actions = Module.BuildTeleportFlyoutActions(true)
    
    if not actions or #actions <= 1 then
        -- One visible option (or none) — use the button directly, no flyout
        return
    end
    
    -- Configure flyout options (onActionUse: same as Mount.lua — main button locks to picked row)
    local config = {
        direction = "UP",
        category = "TeleportItem",  -- For favorites system
        onActionUse = Module.OnTeleportItemPickedFromFlyout,
    }
    
    -- Show flyout using FluxFlyoutFrame
    if FluxFlyoutFrame and FluxFlyoutFrame.ShowFlyout then
        -- Mark button as flyout owner for favorites
        btn.Widget.FluxFlyoutCategory = "TeleportItem"
        btn.Widget.FluxGridFlyoutOwner = true
        
        FluxFlyoutFrame.ShowFlyout(btn.Widget, actions, config)
    end
end

-- Refresh teleport-item flyout if open (e.g. after ncFlyout options change)
function Module.RefreshFlyoutIfOpen()
    local btn = Module._button
    if not btn or not btn.Widget then return end
    if not FluxFlyoutFrame or not FluxFlyoutFrame.IsFlyoutOpenFor then return end
    if not FluxFlyoutFrame.IsFlyoutOpenFor(btn.Widget) then return end
    if not Module.HasTeleportItems() then
        FluxFlyoutFrame.CloseFlyoutFor(btn.Widget)
        return
    end
    local actions = Module.BuildTeleportFlyoutActions(true)
    if not actions or #actions <= 1 then
        FluxFlyoutFrame.CloseFlyoutFor(btn.Widget)
        return
    end
    local config = {
        direction = "UP",
        category = "TeleportItem",
        onActionUse = Module.OnTeleportItemPickedFromFlyout,
    }
    FluxFlyoutFrame.CloseFlyoutFor(btn.Widget)
    local Timer = C_Timer or {}
    if Timer.After then
        Timer.After(0.05, function()
            if InCombatLockdown() then return end
            btn.Widget.FluxFlyoutCategory = "TeleportItem"
            btn.Widget.FluxGridFlyoutOwner = true
            FluxFlyoutFrame.ShowFlyout(btn.Widget, actions, config)
        end)
    else
        btn.Widget.FluxFlyoutCategory = "TeleportItem"
        btn.Widget.FluxGridFlyoutOwner = true
        FluxFlyoutFrame.ShowFlyout(btn.Widget, actions, config)
    end
end

-- Register teleport items button for favorites
function Module.RegisterForFavorites()
    local btn = Module._button
    if not btn or not btn.Widget then return end
    
    -- Set flags expected by FluxFlyoutFavorites
    btn.Widget.FluxFlyoutCategory = "TeleportItem"
    btn.Widget.FluxGridFlyoutOwner = true
    
    -- Register with favorites system if available
    if FluxFlyoutFavorites and FluxFlyoutFavorites.RegisterButton then
        FluxFlyoutFavorites.RegisterButton(btn.Widget, "TeleportItem", {
            itemType = "item",  -- All teleport items use item IDs
        })
    end
end

-- Priority order for favorite fallback
local TELEPORT_PRIORITY_ORDER = { "nomod", "shift", "ctrl", "alt", "ctrl+shift", "shift+alt", "ctrl+alt", "ctrl+shift+alt" }

-- Helper: format modifier string for WoW macro conditionals
-- "ctrl+shift" -> "mod:ctrl,mod:shift"
local function FormatModString(modStr)
    if not modStr or modStr == "nomod" then
        return nil  -- No condition needed for nomod
    end
    if not string.find(modStr, "+") then
        return "mod:" .. modStr
    end
    local parts = {}
    for part in string.gmatch(modStr, "[^+]+") do
        table.insert(parts, "mod:" .. part)
    end
    return table.concat(parts, ",")
end

-- Build a table of modifier actions for macro construction
-- Returns ordered list of { mod, itemId, name, isEquipment, isEquipped } for modifiers with available favorites
function Module.BuildModifierActions()
    local actions = {}
    local items = Module.GetTeleportItems()
    if #items == 0 then return actions end
    
    -- Build set of available items
    local availableSet = {}
    for _, item in ipairs(items) do
        availableSet[item.itemId] = item
    end
    
    if not FluxFlyoutFavorites then return actions end
    
    -- Modifier order for macro conditionals (complex to simple, so they don't shadow each other)
    local modOrder = { "ctrl+shift+alt", "ctrl+shift", "ctrl+alt", "shift+alt", "alt", "ctrl", "shift" }
    
    for _, modKey in ipairs(modOrder) do
        local favId = FluxFlyoutFavorites.GetFavorite("TeleportItem", modKey)
        if favId and availableSet[favId] then
            local item = availableSet[favId]
            table.insert(actions, {
                mod = modKey,
                itemId = favId,
                name = item.name,
                isEquipment = item.isEquipment or false,
                isEquipped = item.isEquipped or false,
            })
        end
    end
    
    return actions
end

-- Build conditional macro for teleport items
-- Macro format:
--   #showtooltip item:123
--   /use [mod:shift] item:456; [mod:ctrl] item:789; item:123
function Module.BuildTeleportMacro()
    local items = Module.GetTeleportItems()
    if #items == 0 then return nil end
    
    -- Single item case: simple direct use/equip
    if #items == 1 then
        local item = items[1]
        local itemId = item.itemId
        local itemName = item.name or ""
        local isEquipment = item.isEquipment
        local isEquipped = item.isEquipped
        
        if itemId then
            if isEquipment and not isEquipped then
                return string.format([[#showtooltip item:%d
/equip item:%d]], itemId, itemId)
            else
                return string.format([[#showtooltip item:%d
/use item:%d]], itemId, itemId)
            end
        elseif itemName ~= "" then
            if isEquipment and not isEquipped then
                return string.format([[#showtooltip %s
/equip %s]], itemName, itemName)
            else
                return string.format([[#showtooltip %s
/use %s]], itemName, itemName)
            end
        end
        return nil
    end
    
    -- Multiple items: build conditional macro
    local useParts = {}
    local equipParts = {}
    
    -- Get modifier actions (favorites that are available)
    local modActions = Module.BuildModifierActions()
    
    -- Helper to add item to macro parts
    local function AddItemToMacro(item, modCond)
        local itemId = item.itemId
        local itemName = item.name
        local isEquipment = item.isEquipment
        local isEquipped = item.isEquipped
        
        if itemId then
            local itemRef = string.format("item:%d", itemId)
            if isEquipment and not isEquipped then
                -- Equipment needs equip first, then use
                if modCond then
                    table.insert(equipParts, string.format("[%s,equipped:!%d] %s", modCond, itemId, itemRef))
                    table.insert(useParts, string.format("[%s] %s", modCond, itemRef))
                else
                    table.insert(equipParts, string.format("[equipped:!%d] %s", itemId, itemRef))
                    table.insert(useParts, itemRef)
                end
            else
                -- Regular item or already equipped - just use
                if modCond then
                    table.insert(useParts, string.format("[%s] %s", modCond, itemRef))
                else
                    table.insert(useParts, itemRef)
                end
            end
        elseif itemName then
            if isEquipment and not isEquipped then
                if modCond then
                    table.insert(equipParts, string.format("[%s] %s", modCond, itemName))
                    table.insert(useParts, string.format("[%s] %s", modCond, itemName))
                else
                    table.insert(equipParts, itemName)
                    table.insert(useParts, itemName)
                end
            else
                if modCond then
                    table.insert(useParts, string.format("[%s] %s", modCond, itemName))
                else
                    table.insert(useParts, itemName)
                end
            end
        end
    end
    
    -- Add modifier-conditioned parts
    for _, action in ipairs(modActions) do
        local modCond = FormatModString(action.mod)
        AddItemToMacro(action, modCond)
    end
    
    -- Add default (nomod with priority fallback)
    local defaultItem = Module.GetBestTeleportItem("nomod")
    local tooltipItem = nil  -- Always use nomod item for #showtooltip
    
    if defaultItem then
        if defaultItem.itemId then
            tooltipItem = string.format("item:%d", defaultItem.itemId)
        else
            tooltipItem = defaultItem.name
        end
        AddItemToMacro(defaultItem, nil)
    else
        -- Fallback to first item if no favorites
        local firstItem = items[1]
        if firstItem.itemId then
            tooltipItem = string.format("item:%d", firstItem.itemId)
        elseif firstItem.name then
            tooltipItem = firstItem.name
        end
        AddItemToMacro(firstItem, nil)
    end
    
    if #useParts == 0 or not tooltipItem then return nil end
    
    local useStr = table.concat(useParts, "; ")
    local macroLines = { string.format("#showtooltip %s", tooltipItem) }
    
    -- Add equip lines if needed (for equipment items)
    if #equipParts > 0 then
        table.insert(macroLines, "/equip " .. table.concat(equipParts, "; "))
    end
    
    -- Add use line
    table.insert(macroLines, "/use " .. useStr)
    
    return table.concat(macroLines, "\n")
end

-- Get best available teleport item for current modifier
function Module.GetBestTeleportItem(requestedModKey)
    local items = Module.GetTeleportItems()
    if #items == 0 then return nil end
    
    -- Build set of available items
    local availableSet = {}
    for _, item in ipairs(items) do
        availableSet[item.itemId] = item
    end
    
    -- Helper to find hearthstone in items
    local function FindHearthstone()
        -- First, try to get configured hearthstone from FluxHearthConfig
        if _G.FluxHearthConfig and _G.FluxHearthConfig.GetHearthItem then
            local ok, hearthItemId = pcall(_G.FluxHearthConfig.GetHearthItem)
            if ok and tonumber(hearthItemId) then
                hearthItemId = tonumber(hearthItemId)
                if availableSet[hearthItemId] then
                    return availableSet[hearthItemId]
                end
            end
        end
        
        -- Fallback: default Hearthstone (6948) or exact name "Hearthstone"
        -- (not place teleports like "Hearthstone of the Dawn").
        for _, item in ipairs(items) do
            local id = tonumber(item.itemId)
            if id == 6948 or id == (Module.DEFAULT_ITEM_ID or 6948) then
                return item
            end
            if item.name and item.name:lower() == "hearthstone" then
                return item
            end
        end
        
        return nil
    end
    
    -- Check if any favorites are set
    local hasAnyFavorites = false
    if FluxFlyoutFavorites then
        for _, modKey in ipairs(TELEPORT_PRIORITY_ORDER) do
            local favId = FluxFlyoutFavorites.GetFavorite("TeleportItem", modKey)
            if favId then
                hasAnyFavorites = true
                break
            end
        end
    end
    
    -- If no favorites system or no favorites set, default to hearthstone
    if not FluxFlyoutFavorites or not hasAnyFavorites then
        local hearthstone = FindHearthstone()
        if hearthstone then
            return hearthstone
        end
        -- Fallback to first item if no hearthstone found
        return items[1]
    end
    
    requestedModKey = requestedModKey or "nomod"
    
    -- Use GetBestAvailableFavorite if available
    if FluxFlyoutFavorites.GetBestAvailableFavorite then
        local favId, foundModKey = FluxFlyoutFavorites.GetBestAvailableFavorite("TeleportItem", requestedModKey, availableSet)
        if favId and availableSet[favId] then
            return availableSet[favId]
        end
    else
        -- Manual priority search
        local exactFavId = FluxFlyoutFavorites.GetFavorite("TeleportItem", requestedModKey)
        if exactFavId and availableSet[exactFavId] then
            return availableSet[exactFavId]
        end
        
        -- Walk through priority order
        for _, modKey in ipairs(TELEPORT_PRIORITY_ORDER) do
            local favId = FluxFlyoutFavorites.GetFavorite("TeleportItem", modKey)
            if favId and availableSet[favId] then
                return availableSet[favId]
            end
        end
    end
    
    -- No favorite available - default to hearthstone
    local hearthstone = FindHearthstone()
    if hearthstone then
        return hearthstone
    end
    
    -- Fallback to first item if no hearthstone found
    return items[1]
end

-- Get current modifier key
local function GetCurrentModKey()
    local tokens = {}
    if IsControlKeyDown and IsControlKeyDown() then table.insert(tokens, "ctrl") end
    if IsShiftKeyDown and IsShiftKeyDown() then table.insert(tokens, "shift") end
    if IsAltKeyDown and IsAltKeyDown() then table.insert(tokens, "alt") end
    if #tokens == 0 then return "nomod" end
    return table.concat(tokens, "+")
end
-- Alias used by modifier-tracker / icon refresh paths (same key format).
local GetCurrentHeldModKey = GetCurrentModKey

local function GetModifierState()
    local state = ""
    if IsShiftKeyDown and IsShiftKeyDown() then state = state .. "S" end
    if IsControlKeyDown and IsControlKeyDown() then state = state .. "C" end
    if IsAltKeyDown and IsAltKeyDown() then state = state .. "A" end
    return state
end

-- Align equip border, cooldown swipe, and stack count with the item the macro will use for current modifiers.
-- FullRefresh / macro resolution only know #showtooltip, so they must be overridden after modifier changes.
function Module.SyncTeleportItemOverlays(btn, item)
    if not btn then return end
    if not Module.HasTeleportItems() then return end
    if Module._isLocked then return end
    if not item or not item.itemId then
        if btn.WBorder then
            btn.WBorder:Hide()
        end
        if btn.WCooldown then
            if btn.CooldownFrame_SetTimer then
                btn:CooldownFrame_SetTimer(0, 0, 0)
            else
                btn.WCooldown:Hide()
            end
        end
        if btn.WCount then
            btn.WCount:SetText("")
        end
        return
    end
    btn.ItemId = item.itemId
    btn.MacroMode = "item"
    btn._fluxManagedFaceItemId = item.itemId
    btn._fluxManagedFaceSpellId = nil
    btn.SpellId = nil
    if btn.UpdateEquipped then
        btn:UpdateEquipped()
    end
    if btn.UpdateCooldown then
        btn:UpdateCooldown()
    end
    if btn.UpdateTextCount then
        btn:UpdateTextCount()
    end
end

-- ============================================================================
-- KEYBINDING MANAGEMENT
-- ============================================================================

-- Update hotkey text display on button
function Module.UpdateHotkeyText(btn)
    btn = btn or Module._button
    if FluxNCHotkeyUtil and FluxNCHotkeyUtil.UpdateHotkeyText then
        FluxNCHotkeyUtil.UpdateHotkeyText(btn, "FLUXGRIDHEARTH")
    end
end

-- Update teleport items keybinding to point to the button widget (secure approach)
function Module.UpdateHearthKeybinding(btn)
    btn = btn or Module._button
    if not btn or not btn.Widget then return end
    if InCombatLockdown() then
        Module._pendingKeybindUpdate = true
        return
    end

    local widgetName = btn.Widget:GetName()
    local hearthKey = GetBindingKey("FLUXGRIDHEARTH")

    -- Clear existing bindings first
    ClearOverrideBindings(btn.Widget)

    if widgetName and hearthKey then
        SetOverrideBindingClick(btn.Widget, false, hearthKey, widgetName, "LeftButton")
    end
end

-- Clear teleport items keybinding
function Module.ClearHearthKeybinding()
    if InCombatLockdown() then return end
    
    local btn = Module._button
    if btn and btn.Widget then
        ClearOverrideBindings(btn.Widget)
    end
end

-- ============================================================================
-- BUTTON CREATION AND UPDATES
-- ============================================================================

-- Register with a grid
function Module.Register(grid)
    if not grid or Module._registered then return end
    
    Module._grid = grid
    Module._registered = true
    
    Module.CreateButton()
    
    if _G.FluxHearthConfig and _G.FluxHearthConfig.RegisterListener then
        _G.FluxHearthConfig.RegisterListener(function()
            Module.InvalidateTeleportCache()
            Module.Update()
        end)
    end
end

local function GetPlayerItemCountForTooltip(itemId)
    return GetBagItemCount(itemId)
end

local function ApplyTeleportItemUsability(self, bestItem)
    if not self or not self.WIcon then
        return
    end
    local U = _G.FluxButtonUsability
    if not U or not U.ApplyVisualFeedback then
        return
    end
    if not bestItem then
        U:ApplyVisualFeedback(self, U.STATE_NOT_USABLE, false)
        return
    end
    -- Unequipped gear teleports: grey like unusable (cannot use until equipped).
    if bestItem.isEquipment and not bestItem.isEquipped then
        U:ApplyVisualFeedback(self, U.STATE_NOT_USABLE, false)
        if self.WIcon.SetDesaturated then
            self.WIcon:SetDesaturated(true)
        end
        return
    end
    local itemId = bestItem.itemId or bestItem.itemID
    if itemId and U.CheckItemUsability then
        local state, mana, itemCount = U:CheckItemUsability(itemId)
        -- Teleport scan already proved the item exists in bags/keyring/equipped.
        -- A stale FluxInv zero-count must not keep the icon dark (ExtraButton item path
        -- would show owned items brightly once count is known).
        if state == U.STATE_NOT_USABLE and (not itemCount or itemCount == 0) then
            local bagCount = GetBagItemCount(itemId)
            local owned = (bagCount and bagCount > 0)
            if not owned then
                local det = GetDetection()
                if det and det.PlayerHasItemInInventory then
                    owned = det.PlayerHasItemInInventory(itemId) and true or false
                end
            end
            if not owned and PlayerOwnsHearthToy(itemId) then
                owned = true
            end
            if owned then
                local isUsable = true
                if C_Item and C_Item.IsUsableItem then
                    local u = C_Item.IsUsableItem(itemId)
                    if u == false then isUsable = false end
                elseif IsUsableItem then
                    local u = IsUsableItem(itemId)
                    if u == false then isUsable = false end
                end
                state = isUsable and U.STATE_USABLE or U.STATE_NOT_USABLE
                mana = false
            end
        end
        self._usabilityState = state
        U:ApplyVisualFeedback(self, state, mana)
        return
    end
    U:ApplyVisualFeedback(self, U.STATE_USABLE, false)
end

local function AssignTeleportUpdateUsable(btn)
    btn.UpdateUsable = function(self)
        if not Module.HasTeleportItems() then
            return
        end
        local bestItem = Module._lockedItem
        if not Module._isLocked then
            bestItem = Module.GetBestTeleportItem(GetCurrentModKey())
        end
        if bestItem and self.WIcon then
            local itemIcon = bestItem.icon
            if itemIcon then
                self.WIcon:SetTexture(itemIcon)
                self.WIcon:Show()
            end
            if self.Widget and self.Widget.icon then
                self.Widget.icon:SetTexture(itemIcon)
                self.Widget.icon:Show()
            end
            self.ItemId = bestItem.itemId or bestItem.itemID
            self.MacroMode = "item"
            self._fluxManagedFaceItemId = self.ItemId
            self._fluxManagedFaceSpellId = nil
            self.SpellId = nil
        end
        Module.SyncTeleportItemOverlays(self, bestItem)
        local Paint = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint
        if Paint and Paint.UpdateLiveFace then
            Paint.UpdateLiveFace(self)
        elseif Paint and Paint.UpdateUsable then
            Paint.UpdateUsable(self)
        end
        -- Unequipped gear teleports cannot be used; Extra item usable can stay bright.
        if bestItem and bestItem.isEquipment and not bestItem.isEquipped then
            ApplyTeleportItemUsability(self, bestItem)
        end
    end
end

local function RestoreFluxButtonTooltipHandlers(btn)
    if not btn or not btn.Widget then return end
    local widget = btn.Widget
    widget:SetScript("OnEnter", function()
        if btn.OnEnter then
            btn:OnEnter()
        elseif type(btn.ShowTooltip) == "function" then
            btn:ShowTooltip()
        end
    end)
    widget:SetScript("OnLeave", function()
        if btn.OnLeave then
            btn:OnLeave()
        else
            local Flux = _G.Flux
            local Action = Flux and Flux.EBS and Flux.EBS.Action
            if Action and Action.OnLeave then
                Action.OnLeave(btn)
            elseif GameTooltip then
                GameTooltip:Hide()
            end
        end
    end)
end

-- Switch between classic hearthstone UI and teleport flyout UI
function Module.RefreshButtonMode(btn, scope)
    if not btn then return end
    scope = scope or (Module.IsCharacterSpecific() and "character" or "account")
    
    if Module.HasTeleportItems() then
        Module._teleportModeActive = true
        Module._isPlaceholder = false
        btn.IsHearthButton = true
        btn.FluxGridFlyoutOwner = true
        btn.TooltipEnabled = false
        if btn.Widget then
            btn.Widget.FluxGridFlyoutOwner = true
        end
        
        AssignTeleportUpdateUsable(btn)
        if not btn._fluxTeleportChrome then
            btn._fluxTeleportChrome = true
            Module.SetupPreClick(btn)
            Module.RegisterForFavorites()
        end
        -- Always reinstall: classic mode restores FluxButton OnEnter/OnLeave and
        -- previously cleared custom handlers without resetting _fluxTeleportChrome.
        Module.SetupTooltip(btn)
        
        -- Bindings depend on flyout vs single-item (SetupRightClick chooses)
        Module.SetupRightClick(btn)
    else
        Module._teleportModeActive = false
        btn._fluxTeleportChrome = nil
        btn.TooltipEnabled = true
        btn.UpdateUsable = nil
        -- Restore default FluxButton tooltip handlers (do not leave OnEnter nil).
        RestoreFluxButtonTooltipHandlers(btn)
        local itemId = Module.GetHearthItemId()
        if btn.SetAction then
            btn:SetAction("item", itemId)
        end
        Module.SetupRightClickClassic(btn)
        if FluxFlyoutFrame and FluxFlyoutFrame.HideArrow and btn.Widget then
            FluxFlyoutFrame.HideArrow(btn.Widget)
        end
    end
end

-- Create the hearthstone button (classic or teleport UI)
function Module.CreateButton()
    if not Module._grid or Module._button then return end
    if InCombatLockdown() then
        Timer.After(0.5, Module.CreateButton)
        return
    end
    
    local grid = Module._grid
    local scope = Module.IsCharacterSpecific() and "character" or "account"
    
    local btn = grid:CreateButton({
        columnPriority = Module.COLUMN_PRIORITY,
        columnGroup = "hearthteleport",
        order = Module.ORDER,
        scope = scope,
    })
    
    if not btn then return end
    
    Module._button = btn
    btn.IsHearthButton = true
    btn.FluxGridFlyoutOwner = true
    if btn.Widget then
        btn.Widget.FluxGridFlyoutOwner = true
    end
    
    if btn.SetLocked then btn:SetLocked(true) end
    if btn.Widget then
        btn.Widget:SetScript("OnDragStart", nil)
        btn.Widget:SetScript("OnReceiveDrag", nil)
        btn.Widget:SetScript("OnDragStop", nil)
        -- Permanently locked (match Food/Water ExtraButtons)
        btn.ButtonLocked = true
        if btn.SetLocked then
            btn:SetLocked(true)
        end
        if btn.Widget.RegisterForDrag then
            btn.Widget:RegisterForDrag()
            btn.Widget:SetScript("OnDragStart", nil)
            btn.Widget:SetScript("OnReceiveDrag", nil)
            btn.Widget:SetScript("OnDragStop", nil)
        end
        if btn.Widget.EnableMouseDrag then
            btn.Widget:EnableMouseDrag(false)
        end
    end
    
    Module.RefreshButtonMode(btn, scope)
    
    -- Column layout (CreateButton already applied config; keep in sync if methods exist)
    if grid.SetButtonColumnPriority then
        grid:SetButtonColumnPriority(btn, Module.COLUMN_PRIORITY)
    else
        grid.ColumnPriorities = grid.ColumnPriorities or {}
        grid.ColumnPriorities[btn] = Module.COLUMN_PRIORITY
    end
    if grid.SetButtonOrder then
        grid:SetButtonOrder(btn, Module.ORDER)
    else
        grid.ButtonOrder = grid.ButtonOrder or {}
        grid.ButtonOrder[btn] = Module.ORDER
    end
    
    Module.UpdateHearthKeybinding(btn)
    Module.UpdateHotkeyText(btn)
    Module.Update()
    
    return btn
end

-- Clear CheckButton highlight (Toy Box / flyout opens are not casts)
local function ClearHearthButtonCheckedState()
    local btn = Module._button
    if not btn or not btn.Widget then return end
    local w = btn.Widget
    if w.SetChecked then
        w:SetChecked(false)
    end
    local tex = w.GetCheckedTexture and w:GetCheckedTexture()
    if tex then
        tex:Hide()
    end
    local namedChecked = w.GetName and _G[w:GetName() .. "Checked"]
    if namedChecked then
        namedChecked:Hide()
    end
    if w.SetButtonState then
        w:SetButtonState("NORMAL")
    end
    if btn.UpdateChecked then
        btn:UpdateChecked()
    end
end
Module.ClearHearthButtonCheckedState = ClearHearthButtonCheckedState

local function GetHearthToyBoxMacro()
    return (FluxMacroClickProxies and FluxMacroClickProxies.MACRO_HEARTH_TOYBOX)
        or "/click FluxMacroProxy_HearthToyBox"
end

-- Toy Box click bindings:
--   Flyout (multiple teleport items): middle-click opens Toy Box; right-click is flyout
--   No flyout (classic / single item): right-click opens Toy Box
function Module.SetupMiddleClickToyBox(btn)
    if not btn or not btn.Widget then return end
    if InCombatLockdown() then
        Timer.After(0.2, function() Module.SetupMiddleClickToyBox(btn) end)
        return
    end
    local hasFlyout = Module.HasTeleportItemFlyout()
    if hasFlyout and HasToyBoxUI() then
        btn.Widget:SetAttribute("type3", "macro")
        btn.Widget:SetAttribute("macrotext3", GetHearthToyBoxMacro())
        btn.PreserveCheckedOnMiddleClick = nil
    else
        btn.Widget:SetAttribute("type3", nil)
        btn.Widget:SetAttribute("macrotext3", nil)
        btn.PreserveCheckedOnMiddleClick = nil
    end
end

-- Classic / single-item: right-click opens Toy Box
function Module.SetupRightClickClassic(btn)
    if not btn or not btn.Widget then return end
    if InCombatLockdown() then
        Timer.After(0.2, function() Module.SetupRightClickClassic(btn) end)
        return
    end
    if HasToyBoxUI() then
        btn.Widget:SetAttribute("type2", "macro")
        btn.Widget:SetAttribute("macrotext2", GetHearthToyBoxMacro())
        btn.PreserveCheckedOnRightClick = nil
    else
        btn.Widget:SetAttribute("type2", nil)
        btn.Widget:SetAttribute("macrotext2", nil)
    end
    -- No flyout → Toy Box is right-click, not middle-click
    btn.Widget:SetAttribute("type3", nil)
    btn.Widget:SetAttribute("macrotext3", nil)
    btn.PreserveCheckedOnMiddleClick = nil
end

function Module.UpdateClassicHearthstone()
    local btn = Module._button
    if not btn then return end
    local itemId = Module.GetHearthItemId()
    local n = GetBagItemCount(itemId)
    local isToy = PlayerOwnsHearthToy(itemId)
    if not itemId or (n <= 0 and not isToy) then
        if ShouldHoldItemIdentity() and Module._lastGoodHearthItemId then
            itemId = Module._lastGoodHearthItemId
            n = math.max(1, tonumber(Module._lastGoodHearthCount) or 1)
            isToy = PlayerOwnsHearthToy(itemId)
        else
            Module._isPlaceholder = true
            if btn.SetPlaceholder then
                btn:SetPlaceholder("Interface/Icons/INV_Misc_Rune_01", "Hearthstone")
            elseif btn.ClearAction then
                btn:ClearAction()
            end
            if btn.FullRefresh then
                btn:FullRefresh()
            end
            return
        end
    else
        Module._lastGoodHearthItemId = itemId
        Module._lastGoodHearthCount = n
    end
    Module._isPlaceholder = false
    if btn.ClearPlaceholder then
        btn:ClearPlaceholder()
    else
        btn.PlaceholderTexture = nil
        btn.PlaceholderLabel = nil
    end
    if isToy and n <= 0 then
        -- Toy Box hearthstones are not bag items; bind via /use item:ID (same as UtilitySlots).
        local _, icon = ResolveHearthItemDisplay(itemId)
        local macroText = string.format([[#showtooltip item:%d
/use item:%d]], itemId, itemId)
        if btn.SetAction then
            btn:SetAction("macrotext", macroText)
        elseif btn.Widget then
            btn.Widget:SetAttribute("type", "macro")
            btn.Widget:SetAttribute("macrotext", macroText)
        end
        if icon and btn.WIcon then
            btn.WIcon:SetTexture(icon)
            btn.WIcon:SetDesaturated(false)
            btn.WIcon:SetVertexColor(1, 1, 1, 1)
            btn.WIcon:Show()
        end
    elseif btn.SetAction then
        btn:SetAction("item", itemId)
    end
    Module.SetupRightClickClassic(btn)
    if btn.FullRefresh then
        btn:FullRefresh()
    end
end

-- Set up right-click behavior (flyout when multiple items; else Toy Box)
function Module.SetupRightClick(btn)
    if not btn or not btn.Widget then return end
    if InCombatLockdown() then
        Timer.After(0.2, function() Module.SetupRightClick(btn) end)
        return
    end
    
    if Module.HasTeleportItemFlyout() then
        -- Flyout owns right-click; Toy Box moves to middle-click
        btn.Widget:SetAttribute("type2", "macro")
        btn.Widget:SetAttribute("macrotext2", (FluxMacroClickProxies and FluxMacroClickProxies.MACRO_HEARTH_TELEPORT_FLYOUT) or "/click FluxMacroProxy_HearthTeleportFlyout")
        btn.PreserveCheckedOnRightClick = nil
        Module.SetupMiddleClickToyBox(btn)
    else
        -- No flyout: Toy Box on right-click when available
        Module.SetupRightClickClassic(btn)
    end
end

-- Set up PreClick hook to capture which item will be used
function Module.SetupPreClick(btn)
    if not btn or not btn.Widget then return end
    
    local widget = btn.Widget
    
    -- Hook PreClick: set pending on mouse *down* only so we capture modifiers at press (not overwritten on up after shift release)
    if widget.HookScript then
        widget:HookScript("PreClick", function(self, button, down)
            if not Module.HasTeleportItems() then return end
            -- Only handle left-click item uses
            if button ~= "LeftButton" then return end
            if not down then return end
            
            -- Don't set pending lock if already locked (just use the locked item)
            if Module._isLocked then return end
            
            -- If it's a placeholder, don't try to lock
            if Module._isPlaceholder then return end
            
            -- Capture which item will be used based on current modifiers
            local heldMod = GetCurrentModKey()
            local bestItem = Module.GetBestTeleportItem(heldMod)
            
            if bestItem then
                -- Mount.lua pattern: only pending here; LockToItem runs when the item spell is confirmed (cast/sent/channel)
                Module._pendingLockItem = {
                    itemId = bestItem.itemId,
                    name = bestItem.name,
                    icon = bestItem.icon,
                    isEquipment = bestItem.isEquipment or false,
                    isEquipped = bestItem.isEquipped or false,
                    spellID = GetSpellIDForItem(bestItem.itemId),
                }
                Module._pendingLockTimestamp = GetTime()
                SetCastLockSpellId(Module._pendingLockItem.spellID)
                local pendingId = bestItem.itemId
                -- Safety timeout: clear pending if cast never starts (CD, cancel, etc.)
                Timer.After(1.0, function()
                    if Module._pendingLockItem
                        and Module._pendingLockItem.itemId == pendingId
                        and not Module._isLocked
                        and not Module._isCasting then
                        Module._pendingLockItem = nil
                        Module._pendingLockTimestamp = nil
                        ClearCastLockSpellId()
                        Module.UpdateTeleportIcon(GetCurrentHeldModKey())
                    end
                end)
            else
                Module._pendingLockItem = nil
                Module._pendingLockTimestamp = nil
                ClearCastLockSpellId()
            end
            Module.RefreshTooltip()
            Module.UpdateTeleportIcon()
        end)
    end
end

-- Main update: classic hearthstone or teleport flyout
function Module.Update()
    if not Module._button then return end
    if InCombatLockdown() then
        Module._pendingUpdate = true
        return
    end
    
    local btn = Module._button
    local bindingForceEBV = FluxExtraButtonVisibility and FluxExtraButtonVisibility.GetBindingForce and FluxExtraButtonVisibility.GetBindingForce() or false
    if not bindingForceEBV and FluxExtraButtonVisibility and not FluxExtraButtonVisibility.Apply("nc_hearthstone", true, bindingForceEBV) then
        if btn.Widget and FluxFlyoutFrame and FluxFlyoutFrame.HideArrow then
            FluxFlyoutFrame.HideArrow(btn.Widget)
        end
        if btn.SlotFrame then btn.SlotFrame:Hide() end
        if btn.Widget then btn.Widget:Hide() end
        Module.ClearHearthKeybinding()
        if Module._grid and Module._grid.Relayout then Module._grid:Relayout() end
        return
    end
    do
        local sf = btn.SlotFrame
        local wasHidden = sf and not sf:IsShown()
        if sf then sf:Show() end
        if btn.Widget then btn.Widget:Show() end
        if wasHidden and Module._grid and Module._grid.ScheduleRelayout then
            Module._grid:ScheduleRelayout()
        end
    end
    local scope = Module.IsCharacterSpecific() and "character" or "account"
    local useTeleport = Module.HasTeleportItems()
    
    if useTeleport ~= Module._teleportModeActive then
        Module.RefreshButtonMode(btn, scope)
    end
    
    if not useTeleport then
        if Module._isLocked then
            Module.Unlock()
        end
        Module.UpdateClassicHearthstone()
    else
        if Module._isLocked then
            Module.UpdateLockedState()
            -- Keep flyout arrow while locked (UpdateTeleportLayout is skipped)
            local items = Module.GetTeleportItems()
            if Module.HasTeleportItemFlyout() and btn.Widget and FluxFlyoutFrame and FluxFlyoutFrame.ShowArrow then
                FluxFlyoutFrame.ShowArrow(btn.Widget, "UP")
            elseif btn.Widget and FluxFlyoutFrame and FluxFlyoutFrame.HideArrow then
                FluxFlyoutFrame.HideArrow(btn.Widget)
            end
            Module.UpdateHearthKeybinding(btn)
            return
        end
        Module.UpdateTeleportLayout()
    end
    
    if _G.FluxGridHearthBindingButton and btn.Widget and not InCombatLockdown() then
        _G.FluxGridHearthBindingButton:SetAttribute("clickbutton", btn.Widget)
    end

    ApplyHearthButtonVisualStyle(btn)
    Module.UpdateHearthKeybinding(btn)
end

-- Teleport mode layout only
function Module.UpdateTeleportLayout()
    if not Module._button then return end
    if not Module.HasTeleportItems() then return end
    if InCombatLockdown() then
        Module._pendingUpdate = true
        return
    end
    
    Module._isPlaceholder = false
    local btn = Module._button
    if btn and btn.ClearPlaceholder then
        btn:ClearPlaceholder()
    elseif btn then
        btn.PlaceholderTexture = nil
        btn.PlaceholderLabel = nil
    end
    local items = Module.GetTeleportItems()
    
    if btn.SlotFrame then
        btn.SlotFrame:Show()
    end
    
    -- If only one item, use it directly
    if #items == 1 then
        local item = items[1]
        local itemId = item.itemId
        local itemName = item.name
        local itemIcon = item.icon
        local isEquipment = item.isEquipment
        local isEquipped = item.isEquipped
        
        -- Build macro based on equipment status (use item: format like Mount.lua)
        local macroText
        if itemId then
            if isEquipment and not isEquipped then
                -- Equipment not equipped - macro to equip it
                macroText = string.format([[#showtooltip item:%d
/equip item:%d]], itemId, itemId)
            else
                -- Item is equipped or not equipment - use it
                macroText = string.format([[#showtooltip item:%d
/use item:%d]], itemId, itemId)
            end
        elseif itemName then
            if isEquipment and not isEquipped then
                macroText = string.format([[#showtooltip %s
/equip %s]], itemName, itemName)
            else
                macroText = string.format([[#showtooltip %s
/use %s]], itemName, itemName)
            end
        end
        
        if macroText then
            if btn.SetAction then
                btn:SetAction("macrotext", macroText)
            elseif btn.Widget then
                btn.Widget:SetAttribute("type", "macro")
                btn.Widget:SetAttribute("macrotext", macroText)
            end
        end
        
        -- Update texture
        if itemIcon then
            _lastSetIcon = itemIcon
            if btn.WIcon then
                btn.WIcon:SetTexture(itemIcon)
                btn.WIcon:SetDesaturated(isEquipment and not isEquipped)
                btn.WIcon:SetVertexColor(1, 1, 1, 1)
                btn.WIcon:Show()
            end
        end
        
        -- Hide flyout arrow for single item
        if FluxFlyoutFrame and FluxFlyoutFrame.HideArrow then
            FluxFlyoutFrame.HideArrow(btn.Widget)
        end
        
        Module.SyncTeleportItemOverlays(btn, item)
    else
        -- Multiple items - build conditional macro with modifier support
        local macro = Module.BuildTeleportMacro()
        
        if macro and macro ~= "" then
            -- Set action using FluxButton's SetAction method
            if btn.SetAction then
                btn:SetAction("macrotext", macro)
            end
            
            -- Also set Widget attributes directly for secure action
            if btn.Widget and not InCombatLockdown() then
                btn.Widget:SetAttribute("type", "macro")
                btn.Widget:SetAttribute("macrotext", macro)
            end
            
            -- Set up icon protection to prevent external TEXTURE changes
            -- This prevents macro evaluation from changing our modifier-based icon
            Module.SetupIconProtection(btn)
            
            -- Reset modifier tracking state to ensure clean start
            lastTeleportIconModState = ""
            if FluxModifierTracker and FluxModifierTracker.NotifyActiveChanged then
                FluxModifierTracker.NotifyActiveChanged()
            end

            -- Update icon for currently held modifier (not forced nomod)
            Module.UpdateTeleportIcon(GetCurrentHeldModKey())
        end

        -- Arrow after SetAction: SetAction used to HideArrow when macro has no /flyout
        if Module.HasTeleportItemFlyout() then
            if FluxFlyoutFrame and FluxFlyoutFrame.ShowArrow and btn.Widget then
                FluxFlyoutFrame.ShowArrow(btn.Widget, "UP")
            end
        elseif FluxFlyoutFrame and FluxFlyoutFrame.HideArrow and btn.Widget then
            FluxFlyoutFrame.HideArrow(btn.Widget)
        end
    end
    
    -- Right-click: flyout when multiple visible options, else Toy Box
    Module.SetupRightClick(btn)
    
    if btn.FullRefresh then
        btn:FullRefresh()
    end

    -- Re-assert arrow after FullRefresh (layout / chrome can recreate frames)
    if Module.HasTeleportItemFlyout() and FluxFlyoutFrame and FluxFlyoutFrame.ShowArrow and btn.Widget then
        FluxFlyoutFrame.ShowArrow(btn.Widget, "UP")
    elseif FluxFlyoutFrame and FluxFlyoutFrame.HideArrow and btn.Widget then
        FluxFlyoutFrame.HideArrow(btn.Widget)
        if FluxFlyoutFrame.IsFlyoutOpenFor and FluxFlyoutFrame.IsFlyoutOpenFor(btn.Widget) then
            FluxFlyoutFrame.CloseFlyoutFor(btn.Widget)
        end
    end
    
    -- FullRefresh restores macro-resolved ItemId; re-sync overlays to modifier-selected item
    Module.SyncTeleportItemOverlays(btn, Module.GetBestTeleportItem(GetCurrentModKey()))
    
    Module.RefreshTooltip()
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player") end)
pcall(function()
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
end)
pcall(function()
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
end)

-- Modifier tracking state for live updates
local lastTeleportIconModState = ""

-- Tooltip state tracking
local tooltipShowing = false
local lastTooltipModifierState = ""

-- Get icon tag for tooltip (inline icon texture)
local function GetIconTag(itemId, itemName)
    if not itemId then return "" end
    local icon = GetItemIcon(itemId)
    if icon then
        return string.format("|T%s:16:16:0:0|t ", icon)
    end
    return ""
end

-- Get item quality color
local function GetItemQualityColorRGB(itemId)
    if not itemId then return 1, 1, 1 end
    local _, _, quality = GetItemInfo(itemId)
    if quality then
        local r, g, b = GetItemQualityColor(quality)
        if r and g and b then
            return r, g, b
        end
    end
    return 1, 1, 1
end

-- Remaining item cooldown in seconds, or nil if none / not applicable
local function GetItemCooldownRemainingSeconds(itemId)
    if not itemId then return nil end
    if type(itemId) == "string" then
        local n = tonumber(itemId) or tonumber(itemId:match("(%d+)"))
        if n then itemId = n end
    end
    if type(itemId) ~= "number" then return nil end

    local start, duration = 0, 0
    if C_Item and C_Item.GetItemCooldown then
        local a, b, c = C_Item.GetItemCooldown(itemId)
        if a == nil then return nil end
        if type(a) == "table" then
            start = a.startTime or 0
            duration = a.duration or 0
        else
            start, duration = a or 0, b or 0
        end
    elseif C_Container and C_Container.GetItemCooldown then
        local a, b = C_Container.GetItemCooldown(itemId)
        if a and type(a) == "table" then
            start = a.startTime or 0
            duration = a.duration or 0
        else
            start, duration = a or 0, b or 0
        end
    elseif GetItemCooldown then
        local s, d = GetItemCooldown(itemId)
        start, duration = s or 0, d or 0
    else
        return nil
    end

    if not duration or duration <= 0 then return nil end
    local remain = (start + duration) - GetTime()
    if remain <= 0 then return nil end
    return remain
end

-- Max stack size for an item (1 = not stackable for display)
local function GetItemMaxStackForTooltip(itemId)
    if not itemId then return 1 end
    if C_Item and C_Item.GetItemInfo then
        local ok, info = pcall(C_Item.GetItemInfo, itemId)
        if ok and type(info) == "table" and info.stackCount then
            return math.max(1, tonumber(info.stackCount) or 1)
        end
    end
    local stack = select(8, GetItemInfo(itemId))
    if type(stack) == "number" and stack > 0 then
        return stack
    end
    return 1
end

-- Suffixes for modifier-binding lines (no |cff| — inherit AddLine quality / active color with item name)
local function FormatStackCountSuffix(itemId)
    if GetItemMaxStackForTooltip(itemId) <= 1 then return "" end
    local n = GetPlayerItemCountForTooltip(itemId)
    if n <= 0 then return "" end
    return string.format(" (x%d)", n)
end

local function FormatCooldownSuffix(itemId)
    local rem = GetItemCooldownRemainingSeconds(itemId)
    if not rem then return "" end
    -- Under 1 minute: seconds only
    if rem < 60 then
        return string.format(" (%ds)", math.ceil(rem))
    end
    -- 1 minute .. < 60 minutes: minutes:seconds
    if rem < 3600 then
        return string.format(" (%d:%02d)", math.floor(rem / 60), math.floor(rem % 60))
    end
    -- 60+ minutes: hours and minutes
    local h = math.floor(rem / 3600)
    local m = math.floor((rem % 3600) / 60)
    return string.format(" (%dh %dm)", h, m)
end

-- Dedicated tooltip frame (not the global GameTooltip) so addons that only hook GameTooltip cannot inject here.
-- TooltipDataProcessor / global hooks may still affect any item tooltip; FluxTooltipGuard blocks AddLine on older clients only (see Button.lua).
local teleportTooltipFrame

local function GetTeleportTooltipFrame()
    if not teleportTooltipFrame then
        teleportTooltipFrame = CreateFrame("GameTooltip", "FluxNCTeleportHearthTooltip", UIParent, "GameTooltipTemplate")
        teleportTooltipFrame:SetFrameStrata("TOOLTIP")
        teleportTooltipFrame:Hide()
    end
    return teleportTooltipFrame
end

local function HideTeleportTooltipFrames()
    if teleportTooltipFrame then
        teleportTooltipFrame:Hide()
    end
    if GameTooltip then
        GameTooltip:Hide()
    end
end

-- Blizzard item tooltip for the resolved teleport item (bags / keyring / equipped all use the same item ID path).
local function SetTeleportTooltipBlizzardItemBody(tip, widget, itemId, nameFallback)
    tip:SetOwner(widget, "ANCHOR_RIGHT")
    if tip.SetOwner then
        tip.updateTooltip = 1
    end
    tip:ClearLines()
    if not itemId then
        if nameFallback and nameFallback ~= "" then
            tip:SetText(nameFallback, 1, 1, 1)
        else
            tip:SetText("Teleport Items", 1, 1, 1)
        end
        return
    end
    local canAccess = true
    if FluxAPICompat and FluxAPICompat.API and FluxAPICompat.API.CanAccessValue then
        canAccess = FluxAPICompat.API.CanAccessValue(itemId)
    end
    local Guard = FluxTooltipGuard
    if canAccess and tip.SetItemByID then
        if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Block(tip) end
        local ok = pcall(tip.SetItemByID, tip, itemId)
        if Guard and not (FLUX_API and FLUX_API.isPostDF) then Guard.Unblock(tip) end
        if ok then
            return
        end
    end
    local _, link = GetItemInfo(itemId)
    if link and tip.SetHyperlink then
        if pcall(tip.SetHyperlink, tip, link) then
            return
        end
    end
    if nameFallback and nameFallback ~= "" then
        tip:SetText(nameFallback, 1, 1, 1)
    else
        tip:SetText("Teleport Items", 1, 1, 1)
    end
end

-- Item shown in tooltip: locked > pending (casting) > modifier-resolved (main click / keybind)
local function GetActiveItemForTeleportTooltip()
    if Module._isLocked and Module._lockedItem and Module._lockedItem.itemId then
        return Module._lockedItem
    end
    if Module._pendingLockItem and Module._pendingLockItem.itemId then
        return Module._pendingLockItem
    end
    local heldMod = GetCurrentHeldModKey()
    return Module.GetBestTeleportItem(heldMod)
end

-- True if active tooltip item or any set TeleportItem favorite is on cooldown (for periodic refresh)
local function TooltipNeedsCooldownRefresh()
    local active = GetActiveItemForTeleportTooltip()
    if not active or not active.itemId then
        local held = GetCurrentHeldModKey()
        active = Module.GetBestTeleportItem(held)
    end
    if active and active.itemId and GetItemCooldownRemainingSeconds(active.itemId) then
        return true
    end
    if not FluxFlyoutFavorites or not FluxFlyoutFavorites.GetFavorite then return false end
    local list = Module.GetTeleportItems()
    local available = {}
    for _, it in ipairs(list) do
        if it.itemId then
            available[it.itemId] = true
        end
    end
    local modOrder = { "nomod", "shift", "ctrl", "alt", "ctrl+shift", "ctrl+alt", "shift+alt", "ctrl+shift+alt" }
    for _, modKey in ipairs(modOrder) do
        local favId = FluxFlyoutFavorites.GetFavorite("TeleportItem", modKey)
        if favId and available[favId] and GetItemCooldownRemainingSeconds(favId) then
            return true
        end
    end
    return false
end

-- Build and show the tooltip: native item block + FluxUI lines (single dedicated tooltip frame)
local function ShowTeleportTooltip(widget)
    if not widget or not Module.HasTeleportItems() then return end
    
    local tip = GetTeleportTooltipFrame()
    if GameTooltip then
        GameTooltip:Hide()
    end
    
    local items = Module.GetTeleportItems()
    local itemCount = #items
    local hasFlyout = Module.HasTeleportItemFlyout()
    
    if itemCount == 0 then
        tip:SetOwner(widget, "ANCHOR_RIGHT")
        if tip.SetOwner then
            tip.updateTooltip = 1
        end
        tip:ClearLines()
        tip:SetText("Teleport Items", 1, 1, 1)
        tip:AddLine("No teleport items found", 1, 0.5, 0)
        tip:AddLine(" ")
        tip:AddLine("Obtain teleport items to use this button", 0.7, 0.7, 0.7)
        if FluxSafeGameTooltipShow then
            FluxSafeGameTooltipShow(tip)
        else
            tip:Show()
        end
        return
    end
    
    local heldMod = GetCurrentHeldModKey()
    local activeItem = GetActiveItemForTeleportTooltip()
    if not activeItem or not activeItem.itemId then
        activeItem = Module.GetBestTeleportItem(heldMod)
    end
    local activeName = activeItem and activeItem.name
    local activeItemId = activeItem and activeItem.itemId
    
    local pinItemId = nil
    if Module._isLocked and Module._lockedItem and Module._lockedItem.itemId then
        pinItemId = Module._lockedItem.itemId
    elseif Module._pendingLockItem and Module._pendingLockItem.itemId then
        pinItemId = Module._pendingLockItem.itemId
    end
    
    SetTeleportTooltipBlizzardItemBody(tip, widget, activeItemId, activeName)
    
    -- FluxUI: click hints + modifier favorites (under the item tooltip)
    tip:AddLine(" ")
    if pinItemId then
        tip:AddLine("Locked to this item (casting / using)", 0.4, 0.9, 0.4)
        tip:AddLine(" ")
    end
    if hasFlyout then
        tip:AddLine("Left-click: Use item", 0.8, 0.8, 0.8)
        tip:AddLine("Right-click: Open flyout", 0.8, 0.8, 0.8)
        if HasToyBoxUI() then
            tip:AddLine("Middle-click: Toy Box", 0.8, 0.8, 0.8)
        end
    else
        tip:AddLine("Left-click: Use item", 0.5, 0.8, 1)
        if HasToyBoxUI() then
            tip:AddLine("Right-click: Toy Box", 0.7, 0.7, 0.7)
        end
    end
    
    local availableSet = {}
    for _, item in ipairs(items) do
        if item.itemId then
            availableSet[item.itemId] = item
        end
    end
    
    local availableFavorites = {}
    if FluxFlyoutFavorites then
        local modOrder = { "nomod", "shift", "ctrl", "alt", "ctrl+shift", "ctrl+alt", "shift+alt", "ctrl+shift+alt" }
        for _, modKey in ipairs(modOrder) do
            local favId = FluxFlyoutFavorites.GetFavorite("TeleportItem", modKey)
            if favId and availableSet[favId] then
                availableFavorites[modKey] = availableSet[favId]
            end
        end
    end
    
    local favoriteLines = {}
    local modOrder = { "nomod", "shift", "ctrl", "alt", "ctrl+shift", "ctrl+alt", "shift+alt", "ctrl+shift+alt" }
    for _, modKey in ipairs(modOrder) do
        local fav = availableFavorites[modKey]
        if fav then
            local modLabel = (modKey == "" or modKey == "nomod") and "no mod" or modKey
            table.insert(favoriteLines, {
                key = modKey,
                modLabel = modLabel,
                itemId = fav.itemId,
                name = fav.name,
            })
        end
    end
    
    tip:AddLine(" ")
    if #favoriteLines > 0 then
        tip:AddLine("Modifier Bindings:", 1, 0.82, 0)
        for _, fav in ipairs(favoriteLines) do
            local iconTag = GetIconTag(fav.itemId, fav.name)
            local r, g, b = GetItemQualityColorRGB(fav.itemId)
            local isActive = (pinItemId and fav.itemId == pinItemId) or
                (not pinItemId and ((fav.key == heldMod) or
                (heldMod == "nomod" and fav.key == "nomod") or
                (activeName and fav.name == activeName)))
            if isActive then
                r, g, b = 0.2, 1, 0.2
            end
            local text = string.format("[%s] %s%s%s%s", fav.modLabel, iconTag, fav.name,
                FormatStackCountSuffix(fav.itemId),
                FormatCooldownSuffix(fav.itemId))
            tip:AddLine(text, r, g, b)
        end
    else
        tip:AddLine("No favorites set", 0.5, 0.5, 0.5)
        if hasFlyout then
            tip:AddLine("Right-click flyout buttons to set favorites", 0.7, 0.7, 0.7)
        else
            tip:AddLine("Modifier favorites require multiple teleport items", 0.7, 0.7, 0.7)
        end
    end
    
    if itemCount > 1 then
        tip:AddLine(" ")
        tip:AddLine(string.format("Teleport items: %d", itemCount), 0.6, 0.6, 0.6)
    end
    
    if FluxSafeGameTooltipShow then
        FluxSafeGameTooltipShow(tip)
    else
        tip:Show()
    end
end

function Module.SetupTooltip(btn)
    if not btn or not btn.Widget then return end
    
    local widget = btn.Widget
    local Hover = _G.FluxTooltipHover
    local cdTicker = nil

    local function StopCdTicker()
        if cdTicker and cdTicker.Cancel then
            cdTicker:Cancel()
        end
        cdTicker = nil
    end

    local function StartCdTickerIfNeeded()
        StopCdTicker()
        if not tooltipShowing or not TooltipNeedsCooldownRefresh() then
            return
        end
        if not (C_Timer and C_Timer.NewTicker) then
            return
        end
        cdTicker = C_Timer.NewTicker(0.5, function()
            if not tooltipShowing then
                StopCdTicker()
                return
            end
            if TooltipNeedsCooldownRefresh() then
                ShowTeleportTooltip(widget)
            else
                StopCdTicker()
            end
        end)
    end
    
    local function hideTeleportTooltip()
        widget._fluxTooltipHadCd = nil
        widget._fluxTooltipCdElapsed = nil
        HideTeleportTooltipFrames()
    end

    if Hover and Hover.RegisterGridWidget then
        Hover.RegisterGridWidget(widget, hideTeleportTooltip)
    end
    
    widget:SetScript("OnEnter", function(self)
        tooltipShowing = true
        lastTooltipModifierState = GetModifierState()
        local function showTip()
            ShowTeleportTooltip(self)
            StartCdTickerIfNeeded()
        end
        if Hover and Hover.BeginGridHover then
            Hover.BeginGridHover(self, showTip)
        else
            showTip()
        end
    end)
    
    widget:SetScript("OnLeave", function(self)
        tooltipShowing = false
        self:SetScript("OnUpdate", nil)
        StopCdTicker()
        if Hover and Hover.EndGridHover then
            Hover.EndGridHover(self, hideTeleportTooltip)
        else
            hideTeleportTooltip()
        end
    end)
end

-- Refresh tooltip if currently shown
function Module.RefreshTooltip()
    if tooltipShowing and Module._button and Module._button.Widget then
        ShowTeleportTooltip(Module._button.Widget)
    end
end

-- Update teleport button icon based on current modifier state
function Module.UpdateTeleportIcon(forceModKey)
    if not Module.HasTeleportItems() then return end
    local btn = Module._button
    if not btn or not btn.WIcon then return end
    Module._isPlaceholder = false
    if Module._isLocked then return end  -- Don't change icon when locked
    
    -- TeleportPortal.lua: while pending lock, keep clicked item icon (modifier release before cast start)
    if Module._pendingLockItem and Module._pendingLockItem.icon then
        local p = Module._pendingLockItem
        local icon = p.icon
        _lastSetIcon = icon
        _iconManagedByModule = true
        if btn.WIcon then
            btn.WIcon:SetTexture(icon)
            btn.WIcon:SetDesaturated(p.isEquipment and not p.isEquipped or false)
            btn.WIcon:Show()
        end
        if btn.Widget and btn.Widget.icon then
            btn.Widget.icon:SetTexture(icon)
            btn.Widget.icon:SetDesaturated(p.isEquipment and not p.isEquipped or false)
            btn.Widget.icon:Show()
        end
        if p.itemId then
            Module.SyncTeleportItemOverlays(btn, {
                itemId = p.itemId,
                name = p.name,
                icon = p.icon,
                isEquipment = p.isEquipment,
                isEquipped = p.isEquipped,
            })
            ApplyTeleportItemUsability(btn, p)
        end
        return
    end
    
    if Module._isCasting then return end
    
    local modKey = forceModKey or GetCurrentModKey()
    
    -- Get best available teleport item for this modifier (uses priority fallback)
    local item = Module.GetBestTeleportItem(modKey)
    
    local icon = nil
    if item then
        icon = item.icon
        if not icon and item.itemId then
            icon = GetItemIcon(item.itemId)
        end
    end
    
    -- Fallback to default icon if no icon found
    if not icon then
        icon = "Interface\\Icons\\INV_Misc_Rune_01"
    end
    
    -- Update icon with protection
    _lastSetIcon = icon
    _iconManagedByModule = true
    
    if btn.WIcon then
        btn.WIcon:SetTexture(icon)
        btn.WIcon:Show()
    end
    if btn.Widget and btn.Widget.icon then
        btn.Widget.icon:SetTexture(icon)
        btn.Widget.icon:Show()
    end
    
    Module.SyncTeleportItemOverlays(btn, item)
    ApplyTeleportItemUsability(btn, item)
end

-- Hook button icon to prevent external TEXTURE changes (not usability)
-- This prevents macro evaluation from changing our modifier-based icon
function Module.SetupIconProtection(btn)
    if not btn or not btn.WIcon then return end
    if btn.WIcon._fluxTeleportIconHooked then return end
    
    -- Store original SetTexture
    local originalSetTexture = btn.WIcon.SetTexture
    
    -- Replace SetTexture with our guarded version
    -- This ONLY protects texture changes, NOT usability (desaturation/color)
    btn.WIcon.SetTexture = function(self, texture, ...)
        -- If we're managing the icon and this isn't our call, ignore it
        if _iconManagedByModule and texture ~= _lastSetIcon then
            return
        end
        return originalSetTexture(self, texture, ...)
    end
    
    btn.WIcon._fluxTeleportIconHooked = true
end

-- Shared modifier tracker (demand-driven OnUpdate via FluxModifierTracker)
local function CheckModifierState()
    if not Module.HasTeleportItems() then return end

    -- Freeze icon while combat / hard-lock / casting / pending click→cast
    if InCombatLockdown() then return end
    if Module._isLocked or not Module._button or not Module._button.WIcon then return end
    if Module._isCasting then return end
    if Module._pendingLockItem then return end

    -- Check if modifier state changed
    local currentState = GetModifierState()
    if currentState ~= lastTeleportIconModState then
        lastTeleportIconModState = currentState
        -- Update icon based on current modifier (macro handles the action switching)
        Module.UpdateTeleportIcon()
    end

    if tooltipShowing then
        if currentState ~= lastTooltipModifierState then
            lastTooltipModifierState = currentState
            if not Module._isLocked and not Module._pendingLockItem then
                ShowTeleportTooltip(Module._button and Module._button.Widget)
            end
        end
    end
end

local function HearthModifierIsActive()
    if tooltipShowing then return true end
    if InCombatLockdown() then return false end
    if not Module.HasTeleportItems() then return false end
    if Module._isLocked or not Module._button or not Module._button.WIcon then return false end
    if Module._isCasting then return false end
    if Module._pendingLockItem then return false end
    return true
end

if FluxModifierTracker and FluxModifierTracker.Register then
    FluxModifierTracker.Register("NCHearthstone", CheckModifierState, {
        isActive = HearthModifierIsActive,
    })
end

-- Helper: Check if a spell is a mount spell (for negative verification)
local function IsMountSpell(spellID)
    if not spellID then return false end
    
    -- Check mount journal (most reliable method)
    if C_MountJournal and C_MountJournal.GetMountFromSpell then
        local mountID = C_MountJournal.GetMountFromSpell(spellID)
        if mountID ~= nil then
            return true
        end
    end
    
    -- Fallback: check spell name for mount patterns
    local spellName = nil
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        spellName = info and info.name
    elseif GetSpellInfo then
        spellName = GetSpellInfo(spellID)
    end
    
    if spellName then
        local lower = spellName:lower()
        -- Common mount patterns
        if lower:find("mount") or lower:find("riding") or lower:find("steed") or 
           lower:find("charger") or lower:find("strider") or lower:find("gryphon") or
           lower:find("wyvern") or lower:find("kodo") or lower:find("raptor") then
            return true
        end
    end
    
    return false
end

-- Spell name from id (for matching item tooltip spell vs item name)
local function GetSpellNameFromSpellID(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        return info and info.name
    end
    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    return nil
end

-- Unit spell events vary by client: pick first positive numeric arg (spell id)
local function GetFirstSpellIdFromUnitSpellArgs(...)
    local n = select("#", ...)
    for i = 1, n do
        local v = select(i, ...)
        if type(v) == "number" and v > 0 then
            return v
        end
    end
    return nil
end

-- Lock pending teleport item when a cast/sent is observed (TeleportPortal.lua pattern).
-- IMPORTANT: Do NOT treat "Teleport: ..." spells as "class portal" clears — item Hearthstones use those names too.
local function TryLockPendingTeleportFromSpell(spellID)
    if not Module._pendingLockItem or Module._isLocked then
        return
    end
    
    local pending = Module._pendingLockItem
    
    local pendingSpellId = pending.spellID
    if not pendingSpellId and pending.itemId then
        pendingSpellId = GetSpellIDForItem(pending.itemId)
    end
    
    local castSpellId = spellID
    local castSpellName = castSpellId and GetSpellNameFromSpellID(castSpellId) or nil
    
    -- Another mount cast: drop pending (Mount.lua-style), unless ids somehow match
    if castSpellId and IsMountSpell(castSpellId) then
        if not pendingSpellId or pendingSpellId ~= castSpellId then
            Module._pendingLockItem = nil
            Module._pendingLockTimestamp = nil
            ClearCastLockSpellId()
            Module.RefreshTooltip()
            return
        end
    end
    
    -- TeleportPortal.lua: match by spell id, else by name, else trust PreClick pending (macro/item timing)
    local shouldLock = false
    if pendingSpellId and castSpellId then
        shouldLock = (pendingSpellId == castSpellId)
    elseif pending.name and castSpellName then
        shouldLock = (pending.name:lower() == castSpellName:lower())
    else
        shouldLock = true
    end
    
    if shouldLock and pending.itemId then
        Module._isCasting = true
        SetCastLockSpellId(pendingSpellId or castSpellId)
        Module.LockToItem(
            pending.itemId,
            pending.name,
            pending.icon,
            pending.isEquipment,
            pending.isEquipped
        )
        Module._pendingLockItem = nil
        Module._pendingLockTimestamp = nil
    end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local arg1, arg2, arg3 = ...
    if event == "PLAYER_REGEN_DISABLED" then
        -- Combat started - lock icon
        if Module._button and Module._button.WIcon then
            _iconManagedByModule = true
        end
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended - unlock icon
        _iconManagedByModule = false
        
        if Module._pendingUnlock then
            Module._pendingUnlock = false
            if Module._isLocked then
                Module.Unlock()
            end
        end
        if Module._pendingUpdate then
            Module._pendingUpdate = nil
            Module.Update()
        end
        if Module._pendingKeybindUpdate then
            Module._pendingKeybindUpdate = nil
            Module.UpdateHearthKeybinding()
        end
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isLogin = (arg1 == true or arg2 == true)
        if not isLogin and not Module._fluxSeenPew then
            isLogin = true
        end
        Module._fluxSeenPew = true
        if isLogin then
            -- Reset lock state on login
            Module._isLocked = false
            Module._lockedItem = nil
            Module._pendingEquipItemId = nil
            Module._isEquipping = false
            Module._isCasting = false
            Module._pendingLockItem = nil
            Module._pendingUnlock = false
            ClearCastLockSpellId()
        end
        
        -- Fast bind on login/reload; zone load screens keep last item.
        if Module._registered then
            if isLogin then
                Module.InvalidateTeleportCache()
            end
            Module.Update()
        end
        if isLogin then
            -- Bags / item info often warm after first frames — retry past 5s scan TTL
            local delays = { 0.12, 0.4, 1.0, 2.0 }
            for _, delay in ipairs(delays) do
                Timer.After(delay, function()
                    if Module._registered then
                        Module.InvalidateTeleportCache()
                        Module.Update()
                    end
                end)
            end
        end
        
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        Module.OnEquipmentChanged()
        if not InCombatLockdown() then
            Timer.After(0.1, function()
                if Module._registered then
                    if Module._teleportModeActive or Module._pendingEquipItemId then
                        Module.InvalidateTeleportCache()
                    end
                    Module.Update()
                end
            end)
        end
        
    elseif event == "UNIT_SPELLCAST_START" then
        if arg1 ~= "player" then return end
        local spellID = (type(arg3) == "number" and arg3) or (type(arg2) == "number" and arg2)
        if not spellID then
            spellID = GetFirstSpellIdFromUnitSpellArgs(...)
        end
        if spellID and (Module._pendingLockItem or Module._isLocked or Module._isCasting) then
            SetCastLockSpellId(spellID)
        end
        TryLockPendingTeleportFromSpell(spellID)
        if Module._lockedItem and not Module._isCasting then
            Module._isCasting = true
        end
        
    elseif event == "UNIT_SPELLCAST_SENT" then
        -- With RegisterUnitEvent(player): often castGUID, spellID (spell id is arg2); full event may pass unit first
        local spellID = (type(arg3) == "number" and arg3) or (type(arg2) == "number" and arg2)
        if not spellID then
            spellID = GetFirstSpellIdFromUnitSpellArgs(...)
        end
        if spellID and (Module._pendingLockItem or Module._isLocked or Module._isCasting) then
            SetCastLockSpellId(spellID)
        end
        TryLockPendingTeleportFromSpell(spellID)
        if Module._lockedItem and not Module._isCasting then
            Module._isCasting = true
        end
        
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local spellID = (type(arg3) == "number" and arg3) or (type(arg2) == "number" and arg2) or (type(arg1) == "number" and arg1)
        if not spellID then
            spellID = GetFirstSpellIdFromUnitSpellArgs(...)
        end
        if spellID and (Module._pendingLockItem or Module._isLocked or Module._isCasting) then
            SetCastLockSpellId(spellID)
        end
        TryLockPendingTeleportFromSpell(spellID)
        if Module._lockedItem and not Module._isCasting then
            Module._isCasting = true
        end
        
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_STOP" then
        if arg1 ~= "player" then return end
        Module._isCasting = false
        if not Module._isLocked and not Module._pendingLockItem then
            ClearCastLockSpellId()
        end
        
        if Module._isLocked and Module._lockedItem then
            Timer.After(0.25, function()
                if Module._isLocked and not Module._isCasting then
                    if not InCombatLockdown() then
                        Module.Unlock()
                    else
                        Module._pendingUnlock = true
                    end
                end
            end)
        end
        
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        -- Cast failed/interrupted - unlock
        if arg1 ~= "player" then return end
        
        if Module._isCasting then
            Module._isCasting = false
            -- Unlock since cast was interrupted
            if not InCombatLockdown() then
                Module.Unlock()
            else
                Module._pendingUnlock = true
            end
        end
        Module._pendingLockItem = nil  -- Clear pending lock
        Module._pendingLockTimestamp = nil
        ClearCastLockSpellId()
        ForceClearButtonCastVFX()
        if not Module._isLocked then
            Module.UpdateTeleportIcon(GetCurrentHeldModKey())
        end
        Module.RefreshTooltip()
    end
end)

do
    local function RefreshCountOnly()
        local btn = Module._button
        if not btn or not Module._registered or Module._isLocked then return end
        if btn.UpdateTextCount then
            btn:UpdateTextCount()
        end
        if btn.UpdateUsable then
            btn:UpdateUsable()
        end
        if btn.UpdateCooldown then
            btn:UpdateCooldown()
        end
    end

    local function NeedsHearthIdentityRefresh()
        if not Module._registered then return false end
        local hasItems = Module.HasTeleportItems()
        if hasItems ~= Module._teleportModeActive then
            return true
        end
        local btn = Module._button
        if btn and (btn.PlaceholderTexture or Module._isPlaceholder) and hasItems then
            return true
        end
        if hasItems then
            local items = Module.GetTeleportItems(true)
            local any = false
            for _, it in ipairs(items or {}) do
                if it.itemId and GetPlayerItemCountForTooltip(it.itemId) > 0 then
                    any = true
                    break
                end
            end
            if not any then
                return true
            end
        else
            local hearthId = Module.GetHearthItemId()
            if hearthId and GetPlayerItemCountForTooltip(hearthId) > 0 then
                return true
            end
            if btn and btn.ItemId and GetPlayerItemCountForTooltip(btn.ItemId) <= 0 then
                return true
            end
        end
        return false
    end

    local function FullHearthBagUpdate()
        if ShouldHoldItemIdentity() then
            return
        end
        if not InCombatLockdown() and Module._registered then
            Module.InvalidateTeleportCache()
            Module.Update()
        else
            Module._pendingUpdate = true
        end
    end

    -- FluxInv is the bag SoT; replace dead BagChangeDispatcher wiring.
    if _G.FluxInv and _G.FluxInv.RegisterListener and not Module._fluxInvListenerRegistered then
        Module._fluxInvListenerRegistered = true
        _G.FluxInv.RegisterListener("NCHearthstone", function(ctx)
            if not Module._registered then return end
            if ShouldHoldItemIdentity() then
                return
            end
            local tier = ctx and ctx.tier
            local countOnly = ctx and ctx.changeKind == "countOnly" and not ctx.force
            if countOnly or tier == "instant" or tier == "light" then
                Module.InvalidateTeleportCache()
                RefreshCountOnly()
                if InCombatLockdown() then return end
                if not countOnly and NeedsHearthIdentityRefresh() then
                    Module.Update()
                end
                return
            end
            FullHearthBagUpdate()
        end, { tier = "scan", regions = { "bags", "equip" }, deferHeavy = true })
    end
end

if FluxEBS_PostLoginBagRefresh and FluxEBS_PostLoginBagRefresh.RegisterPulseEndCallback
    and not Module._hearthPulseEndRegistered then
    Module._hearthPulseEndRegistered = true
    FluxEBS_PostLoginBagRefresh.RegisterPulseEndCallback("NCHearthstone", function()
        if not Module._registered then return end
        if InCombatLockdown() then
            Module._pendingUpdate = true
        else
            Module.Update()
        end
    end)
end

-- ============================================================================
-- FLYOUT BUTTON CLICK HANDLER
-- ============================================================================

-- Legacy / external hook: same result as OnTeleportItemPickedFromFlyout (secure flyout uses onActionUse)
function Module.OnFlyoutButtonClick(itemId, itemName, itemIcon, isEquipment, isEquipped)
    if not itemId then return end
    
    if isEquipment and not isEquipped then
        Module.HandleEquipmentClick(itemId, itemName, itemIcon)
        return
    end
    
    Module.LockToItem(itemId, itemName, itemIcon, isEquipment or false, isEquipped or false)
end

-- ============================================================================
-- FAVORITES LISTENER (delayed registration)
-- ============================================================================

-- Listen for favorites changes to update button
local function RegisterFavoritesListener()
    if not FluxFlyoutFavorites or not FluxFlyoutFavorites.RegisterListener then
        return false
    end
    
    FluxFlyoutFavorites.RegisterListener(function(category)
        if category == "TeleportItem" and Module._registered and not InCombatLockdown() then
            Module.InvalidateTeleportCache()
            Module.Update()
        end
    end)
    return true
end

-- Try to register immediately, then retry with delays
if not RegisterFavoritesListener() then
    Timer.After(0.1, function()
        if not RegisterFavoritesListener() then
            Timer.After(0.5, function()
                if not RegisterFavoritesListener() then
                    Timer.After(1, RegisterFavoritesListener)
                end
            end)
        end
    end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Expose functions for external use
Module.ShowFlyout = Module.ShowTeleportFlyout
Module.GetItems = Module.GetTeleportItems
Module.HasItems = Module.HasTeleportItems

-- ============================================================================
-- EXPORT
-- ============================================================================

_G.FluxNCHearthstone = Module

