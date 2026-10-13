local addonName, ns = ...

local function NotifyFluxUIConfig()
    local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if ACR then
        ACR:NotifyChange("FluxUI")
    end
end

local BuildMicroMenuOptions -- forward decl for RefreshTradeSkills

local function RefreshTradeSkills()
    if FluxTradeSkillMicro and FluxTradeSkillMicro.Refresh then
        FluxTradeSkillMicro:Refresh()
    else
        FluxOptions:RefreshMicroMenuScopedModules()
    end
    -- Rebuild so per-profession selects match currently learned skills.
    if FluxOptions and FluxOptions.RegisterModuleOptions and BuildMicroMenuOptions then
        FluxOptions:RegisterModuleOptions("micromenu", BuildMicroMenuOptions)
    end
    NotifyFluxUIConfig()
end

local function GetTradeSkillDB()
    if FluxTradeSkillMicro and FluxTradeSkillMicro.GetDB then
        return FluxTradeSkillMicro:GetDB()
    end
    return nil
end

local function BuildPerSkillArgs()
    local args = {}
    local skills = (FluxTradeSkillMicro and FluxTradeSkillMicro.GetLearnedSkills)
        and FluxTradeSkillMicro:GetLearnedSkills() or {}
    local order = 1
    for _, skill in ipairs(skills) do
        local key = skill.key
        local argKey = "tsk_" .. tostring(key):gsub("[^%w]", "_")
        args[argKey] = {
            type = "select",
            name = skill.name or key,
            order = order,
            width = "full",
            values = {
                individual = "Individual button",
                flyout = "In flyout",
                off = "Off",
            },
            sorting = { "individual", "flyout", "off" },
            get = function()
                local db = GetTradeSkillDB()
                if not db or not db.perSkill then
                    return (skill.kind == "primary") and "individual" or "flyout"
                end
                local v = db.perSkill[key]
                if v == "individual" or v == "flyout" or v == "off" then
                    return v
                end
                return (skill.kind == "primary") and "individual" or "flyout"
            end,
            set = function(_, val)
                local db = GetTradeSkillDB()
                if not db then return end
                db.perSkill = db.perSkill or {}
                db.perSkill[key] = val
                RefreshTradeSkills()
            end,
        }
        order = order + 1
    end
    if order == 1 then
        args.tsk_none = {
            type = "description",
            name = "No learned professions detected yet.",
            order = 1,
            fontSize = "medium",
            width = "full",
        }
    end
    return args
end

BuildMicroMenuOptions = function()
    return {
    name = "MicroMenu",
    type = "group",
    order = 50,
    args = {
        intro = {
            type = "description",
            name = "Drag buttons in the preview to set order. Use the strip under each icon to cycle Off -> Account -> Character -> Off per row - that visibility is stored separately and is not affected by the bar scope below.\n",
            order = 0,
            fontSize = "medium",
            width = "full",
        },
        microMenuScopeHeader = {
            type = "header",
            name = "Micro menu bar scope",
            order = 2,
        },
        microMenuSettingsScope = {
            type = "select",
            name = "Micro menu bar scope",
            desc = "Account-wide: button size, spacing offset, and drag order (unified list) use the active profile. Character-specific: those three use this character only (account values are copied when you first switch). Does not change Layout tab placement (horizontal vs beside chat). Does not change per-row Off/Account/Character. Independent of General -> Settings scope and independent of the Layout tab's layout scope. Trade skill settings are always character-only.",
            order = 3,
            width = "full",
            values = {
                account = "Account-wide",
                character = "Character-specific",
            },
            sorting = { "account", "character" },
            get = function()
                return FluxOptions:IsMicroMenuSettingsCharacterSpecific() and "character" or "account"
            end,
            set = function(_, val)
                FluxOptions:SetMicroMenuSettingsCharacterSpecific(val == "character")
                NotifyFluxUIConfig()
            end,
        },
        microMenuScopeDesc = {
            type = "description",
            name = "Layout tab -> Layout settings scope only affects where the bar sits (and columns for position 2), not this list or size.\n",
            order = 4,
            fontSize = "small",
            width = "full",
        },
        editor = {
            type = "description",
            name = " ",
            dialogControl = "FluxMicroMenuConfigEmbed",
            width = "full",
            order = 10,
        },
        tradeSkillsHeader = {
            type = "header",
            name = "Trade skills",
            order = 30,
        },
        tradeSkillsDesc = {
            type = "description",
            name = "Learned professions as micromenu buttons (open that trade skill). Default order is just before the Addons (+) button. Visibility and layout for trade skills are always character-only (Off/Character in the preview). Drag reorder still applies.\n",
            order = 31,
            fontSize = "medium",
            width = "full",
        },
        tradeSkillsEnabled = {
            type = "toggle",
            name = "Enable trade skill micro buttons",
            order = 32,
            width = "full",
            get = function()
                local db = GetTradeSkillDB()
                return not db or db.enabled ~= false
            end,
            set = function(_, val)
                local db = GetTradeSkillDB()
                if db then
                    db.enabled = val and true or false
                end
                RefreshTradeSkills()
            end,
        },
        tradeSkillsLayoutMode = {
            type = "select",
            name = "Layout mode",
            desc = "Per-profession: choose Individual / In flyout / Off for each learned skill. Fixed split: primary professions as individual buttons; Cooking, Fishing, First Aid, Archaeology, etc. in one flyout. Global: one policy for every skill.",
            order = 33,
            width = "full",
            values = {
                perProfession = "Per-profession",
                fixedSplit = "Fixed split (primary buttons + secondary flyout)",
                global = "Global",
            },
            sorting = { "perProfession", "fixedSplit", "global" },
            get = function()
                local db = GetTradeSkillDB()
                return (db and db.layoutMode) or "fixedSplit"
            end,
            set = function(_, val)
                local db = GetTradeSkillDB()
                if db then
                    db.layoutMode = val
                end
                RefreshTradeSkills()
            end,
        },
        tradeSkillsGlobalStyle = {
            type = "select",
            name = "Global style",
            desc = "Used when Layout mode is Global. All individual: one button per skill. One flyout: all skills in a single flyout button. Both: every skill as its own button and also listed in the flyout.",
            order = 34,
            width = "full",
            values = {
                allIndividual = "All individual",
                oneFlyout = "One flyout",
                both = "Both (buttons + flyout)",
            },
            sorting = { "allIndividual", "oneFlyout", "both" },
            hidden = function()
                local db = GetTradeSkillDB()
                return not db or db.layoutMode ~= "global" or db.enabled == false
            end,
            get = function()
                local db = GetTradeSkillDB()
                return (db and db.globalStyle) or "allIndividual"
            end,
            set = function(_, val)
                local db = GetTradeSkillDB()
                if db then
                    db.globalStyle = val
                end
                RefreshTradeSkills()
            end,
        },
        tradeSkillsFixedSplitDesc = {
            type = "description",
            name = "Fixed split: primary professions appear as individual micro buttons; secondary skills open from the Trade Skills flyout.\n",
            order = 35,
            fontSize = "small",
            width = "full",
            hidden = function()
                local db = GetTradeSkillDB()
                return not db or db.layoutMode ~= "fixedSplit" or db.enabled == false
            end,
        },
        tradeSkillsPerSkillHeader = {
            type = "header",
            name = "Per-profession placement",
            order = 36,
            hidden = function()
                local db = GetTradeSkillDB()
                return not db or db.layoutMode ~= "perProfession" or db.enabled == false
            end,
        },
        tradeSkillsPerSkill = {
            type = "group",
            name = " ",
            order = 37,
            inline = true,
            hidden = function()
                local db = GetTradeSkillDB()
                return not db or db.layoutMode ~= "perProfession" or db.enabled == false
            end,
            args = BuildPerSkillArgs(),
        },
        buttonSizeScale = {
            type = "range",
            name = "Button size",
            desc = "Uniform scale for every micro menu button. Gold / experience / reputation bars under the menu use the same width as the micro bar, so they stretch or shrink with size and spacing.",
            order = 50,
            min = 0.5,
            max = 1.5,
            step = 0.05,
            width = "full",
            get = function()
                local m = FluxOptions:GetMicroMenuDB()
                return (m and m.buttonSizeScale) or 0.9
            end,
            set = function(_, val)
                local m = FluxOptions:GetMicroMenuDB()
                if m then
                    m.buttonSizeScale = val
                end
                FluxOptions:RefreshMicroMenuScopedModules()
            end,
        },
        buttonSpacingOffset = {
            type = "range",
            name = "Spacing offset",
            desc = "Added on top of the game's default micro button spacing. Lower (more negative) packs icons tighter; higher adds more space between them.",
            order = 51,
            min = -12,
            max = 16,
            step = 1,
            width = "full",
            get = function()
                local m = FluxOptions:GetMicroMenuDB()
                return (m and m.buttonSpacingOffset) or -2
            end,
            set = function(_, val)
                local m = FluxOptions:GetMicroMenuDB()
                if m then
                    m.buttonSpacingOffset = val
                end
                FluxOptions:RefreshMicroMenuScopedModules()
            end,
        },
        resetMicroMenuLayout = {
            type = "execute",
            name = "Reset layout to defaults",
            desc = "Sets button size to 90% and spacing offset to -2 for the current micro menu bar scope. Does not reset drag order or per-row Off/Account/Character.",
            order = 52,
            width = "full",
            confirm = true,
            confirmText = "Reset micro menu layout (size and spacing) to defaults for this scope?",
            func = function()
                FluxOptions:ResetMicroMenuLayoutToDefaults()
            end,
        },
    },
}
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    if FluxOptions and FluxOptions.RegisterModuleOptions then
        FluxOptions:RegisterModuleOptions("micromenu", BuildMicroMenuOptions)
    end
end)

