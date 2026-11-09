-- lua Core/_tmp_clientguardsmoke.lua
-- Reproduce the observed failure mode: execute TOC-filtered files on every client.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function Load(path, env, ns)
    local chunk
    if setfenv then chunk = assert(loadfile(root .. path)); setfenv(chunk, env)
    else chunk = assert(loadfile(root .. path, "t", env)) end
    return chunk("_FluxUI", ns)
end
local secret = {}
local function Scenario(version, project, expectedCamelot, expectedMidnight, timer, strayFlag)
    local frames = 0
    local originalText = function() end
    local originalHealth = function() end
    local originalMana = function() end
    local health, mana = { UpdateTextStringWithValues = originalText }, { UpdateTextStringWithValues = originalText }
    local player = { unit = "player", healthbar = health, manabar = mana }
    local ns = { Flux = {}, API = {}, _FluxAPICompat = { tonumber = tonumber } }
    local env = setmetatable({
        WOW_PROJECT_ID = project, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CLASSIC = 2,
        WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5, WOW_PROJECT_WRATH_CLASSIC = 11,
        WOW_PROJECT_CATACLYSM_CLASSIC = 14, WOW_PROJECT_MISTS_CLASSIC = 19,
        GetBuildInfo = function() return version, "70391", "", expectedMidnight and 120105 or 11509 end,
        PlayerFrame = player, TextStatusBarMixin = { UpdateTextStringWithValues = originalText },
        UnitFrameHealthBar_Update = originalHealth, UnitFrameManaBar_Update = originalMana,
        C_Timer = timer and { NewTimedSignalMap = function() end } or {},
        -- Even Forever-looking globals must not override the Retail build.
        CharacterStatsPaneScrollBox = {}, CharacterStatsPanePetScrollBox = {},
        C_Item = { GetItemInfo = function() end },
        FLUX_API = {},
        issecretvalue = function(value) return rawequal(value, secret) end,
        canaccessvalue = function(value) return not rawequal(value, secret) end,
        canaccesssecrets = function() return false end,
        issecrettable = function(value) return rawequal(value, secret) end,
        canaccesstable = function(value) return not rawequal(value, secret) end,
        CreateFrame = function()
            frames = frames + 1
            assert(expectedCamelot, "compatibility module created a frame on the wrong client")
            return { RegisterEvent = function() end, SetScript = function() end, UnregisterAllEvents = function() end }
        end,
    }, { __index = _G })
    env._G = env
    Load("Core/Client_Camelot.lua", env, ns)
    assert((ns._isCamelotGameType == true) == expectedCamelot, "wrong runtime compatibility flag")
    assert(env.UnitFrameHealthBar_Update == originalHealth and env.UnitFrameManaBar_Update == originalMana,
        "compatibility file replaced native update functions")
    assert(health.UpdateTextStringWithValues == originalText and mana.UpdateTextStringWithValues == originalText)
    assert(env.TextStatusBarMixin.UpdateTextStringWithValues == originalText)
    if not expectedCamelot then
        assert(frames == 0)
        assert(rawget(env, "GetItemInfo") == nil, "compatibility alias escaped the client guard")
    else
        assert(env.GetItemInfo == env.C_Item.GetItemInfo, "Forever item compatibility was disabled")
    end
    if strayFlag then ns._isCamelotGameType = true end
    Load("Core/Client.lua", env, ns)
    assert(ns.Flux.Client.isCamelot == expectedCamelot, "Core misclassified the client")
    assert(ns._isCamelotGameType == expectedCamelot, "direct namespace readers still see a stray flag")
    assert(ns.Flux.Client.isLiveMidnight == (expectedMidnight and not expectedCamelot))
    Load("Core/FluxAPI/Client.lua", env, ns)
    assert(env.FLUX_API.isCamelot == expectedCamelot, "compatibility facade disagrees with Core")
    -- Also exercise the fallback when the Core flags are not available.
    local canonical = ns.Flux.Client
    ns.Flux.Client = nil
    Load("Core/FluxAPI/Client.lua", env, ns)
    assert(env.FLUX_API.isCamelot == expectedCamelot, "facade fallback misclassified the client")
    ns.Flux.Client = canonical
    Load("Core/API/Secrets.lua", env, ns)
    Load("Core/API/Secrets_Midnight.lua", env, ns)
    local beforeClassic = ns._secretsBackend
    Load("Core/API/Secrets_Classic.lua", env, ns)
    if expectedMidnight or expectedCamelot then
        assert(ns._secretsBackend == beforeClassic, "Classic stub overwrote the restricted backend")
        assert(ns._secretsBackendKind == "midnight")
        assert(ns.Flux.Secrets.IsSecretValue(secret) and not ns.Flux.Secrets.CanAccessValue(secret))
    else
        assert(ns._secretsBackendKind == "classic")
        assert(not ns.Flux.Secrets.IsSecretValue(secret) and ns.Flux.Secrets.CanAccessValue(secret))
    end
end

Scenario("12.1.5", 1, false, true, false, true)
Scenario("12.1.5", 1, false, true, true, true) -- misleading timer API + stray TOC flag
Scenario("1.16.1", 1, true, false, true, false) -- Forever
Scenario("1.16.1", 1, true, false, false, false) -- legacy mainline build, no timer probe
Scenario("1.15.9", 2, false, false, true, false) -- Era with a misleading timer
Scenario("2.5.6", 5, false, false, false, false) -- Anniversary
Scenario("5.5.4", 19, false, false, false, false) -- Mists
print("client guard smoke OK (Retail 12.1.5, stray flags/APIs, Forever, Era, Anniversary, Mists, unfiltered secret backend loads)")
