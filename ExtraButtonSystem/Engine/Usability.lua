--[[
    ExtraButtonSystem/Engine/Usability.lua
    Unified usability system for both modern and legacy WoW clients
    Based on FluxButtonUsability.lua and ButtonForge patterns
    Uses FLUX_API for cross-version compatibility
]]

if not FluxButtonUsability then
    FluxButtonUsability = {}
end

local FluxButtonUsability = FluxButtonUsability

-- Usability state constants
FluxButtonUsability.STATE_USABLE = 1          -- Fully usable
FluxButtonUsability.STATE_NOT_ENOUGH_MANA = 2 -- Not enough mana/resources
FluxButtonUsability.STATE_NOT_USABLE = 3      -- Cannot use (wrong zone, no charges, etc.)
FluxButtonUsability.STATE_UNKNOWN = 4         -- Cannot determine
FluxButtonUsability.STATE_OUT_OF_RANGE = 5    -- Usable but out of range

-- Visual feedback colors (matching ButtonForge and Blizzard defaults)
FluxButtonUsability.COLOR_USABLE = {r = 1.0, g = 1.0, b = 1.0}
FluxButtonUsability.COLOR_MANA = {r = 0.5, g = 0.5, b = 1.0}
FluxButtonUsability.COLOR_UNUSABLE = {r = 0.4, g = 0.4, b = 0.4}
FluxButtonUsability.COLOR_OUT_OF_RANGE = {r = 0.8, g = 0.1, b = 0.1}  -- Red when out of range

-- Range checking enabled flag
FluxButtonUsability.RangeCheckEnabled = true

-- API compatibility helpers
local function HasC_Spell()
    return FLUX_API and FLUX_API.hasC_Spell
end

local function HasC_Item()
    return FLUX_API and FLUX_API.hasC_Item
end

local function IsLegacyClient()
    return FLUX_API and FLUX_API.isLegacyClient
end

-- Cache for trading skill detection
local tradingSkillCache = {}

-- Check if a spell is a trading skill/profession spell
-- Trading skills always show as usable to prevent flickering on 12.0.0+
local function IsTradingSkill(spellIdentifier)
    if not spellIdentifier then return false end
    
    -- Check cache first
    if tradingSkillCache[spellIdentifier] ~= nil then
        return tradingSkillCache[spellIdentifier]
    end
    
    -- Get spell info - use pcall in case APIs return protected values
    local spellName = nil
    local spellSubtext = nil
    
    local ok, result = pcall(function()
        if C_Spell and C_Spell.GetSpellInfo then
            local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)
            if spellInfo then 
                spellName = spellInfo.name
                -- Check if subtext contains "Trade Skill" or profession-related
                if C_Spell.GetSpellSubtext then
                    spellSubtext = C_Spell.GetSpellSubtext(spellIdentifier)
                end
            end
        elseif GetSpellInfo then
            spellName = GetSpellInfo(spellIdentifier)
        end
    end)
    
    if not ok or not spellName then
        -- If we can't get spell info, return false but don't cache (might work later)
        return false
    end
    
    if not spellName then
        tradingSkillCache[spellIdentifier] = false
        return false
    end
    
    -- Check if subtext indicates trading skill
    if spellSubtext then
        local subtextLower = spellSubtext:lower()
        if subtextLower:find("trade skill") or subtextLower:find("profession") then
            tradingSkillCache[spellIdentifier] = true
            return true
        end
    end
    
    -- Check player's professions - match both exact name and profession ID
    -- Use pcall in case profession APIs have issues
    pcall(function()
        if GetProfessions then
            local prof1, prof2, arch, fish, cook = GetProfessions()
            local professions = {prof1, prof2, arch, fish, cook}
            
            for _, profIndex in ipairs(professions) do
                if profIndex and GetProfessionInfo then
                    local name = GetProfessionInfo(profIndex)
                    -- Match by name
                    if name and spellName == name then
                        tradingSkillCache[spellIdentifier] = true
                        return
                    end
                    -- Also check if spell name contains the profession name
                    if name and type(spellName) == "string" and spellName:find(name) then
                        tradingSkillCache[spellIdentifier] = true
                        return
                    end
                end
            end
        end
    end)
    
    -- Check if already cached as true from the pcall above
    if tradingSkillCache[spellIdentifier] == true then
        return true
    end
    
    -- Known profession spell names (covers all professions - exact matches)
    local professionNames = {
        "Alchemy", "Blacksmithing", "Enchanting", "Engineering", 
        "Inscription", "Jewelcrafting", "Leatherworking", "Tailoring",
        "Herbalism", "Mining", "Skinning", "Archaeology", 
        "Fishing", "Cooking", "First Aid",
        -- Localized names might also be needed
    }
    
    for _, name in ipairs(professionNames) do
        if spellName == name then
            tradingSkillCache[spellIdentifier] = true
            return true
        end
    end
    
    -- Additional check: spells that open a profession window typically don't need usability checks
    -- These are identified by checking if they're in the player's profession tab
    if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
        -- Try to find this spell in the profession spell book
        local numProfessionSpells = 0
        if HasPetSpells then
            -- This is a workaround - checking if spell exists in profession tabs
            local spellBookType = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or "spell"
            for i = 1, 200 do -- Check first 200 spell slots
                local info = C_SpellBook.GetSpellBookItemInfo(i, spellBookType)
                if info and info.spellID then
                    if info.spellID == spellIdentifier or (type(spellIdentifier) == "string" and info.name == spellIdentifier) then
                        if info.isTradeSkill then
                            tradingSkillCache[spellIdentifier] = true
                            return true
                        end
                    end
                end
            end
        end
    end
    
    tradingSkillCache[spellIdentifier] = false
    return false
end

-- Resolve spell id + localized name for usability APIs (ButtonForge uses spell name on legacy).
-- Prefer Name(Rank N) / numeric ID — never bare name alone on rank clients (max-rank usable bug).
local function FormatRankedUsabilityArg(spellIdentifier, spellId)
    if type(spellIdentifier) == "string" and spellIdentifier:find("%(", 1, true) then
        return spellIdentifier
    end
    local id = tonumber(spellId) or tonumber(spellIdentifier)
    local fmt = _G.FluxFormatSpellCastAttribute
        or (_G.FluxButtonCore and _G.FluxButtonCore.FormatSpellCastAttribute)
    if id and fmt then
        local attr = fmt(id)
        if type(attr) == "string" and attr ~= "" then
            return attr
        end
    end
    return id or spellIdentifier
end

local function ResolveSpellForUsability(spellIdentifier)
    if not spellIdentifier then
        return nil, nil
    end

    local spellId = spellIdentifier
    local spellName

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellIdentifier)
        if info then
            spellId = info.spellID or spellIdentifier
            spellName = info.name
            return spellId, spellName
        end
    end

    if GetSpellInfo then
        local name, _, _, _, _, _, resolvedId = GetSpellInfo(spellIdentifier)
        if name then
            spellName = name
            spellId = resolvedId or spellIdentifier
            return spellId, spellName
        end
    end

    if type(spellIdentifier) == "string" then
        return spellIdentifier, spellIdentifier
    end

    return spellIdentifier, nil
end

-- Check if a spell is usable
function FluxButtonUsability:CheckSpellUsability(spellIdentifier)
    if not spellIdentifier then
        return self.STATE_NOT_USABLE, false
    end
    
    -- Trading skills always show as usable to prevent flickering on 12.0.0+
    if IsTradingSkill(spellIdentifier) then
        return self.STATE_USABLE, false
    end

    local API = FluxAPICompat and FluxAPICompat.API
    if API and API.IsSpellUsable then
        -- Prefer ranked/name form on classic; API resolves override on post-DF.
        local spellId, _spellName = ResolveSpellForUsability(spellIdentifier)
        local usableKey = FormatRankedUsabilityArg(spellIdentifier, spellId)
        local isUsable, notEnoughMana = API.IsSpellUsable(usableKey)
        -- nil,nil = secret / inaccessible — keep last-known (STATE_UNKNOWN).
        if isUsable == nil and notEnoughMana == nil then
            return self.STATE_UNKNOWN, false
        end
        if isUsable then
            return self.STATE_USABLE, false
        elseif notEnoughMana then
            return self.STATE_NOT_ENOUGH_MANA, true
        else
            return self.STATE_NOT_USABLE, false
        end
    end

    local spellId, spellName = ResolveSpellForUsability(spellIdentifier)
    
    local isUsable = false
    local notEnoughMana = false
    
    -- 12.0.0+ Secret Value Handling
    local has12SecretValues = FluxAPICompat and FluxAPICompat.FLUX_API and FluxAPICompat.FLUX_API.hasCanAccessValue
    local canAccessValue = FluxAPICompat and FluxAPICompat.API and FluxAPICompat.API.CanAccessValue or function() return true end
    
    -- Modern API (Retail, Modern Classic)
    if C_Spell and C_Spell.IsSpellUsable then
        local usableKey = FormatRankedUsabilityArg(spellIdentifier, spellId)
        isUsable, notEnoughMana = C_Spell.IsSpellUsable(usableKey)
        if isUsable == nil and spellId and usableKey ~= spellId then
            isUsable, notEnoughMana = C_Spell.IsSpellUsable(spellId)
        end
        
        if has12SecretValues then
            local canAccessUsable = canAccessValue(isUsable)
            local canAccessMana = canAccessValue(notEnoughMana)
            
            if not canAccessUsable or not canAccessMana then
                return self.STATE_UNKNOWN, false
            end
        end
        
        if isUsable == nil and notEnoughMana == nil then
            return self.STATE_NOT_USABLE, false
        end
        if isUsable == nil then
            isUsable = false
        end
        if notEnoughMana == nil then
            notEnoughMana = false
        end
    -- Legacy API fallback (Classic Era / TBC) — ButtonForge: IsUsableSpell(SpellNameRank)
    elseif IsUsableSpell then
        local usableArg = FormatRankedUsabilityArg(spellIdentifier, spellId)
        isUsable, notEnoughMana = IsUsableSpell(usableArg)
        if isUsable == nil and spellId and usableArg ~= spellId then
            isUsable, notEnoughMana = IsUsableSpell(spellId)
        end
        if isUsable == nil then
            isUsable = true
        end
    else
        return self.STATE_UNKNOWN, false
    end
    
    if isUsable then
        return self.STATE_USABLE, false
    elseif notEnoughMana then
        return self.STATE_NOT_ENOUGH_MANA, true
    else
        return self.STATE_NOT_USABLE, false
    end
end

-- Check if an item is usable
function FluxButtonUsability:CheckItemUsability(itemIdentifier)
    if not itemIdentifier then
        return self.STATE_NOT_USABLE, false, 0
    end
    
    -- Special case: check if it's a toy
    if PlayerHasToy and PlayerHasToy(itemIdentifier) then
        return self.STATE_USABLE, false, 0
    end
    
    local isUsable = false
    local notEnoughMana = false
    local itemCount = 0
    
    -- 12.0.0+ Secret Value Handling
    local has12SecretValues = FluxAPICompat and FluxAPICompat.FLUX_API and FluxAPICompat.FLUX_API.hasCanAccessValue
    local canAccessValue = FluxAPICompat and FluxAPICompat.API and FluxAPICompat.API.CanAccessValue or function() return true end
    
    -- Get item count
    local inv = _G.FluxInv
    if inv and inv.GetLiveCount then
        itemCount = inv.GetLiveCount(itemIdentifier, { includeBank = false, charges = true })
        itemCount = itemCount or 0
    elseif inv and inv.GetCount then
        itemCount = inv.GetCount(itemIdentifier, { includeBank = false, charges = true })
        itemCount = itemCount or 0
    elseif _G.FluxGetItemCount then
        itemCount = _G.FluxGetItemCount(itemIdentifier, { includeBank = false, charges = true }) or 0
    elseif HasC_Item() and C_Item and C_Item.GetItemCount then
        itemCount = C_Item.GetItemCount(itemIdentifier, nil, true)
        
        -- 12.0.0+ Check if itemCount is a secret value
        if has12SecretValues and not canAccessValue(itemCount) then
            -- Item count is secret - during combat, return UNKNOWN
            return self.STATE_UNKNOWN, false, 0
        end
        
        itemCount = itemCount or 0
    elseif GetItemCount then
        itemCount = GetItemCount(itemIdentifier, nil, true) or 0
    end

    -- Equipped gear is not included in bag GetItemCount — still "have it"
    -- (multi-cast /use 13–14 trinkets, Extra equip buttons, etc.).
    if (not itemCount or itemCount == 0) then
        local equipped = false
        if C_Item and C_Item.IsEquippedItem then
            equipped = C_Item.IsEquippedItem(itemIdentifier) and true or false
        elseif IsEquippedItem then
            equipped = IsEquippedItem(itemIdentifier) and true or false
        end
        if equipped then
            itemCount = 1
        end
    end
    
    -- Special case: item count is 0
    if itemCount == 0 then
        return self.STATE_NOT_USABLE, false, 0
    end
    
    -- Legacy client behavior
    if IsLegacyClient() then
        if itemCount > 0 then
            return self.STATE_USABLE, false, itemCount
        else
            return self.STATE_NOT_USABLE, false, 0
        end
    end
    
    -- Modern client usability checks
    if C_Item and C_Item.IsUsableItem then
        isUsable, notEnoughMana = C_Item.IsUsableItem(itemIdentifier)
        
        -- 12.0.0+ Check if returns are secret values
        if has12SecretValues then
            local canAccessUsable = canAccessValue(isUsable)
            local canAccessMana = canAccessValue(notEnoughMana)
            
            if not canAccessUsable or not canAccessMana then
                -- Returns are secret values - during combat, return last known state or UNKNOWN
                return self.STATE_UNKNOWN, false, itemCount
            end
        end
        
        -- Handle nil return values (item doesn't exist or API error)
        if isUsable == nil and notEnoughMana == nil then
            -- Both nil means item doesn't exist or API error - treat as NOT_USABLE
            return self.STATE_NOT_USABLE, false, itemCount
        end
        -- Normalize nil to false for boolean checks
        if isUsable == nil then
            isUsable = (itemCount > 0)  -- Default to usable if we have the item
        end
        if notEnoughMana == nil then
            notEnoughMana = false
        end
    elseif IsUsableItem then
        isUsable, notEnoughMana = IsUsableItem(itemIdentifier)
        if isUsable == nil then
            -- Default to usable if we have the item
            isUsable = (itemCount > 0)
        end
    else
        -- No API available, assume usable if we have the item
        return self.STATE_UNKNOWN, false, itemCount  -- Will be treated as USABLE
    end
    
    if isUsable then
        return self.STATE_USABLE, false, itemCount
    elseif notEnoughMana then
        return self.STATE_NOT_ENOUGH_MANA, true, itemCount
    else
        return self.STATE_NOT_USABLE, false, itemCount
    end
end

-- Mount environmental restrictions (combat lockdown + indoors).
-- Use InCombatLockdown only — UnitAffectingCombat can linger after regen and
-- falsely keep mounts gray while still OOC for secure.
function FluxButtonUsability:IsMountEnvironmentBlocked()
    local inCombat = InCombatLockdown and InCombatLockdown()
    local isIndoors = IsIndoors and IsIndoors()
    return inCombat or isIndoors
end

-- Check if a mount item is usable (legacy bag mounts + flyout rows).
-- ButtonForge / LAB: item mounts use IsUsableItem only — never gate on mount spell.
function FluxButtonUsability:CheckMountItemUsability(itemIdentifier)
    if not itemIdentifier then
        return self.STATE_NOT_USABLE, false, 0
    end

    if self:IsMountEnvironmentBlocked() then
        local _, _, itemCount = self:CheckItemUsability(itemIdentifier)
        return self.STATE_NOT_USABLE, false, itemCount or 0
    end

    local Spells = _G.FluxInv and _G.FluxInv.Spells
    local zoneCheck = (Spells and Spells.IsMountUsableInCurrentZone)
        or (FluxItemDetection and FluxItemDetection.IsMountUsableInCurrentZone)
    if zoneCheck and not zoneCheck(itemIdentifier) then
        local _, _, itemCount = self:CheckItemUsability(itemIdentifier)
        return self.STATE_NOT_USABLE, false, itemCount or 0
    end

    return self:CheckItemUsability(itemIdentifier)
end

-- Check if a journal mount is usable (ButtonForge companion path).
function FluxButtonUsability:CheckMountUsability(mountIdentifier)
    if not mountIdentifier then
        return self.STATE_NOT_USABLE, false
    end

    if self:IsMountEnvironmentBlocked() then
        return self.STATE_NOT_USABLE, false
    end

    if C_MountJournal and C_MountJournal.GetMountInfoByID then
        -- name, spellID, icon, isActive, isUsable, ..., isCollected
        local mountName, mountSpellID, _, _, isUsable, _, _, _, _, _, isCollected =
            C_MountJournal.GetMountInfoByID(mountIdentifier)

        if not mountName and not mountSpellID then
            return self.STATE_NOT_USABLE, false
        end

        if not isCollected then
            return self.STATE_NOT_USABLE, false
        end

        -- ButtonForge: spell usable AND journal isUsable when present.
        if isUsable == false then
            return self.STATE_NOT_USABLE, false
        end

        if mountSpellID then
            local spellState, spellMana = self:CheckSpellUsability(mountSpellID)
            if spellState ~= self.STATE_USABLE then
                return spellState, spellMana
            end
        end

        return self.STATE_USABLE, false
    end

    -- Legacy client without C_MountJournal
    return self.STATE_USABLE, false
end

-- Check if a battle pet is usable
function FluxButtonUsability:CheckBattlePetUsability(petID)
    if not petID or not C_PetJournal or not C_PetJournal.GetPetInfoByPetID then
        return self.STATE_UNKNOWN, false
    end
    
    -- Pets are generally always summonable unless player is in combat or dead
    local inCombat = InCombatLockdown() or UnitAffectingCombat("player")
    local isDead = UnitIsDead("player")
    
    if inCombat or isDead then
        return self.STATE_NOT_USABLE, false
    end
    
    -- Check if pet exists
    local speciesID = C_PetJournal.GetPetInfoByPetID(petID)
    if speciesID then
        return self.STATE_USABLE, false
    else
        return self.STATE_NOT_USABLE, false
    end
end

-- Check if a macro is usable
function FluxButtonUsability:CheckMacroUsability(macroBody, macroMode, spellId, itemId)
    if not macroBody then
        return self.STATE_NOT_USABLE, false
    end
    
    -- Trading skills always show as usable to prevent flickering on 12.0.0+
    -- Check early before any condition parsing that might cause flickering
    if macroMode == "spell" and spellId and IsTradingSkill(spellId) then
        return self.STATE_USABLE, false
    end

    -- Bracket conditionals: parse /cast|/use tails only (never the full
    -- "/cast [@mouseover] Spell; …" string — SecureCmdOptionParse on that
    -- returns empty when no clause matches and falsely grays UF-peek badges).
    local function ActiveCastTail(body)
        if type(body) ~= "string" or body == "" or not SecureCmdOptionParse then
            return nil
        end
        if not body:find("%[", 1, true) then
            return nil
        end
        for line in body:gmatch("[^\r\n]+") do
            if not line:match("^%s*#") then
                local cmd, rest = line:match("^%s*(/%a+)%s*(.-)%s*$")
                if cmd and rest and rest ~= "" then
                    cmd = cmd:lower()
                    if cmd == "/cast" or cmd == "/use" or cmd == "/castsequence" then
                        local active = SecureCmdOptionParse(rest)
                        if active and active ~= "" then
                            return active
                        end
                    end
                end
            end
        end
        return nil
    end

    local activeTail = ActiveCastTail(macroBody)

    -- Castsequence macros (e.g. mana gem stacks): use resolved item when available
    if type(macroBody) == "string" and macroBody:find("/castsequence") then
        if itemId then
            local state, notEnoughMana = self:CheckItemUsability(itemId)
            return state, notEnoughMana
        end
        if macroMode == "spell" and spellId then
            return self:CheckSpellUsability(FormatRankedUsabilityArg(nil, spellId))
        end
    end

    -- Mount-item flyout macros only — spell flyouts must not use mount env rules.
    if type(macroBody) == "string" and macroBody:match("/flyout") and macroBody:find("/use") then
        if self:IsMountEnvironmentBlocked() then
            return self.STATE_NOT_USABLE, false
        end
        if macroMode == "spell" and spellId then
            return self:CheckSpellUsability(FormatRankedUsabilityArg(nil, spellId))
        end
    end

    -- Spell cast macros (/cast ...) — prefer active clause, else TranslateMacro's spellId
    if type(macroBody) == "string" and macroBody:find("/cast") and not macroBody:find("/use") then
        if activeTail then
            local state, mana = self:CheckSpellUsability(activeTail)
            if state ~= self.STATE_UNKNOWN then
                return state, mana
            end
        end
        if macroMode == "spell" and spellId then
            return self:CheckSpellUsability(FormatRankedUsabilityArg(nil, spellId))
        end
        -- Known display spell (TranslateMacro / aspect): never force white over real usable.
        if spellId then
            return self:CheckSpellUsability(FormatRankedUsabilityArg(nil, spellId))
        end
        -- Bracketed body with no matching clause and no known spell: white (UF peek).
        if macroBody:find("%[", 1, true) then
            return self.STATE_USABLE, false
        end
    end

    -- /use item macros — consumables and charge items (not mount env unless mount item)
    if type(macroBody) == "string" and macroBody:find("/use") then
        local useItemId = itemId or tonumber(macroBody:match("item:(%d+)"))
            or (activeTail and tonumber(activeTail:match("item:(%d+)")))
        if not useItemId then
            -- Inventory slot extras: `/use 13` / activeTail "13"
            local slot = (activeTail and tonumber(activeTail))
                or tonumber(macroBody:match("/use%s+(%d+)"))
            if slot and slot >= 1 and slot <= 30 and GetInventoryItemID then
                useItemId = GetInventoryItemID("player", slot)
            end
        end
        if not useItemId and activeTail then
            -- activeTail may be an item name; fall through to itemId from TranslateMacro
            useItemId = itemId
        end
        if useItemId then
            if FluxItemDetection and FluxItemDetection.IsItemAMount and FluxItemDetection.IsItemAMount(useItemId) then
                local state, notEnoughMana = self:CheckMountItemUsability(useItemId)
                return state, notEnoughMana
            end
            local state, notEnoughMana = self:CheckItemUsability(useItemId)
            return state, notEnoughMana
        end
    end

    -- Check based on macro mode (if known)
    if macroMode == "spell" and spellId then
        return self:CheckSpellUsability(FormatRankedUsabilityArg(nil, spellId))
    elseif macroMode == "item" and itemId then
        if FluxItemDetection and FluxItemDetection.IsItemAMount and FluxItemDetection.IsItemAMount(itemId) then
            local state, notEnoughMana = self:CheckMountItemUsability(itemId)
            return state, notEnoughMana
        end
        local state, notEnoughMana, itemCount = self:CheckItemUsability(itemId)
        return state, notEnoughMana
    end

    -- Unknown macro mode, assume usable
    return self.STATE_USABLE, false
end

-- Safe IsSpellInRange wrapper for cross-version compatibility
function FluxButtonUsability:IsSpellInRange(spellIdentifier, unit)
    if not spellIdentifier or not unit then return nil end
    local FR = _G.FluxRange
    if FR and FR.CheckSpell then
        return FR.CheckSpell(spellIdentifier, unit)
    end
    local API = FluxAPICompat and FluxAPICompat.API
    if API and API.IsSpellInRange then
        return API.IsSpellInRange(spellIdentifier, unit)
    end
    return nil
end

-- Safe IsItemInRange wrapper for cross-version compatibility
function FluxButtonUsability:IsItemInRange(itemId, unit)
    if not itemId or not unit then return nil end
    local FR = _G.FluxRange
    if FR and FR.CheckItem then
        return FR.CheckItem(itemId, unit)
    end
    local API = FluxAPICompat and FluxAPICompat.API
    if API and API.IsItemInRange then
        return API.IsItemInRange(itemId, unit)
    end
    return nil
end

-- Check if a spell is in range
function FluxButtonUsability:ShouldApplyRangeCheck(spellIdentifier, unit)
    if not spellIdentifier or not unit then
        return true
    end
    local resolveFn = _G.FluxSpellBindingProfile_ResolveSpellHelpHarm
    if type(resolveFn) ~= "function" then
        return true
    end
    local helpful, harmful = resolveFn(spellIdentifier)
    if not helpful and not harmful then
        return true
    end
    local unitExists = false
    local ok, result = pcall(function() return UnitExists(unit) end)
    if ok then
        unitExists = result
    end
    if not unitExists then
        return false
    end
    local canHelp, canHarm = false, false
    ok, result = pcall(function() return UnitIsFriend("player", unit) end)
    if ok then canHelp = result and true or false end
    ok, result = pcall(function() return UnitCanAttack("player", unit) end)
    if ok then canHarm = result and true or false end
    if helpful and not harmful and not canHelp then
        return false
    end
    if harmful and not helpful and not canHarm then
        return false
    end
    return true
end

function FluxButtonUsability:CheckSpellRange(spellIdentifier, unit)
    if not self.RangeCheckEnabled or not spellIdentifier then
        return nil  -- nil means range checking not applicable
    end

    local FR = _G.FluxRange
    if FR and FR.ResolveUnit and not unit then
        unit = FR.ResolveUnit(nil, { unit = "target" })
    else
        unit = unit or "target"
    end
    if unit == "cursor" or not unit then
        return nil
    end

    local unitExists = false
    local ok, result = pcall(function() return UnitExists(unit) end)
    if ok then
        unitExists = result
    end

    if not unitExists then
        return nil
    end

    if not self:ShouldApplyRangeCheck(spellIdentifier, unit) then
        return nil
    end

    if FR and FR.ResolveSpellIdentifier then
        -- Keep aspect/lower-rank display spell when callers pass a button via CheckButtonRange.
    end
    return self:IsSpellInRange(spellIdentifier, unit)
end

-- Check if an item is in range
function FluxButtonUsability:CheckItemRange(itemId, unit)
    if not self.RangeCheckEnabled or not itemId then
        return nil
    end
    
    unit = unit or "target"
    
    -- Wrap UnitExists in pcall as it may be protected during combat
    local unitExists = false
    local ok, result = pcall(function() return UnitExists(unit) end)
    if ok then
        unitExists = result
    end
    
    if not unitExists then
        return nil
    end
    
    return self:IsItemInRange(itemId, unit)
end

-- Extract target unit from macro body (supports @mouseover, @target, @focus, etc.)
-- Evaluates conditions to find which branch is currently active
function FluxButtonUsability:ExtractMacroTarget(macroBody)
    if not macroBody or type(macroBody) ~= "string" then
        return "target"  -- Default to target
    end
    
    -- Use SecureCmdOptionParse to evaluate conditions (if available)
    if SecureCmdOptionParse then
        for line in macroBody:gmatch("[^\r\n]+") do
            -- Look for /cast or /use lines
            local castLine = line:match("^%s*/%s*cast%s+(.+)") or line:match("^%s*/%s*use%s+(.+)")
            if castLine then
                -- Split by semicolons to get each condition/spell pair
                local segments = {}
                for segment in (castLine .. ";"):gmatch("([^;]*);") do
                    if segment and segment ~= "" then
                        table.insert(segments, segment)
                    end
                end
                
                -- Evaluate each segment to find which one is active
                for _, segment in ipairs(segments) do
                    segment = segment:match("^%s*(.-)%s*$")  -- trim
                    
                    -- Try to parse this segment with SecureCmdOptionParse
                    local result = SecureCmdOptionParse(segment)
                    
                    if result and result ~= "" then
                        -- This segment is active, extract target from it
                        -- Look for [@unit] pattern in this specific segment
                        local targetUnit = segment:match("%[@([^%],]+)")
                        
                        if targetUnit then
                            -- Trim and return the target
                            targetUnit = targetUnit:match("^%s*(.-)%s*$")
                            return targetUnit
                        else
                            -- No explicit @unit means it uses current target
                            return "target"
                        end
                    end
                end
                
                -- If we got here, no condition matched, check for default (no condition)
                for _, segment in ipairs(segments) do
                    segment = segment:match("^%s*(.-)%s*$")
                    -- If segment has no brackets, it's the default
                    if not segment:match("%[") then
                        -- Default segment - check if it has @unit
                        local targetUnit = segment:match("@([^%s,;]+)")
                        if targetUnit then
                            return targetUnit
                        else
                            return "target"
                        end
                    end
                end
            end
        end
    end
    
    -- Fallback: Simple pattern matching (less accurate)
    -- Just find the first @unit in the macro
    local targetUnit = macroBody:match("%[@([^%],]+)")
    if targetUnit then
        targetUnit = targetUnit:match("^%s*(.-)%s*$")
        return targetUnit
    end
    
    return "target"  -- Default
end

-- Check range for a button based on its action type
function FluxButtonUsability:CheckButtonRange(button, rangeUnit)
    if not button then return nil end

    local FR = _G.FluxRange
    local unit = rangeUnit
    if not unit and FR and FR.ResolveUnit then
        unit = FR.ResolveUnit(button)
    end
    if not unit then
        -- For macros, use the already-parsed target from TranslateMacro
        if button.ActionType == "macro" then
            if button.Target then
                unit = button.Target
            else
                unit = "target"
            end
        else
            unit = "target"
        end
        if unit == "player" or unit == "cursor" then
            return nil
        end
        local exists = false
        local ok, result = pcall(UnitExists, unit)
        if ok then exists = result end
        if not exists then return nil end
    end

    local actionType = button.ActionType
    if actionType == "spell" then
        local spellIdentifier = button.SpellNameRank or button.SpellId
        if FR and FR.ResolveSpellIdentifier then
            spellIdentifier = FR.ResolveSpellIdentifier(button, spellIdentifier)
        end
        return self:CheckSpellRange(spellIdentifier, unit)

    elseif actionType == "item" then
        return self:CheckItemRange(button.ItemId, unit)

    elseif actionType == "macro" then
        if button.MacroMode == "spell" then
            local spellIdentifier = button.SpellNameRank or button.SpellId
            if FR and FR.ResolveSpellIdentifier then
                spellIdentifier = FR.ResolveSpellIdentifier(button, spellIdentifier)
            end
            return self:CheckSpellRange(spellIdentifier, unit)
        elseif button.MacroMode == "item" then
            return self:CheckItemRange(button.ItemId, unit)
        end
    end

    return nil  -- No range checking for other types
end

-- Check if an action is usable
function FluxButtonUsability:CheckActionUsability(actionSlot)
    if not actionSlot then
        return self.STATE_NOT_USABLE, false
    end
    
    if FluxAPICompat.API.IsUsableAction then
        local isUsable, notEnoughMana = FluxAPICompat.API.IsUsableAction(actionSlot)
        if isUsable == nil then
            isUsable = true
        end
        
        if isUsable then
            return self.STATE_USABLE, false
        elseif notEnoughMana then
            return self.STATE_NOT_ENOUGH_MANA, true
        else
            return self.STATE_NOT_USABLE, false
        end
    else
        return self.STATE_UNKNOWN, false
    end
end

function FluxButtonUsability:CheckActionSlotRange(actionSlot, unit)
    if not actionSlot then
        return nil
    end
    local FR = _G.FluxRange
    if FR and FR.ResolveUnit and not unit then
        unit = FR.ResolveUnit(nil)
    else
        unit = unit or "target"
    end
    if not unit or unit == "cursor" then
        return nil
    end
    local unitExists = false
    local ok, result = pcall(function() return UnitExists(unit) end)
    if ok then
        unitExists = result
    end
    if not unitExists then
        return nil
    end
    if GetActionInfo then
        local atype, id = GetActionInfo(actionSlot)
        if atype == "spell" and id and not self:ShouldApplyRangeCheck(id, unit) then
            return nil
        end
    end
    if FR and FR.CheckAction then
        return FR.CheckAction(actionSlot, unit)
    end
    local API = FluxAPICompat and FluxAPICompat.API or {}
    if API.IsActionInRange then
        return API.IsActionInRange(actionSlot, unit)
    end
    if IsActionInRange then
        return IsActionInRange(actionSlot, unit)
    end
    return nil
end

-- Cache for last known good usability states (used for 12.0.0+ secret value handling)
local lastKnownGoodStates = {}

-- Check usability for any action type
function FluxButtonUsability:CheckUsability(actionType, actionValue, extraData)
    if not actionType or not actionValue then
        -- No action assigned: treat as UNKNOWN (will display as usable but empty)
        -- This allows empty buttons to show correctly without being darkened
        return self.STATE_UNKNOWN, false, nil
    end
    
    -- Trading skills always show as usable to prevent flickering on 12.0.0+
    -- Check EARLY before any API calls that might cause flickering
    if actionType == "spell" and IsTradingSkill(actionValue) then
        return self.STATE_USABLE, false, nil
    end
    if actionType == "macro" and extraData and extraData.spellId and IsTradingSkill(extraData.spellId) then
        return self.STATE_USABLE, false, nil
    end
    
    local state, mana, extraInfo
    
    -- 12.0.0+ secret value handling - check if we should preserve last known state
    local has12SecretValues = FluxAPICompat and FluxAPICompat.FLUX_API and FluxAPICompat.FLUX_API.hasCanAccessValue
    local cacheKey = actionType .. "_" .. tostring(actionValue)
    
    if actionType == "spell" then
        local spellKey = (extraData and extraData.spellNameRank) or actionValue
        state, mana = self:CheckSpellUsability(spellKey)
        -- On 12.0.0+, if UNKNOWN due to secret values, use cached state
        if state == self.STATE_UNKNOWN and has12SecretValues then
            local cached = lastKnownGoodStates[cacheKey]
            if cached then
                return cached.state, cached.mana, nil
            end
            -- No cache: keep UNKNOWN so UpdateButton can retain prior tint (not force white).
            return self.STATE_UNKNOWN, false, nil
        end
        -- ButtonForge: uncertain spell usability displays bright (non-secret clients)
        if state == self.STATE_UNKNOWN then
            state = self.STATE_USABLE
        end
        -- Cache good state
        if has12SecretValues and state ~= self.STATE_UNKNOWN then
            lastKnownGoodStates[cacheKey] = { state = state, mana = mana }
        end
        return state, mana, nil
        
    elseif actionType == "item" then
        if FluxItemDetection and FluxItemDetection.IsItemAMount and FluxItemDetection.IsItemAMount(actionValue) then
            state, mana, extraInfo = self:CheckMountItemUsability(actionValue)
        else
            state, mana, extraInfo = self:CheckItemUsability(actionValue)
        end
        -- On 12.0.0+, if UNKNOWN due to secret values, use cached state
        if state == self.STATE_UNKNOWN and has12SecretValues then
            local cached = lastKnownGoodStates[cacheKey]
            if cached then
                return cached.state, cached.mana, cached.extraInfo
            end
            return self.STATE_USABLE, false, extraInfo
        end
        -- Ensure we never return UNKNOWN for items (should be NOT_USABLE if invalid)
        if state == self.STATE_UNKNOWN then
            state = self.STATE_NOT_USABLE
        end
        -- Cache good state
        if has12SecretValues and state ~= self.STATE_UNKNOWN then
            lastKnownGoodStates[cacheKey] = { state = state, mana = mana, extraInfo = extraInfo }
        end
        return state, mana, extraInfo
        
    elseif actionType == "equipmentset" then
        -- Equipment sets are always usable if they exist
        -- Check if the set still exists
        local exists = false
        if C_EquipmentSet and C_EquipmentSet.GetEquipmentSetInfo then
            local setName = C_EquipmentSet.GetEquipmentSetInfo(actionValue)
            exists = setName ~= nil
        end
        if exists then
            return self.STATE_USABLE, false, nil
        else
            return self.STATE_NOT_USABLE, false, nil
        end
        
    elseif actionType == "mount" then
        state, mana = self:CheckMountUsability(actionValue)
        -- On 12.0.0+, if UNKNOWN due to secret values, use cached state
        if state == self.STATE_UNKNOWN and has12SecretValues then
            local cached = lastKnownGoodStates[cacheKey]
            if cached then
                return cached.state, cached.mana, nil
            end
        end
        -- Mount checks should never return UNKNOWN (environmental checks always apply)
        if state == self.STATE_UNKNOWN then
            state = self.STATE_NOT_USABLE
        end
        -- Cache good state
        if has12SecretValues and state ~= self.STATE_UNKNOWN then
            lastKnownGoodStates[cacheKey] = { state = state, mana = mana }
        end
        return state, mana, nil
        
    elseif actionType == "battlepet" then
        state, mana = self:CheckBattlePetUsability(actionValue)
        -- On 12.0.0+, if UNKNOWN due to secret values, use cached state
        if state == self.STATE_UNKNOWN and has12SecretValues then
            local cached = lastKnownGoodStates[cacheKey]
            if cached then
                return cached.state, cached.mana, nil
            end
        end
        -- Battle pet checks should never return UNKNOWN
        if state == self.STATE_UNKNOWN then
            state = self.STATE_NOT_USABLE
        end
        -- Cache good state
        if has12SecretValues and state ~= self.STATE_UNKNOWN then
            lastKnownGoodStates[cacheKey] = { state = state, mana = mana }
        end
        return state, mana, nil
        
    elseif actionType == "macro" then
        local macroBody = extraData and extraData.macroBody
        local macroMode = extraData and extraData.macroMode
        local spellId = extraData and extraData.spellId
        local itemId = extraData and extraData.itemId
        state, mana = self:CheckMacroUsability(macroBody, macroMode, spellId, itemId)
        -- On 12.0.0+, if UNKNOWN due to secret values, use cached state
        if state == self.STATE_UNKNOWN and has12SecretValues then
            local cached = lastKnownGoodStates[cacheKey]
            if cached then
                return cached.state, cached.mana, nil
            end
        end
        -- Cache good state
        if has12SecretValues and state ~= self.STATE_UNKNOWN then
            lastKnownGoodStates[cacheKey] = { state = state, mana = mana }
        end
        -- Macros can return UNKNOWN for unknown macro modes, which is correct
        return state, mana, nil
        
    elseif actionType == "action" then
        state, mana = self:CheckActionUsability(actionValue)
        return state, mana, nil
        
    else
        -- Unknown action type
        return self.STATE_UNKNOWN, false, nil
    end
end

-- Debouncing cache for visual feedback (prevents flickering on 12.0.0+)
local visualFeedbackCache = {}
local VISUAL_DEBOUNCE_INTERVAL = 0.2  -- 200ms debounce window (increased for better stability)
local VISUAL_COMBAT_DEBOUNCE_INTERVAL = 0.3  -- 300ms debounce window during combat (more aggressive)

-- Clear visual feedback cache (call when leaving combat to allow immediate updates)
function FluxButtonUsability:ClearVisualFeedbackCache()
    visualFeedbackCache = {}
end

function FluxButtonUsability:BustButtonVisualCache(button)
    if not button then return end
    visualFeedbackCache[tostring(button.Widget or button)] = nil
end

-- Apply usability visual feedback to a button
function FluxButtonUsability:ApplyVisualFeedback(button, state, notEnoughMana)
    if not button or not button.WIcon then
        return
    end
    -- Never paint usable/mana/OOR over empty-slot placeholder gray.
    if button.PlaceholderTexture and not button.IsWispLockPlaceholder then
        button.WIcon:SetTexture(button.PlaceholderTexture)
        button.WIcon:SetDesaturated(true)
        button.WIcon:SetVertexColor(0.25, 0.25, 0.25)
        button.WIcon:Show()
        return
    end
    
    -- 12.0.0+ Debouncing: Skip redundant visual updates to prevent flickering
    -- Apply both in and out of combat, but more aggressive during combat
    local has12SecretValues = FluxAPICompat and FluxAPICompat.FLUX_API and FluxAPICompat.FLUX_API.hasCanAccessValue
    if has12SecretValues then
        local buttonKey = tostring(button.Widget or button)
        local now = GetTime()
        local cached = visualFeedbackCache[buttonKey]
        local inCombat = InCombatLockdown()
        local debounceInterval = inCombat and VISUAL_COMBAT_DEBOUNCE_INTERVAL or VISUAL_DEBOUNCE_INTERVAL
        
        if cached then
            -- If same state and within debounce window, skip visual update
            if cached.state == state and cached.mana == notEnoughMana and (now - cached.time) < debounceInterval then
                return  -- Skip this visual update to prevent flickering
            end

            -- Also skip if state changed but very recently (prevents rapid state oscillation).
            -- Exception: always allow OOR enter/leave so red tint never sticks or misses.
            -- Also always allow action-bar badges (multi-cast extras must not stick dark).
            local oorRelated = (state == self.STATE_OUT_OF_RANGE)
                or (cached.state == self.STATE_OUT_OF_RANGE)
            local badgeRelated = button._fluxIsActionBarBadge and true or false
            if not oorRelated and not badgeRelated and (now - cached.time) < 0.05 then
                return
            end
        end
        
        -- Update cache with current state
        visualFeedbackCache[buttonKey] = {
            state = state,
            mana = notEnoughMana,
            time = now
        }
    end
    
    local color
    -- ButtonForge / Bartender4: usable/mana/OOR = vertex color only.
    -- SetDesaturated is reserved for lower-rank colorless (_fluxRankDesaturated).
    
    if state == self.STATE_OUT_OF_RANGE then
        color = self.COLOR_OUT_OF_RANGE
    elseif state == self.STATE_NOT_ENOUGH_MANA then
        color = self.COLOR_MANA
    elseif state == self.STATE_NOT_USABLE then
        color = self.COLOR_UNUSABLE
    elseif state == self.STATE_USABLE then
        color = self.COLOR_USABLE
    elseif state == self.STATE_UNKNOWN then
        -- Prefer last painted state on the button over forced white.
        if button._usabilityState == self.STATE_NOT_ENOUGH_MANA then
            color = self.COLOR_MANA
        elseif button._usabilityState == self.STATE_NOT_USABLE then
            color = self.COLOR_UNUSABLE
        elseif button._usabilityState == self.STATE_OUT_OF_RANGE then
            color = self.COLOR_OUT_OF_RANGE
        else
            color = self.COLOR_USABLE
        end
    else
        color = self.COLOR_USABLE
    end
    
    -- Apply icon color
    if button.WIcon and button.WIcon.SetVertexColor then
        button.WIcon:SetVertexColor(color.r, color.g, color.b)
    end
    
    -- Rank colorless only — never desat for unusable/mana (BF/BT4).
    -- Multi-cast extras: never desat (dead/taxi-look was sticky gray on nomod).
    local extraKey = button._fluxBadgeKey
        or (button.Widget and button.Widget._fluxBadgeKey)
    local isExtraIcon = button._fluxIsMultiCastExtra
        or (type(extraKey) == "string" and extraKey:sub(1, 6) == "extra:")
    if button.WIcon and button.WIcon.SetDesaturated then
        if isExtraIcon then
            button._fluxRankDesaturated = false
            if button.Widget then button.Widget._fluxRankDesaturated = false end
            button.WIcon:SetDesaturated(false)
        elseif button._fluxRankDesaturated then
            button.WIcon:SetDesaturated(true)
        else
            button.WIcon:SetDesaturated(false)
        end
    end
    
    -- Apply ring border color (respects categoryScope for class/character scoped buttons)
    if not button._fluxIsActionBarBadge and button.WNormalTexture and button.WNormalTexture.SetVertexColor then
        -- Check if button has class/character scope that should preserve class color
        local hasClassScope = button.categoryScope and 
            (button.categoryScope == "class" or button.categoryScope == "character")
        
        if hasClassScope then
            -- For class/character scoped buttons: preserve class color, only apply mana color
            if state == self.STATE_NOT_ENOUGH_MANA then
                button.WNormalTexture:SetVertexColor(0.5, 0.5, 1.0)
            end
            -- Otherwise, don't change the color - preserve the class color set by ApplyButtonStyle
        elseif isLegacy then
            -- Legacy client handling for non-class scoped buttons
            if state == self.STATE_NOT_ENOUGH_MANA then
                button.WNormalTexture:SetVertexColor(0.5, 0.5, 1.0)
            else
                button.WNormalTexture:SetVertexColor(1.0, 1.0, 1.0)
            end
        else
            -- Modern client handling for account/realm scoped buttons
            if FluxButtonUtil and FluxButtonUtil.UpdateButtonUsability then
                local classColorActive = FluxButtonUtil.ClassColorSettings and FluxButtonUtil.ClassColorSettings.enabled
                if button.UseClassColor == true then classColorActive = true end
                if button.UseClassColor == false then classColorActive = false end
                
                FluxButtonUtil:UpdateButtonUsability(
                    button,
                    state == self.STATE_USABLE,
                    state == self.STATE_NOT_ENOUGH_MANA,
                    classColorActive
                )
            else
                if state == self.STATE_NOT_ENOUGH_MANA then
                    button.WNormalTexture:SetVertexColor(0.5, 0.5, 1.0)
                else
                    button.WNormalTexture:SetVertexColor(1.0, 1.0, 1.0)
                end
            end
        end
    end
end

-- Update a button's usability and apply visual feedback
function FluxButtonUsability:UpdateButton(button)
    if not button or not button.WIcon then
        return
    end
    
    -- Keep placeholder colorless (rank desat pass must not leave full-color empty slots).
    if button.PlaceholderTexture then
        if not button.IsWispLockPlaceholder then
            button.WIcon:SetTexture(button.PlaceholderTexture)
            button.WIcon:SetDesaturated(true)
            button.WIcon:SetVertexColor(0.25, 0.25, 0.25)
            button.WIcon:Show()
        end
        return
    end

    -- Display-only buttons (e.g. ammo counter): keep icon at full brightness; skip IsUsableItem/range
    if button.IgnoreUsabilityVisual then
        button._isUsable = true
        button._notEnoughMana = false
        button._usabilityState = self.STATE_USABLE
        button._outOfRange = false
        self:ApplyVisualFeedback(button, self.STATE_USABLE, false)
        return self.STATE_USABLE, false, nil
    end

    -- Mana gem: left-click macro is castsequence/use; tint from item charges like other combat items
    if button.IsManaGemButton then
        local itemId = button.ItemId or button._currentGemId
        if itemId then
            local state, notEnoughMana = self:CheckItemUsability(itemId)
            button._isUsable = (state == self.STATE_USABLE or state == self.STATE_UNKNOWN)
            button._notEnoughMana = notEnoughMana or (state == self.STATE_NOT_ENOUGH_MANA)
            button._usabilityState = state
            button._outOfRange = false
            self:ApplyVisualFeedback(button, state, notEnoughMana)
            return state, notEnoughMana, nil
        end
    end
    
    -- Ensure we have valid action data before checking
    local actionType = button.ActionType
    local actionValue = button.ActionValue
    
    -- If no action data, treat as empty (bright)
    if not actionType or not actionValue then
        button.WIcon:SetVertexColor(1, 1, 1)
        if button._fluxRankDesaturated then
            button.WIcon:SetDesaturated(true)
        else
            button.WIcon:SetDesaturated(false)
        end
        button._isUsable = true
        button._notEnoughMana = false
        button._usabilityState = self.STATE_UNKNOWN
        return self.STATE_UNKNOWN, false, nil
    end
    
    local extraData = {
        macroBody = button.MacroBody,
        macroMode = button.MacroMode,
        spellId = button.SpellId,
        spellNameRank = button.SpellNameRank,
        itemId = button.ItemId
    }

    local state, notEnoughMana, extraInfo
    -- Multi-cast extras: never use dual-split aspect (host/peer spell).
    -- Identity is peer-style macrotext + TranslateMacro; only skip aspect stamps.
    local key = button._fluxBadgeKey
        or (button.Widget and button.Widget._fluxBadgeKey)
    local keyIsExtra = type(key) == "string" and key:sub(1, 6) == "extra:"
    local isMultiCastExtra = keyIsExtra
    if not keyIsExtra then
        -- Heal sticky false-positive from earlier builds.
        if button._fluxIsMultiCastExtra then
            button._fluxIsMultiCastExtra = nil
        end
        if button.Widget and button.Widget._fluxIsMultiCastExtra then
            button.Widget._fluxIsMultiCastExtra = nil
        end
    elseif isMultiCastExtra then
        button._fluxIsMultiCastExtra = true
        button._fluxAspectDisplaySpellId = nil
        button._fluxBindingWins = nil
        if button.Widget then
            button.Widget._fluxIsMultiCastExtra = true
            button.Widget._fluxAspectDisplaySpellId = nil
            button.Widget._fluxBindingWins = nil
        end
        -- Prefer want stamps only when TranslateMacro left gaps (same as peers).
        if not button.ItemId and button._fluxWantItemId then
            button.ItemId = button._fluxWantItemId
            button.MacroMode = button.MacroMode or "item"
            extraData.itemId = button.ItemId
        end
        if not button.SpellId and button._fluxWantSpellId then
            button.SpellId = button._fluxWantSpellId
            button.MacroMode = button.MacroMode or "spell"
            extraData.spellId = button.SpellId
        end
        extraData.macroBody = button.MacroBody
        extraData.macroMode = button.MacroMode
        extraData.spellId = button.SpellId or extraData.spellId
        extraData.spellNameRank = button.SpellNameRank
        extraData.itemId = button.ItemId or extraData.itemId
    end
    local aspectId = (not isMultiCastExtra) and tonumber(button._fluxAspectDisplaySpellId) or nil
    local barLegSlot = button._fluxSyncedActionSlot
    local isBarLeg = (not isMultiCastExtra)
        and button._fluxBadgeIconLeg == "bar"
        and type(barLegSlot) == "number" and barLegSlot >= 1

    if isMultiCastExtra then
        -- Multi-cast peeks: same spell/item usable API as Extra buttons / peers.
        -- (Earlier always-dark was a broken `extra:` key match, not IsSpellUsable.)
        -- Skip range only — keep aura/requirement darken (PoM, etc.) via the API.
        button._fluxRankDesaturated = false
        if button.Widget then button.Widget._fluxRankDesaturated = false end
        if button.WIcon and button.WIcon.SetDesaturated then
            button.WIcon:SetDesaturated(false)
        end

        local sid = tonumber(button._fluxWantSpellId or button.SpellId
            or (button.ActionType == "spell" and button.ActionValue))
        local iid = tonumber(button._fluxWantItemId or button.ItemId
            or (button.ActionType == "item" and button.ActionValue))

        if iid and iid > 0 and (button._fluxWantItemId or button.MacroMode == "item"
            or button.ActionType == "item" or not sid) then
            button.ItemId = iid
            button.SpellId = nil
            button.ActionType = "item"
            button.ActionValue = iid
            button.MacroMode = "item"
            state, notEnoughMana = self:CheckItemUsability(iid)
        elseif sid and sid > 0 then
            button.SpellId = sid
            button.ItemId = nil
            button.ActionType = "spell"
            button.ActionValue = sid
            button.MacroMode = "spell"
            if button.Widget then button.Widget.spellID = sid end
            state, notEnoughMana = self:CheckSpellUsability(FormatRankedUsabilityArg(nil, sid))
            if state == self.STATE_UNKNOWN then
                local cached = lastKnownGoodStates["extra_" .. tostring(sid)]
                if cached then
                    state, notEnoughMana = cached.state, cached.mana
                elseif button._usabilityState
                    and button._usabilityState ~= self.STATE_UNKNOWN then
                    state = button._usabilityState
                    notEnoughMana = button._notEnoughMana
                        or (state == self.STATE_NOT_ENOUGH_MANA)
                end
            elseif state then
                lastKnownGoodStates["extra_" .. tostring(sid)] = {
                    state = state,
                    mana = notEnoughMana,
                }
            end
        else
            state = self.STATE_USABLE
            notEnoughMana = false
        end
    elseif aspectId and aspectId > 0 then
        state, notEnoughMana = self:CheckSpellUsability(FormatRankedUsabilityArg(nil, aspectId))
        if state == self.STATE_UNKNOWN then
            local cached = lastKnownGoodStates["aspect_" .. tostring(aspectId)]
            if cached then
                state, notEnoughMana = cached.state, cached.mana
            end
        elseif state then
            lastKnownGoodStates["aspect_" .. tostring(aspectId)] = { state = state, mana = notEnoughMana }
        end
    elseif isBarLeg then
        state, notEnoughMana = self:CheckActionUsability(barLegSlot)
    else
        state, notEnoughMana, extraInfo = self:CheckUsability(actionType, actionValue, extraData)
    end

    -- Action-bar badges (peers): ownership bright when bag/equipped/toy.
    if (not isMultiCastExtra)
        and button._fluxIsActionBarBadge
        and (button.MacroMode == "item" or button.ActionType == "item")
        and button.ItemId
        and (state == self.STATE_NOT_USABLE or state == self.STATE_UNKNOWN) then
        local inv = _G.FluxInv
        local n = 0
        if inv and inv.GetLiveCount then
            n = tonumber(inv.GetLiveCount(button.ItemId, { includeBank = false, charges = true })) or 0
        elseif inv and inv.GetCount then
            n = tonumber(inv.GetCount(button.ItemId, { includeBank = false, charges = true })) or 0
        elseif C_Item and C_Item.GetItemCount then
            n = tonumber(C_Item.GetItemCount(button.ItemId, false, true)) or 0
        elseif GetItemCount then
            n = tonumber(GetItemCount(button.ItemId, false, true)) or 0
        end
        local owned = n > 0
        if not owned then
            if C_Item and C_Item.IsEquippedItem then
                owned = C_Item.IsEquippedItem(button.ItemId) and true or false
            elseif IsEquippedItem then
                owned = IsEquippedItem(button.ItemId) and true or false
            end
        end
        if not owned and PlayerHasToy and PlayerHasToy(button.ItemId) then
            owned = true
        end
        if owned then
            state = self.STATE_USABLE
            notEnoughMana = false
        end
    end

    -- Clear stale mana flag when spell is fully usable.
    if button._fluxIsActionBarBadge
        and (button.MacroMode == "spell" or button.ActionType == "spell" or button.ActionType == "macro")
        and button.SpellId
        and state == self.STATE_USABLE then
        notEnoughMana = false
    end

    -- Secret UNKNOWN with no cache: keep prior button tint instead of forcing white.
    -- Multi-cast extras already resolved above.
    if state == self.STATE_UNKNOWN and not isMultiCastExtra then
        if button._usabilityState
            and button._usabilityState ~= self.STATE_UNKNOWN then
            state = button._usabilityState
            notEnoughMana = button._notEnoughMana
                or (state == self.STATE_NOT_ENOUGH_MANA)
        end
    end
    
    -- If usable, also check range (spells; nil = N/A → clear red)
    -- Corner badges with items: skip range — OOR red looks like "unusable" on peek icons.
    -- Multi-cast extras: same — peeks, not the live cast surface.
    if state == self.STATE_USABLE and self.RangeCheckEnabled
        and not isMultiCastExtra
        and not (button._fluxIsActionBarBadge
            and (button.MacroMode == "item" or button.ActionType == "item" or button.ItemId)) then
        local FR = _G.FluxRange
        local rangeUnit = button._fluxBadgeRangeUnit
        if rangeUnit == "cursor" then
            rangeUnit = nil
        end
        if not rangeUnit and FR and FR.ResolveUnit then
            rangeUnit = FR.ResolveUnit(button)
        end
        local inRange
        local skipRangeApply = false
        if rangeUnit then
            if aspectId and aspectId > 0 then
                inRange = self:CheckSpellRange(aspectId, rangeUnit)
            elseif isBarLeg then
                inRange = self:CheckActionSlotRange(barLegSlot, rangeUnit)
            elseif InCombatLockdown and InCombatLockdown()
                and type(button._fluxSyncedActionSlot) == "number"
                and button._fluxSyncedActionSlot >= 1
                and (button.MacroMode == "item" or button.ActionType == "item") then
                -- IsItemInRange is combat-blocked for friendlies; action-slot range stays legal.
                inRange = self:CheckActionSlotRange(button._fluxSyncedActionSlot, rangeUnit)
            else
                inRange = self:CheckButtonRange(button, rangeUnit)
                -- Combat-skipped item range: keep prior OOR paint (nil would clear red).
                if inRange == nil
                    and (button.MacroMode == "item" or button.ActionType == "item") then
                    local API = FluxAPICompat and FluxAPICompat.API
                    if API and API.CanCheckItemInRange
                        and not API.CanCheckItemInRange(rangeUnit) then
                        skipRangeApply = true
                    end
                end
            end
        else
            inRange = nil
        end
        if FR and FR.Normalize and not skipRangeApply then
            inRange = FR.Normalize(inRange)
        end
        if skipRangeApply then
            if button._outOfRange then
                state = self.STATE_OUT_OF_RANGE
            end
        else
            -- inRange: true = in range, false = out of range, nil = no range check
            if inRange == false then
                state = self.STATE_OUT_OF_RANGE
            end
            button._outOfRange = (inRange == false)
            if FR and FR.ApplyFlag then
                FR.ApplyFlag(button, inRange)
            end
        end
    else
        button._outOfRange = false
        if button.outOfRange ~= nil then
            button.outOfRange = false
        end
    end
    
    -- Store state for reference
    button._usabilityState = state
    button._isUsable = (state == self.STATE_USABLE)
    button._notEnoughMana = notEnoughMana
    
    -- Apply visual feedback
    self:ApplyVisualFeedback(button, state, notEnoughMana)
    
    return state, notEnoughMana, extraInfo
end

-- Export IsTradingSkill as a public method
function FluxButtonUsability:IsTradingSkill(spellIdentifier)
    return IsTradingSkill(spellIdentifier)
end

-- Export
_G.FluxButtonUsability = FluxButtonUsability

