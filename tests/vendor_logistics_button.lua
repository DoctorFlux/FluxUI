-- Desktop exercise of the production merchant tooltip, button and update paths.
local path = arg[1] or "Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua"
local file = assert(io.open(path, "rb"))
local source = assert(file:read("*a"))
file:close()
local function section(first, last)
    local start = assert(source:find(first, 1, true), first)
    local finish = assert(source:find(last, start + #first, true), last)
    return source:sub(start, finish - 1)
end

local clicks, refreshes = 0, 0
local enabled, merchantShown, canBuy = false, true, false
local rows = {}
local subscribed
local regular = {GetRestockVendorItems = function() return rows end,
    GetMerchantItemIndex = function() return {} end,
    HasAnyRestockTargets = function() return false end,
    HasTemporaryVendorTargets = function() return #rows > 0 end,
    HasRestockNeeded = function() return false end,
    DoRestockManual = function() clicks = clicks + 1; return true end}
local tooltip = {entries = {}, headings = {}}
function tooltip:AddLine(line) self.headings[#self.headings + 1] = line end
function tooltip:AddDoubleLine(label, count) self.entries[label] = count end
local button = {IsEnabled = function() return enabled end, Icon = {}}
local policy = {
    CanBuyVendorRequirements = function() return canBuy end,
    Subscribe = function(_, callback) subscribed = callback end,
}
local env = setmetatable({
    Flux = {RestockPolicy = policy}, FV = regular, GameTooltip = tooltip,
    FluxItemClass = {GetName = function(id) return id == 3371 and "Empty Vial" end},
    MerchantFrame = {IsShown = function() return merchantShown end},
    uiState = {cachedRestockItems = {}, cachedRestockTooltipItems = {}, cachedRestockTotal = 0},
    toggles = {},
    GetTooltipIconTag = function() return "icon" end,
    PrepareRestockTooltip = function() tooltip.entries, tooltip.headings = {}, {} end,
    FinishRestockTooltip = function() end,
    AddRestockTooltipEntry = function(entry, opts) tooltip.entries[entry.itemID] = opts end,
    AddTooltipMoneyLine = function() end,
    RestockCursorHasDropItem = function() return false end,
    ShouldDeferRestockDataRefresh = function() return false end,
    RefreshCachedRestockCounts = function() end,
    RefreshRestockTooltipIfShowing = function() end,
    SetMerchantActionButtonEnabled = function(_, value) enabled = value end,
    CreateMerchantStyleButton = function() return button end,
    ApplyRestockButtonIcon = function() end, ApplyMerchantButtonLayer = function() end,
    BindMerchantActionButtonClick = function() end, SetupRestockDragDrop = function() end,
    SetupRestockTooltip = function() end, AttachAutoToggle = function() end,
    ScheduleMerchantUpdate = function(mode) assert(mode == "data"); refreshes = refreshes + 1 end,
}, {__index = _G})
env._G = env
local getButton, update, show, click = assert(load(table.concat({
    section("local function ShowRestockTooltip", "local function IsSellJunkTooltipShowing"),
    section("local function HandleRestockButtonClick", "local function SetupRestockDragDrop"),
    section("local function EnsureRestockButton", "local function JunkButtonHasSellableJunkCheap"),
    section("local function UpdateRestockButton", "function FluxVendorAutoMerchantUI.UpdateMerchantUI"),
    "return EnsureRestockButton, UpdateRestockButton, ShowRestockTooltip, HandleRestockButtonClick",
}, "\n"), "@" .. path, "t", env))()
local row = {itemID = 3371, target = 12, bagCount = 4, vendorSold = true, plannerVendorNeed = 7}
rows, canBuy = {row, {itemID = 3389, target = 0, bagCount = 3, vendorSold = true, plannerVendorNeed = 5}}, true
assert(getButton() == button)
update(false, "data")
assert(enabled, "queued crafting demand must enable the actual Restock button without a saved preset")
show(button)
assert(#tooltip.headings == 0 and tooltip.entries[3371].displayTarget == 19
    and tooltip.entries[3389].displayTarget == 8, "craft materials share the ordinary restock rows")
assert(click(button) and clicks == 1, "one click uses the ordinary merchant owner")
row.plannerVendorPending, row.plannerVendorNeed, canBuy = 5, nil, false
update(false, "data")
show(button)
assert(not enabled and tooltip.entries[3371].suffix:find("5 pending", 1, true), "the projected row shows its pending receipt")

rows = {}
assert(subscribed)
subscribed(1, "coverage")
assert(refreshes == 1)
update(false, "data")
show(button)
assert(not enabled and #tooltip.headings == 0, "carried confirmation removes the temporary overlay")
merchantShown = false
subscribed(2, "coverage")
assert(refreshes == 1, "a receipt cannot reopen a closed merchant")
merchantShown = true

rows = {{itemID = 4791, target = 5}}
regular.HasRestockNeeded = function() return true end
update(false, "data")
assert(enabled and click(button) and clicks == 2, "a regular target uses the same merchant button action")
print("Vendor Restock button, merged temporary rows and common click path passed")
