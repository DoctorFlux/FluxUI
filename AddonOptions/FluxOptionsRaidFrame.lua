local addonName, ns = ...

local max = math.max
local min = math.min
local floor = math.floor

local function GetRaidDB()
    return FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {}
end

local AfterRaidChange

local function RaidFlag(key, defaultOn)
    local db = GetRaidDB()
    if db[key] == nil then
        return defaultOn and true or false
    end
    return db[key] and true or false
end

local function SetRaidFlag(key, value)
    GetRaidDB()[key] = value and true or false
    AfterRaidChange()
end

AfterRaidChange = function()
    if FluxOptions and FluxOptions.RefreshRaidFrameScopedModules then
        FluxOptions:RefreshRaidFrameScopedModules()
    elseif FluxRaid_ApplyOptionsFromDB then
        FluxRaid_ApplyOptionsFromDB()
    end
end

local function AfterPreviewChange()
    if FluxRaidPreview and FluxRaidPreview.RefreshFromOptions then
        FluxRaidPreview.RefreshFromOptions()
    end
end

local healthTextValues = {
    none = "Hidden",
    health = "Values",
    perc = "Percent",
    healthandpercent = "Health and percent",
}

function ns.FluxOptionsBuildPartyRaidTab()
    return {
    name = "Party / Raid",
    type = "group",
    order = 5,
    args = {
        masterHeader = {
            type = "header",
            name = "Names",
            order = 1,
        },
        nameUseClassColor = {
            type = "toggle",
            name = "Class-colored names",
            desc = "Color player names by class on Flux compact frames. Off keeps names white. Health bar class colors use Class colors below.",
            order = 2,
            get = function()
                return GetRaidDB().nameUseClassColor == true
            end,
            set = function(_, val)
                GetRaidDB().nameUseClassColor = val and true or false
                AfterRaidChange()
            end,
        },
        -- =================================================================
        -- WORLD PREVIEW (inline group - keeps everything visually boxed)
        -- =================================================================
        previewGroup = {
            type = "group",
            name = "World Preview",
            order = 10,
            inline = true,
            args = {
                desc = {
                    type = "description",
                    name = "Shows a full-size preview of Flux raid frames in the game world. In a party or raid the first slots mirror real group members; the rest use a demo roster. Always hidden after login / reload.\n",
                    order = 1,
                    fontSize = "small",
                },
                toggle = {
                    type = "execute",
                    name = "Show / Hide Preview",
                    order = 2,
                    width = "normal",
                    func = function()
                        if FluxRaidPreview and FluxRaidPreview.Toggle then
                            FluxRaidPreview.Toggle()
                        end
                    end,
                },
                rosterSize = {
                    type = "select",
                    name = "Roster size",
                    order = 3,
                    width = "normal",
                    values = {
                        ["5"] = "5",  ["10"] = "10", ["15"] = "15", ["20"] = "20",
                        ["25"] = "25", ["30"] = "30", ["35"] = "35", ["40"] = "40",
                    },
                    sorting = { "5", "10", "15", "20", "25", "30", "35", "40" },
                    get = function()
                        local n = tonumber(GetRaidDB().previewRosterSize) or 40
                        return tostring(max(5, min(40, floor(n / 5) * 5)))
                    end,
                    set = function(_, val)
                        GetRaidDB().previewRosterSize = tonumber(val) or 40
                        AfterPreviewChange()
                    end,
                },
                showMT = {
                    type = "toggle",
                    name = "Show MT column",
                    order = 4,
                    width = "normal",
                    get = function()
                        return GetRaidDB().previewShowMTColumn ~= false
                    end,
                    set = function(_, val)
                        GetRaidDB().previewShowMTColumn = val and true or false
                        AfterPreviewChange()
                    end,
                },
                mtCount = {
                    type = "range",
                    name = "MT slots",
                    desc = "How many MT/MA-style frames appear in the MT column.",
                    order = 5,
                    min = 1, max = 8, step = 1,
                    width = "normal",
                    get = function()
                        local n = tonumber(GetRaidDB().previewMainTankCount)
                        if not n or n < 1 then n = 2 end
                        return max(1, min(8, floor(n)))
                    end,
                    set = function(_, val)
                        GetRaidDB().previewMainTankCount = max(1, min(8, floor(val)))
                        AfterPreviewChange()
                    end,
                },
                auraSpacer = {
                    type = "header",
                    name = "Demo Auras",
                    order = 10,
                },
                showBuffs = {
                    type = "toggle",
                    name = "Buffs",
                    order = 11,
                    width = "half",
                    get = function()
                        return GetRaidDB().previewDemoBuffsEnabled ~= false
                    end,
                    set = function(_, val)
                        GetRaidDB().previewDemoBuffsEnabled = val and true or false
                        AfterPreviewChange()
                    end,
                },
                buffCount = {
                    type = "range",
                    name = "Buff count",
                    order = 12,
                    min = 0, max = 6, step = 1,
                    width = "normal",
                    get = function()
                        return tonumber(GetRaidDB().previewBuffCount) or 3
                    end,
                    set = function(_, val)
                        GetRaidDB().previewBuffCount = val
                        AfterPreviewChange()
                    end,
                },
                showDebuffs = {
                    type = "toggle",
                    name = "Debuffs",
                    order = 13,
                    width = "half",
                    get = function()
                        return GetRaidDB().previewDemoDebuffsEnabled ~= false
                    end,
                    set = function(_, val)
                        GetRaidDB().previewDemoDebuffsEnabled = val and true or false
                        AfterPreviewChange()
                    end,
                },
                debuffCount = {
                    type = "range",
                    name = "Debuff count",
                    order = 14,
                    min = 0, max = 6, step = 1,
                    width = "normal",
                    get = function()
                        return tonumber(GetRaidDB().previewDebuffCount) or 5
                    end,
                    set = function(_, val)
                        GetRaidDB().previewDebuffCount = val
                        AfterPreviewChange()
                    end,
                },
            },
        },

        -- =================================================================
        -- FRAME SIZING
        -- =================================================================
        sizingHeader = {
            type = "header",
            name = "Frame sizing (Flux)",
            order = 20,
        },
        memberWidthScale = {
            type = "range",
            name = "Member frame width scale",
            desc = "1 = default width (~72px).",
            order = 21,
            min = 0.6, max = 1.4, step = 0.05,
            width = "full",
            get = function()
                return GetRaidDB().memberWidthScale or 1
            end,
            set = function(_, val)
                GetRaidDB().memberWidthScale = val
                AfterRaidChange()
            end,
        },
        frameHeightScale = {
            type = "range",
            name = "Member frame height scale",
            desc = "1.2 matches the built-in default row height.",
            order = 22,
            min = 0.8, max = 1.6, step = 0.05,
            width = "full",
            get = function()
                return GetRaidDB().frameHeightScale or 1.2
            end,
            set = function(_, val)
                GetRaidDB().frameHeightScale = val
                AfterRaidChange()
            end,
        },
        powerBarHeightScale = {
            type = "range",
            name = "Power bar height scale",
            desc = "Scales only the resource strip at the bottom (independent of member frame height). 1 = default strip size.",
            order = 22.5,
            min = 0.5, max = 2.5, step = 0.05,
            width = "full",
            get = function()
                return GetRaidDB().powerBarHeightScale or 1
            end,
            set = function(_, val)
                GetRaidDB().powerBarHeightScale = val
                AfterRaidChange()
            end,
        },
        auraIconScale = {
            type = "range",
            name = "Aura icon scale",
            order = 23,
            min = 1, max = 2.5, step = 0.05,
            width = "full",
            get = function()
                return GetRaidDB().auraIconScale or 1.4
            end,
            set = function(_, val)
                GetRaidDB().auraIconScale = val
                AfterRaidChange()
            end,
        },
        raidManagerScale = {
            type = "range",
            name = "Raid manager strip scale",
            desc = "Left raid tools / markers strip (when present).",
            order = 24,
            min = 0.5, max = 1.2, step = 0.05,
            width = "full",
            get = function()
                return GetRaidDB().raidManagerScale or 0.9
            end,
            set = function(_, val)
                GetRaidDB().raidManagerScale = val
                AfterRaidChange()
            end,
        },

        -- =================================================================
        -- TRANSPARENCY
        -- =================================================================
        transparencyHeader = {
            type = "header",
            name = "Transparency (Flux)",
            order = 25,
        },
        transparencyDesc = {
            type = "description",
            name = "Frame opacity applies to each unit button. In-range and out-of-range multipliers apply when Fade out of range is on. Aura opacity multiplies buff and debuff icons on top of the frame alpha.\n",
            order = 25.5,
            fontSize = "small",
        },
        frameBaseAlpha = {
            type = "range",
            name = "Frame base opacity",
            order = 26,
            min = 0.2, max = 1, step = 0.05,
            width = "full",
            get = function()
                return tonumber(GetRaidDB().frameBaseAlpha) or 1
            end,
            set = function(_, val)
                GetRaidDB().frameBaseAlpha = val
                AfterRaidChange()
            end,
        },
        rangeAlphaInRange = {
            type = "range",
            name = "Opacity when in range",
            desc = "Used when Fade out of range is on. Multiplied by frame base opacity.",
            order = 27,
            min = 0.2, max = 1, step = 0.05,
            width = "full",
            get = function()
                return tonumber(GetRaidDB().rangeAlphaInRange) or 0.9
            end,
            set = function(_, val)
                GetRaidDB().rangeAlphaInRange = val
                AfterRaidChange()
            end,
        },
        rangeAlphaOutOfRange = {
            type = "range",
            name = "Opacity when out of range / offline",
            desc = "Used when Fade out of range is on. Multiplied by frame base opacity.",
            order = 28,
            min = 0.1, max = 1, step = 0.05,
            width = "full",
            get = function()
                return tonumber(GetRaidDB().rangeAlphaOutOfRange) or 0.44
            end,
            set = function(_, val)
                GetRaidDB().rangeAlphaOutOfRange = val
                AfterRaidChange()
            end,
        },
        auraIconAlpha = {
            type = "range",
            name = "Buff / debuff icon opacity",
            desc = "Multiplies aura button alpha (stacks with frame opacity).",
            order = 29,
            min = 0.2, max = 1, step = 0.05,
            width = "full",
            get = function()
                return tonumber(GetRaidDB().auraIconAlpha) or 1
            end,
            set = function(_, val)
                GetRaidDB().auraIconAlpha = val
                AfterRaidChange()
            end,
        },

        -- =================================================================
        -- DISPEL HIGHLIGHT
        -- =================================================================
        dispelHeader = {
            type = "header",
            name = "Dispel Highlight",
            order = 35,
        },
        showDispelHighlight = {
            type = "toggle",
            name = "Dispel highlight border",
            desc = "Shows a type-colored border when a party/raid member has a debuff your class can dispel (e.g. Curse only if you have Remove Curse). Matches Blizzard Dispellable By Me.",
            order = 36,
            width = "full",
            get = function()
                return GetRaidDB().showDispelHighlight ~= false
            end,
            set = function(_, val)
                GetRaidDB().showDispelHighlight = val and true or false
                AfterRaidChange()
            end,
        },

        highlightHeader = {
            type = "header",
            name = "Highlights",
            order = 37,
        },
        showAggroHighlight = {
            type = "toggle",
            name = "Aggro highlight",
            desc = "Shows the aggro ring when a member has threat.",
            order = 37.1,
            get = function() return RaidFlag("showAggroHighlight", true) end,
            set = function(_, val) SetRaidFlag("showAggroHighlight", val) end,
        },
        showTargetHighlight = {
            type = "toggle",
            name = "Target highlight",
            order = 37.2,
            get = function() return RaidFlag("showTargetHighlight", true) end,
            set = function(_, val) SetRaidFlag("showTargetHighlight", val) end,
        },
        showMouseoverHighlight = {
            type = "toggle",
            name = "Mouseover highlight",
            order = 37.3,
            get = function() return RaidFlag("showMouseoverHighlight", true) end,
            set = function(_, val) SetRaidFlag("showMouseoverHighlight", val) end,
        },
        showRoleIcon = {
            type = "toggle",
            name = "Role icons",
            order = 37.4,
            get = function() return RaidFlag("showRoleIcon", true) end,
            set = function(_, val) SetRaidFlag("showRoleIcon", val) end,
        },
        showGroupLabels = {
            type = "toggle",
            name = "Group labels",
            desc = "Party and group numbers above each column.",
            order = 37.5,
            get = function() return RaidFlag("showGroupLabels", true) end,
            set = function(_, val) SetRaidFlag("showGroupLabels", val) end,
        },
        showRangeFade = {
            type = "toggle",
            name = "Fade out of range",
            desc = "Uses the in-range and out-of-range opacity sliders.",
            order = 37.6,
            get = function() return RaidFlag("showRangeFade", true) end,
            set = function(_, val) SetRaidFlag("showRangeFade", val) end,
        },

        displayHeader = {
            type = "header",
            name = "Bars and auras",
            order = 40,
        },
        useClassColors = {
            type = "toggle",
            name = "Class colors",
            desc = "Class-colored health bars. Names stay on the setting above.",
            order = 42,
            get = function() return RaidFlag("useClassColors", true) end,
            set = function(_, val) SetRaidFlag("useClassColors", val) end,
        },
        displayPowerBar = {
            type = "toggle",
            name = "Power bars",
            order = 43,
            get = function() return RaidFlag("displayPowerBar", true) end,
            set = function(_, val) SetRaidFlag("displayPowerBar", val) end,
        },
        showHealPrediction = {
            type = "toggle",
            name = "Heal prediction",
            order = 43.5,
            get = function() return RaidFlag("showHealPrediction", true) end,
            set = function(_, val) SetRaidFlag("showHealPrediction", val) end,
        },
        healthText = {
            type = "select",
            name = "Health text",
            order = 44,
            values = healthTextValues,
            sorting = { "perc", "health", "healthandpercent", "none" },
            get = function()
                local v = GetRaidDB().healthText
                if v ~= "none" and v ~= "health" and v ~= "perc" and v ~= "healthandpercent" then
                    return "perc"
                end
                return v
            end,
            set = function(_, val)
                if val ~= "none" and val ~= "health" and val ~= "perc" and val ~= "healthandpercent" then
                    val = "perc"
                end
                GetRaidDB().healthText = val
                AfterRaidChange()
            end,
        },
        displayBuffs = {
            type = "toggle",
            name = "Show buffs",
            order = 44.5,
            get = function() return RaidFlag("displayBuffs", true) end,
            set = function(_, val) SetRaidFlag("displayBuffs", val) end,
        },
        displayDebuffs = {
            type = "toggle",
            name = "Show debuffs",
            order = 44.6,
            get = function() return RaidFlag("displayDebuffs", true) end,
            set = function(_, val) SetRaidFlag("displayDebuffs", val) end,
        },
        auraFocusMode = {
            type = "select",
            name = "Aura focus",
            desc = "Debuff focused: more debuff slots. Buff focused: more buff slots along the top.",
            order = 44.7,
            values = {
                debuff = "Debuff focused",
                buff = "Buff focused",
            },
            get = function()
                local v = GetRaidDB().auraFocusMode
                if v == "buff" then return "buff" end
                return "debuff"
            end,
            set = function(_, val)
                GetRaidDB().auraFocusMode = (val == "buff") and "buff" or "debuff"
                AfterRaidChange()
            end,
        },
        displayOnlyDispellableDebuffs = {
            type = "toggle",
            name = "Only dispellable debuffs",
            desc = "Limits debuff icons to auras your class can dispel.",
            order = 45,
            get = function() return RaidFlag("displayOnlyDispellableDebuffs", false) end,
            set = function(_, val) SetRaidFlag("displayOnlyDispellableDebuffs", val) end,
        },
    },
}
end
