-- Exercise the loaded configuration, collection cache, and mount button together.
local root = arg[1] or "."
local directory = root .. "/ExtraButtonSystem/NonCombatGrid/"
local checks = 0
local function eq(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function mountMacro(name)
    return "/dismount [combat,mounted]\n/cast [nocombat,nomounted] " .. name
end

local e = setmetatable({}, { __index = _G })
e._G = e
local combat, mounted, taxi, rank, learned, cursorType, cursorID
local dead, ghost = false, false
local shift, ctrl, alt, checkModifiers
local timers, frames = {}, {}
local function noop() end
local function frame(parent)
    local f = { parent = parent, scripts = {}, events = {}, attributes = {}, shown = true }
    function f:SetScript(script, cb) self.scripts[script] = cb end
    function f:GetScript(script) return self.scripts[script] end
    function f:HookScript(script, cb) self.scripts[script] = cb end
    function f:RegisterEvent(event) self.events[event] = true end
    function f:UnregisterEvent(event) self.events[event] = nil end
    function f:RegisterUnitEvent(event) self.events[event] = true end
    function f:IsShown() return self.shown end
    function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function f:Show()
        if self.shown then return end
        self.shown = true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function f:Hide()
        if not self.shown then return end
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function f:SetEnabled(enabled) self.enabled = enabled end
    function f:SetShown(shown) if shown then self:Show() else self:Hide() end end
    function f:SetHeight(height) self.height = height end
    function f:SetTexture(texture) self.texture = texture end
    function f:ClearAllPoints() self.points = {} end
    function f:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = { ... } end
    function f:CreateFontString() return frame() end
    function f:CreateTexture() return frame() end
    function f:SetAttribute(key, value)
        assert(not combat, "secure attribute written during lockdown")
        self.attributes[key] = value
    end
    function f:GetAttribute(key) return self.attributes[key] end
    for _, method in ipairs({ "SetSize", "SetFrameStrata", "SetFrameLevel", "SetText", "SetTextColor", "SetDesaturated",
        "SetVertexColor", "SetBlendMode", "SetHighlightTexture", "SetNormalFontObject", "RegisterForDrag", "SetAllPoints",
        "SetChecked" }) do
        f[method] = noop
    end
    return f
end

e.CreateFrame = function(_, name, parent)
    local f = frame(parent)
    frames[#frames + 1] = f
    if name then e[name] = f end
    return f
end
local function fire(event, ...)
    for _, f in ipairs(frames) do
        if f.events[event] then f.scripts.OnEvent(f, event, ...) end
    end
end
local function flushTimers()
    local callbacks = timers
    timers = {}
    for _, callback in ipairs(callbacks) do callback.run() end
end

e.C_Timer = { After = function(delay, cb) timers[#timers + 1] = { delay = delay, run = cb } end }
e.FluxBlizzardDropdown = { Create = function(parent)
    local dropdown = frame(parent)
    function dropdown:FluxSetText(label) self.label = label end
    function dropdown:FluxSetMenu(generator) self.menu = generator end
    return dropdown
end }
e.FluxModifierTracker = { Register = function(_, callback) checkModifiers = callback end }
e.IsShiftKeyDown = function() return shift end
e.IsControlKeyDown = function() return ctrl end
e.IsAltKeyDown = function() return alt end
e.GameTooltip = frame()
function e.GameTooltip:SetOwner(owner) self.owner = owner end
function e.GameTooltip:ClearLines() self.lines, self.bindings = {}, {} end
function e.GameTooltip:SetText(title) self:ClearLines(); self.title = title end
function e.GameTooltip:AddLine(line) self.lines[#self.lines + 1] = line end
function e.GameTooltip:AddDoubleLine(key, mountName, red)
    self.bindings[key] = { name = mountName, active = red == 0.2 }
end
e.GetTime = function() return 10 end
e.InCombatLockdown = function() return combat end
e.IsMounted = function() return mounted end
e.UnitIsDeadOrGhost = function() return dead or ghost end
e.UnitIsDead = function() return dead end
e.UnitIsGhost = function() return ghost end
e.UnitOnTaxi = function(unit)
    assert(unit == "player")
    return taxi == true
end
e.Enum, e.SlashCmdList = {}, {}
e.UIParent = frame()
e.UnitClass = function() return "Mage", "MAGE" end
e.RAID_CLASS_COLORS = { MAGE = { r = 0, g = 1, b = 1 } }
e.GetCursorInfo = function() return cursorType, cursorID end
e.ClearCursor = function() cursorType, cursorID = nil, nil end
e.FLUX_API = { isForever = true, isCamelot = true, isRetail = true, majorVersion = 1, hasC_MountJournal = true }
e.FluxNonCombatGridDB = { global = { mountConfig = { ground = "Spell 2", flying = "Other-client mount" } } }
e.C_SkillInfo = { GetSkillLineInfoByID = function(id)
    eq(id, 762, "stable riding skill ID")
    return { rank = rank or 0 }
end }
e.C_SpellBook = { IsSpellKnown = function(id) return id == learned end }
e.C_Spell = { GetSpellName = function(spellID) return "Spell " .. (spellID - 50) end }

local Usable, Collected = {}, {}
local nativeReads, journalReady = 0, true
e.C_MountJournal = {
    GetMountIDs = function() return journalReady and { 1, 2, 3, 4, 5, 6, 7, 8, 9 } or {} end,
    GetMountInfoByID = function(id)
        nativeReads = nativeReads + 1
        return "Journal " .. id, 50 + id, 100 + id, false, false, 0, false, false, nil, id == 9, Collected[id]
    end,
    GetMountUsabilityByID = function(id, indoors)
        eq(indoors, false, "availability allows a persistent button indoors")
        return Usable[id]
    end,
}

for _, file in ipairs({ "FluxSmartMountConfig.lua", "Buttons/MountCollection.lua", "Buttons/Mount.lua" }) do
    assert(loadfile(directory .. file, "t", e))()
end
local config, mount = e.FluxSmartMountConfig, e.FluxNCMount
local updateMountTexture = mount.UpdateTexture
local updateMountKeybinding, clearMountKeybinding = mount.UpdateMountKeybinding, mount.ClearMountKeybinding
eq(mount.HasMountUI(), true, "Forever major version 1 gets the journal")

local widget, slot = frame(), frame()
mount._button = { Widget = widget, SlotFrame = slot }
mount._registered = true
mount.UpdateButtonScope, mount.UpdateTexture = noop, noop
mount.UpdateMountKeybinding, mount.UpdateHotkeyText, mount.ClearMountKeybinding = noop, noop, noop
mount.SetupBagMountButton = function() error("Forever used the bag-mount route") end
e.FluxExtraButtonVisibility = {
    GetEffectiveMode = function() return "auto" end,
    Apply = function(_, smart) return smart end,
}

Collected[2] = true
Collected[9], Usable[9] = true, true
mount.Update()
eq(slot:IsShown(), false, "account mount and hidden usable row do not bypass riding")
rank = 75
fire("SKILL_LINES_CHANGED")
flushTimers()
eq(slot:IsShown(), true, "training refreshes auto visibility")
eq(mount._isPlaceholder, true, "without an eligible mount the trained slot is a placeholder")
Usable[2] = true
fire("MOUNT_JOURNAL_USABILITY_CHANGED")
eq(widget:GetAttribute("macrotext"), "#showtooltip\n" .. mountMacro("Spell 2"), "usable saved ground choice is retained")

e.CollectionsJournal = frame(e.UIParent)
e.MountJournal = frame(e.CollectionsJournal)
e.MountJournal:Hide()
e.SetCollectionsJournalShown = function(shown, tab)
    eq(shown, true, "open collection")
    eq(tab, 1, "open mount tab")
    e.MountJournal:Show()
end
config.CreateMountConfigUI()
local panel = e.FluxSmartMountConfigFrame
eq(panel:IsShown(), false, "mount configuration follows the actual mount pane")
eq(mount.OpenMountUI(), true, "right-click proxy owner has the native Forever opener")
eq(panel:IsShown(), true, "native mount pane shows config without a root selectedTab")
eq(widget:GetAttribute("*macrotext2"), "#showtooltip\n/click FluxMacroProxy_MountOpenUI", "modified right-click still opens the journal")
local function slotFrame(key)
    local button = panel.slots[key]
    return button.row or button
end
eq(slotFrame("nomod"):IsShown(), true, "default is always accessible")
eq(slotFrame("shift"):IsVisible(), false, "an unassigned modifier is not a visible slot")
eq(panel.addModifier:IsShown(), true, "add control is visible while assignments are available")
eq(panel.addModifier:menu()[1].disabled, true, "add control explains how to choose a mount first")
local initialHeight = panel.height
local function visibleSlots()
    local count = 0
    for _, button in pairs(panel.slots) do
        if button.row:IsShown() then count = count + 1 end
    end
    return count
end
eq(visibleSlots(), 1, "a default-only setup displays one slot")
panel.slots.nomod.clearButton.scripts.OnClick()
eq(panel.slots.nomod.mountSpell, "Journal 2", "clearing the default shows the automatic mount immediately")
eq(panel.slots.nomod.clearButton.enabled, false, "automatic default has no saved choice to clear")
local function addModifier(key)
    for _, entry in ipairs(panel.addModifier:menu()) do
        for _, slotInfo in ipairs(config.ForeverSlots) do
            if key == slotInfo.key and entry.text == slotInfo.name then
                entry.func()
                return
            end
        end
    end
    error("modifier missing from menu: " .. key)
end

for id = 1, 8 do Collected[id], Usable[id] = true, true end
fire("NEW_MOUNT_ADDED")
flushTimers()
local cases = {
    { "nomod", "", 1 }, { "ctrl", "ctrl-", 2 }, { "shift", "shift-", 3 }, { "alt", "alt-", 4 },
    { "ctrl+shift", "ctrl-shift-", 5 }, { "ctrl+alt", "alt-ctrl-", 6 }, { "shift+alt", "alt-shift-", 7 },
    { "ctrl+shift+alt", "alt-ctrl-shift-", 8 },
}
local function assignedMacro(prefix)
    local macro = widget:GetAttribute(prefix .. "macrotext1") or widget:GetAttribute("macrotext")
    return macro and macro:match("/cast %[nocombat,nomounted%] ([^\n]+)")
end
for index, case in ipairs(cases) do
    local key, _, id = table.unpack(case)
    e.MountJournal.selectedMountID = id
    if key == "nomod" then
        panel.slots[key].setButton.scripts.OnClick()
    else
        eq(#panel.addModifier:menu(), 9 - index, "menu includes only unused combinations")
        addModifier(key)
    end
    eq(config.GetForeverMountAssignment(key), id, "persist collection ID for " .. key)
    eq(visibleSlots(), index, "adding a choice reveals exactly one row")
end
eq(panel.addModifier:IsShown(), false, "the add control is hidden when every combination is assigned")
eq(string.format("%d/%d", initialHeight, panel.height), "90/232", "default-only and fully assigned heights stay compact")
local cachedReads = nativeReads
for _, case in ipairs(cases) do
    local key, prefix, id = table.unpack(case)
    local name, icon, spell = mount.GetMountForCurrentModifiers(key)
    eq(assignedMacro(prefix), "Spell " .. id, "exact secure assignment for " .. key)
    eq(name, assignedMacro(prefix), "preview and programmed action match for " .. key)
    eq(icon, id + 100, "journal icon for " .. key)
    eq(spell, id + 50, "cast-lock spell identity for " .. key)
end
eq(nativeReads, cachedReads, "modifier previews reuse the journal cache")
eq(e.FluxNonCombatGridDB.global.mountConfig.flying, "Other-client mount", "other client data retained")

local altSlot = panel.slots.alt
altSlot.clearButton.scripts.OnClick()
eq(altSlot.row:IsShown(), false, "clearing immediately hides the row")
eq(panel.addModifier:IsShown(), true, "cleared assignment becomes available to add again")
eq(panel.slots["ctrl+shift"].row.points[1][5], -106, "rows close up without a blank slot")
eq(assignedMacro("alt-"), "Spell 1", "an unassigned modifier uses the default")
eq(assignedMacro("alt-ctrl-"), "Spell 6", "clearing Alt has no effect on Ctrl+Alt")
mount.SetupTooltip(mount._button)
widget.scripts.OnEnter(widget)
eq(e.GameTooltip.bindings.Alt, nil, "button tooltip omits the cleared combination")
eq(e.GameTooltip.bindings.Default.active, true, "tooltip highlights the default with no keys held")
alt = true
checkModifiers()
eq(e.GameTooltip.bindings.Default.active, true, "an unassigned held key still highlights the fallback")
ctrl = true
checkModifiers()
eq(e.GameTooltip.bindings["Ctrl+Alt"].active, true, "holding the exact keys refreshes the highlighted assignment")
eq(e.GameTooltip.bindings.Default.active, false, "only one assignment is highlighted")
ctrl, alt = false, false
checkModifiers()
eq(e.GameTooltip.bindings.Default.active, true, "releasing the keys restores the default highlight")
widget.scripts.OnLeave(widget)
e.MountJournal.selectedMountID = 9
eq(panel.addModifier:menu()[1].disabled, true, "add rejects a hidden journal mount")
eq(config.GetForeverMountAssignment("alt"), nil, "hidden mount selection is rejected")
e.MountJournal.selectedMountID = 3
addModifier("alt")
eq(config.GetForeverMountAssignment("alt"), 3, "cleared modifier can be added back")
cursorType, cursorID = "item", 4
altSlot.scripts.OnReceiveDrag()
eq(cursorType, "item", "unrelated item stays on the cursor")
cursorType = "mount"
altSlot.scripts.OnReceiveDrag()
eq(config.GetForeverMountAssignment("alt"), 4, "drag saves journal mount ID")
eq(cursorType, nil, "accepted mount clears the cursor")

config.ToggleCharacterSpecific()
eq(config.GetForeverMountAssignment("alt"), 4, "new character-specific setup copies account assignments")
altSlot.clearButton.scripts.OnClick()
eq(config.GetForeverMountAssignment("alt"), nil, "character assignment can be cleared")
eq(altSlot.row:IsShown(), false, "the panel shows only assignments from the active scope")
config.ToggleCharacterSpecific()
eq(config.GetForeverMountAssignment("alt"), 4, "character edit does not alter account assignment")
eq(altSlot.row:IsShown(), true, "returning to the account scope restores its row")

mounted = true
mount.LockToMount("Spell 5", 105, 55)
eq(widget:GetAttribute("macrotext"), "/dismount [mounted]", "sticky mount uses the dismount action")
eq(widget:GetAttribute("alt-ctrl-shift-macrotext1"), nil, "modifiers fall back to the mounted action")
mounted = false
mount.Unlock()
eq(assignedMacro("alt-ctrl-shift-"), "Spell 8", "unlock restores exact modifier macros")

combat = true
altSlot.clearButton.scripts.OnClick()
eq(assignedMacro("alt-"), "Spell 4", "combat defers secure config update")
combat = false
fire("PLAYER_REGEN_ENABLED")
eq(assignedMacro("alt-"), "Spell 1", "combat exit applies saved assignment")

Usable[1], Usable[6] = false, false
fire("MOUNT_JOURNAL_USABILITY_CHANGED")
eq(assignedMacro(""), "Spell 2", "first usable mount is the fallback for an unusable default")
eq(assignedMacro("alt-ctrl-"), "Spell 2", "unusable modifiers also fall back")
eq(config.GetForeverMountAssignment("ctrl+alt"), 6, "unusable assignment remains saved")
eq(panel.slots["ctrl+alt"].row:IsShown(), true, "temporarily unusable assignments remain editable")
ctrl, alt = true, true
widget.scripts.OnEnter(widget)
eq(e.GameTooltip.bindings["Ctrl+Alt"].name:find("Unavailable", 1, true) ~= nil, true, "tooltip identifies an unusable assignment")
eq(e.GameTooltip.bindings.Default.active, true, "unusable modifier highlights the actual fallback")
eq(e.GameTooltip.bindings.Default.name:find("Journal 2", 1, true) ~= nil, true, "default tooltip shows the mount the button will use")
widget.scripts.OnLeave(widget)
e.MountJournal:Hide()
eq(panel:IsShown(), false, "switching to another tab hides the config")

for id = 1, 8 do Usable[id] = false end
rank, learned = 0, 33388
fire("SKILL_LINES_CHANGED")
flushTimers()
eq(slot:IsShown(), true, "known localized apprentice spell detects riding without a skill row")
eq(mount._isPlaceholder, true, "loss of usable mounts clears the real action")
eq(widget:GetAttribute("alt-ctrl-shift-macrotext1"), nil, "placeholder clears stale modifier attributes")
widget.scripts.OnEnter(widget)
eq(e.GameTooltip.lines[1], "No collected mount is usable", "placeholder tooltip explains journal availability")
widget.scripts.OnLeave(widget)

-- Exercise the normal mount widget and shared painter with separate owned and
-- in-location journal answers. Generic spell usability can disagree with the journal.
local indoors, readyByID = false, {}
local liveQueries = 0
local collectionUsability = e.C_MountJournal.GetMountUsabilityByID
e.C_MountJournal.GetMountUsabilityByID = function(id, checkIndoors)
    if not checkIndoors then return collectionUsability(id, checkIndoors) end
    liveQueries = liveQueries + 1
    return not indoors and readyByID[id] == true
end
e.C_MountJournal.GetMountFromSpell = function(id) return id - 50 end
e.IsIndoors = function() return indoors end
e.FluxButton = {}
e.Flux = { Client = e.FLUX_API, EBS = { buttons = {} }, Spell = { IsUsable = function() return false, false end } }
assert(loadfile(root .. "/ExtraButtonSystem/Engine/Paint.lua", "t", e))("_FluxUI", { Flux = e.Flux })
local paint = e.Flux.EBS.Paint
paint.UpdateCooldown, paint.UpdateRange, paint.UpdateGlow, paint.UpdateChecked = noop, noop, noop, noop

local icon = frame()
function icon:SetTexture(texture) self.texture = texture end
function icon:SetVertexColor(r) self.red = r end
local liveButton = { WIcon = icon, Widget = frame(), SlotFrame = frame() }
function liveButton:SetAction(actionType, actionValue)
    self.ActionType, self.ActionValue = actionType, actionValue
    self.Widget:SetAttribute("type", "macro")
    self.Widget:SetAttribute("macrotext", actionValue)
end
e.Flux.EBS.buttons[1] = liveButton
mount._grid = { CreateButton = function() return liveButton end }
mount._button = nil
mount._isPlaceholder = false
mount._lastJournalMacro = nil
mount.UpdateTexture = updateMountTexture
rank, ctrl, shift, alt = 75, false, false, false
Usable[1], Usable[5], readyByID[1] = true, true, true
mount.InvalidateCollectedMountCache()
mount.InvalidateRidingSkillCache()
mount.CreateButton()
mount.Update()
eq(icon.texture, 101, "default mount owns the real face")
eq(icon.red, 1, "available journal mount uses standard full brightness")

indoors = true
fire("ZONE_CHANGED_INDOORS")
eq(icon.red, 0.4, "the modifier icon refresh preserves the shared unusable tint indoors")
eq(liveButton.Widget:GetAttribute("macrotext"), "#showtooltip\n" .. mountMacro("Spell 1"), "temporary restrictions preserve the assigned action")
indoors = false
fire("ZONE_CHANGED")
eq(icon.red, 1, "leaving the restricted location restores the shared usable tint")

ctrl, shift = true, true
checkModifiers()
eq(liveButton.MountId, 5, "modifier refresh pins the same journal mount as the icon")
eq(icon.texture, 105, "modifier changes icon")
eq(icon.red, 0.4, "the modifier's own blocked mount darkens immediately")
local settledQueries = liveQueries
for _ = 1, 25 do checkModifiers() end
eq(liveQueries, settledQueries, "steady modifier polling performs no usability queries")
readyByID[5] = true
paint.FlushEval({ ["ebs.usable"] = true })
eq(icon.red, 1, "ordinary shared usability refresh lights the assigned mount")

combat = true
local beforeCombatQueries = liveQueries
fire("PLAYER_REGEN_DISABLED")
eq(icon.red, 0.4, "combat dims the visible mount without a modifier change")
eq(liveQueries, beforeCombatQueries, "combat gate avoids the native journal read")
ctrl, shift = false, false
checkModifiers()
eq(icon.texture, 105, "combat keeps the icon latched")
combat = false
fire("PLAYER_REGEN_ENABLED")
eq(icon.texture, 101, "combat exit restores the current modifier face")
eq(icon.red, 1, "combat exit restores usability")

mounted = true
mount.LockToMount("Spell 5", 105, 55)
readyByID[5] = false
liveButton:UpdateUsable()
eq(liveButton.MountId, 5, "the locked face retains its mount identity")
eq(icon.red, 0.4, "the locked face uses its own usability result")
mounted = false
fire("PLAYER_MOUNT_DISPLAY_CHANGED")
eq(icon.texture, 101, "unlock returns to the default icon")
eq(icon.red, 1, "unlock returns to the default usability tint")

local widgetName, bindings = "ForeverMountButton", {}
function liveButton.Widget:GetName() return widgetName end
e.GetBindingKey = function(command) if command == "FLUXGRIDSMARTMOUNT" then return "M" end end
e.ClearOverrideBindings = function() bindings = {} end
e.SetOverrideBindingClick = function(_, _, key, name, button) bindings[key] = name .. ":" .. button end
mount.UpdateMountKeybinding, mount.ClearMountKeybinding = updateMountKeybinding, clearMountKeybinding
fire("PLAYER_ENTERING_WORLD", true, false)
flushTimers()
local defaultMacro = "#showtooltip\n" .. mountMacro("Spell 1")

-- A genuine placeholder has cleared the secure attributes. The same saved
-- macro must be written again when the cached journal data returns.
journalReady = false
fire("MOUNT_JOURNAL_USABILITY_CHANGED")
eq(mount._isPlaceholder, true, "unavailable journal temporarily clears the action")
eq(liveButton.Widget:GetAttribute("type"), nil, "placeholder cleared the secure click type")
journalReady = true
fire("MOUNT_JOURNAL_USABILITY_CHANGED")
eq(liveButton.Widget:GetAttribute("type"), "macro", "same-macro recovery restores the secure click type")
eq(liveButton.Widget:GetAttribute("macrotext"), defaultMacro, "same-macro recovery restores the default action")

fire("PLAYER_LEAVING_WORLD")
journalReady, rank = false, 0
fire("MOUNT_JOURNAL_USABILITY_CHANGED")
eq(liveButton.Widget:IsShown(), true, "cold journal and skill data cannot hide the button while leaving the world")
eq(liveButton.Widget:GetAttribute("macrotext"), defaultMacro, "load-screen events retain the current secure action")
eq(bindings.M, widgetName .. ":LeftButton", "load-screen events retain the mount binding")

fire("PLAYER_ENTERING_WORLD", false, false)
fire("PLAYER_LEAVING_WORLD")
flushTimers()
eq(liveButton.Widget:IsShown(), true, "an older world's recovery cannot replace the action during another load")
fire("PLAYER_ENTERING_WORLD", false, false)
fire("ZONE_CHANGED_NEW_AREA")
eq(#timers, 1, "zone events share the single outstanding arrival check")
eq(timers[1].delay, 0.25, "first world-entry check waits for client data")
flushTimers()
eq(liveButton.Widget:GetAttribute("macrotext"), defaultMacro, "first cold arrival check retains the existing macro")
eq(#timers, 1, "cold journal schedules one final check")
eq(timers[1].delay, 0.75, "final check is one second after arrival")
journalReady, rank = true, 75
liveButton.Widget:SetAttribute("type", nil)
liveButton.Widget:SetAttribute("macrotext", nil)
liveButton.Widget:SetAttribute("ctrl-shift-macrotext1", nil)
liveButton.Widget:SetAttribute("*macrotext2", nil)
bindings = {}
flushTimers()
eq(#timers, 0, "settled arrival leaves no repeating mount timers")
eq(liveButton.Widget:GetAttribute("type"), "macro", "settled arrival re-arms a lost click type")
eq(liveButton.Widget:GetAttribute("macrotext"), defaultMacro, "settled arrival restores the unchanged base macro")
eq(liveButton.Widget:GetAttribute("ctrl-shift-macrotext1"), mountMacro("Spell 5"), "settled arrival restores the exact modifier")
eq(liveButton.Widget:GetAttribute("*macrotext2"), "#showtooltip\n/click FluxMacroProxy_MountOpenUI", "settled arrival restores journal right-click")
eq(bindings.M, widgetName .. ":LeftButton", "settled arrival restores a lost mount binding")

mounted = true
mount.LockToMount("Spell 5", 105, 55)
fire("PLAYER_LEAVING_WORLD")
fire("PLAYER_ENTERING_WORLD", false, false)
flushTimers()
eq(mount._isLocked, true, "arrival preserves a sticky mount when the player is still mounted")
eq(icon.texture, 105, "arrival retains the valid sticky mount face")

fire("PLAYER_LEAVING_WORLD")
mounted = false
combat = true
fire("PLAYER_ENTERING_WORLD", false, false)
flushTimers()
eq(mount._isLocked, false, "arrival clears a stale sticky mount after dismount during travel")
eq(mount._pendingUpdate, true, "combat defers secure re-arming after travel")
combat = false
fire("PLAYER_REGEN_ENABLED")
flushTimers()
eq(liveButton.Widget:GetAttribute("macrotext"), defaultMacro, "combat exit re-arms the default action")
eq(liveButton.Widget:GetAttribute("ctrl-shift-macrotext1"), mountMacro("Spell 5"), "combat exit re-arms the modifier action")
eq(icon.texture, 101, "combat exit restores the selected face after travel")

local wisp = liveButton._fluxMountedWisp
local liveWidget = liveButton.Widget
local function clickMount(prefix)
    local body = liveWidget:GetAttribute(prefix .. "macrotext1") or liveWidget:GetAttribute("macrotext")
    if mounted and (body:find("/dismount [mounted]", 1, true)
        or (combat and body:find("/dismount [combat,mounted]", 1, true))) then
        mounted = false
    end
    if not combat and not mounted then return body:match("/cast %[nocombat,nomounted%] ([^\n]+)") end
end
eq(wisp.texture, "Interface\\Icons\\Spell_Nature_WispSplode", "mounted face uses the FluxUI wisp art")
eq(wisp:IsShown(), false, "unmounted face uses the underlying mount icon")
mounted = true
fire("PLAYER_MOUNT_DISPLAY_CHANGED")
eq(wisp:IsShown(), true, "mounting through the journal shows the wisp")
eq(liveWidget:GetAttribute("macrotext"), "/dismount [mounted]", "mounting through the journal arms dismount")
eq(liveWidget:GetAttribute("ctrl-shift-macrotext1"), nil, "all modifier routes inherit the mounted action")
liveWidget.scripts.OnEnter(liveWidget)
eq(e.GameTooltip.title, "Dismount", "mounted tooltip describes the active action")
combat = true
fire("PLAYER_REGEN_DISABLED")
journalReady, rank = false, 0
fire("MOUNT_JOURNAL_USABILITY_CHANGED")
fire("SKILL_LINES_CHANGED")
local readsDuringCombat = nativeReads
eq(wisp:IsShown(), true, "combat keeps the active dismount wisp")
eq(liveWidget:GetAttribute("macrotext"), "/dismount [mounted]", "combat preserves the armed dismount action")

eq(clickMount(""), nil, "the mounted click has no summon action under lockdown")
eq(mounted, false, "the mounted click dismounts in combat in the macro model")
fire("PLAYER_MOUNT_DISPLAY_CHANGED")
eq(wisp:IsShown(), false, "dismount hides the wisp during combat")
eq(liveWidget:IsShown(), true, "dismount in combat retains the mount button")
eq(icon.red, 0.4, "dismount restores the underlying combat-dimmed face")
eq(e.GameTooltip.bindings.Default.name:find("Journal 1", 1, true) ~= nil, true, "combat tooltip retains the confirmed mount selection")
eq(nativeReads, readsDuringCombat, "combat collection notifications leave the confirmed journal cache readable")
eq(clickMount(""), nil, "another click while unmounted in combat remains blocked")
liveWidget.scripts.OnLeave(liveWidget)

combat = false
fire("PLAYER_REGEN_ENABLED")
flushTimers()
eq(liveWidget:IsShown(), true, "first cold combat-exit sample keeps the button visible")
journalReady, rank = true, 75
flushTimers()
eq(liveWidget:GetAttribute("macrotext"), defaultMacro, "settled combat exit restores mounting")
eq(bindings.M, widgetName .. ":LeftButton", "mounting and dismount preserve the hotkey")
eq(wisp:IsShown(), false, "restored mounting keeps the wisp hidden")
eq(clickMount("ctrl-shift-"), "Spell 5", "combat recovery restores the exact summon route")

-- The normal action must also dismount if lockdown starts before mounted
-- state can replace the default or exact modifier attributes.
combat, mounted = true, true
fire("PLAYER_REGEN_DISABLED")
fire("PLAYER_MOUNT_DISPLAY_CHANGED")
eq(wisp:IsShown(), true, "the mounted texture can refresh under lockdown")
eq(liveWidget:GetAttribute("macrotext"), defaultMacro, "default action carries an armed combat dismount")
eq(liveWidget:GetAttribute("ctrl-shift-macrotext1"), mountMacro("Spell 5"), "exact override also carries an armed combat dismount")
eq(clickMount("ctrl-shift-"), nil, "combat dismount on an unchanged modifier macro skips summoning")
eq(mounted, false, "unchanged modifier macro dismounts when combat wins the event race")
fire("PLAYER_MOUNT_DISPLAY_CHANGED")
eq(wisp:IsShown(), false, "the event race still removes the wisp immediately")
combat = false
fire("PLAYER_REGEN_ENABLED")
flushTimers()

mounted, taxi = true, true
fire("PLAYER_MOUNT_DISPLAY_CHANGED")
eq(wisp:IsShown(), false, "a taxi reported as mounted does not show the wisp")
eq(liveWidget:GetAttribute("macrotext"), defaultMacro, "a taxi keeps the normal mount action")
liveWidget.scripts.OnEnter(liveWidget)
eq(e.GameTooltip.title, "Mounts", "taxi tooltip uses the mount list")
liveWidget.scripts.OnLeave(liveWidget)

mounted, taxi = false, false
fire("PLAYER_CONTROL_GAINED")
eq(wisp:IsShown(), false, "taxi landing keeps the wisp hidden")

mounted = true
fire("PLAYER_MOUNT_DISPLAY_CHANGED")
eq(wisp:IsShown(), true, "a personal mount after landing still shows the wisp")
taxi = true
fire("PLAYER_CONTROL_LOST")
eq(wisp:IsShown(), false, "taxi boarding control event clears a previously shown wisp")
eq(liveWidget:GetAttribute("macrotext"), defaultMacro, "boarding restores the normal mount route")

taxi, mounted = false, false
fire("PLAYER_CONTROL_GAINED")
mounted = true
fire("PLAYER_MOUNT_DISPLAY_CHANGED")
combat, taxi = true, true
fire("PLAYER_CONTROL_LOST")
eq(wisp:IsShown(), false, "taxi wisp visibility can update without writing protected attributes")

combat, taxi, mounted = false, false, false
fire("PLAYER_CONTROL_GAINED")
fire("PLAYER_REGEN_ENABLED")
flushTimers()
local function refreshUsability()
    paint.FlushEval({ ["ebs.usable"] = true })
end
eq(icon.red, 1, "the living player can use a mount outdoors")
dead = true
fire("PLAYER_DEAD")
local beforeDeathReads = liveQueries
refreshUsability()
eq(icon.red, 0.4, "death dims the mount despite a positive journal answer")
eq(liveQueries, beforeDeathReads, "death stops the live journal read")
journalReady, rank = false, 0
fire("MOUNT_JOURNAL_USABILITY_CHANGED")
eq(liveWidget:GetAttribute("macrotext"), defaultMacro, "death keeps the selected mount action")
eq(bindings.M, widgetName .. ":LeftButton", "death keeps the mount binding")

dead, ghost = false, true
fire("PLAYER_ALIVE")
refreshUsability()
eq(icon.red, 0.4, "releasing spirit keeps the mount dim")
liveWidget.scripts.OnEnter(liveWidget)
eq(e.GameTooltip.bindings.Default.active, false, "ghost tooltip keeps the mount without the ready highlight")
eq(e.GameTooltip.lines[1], "You must be alive to mount", "ghost tooltip explains the restriction")
liveWidget.scripts.OnLeave(liveWidget)
local combinedDeadCheck = e.UnitIsDeadOrGhost
e.UnitIsDeadOrGhost = nil
refreshUsability()
eq(icon.red, 0.4, "ghost fallback works without the combined API")
e.UnitIsDeadOrGhost = combinedDeadCheck

ghost, journalReady, rank = false, true, 75
fire("PLAYER_UNGHOST")
refreshUsability()
flushTimers()
eq(icon.red, 1, "resurrection restores the standard usable tint")
eq(liveWidget:GetAttribute("macrotext"), defaultMacro, "resurrection re-arms the normal mount")

mounted = true
fire("PLAYER_MOUNT_DISPLAY_CHANGED")
eq(wisp:IsShown(), true, "a living mounted player shows a wisp")
combat, dead = true, true
fire("PLAYER_DEAD")
refreshUsability()
eq(wisp:IsShown(), false, "death hides the wisp even with a stale mounted flag in combat")
eq(icon.red, 0.4, "the mount face underneath the wisp is dim")

combat, dead, mounted = false, false, false
fire("PLAYER_UNGHOST")
flushTimers()
mounted, taxi = true, true
fire("PLAYER_CONTROL_LOST")
refreshUsability()
eq(icon.red, 0.4, "a taxi ride also blocks mounting")
mounted, taxi = false, false
fire("PLAYER_CONTROL_GAINED")
refreshUsability()
eq(icon.red, 1, "landing restores usability")
print(("Forever mount config: %d checks PASS"):format(checks))
