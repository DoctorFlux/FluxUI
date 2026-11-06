-- A newly gained food or flask aura advances the selected consumable on UNIT_AURA.
local sourcePath = arg[1] or "ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua"
local file = assert(io.open(sourcePath, "rb"))
local source = file:read("*a")
file:close()
local baseline = arg[2] == "baseline"
local checks = 0
local function eq(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected)
        .. ", got " .. tostring(actual))
end

for _, flavor in ipairs({ "modern", "legacy", "regular", "event_food", "event_regular" }) do
    local eventOnly = flavor == "event_food" or flavor == "event_regular"
    local regular = flavor == "regular" or flavor == "event_regular"
    local active, combat, now = false, false, 100
    local queued, calls, eventFrame = {}, {}, nil
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.GetTime = function() return now end
    env.InCombatLockdown = function() return combat end
    env.SlashCmdList = {}
    env.C_Timer = {
        After = function(delay, fn) queued[#queued + 1] = { delay, fn } end,
        NewTicker = function() return { Cancel = function() end } end,
    }
    env.CreateFrame = function()
        local frame = {
            events = {},
            RegisterEvent = function(self, event) self.events[event] = true end,
            RegisterUnitEvent = function(self, event)
                if flavor == "legacy" and event == "UNIT_AURA" then
                    error("unit-scoped aura registration unavailable")
                end
                self.events[event] = true
            end,
            SetScript = function(self, script, fn) self[script] = fn end,
        }
        eventFrame = frame
        return frame
    end
    env.C_Item = {
        GetItemCooldown = function() return { startTime = 0, duration = 0, isEnabled = true } end,
        GetItemSpell = function(id)
            if regular and id == 101 then
                return "Flask Aura", 777777
            end
        end,
    }
    env.Flux = { Secrets = { AurasRestricted = function() return false end } }
    env._FluxUI_CharSavedVars = {
        consumables = { activePreset = "default", refreshThreshold = 300,
            presets = { default = { items = { 101, 202 } } } },
    }
    if flavor ~= "legacy" then
        env.C_UnitAuras = {
            GetPlayerAuraBySpellID = function() return nil end,
            GetAuraDataByIndex = function(_, index)
                if active and not eventOnly and index == 1 then
                    return { name = regular and "Flask Aura" or "Well Fed",
                        spellId = 777777,
                        duration = 1800, expirationTime = 1900 }
                end
            end,
        }
    else
        env.C_UnitAuras = false
        env.UnitAura = function(_, index)
            if active and index == 1 then
                return "Well Fed", 123, 0, nil, 1800, 1900, nil, nil, nil, 777777
            end
        end
    end
    if regular then
        env.Flux.Aura = { GetDataByIndex = function() return nil end,
            GetPlayerAuraBySpellID = function() return nil end }
    end

    assert(load(source, "Consumables.lua", "t", env))("_FluxUI", {})
    local cons = env.FluxNCConsumables
    cons._registered = true
    cons._isPlaceholder = false
    cons._button = {
        ConsumablesItemID = 101,
        Widget = { IsShown = function() return true end,
            Show = function() end,
            SetAttribute = function(self, key, value) self[key] = value end },
        SetAction = function(self, kind, value)
            self.actionKind, self.actionValue = kind, value
        end,
    }
    env.GetItemInfo = function(id) return "Item " .. id end
    cons.GetItemCount = function() return 1 end
    cons.IsChronoboonItem = function() return false end
    cons.IsWeaponEnchantItem = function() return false end
    cons.ItemGrantsWellFed = function(id) return not regular and id == 101 end
    cons.HasSuperchargedChronoboonBuff = function() return false end
    cons.RefreshAuraTimerOverlay = function() end
    cons.RefreshTooltip = function() end
    if flavor == "event_regular" and not baseline then
        cons.CheckWispLockState = function() return false, 0, nil, true end
        cons.FindPreferredBagSlot = function() return nil end
        cons.UpdateKeybindings = function() end
        cons.RefreshConsumablesUsability = function() end
        cons.SetupRightClickConfig = function() end
        cons.ApplyChronoboonModifierLayer = function() end
        local realUpdateButtonState = cons.UpdateButtonState
        cons.UpdateButtonState = function(force)
            calls[#calls + 1] = force
            return realUpdateButtonState(force)
        end
    else
        cons.UpdateButtonState = function(force)
            calls[#calls + 1] = force
            cons._button.ConsumablesItemID = select(1, cons.GetFirstEligibleItem())
        end
    end
    cons.ApplyPendingChanges = function() end
    cons.RegisterEvents()
    eq(eventFrame.events.UNIT_AURA, true,
        flavor .. " player aura event remains registered")
    cons.SeedConsumableAuraWatchSig()
    eq(cons.GetFirstEligibleItem(), 101, flavor .. " first consumable selected before use")

    local function auraTimers()
        local n, latest = 0, nil
        for _, timer in ipairs(queued) do
            if timer[1] == 0.2 then
                n, latest = n + 1, timer[2]
            end
        end
        return n, latest
    end
    local initialAuraTimers = auraTimers()
    active = true
    eq(cons.GetFirstEligibleItem(), (eventOnly or (baseline and regular)) and 101 or 202,
        flavor .. " active aura selection")
    local auraDelta = eventOnly and { addedAuras = {
        { name = regular and "Flask Aura" or "Well Fed", spellId = 777777,
            auraInstanceID = 50, isHelpful = true,
            duration = 1800, expirationTime = 1900 },
    } } or nil
    eventFrame:OnEvent("UNIT_AURA", "player", auraDelta)
    if baseline and (regular or eventOnly) then
        eq(#calls, 0, "old regular lookup misses readable aura")
        eq(auraTimers(), initialAuraTimers, "old regular aura does not change watch signature")
        eq(cons._button.ConsumablesItemID, 101, "old regular item stays selected")
    else
        eq(#calls, 1, flavor .. " aura gain refreshes immediately")
        eq(calls[1], true, flavor .. " aura gain bypasses debounce")
        eq(cons._button.ConsumablesItemID, 202, flavor .. " next item selected on event")
        if flavor == "event_regular" and not baseline then
            eq(cons._button.actionKind, "item", "event flask binds actual item action")
            eq(cons._button.actionValue, 202, "event flask binds next item action")
            eq(cons._button.Widget.item1, "Item 202", "event flask updates secure button item")
        end
        eq(auraTimers(), initialAuraTimers, flavor .. " no delayed update for item change")
        eventFrame:OnEvent("UNIT_AURA", "player")
        eq(#calls, 1, flavor .. " unchanged aura does not rewrite action")
        if eventOnly then
            eventFrame:OnEvent("UNIT_AURA", "player", { isFullUpdate = true })
            eq(cons._button.ConsumablesItemID, 202,
                flavor .. " full update without deltas keeps observed buff")
            eventFrame:OnEvent("UNIT_AURA", "player", { removedAuraInstanceIDs = { 50 } })
            eq(cons._button.ConsumablesItemID, 101,
                flavor .. " explicit aura removal restores first item")
        else
            active = false
            cons._button.ConsumablesItemID = 101
            cons.SeedConsumableAuraWatchSig()
            active, combat = true, true
            eventFrame:OnEvent("UNIT_AURA", "player")
            eq(#calls, 1, flavor .. " combat does not write action")
            eq(cons._pendingUpdate, true, flavor .. " combat queues next item")
            combat = false
            eventFrame:OnEvent("PLAYER_REGEN_ENABLED")
            eq(cons._button.ConsumablesItemID, 202, flavor .. " combat exit advances")
        end
    end
end

do
    local enchanted, combat, calls, eventFrame = false, false, 0, nil
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.GetTime = function() return 100 end
    env.InCombatLockdown = function() return combat end
    env.SlashCmdList = {}
    env.C_Timer = { After = function() end,
        NewTicker = function() return { Cancel = function() end } end }
    env.C_Item = { GetItemCooldown = function()
        return { startTime = 0, duration = 0, isEnabled = true }
    end }
    env.C_PaperDollInfo = { GetTemporaryEnchantmentInfo = function(slot)
        if enchanted and slot == 16 then
            return { remainingTimeMs = 1800000, chargesRemaining = 1,
                enchantID = 999 }
        end
    end }
    env.Flux = { Secrets = { AurasRestricted = function() return false end } }
    env._FluxUI_CharSavedVars = { consumables = {
        activePreset = "default", refreshThreshold = 300,
        presets = { default = { items = { 101, 202 } } },
    } }
    env.CreateFrame = function()
        eventFrame = { events = {},
            RegisterEvent = function(self, event) self.events[event] = true end,
            RegisterUnitEvent = function(self, event) self.events[event] = true end,
            SetScript = function(self, name, fn) self[name] = fn end }
        return eventFrame
    end
    env.GetItemInfo = function(id) return "Item " .. id end
    assert(load(source, "Consumables.lua", "t", env))("_FluxUI", {})
    local cons = env.FluxNCConsumables
    cons._registered = true
    cons._button = { ConsumablesItemID = 101, ConsumablesIsWeaponEnchant = true,
        Widget = { IsShown = function() return true end,
            Show = function() end,
            SetAttribute = function(self, key, value) self[key] = value end },
        SetAction = function(self, kind, value)
            self.actionKind, self.actionValue = kind, value
        end }
    cons.GetItemCount = function() return 1 end
    cons.IsChronoboonItem = function() return false end
    cons.IsWeaponEnchantItem = function(id) return id == 101 end
    cons.CanEnchantApplyToSlot = function(_, slot) return slot == 16 end
    cons.GetWeaponEnchantSlot = function() return 16 end
    cons.HasSuperchargedChronoboonInBags = function() return false end
    cons.FindPreferredBagSlot = function() return nil end
    cons.CheckWispLockState = function() return false, 0, nil, true end
    cons.UpdateKeybindings = function() end
    cons.RefreshConsumablesUsability = function() end
    cons.RefreshTooltip = function() end
    cons.SetupRightClickConfig = function() end
    cons.ApplyChronoboonModifierLayer = function() end
    local realUpdateButtonState = cons.UpdateButtonState
    cons.UpdateButtonState = function(force)
        calls = calls + 1
        return realUpdateButtonState(force)
    end
    cons.RegisterEvents()
    eq(eventFrame.events.WEAPON_ENCHANT_CHANGED, not baseline or nil,
        "weapon enchant event registration")
    eq(eventFrame.events.UNIT_INVENTORY_CHANGED, not baseline or nil,
        "player inventory event registration")
    eq(cons.GetFirstEligibleItem(), 101, "weapon oil selected before enchant")
    enchanted = true
    eq(cons.GetFirstEligibleItem(), baseline and 101 or 202,
        "modern weapon enchant lookup selects next item")
    eventFrame:OnEvent("WEAPON_ENCHANT_CHANGED")
    if baseline then
        eq(calls, 0, "old weapon enchant event has no immediate redraw")
        eq(cons._button.ConsumablesItemID, 101, "old weapon oil stays selected")
    else
        eq(calls, 1, "weapon enchant event redraws immediately")
        eq(cons._button.ConsumablesItemID, 202, "weapon enchant advances button")
        eq(cons._button.actionKind, "item", "weapon enchant binds next item action")
        eq(cons._button.actionValue, 202, "weapon enchant binds next item ID")
        eq(cons._button.Widget.item1, "Item 202", "weapon enchant updates secure item")
        eventFrame:OnEvent("UNIT_INVENTORY_CHANGED", "target")
        eq(calls, 1, "other unit inventory change ignored")
    end
end

print("Consumable aura advance: " .. checks .. " checks passed")
