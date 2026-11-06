-- A newly gained food aura advances the selected consumable on UNIT_AURA.
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

for _, flavor in ipairs({ "modern", "legacy" }) do
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
        GetItemSpell = function() return nil end,
    }
    env.Flux = { Secrets = { AurasRestricted = function() return false end } }
    env._FluxUI_CharSavedVars = {
        consumables = { activePreset = "default", refreshThreshold = 300,
            presets = { default = { items = { 101, 202 } } } },
    }
    if flavor == "modern" then
        env.C_UnitAuras = {
            GetPlayerAuraBySpellID = function() return nil end,
            GetAuraDataByIndex = function(_, index)
                if active and index == 1 then
                    return { name = "Well Fed", spellId = 777777,
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

    assert(load(source, "Consumables.lua", "t", env))("_FluxUI", {})
    local cons = env.FluxNCConsumables
    cons._registered = true
    cons._isPlaceholder = false
    cons._button = {
        ConsumablesItemID = 101,
        Widget = { IsShown = function() return true end },
    }
    cons.GetItemCount = function() return 1 end
    cons.IsChronoboonItem = function() return false end
    cons.IsWeaponEnchantItem = function() return false end
    cons.ItemGrantsWellFed = function(id) return id == 101 end
    cons.HasSuperchargedChronoboonBuff = function() return false end
    cons.RefreshAuraTimerOverlay = function() end
    cons.RefreshTooltip = function() end
    cons.UpdateButtonState = function(force)
        calls[#calls + 1] = force
        cons._button.ConsumablesItemID = select(1, cons.GetFirstEligibleItem())
    end
    cons.ApplyPendingChanges = function() end
    cons.RegisterEvents()
    if baseline and flavor == "legacy" then
        eq(eventFrame.events.UNIT_AURA, nil,
            "old legacy fallback leaves player aura event unregistered")
    elseif not baseline then
        eq(eventFrame.events.UNIT_AURA, true,
            flavor .. " player aura event remains registered")
    end
    cons.SeedConsumableAuraWatchSig()
    eq(cons.GetFirstEligibleItem(), 101, flavor .. " food selected before eating")

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
    eq(cons.GetFirstEligibleItem(), 202, flavor .. " food aura makes next item eligible")
    eventFrame:OnEvent("UNIT_AURA", "player")
    if baseline then
        eq(#calls, 0, flavor .. " old aura path waits for coalesced update")
        local timerCount, timer = auraTimers()
        eq(timerCount, initialAuraTimers + 1, flavor .. " old 200ms wait")
        timer()
        eq(cons._button.ConsumablesItemID, 202, flavor .. " old eventual next item")
    else
        eq(#calls, 1, flavor .. " aura gain refreshes immediately")
        eq(calls[1], true, flavor .. " aura gain bypasses debounce")
        eq(cons._button.ConsumablesItemID, 202, flavor .. " next item selected on event")
        eq(auraTimers(), initialAuraTimers, flavor .. " no delayed update for item change")
        eventFrame:OnEvent("UNIT_AURA", "player")
        eq(#calls, 1, flavor .. " unchanged aura does not rewrite action")
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

print("Consumable aura advance: " .. checks .. " checks passed")
