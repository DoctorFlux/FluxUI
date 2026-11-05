-- Loads the real AlreadyKnown modules; native row pools and tooltip APIs mocked.
-- Optional argument: directory containing the two baseline source files.
local sourceDir = arg[1] or "Inventory/Restock/Vendor"
local checks, failures, enumerated, classified = 0, 0, 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
for _, family in ipairs({"retail", "forever", "era", "anniversary", "mists"}) do
 for _, provider in ipairs({"builtin", "syndicator"}) do
    local env = setmetatable({}, {__index = _G}); env._G = env
    local state = {frames = {}, reads = 0, children = 0, active = 0, enabled = true}
    local db = {r = 0, g = 1, b = 0, monochrome = true}
    local AK = {GetSettings = function() return db end,
        ShouldRun = function() return state.enabled end,
        _knownTable = { ["item:100"] = true }}
    env.FluxAlreadyKnown = AK
    env.FluxInventoryProvider = provider -- UI must not depend on provider identity.
    env.strmatch, env.gsub, env.format = string.match, string.gsub, string.format
    env.ITEM_PET_KNOWN, env.ITEM_MIN_LEVEL, env.ITEM_CLASSES_ALLOWED = "Already known", "Level %d", "Classes: %s"
    env.HOUSING_DECOR_OWNED_COUNT_FORMAT = "Owned %d"
    env.SlashCmdList, env.StaticPopupDialogs = {}, {}
    env.NORMAL_FONT_COLOR = {WrapTextInColorCode = function(_, s) return s end}
    env.Enum = {ItemClass = {Miscellaneous = 15, Housing = 20}}
    env.C_Item = {GetItemInfoInstant = function(link)
        state.reads = state.reads + 1
        return tonumber(link:match("item:(%d+)")), nil, nil, nil, 1, 7, 0
    end}
    env.C_TooltipInfo = {GetHyperlink = function() return {lines = {}} end}
    env.hooksecurefunc = function() end
    env.CreateFrame = function()
        local frame = {}
        function frame:SetScript() end
        function frame:RegisterEvent() end
        function frame:SetOwner() end
        function frame:SetHyperlink() end
        function frame:ClearLines() end
        function frame:NumLines() return 0 end
        state.frames[#state.frames + 1] = frame
        return frame
    end
    local function region()
        return {SetVertexColor = function(self, r, g, b) self.color = {r, g, b} end,
            SetDesaturated = function(self, v) self.desaturated = v end,
            Show = function(self) self.shown = true end,
            SetAlpha = function(self, v) self.alpha = v end}
    end
    local function row(id)
        return {rowData = id and {itemKey = {itemID = id}}, SelectedHighlight = region(),
            cells = {[2] = {Icon = region(), IconBorder = region()}}}
    end
    local active = {row(100), row(101), row(nil)}
    local children = {active[1], active[2], active[3]}
    -- Released rows retain cells but TableBuilder clears rowData. A prior large
    -- result set can leave a much larger child pool than the active view.
    for i = 1, 1000 do children[#children + 1] = row(nil) end
    local scroll = {ScrollTarget = {GetChildren = function()
        state.children = state.children + #children
        return table.unpack(children)
    end}, GetView = function() return state.view end, ForEachFrame = function(self, fn)
        return self:GetView():ForEachFrame(fn)
    end}
    state.view = {ForEachFrame = function(_, fn)
        for _, button in ipairs(active) do state.active = state.active + 1; fn(button) end
    end}
    env.AuctionHouseFrame = {BrowseResultsFrame = {ItemList = {ScrollBox = scroll}}}
    local filename = family == "retail" and "FluxAlreadyKnown.lua" or "FluxAlreadyKnownClassic.lua"
    assert(loadfile(sourceDir .. "/" .. filename, "t", env))()
    local function refresh()
        if family == "retail" then AK.RefreshAuctionHouse(scroll) else AK.RefreshAuctionHouse() end
    end
    local readyView = state.view
    state.view = nil
    local ok = pcall(refresh)
    check(ok, family .. "/" .. provider .. " pre-view Update is safe")
    check(state.active == 0 and state.reads == 0, "pre-view Update does no work")
    state.view = readyView
    -- 20 matched list updates model the UI refresh burst, not native Buy timing.
    for i = 1, 20 do refresh() end
    check(state.children == 0, family .. "/" .. provider .. " does not enumerate pooled children")
    check(state.active == 60, family .. "/" .. provider .. " visits only active rows")
    check(state.reads == 20, "unknown active items still recheck on every refresh")
    check(active[1].cells[2].Icon.color[2] == 1 and active[1].cells[2].Icon.color[1] == 0, "known tint")
    check(active[1].cells[2].Icon.desaturated == true, "known monochrome")
    check(active[1].SelectedHighlight.alpha == .2, "known highlight alpha")
    check(active[2].cells[2].Icon.color[1] == 1 and not active[2].cells[2].Icon.desaturated, "unknown reset")
    enumerated = enumerated + state.children + state.active
    classified = classified + state.reads
    -- Reused row must lose old tint; no persistent negative cache is introduced.
    active[1].rowData.itemKey.itemID = 102
    refresh()
    check(active[1].cells[2].Icon.color[1] == 1 and not active[1].cells[2].Icon.desaturated, "recycled row reset")
    AK._knownTable["item:102"] = true
    refresh()
    check(active[1].cells[2].Icon.desaturated, "newly learned item repaints immediately")
    local before = state.children + state.active
    state.enabled = false
    refresh()
    check(before == state.children + state.active, "disabled integration stops work")
    state.enabled = true
    state.view = nil
    check(pcall(refresh), "released-view Update is safe")
    state.view = readyView
    local visits = state.active
    refresh()
    check(state.active == visits + #active, "replacement view resumes normal painting")
    if family ~= "retail" then
        -- Era's loaded legacy UI has no modern ScrollBox. Keep that fixed-size
        -- branch usable when no AuctionHouseFrame or ForEachFrame exists.
        env.AuctionHouseFrame = nil
        env.BrowseScrollFrame, env.NUM_BROWSE_TO_DISPLAY = {}, 2
        env.FauxScrollFrame_GetOffset = function() return 0 end
        env.GetAuctionItemLink = function(_, i) return "item:" .. (99 + i) end
        for i = 1, 2 do env["BrowseButton" .. i .. "Item"] = {}; env["BrowseButton" .. i .. "ItemIconTexture"] = region() end
        state.enabled = true
        AK.RefreshAuctionHouse()
        check(env.BrowseButton1ItemIconTexture.desaturated, "legacy known tint retained")
        check(not env.BrowseButton2ItemIconTexture.desaturated, "legacy unknown tint retained")
    end
 end
end
print(string.format("auction active rows: %d checks, %d failures; burst visits=%d, classifications=%d", checks, failures, enumerated, classified))
if failures > 0 then os.exit(1) end
