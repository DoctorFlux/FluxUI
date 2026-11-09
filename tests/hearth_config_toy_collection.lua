-- lua tests/hearth_config_toy_collection.lua (Lua 5.4); no WoW client is launched.
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end

local toc = assert(io.open("_FluxUI.toc", "rb")):read("*a")
local hearthPosition = assert(toc:find("ExtraButtonSystem\\NonCombatGrid\\FluxSmartHearthConfig.lua", 1, true))
local apiPosition = assert(toc:find("Core\\FluxAPI\\FluxAPI.lua", 1, true))
check(hearthPosition < apiPosition, "Hearth editor loads before FLUX_API bootstrap")

local capabilities = assert(io.open("Core/FluxAPI/Capabilities.lua", "rb")):read("*a")
local toyProbe = assert(capabilities:match("FLUX_API%.hasToyBox = ([^\r\n]+)"))
local probe = assert(load("return " .. toyProbe, "toy capability", "t", {
    C_ToyBox = { GetToyInfo = function() end },
    PlayerHasToy = function() return true end,
}))
check(probe(), "Toy Box capability does not require a Collections Journal toggle")

local noToy = { Flux = { Cap = { hasToyBox = false } } }
noToy._G = noToy
assert(loadfile("ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua", "t", noToy))()
check(noToy.FluxHearthConfig == nil, "non-Toy Box clients keep the basic fallback")

local env = setmetatable({}, { __index = _G })
env._G = env
env.Flux = { Cap = { hasToyBox = probe() } }
env.FLUX_API = false -- The TOC has not reached Core/FluxAPI yet.
env.RAID_CLASS_COLORS = { MAGE = { r = 0.2, g = 0.4, b = 1 } }
env.UnitClass = function() return "Mage", "MAGE" end
env.UnitName = function() return "Tester" end
env.GetRealmName = function() return "Realm" end
env.PlayerHasToy = function(id) return id == 54452 end
env.C_ToyBox = { GetToyInfo = function(id)
    if id == 54452 then return id, "Ethereal Portal", 12345 end
end }
env.C_Item = {
    GetItemIconByID = function(id) return id end,
    GetItemInfo = function(id) if id == 6948 then return "Basic Hearthstone" end end,
}
env.GetItemIcon = false -- Deprecated item globals may be disabled on modern clients.
env.GetItemInfo = false
env.GameTooltip = {
    SetOwner = function() end,
    SetText = function(_, name) env.tooltipName = name end,
    AddLine = function() end,
    Show = function() end,
    Hide = function() end,
}
env.C_Timer = { After = function() end }
env.SlashCmdList = {}
env.UIParent = {}
env.print = function() end
env.wipe = function(t) for k in pairs(t) do t[k] = nil end end

local frames = {}
local function widget(name, parent)
    local w = { scripts = {}, hooks = {}, events = {}, shown = true, parent = parent,
        flyout = false, clickCooldown = false }
    function w:RegisterEvent(event) self.events[event] = true end
    function w:UnregisterEvent(event) self.events[event] = nil end
    function w:SetScript(event, fn) self.scripts[event] = fn end
    function w:GetScript(event) return self.scripts[event] end
    function w:HookScript(event, fn)
        self.hooks[event] = self.hooks[event] or {}
        table.insert(self.hooks[event], fn)
    end
    function w:Fire(event, ...)
        if self.scripts[event] then self.scripts[event](self, ...) end
        for _, fn in ipairs(self.hooks[event] or {}) do fn(self, ...) end
    end
    function w:Show() self.shown = true; self:Fire("OnShow") end
    function w:Hide() self.shown = false; self:Fire("OnHide") end
    function w:IsShown() return self.shown end
    function w:GetFrameLevel() return 1 end
    function w:SetTexture(texture) self.texture = texture end
    function w:CreateFontString() return widget(nil, self) end
    function w:CreateTexture() return widget(nil, self) end
    setmetatable(w, { __index = function() return function() end end })
    if name then env[name] = w end
    frames[#frames + 1] = w
    return w
end
env.CreateFrame = function(_, name, parent) return widget(name, parent) end
env.C_AddOns = {
    LoadAddOn = function(name)
        check(name == "Blizzard_Collections", "loads the Collections Journal through C_AddOns")
        env.CollectionsJournal = widget("CollectionsJournal", env.UIParent)
        env.CollectionsJournal.shown = false
        env.CollectionsJournal.selectedTab = 1
        for _, tab in ipairs({ "ToysTab", "MountsTab", "PetsTab", "HeirloomsTab", "WardrobeTab" }) do
            env.CollectionsJournal[tab] = widget(nil, env.CollectionsJournal)
        end
        env.CollectionsJournal.WarbandScenesTab = false
        return true
    end,
}
env.ToggleToyCollection = function()
    env.CollectionsJournal.selectedTab = 3
    env.CollectionsJournal:Show()
end
env.CollectionsJournal_SetTab = function(journal, tab)
    journal.selectedTab = tab
    for _, fn in ipairs(env.setTabHooks or {}) do fn(journal, tab) end
end
env.hooksecurefunc = function(name, fn)
    check(name == "CollectionsJournal_SetTab", "hooks the native tab setter")
    env.setTabHooks = env.setTabHooks or {}
    table.insert(env.setTabHooks, fn)
end

assert(loadfile("Core/API/Item.lua", "t", env))("_FluxUI", { Flux = env.Flux })
assert(loadfile("ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua", "t", env))()
check(env.FluxHearthConfig ~= nil, "Hearth editor registers before FLUX_API exists")
check(env.SlashCmdList.FLUXHEARTH ~= nil, "Hearth command registers")

for _, frame in ipairs(frames) do
    if frame.events and frame.events.ADDON_LOADED then frame:Fire("OnEvent", "ADDON_LOADED", "_FluxUI") end
end
check(env.FluxHearthConfigFrame ~= nil, "editor frame created after Collections load")
check(not env.FluxHearthConfigFrame:IsShown(), "editor starts hidden")
env.SlashCmdList.FLUXHEARTH("config")
check(env.CollectionsJournal.selectedTab == 3 and env.FluxHearthConfigFrame:IsShown(),
    "config opens Toy Box and shows Hearth editor")

local choiceButton
for _, frame in ipairs(frames) do
    if frame.scripts.OnMouseUp then choiceButton = frame; break end
end
check(choiceButton ~= nil, "Hearth choice button exists")
check(choiceButton.icon.texture == 6948, "modern item API paints the basic Hearthstone icon")
choiceButton:Fire("OnEnter")
check(env.tooltipName == "Basic Hearthstone", "selector hover uses modern item name")
choiceButton:Fire("OnMouseUp", "LeftButton")
check(choiceButton.flyout and #choiceButton.flyout.items == 2, "owned toy and random choices appear")
choiceButton.flyout.items[2]:Fire("OnClick")
check(env.FluxNonCombatGridDB.global.hearthConfig.itemID == 54452, "selected toy persists")
check(env.FluxHearthConfig.GetHearthItem() == 54452, "Hearth button receives selected toy")
choiceButton:Fire("OnEnter")
check(env.tooltipName == "Ethereal Portal", "uncached toy hover uses Toy Box name")
choiceButton:Fire("OnMouseUp", "RightButton")
check(env.FluxNonCombatGridDB.global.hearthConfig.mode == "default"
    and env.FluxHearthConfig.GetHearthItem() == 6948, "right click restores basic Hearthstone")

env.CollectionsJournal:Hide()
env.ToggleToyCollection = false
env.SetCollectionsJournalShown = function(shown, tab)
    env.CollectionsJournal.selectedTab = tab
    if shown then env.CollectionsJournal:Show() end
end
env.SlashCmdList.FLUXHEARTH("config")
check(env.CollectionsJournal.selectedTab == 3 and env.FluxHearthConfigFrame:IsShown(),
    "native journal show fallback opens the editor")

print(("hearth_config_toy_collection: %d checks passed"):format(checks))
