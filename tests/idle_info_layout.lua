-- Compare the real horizontal merge/layout implementation with its retained
-- pre-optimization control. Native width metrics are mocked, not FPS timings.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local file = assert(io.open(root .. "StatusBars/FluxInfoFrame.lua", "r"))
local source = file:read("*a"); file:close()
local checks = 0
local function check(value, message)
    assert(value, "idle info layout: " .. message)
    checks = checks + 1
end
local function slice(value, first, last)
    local at = assert(value:find(first, 1, true), first)
    local stop = assert(value:find(last, at + #first, true), last)
    return value:sub(at, stop - 1)
end
local function replaceSection(value, first, last, replacement)
    local at = assert(value:find(first, 1, true), first)
    local stop = assert(value:find(last, at + #first, true), last)
    return value:sub(1, at - 1) .. replacement .. value:sub(stop)
end
local function replace(value, old, replacement)
    local at = assert(value:find(old, 1, true), old)
    return value:sub(1, at - 1) .. replacement .. value:sub(at + #old)
end
local oldMerge = [[
local function _ApplyMergeCascadeUntilFit(rl, mergeGroups, fontSize, availableW)
    local out = rl
    if _MeasureRL(out, fontSize) <= availableW then return out end
    for _, groupKeys in ipairs(mergeGroups) do
        if _MeasureRL(out, fontSize) <= availableW then break end
        local newRl, merged = _TryMergeGroup(out, groupKeys)
        if merged then out = newRl end
    end
    return out
end

]]
local oldPipeline = [[
    local function _RunHorizontalMergePipeline(texts, useFontStart)
        local rl = _BuildRenderList(texts)
        rl = _MergeIlvlAndGearScoreRenderList(rl)
        local useFont = useFontStart
        rl = _ApplyMergeCascadeUntilFit(rl, HORIZ_MERGE_GROUPS_PRIMARY, useFont, availableW)
        if _MeasureRL(rl, useFont) > availableW then
            rl = _ApplyCompactTextsToRenderList(rl, compactByKey)
        end
        while useFont > 7 and _MeasureRL(rl, useFont) > availableW do
            useFont = useFont - 1
        end
        if _MeasureRL(rl, useFont) > availableW then
            rl = _ApplyMergeCascadeUntilFit(rl, HORIZ_MERGE_GROUPS_EMERGENCY, useFont, availableW)
        end
        return rl, useFont
    end

    local rl, useFont = _RunHorizontalMergePipeline(textsShort, fontSize)
    rl = _ApplyHybridIlvlGsTextsToRenderList(rl, fullByKey, compactByKey)
    while useFont > 7 and _MeasureRL(rl, useFont) > availableW do
        useFont = useFont - 1
    end
    if _MeasureRL(rl, useFont) > availableW then
        rl = _ApplyMergeCascadeUntilFit(rl, HORIZ_MERGE_GROUPS_EMERGENCY, useFont, availableW)
    end
]]
local production = slice(source, "local HORIZ_MERGE_GROUPS_PRIMARY", "--- Worst-case horizontal cluster width")
local before = replaceSection(production, "local function _ApplyMergeCascadeUntilFit", "local function _ApplyMergeCascadeUntilRowCount", oldMerge)
before = replaceSection(before, "    local function _RunHorizontalMergePipeline", "    local prev = nil", oldPipeline)

local function run(code, keys, width, fontSize, revision, metrics)
    local count = { font = 0, text = 0, width = 0, bind = 0, getters = 0 }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local active, pool = {}, {}
    local frame = { id = "parent" }
    function frame:GetWidth() return width end
    local aliases = { itemLevel = "itemLevel", ilvl = "itemLevel", itemlvl = "itemLevel",
        gearScore = "gearScore", gearscore = "gearScore" }
    local function canonical(key) return aliases[key] end
    local function keyText(key)
        local key = canonical(key) or key
        if key == "itemLevel" then return "Item LvL: 211.4", "iLvL: 211.4" end
        if key == "gearScore" then return "GearScore: 5342", "G.S.: 5342" end
        if key == "spellPower" then
            local value = "|cff99ccff" .. (revision or "123") .. "|r"
            return "Spell: " .. value .. " / |cff20ff20800|r", "Spell: " .. value .. "/|cff20ff20800|r"
        end
        local label = ({ fps = "FPS", ping = "Ping", durability = "Durability",
            spellPower = "Spell", spellHit = "Spell Hit", weaponDamage = "Damage" })[key] or key
        return label .. ": |cff99ccff" .. (revision or "123") .. "|r"
    end
    for i, key in ipairs(keys) do
        local fs = { id = "stat" .. i, text = "", shown = true, anchors = {} }
        function fs:SetFont(path, size, flags)
            count.font = count.font + 1; self.font = { path, size, flags }
        end
        function fs:SetText(value) count.text = count.text + 1; self.text = value end
        function fs:GetStringWidth()
            count.width = count.width + 1
            local plain = self.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            local weight = 0
            for character in plain:gmatch(".") do
                weight = weight + (character == " " and 0.2 or character == "|" and 0.1 or (metrics or 0.5))
            end
            return weight * self.font[2]
        end
        function fs:SetSpacing(value) self.spacing = value end
        function fs:Show() self.shown = true end
        function fs:Hide() self.shown = false end
        function fs:GetParent() return frame end
        function fs:ClearAllPoints() self.anchors = {} end
        function fs:SetPoint(point, relative, relativePoint, x, y)
            self.anchors[#self.anchors + 1] = { point, relative.id, relativePoint, x, y }
        end
        local full, compact = keyText(key)
        active[i] = { key = key, fs = fs, fullText = full, compactText = compact or full }
        pool[i] = fs
    end
    env.frame, env.activeLines, env.activeLineCount, env.linePool = frame, active, #active, pool
    env.INFO_FRAME_GROUP_GAP = 8
    env._CanonicalIlvlGsRegistryKey = canonical
    env._GetLineFullText = function(line) return line.fullText end
    env._GetLineCompactText = function(line) return line.compactText end
    env.STAT_REGISTRY = {}
    for _, key in ipairs({ "itemLevel", "gearScore" }) do
        env.STAT_REGISTRY[key] = { getText = function()
            count.getters = count.getters + 1
            return keyText(key)
        end }
    end
    env._BindInfoFrameEntryTooltip = function(fs, entry, path, size)
        count.bind = count.bind + 1
        local keys = {}
        for i, key in ipairs(entry.keys) do keys[i] = key end
        fs.tooltip = { key = entry.key, text = entry.text, keys = keys, path = path, size = size }
    end
    env._ClearInfoFrameEntryTooltip = function(fs) fs.tooltip = nil end
    local apply = assert(load(code .. "\nreturn ApplyHorizontalStripTextLayoutDynamic", "@production-info-layout", "t", env))()
    apply(fontSize, 6, 8)
    local snapshot = {}
    for i, fs in ipairs(pool) do
        snapshot[i] = { shown = fs.shown }
        if fs.shown then
            snapshot[i].text, snapshot[i].font = fs.text, fs.font
            snapshot[i].anchors, snapshot[i].tooltip, snapshot[i].spacing = fs.anchors, fs.tooltip, fs.spacing
        end
    end
    return snapshot, count
end
local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do if not equal(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
local cases = {
    {}, { "fps", "ping", "spellPower" },
    { "durability", "fps", "ping", "itemLevel", "gearScore", "crit", "haste", "spellHit", "spellPower", "armor", "weaponDamage" },
    { "crit", "meleeCrit", "rangedCrit", "spellCrit", "meleeHit", "spellHit", "rangedHit", "haste", "spellPower" },
    { "ilvl", "gearscore", "fps", "ping", "spellPower" },
    { "meleeCrit", "spellCrit" },
}
local widths = { 40, 80, 140, 220, 400, 900, 2000, 145, 146, 147, 151, 152, 153, 167, 168, 169, 229, 230, 231, 232 }
local function compare(code)
    for _, keys in ipairs(cases) do
        for _, width in ipairs(widths) do
            for _, font in ipairs({ 9.5, 10 }) do
                for _, revision in ipairs({ "123", "999999", "42.52%" }) do
                    for _, metrics in ipairs({ 0.5, 0.8 }) do
                        local expected, old = run(before, keys, width, font, revision, metrics)
                        local actual, new = run(code, keys, width, font, revision, metrics)
                        check(equal(expected, actual), "visible text, font, merge keys, anchors and tooltip descriptors remain identical ("
                            .. table.concat(keys, ",") .. "; width " .. width .. "; font " .. font .. "; text " .. revision .. "; metrics " .. metrics .. ")")
                        check(old.getters == new.getters, "native stat getters retain their cadence")
                        check(new.width <= old.width and new.text <= old.text and new.font <= old.font,
                            "measurement threading never adds native calls")
                    end
                end
            end
        end
    end
end

compare(production)
local keys = { "fps", "ping", "spellPower" }
local _, old = run(before, keys, 2000, 10)
local _, new = run(production, keys, 2000, 10)
print(string.format("idle info layout: width/font/text native calls per fitting3-stat layout = %d/%d/%d -> %d/%d/%d",
    old.width, old.font, old.text, new.width, new.font, new.text))
if arg[1] ~= "--baseline" then
    check(old.width == 18 and old.font == 21 and old.text == 21, "retained production control reproduces baseline")
    check(new.width == 6 and new.font == 9 and new.text == 9, "candidate measures each changed list once")
    local mutations = {
        { "stale merge width", function(value)
            return replace(value, '            width = _MeasureRL(out, fontSize)', '            width = width')
        end },
        { "stale font width", function(value)
            return replace(value, '            useFont = useFont - 1\n            width = _MeasureRL(rl, useFont)',
                '            useFont = useFont - 1')
        end },
        { "stale hybrid width", function(value)
            return replace(value, '    local width = _MeasureRL(rl, useFont)', '    local width = 0')
        end },
        { "removed emergency merge", function(value)
            local line = 'rl = _ApplyMergeCascadeUntilFit(rl, HORIZ_MERGE_GROUPS_EMERGENCY, useFont, availableW, width)'
            value = replace(value, line, 'rl = rl')
            return replace(value, line, 'rl = rl')
        end },
    }
    for _, mutation in ipairs(mutations) do
        local ok, err = pcall(compare, mutation[2](production))
        check(not ok and tostring(err):find('visible text, font, merge keys, anchors and tooltip descriptors remain identical', 1, true),
            mutation[1] .. " mutation must fail visible layout equality: " .. tostring(err))
    end
    local _, redundant = run(before, keys, 2000, 10)
    local ok, err = pcall(function()
        assert(redundant.width == 6 and redundant.font == 9 and redundant.text == 9,
            "candidate measures each changed list once")
    end)
    check(not ok and tostring(err):find("candidate measures each changed list once", 1, true),
        "old repeated measurements fail the native-call budget")
    print("idle info layout: " .. (#mutations + 1) .. " behavioral mutations rejected")
end
print("idle info layout: " .. checks .. " comparisons passed")
