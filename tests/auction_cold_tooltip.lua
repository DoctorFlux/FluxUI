-- Real Retail AlreadyKnown module; native tooltips/rows are mocked explicitly.
-- lua tests/auction_cold_tooltip.lua [baseline FluxAlreadyKnown.lua] [--measure]
local source = arg[1] or "Inventory/Restock/Vendor/FluxAlreadyKnown.lua"
local measure = arg[2] == "--measure"
local checks, failures = 0, 0
local function check(value, message)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. message) end
end
local function count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function boot(provider)
    local h = { frames = 0, timers = 0, requests = 0, continuations = 0,
        queries = 0, visits = 0, errors = 0, enabled = true, tooltip = nil }
    local env = setmetatable({}, { __index = _G }); env._G = env
    -- This paints the same UI with either provider present; it does not emulate
    -- Syndicator itself or establish the module's native Forever load scope.
    env.Syndicator = provider and { API = {} } or nil
    env.strmatch, env.gsub, env.format = string.match, string.gsub, string.format
    env.ITEM_PET_KNOWN, env.ITEM_SPELL_KNOWN = "Already known pet", "Already known"
    env.ITEM_MIN_LEVEL, env.ITEM_CLASSES_ALLOWED = "Level %d", "Classes: %s"
    env.HOUSING_DECOR_OWNED_COUNT_FORMAT = "Owned %d"
    env.SlashCmdList, env.StaticPopupDialogs = {}, {}
    env.NORMAL_FONT_COLOR = { WrapTextInColorCode = function(_, text) return text end }
    env.Enum = { ItemClass = { Miscellaneous = 15, Housing = 20 } }
    env.C_Item = {
        GetItemInfoInstant = function(link)
            return tonumber(link:match("item:(%d+)")), nil, nil, nil, 1, 7, 0
        end,
        RequestLoadItemDataByID = function() h.requests = h.requests + 1 end,
    }
    env.Item = { CreateFromItemID = function()
        return { ContinueOnItemLoad = function() h.continuations = h.continuations + 1 end }
    end }
    env.C_Timer = { After = function() h.timers = h.timers + 1 end,
        NewTimer = function() h.timers = h.timers + 1 end }
    env.C_TooltipInfo = { GetHyperlink = function()
        h.queries = h.queries + 1
        return h.tooltip
    end }
    env.hooksecurefunc = function() end
    env.CreateFrame = function()
        h.frames = h.frames + 1
        return { SetScript = function() end, RegisterEvent = function() end }
    end
    local settings = { r = .2, g = .8, b = .4, monochrome = true }
    local AK = { GetSettings = function() return settings end,
        ShouldRun = function() return h.enabled end, _knownTable = { ["item:100"] = true } }
    env.FluxAlreadyKnown = AK
    local function region()
        return { Show = function(self) self.shown = true end,
            SetVertexColor = function(self, r, g, b) self.color = { r, g, b } end,
            SetAlpha = function(self, value) self.alpha = value end,
            SetDesaturated = function(self, value) self.desaturated = value end }
    end
    h.row = { rowData = { itemKey = { itemID = 100 } }, SelectedHighlight = region(),
        cells = { [2] = { Icon = region(), IconBorder = region() } } }
    local view = { ForEachFrame = function(_, fn) h.visits = h.visits + 1; fn(h.row) end }
    h.view = view
    h.scroll = { GetView = function() return h.view end,
        ForEachFrame = function(_, fn) return h.view:ForEachFrame(fn) end }
    env.AuctionHouseFrame = { BrowseResultsFrame = { ItemList = { ScrollBox = h.scroll } } }
    assert(loadfile(source, "t", env))()
    function h.refresh()
        local ok = pcall(AK.RefreshAuctionHouse, h.scroll)
        if not ok then h.errors = h.errors + 1 end
        return ok
    end
    h.AK, h.settings, h.readyView, h.env = AK, settings, view, env
    return h
end

for _, provider in ipairs({ false, true }) do
    local label = provider and "provider-present" or "provider-absent"
    local h = boot(provider)
    h.view = nil
    check(h.refresh() and h.queries == 0 and h.visits == 0, label .. " initial missing view is idle")
    h.view = h.readyView
    check(h.refresh(), label .. " cached known row paints")
    local icon, border, highlight = h.row.cells[2].Icon, h.row.cells[2].IconBorder, h.row.SelectedHighlight
    check(icon.desaturated and icon.color[1] == .2 and icon.color[2] == .8
        and border.color[3] == .4 and highlight.alpha == .2, label .. " known appearance retained")
    check(h.queries == 0, label .. " positive cache avoids tooltip queries")
    h.row.rowData.itemKey.itemID = 101
    local frames, queries, errors = h.frames, h.queries, h.errors
    for _ = 1, 500 do h.refresh() end
    check(h.errors == errors, label .. " 500 legitimate missing tooltip replies are safe")
    check(h.queries - queries == 500, label .. " cold replies recheck on normal paint")
    check(h.AK._knownTable["item:101"] == nil, label .. " cold result is not cached negative")
    check(icon.color[1] == 1 and border.color[1] == 1 and not icon.desaturated,
        label .. " recycled cold row clears the previous tint")
    h.tooltip = {}
    check(h.refresh(), label .. " tooltip without lines is safe")
    check(h.AK._knownTable["item:101"] == nil, label .. " incomplete result stays uncached")
    h.tooltip = { lines = {} }
    check(h.refresh() and h.AK._knownTable["item:101"] == nil, label .. " ready unknown result stays uncached")
    h.tooltip = { lines = { { leftText = h.env.ITEM_SPELL_KNOWN } } }
    check(h.refresh() and h.AK._knownTable["item:101"] == true, label .. " late ready known result repaints immediately")
    check(icon.desaturated and icon.color[1] == .2 and border.color[2] == .8,
        label .. " late known tint and monochrome retained")
    queries = h.queries
    h.tooltip = nil
    check(h.refresh() and h.queries == queries, label .. " known cache remains valid during later metadata gaps")
    h.settings.monochrome = false
    check(h.refresh() and not icon.desaturated and icon.color[1] == .2,
        label .. " known tint also retains the default non-monochrome option")
    h.settings.monochrome = true
    h.row.rowData.itemKey.itemID = 102
    h.tooltip = { lines = { { leftText = "Uncollected recipe" } } }
    check(h.refresh() and not icon.desaturated and icon.color[1] == 1,
        label .. " ready uncollected row resets tint")
    check(h.AK._knownTable["item:102"] == nil, label .. " ready negative remains uncached")
    h.tooltip = { lines = { { leftText = h.env.ITEM_SPELL_KNOWN } } }
    check(h.refresh() and h.AK._knownTable["item:102"] == true, label .. " newly learned item is detected on next paint")
    h.enabled = false
    local visits = h.visits
    check(h.refresh() and h.visits == visits, label .. " disabled integration is idle")
    h.enabled, h.view = true, nil
    check(h.refresh() and h.visits == visits, label .. " released view is idle")
    h.view = h.readyView
    check(h.refresh() and h.visits == visits + 1, label .. " replacement view resumes")
    h.row.rowData = nil
    check(h.refresh(), label .. " released row is safe")
    check(h.frames == frames and h.timers == 0 and h.requests == 0 and h.continuations == 0,
        label .. " no additional frame, timer or native load request")
    check(count(h.AK._knownTable) == 3, label .. " only known items enter the cache")
    print(string.format("%s nilReplies=500 missingLinesReplies=1 errors=%d frames=%d timers=%d nativeRequests=%d continuations=%d knownRows=%d",
        label, h.errors - errors, h.frames, h.timers, h.requests, h.continuations, count(h.AK._knownTable)))
end
print(string.format("auction cold tooltip: %d checks, %d failures; desktop production replay only", checks, failures))
if not measure then assert(failures == 0, "auction cold tooltip regressions") end
