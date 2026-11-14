local addonName, ns = ...

local max = math.max
local min = math.min
local floor = math.floor

local function GetRaidDB()
    return FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {}
end

local function AuraScaleMaximum()
    local limit = FluxRaidVisuals and FluxRaidVisuals.GetAuraScaleLimit
        and FluxRaidVisuals.GetAuraScaleLimit(nil, nil, GetRaidDB()) or 2.5
    limit = tonumber(limit) or 2.5
    return max(0.5, floor(min(2.5, limit) * 100 + 0.000001) / 100), limit
end

local function AuraScaleDescription(maximum, limit)
    local text = "1.00 uses Blizzard's default aura size. Resize only the auras from 0.50 to 2.50; frame size stays fixed."
    if FluxRaidVisuals and FluxRaidVisuals.GetAuraLayout then
        local layout = FluxRaidVisuals.GetAuraLayout(nil, nil, GetRaidDB())
        text = text .. string.format(" Current icons: %.1f x %.1f px.", layout.buffs.width, layout.buffs.height)
        if layout.overlap then text = text .. " Aura blocks extend beyond the available frame space." end
    end
    if limit < 0.5 then text = text .. " Icons are already capped to fit at the minimum setting." end
    return text
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

local function BuildAuraScaleOption()
    local option
    local function SyncLimit()
        local maximum, limit = AuraScaleMaximum()
        option.max = maximum
        return maximum, limit
    end
    option = {
        type = "range",
        name = "Aura icon scale",
        desc = function() return AuraScaleDescription(SyncLimit()) end,
        order = 23,
        min = 0.5, max = 2.5, step = 0.01,
        width = "full",
        get = function()
            local maximum = SyncLimit()
            return max(0.5, min(maximum, tonumber(GetRaidDB().auraIconScale) or 1))
        end,
        set = function(_, val)
            local maximum = SyncLimit()
            GetRaidDB().auraIconScale = max(0.5, min(maximum, tonumber(val) or 1))
            AfterRaidChange()
        end,
    }
    SyncLimit()
    return option
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
        partyStyle = {
            type = "group", name = "Party frames", inline = true, order = 0,
            args = {
                partyAsRaid = {
                    type = "toggle", name = "Show party as raid frames", order = 1, width = "full",
                    desc = "Use the compact raid layout for parties. Turn off for smaller Flux player-style frames. Raids always keep the raid layout. Both styles share the last member's bottom-right anchor.",
                    get = function() return RaidFlag("partyAsRaid", true) end,
                    set = function(_, value) SetRaidFlag("partyAsRaid", value) end,
                },
                scale = {
                    type = "range", name = "Party member scale", order = 2, min = 0.35, max = 1.5, step = 0.01,
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return tonumber(GetRaidDB().partyFrameScale) or 0.55 end,
                    set = function(_, value) GetRaidDB().partyFrameScale = value; AfterRaidChange() end,
                },
                portraits = {
                    type = "toggle", name = "Party portraits", order = 3,
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return RaidFlag("partyShowPortrait", true) end,
                    set = function(_, value) SetRaidFlag("partyShowPortrait", value) end,
                },
                casts = {
                    type = "toggle", name = "Show party cast bars", order = 4, width = "full",
                    desc = "Show player-style casts and spell icons over each party member's name and level. Disabling hides an active cast; enabling refreshes the current cast. Changes apply outside combat.",
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return RaidFlag("partyShowCastBar", true) end,
                    set = function(_, value) SetRaidFlag("partyShowCastBar", value) end,
                },
                pets = {
                    type = "toggle", name = "Party pets", order = 5,
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return RaidFlag("partyShowPets", true) end,
                    set = function(_, value) SetRaidFlag("partyShowPets", value) end,
                },
                petScale = {
                    type = "range", name = "Party pet scale", order = 6, min = 0.35, max = 1.5, step = 0.01,
                    disabled = function() return RaidFlag("partyAsRaid", true) or not RaidFlag("partyShowPets", true) end,
                    get = function() return tonumber(GetRaidDB().partyPetScale) or 1 end,
                    set = function(_, value) GetRaidDB().partyPetScale = value; AfterRaidChange() end,
                },
                preview = {
                    type = "execute", name = function()
                        return FluxRaidPreview and FluxRaidPreview.IsPartyShown and FluxRaidPreview.IsPartyShown()
                            and "Hide party preview" or "Show party preview"
                    end, order = 20,
                    func = function()
                        if FluxRaidPreview and FluxRaidPreview.ToggleParty then FluxRaidPreview.ToggleParty() end
                    end,
                },
                classColor = {
                    type = "toggle", name = "Class-colored party borders and backdrop", order = 7, width = "full",
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return RaidFlag("partyClassColor", false) end,
                    set = function(_, value) SetRaidFlag("partyClassColor", value) end,
                },
                targets = {
                    type = "toggle", name = "Party member targets", order = 8,
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return RaidFlag("partyShowTargets", true) end,
                    set = function(_, value) SetRaidFlag("partyShowTargets", value) end,
                },
                width = {
                    type = "range", name = "Party member width", order = 9, min = .35, max = 1.5, step = .01,
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return tonumber(GetRaidDB().partyWidthScale) or .8 end,
                    set = function(_, value) GetRaidDB().partyWidthScale = value; AfterRaidChange() end,
                },
                height = {
                    type = "range", name = "Party member height", order = 10, min = .35, max = 1.5, step = .01,
                    desc = "Four rows always fit within the current raid column. Member size stays constant as the roster changes.",
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return tonumber(GetRaidDB().partyHeightScale) or .85 end,
                    set = function(_, value) GetRaidDB().partyHeightScale = value; AfterRaidChange() end,
                },
                targetWidth = {
                    type = "range", name = "Party target width", order = 11, min = 12, max = 60, step = 1,
                    disabled = function() return RaidFlag("partyAsRaid", true) or not RaidFlag("partyShowTargets", true) end,
                    get = function() return tonumber(GetRaidDB().partyTargetWidth) or 30 end,
                    set = function(_, value) GetRaidDB().partyTargetWidth = value; AfterRaidChange() end,
                },
                auraScale = {
                    type = "range", name = "Party aura size", order = 12, min = .5, max = 2.5, step = .01,
                    desc = "Extra size for player-style party auras. The default 1.50 is fifty percent larger than the same raid aura settings.",
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return tonumber(GetRaidDB().partyAuraScale) or 1.5 end,
                    set = function(_, value) GetRaidDB().partyAuraScale = value; AfterRaidChange() end,
                },
                textScale = {
                    type = "range", name = "Party text size", order = 13, min = .5, max = 1.5, step = .01,
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return tonumber(GetRaidDB().partyTextScale) or 1 end,
                    set = function(_, value) GetRaidDB().partyTextScale = value; AfterRaidChange() end,
                },
                threat = {
                    type = "toggle", name = "Party threat highlight", order = 14,
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return RaidFlag("partyThreatHighlight", true) end,
                    set = function(_, value) SetRaidFlag("partyThreatHighlight", value) end,
                },
                reset = {
                    -- Keep appearance/visibility choices when resetting sizes.
                    type = "execute", name = "Reset party sizes", order = 19,
                    func = function()
                        local defaults = FluxOptionsDefaults.profile.raidFrames
                        for _, key in ipairs({"partyFrameScale", "partyWidthScale", "partyHeightScale", "partyPetScale", "partyTargetWidth", "partyAuraScale", "partyTextScale", "partyPowerHeightScale"}) do
                            GetRaidDB()[key] = defaults[key]
                        end
                        AfterRaidChange()
                    end,
                },
                powerHeight = {
                    type = "range", name = "Party resource height", order = 15, min = .5, max = 1.5, step = .01,
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return tonumber(GetRaidDB().partyPowerHeightScale) or .8 end,
                    set = function(_, value) GetRaidDB().partyPowerHeightScale = value; AfterRaidChange() end,
                },
                healthText = {
                    type = "select", name = "Party HP text", order = 16,
                    values = {values = "Values", percent = "Percent", both = "Values and percent", none = "Hidden"},
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return GetRaidDB().partyHealthText or "values" end,
                    set = function(_, value) GetRaidDB().partyHealthText = value; AfterRaidChange() end,
                },
                powerText = {
                    type = "select", name = "Party resource text", order = 17,
                    values = {values = "Values", percent = "Percent", both = "Values and percent", none = "Hidden"},
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return GetRaidDB().partyPowerText or "percent" end,
                    set = function(_, value) GetRaidDB().partyPowerText = value; AfterRaidChange() end,
                },
                targetClassColor = {
                    type = "toggle", name = "Class-colored party target HP", order = 18,
                    desc = "Use class color only when the party member's target is a player. NPC targets keep their usual color.",
                    disabled = function() return RaidFlag("partyAsRaid", true) end,
                    get = function() return RaidFlag("partyTargetClassColor", false) end,
                    set = function(_, value) SetRaidFlag("partyTargetClassColor", value) end,
                },
            },
        },
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
                    desc = "Raid previews show 10 to 40 members. Use Party Frames for the five-member party preview.",
                    order = 3,
                    width = "normal",
                    values = {
                        ["10"] = "10", ["15"] = "15", ["20"] = "20",
                        ["25"] = "25", ["30"] = "30", ["35"] = "35", ["40"] = "40",
                    },
                    sorting = { "10", "15", "20", "25", "30", "35", "40" },
                    get = function()
                        local n = tonumber(GetRaidDB().previewRosterSize) or 40
                        return tostring(max(10, min(40, floor(n / 5) * 5)))
                    end,
                    set = function(_, val)
                        GetRaidDB().previewRosterSize = max(10, min(40, floor((tonumber(val) or 40) / 5) * 5))
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
            desc = "1.00 uses Blizzard's default unit-frame width.",
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
            desc = "1.00 uses Blizzard's default unit-frame height.",
            order = 22,
            min = 0.8, max = 1.6, step = 0.05,
            width = "full",
            get = function()
                return GetRaidDB().frameHeightScale or 1
            end,
            set = function(_, val)
                GetRaidDB().frameHeightScale = val
                AfterRaidChange()
            end,
        },
        powerBarHeightScale = {
            type = "range",
            name = "Power bar height scale",
            desc = "1.00 uses Blizzard's default resource-strip height. Scales independently of member frame height.",
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
        auraIconScale = BuildAuraScaleOption(),
        auraWidthScale = {
            type = "range", name = "Aura width (X)", order = 23.1,
            desc = "Changes aura width independently of height. 1.00 is Blizzard's width. Updates live icons out of combat when native configuration is allowed; otherwise the change waits until safe.",
            min = 0.5, max = 2.5, step = 0.01, width = "full",
            get = function() return GetRaidDB().auraWidthScale or 1 end,
            set = function(_, value) GetRaidDB().auraWidthScale = max(0.5, min(2.5, tonumber(value) or 1)); AfterRaidChange() end,
        },
        auraDurationFontScale = {
            type = "range", name = "Aura duration text size", order = 23.2,
            desc = "Scales the fitted duration font independently of icon size. 1.00 keeps the default font size. Updates preview and live aura timers out of combat; combat changes apply when combat ends.",
            min = 0.5, max = 2.5, step = 0.01, width = "full",
            get = function() return GetRaidDB().auraDurationFontScale or 1 end,
            set = function(_, value) GetRaidDB().auraDurationFontScale = max(0.5, min(2.5, tonumber(value) or 1)); AfterRaidChange() end,
        },
        auraTimersUnderMinute = {
            type = "toggle", name = "Show aura timers only below 1 minute", order = 23.3, width = "full",
            desc = "Applies to raid and party shown as raid frames. Show numbers only below 60 seconds; icons, swipes and stacks remain. Normal party, target and focus use Unit Frames > General.",
            get = function() return RaidFlag("auraTimersUnderMinute", true) end,
            set = function(_, value) SetRaidFlag("auraTimersUnderMinute", value) end,
        },
        raidManagerScale = {
            type = "range",
            name = "Raid manager strip scale",
            desc = "Left raid tools / markers strip. 1.00 uses a compact baseline that is 30% smaller than Blizzard's manager.",
            order = 24,
            min = 0.5, max = 1.2, step = 0.05,
            width = "full",
            get = function()
                return GetRaidDB().raidManagerScale or 1
            end,
            set = function(_, val)
                GetRaidDB().raidManagerScale = val
                AfterRaidChange()
            end,
        },
        resetSizes = {
            type = "execute",
            name = "Reset sizes",
            desc = "Restores the default sizing preset and under-one-minute aura timer display. Aura filters, counts and transparency stay configured.",
            order = 24.5,
            func = function()
                local db = GetRaidDB()
                local defaults = FluxOptionsDefaults.profile.raidFrames
                for _, key in ipairs({ "memberWidthScale", "frameHeightScale", "powerBarHeightScale", "auraIconScale",
                    "auraWidthScale", "auraDurationFontScale", "raidManagerScale", "auraTimersUnderMinute" }) do
                    db[key] = defaults[key]
                end
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
            name = "Frame opacity applies to the visible cell content. In-range and out-of-range multipliers apply when Fade out of range is on. Aura transparency adjusts buffs, debuffs and their timers.\n",
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
            name = "Aura transparency",
            desc = "Transparency of buff/debuff icons, duration text and cooldown overlays. 0% is fully visible; 100% is invisible. The starting value is 70%.",
            order = 29,
            min = 0, max = 100, step = 1,
            width = "full",
            get = function()
                local db=GetRaidDB()
                local value=tonumber(db.auraTransparency)
                if value==nil then value=100*(1-max(0.1,min(1,tonumber(db.auraIconAlpha) or 1))*0.3) end
                return max(0,min(100,value))
            end,
            set = function(_, val)
                GetRaidDB().auraTransparency = max(0,min(100,tonumber(val) or 70))
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
        showClassBuffs = {
            type = "toggle",
            name = "Class buffs out of combat",
            desc = "Shows buffs currently present on party/raid members while out of combat, including long-duration class buffs.",
            order = 37.9,
            get = function() return RaidFlag("showClassBuffs", true) end,
            set = function(_, val) SetRaidFlag("showClassBuffs", val) end,
        },
        showMissingClassBuffs = {
            type = "toggle",
            name = "Missing class buffs",
            desc = "Out of combat, show up to three dim icons for learned class buffs missing from a member. Restricted or unavailable aura data shows no missing-buff claim.",
            order = 38,
            get = function() return RaidFlag("showMissingClassBuffs", false) end,
            set = function(_, val) SetRaidFlag("showMissingClassBuffs", val) end,
        },
        showPets = {
            type = "toggle",
            name = "Party / raid pets",
            desc = "Adds half-height pet cells beside the existing grid. Requires working secure visibility support. Existing member positions and sizes stay the same.",
            order = 38.1,
            get = function() return RaidFlag("showPets", false) end,
            set = function(_, val) SetRaidFlag("showPets", val) end,
        },
        showFriendlyTarget = {
            type = "toggle",
            name = "Friendly target",
            desc = "Adds a friendly-target cell beside the party/raid grid, above optional pets. Hostile or missing targets hide securely. Existing member positions stay the same.",
            order = 38.2,
            get = function() return RaidFlag("showFriendlyTarget", false) end,
            set = function(_, val) SetRaidFlag("showFriendlyTarget", val) end,
        },
        showEstimatedHoTs = {
            type = "toggle",
            name = "Estimate my remaining HoT healing (Forever)",
            desc = "Optional estimate from your own successful casts and readable learned English spell descriptions. It cannot detect every dispel, refresh or modifier and does not replace native heal prediction. Unavailable or restricted data shows no estimate.",
            order = 38.3,
            disabled = function()
                if FluxRaidHoTs and FluxRaidHoTs.IsSupported then return not FluxRaidHoTs.IsSupported() end
                local client = ns.Flux and ns.Flux.Client
                return not (client and (client.isForever or client.isCamelot))
            end,
            get = function() return RaidFlag("showEstimatedHoTs", false) end,
            set = function(_, val) SetRaidFlag("showEstimatedHoTs", val) end,
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
        maxBuffs = {
            type = "range",
            name = "Maximum buffs",
            desc = "Maximum buff icons per party or raid member.",
            order = 44.55,
            min = 1, max = 6, step = 1,
            get = function() return max(1, min(6, floor(tonumber(GetRaidDB().maxBuffs) or 6))) end,
            set = function(_, val)
                GetRaidDB().maxBuffs = max(1, min(6, floor(tonumber(val) or 6)))
                AfterRaidChange()
            end,
        },
        maxDebuffs = {
            type = "range",
            name = "Maximum debuffs",
            desc = "Maximum debuff icons per party or raid member.",
            order = 44.65,
            min = 1, max = 6, step = 1,
            get = function() return max(1, min(6, floor(tonumber(GetRaidDB().maxDebuffs) or 6))) end,
            set = function(_, val)
                GetRaidDB().maxDebuffs = max(1, min(6, floor(tonumber(val) or 6)))
                AfterRaidChange()
            end,
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
