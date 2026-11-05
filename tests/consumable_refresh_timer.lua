-- Loaded-module timer contract: count down to refresh eligibility, not buff expiry.
local function read(path)
    local file = assert(io.open(path, "rb"))
    local body = file:read("*a")
    file:close()
    return body
end

local consumablesSource = read(arg[1] or "ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua")
local gridSource = read(arg[2] or "ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua")
local configSource = read((arg[3] and arg[3] ~= "baseline") and arg[3]
    or "ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua")
local baseline = arg[3] == "baseline" or arg[4] == "baseline"
local checks, now, paintCalls = 0, 100, 0
local function eq(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local secret = {}
local env = setmetatable({}, { __index = _G })
env._G = env
env.GetTime = function() return now end
env.Flux = {
    Secrets = {
        IsSecretValue = function(value) return value == secret end,
        CanAccessValue = function() return true end,
    },
    Bars = { Stance = { SyncAuraCountdown = function() end } },
    EBS = { Paint = { UpdateCooldown = function() paintCalls = paintCalls + 1 end } },
}
env._FluxUI_CharSavedVars = {
    consumables = { activePreset = "default", refreshThreshold = 300,
        presets = { default = { items = {} } } },
}
env.SlashCmdList = {}
env.CreateFrame = function()
    return { RegisterEvent = function() end, RegisterUnitEvent = function() end,
        SetScript = function() end }
end
env.C_Item = { GetItemCooldown = function()
    return { startTime = 100, duration = 60, isEnabled = true }
end }

assert(load(consumablesSource, "Consumables.lua", "t", env))("_FluxUI", {})
assert(load(gridSource, "FluxConsumablesGridUI.lua", "t", env))()
assert(load(configSource, "ConsumablesConfig.lua", "t", env))()
local cons, grid = env.FluxNCConsumables, env.FluxConsumablesGridUI
local buff = { expirationTime = 1900, duration = 1800, maxDuration = 1800,
    durationObject = {}, timeMod = 1 }
cons.IsChronoboonItem = function(id) return id == 99 end
cons.IsSuperchargedChronoboonItem = function() return false end
cons.FindBuffForItem = function(id) return id == 123 and buff or nil end

local function makeCell()
    local cell = { cooldown = { shown = false }, timerText = { shown = false } }
    function cell.cooldown:SetCooldown(start, duration)
        self.start, self.duration = start, duration
    end
    function cell.cooldown:Show() self.shown = true end
    function cell.cooldown:Hide() self.shown = false end
    function cell.timerText:SetText(value) self.text = value end
    function cell.timerText:SetTextColor() end
    function cell.timerText:Show() self.shown = true end
    function cell.timerText:Hide() self.shown = false end
    return cell
end

local cell = makeCell()
grid.UpdateCellCooldown(cell, 123)
eq(cell.cooldown.shown, true, "active buff swipe visible")
eq(cell.cooldown.start, 100, "buff swipe starts at application")
eq(cell.cooldown.duration, baseline and 1800 or 1500, "swipe ends at refresh point")
eq(cell.timerText.text, baseline and "30m" or "25m", "config cell countdown")

local btn = {}
cons.UpdateBuffCooldown(btn, buff)
eq(btn.StanceBuffExpirationTime, baseline and 1900 or 1600, "button timer expiration")
eq(btn.StanceBuffCooldownDuration, baseline and 1800 or 1500, "button timer duration")
if not baseline then
    eq(btn.StanceBuffDurationObject, nil, "full aura duration object not reused")
    local timer = cons.GetRefreshTimerInfo(buff)
    eq(timer.remaining, 1500, "refresh remaining")
    eq(timer.startTime, 100, "refresh timer start")

    local modded = { expirationTime = 3700, maxDuration = 3600, timeMod = 2 }
    local modTimer = cons.GetRefreshTimerInfo(modded)
    eq(modTimer.expirationTime, 3100, "time-modified refresh deadline")
    eq(modTimer.remaining, 1500, "time-modified visible seconds")
    eq(cons.GetRefreshTimerInfo({ expirationTime = secret, durationObject = {} }), nil,
        "secret expiration has no invented numeric timer")

    local wisp = { IsWispLockPlaceholder = true, WCooldown = makeCell().cooldown,
        WIcon = { SetDesaturated = function() end, SetVertexColor = function() end },
        WCount = { Show = function() end, SetText = function() end } }
    cons.UpdateWispLockCooldown(wisp, 1800, buff)
    eq(wisp.WCooldown.duration, 1500, "wisp ring ends at refresh point")
    eq(wisp.StanceBuffExpirationTime, 1600, "wisp digits share refresh deadline")
    now = 1600
    cons.UpdateWispLockCooldown(wisp, 300, buff)
    eq(wisp.WCooldown.shown, false, "wisp ring clears at threshold")
    eq(wisp.FluxConsumableAuraCooldown, nil, "wisp digits clear at threshold")
    now = 100
end

now = 1600
grid.UpdateCellCooldown(cell, 123)
eq(cell.cooldown.shown, baseline and true or false, "config swipe clears at threshold")
eq(cell.timerText.shown, baseline and true or false, "config digits clear at threshold")
cons.UpdateBuffCooldown(btn, buff)
eq(btn.FluxConsumableAuraCooldown, baseline and true or nil, "button buff timer clears at threshold")
eq(paintCalls >= 2, true, "button repaints after timer change")

now = 100
local chrono = makeCell()
grid.UpdateCellCooldown(chrono, 99)
eq(chrono.cooldown.duration, 60, "Chronoboon item cooldown unchanged")
eq(chrono.timerText.text, "1m", "Chronoboon digits unchanged")

local config = env.FluxConsumablesConfig
local function editBox(value)
    return { GetText = function() return value end, HasFocus = function() return false end,
        SetText = function(self, text) self.value = text end }
end
config._frame = { thresholdMinutesBox = editBox("10"), thresholdSecondsBox = editBox("00") }
cell._mode, cell._itemId = "config", 123
cell.IsShown = function() return true end
config._gridHost = { allCells = { cell } }
cons.SetRefreshThreshold = function(seconds)
    env._FluxUI_CharSavedVars.consumables.refreshThreshold = seconds
end
grid.UpdateCellCooldown(cell, 123)
config.ApplyThresholdChange()
eq(cons.GetRefreshThreshold(), 600, "threshold setting saved")
eq(cell.timerText.text, baseline and "30m" or "20m", "open config cell refreshes after threshold edit")

print("Consumable refresh timer: " .. checks .. " checks passed")
