--[[
    ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua
    Mount button facade + journal/companion collection path (SmartMount / VendorMount).

    Bag-item flyout (Classic Era / TBC): MountItems.lua
    Client detection / vendor helpers: MountCollection.lua
    Config UI: FluxSmartMountConfig.lua

    - Smart mount macro with ground/flying detection
    - Middle-click: SmartMount <-> VendorMount when vendor mounts owned
    - Right-click: Open Mount Journal / companions (collection clients)
    - Column priority: 2, Order: 2
]]

-- Create namespace
FluxNCMount = FluxNCMount or {}
local Module = FluxNCMount

-- Local references (safely captured)
local C_MountJournal = C_MountJournal

-- Constants
Module.COLUMN_PRIORITY = 2
Module.ORDER = 2
Module.MODE_SMART = "SmartMount"
Module.MODE_VENDOR = "VendorMount"

-- Vendor mount IDs (for detection)
local VENDOR_MOUNT_IDS = {
    -- Trader's Gilded Brutosaur (BFA)
    [460] = "Trader's Gilded Brutosaur",
    -- Grand Expedition Yak (MoP)  
    [460] = "Grand Expedition Yak",
    -- Traveler's Tundra Mammoth (WotLK)
    [284] = "Traveler's Tundra Mammoth",
    [280] = "Traveler's Tundra Mammoth",
}

-- Vendor mount names (for lookup)
local VENDOR_MOUNT_NAMES = {
    "Trader's Gilded Brutosaur",
    "Grand Expedition Yak",
    "Traveler's Tundra Mammoth",
}

-- Specific vendor mount names for macro building
local BRUTOSAUR_NAME = "Trader's Gilded Brutosaur"
local YAK_NAME = "Grand Expedition Yak"

-- State
Module._grid = nil
Module._button = nil
Module._registered = false
Module._mode = Module.MODE_SMART
Module._isPlaceholder = false
Module._cachedMounts = nil
Module._cacheTime = 0
local CACHE_DURATION = 5  -- Cache mount list for 5 seconds

-- Lock state (for sticky mount feature)
Module._lockedMount = nil      -- { name = "Mount Name", icon = texture, spellID = number }
Module._isLocked = false
Module._isCasting = false
Module._pendingLockMount = nil -- Mount to lock to when cast starts
Module._castLockSpellId = nil

-- Modifier tracking state for live icon updates (legacy clients)
local lastBagMountIconModState = ""

-- Icon protection state (prevents external code from changing our icon)
local _iconManagedByModule = false
local _lastSetIcon = nil
local SetProtectedIcon -- forward declare (defined near SetupIconProtection)

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

-- Held modifier helpers (must be declared before Unlock / PreClick / icon refresh call sites)
local function GetModifierState()
    local state = ""
    if IsShiftKeyDown and IsShiftKeyDown() then state = state .. "S" end
    if IsControlKeyDown and IsControlKeyDown() then state = state .. "C" end
    if IsAltKeyDown and IsAltKeyDown() then state = state .. "A" end
    return state
end

local function GetCurrentHeldModKey()
    local tokens = {}
    if IsControlKeyDown and IsControlKeyDown() then table.insert(tokens, "ctrl") end
    if IsShiftKeyDown and IsShiftKeyDown() then table.insert(tokens, "shift") end
    if IsAltKeyDown and IsAltKeyDown() then table.insert(tokens, "alt") end
    if #tokens == 0 then return "nomod" end
    return table.concat(tokens, "+")
end

-- ============================================================================
-- API DETECTION (FluxAPICompat integration)
-- ============================================================================

local function HasMountJournalAPI()
    -- Check FluxAPICompat first
    if FLUX_API and FLUX_API.hasC_MountJournal ~= nil then
        return FLUX_API.hasC_MountJournal
    end
    -- Fallback check
    return C_MountJournal ~= nil and C_MountJournal.GetMountIDs ~= nil
end

local function HasCompanionAPI()
    return GetNumCompanions ~= nil
end

-- ============================================================================
-- VERSION DETECTION (must be before HasMountUI)
-- ============================================================================

local function GetMajorVersion()
    if FLUX_API and FLUX_API.majorVersion then
        return FLUX_API.majorVersion
    end
    local v = GetBuildInfo()
    return tonumber(type(v) == "string" and v:match("^(%d+)") or 0) or 0
end

-- Check if any mount UI is available (mount journal or companion system)
-- Vanilla and TBC don't have mount UIs - mounts are items in bags
local function HasMountUI()
    -- Explicitly check for Classic Era and TBC - they don't have mount UIs
    if FLUX_API then
        if FLUX_API.isClassicEra or FLUX_API.isTBC then
            return false
        end
    end
    
    -- Version-based fallback: major version 1 = Vanilla, 2 = TBC (no mount UI)
    local majorVer = GetMajorVersion()
    if majorVer <= 2 then
        return false
    end
    
    -- WotLK+ has companion system (majorVersion 3+), MoP+ has mount journal (5+)
    return HasMountJournalAPI() or HasCompanionAPI()
end
Module.HasMountUI = HasMountUI

local function IsClassicEra()
    return GetMajorVersion() == 1
end

local function IsLegacyClient()
    if FLUX_API and FLUX_API.isLegacyClient ~= nil then
        return FLUX_API.isLegacyClient
    end
    local _, b = GetBuildInfo()
    local bn = tonumber(b) or 0
    return bn > 0 and bn < 15000
end

local SWITCH_FLIGHT_STYLE_SPELL_ID = 404464
local SWITCH_FLIGHT_STYLE_NAME = "Switch Flight Style"

local function HasSwitchFlightStyle()
    if GetMajorVersion() >= 10 then
        if C_Spell and C_Spell.DoesSpellExist then
            return C_Spell.DoesSpellExist(SWITCH_FLIGHT_STYLE_SPELL_ID)
        elseif IsSpellKnown then
            return IsSpellKnown(SWITCH_FLIGHT_STYLE_SPELL_ID)
        end
    end
    return false
end

local function IsSwitchFlightStyleSpell(spellID, name)
    if spellID and spellID == SWITCH_FLIGHT_STYLE_SPELL_ID then
        return true
    end
    if name and name == SWITCH_FLIGHT_STYLE_NAME then
        return true
    end
    return false
end

local function IsFlightStyleLockActive()
    local locked = Module._lockedMount
    if locked and IsSwitchFlightStyleSpell(locked.spellID, locked.name) then
        return true
    end
    local pending = Module._pendingLockMount
    if pending and IsSwitchFlightStyleSpell(pending.spellID, pending.name) then
        return true
    end
    return false
end

local function GetSwitchFlightStyleIcon()
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(SWITCH_FLIGHT_STYLE_SPELL_ID)
    elseif GetSpellTexture then
        return GetSpellTexture(SWITCH_FLIGHT_STYLE_SPELL_ID)
    end
    return nil
end

-- Resolve mod flags for journal macros (same priority as BuildSmartMountMacro lines).
-- forcedModKey supports "nomod", "shift", "ctrl", "alt", and compounds like "ctrl+alt".
local function ResolveJournalModFlags(forcedModKey)
    if type(forcedModKey) == "string" and forcedModKey ~= "" then
        local key = forcedModKey:lower()
        if key == "nomod" then
            return false, false, false
        end
        local isShift = key:find("shift", 1, true) ~= nil
        local isCtrl = key:find("ctrl", 1, true) ~= nil
        local isAlt = key:find("alt", 1, true) ~= nil
        return isShift, isCtrl, isAlt
    end
    local isShift = IsShiftKeyDown and IsShiftKeyDown() or false
    local isCtrl = IsControlKeyDown and IsControlKeyDown() or false
    local isAlt = IsAltKeyDown and IsAltKeyDown() or false
    return isShift, isCtrl, isAlt
end

-- Unlock flight-style sticky lock (cast ends; player is not mounted).
local function UnlockSwitchFlightStyleIfNeeded()
    if not IsFlightStyleLockActive() then
        return false
    end

    local wasLocked = Module._isLocked
    Module._pendingLockMount = nil
    Module._isCasting = false
    ClearCastLockSpellId()

    if wasLocked then
        if not InCombatLockdown() then
            Module.Unlock()
        else
            -- Regen handler unlocks when not mounted; force macro re-apply then
            Module._lastJournalMacro = nil
            Module._lastBagMountMacro = nil
            Module._pendingUpdate = true
        end
    elseif not InCombatLockdown() then
        -- Instant cast never reached LockToMount, but still force smart/vendor macro + icon
        Module._lastJournalMacro = nil
        Module._lastBagMountMacro = nil
        Module._currentTexture = nil
        _lastSetIcon = nil
        if Module.Update then
            Module.Update()
        end
        lastBagMountIconModState = ""
        if HasMountUI() then
            Module.UpdateJournalMountIcon(GetCurrentHeldModKey())
        elseif Module.UpdateBagMountIcon then
            Module.UpdateBagMountIcon(GetCurrentHeldModKey())
        end
        if FluxModifierTracker and FluxModifierTracker.NotifyActiveChanged then
            FluxModifierTracker.NotifyActiveChanged()
        end
    else
        Module._lastJournalMacro = nil
        Module._lastBagMountMacro = nil
        Module._pendingUpdate = true
    end
    return true
end

local function GetMountFlyable()
    local Flux = _G.Flux
    if Flux and Flux.Inventory and Flux.Inventory.Flyable then
        return Flux.Inventory.Flyable
    end
    if FluxItemDetection then
        return FluxItemDetection
    end
    return _G.FluxInv and _G.FluxInv.Spells
end

-- Journal: IsFlyableArea / [flyable]. Bag items: continent+outdoors when that API is missing.
local function IsFlyableAreaFixed()
    local F = GetMountFlyable()
    if F and F.PreferFlying then
        return F.PreferFlying()
    end
    if F and F.IsFlyableHere then
        return F.IsFlyableHere()
    end
    if IsFlyableArea and IsFlyableArea() then
        return true
    end
    return false
end

-- Get item name by ID (helper for favorites)
local function GetItemNameById(itemId)
    if not itemId then return nil end
    if GetItemInfo then
        return select(1, GetItemInfo(itemId))
    end
    return nil
end

-- Get icon for mount by name (helper for legacy client icon resolution)
local function GetMountIcon(mountName)
    if not mountName then return nil end
    
    -- Method 1: Companion system (WotLK/Cata/MoP)
    if GetNumCompanions then
        for i = 1, GetNumCompanions("MOUNT") or 0 do
            local creatureID, creatureName, creatureSpellID, icon = GetCompanionInfo("MOUNT", i)
            if creatureName == mountName then
                if icon then return icon end
                -- Fallback: get spell texture
                if creatureSpellID then
                    if GetSpellTexture then
                        local spellIcon = GetSpellTexture(creatureSpellID)
                        if spellIcon then return spellIcon end
                    end
                end
            end
        end
    end
    
    -- Method 2: Mount journal (modern clients)
    if C_MountJournal and C_MountJournal.GetMountIDs then
        local ids = C_MountJournal.GetMountIDs()
        if type(ids) == "table" then
            for _, id in ipairs(ids) do
                local name, spellID, icon = C_MountJournal.GetMountInfoByID(id)
                if name == mountName then
                    return icon or (spellID and GetSpellTexture and GetSpellTexture(spellID))
                end
            end
        end
    end
    
    -- Method 3: Bag-based mount items (TBC/Vanilla)
    local itemIcon = GetItemIcon and GetItemIcon(mountName)
    if itemIcon then return itemIcon end
    
    -- Method 4: Fallback icons based on keywords
    local lower = string.lower(mountName)
    if lower:find("mechanostrider") then return "Interface\\Icons\\Ability_Mount_MechaStrider" end
    if lower:find("horse") or lower:find("charger") or lower:find("steed") then return "Interface\\Icons\\Ability_Mount_NightmareHorse" end
    if lower:find("wolf") then return "Interface\\Icons\\Ability_Mount_WhiteDireWolf" end
    if lower:find("tiger") or lower:find("saber") or lower:find("panther") then return "Interface\\Icons\\Ability_Mount_BlackPanther" end
    if lower:find("ram") then return "Interface\\Icons\\Ability_Mount_MountainRam" end
    if lower:find("raptor") then return "Interface\\Icons\\Ability_Mount_Raptor" end
    if lower:find("kodo") then return "Interface\\Icons\\Ability_Mount_Kodo_01" end
    if lower:find("gryphon") then return "Interface\\Icons\\Ability_Mount_Gryphon_01" end
    if lower:find("wind rider") or lower:find("wyvern") then return "Interface\\Icons\\Ability_Mount_Wyvern_01" end
    if lower:find("yak") then return "Interface\\Icons\\ability_mount_travellersyakmount" end
    if lower:find("brutosaur") then return "Interface\\Icons\\inv_brutosaur" end
    if lower:find("mammoth") then return "Interface\\Icons\\ability_mount_mammoth_brown" end
    
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- ============================================================================
-- COMPREHENSIVE MOUNT DETECTION
-- ============================================================================

-- Check if player has any collected mount
local collectedMountKnown = nil  -- nil = unknown, true/false = cached
local collectedMountCacheTime = 0
local COLLECTED_MOUNT_CACHE_TTL = 300

function Module.InvalidateCollectedMountCache()
    collectedMountKnown = nil
    collectedMountCacheTime = 0
    if FluxNCMountCollection and FluxNCMountCollection.InvalidateCollectedMountMap then
        FluxNCMountCollection.InvalidateCollectedMountMap()
    end
end

function Module.HasAnyMount()
    if collectedMountKnown == true then
        return true
    end
    if collectedMountKnown == false and collectedMountCacheTime > 0
        and (GetTime() - collectedMountCacheTime) < COLLECTED_MOUNT_CACHE_TTL then
        return false
    end

    local pl = _G.FluxEBS_PostLoginBagRefresh
    local loginBootstrap = pl and pl.IsFreshLoginBootstrap and pl.IsFreshLoginBootstrap()

    local function finish(result)
        collectedMountKnown = result
        collectedMountCacheTime = GetTime()
        return result
    end

    -- Method 1: Modern mount journal (Retail, modern Classic)
    if HasMountJournalAPI() then
        if C_MountJournal.GetMountIDs then
            local ids = C_MountJournal.GetMountIDs()
            if type(ids) == "table" then
                for _, id in ipairs(ids) do
                    local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(id)
                    if isCollected then return finish(true) end
                end
            end
        elseif C_MountJournal.GetNumDisplayedMounts and C_MountJournal.GetDisplayedMountInfo then
            local n = C_MountJournal.GetNumDisplayedMounts()
            for i = 1, (n or 0) do
                local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetDisplayedMountInfo(i)
                if isCollected then return finish(true) end
            end
        end
        -- Journal empty during login bootstrap: don't cache negative yet
        if loginBootstrap then
            return true
        end
    end
    
    -- Method 2: Companion system (WotLK/Cata/MoP)
    if HasCompanionAPI() then
        local numMounts = GetNumCompanions("MOUNT") or 0
        if numMounts > 0 then return finish(true) end
    end
    
    -- Method 3: Bag mount items (FluxInv / soft ItemDetection shim)
    local Spells = _G.FluxInv and _G.FluxInv.Spells
    if Spells and Spells.ScanBagsForAllMountItems then
        local list = Spells.ScanBagsForAllMountItems()
        if list and #list > 0 then
            return finish(true)
        end
    elseif FluxItemDetection and FluxItemDetection.HasAnyCollectedMount then
        return finish(FluxItemDetection.HasAnyCollectedMount())
    end
    
    return finish(false)
end

-- Check if player has any mounts specifically in bags (not just collected mounts)
-- This replicates the old FluxButtonGrid logic for bag-based mount detection
local mountBagCache = nil
local mountBagCacheTime = 0
local MOUNT_BAG_CACHE_DURATION = 5  -- Cache for 5 seconds

-- Forward decl: defined with bag-update helpers; used by Register / login refresh
local InvalidateAllMountItemCaches
local InvalidateMountItemCachesForSettle
local IsBagMountLocationSettling
local RefreshBagMountIconForLocation
local RememberGoodBagMount
local ClearGoodBagMount

local function IsMountCacheValid(cacheTime)
    return cacheTime and (GetTime() - cacheTime) < MOUNT_BAG_CACHE_DURATION
end

local function GetMountScanTooltip()
    -- Create reusable tooltip for mount scanning
    if not _G.FluxMountScanTooltip then
        local tooltip = CreateFrame("GameTooltip", "FluxMountScanTooltip", UIParent, "GameTooltipTemplate")
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        _G.FluxMountScanTooltip = tooltip
    end
    return _G.FluxMountScanTooltip
end

local function IsItemAMount(itemId)
    if not itemId then return false end

    local Spells = _G.FluxInv and _G.FluxInv.Spells
    if Spells and Spells.IsItemAMount then
        return Spells.IsItemAMount(itemId)
    end
    if FluxItemDetection and FluxItemDetection.IsItemAMount then
        return FluxItemDetection.IsItemAMount(itemId)
    end

    -- Method 1: Check item class/subclass (fast path, no tooltip needed)
    local classId, subclassId
    if C_Item and C_Item.GetItemInfoInstant then
        _, _, _, _, _, classId, subclassId = C_Item.GetItemInfoInstant(itemId)
    elseif GetItemInfoInstant then
        _, _, _, _, _, classId, subclassId = GetItemInfoInstant(itemId)
    end

    if classId and subclassId then
        local miscClass = (Enum and Enum.ItemClass and Enum.ItemClass.Miscellaneous) or 15
        local mountSub = (Enum and Enum.ItemMiscellaneousSubclass and Enum.ItemMiscellaneousSubclass.Mount) or 5
        if classId == miscClass and subclassId == mountSub then
            return true
        end
    end

    if C_MountJournal and C_MountJournal.GetMountFromItem then
        return C_MountJournal.GetMountFromItem(itemId) ~= nil
    end

    return false
end

function Module.HasAnyMountInBags()
    local pl = _G.FluxEBS_PostLoginBagRefresh
    local skipNegativeCache = pl and pl.IsFreshLoginBootstrap and pl.IsFreshLoginBootstrap()
    if not skipNegativeCache then
        if IsBagMountLocationSettling and IsBagMountLocationSettling() then
            skipNegativeCache = true
        else
            local B = _G.FluxEBSConsumableBridge
            if B and B.ShouldHoldItemIdentity and B.ShouldHoldItemIdentity() then
                skipNegativeCache = true
            end
        end
    end
    -- Return cached result if still valid (do not cache "no mounts" during load-screen hold)
    if IsMountCacheValid(mountBagCacheTime) then
        if mountBagCache ~= nil or not skipNegativeCache then
            return mountBagCache ~= nil
        end
    end

    -- Prefer MountItems / FluxInv bag scan only (never treat journal collection as "in bags")
    if FluxNCMountItems and FluxNCMountItems.HasAnyMountInBags then
        local has = FluxNCMountItems.HasAnyMountInBags()
        if has then
            local list = FluxNCMountItems.GetBagMountItems and FluxNCMountItems.GetBagMountItems(true)
            local first = list and list[1]
            mountBagCache = first and {
                itemId = first["$itemId"],
                name = first["$name"],
            } or { bagMounts = true }
            mountBagCacheTime = GetTime()
            return true
        end
    end

    local Spells = _G.FluxInv and _G.FluxInv.Spells
    if Spells and Spells.ScanBagsForAllMountItems then
        local list = Spells.ScanBagsForAllMountItems()
        if list and #list > 0 then
            local first = list[1]
            mountBagCache = { itemId = first.itemId or first["$itemId"], name = first.name or first["$name"] }
            mountBagCacheTime = GetTime()
            return true
        end
    end

    -- Direct bag walk fallback
    local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or _G.GetContainerNumSlots
    local GetItemID = FluxGetContainerItemID or (C_Container and C_Container.GetContainerItemID) or _G.GetContainerItemID
    local bagIDs = {}
    if _G.FluxInv and _G.FluxInv.GetCarriedBagIDs then
        bagIDs = _G.FluxInv.GetCarriedBagIDs() or {}
    elseif _G.FluxInv and _G.FluxInv.Containers and _G.FluxInv.Containers.GetCarriedBagIDs then
        bagIDs = _G.FluxInv.Containers.GetCarriedBagIDs() or {}
    else
        local numBagSlots = (FLUX_API and FLUX_API.isPostDF) and 5 or (NUM_BAG_SLOTS or 4)
        for bag = 0, numBagSlots do bagIDs[#bagIDs + 1] = bag end
    end

    for _, bag in ipairs(bagIDs) do
        local numSlots = GetContainerNumSlots and GetContainerNumSlots(bag) or 0

        for slot = 1, numSlots do
            local itemId = GetItemID and GetItemID(bag, slot)

            if itemId and IsItemAMount(itemId) then
                local name = GetItemInfo(itemId) or ("Item " .. itemId)
                mountBagCache = { itemId = itemId, name = name }
                mountBagCacheTime = GetTime()
                return true
            end
        end
    end

    -- Cache the nil result too (not during load-screen hold / login bootstrap)
    if not skipNegativeCache then
        mountBagCache = nil
        mountBagCacheTime = GetTime()
    end
    return false
end

-- Check if player has riding skill (by name, not ID)
local ridingSkillCache = nil
local ridingSkillCacheTime = 0
local RIDING_SKILL_CACHE_TTL = 60

function Module.InvalidateRidingSkillCache()
    ridingSkillCache = nil
    ridingSkillCacheTime = 0
end

function Module.HasRidingSkill()
    if ridingSkillCache ~= nil and ridingSkillCacheTime > 0
        and (GetTime() - ridingSkillCacheTime) < RIDING_SKILL_CACHE_TTL then
        return ridingSkillCache
    end

    local function finish(result)
        ridingSkillCache = result
        ridingSkillCacheTime = GetTime()
        return result
    end

    -- Dragonflight+ Retail ONLY has automatic riding at level 10
    -- Don't apply this to Classic clients
    if FLUX_API and FLUX_API.isRetail and GetMajorVersion() >= 10 then
        local playerLevel = UnitLevel("player") or 0
        if playerLevel >= 10 then
            return finish(true)
        end
    end
    
    -- Check FluxItemDetection first (comprehensive detection)
    if FluxItemDetection and FluxItemDetection.HasAnyRidingSkillLearned then
        if FluxItemDetection.HasAnyRidingSkillLearned() then
            return finish(true)
        end
    end
    
    -- Primary method: Scan spellbook by name for riding-related spells
    -- This works across all client versions without relying on spell IDs
    if GetNumSpellTabs and GetSpellTabInfo then
        local numTabs = GetNumSpellTabs()
        if numTabs and numTabs > 0 then
            for tab = 1, numTabs do
                local ok, tabName, tabTexture, offset, numSpells = pcall(GetSpellTabInfo, tab)
                if ok and offset and numSpells then
                    for i = offset + 1, offset + numSpells do
                        -- Try different methods to get spell name
                        local spellName = nil
                        
                        -- Method 1: GetSpellBookItemName (most common on legacy)
                        if GetSpellBookItemName then
                            local ok2, name = pcall(GetSpellBookItemName, i, "spell")
                            if ok2 and name then
                                spellName = name
                            end
                        end
                        
                        -- Method 2: GetSpellInfo with spell index (some clients)
                        if not spellName and GetSpellInfo then
                            local ok2, name = pcall(GetSpellInfo, i, "spell")
                            if ok2 and name then
                                spellName = name
                            end
                        end
                        
                        -- Method 3: Try GetSpellBookItemInfo (modern clients)
                        if not spellName and GetSpellBookItemInfo then
                            local ok2, itemType, itemID = pcall(GetSpellBookItemInfo, i, "spell")
                            if ok2 and itemType == "SPELL" and itemID then
                                local ok3, name = pcall(GetSpellInfo, itemID)
                                if ok3 and name then
                                    spellName = name
                                end
                            end
                        end
                        
                        -- Check if spell name contains riding skill keywords (be more specific)
                        if spellName then
                            local lowerName = spellName:lower()
                            
                            -- Exclude mount summon spells - only look for actual riding skills
                            -- Riding skills typically contain "riding" or specific patterns
                            if lowerName:find("summon") or lowerName:find("call") then
                                -- Skip mount summon spells
                            elseif lowerName:find("riding") then
                                -- Any spell with "riding" in the name is likely a riding skill
                                return finish(true)
                            elseif lowerName:find("horsemanship") then
                                -- Undead racial
                                return finish(true)
                            elseif lowerName:find("piloting") and (lowerName:find("mechano") or lowerName:find("strider")) then
                                -- Gnome racial - Mechanostrider Piloting
                                return finish(true)
                            elseif (lowerName:find("apprentice") or lowerName:find("journeyman") or 
                                   lowerName:find("expert") or lowerName:find("artisan") or 
                                   lowerName:find("master")) and lowerName:find("riding") then
                                -- Modern riding skills (Apprentice Riding, etc.)
                                return finish(true)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Check for class mount spells by name (Warlock/Paladin)
    -- These imply riding skill because you can't cast them without it
    local class = select(2, UnitClass("player"))
    if class == "WARLOCK" or class == "PALADIN" then
        -- Check for class-specific mount spells by name
        local classMountNames = {
            -- Warlock mounts
            "felsteed",
            "dreadsteed",
            -- Paladin mounts
            "warhorse",
            "charger",
        }
        
        -- Scan spellbook for these mount names
        if GetNumSpellTabs and GetSpellTabInfo then
            local numTabs = GetNumSpellTabs()
            if numTabs and numTabs > 0 then
                for tab = 1, numTabs do
                    local ok, tabName, tabTexture, offset, numSpells = pcall(GetSpellTabInfo, tab)
                    if ok and offset and numSpells then
                        for i = offset + 1, offset + numSpells do
                            local spellName = nil
                            
                            if GetSpellBookItemName then
                                local ok2, name = pcall(GetSpellBookItemName, i, "spell")
                                if ok2 and name then
                                    spellName = name:lower()
                                end
                            end
                            
                            if spellName then
                                for _, mountName in ipairs(classMountNames) do
                                    -- Exact match or contains the mount name (but not "summon mount")
                                    if spellName == mountName or (spellName:find(mountName) and not spellName:find("summon")) then
                                        return finish(true)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Method 4: Scan Skills tab (GetSkillLineInfo)
    -- Important for Vanilla/TBC/Classic where Riding is a skill in the character sheet (K)
    if GetNumSkillLines and GetSkillLineInfo then
        local numSkills = GetNumSkillLines()
        for i = 1, numSkills do
            local skillName = GetSkillLineInfo(i)
            if skillName then
                local lowerName = skillName:lower()
                if lowerName:find("riding") then
                    return finish(true)
                end
            end
        end
    end

    return finish(false)
end

-- Get collected mount by name (uses MountCollection name→mount map)
local function GetCollectedMountByName(mountName)
    if not mountName then return nil end
    if FluxNCMountCollection and FluxNCMountCollection.GetCollectedMountByName then
        return FluxNCMountCollection.GetCollectedMountByName(mountName)
    end
    if not HasMountJournalAPI() then return nil end
    if C_MountJournal.GetMountIDs then
        local ids = C_MountJournal.GetMountIDs()
        if type(ids) == "table" then
            for _, id in ipairs(ids) do
                local name, spellID, icon, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(id)
                if isCollected and name and name:lower() == mountName:lower() then
                    return { id = id, name = name, spellID = spellID, icon = icon }
                end
            end
        end
    end
    return nil
end

-- Check if player has collected a mount by name
local function HasCollectedMountByName(mountName)
    return GetCollectedMountByName(mountName) ~= nil
end

-- ============================================================================
-- VENDOR MOUNT DETECTION
-- ============================================================================

-- Check if player has any vendor mount
function Module.HasAnyVendorMount()
    if _G.FluxSmartMountConfig and _G.FluxSmartMountConfig.HasAnyVendorMount then
        return _G.FluxSmartMountConfig.HasAnyVendorMount()
    end
    
    -- Fallback check
    if not HasMountJournalAPI() then return false end
    
    for _, mountName in ipairs(VENDOR_MOUNT_NAMES) do
        if HasCollectedMountByName(mountName) then
            return true
        end
    end
    
    return false
end

-- Get the best vendor mount (priority: Brutosaur > Yak > Mammoth)
function Module.GetBestVendorMount()
    if _G.FluxSmartMountConfig and _G.FluxSmartMountConfig.GetVendorMount then
        local vendorMountName = _G.FluxSmartMountConfig.GetVendorMount()
        if vendorMountName then
            -- Return mount data structure
            local mount = GetCollectedMountByName(vendorMountName)
            if mount then
                return mount
            end
        end
    end
    
    -- Fallback check
    if not HasMountJournalAPI() then return nil end
    
    for _, mountName in ipairs(VENDOR_MOUNT_NAMES) do
        local mount = GetCollectedMountByName(mountName)
        if mount then
            return mount
        end
    end
    
    return nil
end

-- ============================================================================
-- MOUNT CONFIGURATION (from FluxSmartMountConfig)
-- ============================================================================

-- Get mount configuration from FluxSmartMountConfig
function Module.GetMountConfig()
    local config = _G.FluxSmartMountConfig
    if config and config.GetGroundMount and config.GetFlyingMount and config.GetMultiMount then
        local ground = config.GetGroundMount()
        local flying = config.GetFlyingMount()
        local multi = config.GetMultiMount()
        return ground, flying, multi
    end
    return nil, nil, nil
end

-- ============================================================================
-- MOUNT CACHE AND RANDOM SELECTION
-- ============================================================================

-- Get all usable mounts
local function GetUsableMounts()
    local now = GetTime()
    if Module._cachedMounts and (now - Module._cacheTime) < CACHE_DURATION then
        return Module._cachedMounts
    end
    
    local groundMounts = {}
    local flyingMounts = {}
    
    if HasMountJournalAPI() and C_MountJournal.GetMountIDs then
        local ids = C_MountJournal.GetMountIDs()
        if type(ids) == "table" then
            for _, id in ipairs(ids) do
                local name, spellID, icon, _, isUsable, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(id)
                if isCollected and isUsable and name then
                    -- Check mount type
                    local mountType = nil
                    if C_MountJournal.GetMountInfoExtraByID then
                        local _, _, _, _, mountTypeID = C_MountJournal.GetMountInfoExtraByID(id)
                        mountType = mountTypeID
                    end
                    
                    local mountData = { id = id, name = name, spellID = spellID, icon = icon }
                    
                    -- Ground mounts (type 230 = ground, 248 = both, 424 = dragonriding)
                    -- Flying mounts (type 248 = both, 424 = dragonriding, 247 = flying)
                    if mountType == 230 then
                        table.insert(groundMounts, mountData)
                    elseif mountType == 247 or mountType == 248 or mountType == 424 then
                        table.insert(flyingMounts, mountData)
                        if mountType == 248 then
                            table.insert(groundMounts, mountData)
                        end
                    else
                        -- Default: add to both
                        table.insert(groundMounts, mountData)
                        table.insert(flyingMounts, mountData)
                    end
                end
            end
        end
    elseif HasCompanionAPI() then
        local numMounts = GetNumCompanions("MOUNT") or 0
        for i = 1, numMounts do
            local creatureID, creatureName, creatureSpellID, icon = GetCompanionInfo("MOUNT", i)
            if creatureName then
                local mountData = { id = creatureID, name = creatureName, spellID = creatureSpellID, icon = icon }
                table.insert(groundMounts, mountData)
                table.insert(flyingMounts, mountData)
            end
        end
    end
    
    Module._cachedMounts = { ground = groundMounts, flying = flyingMounts }
    Module._cacheTime = now
    
    return Module._cachedMounts
end

-- Get a random mount from list, or first if no random function
local function GetRandomMount(mountList)
    if not mountList or #mountList == 0 then return nil end
    
    if #mountList == 1 then
        return mountList[1]
    end
    
    local idx = math.random(1, #mountList)
    return mountList[idx]
end

-- Get ground mount (random or first usable)
function Module.GetGroundMount()
    local mounts = GetUsableMounts()
    if mounts and mounts.ground and #mounts.ground > 0 then
        return GetRandomMount(mounts.ground)
    end
    return nil
end

-- Get flying mount (random or first usable)
function Module.GetFlyingMount()
    local mounts = GetUsableMounts()
    if mounts and mounts.flying and #mounts.flying > 0 then
        return GetRandomMount(mounts.flying)
    end
    return nil
end

-- ============================================================================
-- MODE MANAGEMENT
-- ============================================================================

-- Get current mode from saved variables (uses FluxSmartMountConfig if available)
function Module.GetMode()
    -- Try FluxSmartMountConfig first
    if _G.FluxSmartMountConfig and _G.FluxSmartMountConfig.GetMountMode then
        return _G.FluxSmartMountConfig.GetMountMode()
    end
    
    -- Fallback to direct DB access
    if FluxNonCombatGridDB then
        local charKey
        if _G.Flux and _G.Flux.PlayerName and _G.Flux.PlayerName.GetCharKey then
            charKey = _G.Flux.PlayerName.GetCharKey("hyphen")
        else
            local playerName = UnitName("player")
            local realmName = GetRealmName()
            if playerName and realmName then
                charKey = playerName .. "-" .. realmName
            end
        end
        if charKey then
            if FluxNonCombatGridDB[charKey] and FluxNonCombatGridDB[charKey].mount then
                return FluxNonCombatGridDB[charKey].mount.mode or Module.MODE_SMART
            end
        end
    end
    return Module._mode
end

-- Set current mode in saved variables (uses FluxSmartMountConfig if available)
function Module.SetMode(mode)
    if mode ~= Module.MODE_SMART and mode ~= Module.MODE_VENDOR then
        return
    end
    
    Module._mode = mode
    
    -- Try FluxSmartMountConfig first
    if _G.FluxSmartMountConfig and _G.FluxSmartMountConfig.SetMountMode then
        _G.FluxSmartMountConfig.SetMountMode(mode)
        return
    end
    
    -- Fallback to direct DB access
    if FluxNonCombatGridDB then
        local charKey
        if _G.Flux and _G.Flux.PlayerName and _G.Flux.PlayerName.GetCharKey then
            charKey = _G.Flux.PlayerName.GetCharKey("hyphen")
        else
            local playerName = UnitName("player")
            local realmName = GetRealmName()
            if playerName and realmName then
                charKey = playerName .. "-" .. realmName
            end
        end
        if charKey then
            if not FluxNonCombatGridDB[charKey] then
                FluxNonCombatGridDB[charKey] = {}
            end
            if not FluxNonCombatGridDB[charKey].mount then
                FluxNonCombatGridDB[charKey].mount = {
                    mode = Module.MODE_SMART,
                }
            end
            FluxNonCombatGridDB[charKey].mount.mode = mode
        end
    end
end

-- Toggle mode (only if vendor mount available)
function Module.ToggleMode()
    if InCombatLockdown() then return end
    
    local current = Module.GetMode()
    local newMode
    
    if current == Module.MODE_SMART then
        -- Only allow switch to VendorMount if we have one
        if Module.HasAnyVendorMount() then
            newMode = Module.MODE_VENDOR
        else
            return
        end
    else
        newMode = Module.MODE_SMART
    end
    
    Module.SetMode(newMode)
    Module.Update()
end

-- ============================================================================
-- MOUNT UI HELPERS (must be before macro building functions)
-- ============================================================================

-- Clear checked highlight from Mount button (right-click opens collection, not a cast)
local function ClearMountButtonCheckedState()
    local btn = Module._button
    if not btn or not btn.Widget then return end
    if btn.Widget.SetChecked then btn.Widget:SetChecked(false) end
    local tex = btn.Widget.GetCheckedTexture and btn.Widget:GetCheckedTexture()
    if tex then tex:Hide() end
    local namedChecked = btn.Widget.GetName and _G[btn.Widget:GetName() .. "Checked"]
    if namedChecked then namedChecked:Hide() end
end
Module.ClearMountButtonCheckedState = ClearMountButtonCheckedState

-- Helper function to open mount UI with fallbacks for different client types
local function OpenMountUI()
    -- Method 1: Modern client with Mount Journal (Retail 5.0+)
    -- Use FluxOpenMountCollection which LoadAddOns Blizzard_Collections first
    if HasMountJournalAPI() then
        if FluxOpenMountCollection and FluxOpenMountCollection() then
            ClearMountButtonCheckedState()
            return true
        end
        -- Fallback: LoadAddOn then ToggleCollectionsJournal (if helpers not available)
        if LoadAddOn then LoadAddOn("Blizzard_Collections") end
        if ToggleCollectionsJournal and type(ToggleCollectionsJournal) == "function" then
            pcall(ToggleCollectionsJournal, 1)  -- Tab 1 = Mounts
            ClearMountButtonCheckedState()
            return true
        end
    end
    
    -- Method 2: Companion system (WotLK/Cata) - mounts are companions
    if HasCompanionAPI() and not HasMountJournalAPI() then
        if FluxOpenCompanionMounts and FluxOpenCompanionMounts() then
            ClearMountButtonCheckedState()
            return true
        end
        -- Fallback: LoadAddOn then TogglePetJournal
        if LoadAddOn then LoadAddOn("Blizzard_PetJournal") end
        if TogglePetJournal and type(TogglePetJournal) == "function" then
            pcall(TogglePetJournal)
            ClearMountButtonCheckedState()
            return true
        end
        return false
    end
    
    -- Method 3: Legacy fallback - Character frame (very old clients)
    if not HasMountUI() and CharacterFrame and ToggleCharacter then
        ToggleCharacter("PaperDollFrame")
        ClearMountButtonCheckedState()
        return true
    end
    
    return false
end

-- Generate macro text for opening mount UI (with fallbacks) — /click proxy, no /run (retail script dialog)
local function GetOpenMountUIMacro()
    local P = FluxMacroClickProxies
    if P and P.MACRO_MOUNT_OPEN_UI_BLOCK then
        return P.MACRO_MOUNT_OPEN_UI_BLOCK
    end
    return [[#showtooltip
/click FluxMacroProxy_MountOpenUI]]
end

-- ============================================================================
-- MOUNT LOCK SYSTEM (Sticky Mount Feature)
-- ============================================================================

-- Lock the button to a specific mount
function Module.LockToMount(mountName, mountIcon, spellID)
    if not mountName then return end
    
    Module._lockedMount = {
        name = mountName,
        icon = mountIcon,
        spellID = spellID,
    }
    Module._isLocked = true
    Module._pendingLockMount = nil
    SetCastLockSpellId(spellID)
    
    -- Disable icon protection while locked (lock system manages icon)
    _iconManagedByModule = false
    
    -- Update button immediately
    if not InCombatLockdown() then
        Module.UpdateLockedState()
    end
end

-- Unlock the button and restore smart mount behavior
function Module.Unlock()
    if not Module._isLocked then return end
    
    Module._lockedMount = nil
    Module._isLocked = false
    Module._isCasting = false
    Module._pendingLockMount = nil
    ClearCastLockSpellId()
    
    -- Clear cached texture (prevent old icon from being restored)
    Module._currentTexture = nil
    _lastSetIcon = nil

    -- Force macro re-apply: UpdateLockedState sets a locked macro via SetAction without
    -- updating _lastJournalMacro, so Update() would skip restore if cache still matches.
    Module._lastJournalMacro = nil
    Module._lastBagMountMacro = nil
    
    -- Update button immediately (only if out of combat)
    if not InCombatLockdown() then
        Module.Update()
        
        -- Reset modifier icon tracker so icon refreshes even if held mods unchanged
        lastBagMountIconModState = ""
        if not HasMountUI() then
            -- Re-enable icon protection and set icon for currently held mod
            _iconManagedByModule = true
            Module.UpdateBagMountIcon(GetCurrentHeldModKey())
        else
            Module.UpdateJournalMountIcon(GetCurrentHeldModKey())
        end
    end
end

-- Check if button is currently locked
function Module.IsLocked()
    return Module._isLocked and Module._lockedMount ~= nil
end

-- Get the locked mount info
function Module.GetLockedMount()
    return Module._lockedMount
end

-- Update button to reflect locked state
function Module.UpdateLockedState()
    local btn = Module._button
    if not btn or not Module._isLocked or not Module._lockedMount then return end
    if InCombatLockdown() then return end
    
    local mountName = Module._lockedMount.name
    local mountIcon = Module._lockedMount.icon
    
    -- Update macro to use/cast locked mount directly
    -- Use /use for item-based mounts (no mount UI), /cast for spell-based mounts
    local useCommand = HasMountUI() and "/cast" or "/use"
    local lockedMacro = string.format([[#showtooltip %s
%s %s]], mountName, useCommand, mountName)
    
    if btn.SetAction then
        btn:SetAction("macrotext", lockedMacro)
    elseif btn.Widget then
        btn.Widget:SetAttribute("type", "macro")
        btn.Widget:SetAttribute("macrotext", lockedMacro)
    end
    -- Keep cache in sync so Unlock → Update can detect the restore as a change
    if HasMountUI() then
        Module._lastJournalMacro = lockedMacro
    else
        Module._lastBagMountMacro = lockedMacro
    end
    
    -- Update texture (protected path so icon hook cannot drop it)
    if mountIcon then
        if btn.WIcon and SetProtectedIcon then
            SetProtectedIcon(btn, mountIcon, true)
        else
            Module._currentTexture = mountIcon
            if btn.WIcon then
                btn.WIcon:SetTexture(mountIcon)
                btn.WIcon:SetDesaturated(false)
                btn.WIcon:Show()
            end
            if btn.Widget and btn.Widget.icon then
                btn.Widget.icon:SetTexture(mountIcon)
                btn.Widget.icon:Show()
            end
        end
    end
    
    -- Update usability when icon (and thus active mount) changes
    if btn.UpdateUsable then
        btn:UpdateUsable()
    end

    -- Restore right-click (SetAction cleared it)
    if HasMountUI() then
        Module.SetupRightClick(btn)
    else
        local hasFlyout = false
        if Module.HasMountItemFlyout then
            hasFlyout = Module.HasMountItemFlyout()
        else
            local items = Module.GetBagMountItems()
            hasFlyout = items and #items > 1
        end
        if hasFlyout and btn.Widget and not InCombatLockdown() then
            btn.Widget:SetAttribute("type2", "macro")
            btn.Widget:SetAttribute("macrotext2", (FluxMacroClickProxies and FluxMacroClickProxies.MACRO_MOUNT_ITEM_FLYOUT) or "/click FluxMacroProxy_MountItemFlyout")
            if FluxGridFlyout and FluxGridFlyout.BindRightClickFlyout then
                FluxGridFlyout.BindRightClickFlyout(btn.Widget, Module.ShowMountItemFlyout, { hookKey = "_fluxMountItemRCFlyout" })
            end
        else
            if btn.Widget and not InCombatLockdown() then
                btn.Widget:SetAttribute("type2", nil)
                btn.Widget:SetAttribute("macrotext2", nil)
            end
        end
    end
end

-- Determine which mount will be cast based on current modifier state
function Module.GetMountForCurrentModifiers(forcedModKey)
    -- For legacy clients without mount UI, use the bag mount system
    if not HasMountUI() then
        -- Get current modifier key (or use forced value)
        local modKey = forcedModKey or "nomod"
        if not forcedModKey then
            if IsShiftKeyDown and IsShiftKeyDown() then
                modKey = "shift"
            elseif IsControlKeyDown and IsControlKeyDown() then
                modKey = "ctrl"
            elseif IsAltKeyDown and IsAltKeyDown() then
                modKey = "alt"
            end
        end
        
        -- Get best available mount using priority fallback
        local mount = Module.GetBestAvailableMount(modKey)
        if mount then
            -- For item-based mounts, return name, icon, and nil for spellID
            return mount.name, mount.icon or GetItemIcon(mount.itemId), nil
        end
        return nil, nil, nil
    end
    
    local mode = Module.GetMode()
    local ground, flying, multi = Module.GetMountConfig()
    
    -- Honor forcedModKey so modifier-tracker icon updates match the secure macro
    local isShift, isCtrl, isAlt = ResolveJournalModFlags(forcedModKey)
    local anyMod = isShift or isCtrl or isAlt
    
    if mode == Module.MODE_VENDOR then
        -- Vendor mount mode: Yak on nomod, Brutosaur on any mod
        local hasBruto = Module.HasBrutosaur()
        local hasYak = Module.HasYak()
        
        if hasBruto and hasYak then
            -- Both available: use modifier logic
            if anyMod then
                local bruto = Module.GetBrutosaur()
                if bruto then
                    return bruto.name, bruto.icon, bruto.spellID
                end
            else
                local yak = Module.GetYak()
                if yak then
                    return yak.name, yak.icon, yak.spellID
                end
            end
        elseif hasBruto then
            local bruto = Module.GetBrutosaur()
            if bruto then
                return bruto.name, bruto.icon, bruto.spellID
            end
        elseif hasYak then
            local yak = Module.GetYak()
            if yak then
                return yak.name, yak.icon, yak.spellID
            end
        end
        return nil, nil, nil
    end
    
    -- Smart mount mode - same priority as BuildSmartMountMacro:
    -- [mod:shift] ground, [mod:ctrl] multi, [mod:alt] flight style/fly, [nomod] smart
    
    local mountName, mountIcon, mountSpellID
    
    if isShift then
        -- Ground mount
        mountName = ground
    elseif isCtrl then
        -- Multi-seat mount
        mountName = multi
        if not mountName then
            local vendorMount = Module.GetBestVendorMount()
            if vendorMount then
                mountName = vendorMount.name
            end
        end
    elseif isAlt then
        -- Flying mount or Switch Flight Style
        if HasSwitchFlightStyle() then
            return SWITCH_FLIGHT_STYLE_NAME, GetSwitchFlightStyleIcon(), SWITCH_FLIGHT_STYLE_SPELL_ID
        end
        mountName = flying or ground
    else
        -- No modifier - smart selection
        local isFlyable = IsFlyableAreaFixed()
        mountName = (isFlyable and flying) or ground or flying
    end
    
    if not mountName then
        return nil, nil, nil
    end
    
    -- Get mount icon - try spell texture first
    if C_Spell and C_Spell.GetSpellTexture then
        mountIcon = C_Spell.GetSpellTexture(mountName)
    elseif GetSpellTexture then
        mountIcon = GetSpellTexture(mountName)
    end
    
    -- Try to get spellID and icon from mount journal (name map — O(1))
    local mountData = GetCollectedMountByName(mountName)
    if mountData then
        mountSpellID = mountData.spellID
        if not mountIcon then
            mountIcon = mountData.icon
        end
    end
    
    return mountName, mountIcon, mountSpellID
end

-- Cast smart mount (flying if flyable/Outland/Northrend, else ground). Called from macro /run.
function Module.CastSmartMount()
    local config = _G.FluxSmartMountConfig
    if not config or not config.GetGroundMount or not config.GetFlyingMount then return end
    local ground = config.GetGroundMount()
    local flying = config.GetFlyingMount()
    if not ground and not flying then return end
    local fly = IsFlyableAreaFixed()
    local toCast = (fly and flying) or ground or flying
    if toCast then
        if C_Spell and C_Spell.CastSpellByName then
            C_Spell.CastSpellByName(toCast)
        elseif CastSpellByName then
            CastSpellByName(toCast)
        end
    end
end

-- ============================================================================
-- MACRO BUILDING
-- ============================================================================

-- Build smart mount macro (uses configured mounts from FluxSmartMountConfig)
function Module.BuildSmartMountMacro()
    local ground, flying, multi = Module.GetMountConfig()
    
    -- If no mounts configured, fall back to random selection
    if not ground and not flying then
        -- Try to get any usable mount as fallback
        if HasMountJournalAPI() and C_MountJournal.GetMountIDs then
            local ids = C_MountJournal.GetMountIDs()
            if type(ids) == "table" and #ids > 0 then
                for _, id in ipairs(ids) do
                    local name, spellID, _, _, isUsable, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(id)
                    if isCollected and isUsable and name then
                        ground = ground or name
                        flying = flying or name
                        break
                    end
                end
            end
        end
    end
    
    -- If still no mounts, return placeholder macro (with fallbacks)
    if not ground and not flying then
        return GetOpenMountUIMacro()
    end
    
    local groundName = ground or flying
    local flyingName = flying or ground
    local multiName = multi or groundName
    
    -- Check for vendor mount as multi-seat option if not configured
    if not multi then
        local vendorMount = Module.GetBestVendorMount()
        if vendorMount then
            multiName = vendorMount.name
        else
            multiName = groundName
        end
    end
    
    -- Classic Era (Vanilla) - no flying
    if IsClassicEra() then
        return string.format([[#showtooltip
/cast [mod:ctrl] %s; [mod:shift] %s; %s]], 
            multiName, groundName, groundName)
    end
    
    -- Modern client with Switch Flight Style
    local altAction
    if HasSwitchFlightStyle() then
        altAction = SWITCH_FLIGHT_STYLE_NAME
    else
        altAction = flyingName
    end
    
    -- Modifiers (icon preview mirrors these via GetMountForCurrentModifiers):
    -- Shift = Ground mount (always)
    -- Ctrl = Multi-seat mount
    -- Alt = Flying mount or Switch Flight Style
    -- No mod = Smart (flying if flyable, ground otherwise) via [nomod,flyable] - keeps macro under 255 chars
    return string.format([[#showtooltip
/cast [mod:shift] %s
/cast [mod:ctrl] %s
/cast [mod:alt] %s
/cast [nomod,flyable] %s; [nomod] %s]],
        groundName, multiName, altAction, flyingName, groundName)
end

-- Check if player has specific vendor mounts
function Module.HasBrutosaur()
    return HasCollectedMountByName(BRUTOSAUR_NAME)
end

function Module.HasYak()
    return HasCollectedMountByName(YAK_NAME)
end

-- Get mount data for specific vendor mounts
function Module.GetBrutosaur()
    return GetCollectedMountByName(BRUTOSAUR_NAME)
end

function Module.GetYak()
    return GetCollectedMountByName(YAK_NAME)
end

-- Build vendor mount macro
-- Yak on no modifier, Brutosaur on any modifier
function Module.BuildVendorMountMacro()
    local hasBruto = Module.HasBrutosaur()
    local hasYak = Module.HasYak()
    
    -- If no vendor mount available, open Collections (with fallbacks)
    if not hasBruto and not hasYak then
        return GetOpenMountUIMacro()
    end
    
    -- Both mounts: yak on nomod, brutosaur on mod
    if hasBruto and hasYak then
        return string.format([[#showtooltip [mod] %s; %s
/cast [mod] %s
/cast [nomod] %s]], BRUTOSAUR_NAME, YAK_NAME, BRUTOSAUR_NAME, YAK_NAME)
    -- Only brutosaur
    elseif hasBruto then
        return string.format([[#showtooltip %s
/cast %s]], BRUTOSAUR_NAME, BRUTOSAUR_NAME)
    -- Only yak
    else
        return string.format([[#showtooltip %s
/cast %s]], YAK_NAME, YAK_NAME)
    end
end

-- Get macro for current mode
function Module.GetCurrentMacro()
    -- If locked to a specific mount, return simple use/cast macro
    if Module._isLocked and Module._lockedMount and Module._lockedMount.name then
        local mountName = Module._lockedMount.name
        -- Use /use for item-based mounts (no mount UI), /cast for spell-based mounts
        local useCommand = HasMountUI() and "/cast" or "/use"
        return string.format([[#showtooltip %s
%s %s]], mountName, useCommand, mountName)
    end
    
    -- For legacy clients without mount UI, use bag mount macro
    if not HasMountUI() then
        return Module.BuildBagMountMacro()
    end
    
    local mode = Module.GetMode()
    if mode == Module.MODE_VENDOR then
        return Module.BuildVendorMountMacro()
    else
        return Module.BuildSmartMountMacro()
    end
end

-- ============================================================================
-- PLACEHOLDER SUPPORT
-- ============================================================================

local PLACEHOLDER_ICON = "Interface\\Icons\\ability_mount_charger"
local PLACEHOLDER_LABEL = "Mount"

-- Retail-style clients with toy box + mount journal: ring follows FluxSmartMountConfig character vs account (raw class vs no tint), not General → Appearance.
-- Must be defined before CreateButton/ClearPlaceholder (Lua local scope begins after declaration).
local function HasToyAndMountCollections()
    return FLUX_API and FLUX_API.hasToyBox and FLUX_API.hasC_MountJournal
end

local function ApplyMountButtonVisualStyle(btn)
    if not btn then return end
    if HasToyAndMountCollections() and HasMountUI() and FluxButtonUtil and FluxButtonUtil.ApplyNonCombatSmartCollectionButtonStyle then
        local useChar = _G.FluxSmartMountConfig and _G.FluxSmartMountConfig.IsUsingCharacterSpecific and _G.FluxSmartMountConfig.IsUsingCharacterSpecific() or false
        FluxButtonUtil:ApplyNonCombatSmartCollectionButtonStyle(btn, useChar)
    elseif FluxNonCombatGrid and FluxNonCombatGrid.ApplyButtonStyle then
        FluxNonCombatGrid.ApplyButtonStyle(btn, "class")
    elseif FluxButtonUtil and FluxButtonUtil.ApplyButtonStyle then
        FluxButtonUtil:ApplyButtonStyle(btn, "class")
    end
end

local function ShouldHoldItemIdentity()
    local B = _G.FluxEBSConsumableBridge
    if B and B.ShouldHoldItemIdentity then
        return B.ShouldHoldItemIdentity() and true or false
    end
    local Best = _G.FluxConsumableBest
    if Best and Best.ShouldSoftHoldOwned then
        return Best.ShouldSoftHoldOwned() and true or false
    end
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.SnapshotLooksCollapsed and api.SnapshotLooksCollapsed() then
        return true
    end
    if api and api.IsReliable and not api.IsReliable() then
        return true
    end
    return false
end

local function ShouldHoldMountIdentity()
    if IsBagMountLocationSettling and IsBagMountLocationSettling() then
        return true
    end
    return ShouldHoldItemIdentity()
end

-- True when the button can show a real mount action (not optimistic login cache).
function Module.CanDisplayMountButton()
    if Module._isLocked and Module._lockedMount and Module._lockedMount.name then
        return true
    end
    if not HasMountUI() then
        -- Unfiltered: dungeon/instance still has mount items even if zone-unusable.
        if Module.HasAnyMountInBags and Module.HasAnyMountInBags() then
            return true
        end
        local items = Module.GetBagMountItems and Module.GetBagMountItems()
        if type(items) == "table" and #items > 0 then
            return true
        end
        -- Sticky last-good while bags flicker empty on a load screen.
        if Module._lastGoodBagMountMacro and ShouldHoldMountIdentity() then
            return true
        end
        return false
    end
    local mountName = Module.GetMountForCurrentModifiers and Module.GetMountForCurrentModifiers()
    if mountName then
        Module._lastGoodJournalMountName = mountName
        return true
    end
    if Module._lastGoodJournalMountName and ShouldHoldMountIdentity() then
        return true
    end
    return false
end

-- Set button to placeholder state (no mount and no riding skill)
-- Uses the same pattern as food/water buttons
local function SetPlaceholder(btn)
    if not btn then return end
    
    Module._isPlaceholder = true
    btn.IsMountPlaceholder = true
    

    -- Try to use SetPlaceholder method if it exists (FluxButton pattern)
    if btn.SetPlaceholder then
        btn:SetPlaceholder(PLACEHOLDER_ICON, PLACEHOLDER_LABEL)
    else
        -- Set properties directly (fallback)
        btn.PlaceholderTexture = PLACEHOLDER_ICON
        btn.PlaceholderLabel = PLACEHOLDER_LABEL

        -- Clear action to trigger placeholder display in FluxButton
        if btn.ClearAction then
            btn:ClearAction()
        end
        if btn.UpdateTexture then
            btn:UpdateTexture()
        end
    end

    -- Force placeholder icon. Leave icon-protection off so Extra Paint can
    -- keep the gray charger (SetTexture is hooked while a real mount is shown).
    _iconManagedByModule = false
    _lastSetIcon = PLACEHOLDER_ICON
    if btn.WIcon then
        btn.WIcon:SetTexture(PLACEHOLDER_ICON)
        btn.WIcon:SetDesaturated(true)
        btn.WIcon:SetVertexColor(0.25, 0.25, 0.25, 1)
        btn.WIcon:Show()
        Module._currentTexture = PLACEHOLDER_ICON
        btn.Texture = PLACEHOLDER_ICON
    end
    
    -- Clear any action - placeholder button should do nothing
    -- Note: We clear this on Widget directly, so FluxButton sees no action
    if btn.Widget then
        btn.Widget:SetAttribute("type", nil)
        btn.Widget:SetAttribute("macrotext", nil)
        -- Also clear right-click and middle-click actions
        btn.Widget:SetAttribute("type2", nil)
        btn.Widget:SetAttribute("macrotext2", nil)
        btn.Widget:SetAttribute("type3", nil)
        btn.Widget:SetAttribute("macrotext3", nil)
    end


    -- Force update appearance to show placeholder
    if btn.UpdateAppearance then
        btn:UpdateAppearance()
    elseif btn.FullRefresh then
        btn:FullRefresh()
    end

    -- Update usability to reflect placeholder state
    if btn.UpdateUsable then
        btn:UpdateUsable()
    end

    if Module.UpdateButtonScope then
        Module.UpdateButtonScope()
    end
end

-- Clear placeholder state
local function ClearPlaceholder(btn)
    if not btn then return end

    Module._isPlaceholder = false
    btn.IsMountPlaceholder = false

    -- Try to use ClearPlaceholder method if it exists
    if btn.ClearPlaceholder then
        btn:ClearPlaceholder()
    else
        -- Clear properties directly (fallback)
        btn.PlaceholderTexture = nil
        btn.PlaceholderLabel = nil
    end

    -- Ensure normal button styling is maintained
    if btn.UseClassColor ~= nil then btn.UseClassColor = true end
    if Module.UpdateButtonScope then
        Module.UpdateButtonScope()
    else
        ApplyMountButtonVisualStyle(btn)
    end

    -- Update usability to reflect normal state
    if btn.UpdateUsable then
        btn:UpdateUsable()
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
    
    -- Always create the button (placeholder if no mount)
    Module.CreateButton()
    
    -- Register for mount config updates
    local function TryRegisterListener()
        if _G.FluxSmartMountConfig and _G.FluxSmartMountConfig.RegisterListener then
            _G.FluxSmartMountConfig.RegisterListener(function()
                Module.Update()
            end)

            -- Update immediately with current saved config
            Timer.After(0.2, function()
                Module.Update()
            end)
            return true
        end
        return false
    end
    
    -- Try immediately
    if not TryRegisterListener() then
        -- Retry after a short delay (config might not be ready yet)
        Timer.After(0.5, function()
            if not TryRegisterListener() then
                Timer.After(1, TryRegisterListener)
            end
        end)
    end

    if FluxEBS_PostLoginBagRefresh and FluxEBS_PostLoginBagRefresh.RegisterFirstBagDelayedCallback then
        FluxEBS_PostLoginBagRefresh.RegisterFirstBagDelayedCallback("NCMount", function()
            if not Module._registered then return end
            if InCombatLockdown() then
                Module._pendingUpdate = true
                return
            end
            InvalidateAllMountItemCaches()
            Module._bagMountNeedsFullRefresh = true
            Module.Update()
        end)
    end

    if FluxEBS_PostLoginBagRefresh and FluxEBS_PostLoginBagRefresh.RegisterPulseEndCallback
        and not Module._pulseEndRegistered then
        Module._pulseEndRegistered = true
        FluxEBS_PostLoginBagRefresh.RegisterPulseEndCallback("NCMount", function()
            if not Module._registered then return end
            if InCombatLockdown() then
                Module._pendingUpdate = true
                return
            end
            -- Pulse end: light refresh only if login coalesced path already ran Setup
            if not HasMountUI() then
                Module.UpdateBagMountIcon(GetCurrentHeldModKey())
            else
                Module.Update()
            end
        end)
    end
end

local function PinMountExtraFace(btn, heldMod)
    if not btn then
        return
    end
    heldMod = heldMod or "nomod"
    local mountName, _, mountSpellID = Module.GetMountForCurrentModifiers(heldMod)
    if HasMountUI() and mountSpellID then
        btn._fluxManagedFaceSpellId = mountSpellID
        btn.SpellId = mountSpellID
        btn.MacroMode = "spell"
        btn.MountSpellId = mountSpellID
        btn._fluxManagedFaceItemId = nil
        btn.ItemId = nil
        if C_MountJournal and C_MountJournal.GetMountFromSpell then
            btn.MountId = C_MountJournal.GetMountFromSpell(mountSpellID)
        end
        return
    end
    local itemId = Module._lastResolvedBagMount and Module._lastResolvedBagMount.itemId
    if not itemId and mountName and Module.GetMountItemId then
        itemId = Module.GetMountItemId(mountName)
    end
    if not itemId and Module.GetBestAvailableMount then
        local mount = Module.GetBestAvailableMount(heldMod)
        itemId = mount and mount.itemId
        Module._lastResolvedBagMount = mount
    end
    btn.MountSpellId = nil
    btn.MountId = nil
    btn._fluxManagedFaceSpellId = nil
    btn.SpellId = nil
    if itemId then
        btn._fluxManagedFaceItemId = itemId
        btn.ItemId = itemId
        btn.MacroMode = "item"
    end
end

local function PaintMountLiveFace(btn)
    local Paint = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint
    if Paint and Paint.UpdateLiveFace then
        Paint.UpdateLiveFace(btn)
    elseif Paint and Paint.UpdateUsable then
        Paint.UpdateUsable(btn)
    end
end

-- Create the mount button
function Module.CreateButton()
    if not Module._grid or Module._button then return end
    if InCombatLockdown() then
        Timer.After(0.5, Module.CreateButton)
        return
    end
    
    local grid = Module._grid
    
    -- Get initial scope based on config mode
    local initialScope = Module.GetCurrentScope()
    
    -- Create button using grid's method
    local btn = grid:CreateButton({
        columnPriority = Module.COLUMN_PRIORITY,
        columnGroup = "mount",
        order = Module.ORDER,
        scope = initialScope,
    })
    
    if not btn then return end
    
    Module._button = btn
    
    -- Mark as mount button
    btn.IsMountButton = true
    btn.IsUnifiedMountButton = true
    btn.FluxGridFlyoutOwner = true
    -- Mount macros read as "current spell/item" while mounted; suppress sticky checked highlight
    -- (same pattern as combat Ammo display button). Works for bag-item and journal mounts.
    btn.IgnoreCheckedVisual = true
    if btn.Widget then
        btn.Widget.FluxGridFlyoutOwner = true
    end
    ClearMountButtonCheckedState()
    
    -- DISABLE DEFAULT TOOLTIP - We'll use custom tooltip
    btn.TooltipEnabled = false
    
    -- Extra Paint owns usable/CD/range/glow. Pin the modifier-facing mount
    -- so macrotext still morphs like Extra slots.
    btn.UpdateUsable = function(self)
        if Module._isPlaceholder then
            if self.WIcon then
                local tex = self.PlaceholderTexture or PLACEHOLDER_ICON
                local wasProtected = _iconManagedByModule
                _iconManagedByModule = false
                self.WIcon:SetTexture(tex)
                _iconManagedByModule = wasProtected
                self.WIcon:SetDesaturated(true)
                self.WIcon:SetVertexColor(0.25, 0.25, 0.25, 1)
                self.WIcon:Show()
            end
            return
        end

        local heldMod = "nomod"
        if IsControlKeyDown and IsControlKeyDown() then
            if IsShiftKeyDown and IsShiftKeyDown() then
                if IsAltKeyDown and IsAltKeyDown() then heldMod = "ctrl+shift+alt" else heldMod = "ctrl+shift" end
            elseif IsAltKeyDown and IsAltKeyDown() then heldMod = "ctrl+alt" else heldMod = "ctrl" end
        elseif IsShiftKeyDown and IsShiftKeyDown() then
            if IsAltKeyDown and IsAltKeyDown() then heldMod = "shift+alt" else heldMod = "shift" end
        elseif IsAltKeyDown and IsAltKeyDown() then heldMod = "alt" end

        PinMountExtraFace(self, heldMod)
        PaintMountLiveFace(self)
    end
    
    -- DISABLE DRAG/DROP - Pre-set button
    if btn.SetLocked then
        btn:SetLocked(true)
    end
    if btn.Widget then
        btn.Widget:SetScript("OnDragStart", nil)
        btn.Widget:SetScript("OnReceiveDrag", nil)
        btn.Widget:SetScript("OnDragStop", nil)
        if btn.Widget.RegisterForDrag then
            btn.Widget:RegisterForDrag()
        end
        if btn.Widget.EnableMouseDrag then
            btn.Widget:EnableMouseDrag(false)
        end
    end
    
    -- DISABLE DEFAULT TOOLTIP - We'll use custom tooltip
    btn.TooltipEnabled = false
    
    -- Show placeholder when no mount action is available yet (avoids optimistic login cache)
    if not Module.CanDisplayMountButton() then
        -- Show placeholder
        SetPlaceholder(btn)
        -- Force refresh to show placeholder
        if btn.FullRefresh then
            btn:FullRefresh()
        end
    else
        -- Set macro action using macrotext (correct 2-arg form)
        local macro = Module.GetCurrentMacro()
        if btn.SetAction then
            btn:SetAction("macrotext", macro)
            btn.MacroTextEnabled = false
        elseif btn.Widget then
            btn.Widget:SetAttribute("type", "macro")
            btn.Widget:SetAttribute("macrotext", macro)
        end
        
        -- Update texture
        Module.UpdateTexture()
    end
    
    -- Apply complete button styling (smart collection tint when applicable)
    ApplyMountButtonVisualStyle(btn)
    
    -- Set up right-click to open mounts
    Module.SetupRightClick(btn)
    
    -- Set up middle-click to toggle mode (only if vendor mount available)
    Module.SetupMiddleClick(btn)
    
    -- Set up PreClick to capture target mount for lock feature
    Module.SetupPreClick(btn)
    
    -- Set up bag mount flyout for Vanilla/TBC clients (no mount journal)
    if not HasMountUI() then
        Module.SetupBagMountButton()
    end
    
    -- Hook custom tooltip (replaces default tooltip)
    Module.SetupTooltip(btn)
    
    -- Set up icon protection for ALL clients (to support combat locking)
    if Module.SetupIconProtection then
        Module.SetupIconProtection(btn)
    end
    
    -- Set column priority and order
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
    
    -- Setup keybinding via SetOverrideBindingClick (secure approach, no taint)
    Module.UpdateMountKeybinding(btn)
    
    -- Update hotkey text display on button
    Module.UpdateHotkeyText(btn)
    
    return btn
end

-- Update hotkey text display on button
function Module.UpdateHotkeyText(btn)
    btn = btn or Module._button
    if FluxNCHotkeyUtil and FluxNCHotkeyUtil.UpdateHotkeyText then
        FluxNCHotkeyUtil.UpdateHotkeyText(btn, "FLUXGRIDSMARTMOUNT")
    end
end

-- Update mount keybinding to point to the button widget (secure approach)
function Module.UpdateMountKeybinding(btn)
    btn = btn or Module._button
    if not btn or not btn.Widget then return end
    if InCombatLockdown() then
        Module._pendingKeybindUpdate = true
        return
    end

    local widgetName = btn.Widget:GetName()

    -- Clear existing bindings first
    ClearOverrideBindings(btn.Widget)

    local mountKey = GetBindingKey("FLUXGRIDSMARTMOUNT")
    if widgetName and mountKey then
        -- Bind the mount keybinding to the button widget (LeftButton = mount action)
        SetOverrideBindingClick(btn.Widget, false, mountKey, widgetName, "LeftButton")
    end

    -- Bind the toggle mount mode keybinding (MiddleButton = toggle mode)
    local toggleKey = GetBindingKey("FLUXGRIDVENDORMOUNT")
    if widgetName and toggleKey then
        SetOverrideBindingClick(btn.Widget, false, toggleKey, widgetName, "MiddleButton")
    end
end

-- Clear mount keybinding
function Module.ClearMountKeybinding()
    if InCombatLockdown() then return end
    
    local btn = Module._button
    if btn and btn.Widget then
        ClearOverrideBindings(btn.Widget)
    end
end
-- Set up right-click to open Mounts tab (with fallbacks)
function Module.SetupRightClick(btn)
    if not btn or not btn.Widget then return end
    if InCombatLockdown() then
        Timer.After(0.2, function() Module.SetupRightClick(btn) end)
        return
    end
    
    -- Don't set up right-click for placeholder buttons - they should do nothing
    if Module._isPlaceholder or btn.IsMountPlaceholder then
        btn.Widget:SetAttribute("type2", nil)
        btn.Widget:SetAttribute("macrotext2", nil)
        return
    end
    
    -- Only set up right-click if mount UI is available (mount journal or companion system)
    if HasMountUI() then
        btn.Widget:SetAttribute("type2", "macro")
        btn.Widget:SetAttribute("macrotext2", GetOpenMountUIMacro())
    else
        -- Bag mount clients: do NOT touch type2 - SetupBagMountButton owns right-click (flyout).
        -- Clearing here would overwrite the flyout. Simply return.
        return
    end
end

-- Set up middle-click to toggle mode
function Module.SetupMiddleClick(btn)
    if not btn or not btn.Widget then return end
    if InCombatLockdown() then
        Timer.After(0.2, function() Module.SetupMiddleClick(btn) end)
        return
    end
    
    -- Don't set up middle-click for placeholder buttons - they should do nothing
    if Module._isPlaceholder or btn.IsMountPlaceholder then
        btn.Widget:SetAttribute("type3", nil)
        btn.Widget:SetAttribute("macrotext3", nil)
        return
    end
    
    -- Only set up middle-click if player has vendor mounts
    if Module.HasAnyVendorMount() then
        btn.Widget:SetAttribute("type3", "macro")
        btn.Widget:SetAttribute("macrotext3", (FluxMacroClickProxies and FluxMacroClickProxies.MACRO_MOUNT_TOGGLE_MODE) or "/click FluxMacroProxy_MountToggleMode")
    else
        btn.Widget:SetAttribute("type3", nil)
        btn.Widget:SetAttribute("macrotext3", nil)
    end
end

-- Set up PreClick hook to capture which mount will be cast
function Module.SetupPreClick(btn)
    if not btn or not btn.Widget then return end
    
    local widget = btn.Widget
    
    -- Hook PreClick to capture the target mount before click executes
    if widget.HookScript then
        widget:HookScript("PreClick", function(self, button, down)
            -- Only handle left-click mount casts
            if button ~= "LeftButton" then return end

            -- Click-to-dismount: CheckButton toggles checked on press; clear immediately
            -- and again next frames so the highlight does not stick (item + journal mounts).
            if IsMounted and IsMounted() then
                ClearMountButtonCheckedState()
                Timer.After(0, ClearMountButtonCheckedState)
                Timer.After(0.05, ClearMountButtonCheckedState)
                Timer.After(0.15, function()
                    ClearMountButtonCheckedState()
                    local b = Module._button
                    if b and b.UpdateChecked then
                        b:UpdateChecked()
                    end
                end)
            end
            
            -- Don't set pending lock if already locked (just cast the locked mount)
            if Module._isLocked then return end
            
            -- If it's a placeholder, don't try to lock
            if Module._isPlaceholder then return end
            
            -- Capture which mount/spell will be cast based on current modifiers
            local mountName, mountIcon, mountSpellID = Module.GetMountForCurrentModifiers()

            if mountName then
                Module._pendingLockMount = {
                    name = mountName,
                    icon = mountIcon,
                    spellID = mountSpellID,
                }
                SetCastLockSpellId(mountSpellID)
                -- Freeze icon to the cast target immediately (incl. Switch Flight Style)
                if HasMountUI() and mountIcon and Module._button and Module._button.WIcon then
                    SetProtectedIcon(Module._button, mountIcon, true)
                end
                local pendingName = mountName
                Timer.After(1.0, function()
                    if Module._pendingLockMount
                        and Module._pendingLockMount.name == pendingName
                        and not Module._isLocked
                        and not Module._isCasting then
                        Module._pendingLockMount = nil
                        ClearCastLockSpellId()
                        lastBagMountIconModState = ""
                        if not HasMountUI() then
                            Module.UpdateBagMountIcon(GetCurrentHeldModKey())
                        else
                            Module.UpdateJournalMountIcon(GetCurrentHeldModKey())
                        end
                    end
                end)
            else
                Module._pendingLockMount = nil
                ClearCastLockSpellId()
            end
        end)
    end
end

-- ============================================================================
-- TOOLTIP ENHANCEMENT
-- ============================================================================

-- Helper function to get mount icon texture
local function GetMountIconTexture(mountName)
    if not mountName then return nil end
    
    -- Try spell texture first
    if C_Spell and C_Spell.GetSpellTexture then
        local texture = C_Spell.GetSpellTexture(mountName)
        if texture then return texture end
    end
    
    if GetSpellTexture then
        local texture = GetSpellTexture(mountName)
        if texture then return texture end
    end
    
    -- Try mount journal lookup
    if C_MountJournal and C_MountJournal.GetMountIDs then
        local ids = C_MountJournal.GetMountIDs()
        if type(ids) == "table" then
            for _, id in ipairs(ids) do
                local name, _, icon = C_MountJournal.GetMountInfoByID(id)
                if name and name:lower() == mountName:lower() then
                    return icon
                end
            end
        end
    end
    
    return nil
end

-- Format mount text with icon
local function FormatMountWithIcon(mountName, iconSize)
    if not mountName or mountName == "" then
        return nil, nil
    end
    
    iconSize = iconSize or 16
    local texture = GetMountIconTexture(mountName)
    local iconString = ""
    
    if texture then
        iconString = string.format("|T%s:%d:%d:0:0|t ", texture, iconSize, iconSize)
    end
    
    return iconString .. mountName, texture
end

-- Get current flight style (Skyriding vs Normal)
local function GetCurrentFlightStyle()
    -- Check for Dragonflight+ flight style system
    if C_PlayerInfo and C_PlayerInfo.GetGlidingInfo then
        local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
        -- If we can glide, we're probably on Skyriding
        if canGlide then
            return "Skyriding"
        end
    end
    
    -- Check via CVar if available (TWW+)
    if C_CVar and C_CVar.GetCVar then
        local flightStyle = C_CVar.GetCVar("dynamicFlightActivated")
        if flightStyle == "1" then
            return "Skyriding"
        elseif flightStyle == "0" then
            return "Steady Flight"
        end
    end
    
    -- Fallback: check if we know Switch Flight Style spell
    if HasSwitchFlightStyle() then
        return "Dynamic"
    end
    
    return nil
end

-- Tooltip state tracking
local tooltipShowing = false
local lastModifierState = ""

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

-- Tooltip for item-based mounts (Vanilla/TBC - no mount journal)
local function ShowItemMountTooltip(widget)
    if not widget then return end
    
    GameTooltip:SetOwner(widget, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
    -- Get mount items from bags
    local items = Module.GetBagMountItems()
    local mountCount = #items
    local hasFlyout = (Module.HasMountItemFlyout and Module.HasMountItemFlyout()) or false
    
    if mountCount == 0 then
        -- No mounts - show placeholder tooltip
        GameTooltip:SetText("Mount", 1, 1, 1)
        GameTooltip:AddLine("No mount items in bags", 1, 0.5, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Obtain a mount item to use this button", 0.7, 0.7, 0.7)
        GameTooltip:Show()
        return
    end
    
    -- Get current held modifier for determining active mount
    local heldMod = GetCurrentHeldModKey()
    
    -- Get the mount that will be cast (using priority fallback)
    local activeMount = Module.GetBestAvailableMount(heldMod)
    local activeName = activeMount and activeMount.name
    local activeItemId = activeMount and activeMount.itemId
    
    if not hasFlyout then
        -- Single visible option - no flyout
        local itemId = activeItemId or (items[1] and items[1]["$itemId"])
        local itemName = activeName or (items[1] and items[1]["$name"]) or "Mount"
        
        -- Show active mount name in GREEN
        local iconTag = GetIconTag(itemId, itemName)
        GameTooltip:AddLine(iconTag .. itemName, 0.2, 1, 0.2)  -- GREEN
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: Summon mount", 0.5, 0.8, 1)
        GameTooltip:Show()
        return
    end
    
    -- Multiple mounts - show flyout tooltip with active mount in GREEN
    -- Show active mount name in GREEN at the top
    if activeName and activeItemId then
        local iconTag = GetIconTag(activeItemId, activeName)
        GameTooltip:AddLine(iconTag .. activeName, 0.2, 1, 0.2)  -- GREEN
    else
        GameTooltip:SetText("Mount", 1, 1, 1)
    end
    
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: Summon mount", 0.8, 0.8, 0.8)
    GameTooltip:AddLine(" ")
    
    -- Get all favorites for Mount category (only those in bags)
    local availableFavorites = Module.GetAvailableFavorites()
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
                icon = fav.icon,
            })
        end
    end
    
    -- Show right-click action (opens flyout)
    GameTooltip:AddLine("Right-click: Open flyout (set favorites)", 0.7, 0.7, 1)
    
    -- Show modifier bindings section
    if #favoriteLines > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Modifier Bindings:", 1, 0.82, 0)
        
        for _, fav in ipairs(favoriteLines) do
            local iconTag = GetIconTag(fav.itemId, fav.name)
            local r, g, b = GetItemQualityColorRGB(fav.itemId)
            
            -- Highlight active modifier in GREEN
            local isActive = (fav.key == heldMod) or 
                           (heldMod == "nomod" and fav.key == "nomod") or
                           (activeName and fav.name == activeName)
            
            if isActive then
                r, g, b = 0.2, 1, 0.2  -- GREEN for active
            end
            
            local text = string.format("[%s] %s%s", fav.modLabel, iconTag, fav.name)
            GameTooltip:AddLine(text, r, g, b)
        end
    else
        -- No favorites set yet
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("No favorites set", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Right-click flyout buttons to set favorites", 0.7, 0.7, 0.7)
    end
    
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(string.format("Mounts in bags: %d", mountCount), 0.6, 0.6, 0.6)
    
    GameTooltip:Show()
end

-- Build and show the tooltip
local function ShowMountTooltip(widget)
    if not widget then return end
    
    GameTooltip:SetOwner(widget, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
    local mode = Module.GetMode()
    local hasVendor = Module.HasAnyVendorMount()
    
    if Module._isPlaceholder then
        GameTooltip:SetText("Mount", 1, 1, 1)

        -- Check detailed state
        local hasRiding = Module.HasRidingSkill()
        local hasAnyCollectedMount = Module.HasAnyMount()
        local hasMountInBags = Module.HasAnyMountInBags()
        local hasMountUI = HasMountUI()

        -- Show specific status message based on state
        -- Check all combinations: riding only, mount only, both missing, or no mounts in bags
        if not hasRiding and not hasAnyCollectedMount then
            GameTooltip:AddLine("No mount or riding skill", 1, 0.5, 0)
        elseif hasAnyCollectedMount and not hasRiding then
            GameTooltip:AddLine("You have mounts but no riding skill", 1, 0.5, 0)
        elseif hasRiding and not hasAnyCollectedMount then
            GameTooltip:AddLine("You have a riding skill but no mount", 1, 0.5, 0)
        elseif hasAnyCollectedMount and hasMountInBags then
            -- Both exist but placeholder is still showing (shouldn't happen, but handle it)
            GameTooltip:AddLine("Mount button unavailable", 1, 0.5, 0)
        elseif hasAnyCollectedMount and not hasMountInBags then
            -- Has collected mounts but none in bags - show the specific message
            GameTooltip:AddLine("No mounts found in bags", 0.5, 0.5, 0.5)
        else
            -- Fallback case
            GameTooltip:AddLine("Mount button unavailable", 1, 0.5, 0)
        end
        
        GameTooltip:AddLine(" ")
        
        -- Show mount system type (check in order of availability)
        -- Use HasMountUI() check first to exclude Vanilla/TBC
        if not HasMountUI() then
            -- Vanilla/TBC - mounts are items
            GameTooltip:AddLine("Mount System: Items", 0.6, 0.8, 1)
        elseif HasMountJournalAPI() then
            -- Retail MoP+ - Mount Journal
            GameTooltip:AddLine("Mount System: Mount Journal", 0.6, 0.8, 1)
        elseif HasCompanionAPI() then
            -- WotLK/Cata - Companion system
            GameTooltip:AddLine("Mount System: Companions", 0.6, 0.8, 1)
        else
            -- Fallback - should not happen, but show Items as default
            GameTooltip:AddLine("Mount System: Items", 0.6, 0.8, 1)
        end
        
        GameTooltip:AddLine(" ")
        
        -- Show appropriate hint based on available UI
        if hasMountUI then
            GameTooltip:AddLine("Click to open Mount Collection", 0.5, 0.8, 1)
        else
            GameTooltip:AddLine("Obtain a mount item to use this button", 0.7, 0.7, 0.7)
        end
        
        GameTooltip:Show()
        return
    end
    
    -- Check if locked to a specific mount
    if Module._isLocked and Module._lockedMount then
        local lockedName = Module._lockedMount.name
        local lockedIcon = Module._lockedMount.icon
        
        -- Title with locked mount name (CYAN to indicate lock)
        local iconString = ""
        if lockedIcon then
            iconString = string.format("|T%s:20:20:0:0|t ", lockedIcon)
        end
        GameTooltip:AddLine(iconString .. (lockedName or "Mount"), 0.4, 0.8, 1)
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("LOCKED", 1, 0.6, 0)
        GameTooltip:AddLine("Button locked to this mount", 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" ")
        
        if IsMounted() then
            GameTooltip:AddLine("Dismount to unlock (out of combat)", 0.5, 0.8, 1)
        else
            GameTooltip:AddLine("Will unlock when out of combat", 0.5, 0.8, 1)
        end
        
        GameTooltip:AddLine(" ")
        -- Only show right-click hint if mount UI is available
        if HasMountUI() then
            GameTooltip:AddLine("Right-click: Open Mounts", 0.5, 0.8, 1)
        end
        
        GameTooltip:Show()
        return
    end
    
    -- For clients without mount journal/companion, show item-based mount tooltip
    if not HasMountUI() then
        ShowItemMountTooltip(widget)
        return
    end
    
    -- Get mount configuration
    local ground, flying, multi = Module.GetMountConfig()
    local isFlyable = IsFlyableAreaFixed()
    
    -- Check current modifier state
    local isShift = IsShiftKeyDown()
    local isCtrl = IsControlKeyDown()
    local isAlt = IsAltKeyDown()
    local anyMod = isShift or isCtrl or isAlt
    
    -- Determine what each modifier casts based on mode
    local noModMount = nil
    local modMount = nil  -- For vendor mount mode (any modifier)
    local shiftMount = ground
    local ctrlMount = multi
    local altMount = nil
    local altIsFlightStyle = false
    local isVendorMode = (mode == Module.MODE_VENDOR)
    
    if isVendorMode then
        -- Vendor mount mode: Yak on nomod, Brutosaur on any mod
        local hasBruto = Module.HasBrutosaur()
        local hasYak = Module.HasYak()
        
        if hasYak then
            local yak = Module.GetYak()
            noModMount = yak and yak.name
        end
        if hasBruto then
            local bruto = Module.GetBrutosaur()
            modMount = bruto and bruto.name
        end
        
        -- If only one available, use it for both
        if not noModMount and modMount then
            noModMount = modMount
        elseif not modMount and noModMount then
            modMount = noModMount
        end
    else
        noModMount = (isFlyable and flying) or ground or flying
        
        if HasSwitchFlightStyle() then
            altMount = "Switch Flight Style"
            altIsFlightStyle = true
        else
            altMount = flying or ground
        end
    end
    
    -- Determine active mount based on current modifiers
    local activeMountName = noModMount
    local activeModifier = "Click"
    
    if isVendorMode then
        -- Vendor mode: any modifier = brutosaur
        if anyMod then
            activeMountName = modMount
            activeModifier = "Modifier"
        end
    else
        -- Smart mount mode
        if isShift then
            activeMountName = shiftMount
            activeModifier = "Shift"
        elseif isCtrl then
            activeMountName = ctrlMount
            activeModifier = "Ctrl"
        elseif isAlt then
            if altIsFlightStyle then
                activeMountName = "Switch Flight Style"
            else
                activeMountName = altMount
            end
            activeModifier = "Alt"
        end
    end
    
    -- Title with icon - the active mount (GREEN)
    local activeText, activeIcon = FormatMountWithIcon(activeMountName, 20)
    if activeText then
        GameTooltip:AddLine(activeText, 0.2, 1, 0.2)  -- Green
    else
        GameTooltip:AddLine("Mount", 0.2, 1, 0.2)
    end
    
    -- Mode info
    GameTooltip:AddLine(" ")
    if isVendorMode then
        GameTooltip:AddLine("Mode: Vendor Mount", 0.5, 1, 0.5)
    else
        GameTooltip:AddLine("Mode: Smart Mount", 0.5, 1, 0.5)
    end
    
    -- Flight style info (if applicable, only for smart mount)
    if not isVendorMode then
        local flightStyle = GetCurrentFlightStyle()
        if flightStyle and HasSwitchFlightStyle() then
            GameTooltip:AddLine("Flight Style: " .. flightStyle, 0.6, 0.8, 1)
        end
        
        -- Area info
        if isFlyable then
            GameTooltip:AddLine("Area: Flyable", 0.5, 0.8, 1)
        else
            GameTooltip:AddLine("Area: Ground Only", 0.8, 0.6, 0.4)
        end
    end
    
    -- Modifier section
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Modifiers:", 1, 0.82, 0)
    
    -- Helper to add mount line with proper coloring
    local function AddMountLine(prefix, mountName, isActive, isFlightStyle)
        local r, g, b
        if isActive then
            r, g, b = 0.2, 1, 0.2  -- Green for active
        elseif mountName and mountName ~= "" then
            r, g, b = 0.8, 0.8, 0.8  -- White for set
        else
            r, g, b = 0.5, 0.5, 0.5  -- Gray for not set
        end
        
        local text
        if mountName and mountName ~= "" then
            local icon = GetMountIconTexture(mountName)
            if icon and not isFlightStyle then
                text = prefix .. ": |T" .. icon .. ":14:14:0:0|t " .. mountName
            else
                text = prefix .. ": " .. mountName
            end
        else
            text = prefix .. ": (not set)"
        end
        
        GameTooltip:AddLine(text, r, g, b)
    end
    
    if isVendorMode then
        -- Vendor mount mode: Click = Yak, Any Mod = Brutosaur
        AddMountLine("Click", noModMount, activeModifier == "Click", false)
        AddMountLine("Any Mod", modMount, activeModifier == "Modifier", false)
    else
        -- Smart mount mode: Click, Shift, Ctrl, Alt
        -- Click (no modifier)
        AddMountLine("Click", noModMount, activeModifier == "Click", false)
        
        -- Shift (Ground)
        AddMountLine("Shift", shiftMount, activeModifier == "Shift", false)
        
        -- Ctrl (Multi-seat)
        AddMountLine("Ctrl", ctrlMount, activeModifier == "Ctrl", false)
        
        -- Alt (Flying or Switch Flight Style)
        if altIsFlightStyle then
            AddMountLine("Alt", "Switch Flight Style", activeModifier == "Alt", true)
        else
            AddMountLine("Alt", altMount, activeModifier == "Alt", false)
        end
    end
    
    -- Action hints
    GameTooltip:AddLine(" ")
    if hasVendor then
        if FluxNCHotkeyUtil and FluxNCHotkeyUtil.AddTooltipBinding then
            FluxNCHotkeyUtil.AddTooltipBinding(GameTooltip, "Middle-click: Toggle Smart/Vendor", "FLUXGRIDVENDORMOUNT")
        else
            GameTooltip:AddLine("Middle-click: Toggle Smart/Vendor", 0.5, 0.8, 1)
        end
    end
    -- Only show right-click hint if mount UI is available
    if HasMountUI() then
        GameTooltip:AddLine("Right-click: Open Mounts", 0.5, 0.8, 1)
    end
    
    GameTooltip:Show()
end

function Module.SetupTooltip(btn)
    if not btn or not btn.Widget then return end
    
    local widget = btn.Widget
    local Hover = _G.FluxTooltipHover

    local function hideGridTooltip()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end
    if Hover and Hover.RegisterGridWidget then
        Hover.RegisterGridWidget(widget, hideGridTooltip)
    end
    
    widget:SetScript("OnEnter", function(self)
        tooltipShowing = true
        lastModifierState = GetModifierState()
        if Hover and Hover.BeginGridHover then
            Hover.BeginGridHover(self, function()
                ShowMountTooltip(self)
            end)
        else
            ShowMountTooltip(self)
        end
    end)
    
    widget:SetScript("OnLeave", function(self)
        tooltipShowing = false
        self:SetScript("OnUpdate", nil)
        if Hover and Hover.EndGridHover then
            Hover.EndGridHover(self, hideGridTooltip)
        else
            hideGridTooltip()
        end
    end)
end

-- Refresh tooltip if currently shown
function Module.RefreshTooltip()
    if tooltipShowing and Module._button and Module._button.Widget then
        ShowMountTooltip(Module._button.Widget)
    end
end

-- ============================================================================
-- SCOPE DETECTION (matches config mode)
-- ============================================================================

-- Get button scope based on config mode
function Module.GetCurrentScope()
    -- For clients without mount journal or companion system, always use character scope
    if not HasMountUI() then
        return "character"
    end
    
    -- Normal scope detection from config
    if _G.FluxSmartMountConfig and _G.FluxSmartMountConfig.IsUsingCharacterSpecific then
        if _G.FluxSmartMountConfig.IsUsingCharacterSpecific() then
            return "character"
        end
    end
    return "account"
end

-- Update button scope and styling to match config mode
function Module.UpdateButtonScope()
    local btn = Module._button
    if not btn then return end

    if HasToyAndMountCollections() and HasMountUI() and FluxButtonUtil and FluxButtonUtil.ApplyNonCombatSmartCollectionButtonStyle then
        local useChar = _G.FluxSmartMountConfig and _G.FluxSmartMountConfig.IsUsingCharacterSpecific and _G.FluxSmartMountConfig.IsUsingCharacterSpecific() or false
        FluxButtonUtil:ApplyNonCombatSmartCollectionButtonStyle(btn, useChar)
        return
    end

    -- Get scope (will return "character" for clients without mount UI)
    local scope = Module.GetCurrentScope()

    -- For placeholder buttons, always use character scope (legacy / non-collection clients)
    if Module._isPlaceholder then
        scope = "character"
    end

    -- Apply the new scope and styling
    if FluxButtonUtil and FluxButtonUtil.ApplyButtonStyle then
        FluxButtonUtil:ApplyButtonStyle(btn, scope)
    else
        -- Fallback: manually set scope and update ring border
        btn.categoryScope = scope
        if FluxButtonUtil and FluxButtonUtil.ApplyExtraButtonRingBorder then
            FluxButtonUtil:ApplyExtraButtonRingBorder(btn, scope)
        end
        if btn.UpdateEmptyBackground then
            btn:UpdateEmptyBackground()
        end
    end
end

-- ============================================================================
-- TEXTURE UPDATE
-- ============================================================================

--- Static preview icon for a mount mode (same rules as UpdateTexture when not locked).
local function ResolveTextureForMountMode(mode)
    if mode == Module.MODE_VENDOR then
        local hasBruto = Module.HasBrutosaur()
        local hasYak = Module.HasYak()
        local texture
        if hasYak then
            local yak = Module.GetYak()
            if yak and yak.icon then
                texture = yak.icon
            end
        elseif hasBruto then
            local bruto = Module.GetBrutosaur()
            if bruto and bruto.icon then
                texture = bruto.icon
            end
        end
        if not texture then
            texture = "Interface\\Icons\\ability_mount_travelersmammoth"
        end
        return texture
    end

    local ground, flying = Module.GetMountConfig()
    local isFlyable = IsFlyableAreaFixed()
    local mountName = (isFlyable and flying) or ground or flying
    local texture
    if mountName then
        if C_Spell and C_Spell.GetSpellTexture then
            texture = C_Spell.GetSpellTexture(mountName)
        elseif GetSpellTexture then
            texture = GetSpellTexture(mountName)
        end
        if not texture then
            local mount = GetCollectedMountByName(mountName)
            if mount and mount.icon then
                texture = mount.icon
            end
        end
        if not texture and _G.FluxSmartMountConfig and _G.FluxSmartMountConfig.GetMountIconTexture then
            texture = _G.FluxSmartMountConfig.GetMountIconTexture(mountName)
        end
    end
    if not texture then
        texture = "Interface\\Icons\\ability_mount_ridinghorse"
    end
    return texture
end

--- Icon for the mode you would switch to with the vendor toggle binding (opposite of current).
function Module.GetOppositeMountModeIconForBindingGhost()
    if not HasMountUI() then
        return nil
    end
    local mode = Module.GetMode()
    local opposite = (mode == Module.MODE_VENDOR) and Module.MODE_SMART or Module.MODE_VENDOR
    return ResolveTextureForMountMode(opposite)
end

function Module.UpdateTexture()
    local btn = Module._button
    if not btn or Module._isPlaceholder then return end
    
    -- For legacy clients (Vanilla/TBC): Icon is managed by UpdateBagMountIcon()
    -- Return EARLY before any lock checks to prevent interference
    if not HasMountUI() then
        return
    end
    
    local texture
    local mountName
    
    -- If casting with a pending lock, use the pending mount's icon
    -- This prevents fallback to default icon during mount cast
    if Module._isCasting and Module._pendingLockMount and Module._pendingLockMount.icon then
        texture = Module._pendingLockMount.icon
    -- Also check pending lock even if not casting (for smooth transitions)
    elseif Module._pendingLockMount and Module._pendingLockMount.icon then
        texture = Module._pendingLockMount.icon
    -- If locked, use the locked mount's icon
    elseif Module._isLocked and Module._lockedMount and Module._lockedMount.icon then
        texture = Module._lockedMount.icon
    elseif Module._isLocked and Module._lockedMount and Module._lockedMount.name then
        -- Try to get texture from locked mount name
        mountName = Module._lockedMount.name
        if C_Spell and C_Spell.GetSpellTexture then
            texture = C_Spell.GetSpellTexture(mountName)
        elseif GetSpellTexture then
            texture = GetSpellTexture(mountName)
        end
        if not texture then
            local mount = GetCollectedMountByName(mountName)
            if mount and mount.icon then
                texture = mount.icon
            end
        end
    end
    
    -- If not locked (or couldn't get locked texture), use normal logic
    if not texture then
        texture = ResolveTextureForMountMode(Module.GetMode())
    end
    
    -- Apply via SetProtectedIcon so icon-protection hook does not drop the change
    if texture then
        if btn.WIcon then
            SetProtectedIcon(btn, texture, true)
        else
            btn.Texture = texture
            Module._currentTexture = texture
            if btn.Widget and btn.Widget.icon then
                btn.Widget.icon:SetTexture(texture)
                btn.Widget.icon:Show()
            end
            if btn.Widget and btn.Widget.Icon then
                btn.Widget.Icon:SetTexture(texture)
                btn.Widget.Icon:Show()
            end
        end

        if btn.UpdateUsable then
            btn:UpdateUsable()
        end
    end
end

-- ============================================================================
-- BUTTON UPDATE
-- ============================================================================

function Module.Update()
    if not Module._button then return end
    if InCombatLockdown() then
        Module._pendingUpdate = true
        return
    end
    
    local btn = Module._button

    -- Check riding skill for Extra Button Visibility (Auto mode)
    local hasRiding = Module.HasRidingSkill()
    -- Extra visibility Auto: show only when the player can ride (skill/level). Hide without riding even if mount items exist.
    local smartMount = hasRiding == true
    local bindingForceEBV = FluxExtraButtonVisibility and FluxExtraButtonVisibility.GetBindingForce and FluxExtraButtonVisibility.GetBindingForce() or false
    -- Auto + no riding: hide outside binding mode. In binding mode, slot always shows for key assignment (Auto/Off ignored).
    if not bindingForceEBV and FluxExtraButtonVisibility and FluxExtraButtonVisibility.GetEffectiveMode then
        local mountMode = FluxExtraButtonVisibility.GetEffectiveMode("nc_mount")
        if mountMode == "auto" and not hasRiding then
            if btn.Widget and FluxFlyoutFrame and FluxFlyoutFrame.HideArrow then
                FluxFlyoutFrame.HideArrow(btn.Widget)
            end
            if btn.SlotFrame then btn.SlotFrame:Hide() end
            if btn.Widget then btn.Widget:Hide() end
            Module.ClearMountKeybinding()
            if Module._grid and Module._grid.ScheduleRelayout then
                Module._grid:ScheduleRelayout()
            elseif Module._grid and Module._grid.Relayout then
                Module._grid:Relayout()
            end
            return
        end
    end
    if not bindingForceEBV and FluxExtraButtonVisibility and not FluxExtraButtonVisibility.Apply("nc_mount", smartMount, bindingForceEBV) then
        if btn.Widget and FluxFlyoutFrame and FluxFlyoutFrame.HideArrow then
            FluxFlyoutFrame.HideArrow(btn.Widget)
        end
        if btn.SlotFrame then btn.SlotFrame:Hide() end
        if btn.Widget then btn.Widget:Hide() end
        Module.ClearMountKeybinding()
        if Module._grid and Module._grid.ScheduleRelayout then
            Module._grid:ScheduleRelayout()
        elseif Module._grid and Module._grid.Relayout then
            Module._grid:Relayout()
        end
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

    -- ALWAYS update button scope to match config mode (character vs account)
    Module.UpdateButtonScope()


    if not Module.CanDisplayMountButton() then
        SetPlaceholder(btn)
    else
        -- Clear placeholder if it was set
        local wasPlaceholder = Module._isPlaceholder
        if wasPlaceholder then
            ClearPlaceholder(btn)
        end
        
        -- For clients without mount UI, use bag mount setup
        if not HasMountUI() then
            Module.SetupBagMountButton()
            -- Icon is set inside SetupBagMountButton; ensure held-mod icon if setup early-out
            if not Module._lastBagMountMacro then
                RefreshBagMountIconForLocation()
            end
            lastBagMountIconModState = ""
        else
            -- Update macro using FluxButton's SetAction method (handles texture automatically)
            local macro = Module.GetCurrentMacro()
            local macroChanged = (Module._lastJournalMacro ~= macro)
            if macroChanged then
                Module._lastJournalMacro = macro
                if btn.SetAction then
                    btn:SetAction("macrotext", macro)
                elseif btn.Widget then
                    btn.Widget:SetAttribute("type", "macro")
                    btn.Widget:SetAttribute("macrotext", macro)
                end
            end
        end
        
        -- Force texture update (in case SetAction doesn't find the right texture)
        Module.UpdateTexture()
        
        -- Update middle-click (vendor mount availability may have changed)
        Module.SetupMiddleClick(btn)
        -- Update right-click (open mount collection) - SetAction clears type2/macrotext2, so restore it
        Module.SetupRightClick(btn)
    end
    
    -- Update hotkey text display
    Module.UpdateHotkeyText(btn)
    
    -- FullRefresh only when macro/action may have changed (skip icon-only bag refreshes)
    local needFullRefresh = HasMountUI() or Module._bagMountNeedsFullRefresh
    if needFullRefresh and btn.FullRefresh then
        btn:FullRefresh()
    end
    Module._bagMountNeedsFullRefresh = nil

    -- Journal: apply modifier-aware icon AFTER FullRefresh so macro texture parse cannot stick
    if HasMountUI() and not Module._isPlaceholder and not Module._isLocked
        and not Module._isCasting and not Module._pendingLockMount then
        lastBagMountIconModState = ""
        Module.UpdateJournalMountIcon(GetCurrentHeldModKey())
        if FluxModifierTracker and FluxModifierTracker.NotifyActiveChanged then
            FluxModifierTracker.NotifyActiveChanged()
        end
    end
    
    -- Refresh tooltip if shown (our own tooltip)
    Module.RefreshTooltip()
    
    -- Also refresh grid tooltips
    if Module._grid and Module._grid.RefreshTooltipsIfHovered then
        Module._grid:RefreshTooltipsIfHovered()
    end

    Module.UpdateMountKeybinding(btn)
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

-- Shared by SKILL_LINES_CHANGED (direct) and the Core SpellBook bus.
local function OnSpellBookChanged()
    Module.InvalidateRidingSkillCache()
    -- Riding skill or spells changed - update button
    if not InCombatLockdown() then
        -- Delay slightly to ensure data is ready
        Timer.After(0.5, function()
            if Module._registered then
                 Module.Update()
            end
        end)
    end

    -- Item info just became available - re-scan for mounts (legacy clients)
    if not HasMountUI() then
        InvalidateAllMountItemCaches()

        -- Debounce updates
        if not Module._itemInfoTimer then
            Module._itemInfoTimer = Timer.After(0.3, function()
                Module._itemInfoTimer = nil
                if Module._registered and not InCombatLockdown() and not Module._isPlaceholder then
                    Module._bagMountNeedsFullRefresh = true
                    Module.Update()
                end
            end)
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGIN")
-- SPELLS_CHANGED rides the debounced, signature-gated Core bus; the direct
-- frame registration stays only as fallback. SKILL_LINES_CHANGED stays direct.
do
    local SpellBook = _G.Flux and _G.Flux.SpellBook
    if SpellBook and SpellBook.OnChanged then
        SpellBook.OnChanged("ncgrid.mount", OnSpellBookChanged)
    else
        eventFrame:RegisterEvent("SPELLS_CHANGED")
    end
end
if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("SKILL_LINES_CHANGED") then
    eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
elseif not C_EventUtils then
    -- TBC/Vanilla fallback
    pcall(function() eventFrame:RegisterEvent("SKILL_LINES_CHANGED") end)
end

-- Only register mount-related events if the API exists
if HasMountJournalAPI() then
    eventFrame:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
    eventFrame:RegisterEvent("NEW_MOUNT_ADDED")
end
if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("COLLECTIONS_UPDATED") then
    eventFrame:RegisterEvent("COLLECTIONS_UPDATED")
elseif not C_EventUtils then
    pcall(function() eventFrame:RegisterEvent("COLLECTIONS_UPDATED") end)
end
if HasCompanionAPI() then
    eventFrame:RegisterEvent("COMPANION_LEARNED")
end

-- Mount lock feature events
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player") end)
pcall(function() eventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED") end)
do
    local function SafeRegister(frame, eventName)
        local Flux = _G.Flux
        local Events = Flux and Flux.Events
        if Events and Events.SafeRegister then
            return Events.SafeRegister(frame, eventName)
        end
        if _G.FluxSafeRegisterEvent then
            return _G.FluxSafeRegisterEvent(frame, eventName)
        end
        return pcall(frame.RegisterEvent, frame, eventName)
    end
    SafeRegister(eventFrame, "ZONE_CHANGED")
    SafeRegister(eventFrame, "ZONE_CHANGED_INDOORS")
    SafeRegister(eventFrame, "ZONE_CHANGED_NEW_AREA")
end

-- Helper: Check if a spell is a mount spell
local function IsMountSpell(spellID)
    if not spellID then return false end
    
    -- Check mount journal
    if C_MountJournal and C_MountJournal.GetMountFromSpell then
        local mountID = C_MountJournal.GetMountFromSpell(spellID)
        return mountID ~= nil
    end
    
    -- Fallback: check if spell name contains common mount patterns
    local spellName
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        spellName = info and info.name
    elseif GetSpellInfo then
        spellName = GetSpellInfo(spellID)
    end
    
    if spellName then
        -- Check against our pending lock mount
        if Module._pendingLockMount and Module._pendingLockMount.name then
            if spellName:lower() == Module._pendingLockMount.name:lower() then
                return true
            end
        end
        -- Check against locked mount
        if Module._lockedMount and Module._lockedMount.name then
            if spellName:lower() == Module._lockedMount.name:lower() then
                return true
            end
        end
    end
    
    return false
end

local function ResetMountLoginState()
    Module._isLocked = false
    Module._lockedMount = nil
    Module._pendingLockMount = nil
    Module._isCasting = false
    ClearCastLockSpellId()
end

local _postLoginRefreshGen = 0
local _postLoginRefreshScheduled = false

InvalidateAllMountItemCaches = function()
    mountBagCache = nil
    mountBagCacheTime = 0
    if FluxNCMountItems and FluxNCMountItems.InvalidateCache then
        FluxNCMountItems.InvalidateCache()
    elseif FluxItemDetection and FluxItemDetection.InvalidateMountItemsCache then
        FluxItemDetection.InvalidateMountItemsCache()
    elseif FluxItemDetection and FluxItemDetection.InvalidateAllMountItemsCache then
        FluxItemDetection.InvalidateAllMountItemsCache()
    end
end

-- Settle pulses: rescan location/bags without wiping mount trait tooltips.
InvalidateMountItemCachesForSettle = function()
    mountBagCache = nil
    mountBagCacheTime = 0
    if FluxNCMountItems and FluxNCMountItems.InvalidateCacheForSettle then
        FluxNCMountItems.InvalidateCacheForSettle()
        return
    end
    local Spells = GetMountFlyable()
    if Spells and Spells.InvalidateMountItemsCacheForSettle then
        Spells.InvalidateMountItemsCacheForSettle()
        if FluxNCMountItems and FluxNCMountItems.InvalidateFavoriteMap then
            FluxNCMountItems.InvalidateFavoriteMap()
        end
        return
    end
    InvalidateAllMountItemCaches()
end

IsBagMountLocationSettling = function()
    local Spells = GetMountFlyable()
    if Spells and Spells.IsMountItemLocationSettling then
        return Spells.IsMountItemLocationSettling()
    end
    return false
end

RememberGoodBagMount = function(mount, macro)
    if macro and macro ~= "" then
        Module._lastGoodBagMountMacro = macro
    end
    if mount and mount.itemId then
        Module._lastGoodBagMount = mount
    end
end

ClearGoodBagMount = function()
    Module._lastGoodBagMountMacro = nil
    Module._lastGoodBagMount = nil
end

-- After teleport/load screens, held-modifier state is unreliable (keys released
-- during the load screen may not fire MODIFIER_STATE_CHANGED). During settle,
-- always show/resolve the nomod mount; after settle, re-sample live keys.
RefreshBagMountIconForLocation = function(opts)
    opts = opts or {}
    lastBagMountIconModState = ""
    lastModifierState = GetModifierState()
    if HasMountUI() then
        return
    end
    if not Module._button or Module._isPlaceholder or Module._isLocked then
        return
    end
    local forceNomod = opts.forceNomod
    if forceNomod == nil then
        forceNomod = IsBagMountLocationSettling()
    end
    local modKey = forceNomod and "nomod" or GetCurrentHeldModKey()
    Module.UpdateBagMountIcon(modKey)
    if FluxModifierTracker and FluxModifierTracker.NotifyActiveChanged then
        FluxModifierTracker.NotifyActiveChanged()
    end
end

-- Bag mounts bake item IDs into macros (no [flyable]). After teleport/BG/dungeon
-- transitions, map APIs lag — prefer ground while flyable is false, rebuild until
-- location key is stable (early-end) or the settle safety window expires.
local BAG_MOUNT_SETTLE_DELAYS = { 0, 0.1, 0.25, 0.5, 1.0, 1.5, 2.5, 3.5 }
local function BeginBagMountLocationSettle(forceSettle)
    if HasMountUI() then
        return
    end
    local Spells = GetMountFlyable()
    local beginSettle = Spells and Spells.BeginMountItemLocationSettle
    if forceSettle and beginSettle then
        beginSettle(3.5)
    end

    InvalidateMountItemCachesForSettle()
    Module._bagMountNeedsFullRefresh = true
    Module._zoneMountRefreshGen = (Module._zoneMountRefreshGen or 0) + 1
    local gen = Module._zoneMountRefreshGen
    local lastKey = nil
    local wasSettling = true

    -- Drop sticky mod-key icon immediately (shift held through loading screen).
    RefreshBagMountIconForLocation({ forceNomod = true })

    local function refreshIfCurrent()
        if gen ~= Module._zoneMountRefreshGen then
            return
        end
        if not Module._registered then
            return
        end
        if InCombatLockdown() then
            Module._pendingUpdate = true
            return
        end

        InvalidateMountItemCachesForSettle()
        Module._bagMountNeedsFullRefresh = true

        local getKey = Spells and Spells.GetMountItemLocationKey
        local updateSettle = Spells and Spells.UpdateMountItemLocationSettle
        local isSettling = Spells and Spells.IsMountItemLocationSettling
        local key = getKey and getKey() or nil
        local changed = true
        if updateSettle then
            key, changed = updateSettle(key)
        else
            changed = key ~= lastKey
        end
        lastKey = key
        local settling = isSettling and isSettling() or false
        local settleEnded = wasSettling and not settling
        wasSettling = settling

        if changed or settleEnded or not Module._lastBagMountMacro then
            Module.Update()
        end
        if settleEnded then
            -- Re-sample live modifiers after load screen (release may have been missed).
            RefreshBagMountIconForLocation({ forceNomod = false })
        elseif settling then
            RefreshBagMountIconForLocation({ forceNomod = true })
        end
    end

    for _, delay in ipairs(BAG_MOUNT_SETTLE_DELAYS) do
        if delay <= 0 then
            refreshIfCurrent()
        elseif C_Timer and C_Timer.After then
            C_Timer.After(delay, refreshIfCurrent)
        end
    end
end

local function runPostLoginMountRefresh(isLoginBootstrap)
    local function doUpdate()
        _postLoginRefreshScheduled = false
        -- Journal usable-mount list may need refresh after login; bag list via InvalidateAllMountItemCaches
        InvalidateAllMountItemCaches()
        if not Module._registered then return end
        if InCombatLockdown() then
            Module._pendingUpdate = true
            return
        end
        if not HasMountUI() then
            BeginBagMountLocationSettle(true)
            return
        end
        Module._bagMountNeedsFullRefresh = true
        Module.Update()
    end

    local pl = FluxEBS_PostLoginBagRefresh
    local loginBootstrap = isLoginBootstrap
        or (pl and pl.IsFreshLoginBootstrap and pl.IsFreshLoginBootstrap())

    if loginBootstrap then
        -- Coalesce LOGIN + PEW + delayed bag callbacks into one scheduled refresh
        if _postLoginRefreshScheduled then
            return
        end
        _postLoginRefreshScheduled = true
        _postLoginRefreshGen = _postLoginRefreshGen + 1
        local gen = _postLoginRefreshGen
        local wrapped = function()
            if gen ~= _postLoginRefreshGen then return end
            doUpdate()
        end
        if pl and pl.ScheduleLoginItemRefresh then
            pl.ScheduleLoginItemRefresh(wrapped)
        elseif pl and pl.Schedule then
            pl.Schedule(wrapped, pl.LOGIN_ITEM_DELAYS)
        else
            doUpdate()
        end
    else
        doUpdate()
    end
end

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Combat started - lock icon to prevent macro/modifier texture updates during combat
        if Module._button and Module._button.WIcon then
            _iconManagedByModule = true
        end
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not Module._registered or not Module._button then
            return
        end
        local pu = Module._pendingUpdate
        local pk = Module._pendingKeybindUpdate
        local shouldUnlock = Module._isLocked and not IsMounted()
        local needIconRefresh = _iconManagedByModule == true

        if not (pu or pk or shouldUnlock or needIconRefresh) then
            return
        end
        Module._pendingUpdate = nil
        Module._pendingKeybindUpdate = nil

        if needIconRefresh then
            local runHeavyIcon = function()
                if InCombatLockdown() then
                    return
                end
                if not HasMountUI() then
                    _iconManagedByModule = true
                    Module.UpdateBagMountIcon()
                else
                    _iconManagedByModule = false
                    Module.UpdateTexture()
                end
                if Module._button and Module._button.UpdateUsable then
                    Module._button:UpdateUsable()
                end
            end
            if FluxRegenDeferHeavyQueue then
                FluxRegenDeferHeavyQueue(runHeavyIcon)
            elseif FluxCombatRegenDeferQueue then
                FluxCombatRegenDeferQueue(runHeavyIcon)
            else
                runHeavyIcon()
            end
        end

        if not (pu or pk or shouldUnlock) then
            return
        end

        local runLight = function()
            if InCombatLockdown() then
                if pu then Module._pendingUpdate = true end
                if pk then Module._pendingKeybindUpdate = true end
                return
            end
            if pu then
                Module.Update()
            end
            if pk then
                Module.UpdateMountKeybinding()
            end
            if shouldUnlock then
                Module.Unlock()
            end
        end
        if FluxCombatRegenDeferQueue then
            FluxCombatRegenDeferQueue(runLight)
        else
            runLight()
        end
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin = (arg1 == true or arg2 == true)
        if not isInitialLogin and not Module._fluxSeenPew then
            isInitialLogin = true
        end
        Module._fluxSeenPew = true
        if isInitialLogin then
            ResetMountLoginState()
            runPostLoginMountRefresh(true)
        else
            -- Dungeon/portal load screen: keep the item; do not unlock or placeholder.
            if not HasMountUI() then
                BeginBagMountLocationSettle(true)
            else
                runPostLoginMountRefresh(false)
            end
        end
        
    elseif event == "PLAYER_LOGIN" then
        Module._fluxSeenPew = true
        ResetMountLoginState()
        runPostLoginMountRefresh(true)
        
    elseif event == "SPELLS_CHANGED" or event == "SKILL_LINES_CHANGED" then
        OnSpellBookChanged()

    elseif event == "COMPANION_LEARNED" or event == "MOUNT_JOURNAL_USABILITY_CHANGED"
        or event == "NEW_MOUNT_ADDED" or event == "COLLECTIONS_UPDATED" then
        -- Mount collection changed - invalidate cache
        Module.InvalidateCollectedMountCache()
        Module._cachedMounts = nil
        mountBagCache = nil
        mountBagCacheTime = 0
        if not InCombatLockdown() then
            Module.Update()
        else
            Module._pendingUpdate = true
        end
        
    elseif event == "UNIT_SPELLCAST_START" then
        -- arg1 = unit, arg2 = castGUID (or spellName on older clients), arg3 = spellID (on some clients)
        if arg1 ~= "player" then return end
        
        -- Get spell info
        local spellID = arg3
        if not spellID and type(arg2) == "number" then
            spellID = arg2
        end
        if spellID and (Module._pendingLockMount or Module._isLocked or Module._isCasting) then
            SetCastLockSpellId(spellID)
        elseif Module._pendingLockMount and Module._pendingLockMount.spellID then
            SetCastLockSpellId(Module._pendingLockMount.spellID)
        end
        
        -- Check if we have a pending lock and this is the expected cast (mount or Switch Flight Style)
        if Module._pendingLockMount and not Module._isLocked then
            local isMountCast = false
            if spellID and IsMountSpell(spellID) then
                isMountCast = true
            elseif Module._pendingLockMount.spellID and spellID == Module._pendingLockMount.spellID then
                isMountCast = true
            elseif IsSwitchFlightStyleSpell(spellID, Module._pendingLockMount.name) then
                isMountCast = true
            end
            
            if isMountCast or Module._pendingLockMount.name then
                -- Lock to the pending mount/spell for the cast duration
                Module._isCasting = true
                Module.LockToMount(
                    Module._pendingLockMount.name,
                    Module._pendingLockMount.icon,
                    Module._pendingLockMount.spellID
                )
            end
        end
        
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_STOP" then
        -- Cast completed
        if arg1 ~= "player" then return end

        local spellID = arg3
        if not spellID and type(arg2) == "number" then
            spellID = arg2
        end

        -- Switch Flight Style is not a mount: unlock when cast finishes (incl. instant casts)
        if IsFlightStyleLockActive() then
            local expectId = (Module._lockedMount and Module._lockedMount.spellID)
                or (Module._pendingLockMount and Module._pendingLockMount.spellID)
            if not spellID or spellID == expectId or IsSwitchFlightStyleSpell(spellID) then
                UnlockSwitchFlightStyleIfNeeded()
                return
            end
        end

        Module._isCasting = false
        -- Don't unlock mounts - player should now be mounted
        if event == "UNIT_SPELLCAST_STOP" and not Module._isLocked and not Module._pendingLockMount then
            ClearCastLockSpellId()
        end
        
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        -- Cast failed/interrupted - unlock only when NOT mounted (clicking to dismount can fire FAILED)
        if arg1 ~= "player" then return end

        -- Flight style: always clear cast lock on interrupt/fail
        if IsFlightStyleLockActive() then
            ForceClearButtonCastVFX()
            ClearMountButtonCheckedState()
            UnlockSwitchFlightStyleIfNeeded()
            return
        end

        local wasLocked = Module._isLocked
        Module._pendingLockMount = nil
        Module._isCasting = false
        ClearCastLockSpellId()
        ForceClearButtonCastVFX()
        -- Dismount click often fires FAILED; clear checked for item + journal mounts
        ClearMountButtonCheckedState()

        if wasLocked and not IsMounted() then
            -- Unlock since cast was interrupted/failed; or defer until out of combat
            if not InCombatLockdown() then
                Module.Unlock()
            else
                Module._pendingUpdate = true
            end
        elseif not HasMountUI() and Module._button and not Module._isPlaceholder and not Module._isLocked then
            -- Light refresh only — avoid full Module.Update / SetupBagMountButton hitch
            lastBagMountIconModState = ""
            Module.UpdateBagMountIcon(GetCurrentHeldModKey())
        end
        
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        -- Always clear sticky checked highlight on mount/dismount (bag + journal)
        ClearMountButtonCheckedState()
        local btn = Module._button
        if btn and btn.UpdateChecked then
            btn:UpdateChecked()
        end

        -- Check if player dismounted
        if Module._isLocked and not IsMounted() then
            -- Player dismounted - unlock if out of combat
            if not InCombatLockdown() then
                Module.Unlock()
            else
                -- Will unlock when combat ends (handled in PLAYER_REGEN_ENABLED)
            end
        end

    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
        -- Bag mounts: no [flyable] macro — resettle location fingerprint after teleports.
        Module._cachedMounts = nil
        if not HasMountUI() then
            local forceSettle = (event == "ZONE_CHANGED_NEW_AREA")
            if InCombatLockdown() or not Module._registered then
                local Spells = GetMountFlyable()
                local beginSettle = Spells and Spells.BeginMountItemLocationSettle
                if forceSettle and beginSettle then
                    beginSettle(3.5)
                end
                InvalidateMountItemCachesForSettle()
                Module._pendingUpdate = true
                return
            end
            BeginBagMountLocationSettle(forceSettle)
            return
        end
        InvalidateAllMountItemCaches()
        Module._lastBagMountMacro = nil
        if InCombatLockdown() or not Module._registered then
            Module._pendingUpdate = true
            return
        end
        Module._bagMountNeedsFullRefresh = true
        Module._zoneMountRefreshGen = (Module._zoneMountRefreshGen or 0) + 1
        local gen = Module._zoneMountRefreshGen
        local function refreshIfCurrent()
            if gen ~= Module._zoneMountRefreshGen then
                return
            end
            if InCombatLockdown() then
                Module._pendingUpdate = true
                return
            end
            Module.Update()
        end
        refreshIfCurrent()
        if C_Timer and C_Timer.After then
            C_Timer.After(0.25, refreshIfCurrent)
            C_Timer.After(1.0, refreshIfCurrent)
        end
    end
end)

-- FluxInv is the bag SoT for item mounts (BagChangeDispatcher is disabled in toc).
if _G.FluxInv and _G.FluxInv.RegisterListener and not Module._fluxInvListenerRegistered then
    Module._fluxInvListenerRegistered = true
    local mountFluxInvPending = false

    local function RunFluxInvMountUpdate()
        mountFluxInvPending = false
        if not Module._registered then
            return
        end
        if InCombatLockdown() then
            Module._pendingUpdate = true
            return
        end
        InvalidateAllMountItemCaches()
        Module._lastBagMountMacro = nil
        Module._bagMountNeedsFullRefresh = true
        Module.Update()
    end

    local function ScheduleFluxInvMountUpdate()
        if mountFluxInvPending then
            return
        end
        mountFluxInvPending = true
        if C_Timer and C_Timer.After then
            C_Timer.After(0.15, RunFluxInvMountUpdate)
        else
            RunFluxInvMountUpdate()
        end
    end

    _G.FluxInv.RegisterListener("NCMount", function(ctx)
        if not Module._registered then
            return
        end
        -- item-data / light pulses: clear sticky false classify + light icon refresh
        local tier = ctx and ctx.tier
        local countOnly = ctx and ctx.changeKind == "countOnly" and not ctx.force
        if countOnly or tier == "instant" or tier == "light" then
            InvalidateAllMountItemCaches()
            local btn = Module._button
            if btn and not Module._isPlaceholder then
                if not HasMountUI() and Module.UpdateBagMountIcon then
                    Module.UpdateBagMountIcon()
                elseif btn.UpdateUsable then
                    btn:UpdateUsable()
                end
            end
            if InCombatLockdown() then
                return
            end
            -- Promote to real mount button if bags now have a mount
            if not countOnly and Module._isPlaceholder and Module.CanDisplayMountButton and Module.CanDisplayMountButton() then
                ScheduleFluxInvMountUpdate()
            end
            return
        end
        ScheduleFluxInvMountUpdate()
    end, { tier = "scan", regions = { "bags" }, deferHeavy = true })
end

if FluxBagChangeDispatcher and FluxBagChangeDispatcher.Register then
    local mountFullUpdatePending = false
    local mountFullUpdateInvalidate = false

    local function RefreshCountOnly()
        local btn = Module._button
        if not btn or not Module._registered then return end
        if Module._isPlaceholder then return end
        if btn.UpdateTextCount then
            btn:UpdateTextCount()
        end
        if not HasMountUI() and Module.UpdateBagMountIcon then
            Module.UpdateBagMountIcon()
        elseif btn.UpdateUsable then
            btn:UpdateUsable()
        end
    end

    local function InvalidateMountBagCaches()
        InvalidateAllMountItemCaches()
        -- Do not clear Module._cachedMounts here — journal usable list is independent of bag items.
        -- Journal events call InvalidateCollectedMountCache / clear _cachedMounts explicitly.
    end

    local function RunFullMountBagUpdate()
        mountFullUpdatePending = false
        if not Module._registered then return end
        if InCombatLockdown() then
            Module._pendingUpdate = true
            return
        end
        if mountFullUpdateInvalidate then
            InvalidateMountBagCaches()
            mountFullUpdateInvalidate = false
        end
        Module._bagMountNeedsFullRefresh = true
        Module.Update()
    end

    local function ScheduleFullMountBagUpdate(invalidateCaches)
        if invalidateCaches then
            mountFullUpdateInvalidate = true
        end
        if mountFullUpdatePending then
            return
        end
        mountFullUpdatePending = true
        if C_Timer and C_Timer.After then
            C_Timer.After(0.25, RunFullMountBagUpdate)
        else
            RunFullMountBagUpdate()
        end
    end

    local function NeedsMountIdentityRefresh()
        if not Module._registered then return false end
        local canDisplay = Module.CanDisplayMountButton()
        if Module._isPlaceholder and canDisplay then
            return true
        end
        if not Module._isPlaceholder and not canDisplay then
            return true
        end
        return false
    end

    local function NeedsMountSlotRefresh(ctx)
        if not ctx or ctx.changeKind ~= "none" or not ctx.dirtyBags then
            return false
        end
        if HasMountUI() then
            return false
        end
        return next(ctx.dirtyBags) ~= nil
    end

    local function OnBagChangeInstant(ctx)
        if not Module._registered then return end
        local countOnly = ctx and ctx.changeKind == "countOnly" and not ctx.force
        local slotLayout = NeedsMountSlotRefresh(ctx)
        if NeedsMountIdentityRefresh() or slotLayout then
            if InCombatLockdown() then
                Module._pendingUpdate = true
                return
            end
            ScheduleFullMountBagUpdate(true)
            return
        end
        RefreshCountOnly()
        if countOnly then
            return
        end
        if InCombatLockdown() then
            Module._pendingUpdate = true
            return
        end
        ScheduleFullMountBagUpdate(true)
    end

    local function FullMountBagUpdate()
        if not Module._registered then return end
        ScheduleFullMountBagUpdate(true)
    end

    FluxBagChangeDispatcher.RegisterCountListener("NCMount_instant", OnBagChangeInstant)
    FluxBagChangeDispatcher.RegisterScanListener("NCMount", function(ctx)
        if not Module._registered then return end
        if FluxBagChangeDispatcher.OnBagChangeForCombatModule then
            FluxBagChangeDispatcher.OnBagChangeForCombatModule(
                FullMountBagUpdate, RefreshCountOnly, ctx)
        else
            FullMountBagUpdate()
        end
    end, { tier = "scan" })
end

-- ============================================================================
-- BAG MOUNT FLYOUT (delegates to MountItems.lua — sole owner of bag scan + fav map)
-- ============================================================================

function Module.GetMountItemId(mountName)
    if FluxNCMountItems and FluxNCMountItems.GetMountItemId then
        return FluxNCMountItems.GetMountItemId(mountName)
    end
    return nil
end

--- @param includeAllIgnoringZoneFilter boolean|nil
function Module.GetBagMountItems(includeAllIgnoringZoneFilter)
    if FluxNCMountItems and FluxNCMountItems.GetBagMountItems then
        return FluxNCMountItems.GetBagMountItems(includeAllIgnoringZoneFilter)
    end
    return {}
end

function Module.BuildMountItemFlyoutActions()
    if FluxNCMountItems and FluxNCMountItems.BuildMountItemFlyoutActions then
        return FluxNCMountItems.BuildMountItemFlyoutActions()
    end
    return {}
end

function Module.OnMountPickedFromFlyout(actionData)
    if FluxNCMountItems and FluxNCMountItems.OnMountPickedFromFlyout then
        return FluxNCMountItems.OnMountPickedFromFlyout(actionData)
    end
end

function Module.ShowMountItemFlyout()
    if FluxNCMountItems and FluxNCMountItems.ShowMountItemFlyout then
        return FluxNCMountItems.ShowMountItemFlyout()
    end
end

function Module.RefreshFlyoutIfOpen()
    if FluxNCMountItems and FluxNCMountItems.RefreshFlyoutIfOpen then
        return FluxNCMountItems.RefreshFlyoutIfOpen()
    end
end

function Module.RegisterForFavorites()
    local btn = Module._button
    if not btn or not btn.Widget then return end
    if HasMountUI() then return end
    btn.Widget.FluxFlyoutCategory = "Mount"
    btn.Widget.FluxGridFlyoutOwner = true
    if FluxFlyoutFavorites and FluxFlyoutFavorites.RegisterButton then
        FluxFlyoutFavorites.RegisterButton(btn.Widget, "Mount", { itemType = "item" })
    end
end

local MOUNT_PRIORITY_ORDER = { "nomod", "shift", "ctrl", "alt", "ctrl+shift", "shift+alt", "ctrl+alt", "ctrl+shift+alt" }

function Module.GetBagMountItemsSet()
    if FluxNCMountItems and FluxNCMountItems.GetBagMountItemsSet then
        return FluxNCMountItems.GetBagMountItemsSet()
    end
    return {}
end

function Module.GetBestAvailableMount(requestedModKey)
    if FluxNCMountItems and FluxNCMountItems.GetBestAvailableMount then
        return FluxNCMountItems.GetBestAvailableMount(requestedModKey)
    end
    return nil
end

function Module.GetAvailableFavorites()
    if FluxNCMountItems and FluxNCMountItems.GetAvailableFavorites then
        return FluxNCMountItems.GetAvailableFavorites()
    end
    return {}
end

function Module.GetFavoriteMount()
    if FluxNCMountItems and FluxNCMountItems.GetFavoriteMount then
        return FluxNCMountItems.GetFavoriteMount()
    end
    return Module.GetBestAvailableMount()
end


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
-- Returns ordered list of { mod, itemId, name } for modifiers with available favorites
function Module.BuildModifierActions()
    local actions = {}
    local items = Module.GetBagMountItems()
    if #items == 0 then return actions end
    
    local inBagsSet = Module.GetBagMountItemsSet()
    if not FluxFlyoutFavorites then return actions end

    -- Mirror ResolveBest / bag icon: outside flyable zones do not bake flying
    -- favorites into [mod:shift] etc. (holding a mod through teleport would cast
    -- an unusable flyer).
    local preferGround = true
    if Module.IsFlyableHere then
        preferGround = not Module.IsFlyableHere()
    elseif FluxNCMountItems and FluxNCMountItems.IsFlyableHere then
        preferGround = not FluxNCMountItems.IsFlyableHere()
    end
    local function isFlyingId(itemId)
        if Module.IsMountFlying then
            return Module.IsMountFlying(itemId)
        end
        if FluxNCMountItems and FluxNCMountItems.IsMountFlying then
            return FluxNCMountItems.IsMountFlying(itemId)
        end
        return false
    end
    
    -- Modifier order for macro conditionals (complex to simple, so they don't shadow each other)
    local modOrder = { "ctrl+shift+alt", "ctrl+shift", "ctrl+alt", "shift+alt", "alt", "ctrl", "shift" }
    
    for _, modKey in ipairs(modOrder) do
        local favId = FluxFlyoutFavorites.GetFavorite("Mount", modKey)
        if favId and inBagsSet[favId] then
            if preferGround and isFlyingId(favId) then
                -- skip flying fav outside flyable areas
            else
                local item = inBagsSet[favId]
                local name = item["$name"] or select(1, GetItemInfo(favId))
                if name then
                    table.insert(actions, {
                        mod = modKey,
                        itemId = favId,
                        name = name,
                    })
                end
            end
        end
    end
    
    return actions
end

-- Build conditional macro for bag mount items
-- Macro format:
--   #showtooltip [mod:shift] item:123; [mod:ctrl] item:456; item:789
--   /flyout item mounts
--   /stopmacro [btn:2]
--   /use [mod:shift] item:123; [mod:ctrl] item:456; item:789
function Module.BuildBagMountMacro()
    local items = Module.GetBagMountItems()
    if #items == 0 then
        -- Dungeon / instance: keep binding a bag mount item (greyed if unusable).
        items = Module.GetBagMountItems(true) or {}
    end
    if #items == 0 then return nil end
    
    -- Single mount case: simple direct use, no flyout needed
    if #items == 1 then
        local firstItem = items[1]
        local itemId = firstItem["$itemId"]
        local itemName = firstItem["$name"] or ""
        if itemId then
            return string.format([[#showtooltip item:%d
/use item:%d]], itemId, itemId)
        elseif itemName ~= "" then
            return string.format([[#showtooltip %s
/use %s]], itemName, itemName)
        end
        return nil
    end
    
    -- Multiple mounts: build conditional macro with flyout
    local useParts = {}
    
    -- Get modifier actions (favorites that are in bags)
    local modActions = Module.BuildModifierActions()
    
    -- Add modifier-conditioned parts for /use only (NOT for #showtooltip)
    -- We handle icon display ourselves via UpdateBagMountIcon()
    for _, action in ipairs(modActions) do
        local modCond = FormatModString(action.mod)
        if modCond then
            -- Use item ID for reliable resolution
            table.insert(useParts, string.format("[%s] item:%d", modCond, action.itemId))
        end
    end
    
    -- Add default (nomod with priority fallback)
    local defaultMount = Module.GetBestAvailableMount("nomod")
    local tooltipItem = nil  -- Always use nomod mount for #showtooltip
    local preferGround = true
    if Module.IsFlyableHere then
        preferGround = not Module.IsFlyableHere()
    elseif FluxNCMountItems and FluxNCMountItems.IsFlyableHere then
        preferGround = not FluxNCMountItems.IsFlyableHere()
    end

    local function isFlyingId(itemId)
        if Module.IsMountFlying then
            return Module.IsMountFlying(itemId)
        end
        if FluxNCMountItems and FluxNCMountItems.IsMountFlying then
            return FluxNCMountItems.IsMountFlying(itemId)
        end
        return false
    end

    if defaultMount and defaultMount.itemId then
        if preferGround and isFlyingId(defaultMount.itemId) then
            -- Flyer-only bags: still use the flyer so the button is not emptied.
            -- Prefer ground when a non-flyer exists (handled below if we clear here
            -- only after finding a ground candidate).
            local hasGround = false
            for i = 1, #items do
                local id = items[i] and items[i]["$itemId"]
                if id and not isFlyingId(id) then
                    hasGround = true
                    break
                end
            end
            if hasGround then
                defaultMount = nil
            else
                tooltipItem = string.format("item:%d", defaultMount.itemId)
                table.insert(useParts, string.format("item:%d", defaultMount.itemId))
            end
        else
            tooltipItem = string.format("item:%d", defaultMount.itemId)
            table.insert(useParts, string.format("item:%d", defaultMount.itemId))
        end
    end
    if not tooltipItem then
        -- Prefer non-flying outside flyable zones; fall back to any mount.
        local fallbackAny = nil
        for i = 1, #items do
            local candidate = items[i]
            local id = candidate and candidate["$itemId"]
            if id and not (preferGround and isFlyingId(id)) then
                tooltipItem = string.format("item:%d", id)
                table.insert(useParts, string.format("item:%d", id))
                break
            elseif id and not fallbackAny then
                fallbackAny = id
            elseif candidate and candidate["$name"] and not id then
                tooltipItem = candidate["$name"]
                table.insert(useParts, candidate["$name"])
                break
            end
        end
        if not tooltipItem and fallbackAny then
            tooltipItem = string.format("item:%d", fallbackAny)
            table.insert(useParts, string.format("item:%d", fallbackAny))
        end
    end
    
    if #useParts == 0 or not tooltipItem then return nil end
    
    local useStr = table.concat(useParts, "; ")
    
    -- Build full macro:
    -- - #showtooltip with NO conditionals (always nomod mount) - we handle icon via UpdateBagMountIcon()
    -- - /flyout [btn:2] item mounts (ONLY opens flyout on right-click)
    -- - /stopmacro [btn:2] (right-click only opens flyout, doesn't cast)
    -- - /use with conditionals (left-click casts the correct mount based on modifiers)
    return string.format([[#showtooltip %s
/flyout [btn:2] item mounts
/stopmacro [btn:2]
/use %s]], tooltipItem, useStr)
end

-- Hook button icon to prevent external TEXTURE changes (not usability)
-- This prevents macro evaluation from changing our modifier-based icon
local function SetupIconProtection(btn)
    if not btn or not btn.WIcon then return end
    if btn.WIcon._fluxMountIconHooked then return end
    
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
    
    btn.WIcon._fluxMountIconHooked = true
end

-- Expose for internal use
Module.SetupIconProtection = SetupIconProtection

-- Set icon with protection (marks that we're setting it)
SetProtectedIcon = function(btn, icon, skipUsable)
    if not btn or not btn.WIcon then return end
    
    _lastSetIcon = icon
    _iconManagedByModule = true
    
    -- Update cached texture
    Module._currentTexture = icon
    btn.Texture = icon
    
    -- Set on all icon elements
    btn.WIcon:SetTexture(icon)
    btn.WIcon:SetDesaturated(false)
    btn.WIcon:Show()
    
    if btn.Widget and btn.Widget.icon then
        btn.Widget.icon:SetTexture(icon)
    end
    if btn.Widget and btn.Widget.Icon then
        btn.Widget.Icon:SetTexture(icon)
    end

    -- Icon-only path skips UpdateUsable (avoids re-resolving mounts on every mod tick)
    if not skipUsable and btn.UpdateUsable then
        btn:UpdateUsable()
    end
end

local function ApplyBagMountItemTint(btn, itemId)
    if not btn then return end
    if itemId then
        btn._fluxManagedFaceItemId = itemId
        btn.ItemId = itemId
        btn.MacroMode = "item"
        btn._fluxManagedFaceSpellId = nil
        btn.SpellId = nil
        btn.MountSpellId = nil
        btn.MountId = nil
    end
    PaintMountLiveFace(btn)
end

-- Light journal/companion icon update for held modifiers (no FullRefresh / bag scan)
function Module.UpdateJournalMountIcon(forceModKey)
    local btn = Module._button
    if not btn or not btn.WIcon then return end
    if not HasMountUI() then return end
    if Module._isPlaceholder then return end
    if Module._isLocked then return end
    if InCombatLockdown() then return end
    if Module._isCasting or Module._pendingLockMount then return end

    local modKey = forceModKey or GetCurrentHeldModKey()
    local _, mountIcon = Module.GetMountForCurrentModifiers(modKey)
    if not mountIcon then
        mountIcon = "Interface\\Icons\\Ability_Mount_RidingHorse"
    end
    SetProtectedIcon(btn, mountIcon, true)
    if btn.WIcon then
        btn.WIcon:SetVertexColor(1, 1, 1)
    end
end

-- Update mount button icon based on current modifier state
function Module.UpdateBagMountIcon(forceModKey)
    local btn = Module._button
    if not btn or not btn.WIcon then return end
    if HasMountUI() then return end  -- Only for legacy clients
    if Module._isPlaceholder then return end
    if Module._isLocked then return end  -- Don't change icon when locked
    
    -- Get current modifier key (or use forced value)
    local modKey = forceModKey
    if not modKey then
        modKey = "nomod"
        local shiftDown = IsShiftKeyDown and IsShiftKeyDown()
        local ctrlDown = IsControlKeyDown and IsControlKeyDown()
        local altDown = IsAltKeyDown and IsAltKeyDown()
        
        if ctrlDown and shiftDown and altDown then
            modKey = "ctrl+shift+alt"
        elseif ctrlDown and shiftDown then
            modKey = "ctrl+shift"
        elseif ctrlDown and altDown then
            modKey = "ctrl+alt"
        elseif shiftDown and altDown then
            modKey = "shift+alt"
        elseif shiftDown then
            modKey = "shift"
        elseif ctrlDown then
            modKey = "ctrl"
        elseif altDown then
            modKey = "alt"
        end
    end
    
    -- Lookup-only: MountItems precomputes modKey→favorite from cached bag list
    local mount = Module.GetBestAvailableMount(modKey)
    if mount and mount.itemId then
        Module._lastResolvedBagMount = mount
        RememberGoodBagMount(mount, nil)
    elseif Module._lastGoodBagMount then
        -- Brief resolve miss after teleport: keep last known icon.
        mount = Module._lastGoodBagMount
        Module._lastResolvedBagMount = mount
    else
        Module._lastResolvedBagMount = mount
    end
    
    local icon = nil
    if mount then
        icon = mount.icon
        if not icon and mount.name then
            icon = GetMountIcon(mount.name)
        end
        if not icon and mount.itemId then
            icon = GetItemIcon(mount.itemId)
        end
    end
    
    if not icon then
        icon = "Interface\\Icons\\Ability_Mount_Charger"
    end
    
    SetProtectedIcon(btn, icon, true)
    ApplyBagMountItemTint(btn, mount and mount.itemId)
end

-- Shared modifier tracker (demand-driven OnUpdate via FluxModifierTracker)
local function CheckModifierState()
    local currentState = GetModifierState()

    if tooltipShowing and Module._button and Module._button.Widget then
        if currentState ~= lastModifierState then
            lastModifierState = currentState
            ShowMountTooltip(Module._button.Widget)
        end
    end

    -- Freeze icon while combat / hard-lock / casting / pending click→cast
    if InCombatLockdown() then return end
    if Module._isLocked or Module._isPlaceholder then return end
    if Module._isCasting then return end
    if Module._pendingLockMount then return end
    if not Module._button or not Module._button.WIcon then return end

    -- Bag mounts: while location is settling after teleport/load, ignore held
    -- modifiers (shift held through loading screens breaks resolve/icon).
    if not HasMountUI() and IsBagMountLocationSettling() then
        if lastBagMountIconModState ~= "__settle_nomod__" then
            lastBagMountIconModState = "__settle_nomod__"
            Module.UpdateBagMountIcon("nomod")
        end
        return
    end

    if currentState ~= lastBagMountIconModState then
        lastBagMountIconModState = currentState
        if HasMountUI() then
            -- Journal/companion: light texture swap from name map (no FullRefresh)
            Module.UpdateJournalMountIcon(GetCurrentHeldModKey())
        else
            Module.UpdateBagMountIcon()
        end
    end
end

local function MountModifierIsActive()
    if tooltipShowing then return true end
    if InCombatLockdown() then return false end
    if Module._isLocked or Module._isPlaceholder then return false end
    if Module._isCasting then return false end
    if Module._pendingLockMount then return false end
    if not Module._button or not Module._button.WIcon then return false end
    return true
end

if FluxModifierTracker and FluxModifierTracker.Register then
    FluxModifierTracker.Register("NCMount", CheckModifierState, {
        isActive = MountModifierIsActive,
    })
end

-- Update mount macro for bag mount items (with left-click use and flyout support)
function Module.SetupBagMountButton()
    local btn = Module._button
    if not btn or not btn.Widget then return end
    
    -- Only for clients without mount journal
    if HasMountUI() then return end
    
    -- If button is in placeholder state, don't try to set action
    if Module._isPlaceholder then return end
    
    -- Check if we have any bag mount items
    local items = Module.GetBagMountItems()
    if #items == 0 then
        items = Module.GetBagMountItems(true) or {}
    end
    if #items == 0 then
        -- Load screen / bag flicker: keep last successful macro+icon.
        if Module._lastGoodBagMountMacro and ShouldHoldMountIdentity() then
            Module._lastBagMountMacro = Module._lastGoodBagMountMacro
            RefreshBagMountIconForLocation({ forceNomod = true })
            return
        end
        ClearGoodBagMount()
        Module._lastBagMountMacro = nil
        return
    end
    
    local mountCount = #items
    
    -- Register for favorites (enables right-click favorite setting in flyout)
    Module.RegisterForFavorites()
    
    -- Build the conditional macro
    local macro = Module.BuildBagMountMacro()
    
    -- Only set action if we have a valid, complete macro
    if macro and macro ~= "" and macro ~= "#showtooltip" and macro:find("/use") then
        local macroChanged = (Module._lastBagMountMacro ~= macro)
        if macroChanged then
            Module._lastBagMountMacro = macro
            Module._bagMountNeedsFullRefresh = true
            if btn.SetAction then
                btn:SetAction("macrotext", macro)
            end
            if btn.Widget and not InCombatLockdown() then
                btn.Widget:SetAttribute("type", "macro")
                btn.Widget:SetAttribute("macrotext", macro)
            end
            SetupIconProtection(btn)
        end

        RememberGoodBagMount(Module.GetBestAvailableMount and Module.GetBestAvailableMount("nomod"), macro)

        -- Settle / post-load: nomod icon; otherwise live modifiers.
        RefreshBagMountIconForLocation()
    else
        -- Resolve failed briefly: keep last good macro instead of blanking.
        if Module._lastGoodBagMountMacro then
            Module._lastBagMountMacro = Module._lastGoodBagMountMacro
            RefreshBagMountIconForLocation()
            return
        end
        Module._lastBagMountMacro = nil
        return
    end
    
    -- Handle flyout setup based on visible mount options
    local hasFlyout
    if Module.HasMountItemFlyout then
        hasFlyout = Module.HasMountItemFlyout()
    else
        hasFlyout = mountCount > 1
    end
    if hasFlyout then
        if not InCombatLockdown() then
            btn.Widget:SetAttribute("type2", "macro")
            btn.Widget:SetAttribute("macrotext2", (FluxMacroClickProxies and FluxMacroClickProxies.MACRO_MOUNT_ITEM_FLYOUT) or "/click FluxMacroProxy_MountItemFlyout")
        end
        if FluxGridFlyout and FluxGridFlyout.BindRightClickFlyout then
            FluxGridFlyout.BindRightClickFlyout(btn.Widget, Module.ShowMountItemFlyout, { hookKey = "_fluxMountItemRCFlyout" })
        end
        
        if FluxFlyoutFrame and FluxFlyoutFrame.ShowArrow then
            FluxFlyoutFrame.ShowArrow(btn.Widget, "UP")
        end
    else
        if not InCombatLockdown() then
            btn.Widget:SetAttribute("type2", nil)
            btn.Widget:SetAttribute("macrotext2", nil)
        end
        
        if FluxFlyoutFrame and FluxFlyoutFrame.HideArrow then
            FluxFlyoutFrame.HideArrow(btn.Widget)
        end
        if FluxFlyoutFrame and FluxFlyoutFrame.IsFlyoutOpenFor and FluxFlyoutFrame.IsFlyoutOpenFor(btn.Widget) then
            FluxFlyoutFrame.CloseFlyoutFor(btn.Widget)
        end
    end
end

-- Listen for favorites changes to update button
-- Use delayed registration since FluxFlyoutFavorites loads after Mount.lua
local function RegisterFavoritesListener()
    if not FluxFlyoutFavorites or not FluxFlyoutFavorites.RegisterListener then
        return false
    end
    
    FluxFlyoutFavorites.RegisterListener(function(category)
        if category == "Mount" then
            if FluxNCMountItems and FluxNCMountItems.InvalidateFavoriteMap then
                FluxNCMountItems.InvalidateFavoriteMap()
            end
            -- Update macro when mount favorite changes
            if not HasMountUI() then
                local btn = Module._button
                if btn and btn.Widget and not InCombatLockdown() and not Module._isPlaceholder then
                    Module._lastBagMountMacro = nil
                    local macro = Module.BuildBagMountMacro()
                    
                    if macro and macro:find("/use") then
                        Module._lastBagMountMacro = macro
                        btn.Widget:SetAttribute("type", "macro")
                        btn.Widget:SetAttribute("macrotext", macro)
                    end
                    
                    lastBagMountIconModState = ""
                    Module.UpdateBagMountIcon(GetCurrentHeldModKey())
                    
                    Module.RefreshTooltip()
                end
            end
        end
    end)
    return true
end

-- Try to register immediately, then retry with delays
if not RegisterFavoritesListener() then
    -- FluxFlyoutFavorites not loaded yet, wait and retry
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
-- EXPORT
-- ============================================================================

-- Export OpenMountUI function so it can be called from macros
Module.OpenMountUI = OpenMountUI

_G.FluxNCMount = Module

-- ============================================================================
-- DEBUG SLASH COMMAND
-- ============================================================================

SLASH_FLUXMOUNTDEBUG1 = "/fluxmount"
SlashCmdList["FLUXMOUNTDEBUG"] = function(msg)
    print("|cff00ffff[FluxNCMount]|r Debug Info:")
    print("  HasMountUI: " .. tostring(HasMountUI()))
    print("  HasMountJournalAPI: " .. tostring(HasMountJournalAPI()))
    print("  HasCompanionAPI: " .. tostring(HasCompanionAPI()))
    print("  HasAnyMount: " .. tostring(Module.HasAnyMount()))
    print("  HasRidingSkill: " .. tostring(Module.HasRidingSkill()))
    print("  IsPlaceholder: " .. tostring(Module._isPlaceholder))
    print("  Button exists: " .. tostring(Module._button ~= nil))
    
    -- Check FLUX_API flags
    if FLUX_API then
        print("  FLUX_API.isClassicEra: " .. tostring(FLUX_API.isClassicEra))
        print("  FLUX_API.isTBC: " .. tostring(FLUX_API.isTBC))
        print("  FLUX_API.majorVersion: " .. tostring(FLUX_API.majorVersion))
    else
        print("  FLUX_API: nil")
    end
    
    -- Check bag mount items
    if FluxItemDetection then
        local items = FluxItemDetection.ScanBagsForAllMountItems and FluxItemDetection.ScanBagsForAllMountItems()
        if items then
            print("  Bag mount items found: " .. #items)
            for i, item in ipairs(items) do
                print("    " .. i .. ": " .. (item.name or "?") .. " (ID: " .. (item.itemId or "?") .. ")")
            end
        else
            print("  Bag mount items: none or scan skipped")
        end
        
        local singleMount = FluxItemDetection.ScanBagsForMountItems and FluxItemDetection.ScanBagsForMountItems()
        if singleMount then
            print("  ScanBagsForMountItems: " .. (singleMount.name or "?"))
        else
            print("  ScanBagsForMountItems: nil")
        end
    else
        print("  FluxItemDetection: nil")
    end
    
    -- Force update
    if msg == "update" then
        print("  Forcing update...")
        InvalidateAllMountItemCaches()
        Module._cachedMounts = nil
        Module._lastBagMountMacro = nil
        Module._bagMountNeedsFullRefresh = true
        Module.Update()
        print("  Update complete")
    end
end

