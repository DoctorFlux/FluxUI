--[[
    Inventory/FluxEquipSlotCandidates.lua

    Equippable-item lookup for paperdoll slots. Reads Flux.Inventory snapshots
    (Syndicator or builtin) — no independent bag walks.

    Character-window flyouts are bags-only. Bank/warband items are opt-in
    (opts.includeBank) and only while the banker is live so a click can pick
    up and equip — used by respec, not the character sheet.
]]

local addonName, ns = ...
local Flux = ns.Flux

FluxEquipSlotCandidates = FluxEquipSlotCandidates or {}
local Candidates = FluxEquipSlotCandidates

local SLOT_MIN = 1
local SLOT_MAX = 19
local INVSLOT_MAINHAND = _G.INVSLOT_MAINHAND or 16
local INVSLOT_OFFHAND = _G.INVSLOT_OFFHAND or 17

local cacheBags = { bySlot = {}, equipped = {}, key = nil }
local cacheBank = { bySlot = {}, equipped = {}, key = nil }

-- Per-itemID: true = blocked by class/race/skill tooltip, false = ok, nil = unknown.
local tooltipRestrictCache = {}

local PLAYER_CLASS_NAME = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[UnitClassBase and UnitClassBase("player") or select(2, UnitClass("player"))])
    or select(1, UnitClass("player"))
local CLASS_REQ_PATTERN = ITEM_CLASSES_ALLOWED and ITEM_CLASSES_ALLOWED:format("(.*)") or nil

local bound = false

local function Inv()
    return Flux and Flux.Inventory
end

local function ItemClass()
    return _G.FluxItemClass
end

local function WipeOneCache(cache)
    wipe(cache.bySlot)
    wipe(cache.equipped)
    cache.key = nil
end

local function WipeCache()
    WipeOneCache(cacheBags)
    WipeOneCache(cacheBank)
end

local function CacheFor(includeBank)
    return includeBank and cacheBank or cacheBags
end

local function WantsBank(opts)
    return type(opts) == "table" and opts.includeBank == true
end

local function IsTwoHandEquipLoc(equipLoc)
    if not equipLoc or equipLoc == "" then
        return false
    end
    return equipLoc == "INVTYPE_2HWEAPON"
        or equipLoc == "INVTYPE_STAFF"
        or equipLoc == "INVTYPE_POLEARM"
        or equipLoc == "INVTYPE_FISHINGPOLE"
end

local function ParseItemID(itemLink)
    if not itemLink then
        return nil
    end
    local id = itemLink:match("item:(%d+)")
    return id and tonumber(id) or nil
end

local function GetItemEquipLoc(itemID, itemLink)
    local id = itemID
    if (not id or id == 0) and itemLink then
        id = ParseItemID(itemLink)
    end
    if not id or id == 0 then
        return nil
    end

    local ic = ItemClass()
    if ic and ic.GetStatic then
        local static = ic.GetStatic(id)
        if static and type(static.equipLoc) == "string" and static.equipLoc ~= "" then
            return static.equipLoc
        end
    end

    if Flux and Flux.Item and Flux.Item.GetInfo then
        local info = Flux.Item.GetInfo(itemLink or id)
        if type(info) == "table" then
            local loc = info.itemEquipLoc or info.equipLoc
            if type(loc) == "string" and loc ~= "" then
                return loc
            end
        elseif type(info) == "string" then
            local loc = select(9, Flux.Item.GetInfo(itemLink or id))
            if type(loc) == "string" and loc ~= "" then
                return loc
            end
        end
    end

    if type(GetItemInfo) == "function" then
        local loc = select(9, GetItemInfo(itemLink or id))
        if type(loc) == "string" and loc ~= "" then
            return loc
        end
    end

    if C_Item and C_Item.GetItemInfoInstant then
        local ok, r1, r2, r3, r4 = pcall(C_Item.GetItemInfoInstant, id)
        if ok then
            if type(r1) == "table" then
                local loc = r1.itemEquipLoc or r1.equipLoc
                if type(loc) == "string" and loc ~= "" then
                    return loc
                end
            elseif type(r4) == "string" and r4 ~= "" then
                return r4
            end
        end
    end

    return nil
end

local function EquipLocFitsInventorySlot(equipLoc, invSlot)
    if not equipLoc or equipLoc == "" or not invSlot then
        return false
    end
    if invSlot == 5 then
        return equipLoc == "INVTYPE_CHEST" or equipLoc == "INVTYPE_ROBE"
    end
    if invSlot == 11 or invSlot == 12 then
        return equipLoc == "INVTYPE_FINGER"
    end
    if invSlot == 13 or invSlot == 14 then
        return equipLoc == "INVTYPE_TRINKET"
    end
    if invSlot == INVSLOT_MAINHAND then
        return equipLoc == "INVTYPE_WEAPON"
            or equipLoc == "INVTYPE_2HWEAPON"
            or equipLoc == "INVTYPE_STAFF"
            or equipLoc == "INVTYPE_POLEARM"
            or equipLoc == "INVTYPE_WEAPONMAINHAND"
            or equipLoc == "INVTYPE_FISHINGPOLE"
    end
    if invSlot == INVSLOT_OFFHAND then
        return equipLoc == "INVTYPE_WEAPON"
            or equipLoc == "INVTYPE_SHIELD"
            or equipLoc == "INVTYPE_HOLDABLE"
            or equipLoc == "INVTYPE_WEAPONOFFHAND"
    end
    if invSlot == 18 then
        return equipLoc == "INVTYPE_RANGED"
            or equipLoc == "INVTYPE_RANGEDRIGHT"
            or equipLoc == "INVTYPE_THROWN"
    end
    local map = {
        [1] = "INVTYPE_HEAD",
        [2] = "INVTYPE_NECK",
        [3] = "INVTYPE_SHOULDER",
        [4] = "INVTYPE_BODY",
        [6] = "INVTYPE_WAIST",
        [7] = "INVTYPE_LEGS",
        [8] = "INVTYPE_FEET",
        [9] = "INVTYPE_WRIST",
        [10] = "INVTYPE_HAND",
        [15] = "INVTYPE_CLOAK",
        [19] = "INVTYPE_TABARD",
    }
    return map[invSlot] == equipLoc
end

local function GetItemMinLevel(itemID, itemLink)
    local ic = ItemClass()
    if ic and ic.GetInfo then
        local info = ic.GetInfo(itemID)
        if info and type(info.minLevel) == "number" then
            return info.minLevel
        end
    end
    if type(GetItemInfo) == "function" then
        local minLevel = select(5, GetItemInfo(itemLink or itemID))
        if type(minLevel) == "number" then
            return minLevel
        end
    end
    return nil
end

local function IsUnfitForPlayer(itemID)
    if not LibStub then
        return false
    end
    local Unfit = LibStub("Unfit-1.0", true)
    if Unfit and Unfit.IsItemUnusable then
        return Unfit:IsItemUnusable(itemID) and true or false
    end
    return false
end

local function ColorLooksRed(color)
    if not color then
        return false
    end
    if RED_FONT_COLOR and color.IsRGBEqualTo then
        local ok, eq = pcall(color.IsRGBEqualTo, color, RED_FONT_COLOR)
        if ok and eq then
            return true
        end
    end
    local r, g, b = color.r, color.g, color.b
    if type(r) ~= "number" then
        return false
    end
    return r > 0.9 and (g or 0) < 0.35 and (b or 0) < 0.35
end

local function TooltipBlocksEquip(itemID, itemLink)
    if tooltipRestrictCache[itemID] ~= nil then
        return tooltipRestrictCache[itemID]
    end

    local lines
    if C_TooltipInfo then
        local data
        if C_TooltipInfo.GetItemByID then
            local ok, result = pcall(C_TooltipInfo.GetItemByID, itemID)
            if ok then
                data = result
            end
        end
        if (not data or not data.lines) and itemLink and C_TooltipInfo.GetHyperlink then
            local ok, result = pcall(C_TooltipInfo.GetHyperlink, itemLink)
            if ok then
                data = result
            end
        end
        lines = data and data.lines
    end

    if lines then
        local lineTypes = Enum and Enum.TooltipDataLineType
        for i = 1, #lines do
            local line = lines[i]
            if line and TooltipUtil and TooltipUtil.SurfaceArgs then
                pcall(TooltipUtil.SurfaceArgs, line)
            end
            if line then
                local typ = line.type
                if lineTypes and (
                    typ == lineTypes.RestrictedRaceClass
                    or typ == lineTypes.RestrictedLevel
                    or typ == lineTypes.RestrictedSkill
                    or typ == lineTypes.RestrictedFaction
                ) then
                    if ColorLooksRed(line.leftColor) then
                        tooltipRestrictCache[itemID] = true
                        return true
                    end
                end

                local text = line.leftText
                if text and CLASS_REQ_PATTERN and PLAYER_CLASS_NAME then
                    local classList = text:match(CLASS_REQ_PATTERN)
                    if classList then
                        local allowed = classList:find(PLAYER_CLASS_NAME, 1, true) ~= nil
                        tooltipRestrictCache[itemID] = not allowed
                        return not allowed
                    end
                end
            end
        end
        local ic = ItemClass()
        if (ic and ic.IsLoaded and ic.IsLoaded(itemID))
            or (GetItemInfo and select(1, GetItemInfo(itemLink or itemID))) then
            tooltipRestrictCache[itemID] = false
        end
        return false
    end

    local ic = ItemClass()
    if ic and ic.GetTooltipText and CLASS_REQ_PATTERN and PLAYER_CLASS_NAME then
        local text = ic.GetTooltipText(itemID, itemLink)
        if text and text ~= "" then
            local pattern = CLASS_REQ_PATTERN:lower()
            local classList = text:match(pattern)
            if classList then
                local allowed = classList:find(PLAYER_CLASS_NAME:lower(), 1, true) ~= nil
                tooltipRestrictCache[itemID] = not allowed
                return not allowed
            end
            if ic.IsLoaded and ic.IsLoaded(itemID) then
                tooltipRestrictCache[itemID] = false
            end
            return false
        end
    end

    return false
end

local function ItemIsEquippable(itemID)
    if C_Item and C_Item.IsEquippableItem then
        local ok, v = pcall(C_Item.IsEquippableItem, itemID)
        if ok and v ~= nil then
            return v and true or false
        end
    end
    if type(IsEquippableItem) == "function" then
        local ok, v = pcall(IsEquippableItem, itemID)
        if ok and v ~= nil then
            return v and true or false
        end
    end
    return true
end

--- True when this character can equip the item (class/armor/weapon/level/restrictions).
function Candidates.PlayerCanUseEquipment(itemID, itemLink)
    if not itemID or itemID == 0 then
        return false
    end
    local minLevel = GetItemMinLevel(itemID, itemLink)
    if type(minLevel) == "number" and minLevel > 0 then
        local playerLevel = UnitLevel("player") or 1
        if playerLevel < minLevel then
            return false
        end
    end
    if IsUnfitForPlayer(itemID) then
        return false
    end
    if TooltipBlocksEquip(itemID, itemLink) then
        return false
    end
    return true
end

function Candidates.CanItemGoInInventorySlot(itemID, itemLink, invSlot)
    if not itemID or itemID == 0 or not invSlot then
        return false
    end
    local loc = GetItemEquipLoc(itemID, itemLink)
    if not loc or not EquipLocFitsInventorySlot(loc, invSlot) then
        return false
    end
    if invSlot == INVSLOT_OFFHAND and IsTwoHandEquipLoc(loc) then
        return false
    end
    if not ItemIsEquippable(itemID) then
        return false
    end
    if not Candidates.PlayerCanUseEquipment(itemID, itemLink) then
        return false
    end
    return true
end

local function GetItemName(itemID, itemLink)
    local ic = ItemClass()
    if ic and ic.GetName then
        local name = ic.GetName(itemID)
        if name then
            return name
        end
    end
    if type(GetItemInfo) == "function" then
        local name = select(1, GetItemInfo(itemLink or itemID))
        if name then
            return name
        end
    end
    return "#" .. tostring(itemID)
end

local function AddCandidate(list, invSlot, bag, slot, itemID, itemLink, source)
    if not Candidates.CanItemGoInInventorySlot(itemID, itemLink, invSlot) then
        return
    end
    list[#list + 1] = {
        bag = bag,
        slot = slot,
        itemID = itemID,
        itemLink = itemLink,
        name = GetItemName(itemID, itemLink),
        source = source or "bag",
    }
end

function Candidates.SlotHasEquippedItem(invSlot)
    if not invSlot then
        return false
    end
    return GetInventoryItemTexture("player", invSlot) ~= nil
end

local function CanTakeFromBank()
    local api = Inv()
    if api and api.CanTakeFromBank then
        return api.CanTakeFromBank() and true or false
    end
    if api and api.IsBankLive then
        return api.IsBankLive() and true or false
    end
    return false
end

function Candidates.ShouldOfferEmpty(invSlot, includeBank)
    -- Hide "Empty" only when this list is actually offering take-from-bank
    -- items. Character-window (bags-only) flyouts still allow unequip.
    if includeBank and CanTakeFromBank() then
        return false
    end
    return Candidates.SlotHasEquippedItem(invSlot)
end

local SLOT_TEXTURE_NAMES = {
    [1] = "HeadSlot",
    [2] = "NeckSlot",
    [3] = "ShoulderSlot",
    [4] = "ShirtSlot",
    [5] = "ChestSlot",
    [6] = "WaistSlot",
    [7] = "LegsSlot",
    [8] = "FeetSlot",
    [9] = "WristSlot",
    [10] = "HandsSlot",
    [11] = "Finger0Slot",
    [12] = "Finger1Slot",
    [13] = "Trinket0Slot",
    [14] = "Trinket1Slot",
    [15] = "BackSlot",
    [16] = "MainHandSlot",
    [17] = "SecondaryHandSlot",
    [18] = "RangedSlot",
    [19] = "TabardSlot",
}

function Candidates.GetEmptySlotTexture(invSlot, anchor)
    if anchor and anchor.backgroundTextureName then
        return anchor.backgroundTextureName
    end
    local slotName = SLOT_TEXTURE_NAMES[invSlot]
    if slotName and GetInventorySlotInfo then
        local _, texture = GetInventorySlotInfo(slotName)
        if texture then
            return texture
        end
    end
    return "Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck"
end

local function PickupContainer(bag, slot)
    if Flux and Flux.Container and Flux.Container.PickupItem then
        Flux.Container.PickupItem(bag, slot)
        return
    end
    if C_Container and C_Container.PickupContainerItem then
        C_Container.PickupContainerItem(bag, slot)
        return
    end
    if PickupContainerItem then
        PickupContainerItem(bag, slot)
    end
end

function Candidates.UnequipInventorySlot(invSlot)
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    local api = Inv()
    if not invSlot or not api or not api.GetFirstFreeBagSlot then
        return false
    end
    local bag, slot = api.GetFirstFreeBagSlot()
    if not bag or not slot then
        return false
    end
    if IsInventoryItemLocked and IsInventoryItemLocked(invSlot) then
        return false
    end

    ClearCursor()
    if PickupInventoryItem then
        PickupInventoryItem(invSlot)
    end
    PickupContainer(bag, slot)
    ClearCursor()
    return true
end

local function AddEmptyCandidate(list)
    list[#list + 1] = {
        isEmpty = true,
        itemID = 0,
        name = _G.EMPTY or "Empty",
    }
end

local function CurrentCacheKey(includeBank)
    local api = Inv()
    local bags = api and api.GetSnapshotGeneration and api.GetSnapshotGeneration("bags") or 0
    local equip = api and api.GetSnapshotGeneration and api.GetSnapshotGeneration("equip") or 0
    if not includeBank then
        return bags .. ":" .. equip .. ":g"
    end
    local canTake = CanTakeFromBank() and 1 or 0
    local bank = 0
    local warband = 0
    if canTake == 1 then
        bank = api and api.GetSnapshotGeneration and api.GetSnapshotGeneration("bank") or 0
        warband = api and api.GetSnapshotGeneration and api.GetSnapshotGeneration("warband") or 0
    end
    return bags .. ":" .. bank .. ":" .. warband .. ":" .. equip .. ":" .. canTake
end

local function BuildCandidates(invSlot, includeBank)
    local list = {}
    local api = Inv()
    if not api or not api.ForEachLocation then
        return list
    end

    -- Cached bank snapshots stay populated while the bank is closed. Only
    -- offer those locations when the caller opted in and the banker is live.
    local bankLive = includeBank and CanTakeFromBank() or false
    local includeWarband = bankLive and api.HasWarband and api.HasWarband() or false

    api.ForEachLocation(function(loc)
        local source = loc.region == "bags" and "bag" or loc.region
        AddCandidate(list, invSlot, loc.bag, loc.slot, loc.itemID, loc.link, source)
    end, {
        bags = true,
        bank = bankLive,
        warband = includeWarband,
        equipped = false,
    })

    if Candidates.ShouldOfferEmpty(invSlot, includeBank) then
        AddEmptyCandidate(list)
    end

    table.sort(list, function(a, b)
        if a.isEmpty then
            return false
        end
        if b.isEmpty then
            return true
        end
        local sa = a.source == "bag" and 0 or 1
        local sb = b.source == "bag" and 0 or 1
        if sa ~= sb then
            return sa < sb
        end
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)

    return list
end

function Candidates.Invalidate()
    WipeCache()
    wipe(tooltipRestrictCache)
end

function Candidates.GetForInventorySlot(invSlot, anchor, opts)
    if type(anchor) == "table" and opts == nil then
        opts = anchor
    end
    if not invSlot or invSlot < SLOT_MIN or invSlot > SLOT_MAX then
        return {}
    end

    local includeBank = WantsBank(opts)
    local cache = CacheFor(includeBank)
    local key = CurrentCacheKey(includeBank)
    if cache.key ~= key then
        WipeOneCache(cache)
        cache.key = key
    end

    local hasEquipped = Candidates.SlotHasEquippedItem(invSlot)
    if not cache.bySlot[invSlot] or cache.equipped[invSlot] ~= hasEquipped then
        cache.bySlot[invSlot] = BuildCandidates(invSlot, includeBank)
        cache.equipped[invSlot] = hasEquipped
    end

    return cache.bySlot[invSlot]
end

function Candidates.HasAlternatives(invSlot, anchor, opts)
    if type(anchor) == "table" and opts == nil then
        opts = anchor
    end
    local list = Candidates.GetForInventorySlot(invSlot, anchor, opts)
    return type(list) == "table" and #list > 0
end

function Candidates.EquipToInventorySlot(bag, bagSlot, invSlot)
    if InCombatLockdown and InCombatLockdown() then
        return false
    end
    if bag == nil or not bagSlot or not invSlot then
        return false
    end

    ClearCursor()
    PickupContainer(bag, bagSlot)
    local cursorType = GetCursorInfo and GetCursorInfo()
    if cursorType then
        if EquipCursorItem then
            EquipCursorItem(invSlot)
        elseif PickupInventoryItem then
            PickupInventoryItem(invSlot)
        end
        ClearCursor()
    end
    return true
end

local function BindInventory()
    if bound then
        return
    end
    local api = Inv()
    if not api or not api.Register then
        return
    end
    bound = true
    api.Register("FluxEquipSlotCandidates", function()
        Candidates.Invalidate()
    end)
    if api.RegisterBankStateListener then
        api.RegisterBankStateListener("FluxEquipSlotCandidates", function()
            Candidates.Invalidate()
            local fly = _G.FluxEquipSlotFlyout
            if fly and fly._frame and fly._frame.IsShown and fly._frame:IsShown()
                and fly.Show and fly._anchorRef and fly._openSlotID then
                fly.Show(fly._anchorRef, fly._openSlotID)
            end
            local gp = _G.FluxRespec and _G.FluxRespec.GearPicker
            if gp and gp.IsOpenFor and gp._anchorRef and gp._openSlotID and gp.Show
                and gp.IsOpenFor(gp._openSlotID, gp._anchorRef) then
                gp.Show(gp._anchorRef, gp._openSlotID)
            end
        end)
    end
end

BindInventory()
if Flux and Flux.AfterLoad then
    Flux.AfterLoad(BindInventory)
end

if Flux and Flux.Events and Flux.Events.Register then
    Flux.Events.Register("PLAYER_LEVEL_UP", function()
        Candidates.Invalidate()
    end)
    Flux.Events.Register("PLAYER_SPECIALIZATION_CHANGED", function()
        Candidates.Invalidate()
    end)
    Flux.Events.Register("SKILL_LINES_CHANGED", function()
        Candidates.Invalidate()
    end)
end

_G.FluxEquipSlotCandidates = Candidates
return Candidates
