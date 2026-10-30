-- Desktop event model for cursor alerts and optional fast pickup.
local now, external, quality = 10, true, 2
local cursorX, cursorY = 600, 500
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
    function frame:ClearAllPoints() self.point = nil end
    function frame:SetPoint(_, _, _, x, y) self.point = { x = x, y = y } end
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
GetCursorPosition = function() return cursorX, cursorY end
GetNumLootItems = function() return #slots end
GetLootSlotLink = function(slot) return slots[slot] and slots[slot].link end
GetLootSlotInfo = function(slot) return nil, nil, slots[slot] and slots[slot].count end
GetLootSlotType = function(slot) return slots[slot] and slots[slot].type end
LOOT_SLOT_MONEY = 1
LootSlot = function(slot) pickups[#pickups + 1] = slot end
GetCVarBool = function() return false end
IsModifiedClick = function() return true end
C_AddOns = { IsAddOnLoaded = function() return external end }
wipe = function(value) for key in pairs(value) do value[key] = nil end end
LOOT_ITEM_SELF = "You receive loot: %s."
LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %s x%d."
LOOT_ITEM_CREATED_SELF = "You |4make:makes;: %s."
LOOT_ITEM_PUSHED_SELF = "You receive item: %s."
LOOT_ITEM_BONUS_ROLL_SELF = "Bonus loot: %s."
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
    GetInfo = function(item)
        local name = item:find("item:789:", 1, true) and "Fresh Ore" or "Copper Ore"
        for id = 1001, 1004 do
            if item:find("item:" .. id .. ":", 1, true) then name = "Late Ore " .. string.char(64 + id - 1000) end
        end
        return name,
            nil, quality, nil, nil, nil, nil, nil, nil, "ore-icon"
    end,
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
local function RowWithText(value)
    for _, frame in ipairs(frames) do
        if rawget(frame, "text") and frame.text.value == value then return frame end
    end
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
slots = { { link = link, count = 2 }, { link = link, count = 2 } }
Fire("LOOT_READY")
Fire("LOOT_SLOT_CLEARED", 1)
slots[1].link = nil
Fire("CHAT_MSG_LOOT", "You receive loot: " .. link .. " x2.")
assert(CountText("Copper Ore x2") == 1, "slot and chat must show once")
assert(anchor.visible, "alert visible")
local firstRow = RowWithText("Copper Ore x2")
assert(firstRow.point.x == 624 and firstRow.point.y == 480, "origin captured at loot start")
cursorX, cursorY = 900, 700
Fire("LOOT_OPENED")
now = 11
Fire("CHAT_MSG_LOOT", "You receive loot: " .. link .. " x2.")
assert(CountText("Copper Ore x2") == 2, "repeated same item must show")
Fire("LOOT_SLOT_CLEARED", 2)
assert(CountText("Copper Ore x2") == 2, "late slot clear does not duplicate chat")
assert(firstRow.point.x == 624 and firstRow.point.y == 451,
    "earlier row stacks at original cursor despite movement")
for _, frame in ipairs(frames) do
    if rawget(frame, "text") and frame.text.value == "Copper Ore x2" then
        assert(frame.point.x == 624, "every row in the loot batch uses its first cursor snapshot")
    end
end
cursorX, cursorY = 1000, 800
Fire("LOOT_CLOSED")
now = 11.2
slots = { { link = "|Hitem:789:0|h[Copper Ore]|h", count = 1 } }
Fire("LOOT_READY")
Fire("LOOT_SLOT_CLEARED", 1)
local nextRow = RowWithText("Fresh Ore")
assert(nextRow.point.x == 1024 and nextRow.point.y == 780, "new loot uses its own cursor snapshot")
assert(firstRow.point.x == 624, "new loot does not move earlier rows")
Fire("LOOT_CLOSED")
now = 14.3
anchor.scripts.OnUpdate(anchor)
assert(not anchor.visible, "default 3-second alerts expire")

quality = 1
settings.quality = 2
now = 16
Fire("CHAT_MSG_LOOT", "You receive loot: " .. link .. ".")
assert(CountText("Copper Ore") == 0, "ordinary bag gain outside loot window")
Fire("LOOT_READY")
Fire("CHAT_MSG_LOOT", "You receive loot: " .. link .. ".")
assert(CountText("Copper Ore") == 0, "quality threshold")
Fire("LOOT_CLOSED")
settings.quality = 0
now = 21
Fire("CHAT_MSG_LOOT", "You make: " .. link .. ".")
Fire("CHAT_MSG_LOOT", "You receive item: " .. link .. ".")
Fire("CHAT_MSG_LOOT", "You receive loot: " .. link .. ".")
assert(CountText("Copper Ore") == 0, "crafted, pushed and outside-window gains are excluded")
Fire("CHAT_MSG_LOOT", "Bonus loot: " .. link .. ".")
assert(CountText("Copper Ore") == 1, "bonus roll remains loot outside a window")
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
Fire("CHAT_MSG_CURRENCY", "You receive 2 badges.")
assert(CountText("You receive 2 badges.") == 0, "non-loot currency gain is excluded")
slots = { { link = "|Hcurrency:777|h[Badge]|h", count = 3 } }
Fire("LOOT_READY")
cursorX, cursorY = 1200, 900
Fire("CHAT_MSG_LOOT", "You make: " .. link .. ".")
Fire("CHAT_MSG_LOOT", "You receive item: " .. link .. ".")
assert(CountText("Copper Ore") == 1, "craft and pushed rewards stay excluded during loot")
Fire("LOOT_SLOT_CLEARED", 1)
assert(CountText("Copper Ore x3") == 0, "currency slot is not treated as an item")
Fire("CHAT_MSG_CURRENCY", "You receive 3 badges.")
assert(CountText("You receive 3 badges.") == 1)
assert(RowWithText("You receive 3 badges.").point.x == 1024,
    "late currency chat stays at loot-start cursor")
Fire("LOOT_CLOSED")
now = 21.5
Fire("CHAT_MSG_CURRENCY", "You receive 4 badges.")
assert(CountText("You receive 4 badges.") == 1, "late chat from just-closed loot window")
assert(RowWithText("You receive 4 badges.").point.x == 1024,
    "after-close currency stays at loot-start cursor")
now = 23
Fire("CHAT_MSG_CURRENCY", "You receive 5 badges.")
assert(CountText("You receive 5 badges.") == 0, "loot-window grace expires")
Fire("LOOT_ITEM_ROLL_WON", "|Hitem:456:0|h[Copper Ore]|h", 1)
assert(CountText("Copper Ore") == 2, "won roll remains loot without a window")

-- Two windows close before either delayed chat line. Link identity carries
-- each alert back to its own opening cursor rather than the latest cursor.
quality = 2
now, cursorX, cursorY = 40, 300, 400
local lateA = "|Hitem:1001:0|h[Late Ore A]|h"
slots = { { link = lateA, count = 1 } }
Fire("LOOT_READY"); Fire("LOOT_CLOSED")
now, cursorX, cursorY = 41, 900, 700
local lateB = "|Hitem:1002:0|h[Late Ore B]|h"
slots = { { link = lateB, count = 1 } }
Fire("LOOT_READY"); Fire("LOOT_CLOSED")
now, cursorX, cursorY = 45, 1500, 900
Fire("CHAT_MSG_LOOT", "You receive loot: " .. lateA .. ".")
assert(RowWithText("Late Ore A").point.x == 324, "lagged first loot keeps first source")
now = 46
Fire("CHAT_MSG_LOOT", "You receive loot: " .. lateB .. ".")
assert(RowWithText("Late Ore B").point.x == 924, "lagged second loot keeps second source")
Fire("CHAT_MSG_LOOT", "You receive loot: " .. lateA .. ".")
assert(CountText("Late Ore A") == 1, "extra chat line is not another pickup")

now, cursorX, cursorY = 50, 400, 500
local lateC = "|Hitem:1003:0|h[Late Ore C]|h"
slots = { { link = lateC, count = 1 } }
Fire("LOOT_READY"); Fire("LOOT_SLOT_CLEARED", 1); Fire("LOOT_CLOSED")
assert(CountText("Late Ore C") == 1)
now = 60
Fire("CHAT_MSG_LOOT", "You receive loot: " .. lateC .. ".")
assert(CountText("Late Ore C") == 1, "ten-second-late chat does not duplicate slot alert")

now, cursorX, cursorY = 70, 500, 600
local lateD = "|Hitem:1004:0|h[Late Ore D]|h"
slots = {}
Fire("LOOT_READY"); Fire("LOOT_CLOSED")
now, cursorX, cursorY = 72, 1400, 800
Fire("CHAT_MSG_LOOT", "You receive loot: " .. lateD .. ".")
assert(RowWithText("Late Ore D").point.x == 524, "uncaptured fast-loot fallback keeps source")

now, cursorX, cursorY = 80, 700, 800
slots = { { link = "|Hcurrency:777|h[Badge]|h", count = 3 } }
Fire("LOOT_READY"); Fire("LOOT_CLOSED")
now, cursorX, cursorY = 81, 1100, 700
slots = { { link = "|Hcurrency:888|h[Other Badge]|h", count = 1 } }
Fire("LOOT_READY"); Fire("LOOT_CLOSED")
now = 85
Fire("CHAT_MSG_CURRENCY", "You receive |Hcurrency:777|h[Badge]|h x3.")
assert(RowWithText("You receive |Hcurrency:777|h[Badge]|h x3.").point.x == 724,
    "delayed currency uses matching source")
now = 86
Fire("CHAT_MSG_CURRENCY", "You receive |Hcurrency:888|h[Other Badge]|h.")
assert(RowWithText("You receive |Hcurrency:888|h[Other Badge]|h.").point.x == 1124)

now, cursorX, cursorY = 90, 800, 300
slots = { { type = LOOT_SLOT_MONEY } }
Fire("LOOT_READY"); Fire("LOOT_CLOSED")
now, cursorX, cursorY = 91, 1000, 400
slots = { { link = lateB, count = 1 } }
Fire("LOOT_READY"); Fire("LOOT_CLOSED")
now = 95
local lateGold = "7" .. coinArt .. "GoldIcon:0:0:2:0|t"
Fire("CHAT_MSG_MONEY", "You loot 7 Golds.")
assert(RowWithText(lateGold).point.x == 824, "delayed money uses money-slot source")
now = 130
Fire("CHAT_MSG_LOOT", "You receive loot: " .. lateA .. ".")
Fire("CHAT_MSG_CURRENCY", "You receive |Hcurrency:777|h[Badge]|h x3.")
assert(CountText("Late Ore A") == 1, "expired loot source cannot claim later bag gains")
assert(CountText("You receive |Hcurrency:777|h[Badge]|h x3.") == 1,
    "expired currency source cannot claim later currency gains")

settings.alerts = false
callbacks.OnProfileChanged(FluxLoot)
assert(not events.events.CHAT_MSG_LOOT and not anchor.visible, "disabled alerts stop events and hide rows")
settings.fast = true
external = false
FluxLoot:Refresh()
assert(events.events.LOOT_READY and not events.events.CHAT_MSG_LOOT)
slots = { {}, {} }
now = 131
Fire("LOOT_READY")
assert(#pickups == 2 and pickups[1] == 2 and pickups[2] == 1, "reverse pickup")
now = 132
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
print("loot cursor: genuine loot filters, duplicate, quality, coin symbols/icons/white text, currency, toggles and fast pickup checks pass")
