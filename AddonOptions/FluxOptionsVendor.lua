local addonName, ns = ...

local function NotifyVendorSettingsChanged()
    local FV = _G.FluxVendorAuto
    if FV and FV.NotifyVendorSettingsChanged then
        pcall(FV.NotifyVendorSettingsChanged)
    elseif FV and FV.RefreshMerchantOptionsCheckboxes then
        pcall(FV.RefreshMerchantOptionsCheckboxes)
    end
end

_G.FluxOptionsToggleGridSections = {
    automation = {
        {
            key = "autoRepair",
            name = "Auto repair",
            desc = "Repair gear at repair-capable merchants.",
            get = function()
                local FV = _G.FluxVendorAuto
                if not FV or not FV.EnsureSettings then
                    return false
                end
                local s = FV.EnsureSettings()
                return s and s.autoRepair and true or false
            end,
            set = function(val)
                local FV = _G.FluxVendorAuto
                if not FV or not FV.EnsureSettings then
                    return
                end
                local s = FV.EnsureSettings()
                s.autoRepair = val and true or false
                NotifyVendorSettingsChanged()
            end,
        },
        {
            key = "buyEmAllEnabled",
            name = "Bulk buy at vendor",
            desc = "Shift+click merchant items to open the bulk purchase window.",
            get = function()
                local BEA = _G.FluxBuyEmAll
                if BEA and BEA.IsEnabled then
                    return BEA:IsEnabled()
                end
                _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
                return _FluxUI_CharSavedVars.buyEmAllEnabled ~= false
            end,
            set = function(val)
                _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
                _FluxUI_CharSavedVars.buyEmAllEnabled = val and true or false
            end,
        },
        {
            key = "buyEmAllConfirmLarge",
            name = "Confirm large bulk purchases",
            desc = "Show a confirmation dialog before very large vendor purchases. Same as /buyemall confirm.",
            disabled = function()
                local BEA = _G.FluxBuyEmAll
                if BEA and BEA.IsEnabled then
                    return not BEA:IsEnabled()
                end
                _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
                return _FluxUI_CharSavedVars.buyEmAllEnabled == false
            end,
            get = function()
                local BEA = _G.FluxBuyEmAll
                if BEA and BEA.IsConfirmLargeEnabled then
                    return BEA:IsConfirmLargeEnabled()
                end
                _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
                return _FluxUI_CharSavedVars.buyEmAllConfirmLarge ~= false
            end,
            set = function(val)
                local BEA = _G.FluxBuyEmAll
                if BEA and BEA.SetConfirmLargeEnabled then
                    BEA:SetConfirmLargeEnabled(val)
                    return
                end
                _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
                _FluxUI_CharSavedVars.buyEmAllConfirmLarge = val and true or false
            end,
        },
        {
            key = "guildBankRepairFirst",
            name = "Guild bank first",
            desc = "Prefer guild bank over personal gold when auto repair runs.",
            hidden = function()
                local FV = _G.FluxVendorAuto
                if not FV or not FV.ShouldShowGuildRepairPriorityOption then
                    return true
                end
                return not FV.ShouldShowGuildRepairPriorityOption()
            end,
            disabled = function()
                local FV = _G.FluxVendorAuto
                if not FV or not FV.EnsureSettings then
                    return true
                end
                local s = FV.EnsureSettings()
                return not (s and s.autoRepair)
            end,
            get = function()
                local FV = _G.FluxVendorAuto
                if not FV or not FV.EnsureSettings then
                    return false
                end
                local s = FV.EnsureSettings()
                return s and (s.repairPriority or "personal") == "guild"
            end,
            set = function(val)
                local FV = _G.FluxVendorAuto
                if not FV or not FV.EnsureSettings then
                    return
                end
                local s = FV.EnsureSettings()
                s.repairPriority = val and "guild" or "personal"
                NotifyVendorSettingsChanged()
            end,
        },
        {
            key = "autoSellGray",
            name = "Auto sell junk",
            desc = "Sell junk when a vendor opens.",
            get = function()
                local FV = _G.FluxVendorAuto
                if not FV or not FV.EnsureSettings then
                    return false
                end
                local s = FV.EnsureSettings()
                return s and s.autoSellGray and true or false
            end,
            set = function(val)
                local FV = _G.FluxVendorAuto
                if not FV or not FV.EnsureSettings then
                    return
                end
                local s = FV.EnsureSettings()
                s.autoSellGray = val and true or false
                NotifyVendorSettingsChanged()
            end,
        },
        {
            key = "autoRestock",
            name = "Auto restock",
            desc = "Buy listed items up to their targets at vendors.",
            get = function()
                local FV = _G.FluxVendorAuto
                if not FV or not FV.EnsureSettings then
                    return false
                end
                local s = FV.EnsureSettings()
                return s and s.autoRestock and true or false
            end,
            set = function(val)
                local FV = _G.FluxVendorAuto
                if not FV or not FV.EnsureSettings then
                    return
                end
                local s = FV.EnsureSettings()
                s.autoRestock = val and true or false
                NotifyVendorSettingsChanged()
            end,
        },
        {
            key = "autoBankRestock",
            name = "Auto bank restock",
            desc = "Refill bags from the bank toward restock targets when the bank opens.",
            get = function()
                local BR = _G.FluxBankRestock
                if BR and BR.IsAutoEnabled then
                    return BR.IsAutoEnabled() and true or false
                end
                local FV = _G.FluxVendorAuto
                local s = FV and FV.EnsureSettings and FV.EnsureSettings()
                return s and s.autoBankRestock and true or false
            end,
            set = function(val)
                local BR = _G.FluxBankRestock
                if BR and BR.SetAutoEnabled then
                    BR.SetAutoEnabled(val and true or false)
                else
                    local FV = _G.FluxVendorAuto
                    local s = FV and FV.EnsureSettings and FV.EnsureSettings()
                    if s then
                        s.autoBankRestock = val and true or false
                    end
                end
                if _G.FluxBankRestockButton and _G.FluxBankRestockButton.Refresh then
                    pcall(_G.FluxBankRestockButton.Refresh)
                end
                NotifyVendorSettingsChanged()
            end,
        },
    },
    junkFilters = {
        {
            key = "junkFilterConsumable",
            name = "Low-level consumables",
            desc = "Mark low-level consumables as junk.",
            get = function()
                local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings()
                return s and s.junkFilters and s.junkFilters.consumable ~= false
            end,
            set = function(val)
                local s = _G.FluxVendorAuto.EnsureSettings()
                s.junkFilters = s.junkFilters or {}
                s.junkFilters.consumable = val and true or false
                NotifyVendorSettingsChanged()
            end,
        },
        {
            key = "junkFilterUnusable",
            name = "Unusable equipment",
            desc = "Mark gear your class cannot use as junk.",
            get = function()
                local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings()
                return s and s.junkFilters and s.junkFilters.unusable ~= false
            end,
            set = function(val)
                local s = _G.FluxVendorAuto.EnsureSettings()
                s.junkFilters = s.junkFilters or {}
                s.junkFilters.unusable = val and true or false
                NotifyVendorSettingsChanged()
            end,
        },
        {
            key = "junkFilterConjureInferior",
            name = "Sell non-conjured food & water",
            desc = "With Conjure Food, Water, or Refreshment learned: auto-junk non-conjured food/water (no Well Fed). Inferior tiers on the other axis still apply when conjure does not cover it.",
            get = function()
                local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings()
                return s and s.junkFilters and s.junkFilters.conjureInferiorFoodWater ~= false
            end,
            set = function(val)
                local s = _G.FluxVendorAuto.EnsureSettings()
                s.junkFilters = s.junkFilters or {}
                s.junkFilters.conjureInferiorFoodWater = val and true or false
                local FJ = _G.FluxVendorJunk
                if FJ then
                    if val and FJ.ScheduleConjureInferiorJunkSync then
                        FJ.ScheduleConjureInferiorJunkSync(true)
                    end
                    if FJ.FireListChanged then
                        FJ.FireListChanged()
                    end
                end
                NotifyVendorSettingsChanged()
            end,
        },
        {
            key = "junkFilterDestroy",
            name = "Destroy unsellable junk",
            desc = "Delete one unsellable junk item per vendor sell pass.",
            get = function()
                local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings()
                return s and s.junkFilters and s.junkFilters.destroy ~= false
            end,
            set = function(val)
                local s = _G.FluxVendorAuto.EnsureSettings()
                s.junkFilters = s.junkFilters or {}
                s.junkFilters.destroy = val and true or false
                NotifyVendorSettingsChanged()
            end,
        },
        {
            key = "junkFilterSafe",
            name = "Safe batch sell",
            desc = "Sell junk in small batches.",
            get = function()
                local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings()
                return s and s.junkFilters and s.junkFilters.safe ~= false
            end,
            set = function(val)
                local s = _G.FluxVendorAuto.EnsureSettings()
                s.junkFilters = s.junkFilters or {}
                s.junkFilters.safe = val and true or false
                NotifyVendorSettingsChanged()
            end,
        },
    },
    junkDisplay = {
        {
            key = "junkDisplayGlow",
            name = "Junk glow on bag slots",
            desc = "Show a glow on bag slots that contain junk.",
            get = function()
                local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings()
                return s and s.junkDisplay and s.junkDisplay.glow ~= false
            end,
            set = function(val)
                local s = _G.FluxVendorAuto.EnsureSettings()
                s.junkDisplay = s.junkDisplay or {}
                s.junkDisplay.glow = val and true or false
                local FJ = _G.FluxVendorJunk
                if FJ and FJ.FireListChanged then
                    FJ.FireListChanged()
                end
                NotifyVendorSettingsChanged()
            end,
        },
        {
            key = "junkDisplayIcons",
            name = "Junk coin icon on bag slots",
            desc = "Show a coin icon on bag slots that contain junk.",
            get = function()
                local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings()
                return s and s.junkDisplay and s.junkDisplay.icons ~= false
            end,
            set = function(val)
                local s = _G.FluxVendorAuto.EnsureSettings()
                s.junkDisplay = s.junkDisplay or {}
                s.junkDisplay.icons = val and true or false
                local FJ = _G.FluxVendorJunk
                if FJ and FJ.FireListChanged then
                    FJ.FireListChanged()
                end
                NotifyVendorSettingsChanged()
            end,
        },
    },
}

local function AddSectionToggles(args, sectionKey, orderBase)
    local list = _G.FluxOptionsToggleGridSections and _G.FluxOptionsToggleGridSections[sectionKey]
    if type(list) ~= "table" then
        return
    end
    for i = 1, #list do
        local toggle = list[i]
        if toggle and toggle.key then
            args[toggle.key] = {
                type = "toggle",
                name = toggle.name or toggle.key,
                desc = toggle.desc,
                order = orderBase + (i * 0.01),
                hidden = toggle.hidden,
                disabled = toggle.disabled,
                get = function()
                    return toggle.get and toggle.get() or false
                end,
                set = function(_, val)
                    if toggle.set then
                        toggle.set(val)
                    end
                end,
            }
        end
    end
end

local function BuildVendorOptions()
    local salvage = _G.FluxOptionsSalvageGroup and _G.FluxOptionsSalvageGroup() or {
        name = "Salvage",
        desc = "One-click mill, prospect, disenchant, and similar bag actions.",
        type = "group",
        order = 3,
        args = {},
    }

    local vendorArgs = {
        automationHeader = {
            type = "header",
            name = "Automation",
            order = 1,
        },
        automationDesc = {
            type = "description",
            name = "Repair, selling, and restock that run when a vendor or the bank opens.\n",
            order = 1.1,
            fontSize = "small",
            width = "full",
        },
    }
    AddSectionToggles(vendorArgs, "automation", 2)

    vendorArgs.junkHeader = {
        type = "header",
        name = "Junk detection",
        order = 10,
    }
    AddSectionToggles(vendorArgs, "junkFilters", 11)
    vendorArgs.junkListHelp = {
        type = "description",
        name = "In the Restock tab junk grid: |cffffcc66M|r = manually added, |cff888888A|r = auto-marked.\n",
        order = 12,
        fontSize = "small",
        width = "full",
    }

    vendorArgs.bagHeader = {
        type = "header",
        name = "Bag indicators",
        order = 20,
    }
    vendorArgs.bagDesc = {
        type = "description",
        name = "Marks on bag slots that hold junk.\n",
        order = 20.1,
        fontSize = "small",
        width = "full",
    }
    AddSectionToggles(vendorArgs, "junkDisplay", 21)

    vendorArgs.alreadyKnownHeader = {
        type = "header",
        name = "Already known items",
        order = 30,
    }
    vendorArgs.alreadyKnownStandaloneNote = {
        type = "description",
        name = function()
            local AK = _G.FluxAlreadyKnown
            if AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded() then
                return "|cffff6666Standalone AlreadyKnown is loaded.|r FluxUI's built-in tint is disabled while that addon is enabled.\n"
            end
            return "Tints learnable items you already own at merchants, the auction house, and guild bank.\n"
        end,
        order = 30.5,
        fontSize = "small",
        width = "full",
    }
    vendorArgs.alreadyKnownEnabled = {
        type = "toggle",
        name = "Tint already-known items",
        desc = "Highlight vendor, auction, and guild-bank items you have already learned or collected.",
        order = 31,
        disabled = function()
            local AK = _G.FluxAlreadyKnown
            return AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded()
        end,
        get = function()
            local AK = _G.FluxAlreadyKnown
            if AK and AK.GetSettings then
                return AK.GetSettings().enabled ~= false
            end
            local s = _G.FluxVendorAuto and _G.FluxVendorAuto.EnsureSettings and _G.FluxVendorAuto.EnsureSettings()
            return s and s.alreadyKnown and s.alreadyKnown.enabled ~= false
        end,
        set = function(_, val)
            local AK = _G.FluxAlreadyKnown
            if AK and AK.GetSettings then
                AK.GetSettings().enabled = val and true or false
                if AK.NotifySettingsChanged then
                    AK.NotifySettingsChanged()
                end
            end
        end,
    }
    vendorArgs.alreadyKnownMonochrome = {
        type = "toggle",
        name = "Monochrome tint",
        desc = "Desaturate icons for already-known items.",
        order = 32,
        disabled = function()
            local AK = _G.FluxAlreadyKnown
            if AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded() then
                return true
            end
            if AK and AK.GetSettings then
                return AK.GetSettings().enabled == false
            end
            return false
        end,
        get = function()
            local AK = _G.FluxAlreadyKnown
            return AK and AK.GetSettings and AK.GetSettings().monochrome or false
        end,
        set = function(_, val)
            local AK = _G.FluxAlreadyKnown
            if AK and AK.GetSettings then
                AK.GetSettings().monochrome = val and true or false
                if AK.NotifySettingsChanged then
                    AK.NotifySettingsChanged()
                end
            end
        end,
    }
    vendorArgs.alreadyKnownColor = {
        type = "color",
        name = "Tint color",
        desc = "Color used for already-known item highlights.",
        order = 33,
        hasAlpha = false,
        disabled = function()
            local AK = _G.FluxAlreadyKnown
            if AK and AK.IsStandaloneLoaded and AK.IsStandaloneLoaded() then
                return true
            end
            if AK and AK.GetSettings then
                return AK.GetSettings().enabled == false
            end
            return false
        end,
        get = function()
            local AK = _G.FluxAlreadyKnown
            local db = AK and AK.GetSettings and AK.GetSettings() or { r = 0, g = 1, b = 0 }
            return db.r or 0, db.g or 1, db.b or 0
        end,
        set = function(_, r, g, b)
            local AK = _G.FluxAlreadyKnown
            if AK and AK.GetSettings then
                local db = AK.GetSettings()
                db.r, db.g, db.b = r, g, b
                if AK.NotifySettingsChanged then
                    AK.NotifySettingsChanged()
                end
            end
        end,
    }

    return {
        name = "Inventory",
        type = "group",
        order = 21,
        childGroups = "tab",
        args = {
            salvage = salvage,
            vendor = {
                name = "Vendor",
                desc = "Repair, selling, junk rules, bag markers, and already-known tint.",
                type = "group",
                order = 1,
                args = vendorArgs,
            },
            restock = {
                name = "Restock",
                desc = "Item targets to buy from vendors and pull from the bank.",
                type = "group",
                order = 2,
                args = {
                    restockHelp = {
                        type = "description",
                        name = "Drag items into the grids. Preset restock lists spell reagents from your spell book.\n"
                            .. "bags/target — stock vs target (green = enough, red = short). Click to edit.\n"
                            .. "Coin — count bank stock toward the target. |cff7fbfff+N|r — how much is in the bank.\n",
                        order = 1,
                        fontSize = "small",
                        width = "full",
                    },
                    restockPanel = {
                        type = "description",
                        dialogControl = "FluxRestockPanel",
                        name = " ",
                        order = 2,
                        width = "full",
                    },
                    clearRestock = {
                        type = "execute",
                        name = "Clear all restock targets",
                        order = 3,
                        width = "full",
                        confirm = true,
                        confirmText = "Set every restock target to zero?",
                        func = function()
                            local FV = _G.FluxVendorAuto
                            if FV and FV.EnsureSettings then
                                local s = FV.EnsureSettings()
                                if s then
                                    s.restockItems = {}
                                end
                            end
                            NotifyVendorSettingsChanged()
                        end,
                    },
                },
            },
        },
    }
end

if FluxOptions and FluxOptions.RegisterModuleOptions then
    FluxOptions:RegisterModuleOptions("vendor", BuildVendorOptions)
end
