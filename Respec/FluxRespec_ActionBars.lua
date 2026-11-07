-- FluxRespec_ActionBars.lua
-- Snapshot / restore Flux action-bar slots (Classic) and stance-bar order (all clients).
-- Retail/Forever talent loadouts own slots 1–120; Capture then only stores stance layout.

local addonName, ns = ...

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.ActionBars = R.ActionBars or {}
local ActionBars = R.ActionBars
local Compat = R.Compat

local NUM_COLUMNS = 19
local NUM_NATIVE = 12

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

local function MaxActionPage()
    local n = tonumber(_G.NUM_ACTIONBAR_PAGES)
    if type(n) == "number" and n > 0 then
        return math.max(n, 10)
    end
    return 18
end

--- Unique Blizzard action slots Flux hosts (paged mains, static 13–19, SHIFT/CTRL minis).
function ActionBars.CollectSlots()
    local set = {}
    local SM = SlotMath()
    local maxPage = MaxActionPage()
    for page = 1, maxPage do
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
    if not actionType or actionType == "" then
        return { empty = true }, true
    end
    local entry = {
        type = actionType,
        id = id,
        subType = subType,
    }
    if actionType == "macro" then
        if GetMacroInfo and id then
            local name, icon, body = GetMacroInfo(id)
            entry.name = name
            entry.icon = icon
            entry.body = body
        elseif GetActionText then
            entry.name = GetActionText(slot)
        end
    elseif actionType == "equipmentset" then
        if type(id) == "number" and C_EquipmentSet and C_EquipmentSet.GetEquipmentSetInfo then
            local n = C_EquipmentSet.GetEquipmentSetInfo(id)
            entry.name = n
        elseif GetActionText then
            entry.name = GetActionText(slot)
        end
    elseif GetActionText then
        local text = GetActionText(slot)
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
    if a.type ~= b.type then
        return false
    end
    if a.type == "macro" then
        if a.name and b.name then
            return a.name == b.name
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
    if Stance.SetSavedCustomSlots then
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
    local skipSlots = Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts()
    if skipSlots then
        return ActionBars.CaptureStanceLayout()
    end
    local slots = {}
    for _, slot in ipairs(SortedSlots(ActionBars.CollectSlots())) do
        slots[slot] = CaptureSlot(slot)
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
        local name = entry.name
        if name and _G.GetMacroIndexByName then
            local idx = _G.GetMacroIndexByName(name)
            if idx and idx > 0 and _G.PickupMacro then
                return Pickup(_G.PickupMacro, idx)
            end
        end
        if name and _G.PickupMacro then
            return Pickup(_G.PickupMacro, name)
        end
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
    elseif t == "mount" and id then
        if _G.C_MountJournal and _G.C_MountJournal.Pickup then
            return Pickup(_G.C_MountJournal.Pickup, id)
        end
    elseif t == "companion" and id then
        if _G.PickupCompanion then
            return Pickup(_G.PickupCompanion, entry.subType or "MOUNT", id)
        end
    elseif t == "flyout" and id and _G.PickupSpell then
        return Pickup(_G.PickupSpell, id)
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
local function ClearSlot(slot)
    if not PickupAction or not ClearCursor then
        return false, "ACTION_BARS_API_UNAVAILABLE"
    end
    local ok = pcall(PickupAction, slot)
    local cleared = pcall(ClearCursor)
    if not ok or not cleared then return false, "ACTION_BARS_CLEAR_FAILED" end
    local live, readable = CaptureSlot(slot)
    return readable and live.empty == true, "ACTION_BARS_CLEAR_FAILED"
end

local function PlaceEntryOnSlot(slot, entry)
    local live, readable = CaptureSlot(slot)
    if not readable then return false, "ACTION_BARS_READ_FAILED" end
    if EntriesMatch(live, entry) then return true end
    if not entry or entry.empty or not entry.type then
        return ClearSlot(slot)
    end
    if not PlaceAction or not ClearCursor then
        return false, "ACTION_BARS_API_UNAVAILABLE"
    end
    if (CursorHasItem and CursorHasItem()) or (GetCursorInfo and GetCursorInfo()) then
        if not pcall(ClearCursor) then return false, "ACTION_BARS_CURSOR_FAILED" end
    end
    if not PickupForEntry(entry) then
        pcall(ClearCursor)
        return false, "ACTION_BARS_PICKUP_FAILED"
    end
    local placed = pcall(PlaceAction, slot)
    local cleared = pcall(ClearCursor)
    if not placed or not cleared then return false, "ACTION_BARS_PLACE_FAILED" end
    live, readable = CaptureSlot(slot)
    if not readable or not EntriesMatch(live, entry) then
        return false, "ACTION_BARS_VERIFY_FAILED"
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
    local skipSlots = Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts()
    if not skipSlots and type(snap.slots) == "table" then
        local order = SortedSlots(snap.slots)
        for i = 1, #order do
            local slot = order[i]
            local called, ok, reason = pcall(PlaceEntryOnSlot, slot, snap.slots[slot])
            if not called then return false, "ACTION_BARS_SLOT_FAILED" end
            if not ok then return false, reason end
        end
    end
    local called, ok = pcall(ActionBars.ApplyStanceLayout, snap)
    if not called or not ok then return false, "ACTION_BARS_STANCE_FAILED" end
    return true
end

local function RunRequest(request)
    local ok, reason = ApplyNow(request.snapshot)
    Complete(request, ok, reason)
    return ok, reason
end

function ActionBars.Apply(snap, callback)
    if type(snap) ~= "table" then
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
    local skipSlots = Compat and Compat.HasTalentLoadouts and Compat.HasTalentLoadouts()
    if not skipSlots and type(snap.slots) == "table" then
        for slot, want in pairs(snap.slots) do
            local live, readable = CaptureSlot(slot)
            if not readable or not EntriesMatch(live, want) then
                return false
            end
        end
    end
    local liveStance = ActionBars.CaptureStanceLayout()
    if not StanceMapsEqual(liveStance.stanceSlotOrder, snap.stanceSlotOrder) then
        return false
    end
    if not StanceMapsEqual(liveStance.stanceHiddenSlots, snap.stanceHiddenSlots) then
        return false
    end
    if not CustomListsEqual(liveStance.stanceCustomSlots, snap.stanceCustomSlots) then
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
