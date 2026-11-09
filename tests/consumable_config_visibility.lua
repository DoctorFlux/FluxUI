-- Desktop contract for saved consumables remaining visible in the editor.
local source = assert(io.open(arg[1] or "ExtraButtonSystem/NonCombatGrid/Buttons/ConsumablesConfig.lua", "rb"))
local body = source:read("*a")
source:close()
local baseline = arg[2] == "baseline"

local checks = 0
local function eq(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local saved = { 101 }
local visible = {}
local updateFails = false
local requested
local updateCalls = 0
local env = setmetatable({}, { __index = _G })
env._G = env
local retries = 0
env.C_Timer = { After = function() retries = retries + 1 end }
env.C_Item = { RequestLoadItemDataByID = function(id) requested = id end }
env.GetItemInfo = function(id) return id == 101 and "Existing Flask" or nil end
env.CreateFrame = function()
    return { RegisterEvent = function() end, RegisterUnitEvent = function() end, SetScript = function() end }
end
env.FluxNCConsumables = {
    IsChronoboonItem = function() return false end,
    AddItem = function(id)
        for _, old in ipairs(saved) do if old == id then return false end end
        saved[#saved + 1] = id
        return true
    end,
    GetConfigItems = function() return saved end,
    GetActivePreset = function() return "default" end,
    ForceUpdate = function()
        updateCalls = updateCalls + 1
        if updateFails then error("button update failed") end
    end,
}
env.FluxConsumablesGridUI = {
    RebuildConfigHost = function()
        visible = {}
        for _, id in ipairs(env.FluxNCConsumables.GetConfigItems()) do
            visible[#visible + 1] = id
        end
    end,
}

assert(load(body, "ConsumablesConfig.lua", "t", env))()
local config = env.FluxConsumablesConfig
config._frame = {
    _gridHost = {},
    presetDropdown = { FluxSetText = function(self, name) self.text = name end },
    ResizeFrame = function() end,
}

-- Saved entries render regardless of bag count or equipped weapon compatibility.
updateFails = true
local ok = pcall(config.RefreshUI)
eq(ok, false, "live button failure reproduced")
if baseline then
    eq(visible[1], nil, "old refresh stops before saved list")
else
    eq(visible[1], 101, "existing saved item rendered first")
end

updateFails = false
config.AddItem(202) -- valid cursor ID; item name has not loaded yet
eq(requested, 202, "uncached item metadata requested")
if baseline then
    eq(saved[2], nil, "old uncached item not persisted")
    eq(visible[2], nil, "old uncached item not shown")
    eq(config._frame.presetDropdown.text, nil, "old refresh stops before preset label")
    eq(retries, 1, "old delayed save scheduled")
else
    eq(saved[2], 202, "uncached item persisted immediately")
    eq(visible[2], 202, "uncached item shown in editor")
    eq(config._frame.presetDropdown.text, "default", "preset label remains visible")
    eq(retries, 0, "no delayed save required")
end
eq(updateCalls > 0, true, "live button still updates")
print("Consumable config visibility: " .. checks .. " checks passed")
