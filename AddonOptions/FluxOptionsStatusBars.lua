local addonName, ns = ...

local function NotifyFluxUIConfig()
    local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if ACR then
        ACR:NotifyChange("FluxUI")
    end
end

local function EnsurePVPTrackingSavedVars()
    if not _FluxUI_CharSavedVars then
        _FluxUI_CharSavedVars = {}
    end
    if not _FluxUI_CharSavedVars.PVPTracking then
        _FluxUI_CharSavedVars.PVPTracking = {
            trackHonor = false,
            trackArena = false,
        }
    end
    return _FluxUI_CharSavedVars.PVPTracking
end

local function BuildStatusBarsOptions()
    local statusBarsOptions = {
    name = "Status Bars",
    type = "group",
    order = 35,
    args = {
        intro = {
            type = "description",
            name = "Gold, experience, and reputation strips share one height. Layout placement (under menu vs bottom strip) stays on the Layout tab. Gold bar item tracking (up to six item counts) is always per character, regardless of the Status bar settings scope below.\n",
            order = 0,
            fontSize = "medium",
            width = "full",
        },
        scopeHeader = {
            type = "header",
            name = "Status bar scope",
            order = 2,
        },
        statusBarsSettingsScope = {
            type = "select",
            name = "Status bar settings scope",
            desc = "Account-wide: currency strip on/off and bar height use the active profile. Character-specific: those use this character only (account values are copied when you first switch). Independent of General -> Settings scope.",
            order = 3,
            width = "full",
            values = {
                account = "Account-wide",
                character = "Character-specific",
            },
            sorting = { "account", "character" },
            get = function()
                return FluxOptions:IsStatusBarsCharacterSpecific() and "character" or "account"
            end,
            set = function(_, val)
                FluxOptions:SetStatusBarsCharacterSpecific(val == "character")
                NotifyFluxUIConfig()
            end,
        },
        showCurrencyBar = {
            type = "toggle",
            name = "Show currency (gold) bar",
            desc = "When off, the gold strip is hidden. Experience and reputation strips still show when applicable.",
            order = 10,
            width = "full",
            get = function()
                local d = FluxOptions:GetStatusBarSettingsDB()
                if d and d.showCurrencyBar == false then
                    return false
                end
                return true
            end,
            set = function(_, val)
                local d = FluxOptions:GetStatusBarSettingsDB()
                if d then
                    d.showCurrencyBar = val and true or false
                end
                FluxOptions:RefreshStatusBarScopedModules()
            end,
        },
        hideExpBarAtMaxLevel = {
            type = "toggle",
            name = "Hide experience bar when not gaining XP",
            desc = "When on, the experience strip is removed whenever the game would hide the default XP bar (for example at max level). When off, Flux can still show the gray Max Level strip if you are not watching a faction, so you can click it to open Reputation.",
            order = 10.5,
            width = "full",
            get = function()
                local d = FluxOptions:GetStatusBarSettingsDB()
                return d and d.hideExpBarAtMaxLevel and true or false
            end,
            set = function(_, val)
                local d = FluxOptions:GetStatusBarSettingsDB()
                if d then
                    d.hideExpBarAtMaxLevel = val and true or false
                end
                FluxOptions:RefreshStatusBarScopedModules()
            end,
        },
        barHeight = {
            type = "range",
            name = "Bar height",
            desc = "Pixel height for gold, experience, and reputation strips (shared).",
            order = 11,
            min = 10,
            max = 40,
            step = 1,
            width = "full",
            get = function()
                local d = FluxOptions:GetStatusBarSettingsDB()
                local h = d and d.barHeight
                if type(h) == "number" and h == h then
                    return h
                end
                return 18
            end,
            set = function(_, val)
                local d = FluxOptions:GetStatusBarSettingsDB()
                if d then
                    d.barHeight = val
                end
                FluxOptions:RefreshStatusBarScopedModules()
            end,
        },
        resetStatusBars = {
            type = "execute",
            name = "Reset status bar options to defaults",
            desc = "Restores currency strip on, default height, hide-XP-bar default, and item currency fields for the current status bar scope.",
            order = 12,
            width = "full",
            confirm = true,
            confirmText = "Reset status bar strip options to defaults for this scope?",
            func = function()
                FluxOptions:ResetStatusBarsToDefaults()
            end,
        },
        pvpHeader = {
            type = "header",
            name = "Honor & Arena on status bar",
            order = 20,
            hidden = function()
                return not (FluxPVPTracking and FluxPVPTracking.ShouldEnable and FluxPVPTracking.ShouldEnable())
            end,
        },
        pvpIntro = {
            type = "description",
            name = "On this client, Honor and Arena can be shown on the gold strip. These toggles are stored per character (same as the PVP panel checkboxes).\n",
            order = 21,
            fontSize = "small",
            width = "full",
            hidden = function()
                return not (FluxPVPTracking and FluxPVPTracking.ShouldEnable and FluxPVPTracking.ShouldEnable())
            end,
        },
        trackHonorInBar = {
            type = "toggle",
            name = "Show Honor on status bar",
            order = 22,
            width = "full",
            hidden = function()
                return not (FluxPVPTracking and FluxPVPTracking.ShouldEnable and FluxPVPTracking.ShouldEnable())
            end,
            get = function()
                local p = EnsurePVPTrackingSavedVars()
                return p.trackHonor and true or false
            end,
            set = function(_, val)
                local p = EnsurePVPTrackingSavedVars()
                p.trackHonor = val and true or false
                if FluxPVPTracking and FluxPVPTracking.SyncHonorArenaCheckboxesFromSavedVars then
                    FluxPVPTracking.SyncHonorArenaCheckboxesFromSavedVars()
                end
                if _G.UpdateGoldBar then
                    pcall(_G.UpdateGoldBar)
                end
            end,
        },
        trackArenaInBar = {
            type = "toggle",
            name = "Show Arena Points on status bar",
            order = 23,
            width = "full",
            hidden = function()
                return not (FluxPVPTracking and FluxPVPTracking.ShouldEnable and FluxPVPTracking.ShouldEnable())
            end,
            get = function()
                local p = EnsurePVPTrackingSavedVars()
                return p.trackArena and true or false
            end,
            set = function(_, val)
                local p = EnsurePVPTrackingSavedVars()
                p.trackArena = val and true or false
                if FluxPVPTracking and FluxPVPTracking.SyncHonorArenaCheckboxesFromSavedVars then
                    FluxPVPTracking.SyncHonorArenaCheckboxesFromSavedVars()
                end
                if _G.UpdateGoldBar then
                    pcall(_G.UpdateGoldBar)
                end
            end,
        },
    },
}

-- Item currency (bag token counts) - drag/drop from bags via AceGUIWidget-FluxItemCurrencySlots
do
    local function RefAfterItemCurrency()
        if _G.FluxItemCurrencyTracking and _G.FluxItemCurrencyTracking.NotifyItemCurrencyChanged then
            _G.FluxItemCurrencyTracking.NotifyItemCurrencyChanged()
        else
            if FluxOptions then
                FluxOptions:RefreshStatusBarScopedModules()
            end
            if _G.UpdateGoldBar then
                pcall(_G.UpdateGoldBar)
            end
        end
    end

    local function GetItemCurrencyDB()
        if _G.FluxItemCurrencyTracking and _G.FluxItemCurrencyTracking.EnsureItemCurrencyData then
            return _G.FluxItemCurrencyTracking.EnsureItemCurrencyData()
        end
        return nil
    end

    local args = statusBarsOptions.args
    args.itemCurrencyHeader = {
        type = "header",
        name = "Item currency (bag counts)",
        order = 25,
    }
    args.itemCurrencyIntro = {
        type = "description",
        name = "Per character (not account-wide). Icons in a grid: drag to reorder, drag from bags to assign, cursor + click to place, right-click a slot to clear. Counts on the gold strip appear when the main toggle is on and you have at least one of that item.\n",
        order = 25.1,
        fontSize = "small",
        width = "full",
    }
    args.itemCurrencyEnabled = {
        type = "toggle",
        name = "Show item currency on gold strip",
        desc = "When on, each slotted item with a non-zero bag count is shown on the bar after gold / game currencies and Honor & Arena (if any).",
        order = 25.2,
        width = "full",
        get = function()
            local ic = GetItemCurrencyDB()
            return ic and ic.enabled and true or false
        end,
        set = function(_, val)
            local ic = GetItemCurrencyDB()
            if ic then
                ic.enabled = val and true or false
            end
            RefAfterItemCurrency()
        end,
    }
    args.itemCurrencySlotPanel = {
        type = "description",
        name = " ",
        desc = "Drag to reorder, drag an item from bags onto an icon, or use the cursor. Right-click clears a slot.",
        order = 25.3,
        width = "full",
        fontSize = "medium",
        dialogControl = "FluxItemCurrencySlots",
    }
end

-- Account gold (FluxUIGoldLedger): remove deleted alts or stale keys from tooltip SavedVariables
do
    local ledgerPick = { keys = {}, lastIdx = 1 }

    local function SyncGoldLedgerSelect()
        table.wipe(ledgerPick.keys)
        if not _G.FluxGoldLedger or not _G.FluxGoldLedger.GetConfigLedgerIndex then
            ledgerPick.keys[1] = false
            return { [1] = "(not loaded)" }
        end
        local list = _G.FluxGoldLedger:GetConfigLedgerIndex()
        if not list or #list < 1 then
            ledgerPick.keys[1] = false
            return { [1] = "- none -" }
        end
        if (ledgerPick.lastIdx or 1) > #list or (ledgerPick.lastIdx or 1) < 1 then
            ledgerPick.lastIdx = 1
        end
        local vals = {}
        for i, e in ipairs(list) do
            vals[i] = e.label
            ledgerPick.keys[i] = e.k
        end
        return vals
    end

    local a = statusBarsOptions.args
    a.goldLedgerHeader = {
        type = "header",
        name = "Account gold (multi-character tooltip)",
        order = 12.3,
    }
    a.goldLedgerDesc = {
        type = "description",
        name = "Gold per character is stored with Flux inventory awareness (or Syndicator, if that addon is loaded) and shown on this bar tooltip. If you have deleted a character, pick them here and remove the row so they never appear in the list again. For your current character, the row reappears the next time your gold amount changes.\n",
        order = 12.32,
        fontSize = "small",
        width = "full",
    }
    a.goldLedgerSelect = {
        type = "select",
        name = "Stored character",
        desc = "Short lines: name / realm / gold. * = this character (re-adds to the list when you earn or spend gold). Pick a row, then delete if needed. Sorted by name, then realm.",
        order = 12.35,
        width = "full",
        values = function()
            return SyncGoldLedgerSelect()
        end,
        get = function()
            SyncGoldLedgerSelect()
            if ledgerPick.keys[1] == false then
                return 1
            end
            local m = math.floor(tonumber(ledgerPick.lastIdx) or 1)
            m = math.max(1, math.min(m, #ledgerPick.keys))
            ledgerPick.lastIdx = m
            return m
        end,
        set = function(_, v)
            ledgerPick.lastIdx = v
        end,
    }
    a.goldLedgerDelete = {
        type = "execute",
        name = "Delete selected character from ledger",
        desc = "Hides that character from the account gold tooltip. Inventory item locations for that character are kept. The only way to show gold again is to log that character so the addon can re-save their gold.",
        order = 12.4,
        width = "double",
        confirm = true,
        confirmText = "Remove this entry from the account gold saved data? The only way to get it back is to log that character again so the addon can re-save their gold.",
        func = function()
            if not _G.FluxGoldLedger or not _G.FluxGoldLedger.DeleteLedgerEntryByKey then
                return
            end
            SyncGoldLedgerSelect()
            local idx = math.floor(tonumber(ledgerPick.lastIdx) or 1)
            if ledgerPick.keys[1] == false or idx < 1 or idx > #ledgerPick.keys then
                return
            end
            local key = ledgerPick.keys[idx]
            if not key then
                return
            end
            if _G.FluxGoldLedger:DeleteLedgerEntryByKey(key) then
                ledgerPick.lastIdx = 1
                NotifyFluxUIConfig()
            end
        end,
        disabled = function()
            if not _G.FluxGoldLedger or not _G.FluxGoldLedger.GetConfigLedgerIndex then
                return true
            end
            local n = 0
            pcall(function()
                n = #_G.FluxGoldLedger:GetConfigLedgerIndex()
            end)
            return n < 1
        end,
    }
end

do
    local function InvTipDB()
        return FluxOptions and FluxOptions.GetStatusBarSettingsDB and FluxOptions:GetStatusBarSettingsDB()
    end
    local function SyndicatorOwnsTips()
        local FluxNS = _G.Flux
        local tip = FluxNS and FluxNS.Inventory and FluxNS.Inventory.Tooltip
        if tip and tip.IsDelegated then
            return tip.IsDelegated()
        end
        return FluxNS and FluxNS.Optional and FluxNS.Optional.IsLoaded and FluxNS.Optional.IsLoaded("Syndicator")
    end
    local function HasGuildBank()
        local Cap = _G.Flux and _G.Flux.Cap
        return Cap and Cap.hasGuildBank
    end
    local function HasCurrencies()
        local Cap = _G.Flux and _G.Flux.Cap
        return Cap and (Cap.hasCurrencyTokens or Cap.hasCharacterCurrencyTab)
    end

    local a = statusBarsOptions.args
    a.invTipHeader = {
        type = "header",
        name = "Inventory awareness",
        order = 12.5,
    }
    a.invTipDesc = {
        type = "description",
        name = function()
            if SyndicatorOwnsTips() then
                return "Syndicator is loaded, so item and currency location lines on tooltips come from that addon. Flux will not add a second copy.\n"
            end
            return "When Syndicator is not loaded, Flux tracks bags, bank, mail (including mail sent to known alts), auctions, equipped gear, and (where the client has them) guild bank, void storage, warband bank, and currencies. Location lines are added to item tooltips.\n"
        end,
        order = 12.51,
        fontSize = "small",
        width = "full",
    }
    local function TipToggle(key, name, desc, order, hiddenFn)
        return {
            type = "toggle",
            name = name,
            desc = desc,
            order = order,
            width = "full",
            disabled = SyndicatorOwnsTips,
            hidden = hiddenFn,
            get = function()
                local d = InvTipDB()
                if not d then
                    return true
                end
                if d[key] == false then
                    return false
                end
                return d[key] ~= false
            end,
            set = function(_, val)
                local d = InvTipDB()
                if d then
                    d[key] = val and true or false
                end
            end,
        }
    end
    a.invTipShowItems = TipToggle(
        "invTipShowItems",
        "Show item locations on tooltips",
        "Bags, bank, mail, auctions, and other stored locations on this account.",
        12.52
    )
    a.invTipShowCurrencies = TipToggle(
        "invTipShowCurrencies",
        "Show currency locations on tooltips",
        "Token counts on your other characters.",
        12.53,
        function()
            return not HasCurrencies()
        end
    )
    a.invTipShiftOnly = {
        type = "toggle",
        name = "Only while Shift is held",
        desc = "Location lines appear only while you hold Shift.",
        order = 12.54,
        width = "full",
        disabled = SyndicatorOwnsTips,
        get = function()
            local d = InvTipDB()
            return d and d.invTipShiftOnly and true or false
        end,
        set = function(_, val)
            local d = InvTipDB()
            if d then
                d.invTipShiftOnly = val and true or false
            end
        end,
    }
    a.invTipConnectedRealms = {
        type = "toggle",
        name = "Connected realms only",
        desc = "Hide characters on realms that are not connected to this one.",
        order = 12.55,
        width = "full",
        disabled = SyndicatorOwnsTips,
        get = function()
            local d = InvTipDB()
            return d and d.invTipConnectedRealms and true or false
        end,
        set = function(_, val)
            local d = InvTipDB()
            if d then
                d.invTipConnectedRealms = val and true or false
            end
        end,
    }
    a.invTipFactionOnly = {
        type = "toggle",
        name = "Same faction only",
        desc = "Hide characters of the opposite faction.",
        order = 12.56,
        width = "full",
        disabled = SyndicatorOwnsTips,
        get = function()
            local d = InvTipDB()
            return d and d.invTipFactionOnly and true or false
        end,
        set = function(_, val)
            local d = InvTipDB()
            if d then
                d.invTipFactionOnly = val and true or false
            end
        end,
    }
    a.invTipShowEquipped = TipToggle(
        "invTipShowEquipped",
        "Include equipped items",
        "Count gear currently worn on each character.",
        12.57
    )
    a.invTipShowGuild = TipToggle(
        "invTipShowGuild",
        "Include guild bank",
        "Show guild bank stacks when that vault has been visited.",
        12.58,
        function()
            return not HasGuildBank()
        end
    )
    a.invTipBlankLine = TipToggle(
        "invTipBlankLine",
        "Blank line before inventory block",
        "Adds a spacer above the location lines.",
        12.59
    )
    a.invTipRaceIcons = TipToggle(
        "invTipRaceIcons",
        "Show race / gender icons",
        "Race and gender atlas next to each character (guild banner / warband icon too), same as Syndicator.",
        12.60
    )
end

    return statusBarsOptions
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")

    if FluxOptions and FluxOptions.RegisterModuleOptions then
        FluxOptions:RegisterModuleOptions("statusBars", BuildStatusBarsOptions)
    end
end)

