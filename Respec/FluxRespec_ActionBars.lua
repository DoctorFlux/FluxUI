-- FluxRespec_ActionBars.lua
-- Snapshot / restore Flux action-bar slots and stance-bar order on every client.
-- Explicit saved slots are restored after talents, independently of native loadouts.

local addonName, ns = ...

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.ActionBars = R.ActionBars or {}
local ActionBars = R.ActionBars
local Compat = R.Compat

local NUM_COLUMNS = 19
local NUM_NATIVE = 12
local ValidEntry

local function SlotMath()
    local flux = (ns and ns.Flux) or _G.Flux
    local bars = flux and flux.Bars
    return bars and bars.SlotMath
end

local function StanceMod()
    local flux = (ns and ns.Flux) or _G.Flux
    local bars = flux and flux.Bars
    return bars and bars.Stance
end

local function CopyTable(tbl)
    if type(tbl) ~= "table" then
        return nil
    end
    if Compat and Compat.DeepCopy then
        return Compat.DeepCopy(tbl)
    end
    local out = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            out[k] = CopyTable(v)
        else
            out[k] = v
        end
    end
    return out
end

local function InLockdown()
    return InCombatLockdown and InCombatLockdown()
end

--- Unique Blizzard action slots Flux hosts (paged mains, static 13–19, SHIFT/CTRL minis).
function ActionBars.CollectSlots()
    local set = {}
    local SM = SlotMath()
    local transient = {}
    local api = _G.C_ActionBar
    for _, name in ipairs({ "GetVehicleBarIndex", "GetOverrideBarIndex", "GetTempShapeshiftBarIndex", "GetExtraBarIndex" }) do
        if api and api[name] then
            local ok, page = pcall(api[name])
            if ok and type(page) == "number" and page > 0 then transient[page] = true end
        end
    end
    -- Shared MultiActionBars loads pages 13–15 on Retail/Forever/Classic.
    -- Pages 11/12 and vehicle/override/temporary pages are not saved user bars.
    for page = 1, 15 do
        if (page <= 10 or page >= 13) and not transient[page] then
        for col = 1, NUM_NATIVE do
            local slot
            if SM and SM.MainSlot then
                slot = SM.MainSlot(col, page)
            else
                slot = (page - 1) * NUM_NATIVE + col
            end
            if type(slot) == "number" and slot > 0 then
                set[slot] = true
            end
        end
        end
    end
    for col = NUM_NATIVE + 1, NUM_COLUMNS do
        local slot
        if SM and SM.MainSlot then
            slot = SM.MainSlot(col, 0)
        else
            slot = col
        end
        if type(slot) == "number" and slot > 0 then
            set[slot] = true
        end
    end
    for col = 1, NUM_COLUMNS do
        local sec, tert
        if SM and SM.SecondarySlot then
            sec = SM.SecondarySlot(col)
        else
            sec = (col <= NUM_NATIVE) and (60 + col) or (48 + (col - NUM_NATIVE))
        end
        if SM and SM.TertiarySlot then
            tert = SM.TertiarySlot(col)
        else
            tert = (col <= NUM_NATIVE) and (24 + col) or (36 + (col - NUM_NATIVE))
        end
        if type(sec) == "number" and sec > 0 then
            set[sec] = true
        end
        if type(tert) == "number" and tert > 0 then
            set[tert] = true
        end
    end
    return set
end

local function SortedSlots(set)
    local list = {}
    for slot in pairs(set) do
        list[#list + 1] = slot
    end
    table.sort(list)
    return list
end

local function CaptureSlot(slot)
    if not GetActionInfo then
        return { empty = true }, false
    end
    local ok, actionType, id, subType = pcall(GetActionInfo, slot)
    if not ok then
        return { empty = true }, false
    end
    if _G.issecretvalue and (_G.issecretvalue(actionType) or _G.issecretvalue(id) or _G.issecretvalue(subType)) then
        return nil, false
    end
    if not actionType or actionType == "" then
        return { empty = true }, true
    end
    if type(actionType) ~= "string" or id == nil then return nil, false end
    local entry = {
        type = actionType,
        id = id,
        subType = subType,
    }
    if actionType == "macro" then
        if GetMacroInfo and id then
            local readOK, name, icon, body = pcall(GetMacroInfo, id)
            if not readOK or not name then return nil, false end
            entry.name = name
            entry.icon = icon
            entry.body = body
        elseif GetActionText then
            local readOK, name = pcall(GetActionText, slot)
            if not readOK then return nil, false end
            entry.name = name
        end
    elseif actionType == "equipmentset" then
        if type(id) == "number" and C_EquipmentSet and C_EquipmentSet.GetEquipmentSetInfo then
            local readOK, n = pcall(C_EquipmentSet.GetEquipmentSetInfo, id)
            if not readOK or not n then return nil, false end
            entry.name = n
        elseif GetActionText then
            local readOK, name = pcall(GetActionText, slot)
            if not readOK then return nil, false end
            entry.name = name
        end
    elseif GetActionText then
        local readOK, text = pcall(GetActionText, slot)
        if not readOK then return nil, false end
        if type(text) == "string" and text ~= "" then
            entry.text = text
        end
    end
    return entry, true
end

local function EntriesMatch(a, b)
    a = a or { empty = true }
    b = b or { empty = true }
    local aEmpty = a.empty == true or not a.type
    local bEmpty = b.empty == true or not b.type
    if aEmpty and bEmpty then
        return true
    end
    if aEmpty or bEmpty then
        return false
    end
    local aMount = a.type == "mount" or a.type == "summonmount"
    local bMount = b.type == "mount" or b.type == "summonmount"
    if aMount and bMount then return a.id == b.id end
    if a.type ~= b.type then
        -- Placing a collected mount via its spell can expose either descriptor.
        local mount, spell = aMount and a or bMount and b, a.type == "spell" and a or b.type == "spell" and b
        if mount and spell and _G.C_MountJournal and _G.C_MountJournal.GetMountInfoByID then
            local _, spellID = _G.C_MountJournal.GetMountInfoByID(mount.id)
            return spellID ~= nil and spell.id == spellID
        end
        return false
    end
    if a.type == "macro" then
        if a.name and b.name then
            return a.name == b.name and (not a.body or not b.body or a.body == b.body)
        end
        return a.id == b.id
    end
    if a.type == "equipmentset" then
        if a.name and b.name then
            return a.name == b.name
        end
        return a.id == b.id
    end
    return a.id == b.id and a.subType == b.subType
end

local function StanceMapsEqual(a, b)
    a = a or {}
    b = b or {}
    if type(a) ~= "table" or type(b) ~= "table" then
        return a == b
    end
    -- Array-style order
    local aLen = #a
    local bLen = #b
    if aLen > 0 or bLen > 0 then
        if aLen ~= bLen then
            return false
        end
        for i = 1, aLen do
            if a[i] ~= b[i] then
                return false
            end
        end
        return true
    end
    for k, v in pairs(a) do
        if (b[k] and true or false) ~= (v and true or false) and b[k] ~= v then
            return false
        end
    end
    for k, v in pairs(b) do
        if (a[k] and true or false) ~= (v and true or false) and a[k] ~= v then
            return false
        end
    end
    return true
end

local function CustomEntryKey(entry)
    if type(entry) ~= "table" or not entry.type or entry.id == nil then
        return nil
    end
    local id = entry.id
    if entry.type == "macro" then
        id = entry.name or entry.id
    end
    return tostring(entry.type) .. "\0" .. tostring(id)
end

local function CustomListsEqual(a, b)
    if type(a) ~= "table" then
        a = {}
    end
    if type(b) ~= "table" then
        b = {}
    end
    if #a ~= #b then
        return false
    end
    for i = 1, #a do
        if CustomEntryKey(a[i]) ~= CustomEntryKey(b[i]) then
            return false
        end
    end
    return true
end

local function StanceSpellKey(spellId)
    return "custom:spell:" .. tostring(spellId)
end

--- Rewrite one saved stance snapshot from an old spell rank to the highest rank.
function ActionBars.RewriteStanceSpellId(snap, oldId, newId, newName)
    if type(snap) ~= "table" then
        return false
    end
    oldId = tonumber(oldId)
    newId = tonumber(newId)
    if not oldId or not newId or oldId == newId then
        return false
    end
    local oldKey = StanceSpellKey(oldId)
    local newKey = StanceSpellKey(newId)
    local changed = false
    local newExists = false
    local list = snap.stanceCustomSlots
    if type(list) == "table" then
        for i = 1, #list do
            local entry = list[i]
            if type(entry) == "table" and entry.type == "spell" and tonumber(entry.id) == newId then
                newExists = true
                break
            end
        end
        if newExists then
            for i = #list, 1, -1 do
                local entry = list[i]
                if type(entry) == "table" and entry.type == "spell" and tonumber(entry.id) == oldId then
                    table.remove(list, i)
                    changed = true
                end
            end
        else
            for i = 1, #list do
                local entry = list[i]
                if type(entry) == "table" and entry.type == "spell" and tonumber(entry.id) == oldId then
                    entry.id = newId
                    if type(newName) == "string" and newName ~= "" then
                        entry.name = newName
                    end
                    changed = true
                end
            end
        end
    end
    local order = snap.stanceSlotOrder
    if type(order) == "table" then
        local out = {}
        local seen = {}
        for i = 1, #order do
            local key = order[i]
            if key == oldKey then
                changed = true
                key = newExists and nil or newKey
            end
            if type(key) == "string" and key ~= "" and not seen[key] then
                seen[key] = true
                out[#out + 1] = key
            end
        end
        snap.stanceSlotOrder = out
    end
    local hidden = snap.stanceHiddenSlots
    if type(hidden) == "table" and hidden[oldKey] then
        if not newExists then
            hidden[newKey] = true
        end
        hidden[oldKey] = nil
        changed = true
    end
    return changed
end

--- Every respec profile, and every rune-preset bar bundle, that saved this stance spell.
function ActionBars.RewriteSavedStanceSpellId(oldId, newId, newName)
    local changed = 0
    local R = _G.FluxRespec
    if R and R.GetProfileNames and R.GetProfile then
        local names = R.GetProfileNames()
        for i = 1, #names do
            local profile = R.GetProfile(names[i])
            if profile and ActionBars.RewriteStanceSpellId(profile.bars, oldId, newId, newName) then
                changed = changed + 1
            end
        end
    end
    local Presets = R and R.RunePresets
    if Presets and Presets.GetPresetNames and Presets.GetPreset then
        local names = Presets.GetPresetNames()
        for i = 1, #names do
            local preset = Presets.GetPreset(names[i])
            local groups = preset and preset.barsByGroup
            if type(groups) == "table" then
                for _, bars in pairs(groups) do
                    if ActionBars.RewriteStanceSpellId(bars, oldId, newId, newName) then
                        changed = changed + 1
                    end
                end
            end
        end
    end
    return changed
end

function ActionBars.CaptureStanceLayout()
    local Stance = StanceMod()
    local order, hidden, custom
    if Stance then
        if Stance.GetSavedOrder then
            order = CopyTable(Stance.GetSavedOrder())
        end
        if Stance.GetHiddenSlots then
            hidden = CopyTable(Stance.GetHiddenSlots())
        end
        if Stance.GetSavedCustomSlots then
            custom = CopyTable(Stance.GetSavedCustomSlots())
        end
    end
    return {
        slots = nil,
        stanceSlotOrder = order,
        stanceHiddenSlots = hidden,
        stanceCustomSlots = custom or {},
    }
end

function ActionBars.ApplyStanceLayout(snap)
    if type(snap) ~= "table" then
        return false
    end
    if snap.stanceSlotOrder == nil and snap.stanceHiddenSlots == nil and snap.stanceCustomSlots == nil then return true end
    local Stance = StanceMod()
    if not Stance then
        return false
    end
    if snap.stanceSlotOrder and Stance.SetSavedOrder then
        if Stance.SetSavedOrder(CopyTable(snap.stanceSlotOrder)) == false then return false end
    end
    if type(snap.stanceHiddenSlots) == "table" then
        local cab
        if FluxOptions and FluxOptions.db and FluxOptions.db.char then
            FluxOptions.db.char.actionbars = FluxOptions.db.char.actionbars or {}
            cab = FluxOptions.db.char.actionbars
        end
        if cab then
            cab.stanceBarHiddenSlots = CopyTable(snap.stanceHiddenSlots) or {}
        elseif Stance.SetSlotHidden then
            local current = Stance.GetHiddenSlots and Stance.GetHiddenSlots() or {}
            for key in pairs(current) do
                if Stance.SetSlotHidden(key, false) == false then return false end
            end
            for key, hidden in pairs(snap.stanceHiddenSlots) do
                if hidden then
                    if Stance.SetSlotHidden(key, true) == false then return false end
                end
            end
        end
    end
    if snap.stanceCustomSlots ~= nil and Stance.SetSavedCustomSlots then
        local list = snap.stanceCustomSlots
        if type(list) ~= "table" then
            list = {}
        end
        if Stance.SetSavedCustomSlots(CopyTable(list) or {}) == false then return false end
    end
    if Stance.RequestLayout then
        if Stance.RequestLayout("respec") == false then return false end
    end
    return true
end

function ActionBars.Capture()
    if R.Apply and R.Apply.IsRunning and R.Apply.IsRunning() then return nil, "ACTION_BARS_APPLY_PENDING" end
    if InLockdown() then return nil, "IN_COMBAT" end
    if not GetCursorInfo then return nil, "ACTION_BARS_CURSOR_UNAVAILABLE" end
    local cursorOK, cursorType = pcall(GetCursorInfo)
    if not cursorOK then return nil, "ACTION_BARS_CURSOR_FAILED" end
    if cursorType ~= nil then return nil, "ACTION_BARS_CURSOR_BUSY" end
    local slots = {}
    for _, slot in ipairs(SortedSlots(ActionBars.CollectSlots())) do
        local called, entry, readable = pcall(CaptureSlot, slot)
        if not called or not readable then return nil, "ACTION_BARS_READ_FAILED" end
        if not ValidEntry(entry) then return nil, "ACTION_BARS_UNSUPPORTED_ACTION" end
        slots[slot] = entry
    end
    local stance = ActionBars.CaptureStanceLayout()
    return {
        slots = slots,
        stanceSlotOrder = stance.stanceSlotOrder,
        stanceHiddenSlots = stance.stanceHiddenSlots,
        stanceCustomSlots = stance.stanceCustomSlots,
    }
end

local function Pickup(fn, ...)
    local called, result = pcall(fn, ...)
    return called and result ~= false
end

local function PositiveID(id)
    return type(id) == "number" and id > 0 and id < math.huge and id == math.floor(id)
end

-- Missing/malformed entries are never shorthand for a saved empty slot.
ValidEntry = function(entry)
    if type(entry) ~= "table" then return false end
    if entry.name ~= nil and type(entry.name) ~= "string" then return false end
    if entry.body ~= nil and type(entry.body) ~= "string" then return false end
    if entry.subType ~= nil and type(entry.subType) ~= "string" then return false end
    if entry.empty == true then return entry.type == nil and entry.id == nil end
    if entry.empty ~= nil and entry.empty ~= false then return false end
    local t, id = entry.type, entry.id
    if t == "summonpet" or t == "battlepet" then return type(id) == "string" and id ~= "" end
    if t == "equipmentset" or t == "mount" or t == "summonmount" then return id == 0 or PositiveID(id) end
    if t == "spell" or t == "item" or t == "macro" or t == "mount" or t == "companion" or t == "flyout" or t == "outfit" then
        return PositiveID(id)
    end
    return false
end

local function ValidSnapshot(snap)
    if type(snap) ~= "table" or (snap.slots ~= nil and type(snap.slots) ~= "table") then return false end
    for _, key in ipairs({ "stanceSlotOrder", "stanceHiddenSlots", "stanceCustomSlots" }) do
        if snap[key] ~= nil and type(snap[key]) ~= "table" then return false end
    end
    if snap.slots then
        for slot, entry in pairs(snap.slots) do
            -- Older snapshots included temporary pages through slot 216. Keep
            -- those snapshots readable, but never restore their temporary slots.
            if not PositiveID(slot) or slot > 216 or not ValidEntry(entry) then return false end
        end
    end
    return true
end

local function CursorEmpty()
    if not GetCursorInfo then return false end
    local ok, kind = pcall(GetCursorInfo)
    return ok and kind == nil
end

-- Resolve identities that Blizzard may renumber, without falling back to a
-- reused numeric macro/equipment index when a saved name no longer exists.
local function ResolveEntry(entry)
    local out = CopyTable(entry)
    if out.type == "macro" and out.name then
        if not GetMacroIndexByName or not GetMacroInfo then return nil end
        local function matches(id)
            if not PositiveID(id) then return false end
            local name, _, body = GetMacroInfo(id)
            return name == out.name and (out.body == nil or body == out.body)
        end
        local id = matches(out.id) and out.id or GetMacroIndexByName(out.name)
        if not matches(id) and _G.GetNumMacros then
            local account, character = _G.GetNumMacros()
            id = nil
            for candidate = 1, account do
                if matches(candidate) then id = candidate; break end
            end
            if not id then
                local constants = _G.Constants and _G.Constants.MacroConsts
                local base = constants and constants.MAX_ACCOUNT_MACROS or _G.MAX_ACCOUNT_MACROS or 120
                for candidate = base + 1, base + character do
                    if matches(candidate) then id = candidate; break end
                end
            end
        end
        if not matches(id) then return nil end
        out.id = id
    elseif out.type == "equipmentset" and out.name then
        local api = _G.C_EquipmentSet
        if not api or not api.GetEquipmentSetInfo then return nil end
        local found
        if api.GetEquipmentSetIDs then
            for _, id in ipairs(api.GetEquipmentSetIDs() or {}) do
                if api.GetEquipmentSetInfo(id) == out.name then found = id; break end
            end
        elseif api.GetEquipmentSetInfo(out.id) == out.name then
            found = out.id
        end
        if found == nil then return nil end
        out.id = found
    elseif out.type == "flyout" then
        local book = _G.C_SpellBook
        local bank = _G.Enum and _G.Enum.SpellBookSpellBank and _G.Enum.SpellBookSpellBank.Player
        if book and book.GetNumSpellBookSkillLines and book.GetSpellBookSkillLineInfo and book.GetSpellBookItemInfo and bank then
            for tab = 1, book.GetNumSpellBookSkillLines() do
                local info = book.GetSpellBookSkillLineInfo(tab)
                if info then
                    for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                        local item = book.GetSpellBookItemInfo(slot, bank)
                        local flyout = _G.Enum.SpellBookItemType and _G.Enum.SpellBookItemType.Flyout
                        if item and item.itemType == flyout and item.actionID == out.id then
                            out.bookSlot, out.bookBank, out.modernBook = slot, bank, true
                            return out
                        end
                    end
                end
            end
        elseif _G.GetNumSpellTabs and _G.GetSpellTabInfo and _G.GetSpellBookItemInfo then
            for tab = 1, _G.GetNumSpellTabs() do
                local _, _, offset, count = _G.GetSpellTabInfo(tab)
                for slot = offset + 1, offset + count do
                    local kind, id = _G.GetSpellBookItemInfo(slot, _G.BOOKTYPE_SPELL or "spell")
                    if kind == "FLYOUT" and id == out.id then
                        out.bookSlot, out.bookBank = slot, _G.BOOKTYPE_SPELL or "spell"
                        return out
                    end
                end
            end
        end
        return nil
    elseif (out.type == "mount" or out.type == "summonmount") and out.id == 0 then
        -- Native journal uses Pickup(0) for the random-favorite mount action.
        if not (_G.C_MountJournal and _G.C_MountJournal.Pickup) then return nil end
    elseif (out.type == "mount" or out.type == "summonmount") and _G.C_MountJournal and _G.C_MountJournal.GetMountInfoByID then
        local _, spellID = _G.C_MountJournal.GetMountInfoByID(out.id)
        if not PositiveID(spellID) then return nil end
        out.mountSpellID = spellID
    end
    return out
end

local function CursorMatches(entry)
    if not GetCursorInfo then return false end
    local ok, kind, id, subType, spellID = pcall(GetCursorInfo)
    if not ok or not kind then return false end
    if _G.issecretvalue and (_G.issecretvalue(kind) or _G.issecretvalue(id) or _G.issecretvalue(spellID)) then return false end
    if entry.type == "spell" then
        return kind == "spell" and spellID == entry.id
    end
    if entry.type == "summonpet" or entry.type == "battlepet" then
        return (kind == "summonpet" or kind == "battlepet") and id == entry.id
    end
    if entry.type == "mount" or entry.type == "summonmount" then
        if kind == "spell" then return spellID ~= nil and spellID == entry.mountSpellID end
        return (kind == "mount" or kind == "summonmount") and id == entry.id
    end
    return kind == entry.type and id == entry.id
end

local function PickupForEntry(entry)
    if not entry or entry.empty or not entry.type then
        return false
    end
    local t = entry.type
    local id = entry.id
    if t == "spell" then
        if _G.C_Spell and _G.C_Spell.PickupSpell and id then
            return Pickup(_G.C_Spell.PickupSpell, id)
        end
        if _G.PickupSpell and id then
            return Pickup(_G.PickupSpell, id)
        end
    elseif t == "item" then
        if _G.C_Item and _G.C_Item.PickupItem and id then
            return Pickup(_G.C_Item.PickupItem, id)
        end
        if _G.PickupItem and id then
            return Pickup(_G.PickupItem, id)
        end
    elseif t == "macro" then
        if id and _G.PickupMacro then
            return Pickup(_G.PickupMacro, id)
        end
    elseif t == "equipmentset" then
        local setID = id
        if (not setID or setID == 0) and entry.name and C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID then
            setID = C_EquipmentSet.GetEquipmentSetID(entry.name)
        end
        if setID and C_EquipmentSet and C_EquipmentSet.PickupEquipmentSet then
            return Pickup(C_EquipmentSet.PickupEquipmentSet, setID)
        end
    elseif t == "outfit" and _G.C_TransmogOutfitInfo and _G.C_TransmogOutfitInfo.PickupOutfit then
        return Pickup(_G.C_TransmogOutfitInfo.PickupOutfit, id)
    elseif (t == "mount" or t == "summonmount") and id then
        -- MountJournal.Pickup expects a filtered DISPLAY INDEX, not mountID.
        if id == 0 and _G.C_MountJournal and _G.C_MountJournal.Pickup then
            return Pickup(_G.C_MountJournal.Pickup, 0)
        elseif entry.mountSpellID and _G.C_Spell and _G.C_Spell.PickupSpell then
            return Pickup(_G.C_Spell.PickupSpell, entry.mountSpellID)
        elseif entry.mountSpellID and _G.PickupSpell then
            return Pickup(_G.PickupSpell, entry.mountSpellID)
        end
    elseif t == "companion" and id then
        if _G.PickupCompanion then
            return Pickup(_G.PickupCompanion, entry.subType or "MOUNT", id)
        end
    elseif t == "flyout" and entry.bookSlot then
        if entry.modernBook and _G.C_SpellBook and _G.C_SpellBook.PickupSpellBookItem then
            return Pickup(_G.C_SpellBook.PickupSpellBookItem, entry.bookSlot, entry.bookBank)
        elseif _G.PickupSpellBookItem then
            return Pickup(_G.PickupSpellBookItem, entry.bookSlot, entry.bookBank)
        end
    elseif t == "summonpet" or t == "battlepet" then
        if _G.C_PetJournal and _G.C_PetJournal.PickupPet and id then
            return Pickup(_G.C_PetJournal.PickupPet, id)
        end
    end
    return false
end

-- Slot APIs do not report completion through a return value. Check the public
-- slot state after each operation instead of treating a successful pcall as a
-- restored action. A partial restore is retryable through the load checkpoint.
local function ClearSlot(slot, previous)
    if not PickupAction or not ClearCursor then
        return false, "ACTION_BARS_API_UNAVAILABLE"
    end
    if not CursorEmpty() then return false, "ACTION_BARS_CURSOR_BUSY" end
    local ok = pcall(PickupAction, slot)
    local live, readable = CaptureSlot(slot)
    if not ok or not readable or not live.empty or not CursorMatches(previous) then return false, "ACTION_BARS_CLEAR_FAILED" end
    if InLockdown() then return false, "ACTION_BARS_STATE_CHANGED" end
    if not pcall(ClearCursor) then return false, "ACTION_BARS_CLEAR_FAILED" end
    live, readable = CaptureSlot(slot)
    return readable and live.empty == true, "ACTION_BARS_CLEAR_FAILED"
end

local function PlaceEntryOnSlot(slot, entry)
    local live, readable = CaptureSlot(slot)
    if not readable then return false, "ACTION_BARS_READ_FAILED" end
    if EntriesMatch(live, entry) then return true end
    if entry.empty == true then
        return ClearSlot(slot, live)
    end
    if not PlaceAction or not ClearCursor then
        return false, "ACTION_BARS_API_UNAVAILABLE"
    end
    if not CursorEmpty() then return false, "ACTION_BARS_CURSOR_BUSY" end
    if InLockdown() then return false, "ACTION_BARS_STATE_CHANGED" end
    local previous = live
    if not PickupForEntry(entry) or not CursorMatches(entry) then
        if not InLockdown() and CursorMatches(entry) then pcall(ClearCursor) end
        return false, "ACTION_BARS_PICKUP_FAILED"
    end
    live, readable = CaptureSlot(slot)
    if InLockdown() or not readable or not EntriesMatch(live, previous) then
        if not InLockdown() and CursorMatches(entry) then pcall(ClearCursor) end
        return false, "ACTION_BARS_STATE_CHANGED"
    end
    local placed = pcall(PlaceAction, slot)
    live, readable = CaptureSlot(slot)
    if not placed or not readable or not EntriesMatch(live, entry) then
        -- Do not discard a displaced live action when placement failed. A
        -- successful placement is the only path allowed to clear that cursor.
        return false, "ACTION_BARS_VERIFY_FAILED"
    end
    if InLockdown() then return false, "ACTION_BARS_STATE_CHANGED" end
    if not CursorEmpty() then
        -- Placement may run callbacks. Only retire our selected/displaced
        -- payload; a different cursor belongs to its new owner.
        if not CursorMatches(previous) and not CursorMatches(entry) then return false, "ACTION_BARS_CURSOR_CHANGED" end
        if not pcall(ClearCursor) then return false, "ACTION_BARS_CURSOR_FAILED" end
    end
    return true
end

local pendingApply
local latestApply
local combatWatcher

local function StopCombatWatcher()
    if not combatWatcher then return end
    combatWatcher:UnregisterAllEvents()
    combatWatcher:SetScript("OnEvent", nil)
end

local function Complete(request, ok, reason)
    if request.completed then return end
    request.completed = true
    if latestApply == request then latestApply = nil end
    if request.callback then request.callback(ok, reason) end
end

-- A callback is also the request's owner, just as with deferred spell bindings.
-- Cancelling one profile must not remove another caller's pending restore.
function ActionBars.CancelPendingApply(callback)
    local request = pendingApply
    if not request or (callback and request.callback ~= callback) then return false end
    pendingApply = nil
    StopCombatWatcher()
    Complete(request, false, "CANCELLED")
    return true
end

local function ApplyNow(snap)
    if not ValidSnapshot(snap) then return false, "ACTION_BARS_INVALID_SNAPSHOT" end
    if ActionBars.MatchesSnapshot(snap) then return true end
    if type(snap.slots) == "table" then
        local owned = ActionBars.CollectSlots()
        local slots = {}
        for slot, entry in pairs(snap.slots) do if owned[slot] then slots[slot] = entry end end
        local order = SortedSlots(slots)
        local entries = {}
        -- Resolve and read the complete requested set before clearing any slot.
        for i = 1, #order do
            local slot = order[i]
            local live, readable = CaptureSlot(slot)
            if not readable then return false, "ACTION_BARS_READ_FAILED" end
            local entry = ResolveEntry(snap.slots[slot])
            if not entry then return false, "ACTION_BARS_IDENTITY_UNAVAILABLE" end
            entries[slot] = entry
            if not EntriesMatch(live, entry) and not CursorEmpty() then return false, "ACTION_BARS_CURSOR_BUSY" end
        end
        for i = 1, #order do
            local slot = order[i]
            local called, ok, reason = pcall(PlaceEntryOnSlot, slot, entries[slot])
            if not called then return false, "ACTION_BARS_SLOT_FAILED" end
            if not ok then return false, reason end
        end
    end
    local called, ok = pcall(ActionBars.ApplyStanceLayout, snap)
    if not called or not ok then return false, "ACTION_BARS_STANCE_FAILED" end
    return true
end

local function RunRequest(request)
    local called, ok, reason = pcall(ApplyNow, request.snapshot)
    if not called then ok, reason = false, "ACTION_BARS_READ_FAILED" end
    Complete(request, ok, reason)
    return ok, reason
end

function ActionBars.Apply(snap, callback)
    if not ValidSnapshot(snap) then
        if callback then callback(false, "ACTION_BARS_INVALID_SNAPSHOT") end
        return false, "ACTION_BARS_INVALID_SNAPSHOT"
    end
    -- Detach nested slots/order/custom entries from the editable saved profile.
    local request = { snapshot = CopyTable(snap), callback = callback }
    latestApply = request
    if pendingApply then
        local previous = pendingApply
        pendingApply = nil
        StopCombatWatcher()
        Complete(previous, false, "SUPERSEDED")
    end
    -- A superseded caller can synchronously issue a newer request from its
    -- completion callback. That newer request retains ownership of the queue.
    if latestApply ~= request then
        Complete(request, false, "SUPERSEDED")
        return false, "SUPERSEDED"
    end
    if InLockdown() then
        pendingApply = request
        -- WoW frames cannot be destroyed. Reuse one dormant watcher across
        -- cancelled/repeated loads instead of allocating one per request.
        combatWatcher = combatWatcher or CreateFrame("Frame")
        combatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
        combatWatcher:SetScript("OnEvent", function()
            if pendingApply ~= request then return end -- a cancelled/superseded event owns no work
            if InLockdown() then return end
            local pending = pendingApply
            pendingApply = nil
            StopCombatWatcher()
            if pending then RunRequest(pending) end
        end)
        if R.Print then R.Print("In combat: action bars will apply when combat ends.") end
        return false, "IN_COMBAT"
    end
    return RunRequest(request)
end

function ActionBars.MatchesSnapshot(snap)
    if type(snap) ~= "table" then
        return true
    end
    if not ValidSnapshot(snap) then return false end
    if type(snap.slots) == "table" then
        local owned = ActionBars.CollectSlots()
        for slot, want in pairs(snap.slots) do
            if owned[slot] then
            local live, readable = CaptureSlot(slot)
            if not readable or not EntriesMatch(live, want) then
                return false
            end
            end
        end
    end
    local liveStance = ActionBars.CaptureStanceLayout()
    if snap.stanceSlotOrder ~= nil and not StanceMapsEqual(liveStance.stanceSlotOrder, snap.stanceSlotOrder) then
        return false
    end
    if snap.stanceHiddenSlots ~= nil and not StanceMapsEqual(liveStance.stanceHiddenSlots, snap.stanceHiddenSlots) then
        return false
    end
    if snap.stanceCustomSlots ~= nil and not CustomListsEqual(liveStance.stanceCustomSlots, snap.stanceCustomSlots) then
        return false
    end
    return true
end

function ActionBars.FilledCount(snap)
    if type(snap) ~= "table" or type(snap.slots) ~= "table" then
        return 0
    end
    local n = 0
    for _, entry in pairs(snap.slots) do
        if type(entry) == "table" and not entry.empty and entry.type then
            n = n + 1
        end
    end
    return n
end

R.ActionBars = ActionBars
