-- lua Core/_tmp_foreverbarstylesmoke.lua
-- Run the actual Flux styling helpers against Blizzard's Forever power-color
-- table. Forever uses complete exported Retail textures; Live keeps its atlas
-- names. Passing a cropped raw sheet to StatusBar loses its UVs in game.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function Read(path)
    local file = assert(io.open(root .. path, "r")); local text = file:read("*a"); file:close(); return text
end
local function Compile(text, env)
    if setfenv then local fn = assert(loadstring(text)); setfenv(fn, env); return fn end
    return assert(load(text, "Flux bar style fixture", "t", env))
end
local source = Read("UnitFrames/FluxUnitFrames_Shared.lua")
local start = assert(source:find('local TEXTURE_BAR = ', 1, true))
local finish = assert(source:find('-- Blizzard raid-frame absorb assets', start, true))
local healthStart = assert(source:find('function UF.UpdateHealthColor(', finish, true))
local healthEnd = assert(source:find('\n-- ---------------------------------------------------------------------------', healthStart, true))
local pcoSource = Read("UnitFrames/FluxPowerCostOverlay.lua")
local segStart = assert(pcoSource:find('function PCO.ApplySegmentArt(', 1, true))
local segEnd = assert(pcoSource:find('\nfunction PCO.UpdateOverlayColor', segStart, true))
local ghostStart = assert(pcoSource:find('local function MatchGhostArt(', 1, true))
local ghostEnd = assert(pcoSource:find('\nlocal function CommitPowerGhost', ghostStart, true))
local plain = "Interface\\TargetingFrame\\UI-StatusBar"
local function ColorEquals(actual, r, g, b, a)
    assert(actual[1] == r and actual[2] == g and actual[3] == b and actual[4] == (a or 1), table.concat(actual, ','))
end
local function Texture()
    return {
        Hide = function(self) self.hidden = true end,
        Show = function(self) self.hidden = false end,
        SetDesaturated = function(self, v) self.desaturated = v end,
        SetAlpha = function(self, v) self.alpha = v end,
        SetAtlas = function(self, v) self.atlas = v; self.texture = nil end,
        SetTexture = function(self, v) assert(type(v) ~= "number", "raw atlas sheet escaped its atlas"); self.texture = v; self.atlas = nil end,
        SetTexCoord = function(self, ...) self.coords = { ... } end,
        SetVertexColor = function(self, ...) self.color = { ... } end,
        SetBlendMode = function() end,
        ClearAllPoints = function() end,
        SetPoint = function() end,
        SetScale = function() end,
        GetHeight = function() return 20 end,
        GetWidth = function() return 50 end,
    }
end
local function Bar()
    local bar = { fill = Texture(), color = { 1, 1, 1, 1 } }
    function bar:SetStatusBarTexture(value)
        assert(type(value) == "string", "status bar received a raw atlas texture object")
        self.asset = value
        self.fill:SetAtlas(value)
    end
    function bar:GetStatusBarTexture() return self.fill end
    function bar:SetStatusBarColor(r, g, b, a) self.color = { r, g, b, a or 1 } end
    function bar:GetStatusBarColor() return (table.unpack or unpack)(self.color) end
    function bar:CreateTexture() return Texture() end
    function bar:GetWidth() return 100 end
    return bar
end
local function Boot(family, fallback, missingAtlases)
    local connected, dead, afk = true, false, false
    local client = { isCamelot = family == "forever", isForever = family == "forever", isLiveMidnight = family == "live" }
    local ns = { UnitFrames = {}, API = {}, Flux = { Client = not fallback and client or nil } }
    local UF = ns.UnitFrames
    UF.UnitIsAFKDisplay = function() return afk end
    local env = setmetatable({
        FLUX_API = client,
        UnitIsConnected = function() return connected end,
        UnitIsDead = function() return dead end,
        UnitIsGhost = function() return false end,
        C_Texture = { GetAtlasInfo = function(name)
            if missingAtlases then return nil end
            if name:find("FullAlert", 1, true) then return nil end
            return { width = 124, height = 20 }
        end },
    }, { __index = _G })
    env._G = env
    Compile(Read("../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_UnitFrame/Mainline/PowerBarColorUtil.lua"), env)()
    local helpers = "local ns, UF, API = ...\n" .. source:sub(start, finish - 1)
        .. source:sub(healthStart, healthEnd - 1) .. "\nreturn UF"
    Compile(helpers, env)(ns, UF, ns.API)
    -- Prediction segments and the old-fill ghost must not put the rim back.
    local pco = {}; ns.PowerCostOverlay = pco
    local matchGhost = Compile("local PCO, UF, TEXTURE_BAR = ...\n" .. pcoSource:sub(segStart, segEnd - 1)
        .. pcoSource:sub(ghostStart, ghostEnd - 1) .. "\nreturn MatchGhostArt", env)(pco, UF, plain)
    return UF, env.PowerBarColor, matchGhost, function(c, d, a) connected, dead, afk = c, d, a end
end

local retailPath = "Interface\\AddOns\\_FluxUI\\Media\\UnitFrames\\Retail\\"
local expectedFiles = { Health = true, Mana = true, ManaStatus = true, Energy = true, Focus = true,
    Rage = true, RunicPower = true, ClassResourceMana = true, ClassResourceEnergy = true }
local function ExpectedArt(family, atlas)
    if family ~= "forever" then return atlas end
    local name = atlas:match("^UI%-HUD%-UnitFrame%-Player%-PortraitOn%-Bar%-(.+)$")
    if name == "Mana-Status" then name = "ManaStatus" end
    local className = atlas:match("^UI%-HUD%-UnitFrame%-Player%-PortraitOn%-ClassResource%-Bar%-(.+)$")
    if className then name = "ClassResource" .. className end
    return expectedFiles[name] and (retailPath .. name .. ".tga") or atlas
end

for _, fallback in ipairs({ false, true }) do
    for _, family in ipairs({ "forever", "live" }) do
        local UF, colors, matchGhost, state = Boot(family, fallback)
        assert(UF.UsesHudUnitBars())
        for _, unit in ipairs({ "player", "target", "focus" }) do
            local health = Bar(); health.AnimatedLossBar = Bar()
            UF.UpdateHealthColor({ Health = health, unit = unit }, unit)
            assert(health.asset == ExpectedArt(family, "UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health"))
            assert(health.AnimatedLossBar.asset == health.asset)
            ColorEquals(health.color, 1, 1, 1)
            for _, power in ipairs({ { "MANA", 0 }, { "RAGE", 1 }, { "FOCUS", 2 }, { "ENERGY", 3 }, { "RUNIC_POWER", 6 },
                { "LUNAR_POWER", 8 }, { "MAELSTROM", 11 }, { "INSANITY", 13 }, { "FURY", 17 } }) do
                local bar = Bar(); bar.CostOverlay = Texture()
                UF.ApplyResourceBarStyle(bar, unit, power[1], power[2], nil, nil, nil, false)
                local info = colors[power[1]]
                local expected = info.atlas or ("UI-HUD-UnitFrame-Player-PortraitOn-Bar-" .. info.atlasElementName)
                assert(bar.asset == ExpectedArt(family, expected) and bar._fluxHudAtlas, "wrong HUD fill")
                ColorEquals(bar.color, 1, 1, 1)
                local expectedStatus = ExpectedArt(family, UF.GetPowerStatusAtlas(info))
                assert((bar.CostOverlay.atlas or bar.CostOverlay.texture) == expectedStatus, "wrong prediction art")
                local ghost = Bar(); matchGhost(bar, ghost)
                assert(ghost.asset == bar.asset, "power ghost lost its atlas")
                state(false, false, false); UF.RefreshResourceConnection(bar, unit); ColorEquals(bar.color, 0.5, 0.5, 0.5)
                state(true, false, false); UF.RefreshResourceConnection(bar, unit); ColorEquals(bar.color, 1, 1, 1)
            end
        end
        local mana = Bar()
        for _, cr in ipairs({ false, true, false }) do
            UF.ApplyResourceBarStyle(mana, "player", "MANA", 0, nil, nil, nil, cr)
            assert(mana.asset == ExpectedArt(family, "UI-HUD-UnitFrame-Player-PortraitOn" .. (cr and "-ClassResource" or "") .. "-Bar-Mana"))
        end
        state(true, true, false); UF.RefreshResourceConnection(mana, "player")
        assert(mana.fill.desaturated and mana.fill.alpha == 0.5)
        state(true, false, false); UF.RefreshResourceConnection(mana, "player")
        assert(not mana.fill.desaturated and mana.fill.alpha == 1)
    end
end

-- Bundled fills remain available even when Forever omits the native atlas.
for _, fallback in ipairs({ false, true }) do
    local UF, _, matchGhost = Boot("forever", fallback, true)
    local bar = Bar(); bar.CostOverlay = Texture()
    UF.ApplyResourceBarStyle(bar, "player", "MANA", 0)
    assert(bar.asset == retailPath .. "Mana.tga")
    assert(bar.CostOverlay.texture == retailPath .. "ManaStatus.tga")
    assert(table.concat(bar.CostOverlay.coords, ",") == "0,1,0,1")
    local ghost = Bar(); matchGhost(bar, ghost); assert(ghost.asset == bar.asset)
    local health = Bar(); UF.UpdateHealthColor({ Health = health, unit = "player" }, "player")
    assert(health.asset == retailPath .. "Health.tga")
end
for _, family in ipairs({ "era", "anniversary", "mists" }) do
    local UF = Boot(family, false)
    assert(not UF.UsesHudUnitBars())
    assert(UF.GetHudBarTexture("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health") == "UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health")
end
for name in pairs(expectedFiles) do
    local file = assert(io.open(root .. "Media/UnitFrames/Retail/" .. name .. ".tga", "rb"))
    local data = file:read("*a"); file:close()
    local w = data:byte(13) + data:byte(14) * 256
    local h = data:byte(15) + data:byte(16) * 256
    assert(data:byte(3) == 2 and data:byte(17) == 32 and data:byte(18) == 0x28)
    assert(w == 256 and h == (name == "Health" and 64 or 32))
    assert(#data == 18 + w * h * 4, "incomplete standalone texture")
end
print("Retail HUD art smoke OK (Forever standalone fills, Live atlases, HP/loss, power, prediction/ghost, recovery, missing atlases, client guards, TGA assets)")
