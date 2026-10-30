-- lua tests/defaults_first_login.lua
-- Execute the production new-character path with both CVarInfo return shapes.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local file = assert(io.open(root .. "FluxDefaultSettings.lua", "r"))
local source = file:read("*a")
file:close()
local first = assert(source:find("local function IsCharacterCVar(cvar)", 1, true))
local last = assert(source:find("-- Check client CVar reverts", first, true))
local code = source:sub(first, last - 1)
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end

for _, shape in ipairs({ "table", "tuple", "legacy" }) do
    local writes, bits, raid, chat = {}, {}, 0, 0
    local function info(cvar)
        if cvar == "missing" then error("unsupported") end
        local character = cvar == "character" or cvar == "characterBits"
            or cvar == "uiscale" or cvar == "cameraDistanceMaxZoomFactor"
        if shape == "table" then
            return { isStoredServerCharacter = character }
        end
        return "current", "default", not character, character
    end
    local env = {
        _G = false,
        FluxDefaultSettings = {},
        FLUX_DEFAULTS = { account = "accountValue", character = "characterValue", missing = "missingValue" },
        GetOptimalUIScale = function() return "0.80" end,
        BlizzardSettings = {
            Write = {
                Run = function(_, fn) fn() end,
                CVar = function(cvar, value) writes[cvar] = value end,
            },
            Nameplates = {
                ApplyBitfields = function(_, include)
                    for _, cvar in ipairs({ "accountBits", "characterBits" }) do
                        if include(cvar) then bits[cvar] = true end
                    end
                end,
            },
        },
        print = function() end,
    }
    env.FluxDefaultSettings.GetMaxCameraDistanceZoomFactor = function() return 3.4 end
    env._G = env
    if shape == "legacy" then
        env.GetCVarInfo = info
    else
        env.C_CVar = { GetCVarInfo = info }
    end
    setmetatable(env, { __index = _G })
    assert(load(code, "new character defaults", "t", env))()
    env.FluxDefaultSettings.ApplyRaidFrameSettings = function() raid = raid + 1 end
    env.FluxDefaultSettings.ApplyChatSettings = function() chat = chat + 1 end
    env.FluxDefaultSettings.ApplyCharacterFirstLogin()
    check(writes.character == "characterValue", shape .. ": character CVar applied")
    check(writes.account == nil and writes.missing == nil, shape .. ": account and missing CVars preserved")
    check(bits.characterBits and not bits.accountBits, shape .. ": only character bitfields applied")
    check(raid == 1 and chat == 1, shape .. ": raid and chat setup retained")
    check(env.FLUX_DEFAULTS.uiscale == "0.80"
        and env.FLUX_DEFAULTS.cameraDistanceMaxZoomFactor == "3.4",
        shape .. ": dynamic scale and camera recommendations resolved")
    check(writes.uiscale == "0.80" and writes.cameraDistanceMaxZoomFactor == "3.4",
        shape .. ": character-stored dynamic recommendations applied")
end

do
    local pending, fail = nil, false
    local saved = { characters = {} }
    local env = {
        FluxUI_DB = saved,
        FluxDefaultSettings = {},
        FLUX_DEFAULTS = { character = "1" },
        GetOptimalUIScale = function() return "0.80" end,
        C_CVar = { GetCVarInfo = function() return { isStoredServerCharacter = true } end },
        BlizzardSettings = { Write = {
            Run = function(_, fn) pending = fn; return false end,
            CVar = function() if fail then error("write failed") end end,
        } },
        print = function() end,
    }
    setmetatable(env, { __index = _G })
    env.FluxDefaultSettings.GetMaxCameraDistanceZoomFactor = function() return 3.4 end
    assert(load(code, "deferred character defaults", "t", env))()
    env.FluxDefaultSettings.ApplyRaidFrameSettings = function() end
    env.FluxDefaultSettings.ApplyChatSettings = function() end
    env.FluxDefaultSettings.ApplyCharacterFirstLogin("New-Realm")
    check(saved.characters["New-Realm"] == nil and pending, "queued work does not mark character seen")
    fail = true
    check(not pcall(pending) and saved.characters["New-Realm"] == nil, "failed queued work remains retryable")
    fail = false
    check(pending() and saved.characters["New-Realm"], "completed queued work marks character seen")
end

-- The full first-account route still reaches every established setup owner.
do
    local first = assert(source:find("function FluxDefaultSettings.Apply(force, deferBindings)", 1, true))
    local last = assert(source:find("-- Track last known display size", first, true))
    local writes, calls, fail = {}, {}, false
    local settings = { _resetDetection = {} }
    local env = {
        FluxDefaultSettings = settings,
        FLUX_DEFAULTS = { first = "1", second = "0" },
        FluxSkipCoupledDefaultCVar = function() return false end,
        FluxSetCVar = function(cvar, value) writes[cvar] = value; return true end,
        GetOptimalUIScale = function() return "0.75" end,
        C_Timer = { After = function() end },
        print = function() end,
    }
    for _, name in ipairs({ "SyncSettingsRegistryProxies", "ScheduleSoftTargetEnemyReassertFromDefaults",
            "ApplyKeybinds", "ApplySelfCastAndFocusCastDefaults", "ApplySpecialCVarSettings",
            "ApplyRaidFrameSettings", "ApplyChatSettings" }) do
        settings[name] = function()
            calls[name] = (calls[name] or 0) + 1
            if name == "ApplyKeybinds" and fail then error("binding setup failed") end
        end
    end
    settings.GetMaxCameraDistanceZoomFactor = function() return 2.6 end
    setmetatable(env, { __index = _G })
    assert(load(source:sub(first, last - 1), "first account defaults", "t", env))()
    fail = true
    check(not pcall(settings.Apply) and not env.FluxUI_DB.accountDefaultsApplied,
        "failed full setup leaves account flag unset")
    fail = false
    settings.Apply()
    check(env.FluxUI_DB.accountDefaultsApplied and writes.first == "1" and writes.second == "0",
        "first account applies scalar defaults and records success")
    check(writes.uiscale == "0.75" and writes.cameraDistanceMaxZoomFactor == "2.6",
        "first account resolves dynamic scale and camera defaults")
    for _, name in ipairs({ "SyncSettingsRegistryProxies", "ScheduleSoftTargetEnemyReassertFromDefaults",
            "ApplyKeybinds", "ApplySelfCastAndFocusCastDefaults", "ApplySpecialCVarSettings",
            "ApplyRaidFrameSettings", "ApplyChatSettings" }) do
        check(calls[name] and calls[name] >= 1, "first account reaches " .. name)
    end
    local bindingCalls = calls.ApplyKeybinds
    settings.Apply(true, true)
    check(calls.ApplyKeybinds == bindingCalls,
        "first login can defer the native binding reset until world entry")
end

-- AceDB's character defaults are resolved by its own bootstrap; every feature
-- selector must start on the shared branch for a fresh character.
do
    local env = {}
    assert(loadfile(root .. "AddonOptions/FluxOptionsDefaults.lua", "t", env))("_FluxUI", {})
    local defaults = env.FluxOptionsDefaults
    for _, key in ipairs({ "actionbarsSettingsScope", "layoutSettingsScope",
            "windowMoverSettingsScope", "microMenuSettingsScope", "raidFramesSettingsScope",
            "unitFramesSettingsScope", "statusBarsSettingsScope" }) do
        check(defaults.char[key] == "account", "fresh character defaults " .. key .. " to account")
    end
    check(defaults.char.useCharacterSpecific == false and defaults.profile.settingsScope == "account",
        "general profile starts on the account branch")
    check(type(defaults.global) == "table" and type(defaults.char) == "table"
        and type(defaults.profile) == "table", "AceDB profile, character and global domains remain defined")
end

-- Exercise the real nameplate pack's filter without changing its full-pack route.
do
    local file = assert(io.open(root .. "BlizzardSettings/Nameplates.lua", "r"))
    local source = file:read("*a")
    file:close()
    local writes = {}
    local write = {
        Exists = function() return true end,
        Bit = function(cvar, index, on)
            writes[#writes + 1] = { cvar, index, on }
            return true
        end,
    }
    local frame = { RegisterEvent = function() end, SetScript = function() end }
    local env = { Enum = { NamePlateInfoDisplay = { CurrentHealthValue = 1, RarityIcon = 2 } },
        CreateFrame = function() return frame end }
    setmetatable(env, { __index = _G })
    local ns = { Flux = { BlizzardSettings = { Write = write } } }
    assert(load(source, "nameplate pack", "t", env))("_FluxUI", ns)
    ns.Flux.BlizzardSettings.Nameplates.ApplyBitfields(false,
        function(cvar) return cvar == "nameplateInfoDisplay" end)
    check(#writes == 2, "character filter limits the real bitfield pack")
    check(writes[1][1] == "nameplateInfoDisplay" and writes[2][1] == "nameplateInfoDisplay",
        "filtered writes stay within the character CVar")
end

print("first-login defaults: " .. checks .. " checks passed")
