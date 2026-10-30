-- Desktop event model for cursor alerts and optional fast pickup.
local now, external, quality = 10, true, 2
local slots, frames, texts, pickups = {}, {}, {}, {}
assert(loadfile("AddonOptions/FluxOptionsDefaults.lua"))("_FluxUI", {})
local defaults = FluxOptionsDefaults.profile.loot
assert(defaults.fast == true and defaults.alerts == true and defaults.duration == 3,
    "all clients use the same on/on/3-second defaults")
local settings = {
    fast = defaults.fast, alerts = defaults.alerts, money = defaults.money,
    currency = defaults.currency, quality = defaults.quality, duration = defaults.duration,
}

local function Region()
    return setmetatable({}, { __index = function(self, key)
        if key == "SetText" then return function(region, value)
            region.value = value
            texts[#texts + 1] = value
        end end
        if key == "SetTextColor" then return function(region, r, g, b)
            region.color = { r, g, b }
        end end
        if key == "SetTexture" then return function(region, value)
            region.texture = value
        end end
        return function() end
    end })
end

local function Frame()
    local frame = { events = {}, scripts = {}, visible = false }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:UnregisterEvent(event) self.events[event] = nil end
    function frame:UnregisterAllEvents() self.events = {} end
    function frame:SetScript(event, func) self.scripts[event] = func end
    function frame:CreateTexture() return Region() end
    function frame:CreateFontString() return Region() end
    function frame:Show() self.visible = true end
    function frame:Hide() self.visible = false end
    function frame:GetEffectiveScale() return 1 end
    function frame:GetWidth() return 1920 end
    function frame:GetHeight() return 1080 end
    setmetatable(frame, { __index = function() return function() end end })
    frames[#frames + 1] = frame
    return frame
end

CreateFrame = Frame
UIParent = Frame()
GetTime = function() return now end
GetCursorPosition = function() return 600, 500 end
GetNumLootItems = function() return #slots end
GetLootSlotLink = function(slot) return slots[slot] and slots[slot].link end
GetLootSlotInfo = function(slot) return nil, nil, slots[slot] and slots[slot].count end
LootSlot = function(slot) pickups[#pickups + 1] = slot end
GetCVarBool = function() return false end
IsModifiedClick = function() return true end
C_AddOns = { IsAddOnLoaded = function() return external end }
wipe = function(value) for key in pairs(value) do value[key] = nil end end
LOOT_ITEM_SELF = "You receive loot: %s."
LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %s x%d."
LOOT_ITEM_CREATED_SELF = "You |4make:makes;: %s."
YOU_LOOT_MONEY = "You loot %s."
YOU_LOOT_MONEY_GUILD = "Guild %1$s receives %2$s."
LOOT_MONEY_SPLIT = "Your share of loot is %s."
GOLD_AMOUNT = "%d |4Gold:Golds;"
SILVER_AMOUNT = "%d Silver"
COPPER_AMOUNT = "%d Copper"
local callbacks = {}
FluxOptions = { db = {
    profile = { loot = settings },
    RegisterCallback = function(target, event, method)
        assert(target == FluxLoot, "callback target")
        assert(type(event) == "string", "CallbackHandler event name must be a string")
        assert(method == FluxLoot.Refresh, "profile refresh callback")
        callbacks[event] = method
    end,
} }
local optionBuilder
FluxOptions.RegisterModuleOptions = function(_, key, builder)
    assert(key == "loot")
    optionBuilder = builder
end

local ns = { Flux = { Item = {
    GetInfo = function() return "Copper Ore", nil, quality, nil, nil, nil, nil, nil, nil, "ore-icon" end,
    GetIcon = function() return "ore-icon" end,
} } }
assert(loadfile("Other/FluxLoot.lua"))("_FluxUI", ns)
local anchor, events, loader = frames[2], frames[3], frames[4]
loader.scripts.OnEvent(loader, "ADDON_LOADED", "_FluxUI")
assert(loadfile("AddonOptions/FluxOptionsLoot.lua"))("_FluxUI", ns)
frames[5].scripts.OnEvent(frames[5], "ADDON_LOADED", "_FluxUI")
local options = optionBuilder().args
assert(options.fast.get() and options.alerts.get() and options.duration.get() == 3)
assert(options.duration.name == "Disappear after (seconds)")
options.duration.set(nil, 4)
assert(settings.duration == 4, "duration control updates the saved setting")
options.duration.set(nil, 3)
assert(events.events.LOOT_READY and events.events.CHAT_MSG_LOOT)

local function Fire(event, ...)
    assert(events.events[event], event .. " not registered")
    events.scripts.OnEvent(events, event, ...)
end
local function CountText(value)
    local count = 0
    for _, text in ipairs(texts) do if text == value then count = count + 1 end end
    return count
end
local function MoneyRow(value, icon)
    assert(CountText(value) == 1, "money symbols/amount: " .. value)
    for _, frame in ipairs(frames) do
        if rawget(frame, "text") and frame.text.value == value then
            assert(frame.icon.texture == "Interface\\MoneyFrame\\UI-" .. icon .. "Icon", "coin icon")
            assert(frame.text.color[1] == 1 and frame.text.color[2] == 1 and frame.text.color[3] == 1,
                "money numbers white")
            return
        end
    end
    error("money row not found")
end

local link = "|Hitem:123:0|h[Copper Ore]|h"
slots = { { link = link, count = 2 } }
Fire("LOOT_READY")
Fire("LOOT_SLOT_CLEARED", 1)
Fire("CHAT_MSG_LOOT", "You receive loot: " .. link .. " x2.")
assert(CountText("Copper Ore x2") == 1, "slot and chat must show once")
assert(anchor.visible, "alert visible")
now = 11
Fire("CHAT_MSG_LOOT", "You receive loot: " .. link .. " x2.")
assert(CountText("Copper Ore x2") == 2, "repeated same item must show")
now = 14.1
anchor.scripts.OnUpdate(anchor)
assert(not anchor.visible, "default 3-second alerts expire")

quality = 1
settings.quality = 2
now = 16
Fire("CHAT_MSG_LOOT", "You receive loot: " .. link .. ".")
assert(CountText("Copper Ore") == 0, "quality threshold")
settings.quality = 0
now = 21
Fire("CHAT_MSG_LOOT", "You make: " .. link .. ".")
assert(CountText("Copper Ore") == 1, "localized grammar alternative")
local coinArt = "|TInterface\\MoneyFrame\\UI-"
Fire("CHAT_MSG_MONEY", "You loot 99 Copper.")
MoneyRow("99" .. coinArt .. "CopperIcon:0:0:2:0|t", "Copper")
Fire("CHAT_MSG_MONEY", "You loot 1 Silver.")
MoneyRow("1" .. coinArt .. "SilverIcon:0:0:2:0|t", "Silver")
Fire("CHAT_MSG_MONEY", "You loot 99 Silver, 99 Copper.")
MoneyRow("99" .. coinArt .. "SilverIcon:0:0:2:0|t 99" .. coinArt .. "CopperIcon:0:0:2:0|t", "Silver")
Fire("CHAT_MSG_MONEY", "You loot 1 Gold.")
MoneyRow("1" .. coinArt .. "GoldIcon:0:0:2:0|t", "Gold")
Fire("CHAT_MSG_MONEY", "You loot 2 Golds.")
MoneyRow("2" .. coinArt .. "GoldIcon:0:0:2:0|t", "Gold")
Fire("CHAT_MSG_MONEY", "Guild Example receives 3 Golds.")
MoneyRow("3" .. coinArt .. "GoldIcon:0:0:2:0|t", "Gold")
Fire("CHAT_MSG_MONEY", "Your share of loot is 1 Gold, 2 Silver, 3 Copper.")
MoneyRow("1" .. coinArt .. "GoldIcon:0:0:2:0|t 2" .. coinArt .. "SilverIcon:0:0:2:0|t 3" .. coinArt .. "CopperIcon:0:0:2:0|t", "Gold")
Fire("CHAT_MSG_MONEY", "You spent 1 Gold.")
assert(CountText("You spent 1 Gold.") == 0, "only received money")
Fire("CHAT_MSG_CURRENCY", "You receive 3 badges.")
assert(CountText("You receive 3 badges.") == 1)

settings.alerts = false
callbacks.OnProfileChanged(FluxLoot)
assert(not events.events.CHAT_MSG_LOOT and not anchor.visible, "disabled alerts stop events and hide rows")
settings.fast = true
external = false
FluxLoot:Refresh()
assert(events.events.LOOT_READY and not events.events.CHAT_MSG_LOOT)
slots = { {}, {} }
now = 30
Fire("LOOT_READY")
assert(#pickups == 2 and pickups[1] == 2 and pickups[2] == 1, "reverse pickup")
now = 31
external = true
Fire("LOOT_READY")
assert(#pickups == 2, "external FasterLoot owns pickup")
external = false
local modernAddonAPI = C_AddOns
C_AddOns = nil
IsAddOnLoaded = function() return true end
FluxLoot:Refresh()
assert(not events.events.LOOT_READY, "legacy external addon probe")
C_AddOns = modernAddonAPI
IsAddOnLoaded = nil
settings.fast = false
settings.alerts = true
callbacks.OnProfileCopied(FluxLoot)
assert(events.events.CHAT_MSG_LOOT, "copied profile refreshes alert events")
settings.alerts = false
callbacks.OnProfileReset(FluxLoot)
assert(not events.events.LOOT_READY, "all events stop when both features are disabled")
assert(callbacks.OnProfileChanged == FluxLoot.Refresh and callbacks.OnProfileReset == FluxLoot.Refresh)
print("loot cursor: event, duplicate, locale, quality, coin symbols/icons/white text, currency, toggle and fast pickup checks pass")
