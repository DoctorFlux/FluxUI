local addonName, ns = ...

local function GetInfoFrameCharDB()
    if _G.FluxInfoFrame and _G.FluxInfoFrame.GetCharDB then
        return _G.FluxInfoFrame.GetCharDB()
    end
    _FluxUI_CharSavedVars = _FluxUI_CharSavedVars or {}
    if not _FluxUI_CharSavedVars.infoFrame then
        _FluxUI_CharSavedVars.infoFrame = {
            showFPS = true,
            showDurability = false,
            showPing = true,
            pinnedStats = {},
            spellDisplayMode = "off",
            statOrder = {},
        }
    end
    return _FluxUI_CharSavedVars.infoFrame
end

local function RefreshInfoFrame()
    if _G.FluxInfoFrame and _G.FluxInfoFrame.ForceRebuild then
        _G.FluxInfoFrame.ForceRebuild()
    end
    if _G.FluxInfoStatOrder_RequestRefresh then
        _G.FluxInfoStatOrder_RequestRefresh()
    end
end

local function NotifyFluxUIConfig()
    local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if ACR then
        ACR:NotifyChange("FluxUI")
    end
end

local function BuildInfoOptions()
    return {
        name = "Info",
        type = "group",
        order = 36,
        args = {
            intro = {
                type = "description",
                name = "FPS, ping, durability, and stats pinned from the character panel. These toggles are always per character. Where the whole panel sits is on the Layout tab.\n",
                order = 0,
                fontSize = "medium",
                width = "full",
            },
            infoShowFPS = {
                type = "toggle",
                name = "Show FPS",
                desc = "Display frames per second on the Info panel.",
                order = 10,
                width = "normal",
                get = function()
                    return GetInfoFrameCharDB().showFPS
                end,
                set = function(_, val)
                    GetInfoFrameCharDB().showFPS = val
                    RefreshInfoFrame()
                end,
            },
            infoShowPing = {
                type = "toggle",
                name = "Show Ping",
                desc = "Display world latency on the Info panel.",
                order = 11,
                width = "normal",
                get = function()
                    return GetInfoFrameCharDB().showPing
                end,
                set = function(_, val)
                    GetInfoFrameCharDB().showPing = val
                    RefreshInfoFrame()
                end,
            },
            infoShowDurability = {
                type = "toggle",
                name = "Show Durability",
                desc = "Display average gear durability on the Info panel.",
                order = 12,
                width = "normal",
                get = function()
                    return GetInfoFrameCharDB().showDurability
                end,
                set = function(_, val)
                    GetInfoFrameCharDB().showDurability = val
                    RefreshInfoFrame()
                end,
            },
            infoResetPinned = {
                type = "execute",
                name = "Clear pinned stats",
                desc = "Remove all character stats pinned to the Info panel.",
                order = 13,
                width = "normal",
                confirm = true,
                confirmText = "Remove all pinned stats from the Info panel?",
                func = function()
                    local db = GetInfoFrameCharDB()
                    db.pinnedStats = {}
                    RefreshInfoFrame()
                end,
            },
            orderHeader = {
                type = "header",
                name = "Stat order",
                order = 20,
            },
            orderDesc = {
                type = "description",
                name = "Drag a row to change the order inside the panel. Newly pinned stats are added at the end.\n",
                order = 21,
                fontSize = "medium",
                width = "full",
            },
            statOrder = {
                type = "description",
                name = " ",
                dialogControl = "FluxInfoStatOrder",
                order = 22,
            },
            slotHeader = {
                type = "header",
                name = "Status bar cell",
                order = 30,
            },
            slotDesc = {
                type = "description",
                name = "Used when Layout places the panel on the status bar. Left, between, and right are columns on the horizontal status row. On the stacked status bar under the micro menu, the same choice is the top row, the row after the first bar, or the bottom row.\n",
                order = 31,
                fontSize = "medium",
                width = "full",
            },
            infoStatusSlot = {
                type = "select",
                name = "Cell position",
                desc = "Where the info cell sits among gold, experience, and reputation.",
                order = 32,
                width = "full",
                values = {
                    start = "Left",
                    middle = "Between",
                    ["end"] = "Right",
                },
                sorting = { "start", "middle", "end" },
                get = function()
                    if FluxOptions and FluxOptions.GetInfoStatusSlot then
                        return FluxOptions:GetInfoStatusSlot()
                    end
                    return "start"
                end,
                set = function(_, val)
                    local d = FluxOptions and FluxOptions.GetLayoutDB and FluxOptions:GetLayoutDB()
                    if d then
                        if val ~= "middle" and val ~= "end" then
                            val = "start"
                        end
                        d.infoStatusSlot = val
                    end
                    if FluxOptions and FluxOptions.RefreshLayoutDependents then
                        FluxOptions:RefreshLayoutDependents()
                    end
                    NotifyFluxUIConfig()
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
        FluxOptions:RegisterModuleOptions("info", BuildInfoOptions)
    end
end)

