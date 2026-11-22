-- Client gates and native lookup for the published FluxUI overlay driver.
local checks = 0
local function check(condition, detail)
    checks = checks + 1
    assert(condition, detail)
end

local clients = {
    { name = "Retail", isRetail = true, isLiveMidnight = true, majorVersion = 12 },
    { name = "Forever", isRetail = true, isForever = true, isCamelot = true, majorVersion = 1 },
    { name = "Mists", isAnyClassic = true, isClassic = true, majorVersion = 5 },
    { name = "Era", isAnyClassic = true, isClassicEra = true, majorVersion = 1 },
    { name = "Anniversary", isAnyClassic = true, isAnniversary = true, isTBC = true, majorVersion = 2 },
}

for _, client in ipairs(clients) do
    local queryCount, opaque = 0, {}
    local health, cast, auras = {}, {}, {}
    local container = { healthBar = health }
    local frame = { unit = "nameplate1", HealthBarsContainer = container, CastBarsContainer = { castBar = cast }, AurasFrame = auras }
    local native = { UnitFrame = frame }
    local env = setmetatable({
        NamePlateConstants = { PREVIEW_UNIT_TOKEN = "client-settings-preview" },
        CreateFrame = function()
            return { RegisterEvent = function() end, SetScript = function() end, HookScript = function() end,
                Hide = function() end }
        end,
        issecretvalue = function(value) return value == opaque end,
        C_NamePlate = {
            GetNamePlateForUnit = function(unit, includeForbidden)
                assert(not includeForbidden)
                queryCount = queryCount + 1
                if unit == "nameplate1" then return native end
            end,
        },
    }, { __index = _G })
    env._G = env
    local ns = { Flux = { Client = client } }
    local loader
    if setfenv then loader = setfenv(assert(loadfile("NamePlates/Core.lua")), env)
    else loader = assert(loadfile("NamePlates/Core.lua", "t", env)) end
    loader("_FluxUI", ns)
    local plates = ns.Flux.NamePlates
    check(plates.IsThreatSupported() and plates.IsLevelSupported() == not client.isLiveMidnight,
        client.name .. " keeps published threat and level support")
    check(plates.IsClassicFamily() == (client.isAnyClassic == true)
        and plates.IsLiveClient() == (client.isLiveMidnight == true),
        client.name .. " resolves the installed client family")
    check(plates.IsSecretClient() == (client.isRetail == true),
        client.name .. " keeps the published secret-aware client policy")
    check(plates.IsSecret(opaque) and not plates.IsUsable(opaque) and plates.BoolTest(opaque, false) == false,
        client.name .. " rejects inaccessible inputs before reading them as values")
    check(plates.GetPlate(plates.PREVIEW_UNIT) == nil and queryCount == 0,
        client.name .. " the settings preview token never reaches live plate lookup")
    local foundFrame, foundPlate, foundContainer, foundHealth = plates.GetParts("nameplate1")
    check(foundFrame == frame and foundPlate == native and foundContainer == container and foundHealth == health,
        client.name .. " reads the client's existing plate and health bar")
    check(foundFrame.CastBarsContainer.castBar == cast and foundFrame.AurasFrame == auras,
        client.name .. " native cast and aura widgets have their original owners")
    check(plates.GetPlate("nameplate2") == nil,
        client.name .. " absent nameplates have no replacement frame")
end

print(("PASS nameplate client compatibility: %d desktop checks"):format(checks))
