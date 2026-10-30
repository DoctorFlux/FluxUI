-- lua tests/raid_owned_settings.lua
-- Flux raid options remain effective when native compact-frame CVars are guarded.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function read(path)
    local file = assert(io.open(root .. path, "r"))
    local source = file:read("*a")
    file:close()
    return source
end
local function part(source, first, last)
    local start = assert(source:find(first, 1, true))
    local finish = assert(source:find(last, start, true))
    return source:sub(start, finish - 1)
end
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end

local secretClient = true
local db = { useClassColors = true, displayPowerBar = true,
    healthText = "perc", displayBuffs = true, displayDebuffs = true }
local env = {
    FluxRaidVisuals = {},
    FluxOptions = { GetRaidFrameDB = function() return db end },
    C_CVar = { GetCVar = function(cvar)
        if cvar == "raidFramesHealthText" then return "none" end
    end },
    FluxRaid_GetCVarBool = function() return false end,
    Compat = { GetHealthPercent = function() return 75 end },
    UnitOf = function(frame) return frame.unit end,
    UnitIsConnected = function() return true end,
    UnitIsDeadOrGhost = function() return false end,
    IsSecret = function() return false end,
    ns = { Flux = { BlizzardSettings = { Write = {
        IsSecretClient = function() return secretClient end,
    } } } },
}
setmetatable(env, { __index = _G })

local visuals = read("RaidFrame/FluxRaidVisuals.lua")
assert(load(part(visuals, "function FluxRaidVisuals.UseOwnRaidSettings()",
    "function FluxRaidVisuals.SyncAuraDisplayOptions"), "raid owner policy", "t", env))()
check(env.FluxRaidVisuals.UseOwnRaidSettings(), "protected clients select Flux-owned raid options")

local preview = read("RaidFrame/FluxRaidPreview.lua")
local previewOption = assert(load(part(preview, "local function PreviewRaidSetting(optionKey, cvar, fallback)",
    "local function ApplyDemoAuras") .. "\nreturn PreviewRaidSetting", "raid preview settings", "t", env))()
check(previewOption("useClassColors", "raidFramesDisplayClassColor", true),
    "class colors use Flux options despite native CVar off")
check(previewOption("displayPowerBar", "raidFramesDisplayPowerBars", true),
    "power bars use Flux options despite native CVar off")
check(previewOption("healthText", "raidFramesHealthText", "perc") == "perc",
    "preview health text uses Flux option despite native CVar set to none")
db.displayPowerBar = false
check(not previewOption("displayPowerBar", "raidFramesDisplayPowerBars", true),
    "deliberate Flux power-bar toggle remains effective")
db.displayPowerBar = true

local unit = read("RaidFrame/FluxRaidUnit.lua")
assert(load(part(unit, "function FluxRaid_UpdateStatusText(frame)",
    "function FluxRaid_UpdateSelectionHighlight(frame)"), "raid unit status text", "t", env))()
local fs = { visible = false }
function fs:Hide() self.visible = false end
function fs:Show() self.visible = true end
function fs:SetFormattedText(fmt, value) self.text = string.format(fmt, value) end
function fs:SetText(value) self.text = value end
local frame = { statusText = fs, optionTable = { healthText = "perc" }, unit = "raid1" }
env.FluxRaid_UpdateStatusText(frame)
check(fs.visible and fs.text == "75%", "live Flux raid unit keeps percent text")

secretClient = false
check(not env.FluxRaidVisuals.UseOwnRaidSettings(), "Classic keeps native raid CVar policy")
check(not previewOption("useClassColors", "raidFramesDisplayClassColor", true)
    and previewOption("healthText", "raidFramesHealthText", "perc") == "none",
    "Classic preview still reflects native settings")
env.FluxRaid_UpdateStatusText(frame)
check(not fs.visible, "Classic raid unit still honors native health-text CVar")

print("raid owned settings: " .. checks .. " checks passed")
