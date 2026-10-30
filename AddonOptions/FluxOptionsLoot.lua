local addonName = ...

local function LootDB()
    return FluxOptions.db.profile.loot
end

local function Changed()
    if FluxLoot and FluxLoot.Refresh then
        FluxLoot:Refresh()
    end
end

local function BuildLootOptions()
    return {
        name = "Loot", type = "group", order = 3,
        args = {
            header = { type = "header", name = "Loot", order = 1 },
            fast = {
                type = "toggle", name = "Fast loot", order = 2, width = "full",
                desc = "Pick up loot as soon as it is ready, respecting your Auto Loot modifier. If the separate FasterLoot addon is enabled, it remains in charge; disable that addon to use this switch.",
                get = function() return LootDB().fast end,
                set = function(_, value) LootDB().fast = value; Changed() end,
            },
            alerts = {
                type = "toggle", name = "Show loot at cursor", order = 3, width = "full",
                desc = "Show a short, non-clickable list next to the cursor when you receive loot.",
                get = function() return LootDB().alerts end,
                set = function(_, value) LootDB().alerts = value; Changed() end,
            },
            money = {
                type = "toggle", name = "Money", order = 4,
                disabled = function() return not LootDB().alerts end,
                get = function() return LootDB().money end,
                set = function(_, value) LootDB().money = value; Changed() end,
            },
            currency = {
                type = "toggle", name = "Currency", order = 5,
                disabled = function() return not LootDB().alerts end,
                get = function() return LootDB().currency end,
                set = function(_, value) LootDB().currency = value; Changed() end,
            },
            quality = {
                type = "select", name = "Minimum item quality", order = 6,
                values = { [0] = "All", [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic" },
                disabled = function() return not LootDB().alerts end,
                get = function() return LootDB().quality end,
                set = function(_, value) LootDB().quality = value; Changed() end,
            },
            duration = {
                type = "range", name = "Disappear after (seconds)", order = 7, min = 2, max = 8, step = 1,
                desc = "How long each loot alert stays beside the cursor. Default: 3 seconds.",
                disabled = function() return not LootDB().alerts end,
                get = function() return LootDB().duration end,
                set = function(_, value) LootDB().duration = value; Changed() end,
            },
            preview = {
                type = "execute", name = "Preview", order = 8,
                disabled = function() return not LootDB().alerts end,
                func = function() if FluxLoot and FluxLoot.Preview then FluxLoot:Preview() end end,
            },
        },
    }
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, loaded)
    if loaded ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    FluxOptions:RegisterModuleOptions("loot", BuildLootOptions)
end)
