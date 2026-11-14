-- Executes the complete active CharacterInfo owners, not historical Other copies.
local paths, baseline, verbose = {}, false, false
for _, value in ipairs(arg) do
    if value == "--baseline" then baseline = true
    elseif value == "--trace" then verbose = true
    else paths[#paths + 1] = value end
end
local gearPath = paths[1] or "CharacterInfo/GearScore.lua"
local qualityPath = paths[2] or "CharacterInfo/PaperDollQuality.lua"
local checks, failures, scores, traces = 0, 0, {}, {}
local unpack = table.unpack or unpack
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local function run(path, env, module)
    if setfenv then local f = assert(loadfile(path)); setfenv(f, env); f("FluxUI", { CharacterStats = module })
    else assert(loadfile(path, "t", env))("FluxUI", { CharacterStats = module }) end
end
local function upvalue(fn, wanted)
    for i = 1, 100 do
        local name, value = debug.getupvalue(fn, i)
        if not name then break end
        if name == wanted then return value, i end
    end
    error("missing production upvalue " .. wanted)
end
local function gearBoot(family, class)
    local s = { queries = 0, links = 0, requests = {}, items = {}, equipped = {}, family = family }
    local e = setmetatable({}, { __index = _G }); e._G = e
    e.WOW_PROJECT_ID = family == "wrath" and 11 or (family == "anniversary" and 5 or 2)
    e.WOW_PROJECT_WRATH_CLASSIC, e.WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 11, 5
    e.UnitClass = function() return class or "Warrior", class or "WARRIOR" end
    for slot = 1, 18 do
        local link = "item:" .. slot
        s.equipped[slot] = link
        s.items[link] = { quality = 4, level = 200,
            equip = slot == 16 and "INVTYPE_WEAPONMAINHAND" or (slot == 17 and "INVTYPE_WEAPONOFFHAND" or "INVTYPE_HEAD") }
    end
    e.GetInventoryItemLink = function(_, slot)
        s.links = s.links + 1
        if s.linkThrows then error("inventory link failure") end
        return s.equipped[slot]
    end
    e.GetItemInfo = function(link)
        s.queries = s.queries + 1
        if s.infoThrows then error("item metadata failure") end
        local item = s.items[link]
        if not item then s.requests[link] = (s.requests[link] or 0) + 1; return nil end
        return "Item", link, item.quality, item.level, 70, "Armor", "Plate", 1, item.equip, 123
    end
    s.module = { useClassicPaperDollChrome = family ~= "retail" and family ~= "forever" and family ~= "mists", isRetail = family == "retail" or family == "forever" }
    run(gearPath, e, s.module); s.env = e
    function s:score() return self.env.FluxCSC_GetPlayerGearScore() end
    return s
end

for _, family in ipairs({ "retail", "forever", "mists" }) do
    local s = gearBoot(family)
    check(s.env.FluxCSC_GetPlayerGearScore == nil and s.queries == 0, family .. " retains inactive Classic GearScore gate")
end
for _, family in ipairs({ "era", "anniversary", "wrath" }) do
    for _, class in ipairs({ "WARRIOR", "HUNTER", "DRUID" }) do
        local s = gearBoot(family, class)
        local full = s:score(); scores[#scores + 1] = family .. class .. "=" .. tostring(full)
        check(full == (class == "HUNTER" and 6186 or 5270), family .. class .. " complete equipment score")
        s.items["item:16"].equip, s.items["item:17"].equip = "INVTYPE_2HWEAPON", "INVTYPE_2HWEAPON"
        local titan = s:score(); scores[#scores + 1] = "titan=" .. tostring(titan)
        check(titan == (class == "HUNTER" and 6186 or 5271), family .. class .. " Titan Grip adjustment retained")
        s.equipped = { [1] = "one" }; s.items.one = { quality = 4, level = 200, equip = "INVTYPE_HEAD" }
        check(s:score() == 310, family .. class .. " exact single-slot formula")
        for quality = 0, 7 do
            s.items.one.quality = quality
            for _, level in ipairs({ 20, 99, 120, 137, 147, 167, 200 }) do
                s.items.one.level = level
                scores[#scores + 1] = tostring(s:score())
            end
        end
        s.equipped = {}; check(s:score() == nil, family .. class .. " empty inventory remains unavailable")
    end
    local s = gearBoot(family)
    s.items = {}
    check(s:score() == nil and next(s.requests) ~= nil, family .. " cold primary GetItemScore requests metadata")
    for slot = 1, 18 do
        if slot ~= 4 then check(s.requests["item:" .. slot] ~= nil, family .. " every equipped score slot requests its own cold metadata") end
    end
    local complete = {}
    for link in pairs(s.requests) do complete[link] = { quality = 4, level = 200, equip = "INVTYPE_HEAD" } end
    s.items = complete
    check(s:score() == 5270, family .. " late metadata becomes usable without a miss cache")
    s.equipped = { [13] = "shared", [14] = "shared" }
    s.items.shared = { quality = 4, level = 200, equip = "INVTYPE_FINGER" }
    check(s:score() == 348, family .. " identical item ID in two slots still contributes twice")
    s.equipped[14] = "upgraded"; s.items.upgraded = { quality = 4, level = 250, equip = "INVTYPE_FINGER" }
    check(s:score() > 348, family .. " newly equipped item takes effect immediately")
    s.infoThrows = true; check(not pcall(s.score, s), family .. " primary metadata errors still propagate")
    s.infoThrows = nil; check(s:score() > 348, family .. " metadata exception does not poison the next calculation")
    s.linkThrows = true; check(not pcall(s.score, s), family .. " link errors still propagate")
    s.linkThrows = nil
    local reads = s.queries
    s.env.TT_GS = { GetScore = function() return 1234.5 end, GetQuality = function() return .1, .2, .3 end }
    check(s:score() == 1234.5 and s.queries == reads, family .. " successful TacoTip avoids internal metadata reads")
    local r, g, b = s.env.FluxCSC_GetGearScoreQualityRGB(1234)
    check(r == .1 and g == .2 and b == .3, family .. " TacoTip quality provider retained")
    s.env.TT_GS.GetScore = function() error("TacoTip transient failure") end
    check(s:score() > 348, family .. " TacoTip failure still uses internal fallback")
    s.env.TT_GS.GetScore = function()
        s.equipped = { [1] = "one" }; s.items.one = { quality = 4, level = 200, equip = "INVTYPE_HEAD" }
        return nil
    end
    check(s:score() == 310, family .. " provider callback equipment changes remain visible to fallback")
    s.env.TT_GS.GetQuality = function() error("TacoTip color failure") end
    r, g, b = s.env.FluxCSC_GetGearScoreQualityRGB(300)
    check(type(r) == "number" and type(g) == "number" and type(b) == "number", family .. " failed external color still falls back")
    s.env.TT_GS = nil
    for _, value in ipairs({ 0, 1, 199, 200, 201, 399, 400, 401, 999, 1000, 1001, 2399, 5999, 99999 }) do
        r, g, b = s.env.FluxCSC_GetGearScoreQualityRGB(value)
        scores[#scores + 1] = family .. "rgb" .. value .. "=" .. r .. "," .. g .. "," .. b
        check(type(r) == "number" and type(g) == "number" and type(b) == "number", family .. " public palette tier remains available")
    end
    r, g, b = s.env.FluxCSC_GetGearScoreQualityRGB(0)
    check(r == .53 and g == .53 and b == .53, family .. " exact unavailable public palette")
    r, g, b = s.env.FluxCSC_GetGearScoreQualityRGB(1)
    check(math.abs(r - .55045) < 1e-9 and math.abs(g - .55045) < 1e-9 and math.abs(b - .55045) < 1e-9,
        family .. " exact low public palette")
    r, g, b = s.env.FluxCSC_GetGearScoreQualityRGB(99999)
    local expected = family == "wrath" and { .99994, .00047, 0 }
        or (family == "anniversary" and { .96394, .28247, 0 } or { .95194, .37647, 0 })
    check(math.abs(r - expected[1]) < 1e-9 and math.abs(g - expected[2]) < 1e-9 and b == expected[3],
        family .. " exact saturated public palette")
    local internal = upvalue(s.env.FluxCSC_GetPlayerGearScore, "ComputeGearScorePlayerInternal")
    local item = upvalue(internal, "GetItemScore")
    check(select("#", item(nil)) == 2 and select(1, item(nil)) == 0 and select(2, item(nil)) == nil,
        family .. " private nil item contract remains exactly score/equip-location")
    s.items.one = { quality = 4, level = 200, equip = "INVTYPE_HEAD" }
    check(select("#", item("one")) == 2 and select(1, item("one")) == 310 and select(2, item("one")) == "INVTYPE_HEAD",
        family .. " private success contract has exactly two consumed results")
    s.items.one = nil
    check(select("#", item("one")) == 2 and select(1, item("one")) == 0 and select(2, item("one")) == nil,
        family .. " private cold metadata contract remains exactly score/equip-location")
    s.infoThrows = true
    check(not pcall(item, "one"), family .. " private primary metadata error propagation retained")
end
do
    local s = gearBoot("era")
    local palette, index = upvalue(s.env.FluxCSC_GetGearScoreQualityRGB, "GetQuality")
    local paletteCalls = 0
    debug.setupvalue(s.env.FluxCSC_GetGearScoreQualityRGB, index, function(...)
        paletteCalls = paletteCalls + 1; return palette(...)
    end)
    for _ = 1, 1000 do s:score() end
    check(s.links == 18000, "GearScore retains every inventory identity read")
    if not baseline then check(s.queries == 19000, "GearScore discards only unused duplicate level metadata queries") end
    if not baseline then check(paletteCalls == 0, "GearScore discards only unused private palette calculations") end
    print(("SAMPLE gear calls=1000 metadata=%d inventoryLinks=%d discardedPaletteCalls=%d"):format(s.queries, s.links, paletteCalls))
end

local slotNames = { "Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist", "Hands", "Waist",
    "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1", "MainHand", "SecondaryHand", "Ranged", "Ammo" }
local function qualityBoot(family, late)
    local s = { queries = 0, texture = 0, color = 0, show = 0, hide = 0, trace = {}, hooks = {}, frames = {} }
    local e = setmetatable({}, { __index = _G }); e._G = e
    local function record(value) if s.trace then s.trace[#s.trace + 1] = value end end
    function s.button(slot, tag)
        local button = { slot = slot, hasItem = true, tag = tag or tostring(slot) }
        function button:GetID() return self.slot end
        button.IconBorder = {
            SetTexture = function(_, texture)
                s.texture = s.texture + 1; record("T" .. button.tag .. ":" .. texture)
                if s.sinkThrows then error("native texture sink failure") end
                if s.onPaint then local callback = s.onPaint; s.onPaint = nil; callback() end
            end,
            SetVertexColor = function(_, r, g, b) s.color = s.color + 1; record("C" .. button.tag .. ":" .. r .. "," .. g .. "," .. b) end,
            Show = function() s.show = s.show + 1; record("S" .. button.tag) end,
            Hide = function() s.hide = s.hide + 1; record("H" .. button.tag) end,
        }
        return button
    end
    e.PaperDollFrame = { visible = true, HookScript = function(_, event, fn) s.hooks[event] = fn end,
        IsVisible = function(self) return self.visible end }
    e.PaperDollItemsFrame = { EquipmentSlots = {}, WeaponSlots = {} }
    function s:populate()
        for slot, name in ipairs(slotNames) do
            local button = self.button(slot)
            e["Character" .. name .. "Slot"] = button
            table.insert(slot <= 16 and e.PaperDollItemsFrame.EquipmentSlots or e.PaperDollItemsFrame.WeaponSlots, button)
        end
    end
    if not late then s:populate() end
    e.CreateFrame = function()
        local f = { RegisterEvent = function() end, SetScript = function(_, _, fn) s.event = fn end }
        s.frames[#s.frames + 1] = f; return f
    end
    e.PaperDollItemSlotButton_Update = function() end
    e.hooksecurefunc = function(name, fn) check(name == "PaperDollItemSlotButton_Update", "quality retains the original native posthook"); s.nativeHook = fn end
    e.BAG_ITEM_QUALITY_COLORS = { [4] = { r = .5, g = .2, b = .8 } }
    e.GetInventoryItemQuality = function(_, slot) s.queries = s.queries + 1; record("Q" .. slot); return s.quality or 4 end
    e.GetInventoryItemTexture = function() if s.empty then return nil end; return 123 end
    e.GetInventoryItemLink = function(_, slot) return "item:" .. slot end
    e.GetInventoryItemID = function(_, slot) return slot end
    e.GetItemInfo = function() return "Item", "item:1", s.legacyQuality or 4 end
    s.module = { useClassicPaperDollChrome = family ~= "retail" and family ~= "forever" and family ~= "mists", isRetail = family == "retail" or family == "forever" }
    run(qualityPath, e, s.module); s.env = e
    function s:refresh() self.event(nil, "UNIT_INVENTORY_CHANGED", "player") end
    return s
end
for _, family in ipairs({ "retail", "forever", "mists" }) do
    local s = qualityBoot(family)
    check(not s.event and #s.frames == 0, family .. " retains inactive Classic quality gate")
end
for _, family in ipairs({ "era", "anniversary", "wrath" }) do
    local s = qualityBoot(family); s:refresh()
    check(s.queries == 40 and s.texture == 40 and s.color == 40 and s.show == 40, family .. " all arrays/global duplicates paint in original order")
    traces[#traces + 1] = table.concat(s.trace, ";")
    s.trace = {}; s.env.PaperDollFrame.visible = false; s:refresh()
    check(#s.trace == 0, family .. " existing hidden panel skip remains")
    s.env.PaperDollFrame.visible = true; s.hooks.OnShow()
    check(#s.trace == 160, family .. " existing immediate OnShow repaint retained")
    local calls = s.queries; s.event(nil, "UNIT_INVENTORY_CHANGED", "target")
    check(s.queries == calls, family .. " non-player inventory event remains ignored")
    s.trace = {}
    s.onPaint = function() s.env.CharacterAmmoSlot = s.button(20, "replacementAmmo") end
    s:refresh()
    check(table.concat(s.trace, ";"):find("TreplacementAmmo:", 1, true), family .. " global widget is resolved when visited after native callbacks")
    traces[#traces + 1] = table.concat(s.trace, ";")
    s.trace = {}; s.onPaint = function() s:refresh() end; s:refresh()
    check(s.queries == calls + 120, family .. " reentrant refresh keeps independent traversal state")
    traces[#traces + 1] = table.concat(s.trace, ";")
    s.sinkThrows = true; check(not pcall(s.refresh, s), family .. " native sink failure still propagates")
    s.sinkThrows = nil; s.trace = {}; s:refresh()
    check(#s.trace == 160, family .. " sink failure does not suppress later repair")
    local head = s.env.CharacterHeadSlot
    s.quality = 0; s.trace = {}; s.nativeHook(head)
    check(s.trace[#s.trace] == "H1", family .. " live quality downgrade hides border immediately")
    s.quality = 4; s.trace = {}; s.nativeHook(head)
    check(s.trace[#s.trace] == "S1", family .. " live quality restoration paints immediately")
    head.hasItem, s.empty = false, true
    s.trace = {}; s.nativeHook(head)
    check(s.trace[1] == "H1" and #s.trace == 1, family .. " empty native slot still hides border")
    head.hasItem = true; s.env.GetInventoryItemQuality = nil
    s.env.C_Item = { GetItemQualityByID = function() error("cold quality provider") end }
    s.trace = {}; s.nativeHook(head)
    check(s.trace[#s.trace] == "S1", family .. " protected quality provider failure retains legacy metadata fallback")
    s.legacyQuality = nil; s.env.GetItemInfo = function() return nil end
    s.trace = {}; s.nativeHook(head)
    check(s.trace[1] == "H1", family .. " missing metadata hides only border")
    s.env.GetItemInfo = function() return "Item", "item:1", 4 end
    s.trace = {}; s.nativeHook(head)
    check(s.trace[#s.trace] == "S1", family .. " late metadata repaints without permanent miss cache")
    local late = qualityBoot(family, true)
    check(not late.nativeHook and not late.hooks.OnShow, family .. " missing native slots defer installation")
    late:populate(); check(late.module.InstallQuality() == true and late.nativeHook and late.hooks.OnShow, family .. " late slots install through existing service")
end
do
    local s = qualityBoot("era"); s.trace = false
    collectgarbage("collect"); collectgarbage("stop"); local before = collectgarbage("count")
    for _ = 1, 10000 do s:refresh() end
    local heap = collectgarbage("count") - before; collectgarbage("restart")
    check(s.queries == 400000 and s.texture == 400000 and s.color == 400000 and s.show == 400000,
        "quality allocation change retains every native query and sink")
    if not baseline then check(heap < 32, "quality refresh avoids immutable name/helper allocation") end
    print(("SAMPLE quality refreshes=10000 queries=%d texture=%d color=%d show=%d heapKiB=%.3f"):format(s.queries, s.texture, s.color, s.show, heap))
end
local function digest(text)
    local hash = 0
    for i = 1, #text do hash = (hash * 131 + text:byte(i)) % 2147483647 end
    return hash
end
local scoreTrace, qualityTrace = table.concat(scores, ","), table.concat(traces, "|")
print(("TRACE scores=%d quality=%d scoreBytes=%d qualityBytes=%d"):format(digest(scoreTrace), digest(qualityTrace), #scoreTrace, #qualityTrace))
if verbose then print("RAW_SCORES " .. scoreTrace); print("RAW_QUALITY " .. qualityTrace) end
print(("passive character work: %d checks, %d failures"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
