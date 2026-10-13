--[[
    ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua
    Teleport/Portal preset button module
    
    Features:
    - Class-agnostic: detects teleport/portal spells by name, not by player class
    - Middle-click: Toggle between Teleport and Portal modes (if both types learned)
    - Right-click: Cast favorite spell for current modifier
    - Left-click: Open flyout with all known spells of current mode
    - Synced favorites: Teleport: X favorites sync with Portal: X
    - Cast locking: Button locks to casting spell during cast (like Mount button)
    - Column priority: 1, Order: 3
    
    Supported spell types:
    - Mage: Teleport: *, Portal: *
    - Monk: Zen Pilgrimage, Zen Pilgrimage: Return
    - Druid: Dreamwalk, Teleport: Moonglade
    - Death Knight: Death Gate
    - Shaman: Astral Recall
    - Warlock: Demonic Gateway, Ritual of Summoning
    
    Compatible with all WoW versions via FluxAPICompat.lua
]]

-- Create namespace
FluxNCTeleportPortal = FluxNCTeleportPortal or {}
local Module = FluxNCTeleportPortal

local function GetBagItemCount(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return 0
    end
    local Flux = _G.Flux
    local api = Flux and Flux.Inventory
    if api and api.GetCount then
        return api.GetCount(itemId, { bags = true, bank = false, warband = false }) or 0
    end
    local inv = _G.FluxInv
    if inv and inv.GetCount then
        return inv.GetCount(itemId) or 0
    end
    if inv and inv.Bags and inv.Bags.GetCount then
        return inv.Bags.GetCount(itemId) or 0
    end
    return 0
end

-- Constants
Module.MODE_TELEPORT = "Teleport"
Module.MODE_PORTAL = "Portal"
Module.COLUMN_PRIORITY = 1
Module.ORDER = 3

-- Mage city teleport / portal reagents (flyout rows + tooltip scan; IDs resolved live)

-- Mage "Teleport: Stormwind"–style icon when there is no class teleport/portal (binding placeholder only)
local NO_CLASS_TELEPORT_PLACEHOLDER_SPELL_ID = 3561
local NO_CLASS_TELEPORT_ICON_FALLBACK = "Interface\\Icons\\Spell_Arcane_TeleportStormwind"

local function GetNoClassTeleportPlaceholderIcon()
    if C_Spell and C_Spell.GetSpellTexture then
        local t = C_Spell.GetSpellTexture(NO_CLASS_TELEPORT_PLACEHOLDER_SPELL_ID)
        if t and t ~= "" then return t end
    end
    if GetSpellTexture then
        local t = GetSpellTexture(NO_CLASS_TELEPORT_PLACEHOLDER_SPELL_ID)
        if t and t ~= "" then return t end
    end
    return NO_CLASS_TELEPORT_ICON_FALLBACK
end

-- Desaturated + dark gray (FluxButton:SetPlaceholder uses 0.25; we go slightly darker for a flatter "empty slot" read)
local NO_CLASS_TP_PLACEHOLDER_R, NO_CLASS_TP_PLACEHOLDER_G, NO_CLASS_TP_PLACEHOLDER_B = 0.2, 0.2, 0.22

-- State
Module._grid = nil
Module._button = nil
Module._registered = false
Module._mode = Module.MODE_TELEPORT

-- Lock state (for sticky spell feature, like Mount button)
Module._lockedSpell = nil    -- { name, icon, spellID }
Module._isLocked = false
Module._isCasting = false
Module._pendingLockSpell = nil
Module._pendingUnlock = false
Module._castLockSpellId = nil

-- Cache (separate clocks so a teleport scan cannot freeze an empty portal list)
Module._knownTeleportSpells = nil
Module._knownPortalSpells = nil
Module._teleportCacheTime = 0
Module._portalCacheTime = 0
Module._cacheTime = 0
local CACHE_DURATION = 5  -- seconds

local function ShouldHoldItemIdentity()
    local B = _G.FluxEBSConsumableBridge
    if B and B.ShouldHoldItemIdentity then
        return B.ShouldHoldItemIdentity() and true or false
    end
    local Best = _G.FluxConsumableBest
    if Best and Best.ShouldSoftHoldOwned then
        return Best.ShouldSoftHoldOwned() and true or false
    end
    return false
end

-- True only while CreateButton runs for binding-mode placeholder (no spells known)
Module._creatingForBindingPlaceholder = false

-- Modifier tracking state for live icon updates
local lastModifierState = ""

-- Icon protection state (prevents external code from changing our icon)
local _iconManagedByModule = false
local _lastSetIcon = nil

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

-- ============================================================================
-- SPELL DATABASE (Class-agnostic - all possible teleport/portal spells)
-- ============================================================================

-- Teleport-type spells (personal teleportation)
local TELEPORT_SPELL_NAMES = {
    -- Mage Teleports (Alliance)
    "Teleport: Stormwind",
    "Teleport: Ironforge",
    "Teleport: Darnassus",
    "Teleport: Exodar",
    "Teleport: Theramore",
    "Teleport: Boralus",
    -- Mage Teleports (Horde)
    "Teleport: Orgrimmar",
    "Teleport: Undercity",
    "Teleport: Thunder Bluff",
    "Teleport: Silvermoon",
    "Teleport: Stonard",
    "Teleport: Dazar'alor",
    -- Mage Teleports (Neutral/Both)
    "Teleport: Shattrath",
    "Teleport: Dalaran",
    "Teleport: Dalaran - Northrend",
    "Teleport: Dalaran - Broken Isles",
    "Teleport: Tol Barad",
    "Teleport: Vale of Eternal Blossoms",
    "Teleport: Warspear",
    "Teleport: Stormshield",
    "Teleport: Hall of the Guardian",
    "Teleport: Valdrakken",
    "Teleport: Oribos",
    "Teleport: Dornogal",
    -- Monk
    "Zen Pilgrimage",
    "Zen Pilgrimage: Return",
    -- Druid
    "Dreamwalk",
    "Teleport: Moonglade",
    -- Death Knight
    "Death Gate",
    -- Shaman
    "Astral Recall",
    -- Demon Hunter
    "Return to the Black Temple",
    -- Warlock (utility)
    "Demonic Circle: Teleport",
}

-- Portal-type spells (group teleportation / summoning)
local PORTAL_SPELL_NAMES = {
    -- Mage Portals (Alliance)
    "Portal: Stormwind",
    "Portal: Ironforge",
    "Portal: Darnassus",
    "Portal: Exodar",
    "Portal: Theramore",
    "Portal: Boralus",
    -- Mage Portals (Horde)
    "Portal: Orgrimmar",
    "Portal: Undercity",
    "Portal: Thunder Bluff",
    "Portal: Silvermoon",
    "Portal: Stonard",
    "Portal: Dazar'alor",
    -- Mage Portals (Neutral/Both)
    "Portal: Shattrath",
    "Portal: Dalaran",
    "Portal: Dalaran - Northrend",
    "Portal: Dalaran - Broken Isles",
    "Portal: Tol Barad",
    "Portal: Vale of Eternal Blossoms",
    "Portal: Warspear",
    "Portal: Stormshield",
    "Portal: Valdrakken",
    "Portal: Oribos",
    "Portal: Dornogal",
    -- Warlock
    "Ritual of Summoning",
    "Portal of Summoning",
}

-- ============================================================================
-- SPELL INFO HELPERS
-- ============================================================================

-- Reusable hidden tooltip for spell scanning
local SpellTooltipScanner = nil
local function EnsureSpellTooltipScanner()
    if SpellTooltipScanner then return SpellTooltipScanner end
    local tip = CreateFrame("GameTooltip", "FluxNCTeleportPortalSpellScanner", UIParent, "GameTooltipTemplate")
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    SpellTooltipScanner = tip
    return tip
end

local RUNE_OF_TELEPORTATION = 17031
local RUNE_OF_PORTAL = 17032

-- Bag items whose counts this button shows. A pulse that moves none of them
-- skips the reagent refresh, which tooltip-scans every known teleport spell.
local reagentItemIDs = { [RUNE_OF_TELEPORTATION] = true, [RUNE_OF_PORTAL] = true }

local function NoteReagentItemID(itemId)
    itemId = tonumber(itemId)
    if itemId then
        reagentItemIDs[itemId] = true
    end
end

local function AnyReagentMoved(changedItemIDs)
    for itemId in pairs(changedItemIDs) do
        if reagentItemIDs[itemId] then
            return true
        end
    end
    return false
end

local function TooltipLineText(fontString)
    if not fontString or not fontString.GetText then
        return nil
    end
    local raw = fontString:GetText()
    local S = _G.Flux and _G.Flux.Secrets
    if S and S.SafeAccessibleString then
        local text = S.SafeAccessibleString(raw)
        if type(text) == "string" then
            return text
        end
        return nil
    end
    if S and S.CanAccessValue and raw ~= nil and not S.CanAccessValue(raw) then
        return nil
    end
    if type(raw) ~= "string" then
        return nil
    end
    return raw
end

-- Check if a spell requires reagents by scanning its tooltip
local function SpellRequiresReagentsFromTooltip(spellId)
    if not spellId then return false end

    local tip = EnsureSpellTooltipScanner()
    tip:ClearLines()

    local success = pcall(function()
        tip:SetSpellByID(spellId)
    end)

    if not success then return true end

    -- Scan tooltip lines for reagent mentions
    local numLines = tip:NumLines() or 0
    local sawSecret = false
    for i = 1, numLines do
        local left = _G["FluxNCTeleportPortalSpellScannerTextLeft" .. i]
        if left then
            local line = TooltipLineText(left)
            if not line then
                sawSecret = true
            else
                local lowerLine = string.lower(line)
                if lowerLine:find("rune of teleportation", 1, true) or
                   lowerLine:find("rune of portal", 1, true) then
                    return true
                end
            end
        end
    end

    -- Midnight: tooltip bodies are secret. Fail closed so the count still shows.
    return sawSecret
end

-- Get reagent item IDs that are required for spells in a given mode (tooltip names → live resolve).
local function ResolveReagentNameToItemID(itemName)
    if not itemName or itemName == "" then
        return nil
    end
    if C_Item and C_Item.GetItemInfoByName then
        local id = tonumber(C_Item.GetItemInfoByName(itemName))
        if id then
            return id
        end
    end
    if GetItemInfo then
        local _, link = GetItemInfo(itemName)
        if link then
            local id = tonumber(link:match("item:(%d+)"))
            if id then
                return id
            end
        end
    end
    if GetMerchantNumItems and GetMerchantItemLink then
        local lower = itemName:lower()
        for i = 1, GetMerchantNumItems() or 0 do
            local name = GetMerchantItemInfo and GetMerchantItemInfo(i)
            if name and name:lower() == lower then
                local link = GetMerchantItemLink(i)
                local id = link and tonumber(link:match("item:(%d+)"))
                if id then
                    return id
                end
            end
        end
    end
    return nil
end

local function GetRequiredReagentsForMode(mode)
    local spells = (mode == Module.MODE_TELEPORT) and Module.GetKnownTeleportSpells() or Module.GetKnownPortalSpells()
    local requiredReagents = {}

    for _, spell in ipairs(spells) do
        if spell.spellID and SpellRequiresReagentsFromTooltip(spell.spellID) then
            local tip = EnsureSpellTooltipScanner()
            tip:ClearLines()
            pcall(function() tip:SetSpellByID(spell.spellID) end)

            local numLines = tip:NumLines() or 0
            local reagentLabel = (REAGENTS or "Reagents"):lower()
            local sawSecret = false
            for i = 1, numLines do
                local left = _G["FluxNCTeleportPortalSpellScannerTextLeft" .. i]
                if left then
                    local line = TooltipLineText(left)
                    if not line then
                        sawSecret = true
                    else
                        local lowerLine = string.lower(line)
                        local itemID = tonumber(line:match("item:(%d+)"))
                        if itemID then
                            local name = line:match("%[(.-)%]") or line
                            requiredReagents[itemID] = name
                        elseif lowerLine:find(reagentLabel, 1, true) or lowerLine:find("rune of", 1, true) then
                            local itemsPart = line:gsub("^[Rr]eagents?[:%s]*", "")
                            itemsPart = itemsPart:match("^%d+%s+(.+)$") or itemsPart
                            itemsPart = itemsPart:match("^%s*(.-)%s*$") or itemsPart
                            if itemsPart ~= "" then
                                local id = ResolveReagentNameToItemID(itemsPart)
                                if id then
                                    requiredReagents[id] = itemsPart
                                end
                            end
                        end
                    end
                end
            end
            if sawSecret then
                if mode == Module.MODE_TELEPORT then
                    requiredReagents[RUNE_OF_TELEPORTATION] = requiredReagents[RUNE_OF_TELEPORTATION] or "Rune of Teleportation"
                else
                    requiredReagents[RUNE_OF_PORTAL] = requiredReagents[RUNE_OF_PORTAL] or "Rune of Portals"
                end
            end
        end
    end

    return requiredReagents
end

--- Tooltip: leading quantity for a reagent line (e.g. "1 Rune of Teleportation").
local function GetReagentCastCountFromSpellTooltip(spellId)
    if not spellId then
        return nil
    end
    local tip = EnsureSpellTooltipScanner()
    tip:ClearLines()
    if not pcall(function()
        tip:SetSpellByID(spellId)
    end) then
        return nil
    end
    local numLines = tip:NumLines() or 0
    for i = 1, numLines do
        local left = _G["FluxNCTeleportPortalSpellScannerTextLeft" .. i]
        if left then
            local line = TooltipLineText(left)
            if line then
                local lower = string.lower(line)
                if lower:find("rune of", 1, true) or lower:find("reagent", 1, true) then
                    local n = line:match("^(%d+)%s")
                    if n then
                        return tonumber(n)
                    end
                    if lower:find("rune of", 1, true) then
                        return 1
                    end
                end
            end
        end
    end
    return nil
end

--- Plain multi-line summary for FluxUI options (Vendor & restock tab).
function Module.GetVendorOptionReagentSummary()
    local lines = {}
    local hasTP = Module.HasAnyTeleportSpell and Module.HasAnyTeleportSpell()
    local hasPo = Module.HasAnyPortalSpell and Module.HasAnyPortalSpell()
    if not hasTP and not hasPo then
        return "No class Teleport: or Portal: spells detected on this character."
    end

    local function appendMode(title, modeKey)
        local spells = modeKey == Module.MODE_TELEPORT and (Module.GetKnownTeleportSpells() or {})
            or (Module.GetKnownPortalSpells() or {})
        if #spells == 0 then
            lines[#lines + 1] = title .. ": (no spells known)"
            return
        end
        local reagents = GetRequiredReagentsForMode(modeKey)
        if not reagents or not next(reagents) then
            lines[#lines + 1] = title .. ": no reagent items (retail / no rune cost on tooltip)."
            return
        end
        local perCast = nil
        for _, sp in ipairs(spells) do
            if sp.spellID and SpellRequiresReagentsFromTooltip(sp.spellID) then
                perCast = GetReagentCastCountFromSpellTooltip(sp.spellID) or 1
                break
            end
        end
        perCast = perCast or 1
        for itemId, fallbackName in pairs(reagents) do
            local disp = fallbackName
            if C_Item and C_Item.GetItemInfo then
                local nm = C_Item.GetItemInfo(itemId)
                if nm then
                    disp = nm
                end
            elseif GetItemInfo then
                local nm = GetItemInfo(itemId)
                if nm then
                    disp = nm
                end
            end
            lines[#lines + 1] = string.format(
                "%s: %d × %s (item %d) per cast",
                title,
                perCast,
                disp,
                itemId
            )
        end
    end

    appendMode("Teleport", Module.MODE_TELEPORT)
    appendMode("Portal", Module.MODE_PORTAL)

    return table.concat(lines, "\n")
end


local function GetSpellInfoCompat(spellNameOrId)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellNameOrId)
        if info then
            return info.name, nil, info.iconID, nil, nil, nil, info.spellID
        end
        return nil
    end
    if GetSpellInfo then
        return GetSpellInfo(spellNameOrId)
    end
    return nil
end

local function IsSpellKnownCompat(spellId)
    if not spellId then return false end
    
    -- Try IsSpellKnown first
    if IsSpellKnown and IsSpellKnown(spellId) then
        return true
    end
    
    -- Try IsPlayerSpell
    if IsPlayerSpell and IsPlayerSpell(spellId) then
        return true
    end
    
    -- Fallback: check if we can get spell info for it
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellId)
        if info and info.spellID then
            -- Additional check: try to see if it's castable
            if C_Spell.IsSpellUsable then
                local usable = C_Spell.IsSpellUsable(spellId)
                return usable ~= nil  -- If we get any result, spell exists for player
            end
            return true
        end
    end
    
    return false
end

local function GetSpellIdByName(spellName)
    if not spellName then return nil end
    
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellName)
        if info and info.spellID then
            return info.spellID
        end
    end
    
    if GetSpellInfo then
        local _, _, _, _, _, _, spellId = GetSpellInfo(spellName)
        return spellId
    end
    
    return nil
end

local function GetSpellTexture(spellIdOrName)
    local API = _G.FluxAPICompat and FluxAPICompat.API
    if API and API.GetSpellDisplayTexture then
        local t = API.GetSpellDisplayTexture(spellIdOrName)
        if t ~= nil and t ~= "" then
            return t
        end
    end
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellIdOrName)
    end
    if GetSpellTexture then
        return _G.GetSpellTexture(spellIdOrName)
    end
    -- Fallback: try GetSpellInfo
    local _, _, icon = GetSpellInfoCompat(spellIdOrName)
    return icon
end

-- ============================================================================
-- SPELL DETECTION (Class-Agnostic)
-- ============================================================================

-- Get all known teleport spells
function Module.GetKnownTeleportSpells()
    local now = GetTime()
    if Module._knownTeleportSpells and (now - (Module._teleportCacheTime or 0)) < CACHE_DURATION then
        if #Module._knownTeleportSpells > 0 then
            return Module._knownTeleportSpells
        end
        if ShouldHoldItemIdentity() and Module._lastGoodTeleportSpells and #Module._lastGoodTeleportSpells > 0 then
            return Module._lastGoodTeleportSpells
        end
        return Module._knownTeleportSpells
    end
    
    local known = {}
    for _, spellName in ipairs(TELEPORT_SPELL_NAMES) do
        local spellId = GetSpellIdByName(spellName)
        if spellId and IsSpellKnownCompat(spellId) then
            local name, _, iconFromInfo = GetSpellInfoCompat(spellId)
            if name then
                table.insert(known, {
                    name = name,
                    spellID = spellId,
                    -- Do not use iconFromInfo alone: flyout-contained spells often use a truthy "?" fileID.
                    icon = GetSpellTexture(spellId) or iconFromInfo,
                })
            end
        end
    end
    
    Module._knownTeleportSpells = known
    Module._teleportCacheTime = now
    Module._cacheTime = now
    if #known > 0 then
        Module._lastGoodTeleportSpells = known
    elseif ShouldHoldItemIdentity() and Module._lastGoodTeleportSpells and #Module._lastGoodTeleportSpells > 0 then
        Module._knownTeleportSpells = Module._lastGoodTeleportSpells
        return Module._lastGoodTeleportSpells
    end
    return known
end

-- Get all known portal spells
function Module.GetKnownPortalSpells()
    local now = GetTime()
    if Module._knownPortalSpells and (now - (Module._portalCacheTime or 0)) < CACHE_DURATION then
        if #Module._knownPortalSpells > 0 then
            return Module._knownPortalSpells
        end
        if ShouldHoldItemIdentity() and Module._lastGoodPortalSpells and #Module._lastGoodPortalSpells > 0 then
            return Module._lastGoodPortalSpells
        end
        return Module._knownPortalSpells
    end
    
    local known = {}
    for _, spellName in ipairs(PORTAL_SPELL_NAMES) do
        local spellId = GetSpellIdByName(spellName)
        if spellId and IsSpellKnownCompat(spellId) then
            local name, _, iconFromInfo = GetSpellInfoCompat(spellId)
            if name then
                table.insert(known, {
                    name = name,
                    spellID = spellId,
                    icon = GetSpellTexture(spellId) or iconFromInfo,
                })
            end
        end
    end
    
    Module._knownPortalSpells = known
    Module._portalCacheTime = now
    if #known > 0 then
        Module._lastGoodPortalSpells = known
    elseif ShouldHoldItemIdentity() and Module._lastGoodPortalSpells and #Module._lastGoodPortalSpells > 0 then
        Module._knownPortalSpells = Module._lastGoodPortalSpells
        return Module._lastGoodPortalSpells
    end
    return known
end

-- Check if player has ANY teleport spell
function Module.HasAnyTeleportSpell()
    local known = Module.GetKnownTeleportSpells()
    return known and #known > 0
end

-- Check if player has ANY portal spell
function Module.HasAnyPortalSpell()
    local known = Module.GetKnownPortalSpells()
    return known and #known > 0
end

-- Check if player has any teleport OR portal spell (button visibility)
function Module.HasAnyTeleportOrPortalSpell()
    local has = Module.HasAnyTeleportSpell() or Module.HasAnyPortalSpell()
    if has then
        Module._lastGoodHasSpells = true
        return true
    end
    local B = _G.FluxEBSConsumableBridge
    if Module._lastGoodHasSpells and B and B.ShouldHoldItemIdentity and B.ShouldHoldItemIdentity() then
        return true
    end
    return false
end

-- Invalidate spell cache (call when spells change)
function Module.InvalidateCache()
    Module._knownTeleportSpells = nil
    Module._knownPortalSpells = nil
    Module._teleportCacheTime = 0
    Module._portalCacheTime = 0
    Module._cacheTime = 0
end

-- Get the first known spell for a mode (fallback)
function Module.GetFirstKnownSpell(mode)
    local spells
    if mode == Module.MODE_TELEPORT then
        spells = Module.GetKnownTeleportSpells()
    else
        spells = Module.GetKnownPortalSpells()
    end
    
    if spells and #spells > 0 then
        return spells[1]
    end
    return nil
end

-- ============================================================================
-- MODE MANAGEMENT
-- ============================================================================

-- Get current mode from saved variables
function Module.GetMode()
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
            if FluxNonCombatGridDB[charKey] and FluxNonCombatGridDB[charKey].teleportPortal then
                local savedMode = FluxNonCombatGridDB[charKey].teleportPortal.mode
                if savedMode == Module.MODE_TELEPORT or savedMode == Module.MODE_PORTAL then
                    return savedMode
                end
            end
        end
    end
    return Module._mode
end

-- Set current mode in saved variables
function Module.SetMode(mode)
    if mode ~= Module.MODE_TELEPORT and mode ~= Module.MODE_PORTAL then
        return
    end
    
    Module._mode = mode
    
    -- Save to DB
    FluxNonCombatGridDB = FluxNonCombatGridDB or {}
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
        FluxNonCombatGridDB[charKey] = FluxNonCombatGridDB[charKey] or {}
        FluxNonCombatGridDB[charKey].teleportPortal = FluxNonCombatGridDB[charKey].teleportPortal or {}
        FluxNonCombatGridDB[charKey].teleportPortal.mode = mode
    end
end

-- Toggle between Teleport and Portal modes
function Module.ToggleMode()
    if InCombatLockdown() then return end
    -- OnMouseDown plus type3 /click (or a leftover up-click) must not flip twice.
    local now = (GetTime and GetTime()) or 0
    if Module._toggleAt and (now - Module._toggleAt) < 0.35 then
        return
    end
    Module._toggleAt = now

    -- Only allow toggle if both types are learned
    local hasTeleport = Module.HasAnyTeleportSpell()
    local hasPortal = Module.HasAnyPortalSpell()

    if not (hasTeleport and hasPortal) then
        -- Can't toggle - only one type exists
        return
    end

    local current = Module.GetMode()
    local newMode = (current == Module.MODE_TELEPORT) and Module.MODE_PORTAL or Module.MODE_TELEPORT

    Module.SetMode(newMode)
    Module.InvalidateCache()
    Module.Update()
    Module.ClearCheckedVisual()

    -- Refresh flyout if it's currently open
    Module.RefreshFlyoutIfOpen()

    -- Refresh tooltip if it's currently shown
    Module.RefreshTooltip()

    -- Ensure reagent displays are updated after mode change (in case saved vars weren't loaded)
    Timer.After(0.2, function()
        if FluxFlyoutFrame and FluxFlyoutFrame.GetActiveFlyout then
            local activeFlyout = FluxFlyoutFrame.GetActiveFlyout()
            if activeFlyout and activeFlyout.buttons then
                for _, btn in ipairs(activeFlyout.buttons) do
                    if btn.actionData and btn.actionData["$isReagent"] then
                        local itemId = btn.actionData["$reagentItemId"] or btn.actionData["$itemId"]
                        if itemId then
                            Module.UpdateReagentButtonDisplay(btn, itemId)
                        end
                    end
                end
            end
        end
    end)
end

-- CheckButton C++ still toggles checked on middle/right. Extra gold hilight
-- would stick after a mode toggle that is not a cast.
function Module.ClearCheckedVisual()
    local btn = Module._button
    local w = btn and btn.Widget
    if not w then
        return
    end
    if btn then
        btn._lastChecked = false
    end
    w._fluxPaintChecked = false
    w._fluxCheckedApplied = false
    local Flux = _G.Flux
    local ov = Flux and Flux.ButtonFX and Flux.ButtonFX.Overlay
    if ov and ov.ApplyChecked then
        ov.ApplyChecked(w, false)
    elseif w.SetChecked then
        w._fluxCheckedFromPaint = true
        w:SetChecked(false)
        w._fluxCheckedFromPaint = nil
    end
    local ct = w.GetCheckedTexture and w:GetCheckedTexture()
    if ct and ct.Hide then
        pcall(ct.Hide, ct)
    end
    if w._fluxGoldChecked and w._fluxGoldChecked.Hide then
        pcall(w._fluxGoldChecked.Hide, w._fluxGoldChecked)
    end
    if w.SetButtonState then
        pcall(w.SetButtonState, w, "NORMAL")
    end
    if Timer.After then
        Timer.After(0, Module.ClearCheckedVisualNow)
        Timer.After(0.05, Module.ClearCheckedVisualNow)
    end
end

function Module.ClearCheckedVisualNow()
    if Module._isCasting or Module._isLocked or Module._pendingLockSpell then
        return
    end
    local btn = Module._button
    local w = btn and btn.Widget
    if not w then
        return
    end
    if btn then
        btn._lastChecked = false
    end
    w._fluxPaintChecked = false
    w._fluxCheckedApplied = false
    local Flux = _G.Flux
    local ov = Flux and Flux.ButtonFX and Flux.ButtonFX.Overlay
    if ov and ov.ApplyChecked then
        ov.ApplyChecked(w, false)
    elseif w.SetChecked then
        w._fluxCheckedFromPaint = true
        w:SetChecked(false)
        w._fluxCheckedFromPaint = nil
    end
    local ct = w.GetCheckedTexture and w:GetCheckedTexture()
    if ct and ct.Hide then
        pcall(ct.Hide, ct)
    end
    if w._fluxGoldChecked and w._fluxGoldChecked.Hide then
        pcall(w._fluxGoldChecked.Hide, w._fluxGoldChecked)
    end
end

-- Refresh the flyout if it's currently open (e.g., after mode toggle)
function Module.RefreshFlyoutIfOpen()
    Module.SyncFlyoutEngine()
    Module.HookFlyoutButtons()
    if Timer.After then
        Timer.After(0.1, function()
            Module.RefreshAllReagentDisplays()
        end)
    end
end

-- ============================================================================
-- MODIFIER KEY HELPERS (Need to be defined before Lock system uses them)
-- ============================================================================

-- Helper: Get current modifier state as string (for comparison)
local function GetModifierState()
    local state = ""
    if IsShiftKeyDown and IsShiftKeyDown() then state = state .. "S" end
    if IsControlKeyDown and IsControlKeyDown() then state = state .. "C" end
    if IsAltKeyDown and IsAltKeyDown() then state = state .. "A" end
    return state
end

-- Helper: Get current held modifier key string (for favorites lookup)
local function GetCurrentHeldModKey()
    local tokens = {}
    if IsControlKeyDown and IsControlKeyDown() then table.insert(tokens, "ctrl") end
    if IsShiftKeyDown and IsShiftKeyDown() then table.insert(tokens, "shift") end
    if IsAltKeyDown and IsAltKeyDown() then table.insert(tokens, "alt") end
    if #tokens == 0 then return "nomod" end
    return table.concat(tokens, "+")
end

-- ============================================================================
-- LOCK SYSTEM (Like Mount button - locks during cast)
-- ============================================================================

-- Lock the button to a specific spell
function Module.LockToSpell(spellName, spellIcon, spellID)
    if not spellName then return end
    
    -- Get icon if not provided
    if not spellIcon and spellID then
        spellIcon = GetSpellTexture(spellID)
    end
    
    Module._lockedSpell = {
        name = spellName,
        icon = spellIcon,
        spellID = spellID,
    }
    Module._isLocked = true
    Module._pendingLockSpell = nil
    SetCastLockSpellId(spellID)
    
    -- Extra Cast/Paint follow this id; keep it on the locked spell for the fill.
    local btn = Module._button
    if btn and spellID then
        btn._fluxManagedFaceSpellId = spellID
        btn.SpellId = spellID
        btn.MacroMode = "spell"
        if spellIcon then
            btn.IconOverrideTexture = spellIcon
            btn.MacroTexture = spellIcon
        end
    end
    
    -- Disable icon protection while locked (lock system manages icon)
    -- This allows WoW's built-in systems to update cooldowns, etc.
    _iconManagedByModule = false
    
    -- Update button immediately
    if not InCombatLockdown() then
        Module.UpdateLockedState()
    end
end

-- Unlock the button
function Module.Unlock()
    if not Module._isLocked then return end
    
    local btn = Module._button
    
    Module._lockedSpell = nil
    Module._isLocked = false
    Module._isCasting = false
    Module._pendingLockSpell = nil
    Module._pendingUnlock = false
    ClearCastLockSpellId()
    
    -- Clear cached texture (prevent old icon from being restored)
    Module._currentTexture = nil
    _lastSetIcon = nil
    
    -- Reset tracking state
    lastModifierState = ""
    
    -- Hide any overlay glow that was shown during lock
    if btn and btn.Widget then
        -- Try ActionButton overlay glow (Retail)
        if ActionButton_HideOverlayGlow then
            pcall(ActionButton_HideOverlayGlow, btn.Widget)
        end
        
        -- Try LibButtonGlow if available
        if LibStub then
            local LBG = LibStub("LibButtonGlow-1.0", true)
            if LBG and LBG.HideOverlayGlow then
                pcall(LBG.HideOverlayGlow, btn.Widget)
            end
        end
    end
    
    -- Update button immediately
    if not InCombatLockdown() then
        Module.Update()
        -- Re-enable icon protection and set icon based on current modifiers
        _iconManagedByModule = true
        local currentModKey = GetCurrentHeldModKey()
        Module.UpdateIcon(currentModKey)
    end
end

-- Check if locked
function Module.IsLocked()
    return Module._isLocked and Module._lockedSpell ~= nil
end

-- Update button to reflect locked state
function Module.UpdateLockedState()
    local btn = Module._button
    if not btn or not Module._isLocked or not Module._lockedSpell then return end
    if InCombatLockdown() then return end
    
    local spellName = Module._lockedSpell.name
    local spellIcon = Module._lockedSpell.icon
    local spellID = Module._lockedSpell.spellID
    
    -- Get icon if not provided
    if not spellIcon and spellID then
        spellIcon = GetSpellTexture(spellID)
    end
    -- Keep Extra SpellCastAnimFrame: this runs at UNIT_SPELLCAST_START.
    
    -- Update macro to cast locked spell directly
    local lockedMacro = string.format([[#showtooltip %s
/cast %s]], spellName, spellName)
    
    if btn.SetAction then
        btn:SetAction("macrotext", lockedMacro)
    elseif btn.Widget then
        btn.Widget:SetAttribute("type", "macro")
        btn.Widget:SetAttribute("macrotext", lockedMacro)
    end
    Module.SetupClickHandlers(btn)
    if spellID then
        btn._fluxManagedFaceSpellId = spellID
        btn.SpellId = spellID
        btn.MacroMode = "spell"
        if spellIcon then
            btn.IconOverrideTexture = spellIcon
            btn.MacroTexture = spellIcon
        end
    end
    
    -- Update texture (bypass protection during lock)
    if spellIcon then
        -- Store for reference
        Module._currentTexture = spellIcon
        _lastSetIcon = spellIcon
        
        -- Update main icon
        if btn.WIcon then
            -- Temporarily disable protection to set icon
            local savedManaged = _iconManagedByModule
            _iconManagedByModule = false
            
            btn.WIcon:SetTexture(spellIcon)
            btn.WIcon:SetDesaturated(false)
            btn.WIcon:SetVertexColor(1, 1, 1, 1)
            btn.WIcon:Show()
            
            _iconManagedByModule = savedManaged
        end
        
        -- Update widget icons
        if btn.Widget then
            if btn.Widget.icon then
                btn.Widget.icon:SetTexture(spellIcon)
                btn.Widget.icon:Show()
            end
            if btn.Widget.Icon then
                btn.Widget.Icon:SetTexture(spellIcon)
                btn.Widget.Icon:Show()
            end
        end
        
        -- Update btn.Texture property for consistency
        btn.Texture = spellIcon
    end
    
    -- Update spell VFX/overlay if available (for clients that support it)
    -- This shows the spell activation glow when applicable
    if spellID and btn.Widget then
        -- Try ActionButton overlay glow (Retail)
        if ActionButton_ShowOverlayGlow and btn.Widget.ShowOverlayGlow then
            -- Check if spell has an active proc
            if IsSpellOverlayed and IsSpellOverlayed(spellID) then
                ActionButton_ShowOverlayGlow(btn.Widget)
            end
        end
        
        -- Try LibButtonGlow if available (for addons that use it)
        if LibStub then
            local LBG = LibStub("LibButtonGlow-1.0", true)
            if LBG and LBG.ShowOverlayGlow then
                if IsSpellOverlayed and IsSpellOverlayed(spellID) then
                    LBG.ShowOverlayGlow(btn.Widget)
                end
            end
        end
    end
end

-- ============================================================================
-- FLYOUT SYSTEM
-- ============================================================================

-- Build reagent actions for current mode
function Module.BuildReagentActions(mode)
    mode = mode or Module.GetMode()

    local reagentActions = {}
    local seenReagents = {}  -- Avoid duplicates

    -- Always prefer spells in *this* mode (teleport vs portal); never use the
    -- global spellbook reagent list here — that shows every reagent on the character.
    local requiredReagents = GetRequiredReagentsForMode(mode)

    -- If tooltip name→ID could not resolve yet, ask FluxInv for reagents on this mode's spells.
    if not next(requiredReagents) then
        local spells = (mode == Module.MODE_TELEPORT) and Module.GetKnownTeleportSpells() or Module.GetKnownPortalSpells()
        local S = _G.FluxInv and _G.FluxInv.Spells
        if S and S.GetReagents and type(spells) == "table" then
            for _, spell in ipairs(spells) do
                local list = spell.spellID and S.GetReagents(spell.spellID)
                if type(list) == "table" then
                    for i = 1, #list do
                        local r = list[i]
                        local id = r and tonumber(r.itemID)
                        if id then
                            requiredReagents[id] = r.name or GetItemInfo(id) or ("item:" .. id)
                        end
                    end
                end
            end
        end
    end

    for itemId, reagentName in pairs(requiredReagents) do
        if not seenReagents[itemId] then
            seenReagents[itemId] = true

            -- Get current count and restock target
            local currentCount = GetBagItemCount(itemId)
            local restockTarget = Module.GetRestockTarget(itemId)

            -- Create action with item count display
            local displayName = string.format("%s (%d / %d)", reagentName, currentCount, restockTarget)

            -- Get unit price for tooltip calculation
            local unitPrice = 0
            if FluxRestock and FluxRestock.GetItemUnitPrice then
                unitPrice = FluxRestock.GetItemUnitPrice(itemId)
            end

            table.insert(reagentActions, {
                ["type"] = "item",
                ["item"] = "item:" .. tostring(itemId),
                ["$itemId"] = itemId,
                ["$name"] = displayName,
                ["$iconTexture"] = GetItemIcon(itemId) or "Interface\\Icons\\INV_Misc_QuestionMark",
                ["$isReagent"] = true,  -- Mark as reagent for special handling
                ["$currentCount"] = currentCount,
                ["$targetCount"] = restockTarget,
                ["$itemPrice"] = unitPrice,
                ["$reagentItemId"] = itemId,  -- Store for edit box functionality
            })
        end
    end

    return reagentActions
end

-- Restock targets live in FluxRestock (via FluxVendorAuto), not the wiped
-- legacy _FluxUI_CharSavedVars.VendorAuto store.
function Module.GetRestockTarget(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        return 0
    end
    local FV = _G.FluxVendorAuto
    if FV and FV.GetRestockTargetForItem then
        return FV.GetRestockTargetForItem(itemId) or 0
    end
    local FR = _G.FluxRestock
    if FR and FR.GetTargetQuantity then
        return FR.GetTargetQuantity(itemId) or 0
    end
    return 0
end

function Module.SetRestockTarget(itemId, targetQuantity)
    itemId = tonumber(itemId)
    if not itemId then
        return
    end
    targetQuantity = math.max(0, math.min(999, tonumber(targetQuantity) or 0))
    local FV = _G.FluxVendorAuto
    if FV and FV.SetRestockTarget then
        FV.SetRestockTarget(itemId, targetQuantity)
    elseif _G.FluxRestock and _G.FluxRestock.SetTargetQuantity then
        _G.FluxRestock.SetTargetQuantity(itemId, targetQuantity)
    end
    if Module.RefreshAllReagentDisplays then
        pcall(Module.RefreshAllReagentDisplays)
    end
end

-- Update reagent button display with current count/target
function Module.UpdateReagentButtonDisplay(button, itemId)
    if not button or not itemId then return end

    local currentCount = GetBagItemCount(itemId)
    local restockTarget = Module.GetRestockTarget(itemId)

    -- Update button's action data for display
    if button.actionData then
        local displayName = string.format("%s (%d / %d)", GetItemInfo(itemId) or ("Item " .. itemId), currentCount, restockTarget)
        button.actionData["$name"] = displayName
        button.actionData["$currentCount"] = currentCount
        button.actionData["$targetCount"] = restockTarget
    end
    if button._fluxFlyoutDef then
        button._fluxFlyoutDef.currentCount = currentCount
        button._fluxFlyoutDef.targetCount = restockTarget
    end

    Module.UpdateReagentButtonCountText(button, currentCount, restockTarget)
end

-- Update reagent button count text display
function Module.UpdateReagentButtonCountText(button, currentCount, targetCount)
    if not button then return end

    local countText = button.Count or button.countText or button.WCount
        or (button.GetName and _G[button:GetName() .. "Count"])
    if button.editBox and button.editBox:IsShown() then
        if countText then
            countText:Hide()
        end
        return
    end
    if countText then
        countText:SetText(string.format("%d/%d", currentCount, targetCount))
        countText:SetTextColor(1, 1, 1, 1)
        countText:Show()
    end
end

-- Show/hide reagent button count text
function Module.ShowReagentButtonCount(button, show)
    if not button then return end

    local countText = button.Count or button.countText or _G[button:GetName() .. "Count"]
    if countText then
        if show then
            countText:Show()
        else
            countText:Hide()
        end
    end
end

-- Build flyout actions for current mode
function Module.BuildFlyoutActions(mode)
    mode = mode or Module.GetMode()
    local spells = (mode == Module.MODE_TELEPORT) and Module.GetKnownTeleportSpells() or Module.GetKnownPortalSpells()

    local spellActions = {}
    for _, spell in ipairs(spells) do
        table.insert(spellActions, {
            ["type"] = "spell",
            ["spell"] = spell.name,
            ["$spellID"] = spell.spellID,
            ["$name"] = spell.name,
            ["$iconTexture"] = spell.icon or GetSpellTexture(spell.spellID),
        })
    end

    -- Sort spells by name first (baseline before ncFlyout hide/order)
    table.sort(spellActions, function(a, b)
        local nameA = a["$name"] or ""
        local nameB = b["$name"] or ""
        return nameA < nameB
    end)

    if FluxNCFlyoutOptions and FluxNCFlyoutOptions.ApplyClassTeleportSpells then
        spellActions = FluxNCFlyoutOptions.ApplyClassTeleportSpells(mode, spellActions)
    end

    local actions = {}
    for _, a in ipairs(spellActions) do
        actions[#actions + 1] = a
    end

    -- Reagents after spells, default order only (not customizable — always last).
    local reagentActions = Module.BuildReagentActions(mode)
    table.sort(reagentActions, function(a, b)
        local na = a["$name"] or ""
        local nb = b["$name"] or ""
        return na < nb
    end)
    for _, reagentAction in ipairs(reagentActions) do
        table.insert(actions, reagentAction)
    end

    return actions
end

--- Visible teleport/portal destinations after hide/order (reagents are not options).
function Module.CountVisibleTeleportDestinations(mode)
    mode = mode or Module.GetMode()
    local actions = Module.BuildFlyoutActions(mode)
    local n = 0
    for i = 1, #(actions or {}) do
        local a = actions[i]
        if a and not a["$isReagent"] then
            n = n + 1
        end
    end
    return n
end

function Module.HasTeleportFlyout(mode)
    return Module.CountVisibleTeleportDestinations(mode) > 1
end

local function ToEngineFlyoutList(actions)
    local list = {}
    for i = 1, #(actions or {}) do
        local src = actions[i]
        if type(src) == "table" then
            local isReagent = src["$isReagent"] and true or false
            local spellId = tonumber(src["$spellID"] or src["$spellId"] or src.spellID)
            local itemId = tonumber(src["$itemId"] or src["$reagentItemId"] or src.itemId)
            local spellName = src["$name"] or src.name
            local spellIcon = src["$iconTexture"] or src.icon
            list[#list + 1] = {
                type = src.type or (spellId and "spell") or (itemId and "item") or "spell",
                spell = spellId or src.spell,
                item = itemId or src.item,
                icon = spellIcon,
                name = spellName,
                skipFavorite = isReagent,
                skipUse = isReagent,
                isReagent = isReagent,
                currentCount = src["$currentCount"],
                targetCount = src["$targetCount"],
                onClick = (not isReagent) and function(_, mouse)
                    if mouse ~= "LeftButton" then
                        return
                    end
                    Module._pendingLockSpell = {
                        name = spellName,
                        icon = spellIcon,
                        spellID = spellId,
                    }
                    Timer.After(1.0, function()
                        if Module._pendingLockSpell
                           and Module._pendingLockSpell.spellID == spellId
                           and not Module._isLocked
                           and not Module._isCasting then
                            Module._pendingLockSpell = nil
                            Module.UpdateIcon(GetCurrentHeldModKey())
                        end
                    end)
                end or nil,
            }
        end
    end
    return list
end

function Module.SyncFlyoutEngine()
    local btn = Module._button
    if not btn or not btn.Widget then
        return
    end
    local Flux = _G.Flux
    local Flyout = Flux and Flux.EBS and Flux.EBS.Flyout
    if not Flyout or not Flyout.SetButtons then
        return
    end
    local mode = Module.GetMode()
    if Flyout.Favorites and Flyout.Favorites.RegisterButton then
        Flyout.Favorites.RegisterButton(btn.Widget, mode)
    end
    if not Module.HasTeleportFlyout(mode) then
        if Flyout.Clear then
            Flyout.Clear(btn.Widget)
        elseif Flyout.Arrow and Flyout.Arrow.Hide then
            Flyout.Arrow.Hide(btn.Widget)
        end
        return
    end
    Flyout.SetButtons(btn.Widget, ToEngineFlyoutList(Module.BuildFlyoutActions(mode)), {
        direction = "UP",
        favoriteCategory = mode,
        classColorArrow = true,
    })
end

-- Show the teleport/portal flyout
function Module.ShowFlyout()
    local btn = Module._button
    if not btn or not btn.Widget then return end
    if InCombatLockdown and InCombatLockdown() then return end

    local now = (GetTime and GetTime()) or 0
    if Module._flyoutToggleAt and (now - Module._flyoutToggleAt) < 0.08 then
        return
    end
    Module._flyoutToggleAt = now

    local mode = Module.GetMode()
    if not Module.HasTeleportFlyout(mode) then
        return
    end
    local actions = Module.BuildFlyoutActions(mode)
    if #actions == 0 then
        return
    end

    Module.SyncFlyoutEngine()

    local Flux = _G.Flux
    local Flyout = Flux and Flux.EBS and Flux.EBS.Flyout
    if Flyout and Flyout.Toggle then
        Flyout.Toggle(btn.Widget)
    elseif FluxFlyoutFrame and FluxFlyoutFrame.ShowFlyout then
        FluxFlyoutFrame.ShowFlyout(btn.Widget, actions, {
            direction = "UP",
            favoriteCategory = mode,
        })
    end

    Module.HookFlyoutButtons()
    Timer.After(0.1, function()
        Module.RefreshAllReagentDisplays()
    end)
end

-- Hook flyout buttons to lock main button when casting from flyout
function Module.HookFlyoutButtons()
    local btn = Module._button
    if not btn or not btn.Widget then return end

    local flyout
    if FluxFlyoutFrame and FluxFlyoutFrame.GetFlyoutForButton then
        flyout = FluxFlyoutFrame.GetFlyoutForButton(btn.Widget)
    end
    local kids = flyout and (flyout.kids or flyout.buttons)
    if not kids then return end

    for _, flyoutBtn in ipairs(kids) do
        if flyoutBtn.IsShown and flyoutBtn:IsShown() then
            local def = flyoutBtn._fluxFlyoutDef
            local itemId = def and (tonumber(def.item) or def.item)
            if def and (def.isReagent or def.skipUse) and itemId then
                flyoutBtn._reagentItemId = itemId
                flyoutBtn._fluxSkipFavorites = true
                Module.UpdateReagentButtonDisplay(flyoutBtn, itemId)
            elseif def then
                flyoutBtn._reagentItemId = nil
                flyoutBtn._fluxSkipFavorites = def.skipFavorite and true or false
            end
        end
    end
end

-- ============================================================================
-- MACRO BUILDING
-- ============================================================================

-- Helper: Convert modifier key string to macro conditional
-- "ctrl+shift" -> "[mod:ctrl,mod:shift]"
local function ModKeyToMacroConditional(key)
    if not key or key == "" or key == "nomod" then return nil end
    local parts = {}
    for token in string.gmatch(key, "[^+]+") do
        token = token:gsub("%s+", "")
        if token == "ctrl" then table.insert(parts, "mod:ctrl") end
        if token == "shift" then table.insert(parts, "mod:shift") end
        if token == "alt" then table.insert(parts, "mod:alt") end
    end
    if #parts == 0 then return nil end
    return "[" .. table.concat(parts, ",") .. "]"
end

-- Build the conditional /cast line with all modifier favorites
-- Returns: "/cast [mod:shift] SpellA; [mod:ctrl] SpellB; SpellC"
function Module.BuildConditionalCastLine(mode)
    mode = mode or Module.GetMode()
    
    -- Modifier order: complex to simple (so they don't shadow each other)
    local modOrder = { "ctrl+shift+alt", "ctrl+shift", "ctrl+alt", "shift+alt", "ctrl", "shift", "alt" }
    local clauses = {}
    local defaultSpellName = nil
    
    -- Get default (nomod) spell first — always a spell of *this* mode
    local nomodSpell = Module.GetSpellForModifier("nomod", mode)
    if nomodSpell then
        defaultSpellName = nomodSpell.name
    end
    
    -- If no nomod favorite, use first known spell
    if not defaultSpellName then
        local firstSpell = Module.GetFirstKnownSpell(mode)
        if firstSpell then
            defaultSpellName = firstSpell.name
        end
    end
    
    -- Build modifier clauses
    if FluxFlyoutFavorites and FluxFlyoutFavorites.GetFavorite then
        for _, modKey in ipairs(modOrder) do
            local favId = FluxFlyoutFavorites.GetFavorite(mode, modKey)
            if favId then
                local spell = Module.GetSpellForModifier(modKey, mode)
                local favName = (spell and spell.name) or GetSpellInfoCompat(favId)
                if favName then
                    local cond = ModKeyToMacroConditional(modKey)
                    if cond then
                        table.insert(clauses, string.format("%s %s", cond, favName))
                    end
                end
            end
        end
    end
    
    -- Add default (no modifier) at the end
    if defaultSpellName then
        table.insert(clauses, defaultSpellName)
    end
    
    if #clauses == 0 then return nil end
    return "/cast " .. table.concat(clauses, "; ")
end

-- Build macro text for the button (LEFT-CLICK action)
-- Behavior (matches Mount button):
-- - Left-click: Cast favorite based on held modifier
-- - Right-click: Open flyout (handled via macrotext2 in SetupRightClick)
-- - Middle-click: Toggle mode (handled via macrotext3 in SetupMiddleClick)
function Module.BuildFlyoutMacro(mode)
    mode = mode or Module.GetMode()
    
    -- Get default spell name (needed for fallback cast line)
    local defaultSpellName = nil
    local nomodSpell = Module.GetSpellForModifier("nomod", mode)
    if nomodSpell then
        defaultSpellName = nomodSpell.name
    end
    
    -- If no favorite, use first known spell
    if not defaultSpellName then
        local firstSpell = Module.GetFirstKnownSpell(mode)
        if firstSpell then
            defaultSpellName = firstSpell.name
        end
    end
    
    if not defaultSpellName then
        return nil
    end
    
    -- Build conditional cast line (includes all modifier favorites)
    local castLine = Module.BuildConditionalCastLine(mode)
    if not castLine then
        castLine = "/cast " .. defaultSpellName
    end
    
    -- Use plain #showtooltip - icon is managed by Module.UpdateIcon()
    -- This allows the icon to change dynamically with modifiers
    return string.format([[#showtooltip
%s]], castLine)
end

-- ============================================================================
-- BUTTON CREATION AND UPDATES
-- ============================================================================

-- Register with a grid
function Module.Register(grid)
    if not grid or Module._registered then return end
    
    Module._grid = grid
    Module._registered = true
    
    -- Only create button if we have any teleport/portal spells
    if Module.HasAnyTeleportOrPortalSpell() then
        Module.CreateButton()
        
        -- Register for favorite changes ONLY if we created the button
        if FluxFlyoutFavorites and FluxFlyoutFavorites.RegisterListener then
            FluxFlyoutFavorites.RegisterListener(function(category)
                if category == "Teleport" or category == "Portal" then
                    Module.Update()
                end
            end)
        end
    end
end

-- Lazily create grid button during LibKeyBound mode when the player has no teleport/portal spells
function Module.EnsureButtonForBindingMode()
    if Module._button or not Module._grid or not Module._registered then return end
    local fbm = _G.FluxBindingMode
    if not (fbm and fbm.ShouldForceShowAllExtraSlots and fbm:ShouldForceShowAllExtraSlots()) then return end
    if Module.HasAnyTeleportOrPortalSpell() then return end
    Module._creatingForBindingPlaceholder = true
    Module.CreateButton()
    if not Module._button and not InCombatLockdown() then
        Module._creatingForBindingPlaceholder = nil
    end
end

-- Create the button
function Module.CreateButton()
    if not Module._grid or Module._button then return end
    if InCombatLockdown() then
        Timer.After(0.5, Module.CreateButton)
        return
    end
    
    -- Don't create if no spells known (unless binding mode is creating a placeholder slot)
    if not Module.HasAnyTeleportOrPortalSpell() and not Module._creatingForBindingPlaceholder then
        return
    end
    
    local grid = Module._grid
    
    -- Determine initial mode based on what's available
    local hasTeleport = Module.HasAnyTeleportSpell()
    local hasPortal = Module.HasAnyPortalSpell()
    
    if hasTeleport and not hasPortal then
        Module.SetMode(Module.MODE_TELEPORT)
    elseif hasPortal and not hasTeleport then
        Module.SetMode(Module.MODE_PORTAL)
    end
    -- If both exist, use saved preference
    
    -- Create button
    local btn = grid:CreateButton({
        columnPriority = Module.COLUMN_PRIORITY,
        columnGroup = "hearthteleport",
        order = Module.ORDER,
        scope = "class",
    })
    
    if not btn then
        Module._creatingForBindingPlaceholder = nil
        return
    end
    
    Module._button = btn
    Module._creatingForBindingPlaceholder = nil
    
    -- DISABLE DEFAULT TOOLTIP - We'll use custom tooltip
    btn.TooltipEnabled = false
    
    -- Mark button for flyout system (on button AND widget)
    btn.IsTeleportPortalButton = true
    btn.FluxGridFlyoutOwner = true
    btn.FluxFlyoutCategory = Module.GetMode()
    
    -- DISABLE DRAG/DROP - Pre-set button (match Food/Water)
    btn.ButtonLocked = true
    if btn.SetLocked then btn:SetLocked(true) end
    if btn.Widget then
        btn.Widget:SetScript("OnDragStart", nil)
        btn.Widget:SetScript("OnReceiveDrag", nil)
        btn.Widget:SetScript("OnDragStop", nil)
        if btn.Widget.RegisterForDrag then
            btn.Widget:RegisterForDrag()
            btn.Widget:SetScript("OnDragStart", nil)
            btn.Widget:SetScript("OnReceiveDrag", nil)
            btn.Widget:SetScript("OnDragStop", nil)
        end
        
        -- Set flyout flags on Widget (required by FluxFlyoutFrame)
        btn.Widget.FluxFlyoutCategory = Module.GetMode()
        btn.Widget.FluxGridFlyoutOwner = true
    end
    
    -- Set up icon protection (prevent macro evaluation from overwriting our icon)
    Module.SetupIconProtection(btn)
    
    -- Set up middle-click toggle
    Module.SetupMiddleClick(btn)
    
    -- Set up right-click favorites
    Module.SetupRightClick(btn)
    
    -- Set up PreClick for lock feature
    Module.SetupPreClick(btn)
    
    -- Set up tooltip
    Module.SetupTooltip(btn)
    
    -- Set column priority and order (CreateButton already applied config; keep in sync if methods exist)
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
    
    -- Set up flyout arrow (show if more than 1 spell)
    Module.UpdateFlyoutArrow()
    Module.SyncFlyoutEngine()
    
    -- Setup keybinding via SetOverrideBindingClick (secure approach, no taint)
    Module.UpdateTeleportKeybinding(btn)
    
    -- Update hotkey text display on button
    Module.UpdateHotkeyText(btn)

    -- Extra Paint owns usable/CD/range/glow. Pin the modifier-facing spell
    -- so macrotext still morphs like Extra slots.
    btn.UpdateUsable = function(self)
        if self.PlaceholderTexture then return end
        
        local heldMod = GetCurrentHeldModKey()
        local activeSpell = Module.GetSpellForModifier(heldMod)
        local spellId = activeSpell and activeSpell.spellID
        if spellId then
            self._fluxManagedFaceSpellId = spellId
            self.SpellId = spellId
            self.MacroMode = "spell"
            self.ItemId = nil
            self._fluxManagedFaceItemId = nil
        end
        local Paint = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint
        if Paint and Paint.UpdateLiveFace then
            Paint.UpdateLiveFace(self)
        elseif Paint then
            if Paint.UpdateCooldown then Paint.UpdateCooldown(self) end
            if Paint.UpdateRange then Paint.UpdateRange(self) end
            if Paint.UpdateUsable then Paint.UpdateUsable(self) end
            if Paint.UpdateGlow then Paint.UpdateGlow(self) end
        end
        if self.UpdateTextCount then
            self:UpdateTextCount()
        end
    end

    local baseUpdateTextCount = btn.UpdateTextCount
    btn.UpdateTextCount = function(self)
        if self.PlaceholderHideCount then
            if self.WCount then
                self.WCount:SetText("")
            end
            return
        end
        if self.MacroMode == "spell" and self.SpellNameRank and baseUpdateTextCount then
            baseUpdateTextCount(self)
            return
        end
        local mode = Module.GetMode()
        local reagents = GetRequiredReagentsForMode(mode)
        if reagents and next(reagents) and self.WCount then
            for itemId in pairs(reagents) do
                NoteReagentItemID(itemId)
                local count = GetBagItemCount(itemId)
                self.WCount:Show()
                self.WCount:SetText(tostring(count))
                return
            end
        end
        if baseUpdateTextCount then
            baseUpdateTextCount(self)
        end
    end

    -- Apply styling + macro after custom usability override is installed
    if FluxNonCombatGrid and FluxNonCombatGrid.ApplyButtonStyle then
        FluxNonCombatGrid.ApplyButtonStyle(btn, "class")
    end
    Module.ApplyMacro(btn)
    
    return btn
end

-- Apply the macro action to the button
function Module.ApplyMacro(btn)
    btn = btn or Module._button
    if not btn then return end
    if InCombatLockdown() then return end
    
    -- If locked, use locked state
    if Module._isLocked and Module._lockedSpell then
        Module.UpdateLockedState()
        return
    end
    
    local mode = Module.GetMode()
    local macro = Module.BuildFlyoutMacro(mode)
    
    if macro then
        -- Force Extra TranslateMacro to re-parse the new teleport/portal body.
        btn.MacroAction = nil
        btn.MacroTexture = nil
        if btn.SetAction then
            btn:SetAction("macrotext", macro)
        elseif btn.Widget then
            btn.Widget:SetAttribute("type", "macro")
            btn.Widget:SetAttribute("macrotext", macro)
        end
    end
    
    -- Update flyout category
    btn.FluxFlyoutCategory = mode
    
    -- Update texture
    Module.UpdateTexture()

    -- SetAction/WriteAttributes rewrite type/typerelease; restore mouse 2/3 after.
    Module.SetupClickHandlers(btn)
end

-- Set up icon protection to prevent external code from changing our icon
-- This is important because we manage the icon ourselves based on modifiers
function Module.SetupIconProtection(btn)
    if not btn or not btn.WIcon then return end
    if btn.WIcon._fluxTeleportIconHooked then return end
    
    -- Store original SetTexture
    local originalSetTexture = btn.WIcon.SetTexture
    
    -- Replace SetTexture with our guarded version
    -- This ONLY protects texture changes when we're managing it
    btn.WIcon.SetTexture = function(self, texture, ...)
        -- Binding / empty placeholder must not be blocked (FluxButton:SetPlaceholder vs. protection)
        if btn.PlaceholderTexture then
            return originalSetTexture(self, texture, ...)
        end
        -- If we're managing the icon and this isn't our call, ignore it
        if _iconManagedByModule and texture ~= _lastSetIcon then
            return
        end
        return originalSetTexture(self, texture, ...)
    end
    
    local function GuardIcon(icon)
        if not icon or not icon.SetTexture or icon._fluxTeleportIconHooked then
            return
        end
        if icon == btn.WIcon then
            return
        end
        local orig = icon.SetTexture
        icon.SetTexture = function(self, texture, ...)
            if btn.PlaceholderTexture then
                return orig(self, texture, ...)
            end
            if _iconManagedByModule and texture ~= _lastSetIcon then
                return
            end
            return orig(self, texture, ...)
        end
        icon._fluxTeleportIconHooked = true
    end
    if btn.Widget then
        GuardIcon(btn.Widget.icon)
        GuardIcon(btn.Widget.Icon)
    end
    
    btn.WIcon._fluxTeleportIconHooked = true
end

-- Right-click opens the flyout; middle-click toggles teleport/portal.
-- type2/type3 swallow those clicks so they do not cast the left-click spell.
function Module.SetupClickHandlers(btn)
    if not btn or not btn.Widget then return end
    if InCombatLockdown() then
        Timer.After(0.2, function() Module.SetupClickHandlers(btn) end)
        return
    end

    local w = btn.Widget
    local hasFlyout = Module.HasTeleportFlyout()

    if hasFlyout then
        w:SetAttribute("type2", "macro")
        w:SetAttribute("macrotext2", "/")
    else
        w:SetAttribute("type2", nil)
        w:SetAttribute("macrotext2", nil)
    end

    if Module.HasAnyTeleportSpell() and Module.HasAnyPortalSpell() then
        local toggleMacro = (FluxMacroClickProxies and FluxMacroClickProxies.MACRO_TELEPORT_TOGGLE_MODE) or "/click FluxMacroProxy_TeleportToggleMode"
        w:SetAttribute("type3", "macro")
        -- pressAndHoldAction mouse-up reads typerelease*, not type*.
        w:SetAttribute("typerelease3", "macro")
        w:SetAttribute("macrotext3", toggleMacro)
    else
        w:SetAttribute("type3", nil)
        w:SetAttribute("typerelease3", nil)
        w:SetAttribute("macrotext3", nil)
    end

    if not w._fluxTeleportMouseHooked then
        w._fluxTeleportMouseHooked = true
        w:HookScript("OnMouseDown", function(_, button)
            if button == "RightButton" then
                if Module.HasTeleportFlyout() then
                    Module.ShowFlyout()
                end
                Module.ClearCheckedVisual()
            elseif button == "MiddleButton" then
                if Module.HasAnyTeleportSpell() and Module.HasAnyPortalSpell() then
                    Module.ToggleMode()
                else
                    Module.ClearCheckedVisual()
                end
            end
        end)
        w:HookScript("PostClick", function(_, button, down)
            if down then
                return
            end
            if button == "MiddleButton" or button == "RightButton" then
                Module.ClearCheckedVisual()
            end
        end)
    end
end

function Module.SetupMiddleClick(btn)
    Module.SetupClickHandlers(btn)
end

function Module.SetupRightClick(btn)
    Module.SetupClickHandlers(btn)
end

-- Set up PreClick hook to capture which spell will be cast (for lock feature)
function Module.SetupPreClick(btn)
    if not btn or not btn.Widget then return end
    if btn.Widget._fluxTeleportPreClickHooked then return end
    btn.Widget._fluxTeleportPreClickHooked = true
    
    btn.Widget:HookScript("PreClick", function(self, button, down)
        -- Only handle left-click casts
        if button ~= "LeftButton" then return end
        
        -- Don't set pending lock if already locked
        if Module._isLocked then return end
        
        -- Determine what spell would be cast
        local mode = Module.GetMode()
        local spellName, spellIcon, spellId
        
        -- Check for favorites with current modifier
        if FluxFlyoutFavorites and FluxFlyoutFavorites.GetFavorite then
            local modKey = "nomod"
            if IsControlKeyDown and IsControlKeyDown() then
                if IsShiftKeyDown and IsShiftKeyDown() then
                    if IsAltKeyDown and IsAltKeyDown() then
                        modKey = "ctrl+shift+alt"
                    else
                        modKey = "ctrl+shift"
                    end
                elseif IsAltKeyDown and IsAltKeyDown() then
                    modKey = "ctrl+alt"
                else
                    modKey = "ctrl"
                end
            elseif IsShiftKeyDown and IsShiftKeyDown() then
                if IsAltKeyDown and IsAltKeyDown() then
                    modKey = "shift+alt"
                else
                    modKey = "shift"
                end
            elseif IsAltKeyDown and IsAltKeyDown() then
                modKey = "alt"
            end
            
            local favId = FluxFlyoutFavorites.GetFavorite(mode, modKey)
            if favId then
                spellName, _, spellIcon = GetSpellInfoCompat(favId)
                spellId = favId
            end
        end
        
        -- Fallback to first spell
        if not spellName then
            local firstSpell = Module.GetFirstKnownSpell(mode)
            if firstSpell then
                spellName = firstSpell.name
                spellIcon = firstSpell.icon
                spellId = firstSpell.spellID
            end
        end
        
        if spellName then
            Module._pendingLockSpell = {
                name = spellName,
                icon = spellIcon,
                spellID = spellId,
            }
            SetCastLockSpellId(spellId)
            
            -- Safety timeout: clear pending lock if cast doesn't start within 1 second
            -- This handles cases where the spell is on cooldown, player is silenced, etc.
            Timer.After(1.0, function()
                -- Only clear if this is still the same pending spell (not already locked or cleared)
                if Module._pendingLockSpell 
                   and Module._pendingLockSpell.name == spellName 
                   and not Module._isLocked 
                   and not Module._isCasting then
                    Module._pendingLockSpell = nil
                    ClearCastLockSpellId()
                    -- Restore icon to current modifier state
                    local currentModKey = GetCurrentHeldModKey()
                    Module.UpdateIcon(currentModKey)
                end
            end)
        end
    end)
end

-- ============================================================================
-- TOOLTIP HELPER FUNCTIONS (must be before tooltip functions that use them)
-- ============================================================================

-- Helper: Get current modifier state as string (for comparison)
local function GetModifierStateForTooltip()
    local state = ""
    if IsShiftKeyDown and IsShiftKeyDown() then state = state .. "S" end
    if IsControlKeyDown and IsControlKeyDown() then state = state .. "C" end
    if IsAltKeyDown and IsAltKeyDown() then state = state .. "A" end
    return state
end

-- Helper: Get current held modifier key string (for favorites lookup)
local function GetCurrentHeldModKeyForTooltip()
    local tokens = {}
    if IsControlKeyDown and IsControlKeyDown() then table.insert(tokens, "ctrl") end
    if IsShiftKeyDown and IsShiftKeyDown() then table.insert(tokens, "shift") end
    if IsAltKeyDown and IsAltKeyDown() then table.insert(tokens, "alt") end
    if #tokens == 0 then return "nomod" end
    return table.concat(tokens, "+")
end

-- Tooltip state tracking
local tooltipShowing = false
local tooltipModState = ""
local tooltipRefreshElapsed = 0
local TOOLTIP_REFRESH_INTERVAL = 0.25

-- Set up tooltip (completely overrides default tooltip)
function Module.SetupTooltip(btn)
    if not btn or not btn.Widget then return end
    
    -- DISABLE DEFAULT TOOLTIP - We use our own custom tooltip
    btn.TooltipEnabled = false
    
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
        tooltipModState = GetModifierStateForTooltip()
        
        local hoverOpts = {
            interval = TOOLTIP_REFRESH_INTERVAL,
            isActive = function() return tooltipShowing end,
            onRefresh = function()
                if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
                    Module.ShowTooltip()
                end
            end,
        }
        if Hover and Hover.BeginGridHover then
            Hover.BeginGridHover(self, function()
                Module.ShowTooltip()
            end, hoverOpts)
        else
            Module.ShowTooltip()
            if Hover and Hover.Start then
                Hover.Start(self, hoverOpts)
            end
        end
    end)
    
    widget:SetScript("OnLeave", function(self)
        tooltipShowing = false
        self:SetScript("OnUpdate", nil)
        if Hover and Hover.EndGridHover then
            Hover.EndGridHover(self, hideGridTooltip)
        else
            if Hover and Hover.Stop then
                Hover.Stop(self)
            end
            hideGridTooltip()
        end
    end)
end

-- Show tooltip (updates dynamically based on held modifiers)
function Module.ShowTooltip()
    local btn = Module._button
    if not btn or not btn.Widget then return end
    
    GameTooltip:SetOwner(btn.Widget, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
    local mode = Module.GetMode()
    local hasTeleport = Module.HasAnyTeleportSpell()
    local hasPortal = Module.HasAnyPortalSpell()
    local hasBoth = hasTeleport and hasPortal
    
    -- Check if locked
    if Module._isLocked and Module._lockedSpell then
        local lockedName = Module._lockedSpell.name
        local lockedIcon = Module._lockedSpell.icon
        
        local iconString = ""
        if lockedIcon then
            iconString = string.format("|T%s:20:20:0:0|t ", lockedIcon)
        end
        GameTooltip:AddLine(iconString .. (lockedName or mode), 0.4, 0.8, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("LOCKED", 1, 0.6, 0)
        GameTooltip:AddLine("Button locked to this spell", 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Casting complete will unlock", 0.7, 0.7, 0.7)
        GameTooltip:Show()
        return
    end
    
    -- Get current held modifier - directly use what's held (no sticky)
    local heldMod = GetCurrentHeldModKeyForTooltip()
    
    -- Get active spell based on currently held modifier
    local activeSpell = Module.GetSpellForModifier(heldMod)
    local activeName = activeSpell and activeSpell.name
    local activeIcon = activeSpell and activeSpell.icon
    
    -- Title: Active spell name with icon (GREEN)
    if activeName then
        local iconString = ""
        if activeIcon then
            iconString = string.format("|T%s:20:20:0:0|t ", activeIcon)
        end
        GameTooltip:AddLine(iconString .. activeName, 0.2, 1, 0.2)
    else
        local titleColor = (mode == Module.MODE_TELEPORT) and {0.4, 0.8, 1.0} or {1.0, 0.6, 0.8}
        GameTooltip:AddLine(mode, titleColor[1], titleColor[2], titleColor[3])
    end
    
    -- Mode info
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Mode: " .. mode, 0.7, 0.7, 0.7)
    
    -- Spell count
    local spells = (mode == Module.MODE_TELEPORT) and Module.GetKnownTeleportSpells() or Module.GetKnownPortalSpells()
    if spells and #spells > 0 then
        GameTooltip:AddLine(string.format("%d destination(s)", #spells), 0.5, 0.8, 1)
    end
    
    -- Modifier bindings section - ONLY show modifiers that have favorites set
    -- All possible modifier combinations (simple first, then combos)
    local modOrder = { 
        "nomod", "shift", "ctrl", "alt",
        "ctrl+shift", "ctrl+alt", "shift+alt", 
        "ctrl+shift+alt" 
    }
    local modLabels = { 
        nomod = "Click", 
        shift = "Shift", 
        ctrl = "Ctrl", 
        alt = "Alt",
        ["ctrl+shift"] = "Ctrl+Shift",
        ["ctrl+alt"] = "Ctrl+Alt",
        ["shift+alt"] = "Shift+Alt",
        ["ctrl+shift+alt"] = "Ctrl+Shift+Alt",
    }
    
    -- First pass: collect only the modifiers that have favorites
    local bindingsToShow = {}
    for _, modKey in ipairs(modOrder) do
        local spell = nil
        if FluxFlyoutFavorites and FluxFlyoutFavorites.GetFavorite then
            local favId = FluxFlyoutFavorites.GetFavorite(mode, modKey)
            if favId then
                local name = GetSpellInfoCompat(favId)
                local icon = GetSpellTexture(favId)
                if name then
                    spell = { name = name, icon = icon }
                    table.insert(bindingsToShow, {
                        modKey = modKey,
                        label = modLabels[modKey] or modKey,
                        spell = spell,
                    })
                end
            end
        end
    end
    
    -- Only show bindings section if there are any favorites set
    if #bindingsToShow > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Modifier Bindings:", 1, 0.82, 0)
        
        for _, binding in ipairs(bindingsToShow) do
            local isActive = (binding.modKey == heldMod)
            local iconStr = binding.spell.icon and string.format("|T%s:14:14:0:0|t ", binding.spell.icon) or ""
            local r, g, b = 0.8, 0.8, 0.8
            if isActive then
                r, g, b = 0.2, 1, 0.2  -- GREEN for active
            end
            GameTooltip:AddLine(string.format("[%s] %s%s", binding.label, iconStr, binding.spell.name), r, g, b)
        end
    end
    
    -- Action hints
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: Cast", 0.5, 0.8, 1)
    if Module.HasTeleportFlyout() then
        GameTooltip:AddLine("Right-click: Open flyout", 0.5, 0.8, 1)
    end
    if hasBoth then
        local label = "Middle-click: Toggle " .. mode .. "/" .. 
            ((mode == Module.MODE_TELEPORT) and Module.MODE_PORTAL or Module.MODE_TELEPORT)
        if FluxNCHotkeyUtil and FluxNCHotkeyUtil.AddTooltipBinding then
            FluxNCHotkeyUtil.AddTooltipBinding(GameTooltip, label, "FLUXMAGE_TOGGLE_TPPT")
        else
            GameTooltip:AddLine(label, 0.5, 0.8, 1)
        end
    end
    
    GameTooltip:Show()
end

-- Refresh tooltip if currently shown
function Module.RefreshTooltip()
    if tooltipShowing and Module._button and Module._button.Widget then
        Module.ShowTooltip()
    end
end

-- ============================================================================
-- ICON AND MODIFIER MANAGEMENT
-- ============================================================================
-- Note: GetModifierState() and GetCurrentHeldModKey() are defined earlier in the file
-- (before the Lock System section) to ensure they're in scope when needed.

-- Get spell for a specific modifier key
function Module.GetSpellForModifier(modKey, mode)
    mode = mode or Module.GetMode()
    modKey = modKey or "nomod"

    local function FindKnown(spellId)
        spellId = tonumber(spellId)
        if not spellId then
            return nil
        end
        local list = (mode == Module.MODE_TELEPORT) and Module.GetKnownTeleportSpells() or Module.GetKnownPortalSpells()
        for i = 1, #(list or {}) do
            local sp = list[i]
            if sp and sp.spellID == spellId then
                return sp
            end
        end
        return nil
    end

    local function DestinationOf(name)
        if type(name) ~= "string" then
            return nil
        end
        return name:match("^Teleport:%s*(.+)$")
            or name:match("^Portal:%s*(.+)$")
            or name:match("^Teleport：%s*(.+)$")
            or name:match("^Portal：%s*(.+)$")
    end

    local function KindOf(name)
        if type(name) ~= "string" then
            return nil
        end
        if name:find("^Teleport:", 1, true) or name:find("^Teleport：", 1, true) then
            return Module.MODE_TELEPORT
        end
        if name:find("^Portal:", 1, true) or name:find("^Portal：", 1, true) then
            return Module.MODE_PORTAL
        end
        return nil
    end

    local function PairIntoMode(spellId)
        local known = FindKnown(spellId)
        if known then
            return known
        end
        spellId = tonumber(spellId)
        if not spellId then
            return nil
        end
        local name = GetSpellInfoCompat(spellId)
        if KindOf(name) == mode then
            local icon = GetSpellTexture(spellId)
            if name then
                return { name = name, spellID = spellId, icon = icon }
            end
        end
        local dest = DestinationOf(name)
        if not dest then
            return nil
        end
        local list = (mode == Module.MODE_TELEPORT) and Module.GetKnownTeleportSpells() or Module.GetKnownPortalSpells()
        for i = 1, #(list or {}) do
            local sp = list[i]
            if sp and DestinationOf(sp.name) == dest then
                return sp
            end
        end
        return nil
    end

    if FluxFlyoutFavorites and FluxFlyoutFavorites.GetFavorite then
        local favId = FluxFlyoutFavorites.GetFavorite(mode, modKey)
        local spell = PairIntoMode(favId)
        if spell then
            return spell
        end
    end

    if modKey ~= "nomod" then
        return Module.GetSpellForModifier("nomod", mode)
    end

    return Module.GetFirstKnownSpell(mode)
end

--- Binding-mode toggle corner: opposite mode's matching destination (Portal:X <-> Teleport:X).
function Module.GetOppositeModeDisplaySpell(forceModKey)
    local mode = Module.GetMode()
    local opposite = (mode == Module.MODE_TELEPORT) and Module.MODE_PORTAL or Module.MODE_TELEPORT
    local modKey = forceModKey or GetCurrentHeldModKey() or "nomod"

    local function SpellFromID(spellID)
        if not spellID then return nil end
        local name = GetSpellInfoCompat(spellID)
        local icon = GetSpellTexture(spellID)
        if name then
            return { name = name, spellID = spellID, icon = icon }
        end
        return nil
    end

    if FluxFlyoutFavorites and FluxFlyoutFavorites.GetFavorite then
        local favId = FluxFlyoutFavorites.GetFavorite(opposite, modKey)
        local s = SpellFromID(favId)
        if s then return s end
        if modKey ~= "nomod" then
            s = SpellFromID(FluxFlyoutFavorites.GetFavorite(opposite, "nomod"))
            if s then return s end
        end
    end

    local current = Module.GetSpellForModifier(modKey)
    if current and current.name then
        local pairedName
        if current.name:find("^Teleport:", 1, true) or current.name:find("^Teleport：", 1, true) then
            pairedName = current.name:gsub("^[Tt]eleport:", "Portal:", 1):gsub("^Teleport：", "Portal：", 1)
        elseif current.name:find("^Portal:", 1, true) or current.name:find("^Portal：", 1, true) then
            pairedName = current.name:gsub("^[Pp]ortal:", "Teleport:", 1):gsub("^Portal：", "Teleport：", 1)
        end
        if pairedName then
            local spellID
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(pairedName)
                spellID = info and info.spellID
            end
            if not spellID and GetSpellInfo then
                spellID = select(7, GetSpellInfo(pairedName)) or nil
            end
            local s = SpellFromID(spellID)
            if s then return s end
            local icon = GetSpellTexture and GetSpellTexture(pairedName)
            if icon then
                return { name = pairedName, spellID = spellID, icon = icon }
            end
        end
    end

    return Module.GetFirstKnownSpell(opposite)
end

-- Set icon with protection (marks that we're setting it)
local function SetProtectedIcon(btn, icon, spell)
    if not btn or not btn.WIcon then return end
    
    _lastSetIcon = icon
    _iconManagedByModule = true
    
    -- Update cached texture
    Module._currentTexture = icon
    btn.Texture = icon
    -- Extra Paint prefers IconOverrideTexture over macro parse (file id or path).
    btn.IconOverrideTexture = icon
    btn._lastIcon = nil
    if spell and spell.spellID then
        btn._fluxManagedFaceSpellId = spell.spellID
        btn.SpellId = spell.spellID
        btn.MacroMode = "spell"
        btn.ItemId = nil
        btn._fluxManagedFaceItemId = nil
        btn.MacroTexture = icon
    else
        btn._fluxManagedFaceSpellId = nil
    end
    
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

    if btn.UpdateUsable then
        btn:UpdateUsable()
    end
end

--- Sync WIcon + LAB icon layers: mage teleport glyph, grayscale, darkened (matches FluxButton placeholder intent).
local function SyncNoClassTeleportPlaceholderIconLayers(btn)
    if not btn then return end
    local tex = btn.PlaceholderTexture or GetNoClassTeleportPlaceholderIcon()
    local r, g, b = NO_CLASS_TP_PLACEHOLDER_R, NO_CLASS_TP_PLACEHOLDER_G, NO_CLASS_TP_PLACEHOLDER_B
    local function styleIcon(region)
        if not region or not region.SetTexture then return end
        region:SetTexture(tex)
        if region.SetDesaturated then
            region:SetDesaturated(true)
        end
        region:SetVertexColor(r, g, b)
        region:Show()
    end
    styleIcon(btn.WIcon)
    if btn.Widget then
        styleIcon(btn.Widget.icon)
        styleIcon(btn.Widget.Icon)
    end
end

local function ApplyBindingModeNoSpellsPlaceholderLook(btn)
    if not btn then return end
    local tex = GetNoClassTeleportPlaceholderIcon()
    -- Hide stack/count like other empty-slot placeholders (FluxButton UpdateTextCount)
    btn.PlaceholderHideCount = true
    -- Placeholder must be applied before ClearAction so FullRefresh never runs the empty-state (hide icon) path first.
    if btn.SetPlaceholder then
        btn:SetPlaceholder(tex, "Class Teleport")
    else
        btn.PlaceholderTexture = tex
        btn.PlaceholderLabel = "Class Teleport"
    end
    SyncNoClassTeleportPlaceholderIconLayers(btn)
    -- Match Food/Water: both SlotFrame and Widget must be shown or the icon layer stays invisible.
    if btn.Widget then
        btn.Widget:Show()
    end
end

-- Update button icon based on current modifier state
function Module.UpdateIcon(forceModKey)
    local btn = Module._button
    if not btn or not btn.WIcon then return end

    -- No spells: only binding-mode placeholder; do not run SetProtectedIcon (full-color fallback)
    if not Module.HasAnyTeleportOrPortalSpell() then
        btn.IconOverrideTexture = nil
        btn._fluxManagedFaceSpellId = nil
        local fbm = _G.FluxBindingMode
        if fbm and fbm.ShouldForceShowAllExtraSlots and fbm:ShouldForceShowAllExtraSlots() then
            ApplyBindingModeNoSpellsPlaceholderLook(btn)
        end
        return
    end
    
    -- If locked, use locked spell icon (don't change during lock)
    if Module._isLocked and Module._lockedSpell and Module._lockedSpell.icon then
        SetProtectedIcon(btn, Module._lockedSpell.icon, Module._lockedSpell)
        return
    end
    
    -- If we have a pending lock spell (just clicked, waiting for cast to start),
    -- show that spell's icon to prevent flickering when modifier is released
    if Module._pendingLockSpell and Module._pendingLockSpell.icon then
        SetProtectedIcon(btn, Module._pendingLockSpell.icon, Module._pendingLockSpell)
        return
    end
    
    -- If casting, don't change icon (shouldn't happen if above checks work)
    if Module._isCasting then return end
    
    -- Get current modifier key (or use forced value)
    local modKey = forceModKey or GetCurrentHeldModKey()
    
    -- Get spell for this modifier
    local spell = Module.GetSpellForModifier(modKey)
    
    local texture = nil
    if spell then
        texture = spell.icon or (spell.spellID and GetSpellTexture(spell.spellID))
    end
    
    -- Fallback icon based on mode
    if not texture then
        local mode = Module.GetMode()
        texture = (mode == Module.MODE_TELEPORT) 
            and "Interface\\Icons\\Spell_Arcane_TeleportStormwind" 
            or "Interface\\Icons\\Spell_Arcane_PortalStormwind"
    end
    
    SetProtectedIcon(btn, texture, spell)
    local Paint = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Paint
    if Paint and Paint.Update then
        Paint.Update(btn)
    end
end

-- Update texture (calls UpdateIcon with nomod)
function Module.UpdateTexture()
    -- Reset tracking state and update icon based on current modifiers
    lastModifierState = ""
    local currentModKey = GetCurrentHeldModKey()
    Module.UpdateIcon(currentModKey)
end

-- ============================================================================
-- MODIFIER TRACKING (for live icon updates)
-- ============================================================================

-- Shared modifier tracker (event-driven; no fallback polling)
local function CheckModifierState()
    -- Don't update if no button
    if not Module._button or not Module._button.WIcon then return end

    -- Freeze icon while combat / hard-lock / casting / pending click→cast
    if InCombatLockdown() then return end
    if Module._isLocked then return end
    if Module._isCasting then return end
    if Module._pendingLockSpell then return end

    -- Check if modifier state changed
    local currentState = GetModifierState()
    if currentState ~= lastModifierState then
        lastModifierState = currentState

        -- Get current held modifier key and update icon immediately
        -- No sticky behavior - always shows current modifier's spell
        local currentModKey = GetCurrentHeldModKey()
        Module.UpdateIcon(currentModKey)
    end

    if tooltipShowing then
        local tipState = GetModifierStateForTooltip()
        if tipState ~= tooltipModState then
            tooltipModState = tipState
            Module.ShowTooltip()
        end
    end
end

local function TeleportModifierIsActive()
    if tooltipShowing then return true end
    if InCombatLockdown() then return false end
    if not Module._button or not Module._button.WIcon then return false end
    if Module._isLocked then return false end
    if Module._isCasting then return false end
    if Module._pendingLockSpell then return false end
    return true
end

if FluxModifierTracker and FluxModifierTracker.Register then
    FluxModifierTracker.Register("NCTeleportPortal", CheckModifierState, {
        isActive = TeleportModifierIsActive,
    })
end

-- Update flyout arrow visibility
function Module.UpdateFlyoutArrow()
    local btn = Module._button
    if not btn or not btn.Widget then return end

    if Module.HasTeleportFlyout() then
        local Flyout = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Flyout
        if Flyout and Flyout.BindHost then
            Flyout.BindHost(btn.Widget, { direction = "UP", classColorArrow = true })
        end
        if FluxFlyoutFrame and FluxFlyoutFrame.ShowArrow then
            FluxFlyoutFrame.ShowArrow(btn.Widget, "UP")
        end
    else
        if FluxFlyoutFrame and FluxFlyoutFrame.HideArrow then
            FluxFlyoutFrame.HideArrow(btn.Widget)
        end
    end
end

-- Update the button
function Module.Update()
    if not Module._button then return end
    if InCombatLockdown() then
        Module._pendingUpdate = true
        return
    end
    
    local btn = Module._button
    local smartTP = Module.HasAnyTeleportOrPortalSpell()
    local fbm = _G.FluxBindingMode
    local bindingForce = fbm and fbm.ShouldForceShowAllExtraSlots and fbm:ShouldForceShowAllExtraSlots()

    -- Check if we still have spells
    if not smartTP then
        if bindingForce then
            if btn.SlotFrame then btn.SlotFrame:Show() end
            ApplyBindingModeNoSpellsPlaceholderLook(btn)
            if btn.ClearAction then btn:ClearAction() end
            SyncNoClassTeleportPlaceholderIconLayers(btn)
            if Module._grid and Module._grid.ScheduleRelayout then
                Module._grid:ScheduleRelayout()
            elseif Module._grid and Module._grid.Relayout then
                Module._grid:Relayout()
            end
            return
        end
        if FluxExtraButtonVisibility and not FluxExtraButtonVisibility.Apply("nc_teleport", smartTP, bindingForce) then
            if btn.Widget and FluxFlyoutFrame and FluxFlyoutFrame.HideArrow then
                FluxFlyoutFrame.HideArrow(btn.Widget)
            end
            if btn.ClearPlaceholder then
                btn.PlaceholderHideCount = nil
                btn:ClearPlaceholder()
            end
            if btn.WIcon then
                if btn.WIcon.SetDesaturated then
                    btn.WIcon:SetDesaturated(false)
                end
                btn.WIcon:SetVertexColor(1, 1, 1, 1)
            end
            if btn.Widget and btn.Widget.icon then
                if btn.Widget.icon.SetDesaturated then
                    btn.Widget.icon:SetDesaturated(false)
                end
                btn.Widget.icon:SetVertexColor(1, 1, 1, 1)
            end
            if btn.SlotFrame then
                btn.SlotFrame:Hide()
            end
            if btn.Widget then
                btn.Widget:Hide()
            end
            if Module._grid and Module._grid.ScheduleRelayout then
                Module._grid:ScheduleRelayout()
            elseif Module._grid and Module._grid.Relayout then
                Module._grid:Relayout()
            end
            Module.ClearTeleportKeybinding()
            return
        end
    end

    if FluxExtraButtonVisibility and not FluxExtraButtonVisibility.Apply("nc_teleport", smartTP, bindingForce) then
        if btn.Widget and FluxFlyoutFrame and FluxFlyoutFrame.HideArrow then
            FluxFlyoutFrame.HideArrow(btn.Widget)
        end
        if btn.SlotFrame then btn.SlotFrame:Hide() end
        if btn.Widget then btn.Widget:Hide() end
        if Module._grid and Module._grid.ScheduleRelayout then
            Module._grid:ScheduleRelayout()
        elseif Module._grid and Module._grid.Relayout then
            Module._grid:Relayout()
        end
        Module.ClearTeleportKeybinding()
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
    
    if btn.ClearPlaceholder then
        btn.PlaceholderHideCount = nil
        btn:ClearPlaceholder()
    end
    
    -- Update flyout category on button and widget (in case mode changed)
    local mode = Module.GetMode()
    btn.FluxFlyoutCategory = mode
    if btn.Widget then
        btn.Widget.FluxFlyoutCategory = mode
    end
    
    -- Apply macro
    Module.ApplyMacro(btn)
    
    -- Update right-click
    Module.SetupRightClick(btn)
    
    -- Update middle-click
    Module.SetupMiddleClick(btn)
    
    -- Update texture
    Module.UpdateTexture()
    
    -- Update flyout arrow
    Module.UpdateFlyoutArrow()
    Module.SyncFlyoutEngine()
    
    -- Update hotkey text display
    Module.UpdateHotkeyText(btn)
    
    -- Refresh display, then re-apply the mode icon so Paint cannot keep the old face.
    if btn.FullRefresh then
        btn:FullRefresh()
    end
    Module.UpdateTexture()
    
    -- Refresh tooltip if shown
    Module.RefreshTooltip()

    Module.UpdateTeleportKeybinding(btn)
end

-- Update teleport keybinding to point to the button widget (secure approach)
function Module.UpdateTeleportKeybinding(btn)
    btn = btn or Module._button
    if not btn or not btn.Widget then return end
    if InCombatLockdown() then
        Module._pendingKeybindUpdate = true
        return
    end

    local widgetName = btn.Widget:GetName()

    -- Clear existing bindings first
    ClearOverrideBindings(btn.Widget)

    local teleportKey = GetBindingKey("FLUXCLASS_TELEPORT")
    if widgetName and teleportKey then
        -- Bind the teleport keybinding to the button widget
        SetOverrideBindingClick(btn.Widget, false, teleportKey, widgetName, "LeftButton")
    end

    -- Bind the toggle teleport/portal mode keybinding to the Lua proxy
    -- (widget MiddleButton has no OnMouseDown when fired from a key).
    local toggleKey = GetBindingKey("FLUXMAGE_TOGGLE_TPPT")
    if toggleKey then
        local proxyName = "FluxMacroProxy_TeleportToggleMode"
        if _G[proxyName] then
            SetOverrideBindingClick(btn.Widget, false, toggleKey, proxyName, "LeftButton")
        elseif widgetName then
            SetOverrideBindingClick(btn.Widget, false, toggleKey, widgetName, "MiddleButton")
        end
    end
end

-- Clear teleport keybinding
function Module.ClearTeleportKeybinding()
    if InCombatLockdown() then return end
    
    local btn = Module._button
    if btn and btn.Widget then
        ClearOverrideBindings(btn.Widget)
    end
end

-- Update hotkey text display on button
function Module.UpdateHotkeyText(btn)
    btn = btn or Module._button
    if FluxNCHotkeyUtil and FluxNCHotkeyUtil.UpdateHotkeyText then
        -- Check if favorites are set for modifiers (not just nomod)
        local hasModifierFavorites = false
        if FluxFlyoutFavorites and FluxFlyoutFavorites.GetFavorite then
            local mode = Module.GetMode()
            -- Check all possible modifier combinations
            local modKeys = { "shift", "ctrl", "alt", "ctrl+shift", "ctrl+alt", "shift+alt", "ctrl+shift+alt" }
            for _, modKey in ipairs(modKeys) do
                local favId = FluxFlyoutFavorites.GetFavorite(mode, modKey)
                if favId then
                    hasModifierFavorites = true
                    break
                end
            end
        end
        
        FluxNCHotkeyUtil.UpdateHotkeyText(btn, "FLUXCLASS_TELEPORT", false, hasModifierFavorites)
    end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local function OnSpellBookChanged()
    if ShouldHoldItemIdentity() then
        if Module._registered then
            Module.Update()
        end
        return
    end
    -- Invalidate cache and update
    Module.InvalidateCache()
    Timer.After(0.5, function()
        -- Check if button needs to be created now
        if not Module._button and Module._grid and Module.HasAnyTeleportOrPortalSpell() then
            Module.CreateButton()
        else
            Module.Update()
        end
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- SPELLS_CHANGED rides the debounced, signature-gated Core bus; the direct
-- frame registration stays only as fallback when the bus is missing.
do
    local SpellBook = _G.Flux and _G.Flux.SpellBook
    if SpellBook and SpellBook.OnChanged then
        SpellBook.OnChanged("ncgrid.teleport", OnSpellBookChanged)
    else
        eventFrame:RegisterEvent("SPELLS_CHANGED")
    end
end
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player") end)

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "PLAYER_REGEN_ENABLED" then
        if not Module._registered then
            return
        end
        local pu = Module._pendingUpdate
        local pk = Module._pendingKeybindUpdate
        local shouldUnlock = Module._pendingUnlock == true
        if not (pu or pk or shouldUnlock) then
            return
        end
        Module._pendingUpdate = nil
        Module._pendingKeybindUpdate = nil
        local runRegen = function()
            if InCombatLockdown() then
                if pu then Module._pendingUpdate = true end
                if pk then Module._pendingKeybindUpdate = true end
                return
            end
            -- Process pending updates after combat
            if pu then
                Module.Update()
            end
            if pk then
                Module.UpdateTeleportKeybinding()
            end
            -- Unlock only when cast finished/interrupted during combat requested it
            if shouldUnlock then
                Module._pendingUnlock = false
                Module.Unlock()
            end
        end
        if FluxCombatRegenDeferQueue then
            FluxCombatRegenDeferQueue(runRegen)
        else
            runRegen()
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
            Module._lockedSpell = nil
            Module._pendingLockSpell = nil
            Module._pendingUnlock = false
            Module._isCasting = false
            ClearCastLockSpellId()
            Module.InvalidateCache()
        end

        -- Fast bind on login/reload; zone load screens keep last spell/item.
        if Module._registered then
            if not Module._button and Module._grid and Module.HasAnyTeleportOrPortalSpell() then
                Module.CreateButton()
            else
                Module.Update()
            end
            Module.RefreshAllReagentDisplays()
        end
        if isLogin then
            local delays = { 0.12, 0.4 }
            for _, delay in ipairs(delays) do
                Timer.After(delay, function()
                    if Module._registered then
                        Module.InvalidateCache()
                        -- Check if button needs to be created
                        if not Module._button and Module._grid and Module.HasAnyTeleportOrPortalSpell() then
                            Module.CreateButton()
                        else
                            Module.Update()
                        end
                        -- Refresh reagent displays in case saved vars were loaded after flyout opened
                        Module.RefreshAllReagentDisplays()
                    end
                end)
            end
        end
        
    elseif event == "SPELLS_CHANGED" then
        -- Fallback path only (no Core SpellBook bus).
        OnSpellBookChanged()

    elseif event == "UNIT_SPELLCAST_START" then
        if arg1 ~= "player" then return end
        
        -- If we have a pending lock spell from PreClick, lock to it now
        -- We trust PreClick to have captured the correct spell
        if Module._pendingLockSpell then
            -- Get spell info from the event (arg2/arg3 format varies by client version)
            local castSpellId = nil
            local castSpellName = nil
            
            -- Modern clients: arg2 = castGUID, arg3 = spellID
            -- Some clients: arg2 = spellName, arg3 = nil
            if type(arg3) == "number" then
                castSpellId = arg3
                castSpellName = GetSpellInfoCompat(castSpellId)
            elseif type(arg2) == "string" and not arg2:find("^Cast%-") then
                castSpellName = arg2
            end
            if castSpellId then
                SetCastLockSpellId(castSpellId)
            elseif Module._pendingLockSpell and Module._pendingLockSpell.spellID then
                SetCastLockSpellId(Module._pendingLockSpell.spellID)
            end
            
            -- Verify this is our pending spell (if we can identify it)
            local shouldLock = false
            if Module._pendingLockSpell.spellID and castSpellId then
                -- Match by spell ID
                shouldLock = (Module._pendingLockSpell.spellID == castSpellId)
            elseif Module._pendingLockSpell.name and castSpellName then
                -- Match by name
                shouldLock = (Module._pendingLockSpell.name:lower() == castSpellName:lower())
            else
                -- Can't verify, but we have a pending lock so assume it's our cast
                shouldLock = true
            end
            
            if shouldLock then
                Module._isCasting = true
                Module.LockToSpell(
                    Module._pendingLockSpell.name,
                    Module._pendingLockSpell.icon,
                    Module._pendingLockSpell.spellID
                )
            end
        end
        
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if arg1 ~= "player" then return end
        Module._isCasting = false
        Module.RefreshReagentCounts()
        
        -- Unlock after a short delay (teleport completes). Defer if still in combat.
        Timer.After(0.5, function()
            if Module._isLocked and not Module._isCasting then
                if not InCombatLockdown() then
                    Module.Unlock()
                else
                    Module._pendingUnlock = true
                end
            end
        end)
        
    elseif event == "UNIT_SPELLCAST_STOP" then
        if arg1 ~= "player" then return end
        Module._isCasting = false
        -- Note: STOP fires when cast ends (success or fail), before SUCCEEDED/FAILED
        -- Don't unlock here - wait for SUCCEEDED or FAILED
        
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        if arg1 ~= "player" then return end
        Module._isCasting = false
        
        -- Cast failed - unlock immediately OOC; defer unlock while in combat
        if not InCombatLockdown() then
            Module.Unlock()
        else
            Module._pendingUnlock = true
        end
        Module._pendingLockSpell = nil
        ClearCastLockSpellId()
        ForceClearButtonCastVFX()
        return  -- Early return since we handled everything
        
    end
    
    -- Clear pending lock spell for successful cast events
    if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_STOP" then
        if arg1 == "player" then
            Module._pendingLockSpell = nil
            if not Module._isLocked and not Module._isCasting then
                ClearCastLockSpellId()
            end
        end
    end
end)

-- FluxInv is the bag SoT for reagent counts (no BagChangeDispatcher / GetItemCount).
if _G.FluxInv and _G.FluxInv.RegisterListener and not Module._fluxInvListenerRegistered then
    Module._fluxInvListenerRegistered = true
    _G.FluxInv.RegisterListener("NCTeleportPortal", function(ctx)
        local changed = ctx and ctx.changedItemIDs
        if changed and not AnyReagentMoved(changed) then
            return
        end
        Module.RefreshReagentCounts()
    end, { tier = "instant", regions = { "bags" }, sync = true })
end

-- Check if a spell is a teleport or portal spell
function Module.IsTeleportOrPortalSpell(spellId, spellName)
    if not spellId and not spellName then return false end
    
    -- Check by name pattern
    if spellName then
        local lowerName = spellName:lower()
        if lowerName:find("^teleport:") or lowerName:find("^portal:") then
            return true
        end
        -- Check known spell lists
        for _, name in ipairs(TELEPORT_SPELL_NAMES) do
            if name:lower() == lowerName then return true end
        end
        for _, name in ipairs(PORTAL_SPELL_NAMES) do
            if name:lower() == lowerName then return true end
        end
    end
    
    -- Check by spell ID
    if spellId then
        local name = GetSpellInfoCompat(spellId)
        if name then
            return Module.IsTeleportOrPortalSpell(nil, name)
        end
    end
    
    return false
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Export reagent detection functions for external use (e.g., FluxVendorAuto)
Module.SpellRequiresReagentsFromTooltip = SpellRequiresReagentsFromTooltip
Module.GetRequiredReagentsForMode = GetRequiredReagentsForMode
Module.GetRestockTarget = Module.GetRestockTarget
Module.SetRestockTarget = Module.SetRestockTarget

function Module.RefreshReagentCounts()
    local btn = Module._button
    if btn and btn.TranslateMacro then
        btn:TranslateMacro()
    end
    if btn and btn.UpdateTextCount then
        btn:UpdateTextCount()
    end
    if btn and btn.UpdateUsable then
        btn:UpdateUsable()
    end
    Module.RefreshAllReagentDisplays()
end

-- Refresh all visible reagent button displays
function Module.RefreshAllReagentDisplays()
    local function refreshKids(kids)
        if type(kids) ~= "table" then
            return
        end
        for _, flyoutBtn in ipairs(kids) do
            if flyoutBtn and flyoutBtn.IsShown and flyoutBtn:IsShown() then
                local def = flyoutBtn._fluxFlyoutDef
                local actionData = flyoutBtn.actionData
                local itemId
                if def and (def.isReagent or def.skipUse) then
                    itemId = tonumber(def.item) or def.item
                elseif actionData and actionData["$isReagent"] then
                    itemId = actionData["$reagentItemId"] or actionData["$itemId"]
                end
                if itemId then
                    NoteReagentItemID(itemId)
                    Module.UpdateReagentButtonDisplay(flyoutBtn, itemId)
                end
            end
        end
    end

    if FluxFlyoutFrame and FluxFlyoutFrame.GetActiveFlyout then
        local activeFlyout = FluxFlyoutFrame.GetActiveFlyout()
        if activeFlyout then
            refreshKids(activeFlyout.kids or activeFlyout.buttons)
        end
    end

    if Module._button and Module._button.Widget and FluxFlyoutFrame and FluxFlyoutFrame.GetFlyoutForButton then
        local flyout = FluxFlyoutFrame.GetFlyoutForButton(Module._button.Widget)
        if flyout then
            refreshKids(flyout.kids or flyout.buttons)
        end
    end
end

-- Debug slash command
SLASH_FLUXTELEPORT1 = "/fluxtp"
SLASH_FLUXTELEPORT2 = "/fluxtp"
SlashCmdList["FLUXTELEPORT"] = function(msg)
    local cmd, args = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "targets" then
        -- No output for targets command
    elseif cmd == "set" then
        local itemId, target = args:match("^(%d+)%s+(%d+)$")
        itemId = tonumber(itemId)
        target = tonumber(target)
        if itemId and target then
            Module.SetRestockTarget(itemId, target)
            -- Refresh displays
            Module.RefreshAllReagentDisplays()
        end
    elseif cmd == "refresh" then
        Module.RefreshAllReagentDisplays()
    else
        -- No help output
    end
end

-- Export for external access
_G.FluxNCTeleportPortal = Module

