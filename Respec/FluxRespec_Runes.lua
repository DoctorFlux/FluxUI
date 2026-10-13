-- FluxRespec_Runes.lua
-- SoD-only. Capture engraved runes per equipment slot, and provide a queue
-- that engraves runes one at a time (one press per rune) until the target
-- build is fully applied.
-- Non-engraving clients: module is a no-op; Capture returns nil.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.Runes = R.Runes or {}
local Runes = R.Runes
local Compat = R.Compat

--- RUNE_UPDATED exists only on some builds (e.g. SoD engraving); raw RegisterEvent errors on others.
local function RegisterRuneUpdatedIfAvailable(frame)
    if _G.FluxSafeRegisterEvent then
        return FluxSafeRegisterEvent(frame, "RUNE_UPDATED")
    end
    local ok = pcall(function()
        frame:RegisterEvent("RUNE_UPDATED")
    end)
    return ok
end

-- Equipment slots that can hold runes on SoD (order = UI strip left→right).
-- Shoulders excluded (primary slot 3 and SoD secondary shoulder slot 20).
local ENGRAVABLE_SLOTS = {}
do
    local head = { 5, 7, 10, 6, 8 } -- chest, legs, hands, waist, feet
    for _, s in ipairs(head) do
        ENGRAVABLE_SLOTS[#ENGRAVABLE_SLOTS + 1] = s
    end
    for _, s in ipairs({ 15, 1, 9, 11, 12 }) do
        ENGRAVABLE_SLOTS[#ENGRAVABLE_SLOTS + 1] = s
    end
end

-- Auto-click Blizzard REPLACE_ENCHANT confirmation (rune replace) for a short window after casts.
local pulseFrameEnchant
--- RuneReminder-style: Blizzard accepts the replace dialog, then hide it (no click needed).
local function ConfirmReplaceEnchantLikeRuneReminder()
    if _G.ReplaceEnchant then
        pcall(_G.ReplaceEnchant)
    end
    if _G.StaticPopup_Hide then
        _G.StaticPopup_Hide("REPLACE_ENCHANT")
    end
end

local function ClickBlizzardReplaceEnchantPopup()
    local n = _G.STATICPOPUP_NUMDIALOGS or 4
    for i = 1, n do
        local d = _G["StaticPopup" .. i]
        if d and d:IsShown() and d.which == "REPLACE_ENCHANT" and d.button1 then
            d.button1:Click()
            return true
        end
    end
    return false
end

local function RunReplaceEnchantAutoAcceptPulse(seconds)
    Runes._autoConfirmReplace = true
    if not pulseFrameEnchant then
        pulseFrameEnchant = CreateFrame("Frame")
    end
    local t = 0
    local maxT = seconds or 3
    pulseFrameEnchant:SetScript("OnUpdate", function(self, dt)
        t = t + (dt or 0)
        ClickBlizzardReplaceEnchantPopup()
        if t >= maxT then
            self:SetScript("OnUpdate", nil)
        end
    end)
    ClickBlizzardReplaceEnchantPopup()
end

-- -----------------------------------------------------------------------------
-- Capture
-- -----------------------------------------------------------------------------

local function IsAvailable()
    return Compat and Compat.IsSoD() and _G.C_Engraving and _G.C_Engraving.GetRuneForEquipmentSlot
end

--- Capture current runes engraved per slot. Returns nil on non-engraving clients.
function Runes.Capture()
    if not IsAvailable() then return nil end
    local ok = pcall(function()
        if _G.C_Engraving.RefreshRunesList then
            _G.C_Engraving.RefreshRunesList()
        end
    end)
    local out = {}
    for _, slotID in ipairs(ENGRAVABLE_SLOTS) do
        local rune = nil
        local ok2, r = pcall(_G.C_Engraving.GetRuneForEquipmentSlot, slotID)
        if ok2 then rune = r end
        if rune and rune.skillLineAbilityID then
            out[slotID] = {
                skillLineAbilityID = rune.skillLineAbilityID,
                name = rune.name,
                iconTexture = rune.iconTexture,
            }
        end
    end
    return out
end

-- -----------------------------------------------------------------------------
-- Diff
-- -----------------------------------------------------------------------------

--- Return a queue of runes needed for the snapshot that are NOT currently engraved.
--- Each entry: { slotID, skillLineAbilityID, name, iconTexture }
function Runes.BuildQueue(snapshot)
    if not IsAvailable() or type(snapshot) ~= "table" then return {} end
    pcall(function()
        if _G.C_Engraving.RefreshRunesList then
            _G.C_Engraving.RefreshRunesList()
        end
    end)
    local queue = {}
    for _, slotID in ipairs(ENGRAVABLE_SLOTS) do
        local want = snapshot[slotID]
        if want and want.skillLineAbilityID then
            local current = nil
            local ok, r = pcall(_G.C_Engraving.GetRuneForEquipmentSlot, slotID)
            if ok then current = r end
            if not current or current.skillLineAbilityID ~= want.skillLineAbilityID then
                table.insert(queue, {
                    slotID = slotID,
                    skillLineAbilityID = want.skillLineAbilityID,
                    name = want.name,
                    iconTexture = want.iconTexture,
                })
            end
        end
    end
    return queue
end

--- Count of queued runes for UI summary.
function Runes.DiffCount(snapshot)
    local q = Runes.BuildQueue(snapshot)
    return #q
end

--- True if the rune engraved on `slotID` matches the profile snapshot (for UI match highlight).
function Runes.SlotMatchesSnapshot(slotID, want)
    if not IsAvailable() or not want or not want.skillLineAbilityID then
        return false
    end
    local current = nil
    local ok, r = pcall(_G.C_Engraving.GetRuneForEquipmentSlot, slotID)
    if ok then current = r end
    return current ~= nil and current.skillLineAbilityID == want.skillLineAbilityID
end

--- Cast the profile's saved rune for this slot (single click), if it does not already match. RuneReminder-style CastRune + UseInventoryItem.
function Runes.EngraveFromProfileSlot(slotID)
    if not IsAvailable() then
        return false
    end
    if InCombatLockdown() then
        R.Warn("Can't engrave runes in combat.")
        return false
    end
    local pname = R.GetActiveName and R.GetActiveName()
    local profile = pname and R.GetProfile and R.GetProfile(pname)
    local want = profile and profile.runes and profile.runes[slotID]
    if not want or not want.skillLineAbilityID then
        R.Print("No rune saved for this slot in the active profile.")
        return false
    end
    if Runes.SlotMatchesSnapshot(slotID, want) then
        return false
    end
    local item = GetInventoryItemID and GetInventoryItemID("player", slotID)
    if not item then
        R.Warn(("Equip an item in this slot first (slot %d)."):format(slotID))
        return false
    end
    Runes._autoConfirmReplace = true
    local ok = pcall(function()
        if _G.ClearCursor then _G.ClearCursor() end
        _G.C_Engraving.ClearExclusiveCategoryFilter()
        _G.C_Engraving.SetSearchFilter("")
        _G.C_Engraving.CastRune(want.skillLineAbilityID)
        if _G.UseInventoryItem then
            _G.UseInventoryItem(slotID)
        end
        ConfirmReplaceEnchantLikeRuneReminder()
        if _G.ClearCursor then _G.ClearCursor() end
    end)
    if ok then
        RunReplaceEnchantAutoAcceptPulse(3)
    end
    return ok == true
end

--- Ordered equipment slot IDs that can hold engravings (same order as capture / queue).
Runes.ENGRAVABLE_SLOTS = ENGRAVABLE_SLOTS

-- -----------------------------------------------------------------------------
-- Queue state (lives in memory only, not in saved vars)
-- -----------------------------------------------------------------------------

Runes._queue = nil
--- While true, REPLACE_ENCHANT is auto-confirmed (rune replace on gear).
Runes._autoConfirmReplace = false

function Runes.HasActiveQueue()
    return Runes._queue ~= nil and #Runes._queue > 0
end

--- True when the queued head rune targets a slot whose profile gear entry is not yet equipped.
--- Engraving applies to the item in that paperdoll slot — wrong item must be swapped first.
function Runes.HeadBlockedByProfileGear(profile)
    if not IsAvailable() or not Runes._queue or #Runes._queue == 0 then
        return false
    end
    local head = Runes._queue[1]
    local slotID = head and head.slotID
    if not slotID or type(profile) ~= "table" or not profile.equipment then
        return false
    end
    local want = profile.equipment[slotID]
    if not want or not want.itemID then
        return false
    end
    if R.Includes and R.Includes.EquipSlotEnabled and not R.Includes.EquipSlotEnabled(profile, slotID) then
        return false
    end
    if not R.Equipment or not R.Equipment.SlotMatchesEntry then
        return false
    end
    return not R.Equipment.SlotMatchesEntry(slotID, want, profile.equipment)
end

function Runes.GetActiveQueue()
    return Runes._queue or {}
end

function Runes.ClearQueue()
    Runes._autoConfirmReplace = false
    Runes._queue = nil
    R.Fire("RUNE_QUEUE_CHANGED")
end

--- Set the queue from a snapshot. Does NOT cast anything.
function Runes.StartQueue(snapshot)
    if not IsAvailable() then return false end
    local queue = Runes.BuildQueue(snapshot)
    if #queue == 0 then
        Runes.ClearQueue()
        return false
    end
    Runes._queue = queue
    Runes._autoConfirmReplace = true
    RunReplaceEnchantAutoAcceptPulse(3)
    -- Listen for engraving completion so we pop the head automatically when
    -- the correct rune lands on the equipped item.
    if not Runes._watcher then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        RegisterRuneUpdatedIfAvailable(f)
        f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        f:SetScript("OnEvent", function(self, event, ...)
            if not Runes._queue then return end
            local head = Runes._queue[1]
            if not head then
                Runes.ClearQueue()
                return
            end
            local current = nil
            local ok, r = pcall(_G.C_Engraving.GetRuneForEquipmentSlot, head.slotID)
            if ok then current = r end
            if current and current.skillLineAbilityID == head.skillLineAbilityID then
                table.remove(Runes._queue, 1)
                if #Runes._queue == 0 then
                    Runes.ClearQueue()
                else
                    R.Fire("RUNE_QUEUE_CHANGED")
                end
            end
        end)
        Runes._watcher = f
    end
    R.Fire("RUNE_QUEUE_CHANGED")
    return true
end

--- Cast the next queued rune. Must run from a secure path (e.g. Load / Engrave button OnClick);
--- CastRune() is protected and will error if called from equipment/talent callbacks.
--- Returns true if a cast was attempted.
--- Matches RuneReminder: CastRune then UseInventoryItem(slot) so the correct
--- paperdoll slot is targeted.
function Runes.CastNext()
    if not IsAvailable() or not Runes._queue or #Runes._queue == 0 then
        return false
    end
    if InCombatLockdown() then
        R.Warn("Can't engrave runes in combat.")
        return false
    end
    local head = Runes._queue[1]
    if not head or not head.slotID or not head.skillLineAbilityID then
        return false
    end
    local slotID = head.slotID
    local pname = R.GetActiveName and R.GetActiveName()
    local profile = pname and R.GetProfile and R.GetProfile(pname)
    if Runes.HeadBlockedByProfileGear(profile) then
        R.Warn(("Equip the profile item for slot %d first — engraving uses whatever is equipped there."):format(slotID))
        return false
    end
    local item = GetInventoryItemID and GetInventoryItemID("player", slotID)
    if not item then
        R.Warn(("Cannot engrave: no item equipped in slot %d."):format(slotID))
        return false
    end
    Runes._autoConfirmReplace = true
    local ok = pcall(function()
        if _G.ClearCursor then _G.ClearCursor() end
        _G.C_Engraving.ClearExclusiveCategoryFilter()
        _G.C_Engraving.SetSearchFilter("")
        _G.C_Engraving.CastRune(head.skillLineAbilityID)
        if _G.UseInventoryItem then
            _G.UseInventoryItem(slotID)
        end
        ConfirmReplaceEnchantLikeRuneReminder()
        if _G.ClearCursor then _G.ClearCursor() end
    end)
    if ok then
        RunReplaceEnchantAutoAcceptPulse(3)
    end
    return ok == true
end

--- RuneReminder-style category id for C_Engraving filters.
local function AdjustedCategorySlot(slotID)
    if slotID == 12 then return 11 end
    if slotID == 15 then return 16 end
    return slotID
end

--- Pick a specific rune (e.g. no-profile picker). Same secure CastRune + UseInventoryItem as CastNext;
--- does not use the profile gear gate.
function Runes.CastSkillLineOnSlot(slotID, skillLineAbilityID)
    if not IsAvailable() or not skillLineAbilityID or not slotID then return false end
    if InCombatLockdown() then
        R.Warn("Can't engrave runes in combat.")
        return false
    end
    local item = GetInventoryItemID and GetInventoryItemID("player", slotID)
    if not item then
        R.Warn(("Cannot engrave: no item equipped in slot %d."):format(slotID))
        return false
    end
    Runes._autoConfirmReplace = true
    local ok = pcall(function()
        if _G.ClearCursor then _G.ClearCursor() end
        local cat = AdjustedCategorySlot(slotID)
        pcall(_G.C_Engraving.ClearCategoryFilter, cat)
        _G.C_Engraving.ClearExclusiveCategoryFilter()
        _G.C_Engraving.SetSearchFilter("")
        _G.C_Engraving.CastRune(skillLineAbilityID)
        if _G.UseInventoryItem then
            _G.UseInventoryItem(slotID)
        end
        ConfirmReplaceEnchantLikeRuneReminder()
        if _G.ClearCursor then _G.ClearCursor() end
    end)
    if ok then
        RunReplaceEnchantAutoAcceptPulse(3)
    end
    return ok == true
end

--- Kick off a rune apply: just starts the queue. UI drives cast presses.
function Runes.Apply(snapshot)
    if not IsAvailable() then
        R.Fire("RUNES_APPLIED", true, "NOT_SOD")
        return true
    end
    local ok = Runes.StartQueue(snapshot)
    R.Fire("RUNES_APPLIED", true, ok and "QUEUED" or "NOOP")
    return true
end

-- Also react the moment REPLACE_ENCHANT is shown (hook + pulse catches delayed layout).
local function FluxRunesStaticPopupLogoutFlowVisible()
    local vis = _G.StaticPopup_Visible
    if type(vis) ~= "function" then
        return false
    end
    return vis("CAMP") or vis("QUIT") or vis("PLUNDERSTORM_LEAVE")
end

if hooksecurefunc and _G.StaticPopup_Show then
    hooksecurefunc("StaticPopup_Show", function(which)
        if Compat.SecureUIPanelsBlockRespecWork() then
            return
        end
        if FluxRunesStaticPopupLogoutFlowVisible() then
            return
        end
        if which == "REPLACE_ENCHANT" and Runes._autoConfirmReplace then
            ConfirmReplaceEnchantLikeRuneReminder()
            RunReplaceEnchantAutoAcceptPulse(2)
        end
    end)
end

R.Runes = Runes
