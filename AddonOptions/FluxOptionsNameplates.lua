local addonName, ns = ...

-- /fluxui Nameplates: the only place Flux nameplate options live, on every client.
-- Nothing here is added to Blizzard's Nameplates or Combat settings pages.

local function ThreatAPI()
    return ns.Flux and ns.Flux.Threat
end

--- Level overlay runs on every client that loads NamePlates (NamePlates/Level.lua).
local function IsLevelOverlaySupported()
    local NP = ns.Flux and ns.Flux.NamePlates
    if NP and NP.IsLevelSupported then
        return NP.IsLevelSupported()
    end
    local client = ns.Flux and ns.Flux.Client
    return client and client.isAnyClassic and true or false
end

--- Live store read by NamePlates/Core.lua (FluxUI_DB SavedVariables).
local function EnsureNameplateThreatDB()
    if type(FluxUI_DB) ~= "table" then
        FluxUI_DB = {}
    end
    local db = FluxUI_DB.nameplateThreat
    if type(db) ~= "table" then
        db = {}
        FluxUI_DB.nameplateThreat = db
    end

    local defaults = FluxOptionsDefaults
        and FluxOptionsDefaults.global
        and FluxOptionsDefaults.global.nameplateThreat
    defaults = defaults or {
        npcThreatBorder = true,
        enemyPlayerTarget = true,
        visibilityMode = "group",
        levelOverlayEnabled = true,
    }

    if db.npcThreatBorder == nil then
        db.npcThreatBorder = defaults.npcThreatBorder ~= false
    end
    if db.enemyPlayerTarget == nil then
        db.enemyPlayerTarget = defaults.enemyPlayerTarget ~= false
    end
    if db.visibilityMode ~= "always" and db.visibilityMode ~= "never" and db.visibilityMode ~= "group" then
        db.visibilityMode = defaults.visibilityMode or "group"
    end
    if db.levelOverlayEnabled == nil then
        db.levelOverlayEnabled = defaults.levelOverlayEnabled ~= false
    end
    return db
end

local function RefreshNameplatesFromDB()
    if FluxNamePlates_RefreshFromDB then
        FluxNamePlates_RefreshFromDB()
    end
end

local function BlizzardThreatToggle(key, name, desc, order)
    return {
        type = "toggle",
        name = name,
        desc = desc,
        order = order,
        width = "full",
        get = function()
            local api = ThreatAPI()
            if api and api.NameplateDisplayEnabled then
                return api.NameplateDisplayEnabled(key)
            end
            return true
        end,
        set = function(_, v)
            local api = ThreatAPI()
            if api and api.SetNameplateDisplay then
                api.SetNameplateDisplay(key, v)
            end
        end,
    }
end

local function BuildNameplatesOptions()
    local args = {
        headerThreat = {
            type = "header",
            name = "Threat",
            order = 1,
        },
        threatDesc = {
            type = "description",
            name = "Flux draws a threat-colored border and your threat rank and percent (100% = you have aggro) on enemy NPC nameplates. Enemy players targeting you get a red border.\n",
            order = 2,
            fontSize = "small",
        },
        visibilityMode = {
            type = "select",
            name = "Threat visibility",
            desc = "When Flux nameplate threat visuals are shown. Group = party/raid only.",
            order = 3,
            width = "full",
            values = {
                group = "In group only",
                always = "Always",
                never = "Never",
            },
            get = function()
                return EnsureNameplateThreatDB().visibilityMode or "group"
            end,
            set = function(_, v)
                if v ~= "always" and v ~= "never" and v ~= "group" then
                    v = "group"
                end
                EnsureNameplateThreatDB().visibilityMode = v
                RefreshNameplatesFromDB()
            end,
        },
        npcThreatBorder = {
            type = "toggle",
            name = "NPC threat border + rank/%",
            desc = "Color the nameplate border from your threat on enemy NPCs and show threat rank and percent under the health bar.",
            order = 4,
            width = "full",
            get = function()
                return EnsureNameplateThreatDB().npcThreatBorder ~= false
            end,
            set = function(_, v)
                EnsureNameplateThreatDB().npcThreatBorder = v and true or false
                RefreshNameplatesFromDB()
            end,
        },
        showNumericThreat = {
            type = "toggle",
            name = "Show threat percentage",
            desc = "Shows tank-relative threat % (100% = you have aggro) on nameplates and on the Flux target/focus threat bar.",
            order = 4.5,
            width = "full",
            get = function()
                local api = ThreatAPI()
                if api and api.ShowNumeric then
                    return api.ShowNumeric()
                end
                return true
            end,
            set = function(_, v)
                local api = ThreatAPI()
                if api and api.SetShowNumeric then
                    api.SetShowNumeric(v)
                end
                RefreshNameplatesFromDB()
                if FluxUnitFrames_ApplyThreatBarOptionsFromDB then
                    FluxUnitFrames_ApplyThreatBarOptionsFromDB()
                end
            end,
        },
        enemyPlayerTarget = {
            type = "toggle",
            name = "Enemy player targeting you",
            desc = "Red nameplate border when an enemy player is targeting you.",
            order = 5,
            width = "full",
            get = function()
                return EnsureNameplateThreatDB().enemyPlayerTarget ~= false
            end,
            set = function(_, v)
                EnsureNameplateThreatDB().enemyPlayerTarget = v and true or false
                RefreshNameplatesFromDB()
            end,
        },
        headerBlizzardThreat = {
            type = "header",
            name = "Blizzard nameplate threat",
            order = 6,
        },
        blizzardThreatDesc = {
            type = "description",
            name = "The game's own Progressive / Flash / Health Bar Color threat display (nameplateThreatDisplay). Flux writes these bits with SetCVarBitfield only.\n",
            order = 6.1,
            fontSize = "small",
        },
        blizzardProgressive = BlizzardThreatToggle("Progressive", "Progressive",
            "Blizzard progressive aggro highlight on enemy nameplates.", 6.2),
        blizzardFlash = BlizzardThreatToggle("Flash", "Flash",
            "Blizzard aggro flash on enemy nameplates.", 6.3),
        blizzardHealthBarColor = BlizzardThreatToggle("HealthBarColor", "Health Bar Color",
            "Blizzard threat coloring on the nameplate health bar. The Flux border is separate.", 6.4),
        threatWarning = {
            type = "select",
            name = "Threat warning",
            desc = "Blizzard threatWarning CVar (tanking/losing aggro indicator). Off / party / raid / always.",
            order = 6.5,
            width = "full",
            values = {
                [0] = "Off",
                [1] = "In party",
                [2] = "In raid",
                [3] = "Always",
            },
            sorting = { 0, 1, 2, 3 },
            hidden = function()
                local api = ThreatAPI()
                return not (api and api.HasWarningCVar and api.HasWarningCVar())
            end,
            get = function()
                local api = ThreatAPI()
                if api and api.GetWarningMode then
                    return api.GetWarningMode()
                end
                return 3
            end,
            set = function(_, v)
                local api = ThreatAPI()
                if api and api.SetWarningMode then
                    api.SetWarningMode(v)
                end
            end,
        },
    }

    if IsLevelOverlaySupported() then
        args.headerLevel = {
            type = "header",
            name = "Level",
            order = 10,
        }
        args.levelDesc = {
            type = "description",
            name = "On Modern nameplate style, Flux shows a smaller \"Lvl. N\" under the right side of the health bar.\n",
            order = 11,
            fontSize = "small",
        }
        args.levelOverlayEnabled = {
            type = "toggle",
            name = "Show level overlay (Modern style)",
            desc = "Flux level text/skull under the health text on Modern-style nameplates. Ignored while the Classic health-bar style is active.",
            order = 12,
            width = "full",
            get = function()
                return EnsureNameplateThreatDB().levelOverlayEnabled ~= false
            end,
            set = function(_, v)
                EnsureNameplateThreatDB().levelOverlayEnabled = v and true or false
                RefreshNameplatesFromDB()
            end,
        }
    end

    local countdownHeader = {
        type = "header",
        name = "Buff / debuff countdown",
        order = 20,
    }
    args.headerAuras = countdownHeader
    args.aurasDesc = {
        type = "description",
        name = "Countdown digits use the same Flux 12px overlay as Classic on every client. Size: edit FLUX_NAMEPLATE_AURA_COUNTDOWN_SCALE in NamePlates/Countdown.lua (default 0.75), then /reload.\n",
        order = 21,
        fontSize = "small",
    }

    return {
        name = "Nameplates",
        type = "group",
        order = 24,
        args = args,
    }
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, _, loadedAddon)
    if loadedAddon ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    if FluxOptions and FluxOptions.RegisterModuleOptions then
        FluxOptions:RegisterModuleOptions("nameplates", BuildNameplatesOptions)
    end
end)

