-- FluxRespec_AtieshDualSpecFix.lua
-- On dual-spec change: unequip Atiesh once when the swap starts, re-equip once when it
-- finishes or the swap cast is interrupted. Never runs on login.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.AtieshDualSpecFix = R.AtieshDualSpecFix or {}
local Fix = R.AtieshDualSpecFix
local Compat = R.Compat

local INVSLOT_MAINHAND = _G.INVSLOT_MAINHAND or 16
local SESSION_TIMEOUT = 8

local ATIESH_ITEM_IDS = {
    [22589] = true, -- Mage
    [22630] = true, -- Priest
    [22631] = true, -- Warlock
    [22632] = true, -- Druid
}

local session = nil
local hooksInstalled = false
local playerReady = false
local finishScheduled = false
local timeoutTimer = nil

local function GetCharacterBagIDs()
    local inv = R.Inv
    if inv and inv.GetBagIDs then
        return inv.GetBagIDs()
    end
    local NUM_BAG_SLOTS = _G.NUM_BAG_SLOTS or 4
    local ids = {}
    for bag = 0, NUM_BAG_SLOTS do
        ids[#ids + 1] = bag
    end
    return ids
end

local function GetActiveGroup()
    if Compat and Compat.GetActiveGroup then
        return Compat.GetActiveGroup()
    end
    if _G.GetActiveTalentGroup then
        local ok, g = pcall(_G.GetActiveTalentGroup, false, false)
        if ok and type(g) == "number" then
            return g
        end
    end
    return 1
end

local function HasDualSpecAPI()
    if _G.SetActiveTalentGroup then
        return true
    end
    local CSI = _G.C_SpecializationInfo
    if CSI and CSI.SetActiveSpecGroup then
        return true
    end
    return false
end

local function ItemNameIsAtiesh(itemID, itemLink)
    if itemID and ATIESH_ITEM_IDS[itemID] then
        return true
    end
    if Compat and Compat.ParseItemID and itemLink then
        local id = Compat.ParseItemID(itemLink)
        if id and ATIESH_ITEM_IDS[id] then
            return true
        end
    end
    if itemID and _G.GetItemInfo then
        local name = GetItemInfo(itemID)
        if type(name) == "string" and name:find("Atiesh", 1, true) then
            return true
        end
    end
    if itemLink and _G.GetItemInfo then
        local name = GetItemInfo(itemLink)
        if type(name) == "string" and name:find("Atiesh", 1, true) then
            return true
        end
    end
    return false
end

local function FindEquippedAtiesh()
    local link = GetInventoryItemLink and GetInventoryItemLink("player", INVSLOT_MAINHAND)
    local id = GetInventoryItemID and GetInventoryItemID("player", INVSLOT_MAINHAND)
    if ItemNameIsAtiesh(id, link) then
        return INVSLOT_MAINHAND, id, link
    end
    return nil
end

local function FindAtieshInBags(itemID)
    local inv = R.Inv
    if not inv then
        return nil, nil
    end
    if itemID and inv.Find then
        local locs = inv.Find(itemID, "bags")
        local loc = locs and locs[1]
        if loc then
            return loc.bag, loc.slot
        end
        return nil, nil
    end
    if inv.ForEachLocation then
        local foundBag, foundSlot
        inv.ForEachLocation(function(loc)
            if foundBag then
                return
            end
            if loc.itemID and ItemNameIsAtiesh(loc.itemID, loc.link) then
                foundBag, foundSlot = loc.bag, loc.slot
            end
        end, "bags")
        return foundBag, foundSlot
    end
    return nil, nil
end

local function FindFirstEmptyPlayerBagSlot()
    local inv = R.Inv
    if inv and inv.GetFirstFreeBagSlot then
        local bag, slot = inv.GetFirstFreeBagSlot()
        if bag ~= nil then
            return bag, slot
        end
    end
    local mover = _G.FluxItemMover
    if mover and mover.FindFirstEmptyBagSlot then
        local bag, slot = mover.FindFirstEmptyBagSlot(GetCharacterBagIDs())
        if bag ~= nil then
            return bag, slot
        end
    end
    return nil, nil
end

local function PickupContainer(bag, slot)
    if Compat and Compat.PickupContainerItem then
        return Compat.PickupContainerItem(bag, slot)
    end
    if _G.PickupContainerItem then
        return pcall(_G.PickupContainerItem, bag, slot)
    end
    return false
end

local function ClearCursorSafe()
    if _G.ClearCursor then
        pcall(_G.ClearCursor)
    end
end

local function UnequipInventorySlotToBag(invSlot)
    local destBag, destSlot = FindFirstEmptyPlayerBagSlot()
    if destBag == nil then
        return nil
    end
    ClearCursorSafe()
    if not _G.PickupInventoryItem then
        return nil
    end
    pcall(_G.PickupInventoryItem, invSlot)
    if not GetCursorInfo or not GetCursorInfo() then
        ClearCursorSafe()
        return nil
    end
    if not PickupContainer(destBag, destSlot) then
        ClearCursorSafe()
        return nil
    end
    ClearCursorSafe()
    return destBag, destSlot
end

local function EquipBagSlotToInventory(bag, bagSlot, invSlot)
    if bag == nil or not bagSlot or not invSlot then
        return false
    end
    ClearCursorSafe()
    if not PickupContainer(bag, bagSlot) then
        return false
    end
    if not GetCursorInfo or not GetCursorInfo() then
        ClearCursorSafe()
        return false
    end
    if _G.EquipCursorItem then
        pcall(_G.EquipCursorItem, invSlot)
    elseif _G.PickupInventoryItem then
        pcall(_G.PickupInventoryItem, invSlot)
    end
    ClearCursorSafe()
    local id = GetInventoryItemID and GetInventoryItemID("player", invSlot)
    return ItemNameIsAtiesh(id, nil)
end

local function CancelSessionTimeout()
    if timeoutTimer and timeoutTimer.Cancel then
        pcall(function() timeoutTimer:Cancel() end)
    end
    timeoutTimer = nil
end

local function ClearSession()
    CancelSessionTimeout()
    session = nil
    finishScheduled = false
end

local function TryReequipFromSession(rec)
    if not rec then
        return false
    end
    if FindEquippedAtiesh() then
        return true
    end
    if EquipBagSlotToInventory(rec.bag, rec.bagSlot, rec.invSlot) then
        return true
    end
    local bag, slot = FindAtieshInBags(rec.itemID)
    if bag and EquipBagSlotToInventory(bag, slot, rec.invSlot) then
        return true
    end
    return false
end

local function FinishReequip()
    if not session or session.finished then
        return
    end
    session.finished = true
    CancelSessionTimeout()

    if InCombatLockdown and InCombatLockdown() then
        session.finished = false
        return
    end

    local rec = session
    TryReequipFromSession(rec)
    ClearSession()
end

local function ScheduleFinishReequip()
    if not session or session.finished or finishScheduled then
        return
    end
    finishScheduled = true
    local function run()
        finishScheduled = false
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0, FinishReequip)
        else
            FinishReequip()
        end
    end
    run()
end

local function ArmSessionTimeout()
    CancelSessionTimeout()
    if not (_G.C_Timer and _G.C_Timer.NewTimer) then
        return
    end
    timeoutTimer = _G.C_Timer.NewTimer(SESSION_TIMEOUT, function()
        timeoutTimer = nil
        ScheduleFinishReequip()
    end)
end

local function IsLikelyDualSpecCastSpell(spellID)
    if not spellID or not _G.GetSpellInfo then
        return false
    end
    local name = GetSpellInfo(spellID)
    if type(name) ~= "string" or name == "" then
        return false
    end
    local lower = name:lower()
    if lower:find("specialization", 1, true) or lower:find("specialisation", 1, true) then
        return true
    end
    if lower:find("talent", 1, true) and lower:find("activ", 1, true) then
        return true
    end
    if lower:find("spec", 1, true) and lower:find("activ", 1, true) then
        return true
    end
    return false
end

function Fix.OnDualSpecSwitchStart(targetGroup)
    if not playerReady then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    if session then
        return
    end
    local target = tonumber(targetGroup)
    if not target then
        return
    end
    local fromGroup = tonumber(GetActiveGroup())
    if not fromGroup or fromGroup == target then
        return
    end
    local invSlot, itemID = FindEquippedAtiesh()
    if not invSlot then
        return
    end
    local bag, bagSlot = UnequipInventorySlotToBag(invSlot)
    if bag == nil then
        return
    end
    session = {
        invSlot = invSlot,
        bag = bag,
        bagSlot = bagSlot,
        itemID = itemID,
        fromGroup = fromGroup,
        toGroup = target,
        finished = false,
        swapCastSpellID = nil,
    }
    ArmSessionTimeout()
end

local function InstallPreHookSetActiveTalentGroup()
    local orig = _G.SetActiveTalentGroup
    if not orig or orig == Fix._wrappedSetActiveTalentGroup then
        return
    end
    Fix._origSetActiveTalentGroup = orig
    Fix._wrappedSetActiveTalentGroup = function(group, ...)
        Fix.OnDualSpecSwitchStart(group)
        return orig(group, ...)
    end
    _G.SetActiveTalentGroup = Fix._wrappedSetActiveTalentGroup
end

local function InstallPreHookSetActiveSpecGroup()
    local CSI = _G.C_SpecializationInfo
    if not CSI or not CSI.SetActiveSpecGroup then
        return
    end
    if CSI.SetActiveSpecGroup == Fix._wrappedSetActiveSpecGroup then
        return
    end
    Fix._origSetActiveSpecGroup = CSI.SetActiveSpecGroup
    Fix._wrappedSetActiveSpecGroup = function(group)
        Fix.OnDualSpecSwitchStart(group)
        return Fix._origSetActiveSpecGroup(group)
    end
    CSI.SetActiveSpecGroup = Fix._wrappedSetActiveSpecGroup
end

local function InstallHooks()
    if hooksInstalled then
        return
    end
    if not HasDualSpecAPI() then
        return
    end
    InstallPreHookSetActiveTalentGroup()
    InstallPreHookSetActiveSpecGroup()
    hooksInstalled = true
end

local function MarkPlayerReady()
    if playerReady then
        return
    end
    playerReady = true
end

local function OnSpellcastEnd(spellID, isInterrupt)
    if not session or session.finished then
        return
    end
    if isInterrupt then
        local active = tonumber(GetActiveGroup())
        if active == session.fromGroup then
            ScheduleFinishReequip()
        end
        return
    end
    if spellID and (spellID == session.swapCastSpellID or IsLikelyDualSpecCastSpell(spellID)) then
        ScheduleFinishReequip()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player") end)
pcall(function() eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player") end)

eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == "_FluxUI" then
            InstallHooks()
        end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        playerReady = false
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(2, MarkPlayerReady)
        else
            MarkPlayerReady()
        end
        return
    end

    if event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if session and not session.finished then
            ScheduleFinishReequip()
        end
        return
    end

    if event == "UNIT_SPELLCAST_START" and arg1 == "player" then
        if not session or session.finished then
            return
        end
        local spellID = arg2
        if IsLikelyDualSpecCastSpell(spellID) then
            session.swapCastSpellID = spellID
        end
        return
    end

    if arg1 ~= "player" then
        return
    end

    if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        OnSpellcastEnd(arg2, true)
        return
    end

    if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_STOP" then
        OnSpellcastEnd(arg2, false)
    end
end)

R.AtieshDualSpecFix = Fix

