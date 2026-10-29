-- Real merchant events, inventory facade, junk rules and UI availability callbacks.
-- Native rendering/other vendor integrations are outside this desktop fixture.
local source, measure = "Inventory/Restock/Junk/FluxJunk.lua", false
for i, value in ipairs(arg or {}) do
    if value == "--source" then source = assert(arg[i + 1]) end
    if value == "--measure" then measure = true end
end
local checks, failures = 0, 0
local function check(value, label)
    checks = checks + 1
    if not value then failures = failures + 1; print("FAIL " .. label) end
end
local function read(path)
    local f = assert(io.open(path, "rb")); local text = f:read("*a"); f:close()
    return text:gsub("\r\n", "\n")
end
-- Reuse the existing merchant fixture without running its independent scenarios.
local smoke = read("Inventory/Restock/Junk/_tmp_junksmoke.lua")
local ending = assert(smoke:find('for _, family in ipairs({ "live", "forever", "era", "anniversary", "mists" }) do', 1, true))
local bootSource = smoke:sub(1, ending - 1):gsub('Load%("Inventory/Restock/Junk/FluxJunk.lua", env, ns%)',
    'Load("' .. source .. '", env, ns)')
local fixtureEnv = setmetatable({ arg = { [0] = "Inventory/Restock/Junk/_tmp_junksmoke.lua" } }, { __index = _G })
local Boot = assert(load(bootSource .. "\nreturn Boot", "@merchant-fixture", "t", fixtureEnv))()
local uiSource = read("Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua")
local function section(first, last)
    local start = assert(uiSource:find(first, 1, true), first)
    local finish = assert(uiSource:find(last, start + #first, true), last)
    return uiSource:sub(start, finish - 1)
end

local function boot(family)
    local t = Boot(family)
    local env, inv, fj = t.env, t.inv, t.fj
    local h = { reads = 0, idReads = 0, generation = 1,
        frames = {}, enabled = false, native = 0, nativeReads = 0, builds = 0, ready = true }
    for bag, slots in pairs(t.bags) do
        for slot = 1, 20 do t.add(slot, 300000 + bag * 100 + slot, { quality = 1 }, bag) end
    end
    inv.GetBagSnapshotGeneration = function() return h.generation end
    inv.IsReliable = function() return h.ready end
    inv.GetContainerNumSlots = function() return 20 end
    local info, id = inv.GetContainerItemInfo, inv.GetContainerItemID
    inv.GetContainerItemInfo = function(...) h.reads = h.reads + 1; return info(...) end
    inv.GetContainerItemID = function(...) h.idReads = h.idReads + 1; return id(...) end
    local frame = env.MerchantFrame
    frame.selectedTab = 1
    env.GetMerchantNumItems = function() return 0 end
    env.FluxVendorAuto.EnsureSettings = function() return t.settings end
    env.FluxVendorAuto.GetRestockTargetItems = function() return {} end
    env.CreateFrame = function()
        local f = { events = {} }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        function f:SetScript(_, fn) self.onEvent = fn end
        h.frames[#h.frames + 1] = f
        return f
    end
    local native = family == "live" or family == "forever"
    env.C_MerchantFrame = native and { GetNumJunkItems = function()
        h.nativeReads = h.nativeReads + 1; return h.native
    end } or nil
    local button = { SetScript = function() end, Icon = { SetDesaturated = function() end } }
    function button:SetEnabled(enabled) h.enabled = not not enabled end
    env.MerchantSellAllJunkButton = native and button or nil
    local uiState = { classicJunkButton = button, cachedJunkSlotCount = 0, junkStatsDirty = true }
    env.uiState, env.FV = uiState, env.FluxVendorAuto
    env.HasNativeSellJunkButton = function() return native end
    env.IsMerchantBuyTabActive = function() return h.open and frame.selectedTab == 1 end
    env.EnsureClassicJunkButton = function() return button end
    env.SetMerchantActionButtonEnabled = function(_, enabled) button:SetEnabled(enabled) end
    env.UpdateSellJunkAutoToggle = function() end
    env.GetRepairClusterVisible = function() return false end
    env.EnsurePostDFSellJunkButtonVisible = function() end
    env.VendorAutomationEnabled = function()
        return t.settings.autoSellGray or t.settings.autoRepair or t.settings.autoRestock
    end
    env.FlushPendingRestockDataRefresh = function() end
    env.FluxVendorSession = { IsOpen = function() return h.open end }
    env.FluxVendorAutoMerchantUI = {}
    -- Bind the local callback used by the original two button-state functions.
    env.FluxHasSellableJunkForButton = assert(load(section("local function FluxHasSellableJunkForButton()",
        "function FluxVendorAutoMerchantUI.MarkVendorBagPulseDone()") ..
        "\nreturn FluxHasSellableJunkForButton", "@merchant-ui-availability", "t", env))()
    assert(load(section("function RefreshCheapJunkSlotCount()", "function FluxVendorAutoMerchantUI.GetCachedSellJunkTotal()"),
        "@merchant-ui-count", "t", env))()
    assert(load(section("function ApplyNativeSellJunkButtonState()", "FluxVendorAutoMerchantUI.RefreshCheapJunkSlotCount ="),
        "@merchant-ui-native-state", "t", env))()
    assert(load(section("function FluxVendorAutoMerchantUI.ApplyClassicSellJunkButtonState()", "local function UpdateSellJunkButton("),
        "@merchant-ui-classic-state", "t", env))()
    assert(load(section("function FluxVendorAutoMerchantUI.OnVendorOpenStormSettled()", "function FluxVendorAutoMerchantUI.RunPipelineLayout("),
        "@merchant-ui-settle", "t", env))()
    local ui = env.FluxVendorAutoMerchantUI
    function h:paint()
        if native then env.ApplyNativeSellJunkButtonState() else ui.ApplyClassicSellJunkButtonState() end
    end
    ui.RunPipelineLayout = function() h:paint() end -- rendering excluded; availability callback retained
    ui.ScheduleMerchantUpdate = function() h:paint() end
    ui.OnMerchantClosed = function()
        uiState.cachedJunkSlotCount = 0; uiState.junkStatsDirty = true; h.open = false
    end
    ui.MarkJunkStatsDirty = function() uiState.junkStatsDirty = true end
    ui.ScheduleJunkUIRefresh = function() end
    fj.RegisterListChanged(ui.MarkJunkStatsDirty)
    env.FluxRestockList = { RecordMerchantPrices = function() h.builds = h.builds + 1 end }
    assert(loadfile("Inventory/Restock/Vendor/FluxVendorBuy.lua", "t", env))("_FluxUI", {})
    function h:event(event, ...)
        if event == "MERCHANT_SHOW" then self.open = true end
        for _, f in ipairs(self.frames) do if f.events[event] then f.onEvent(f, event, ...) end end
    end
    function h:openClose()
        self:event("MERCHANT_SHOW"); t.advance(0.7)
        self:event("MERCHANT_CLOSED"); t.advance(0.1)
    end
    function h:refresh() env.RefreshCheapJunkSlotCount(); self:paint() end
    h.t, h.fj, h.inv, h.ui, h.state = t, fj, inv, ui, uiState
    return h
end

for _, family in ipairs({ "era", "anniversary", "wrath", "cata", "mists", "live", "forever" }) do
    local h = boot(family)
    h:openClose()
    local cold = h.reads
    local before, frames = h.reads, #h.frames
    for _ = 1, 25 do h:openClose(); check(not h.enabled, family .. " unchanged non-junk bags keep button disabled") end
    print(("METRIC %s cold_reads=%d repeat_reads=%d frames=%d native_reads=%d")
        :format(family, cold, h.reads - before, #h.frames, h.nativeReads))
    check(h.reads == before, family .. " repeated idle opens reuse unchanged availability")
    check(#h.frames == frames, family .. " repeated opens reuse event frames")
    -- Cold item data must not erase native-gray availability on legacy clients.
    h.t.add(20, 3300, { quality = 0, classID = 15 }, 0); h.t.hidden[3300] = true
    h.generation = 2; h.fj.OnBagSnapshotDiff({ changeKind = "identityChanged" })
    h:event("MERCHANT_SHOW"); h.t.advance(0.7)
    check(h.enabled, family .. " uncached gray remains available immediately")
    h.t.settings.junkList[3300] = false; h.fj.FireListChanged(3300); h:paint()
    check(not h.enabled, family .. " Useful invalidation updates availability")
    h.t.settings.junkList[3300] = nil; h.fj.FireListChanged(3300); h:paint()
    check(h.enabled, family .. " clearing Useful restores gray availability")
    h.t.bags[0][20] = nil; h.generation = 3; h.fj.OnBagSnapshotDiff({ changeKind = "identityChanged" }); h:refresh()
    check(not h.enabled, family .. " bag identity invalidation clears removed gray")
    h.t.add(20, 3300, { quality = 1 }, 0); h.generation = 4; h.fj.OnBagSnapshotDiff({ changeKind = "identityChanged" })
    check(not h.fj.AnyBlizzardVendorJunkInBags(), family .. " normal quality cached negative")
    h.t.facts[3300].quality = 0; h.fj.OnItemDataLoaded(3300)
    check(h.fj.AnyBlizzardVendorJunkInBags(), family .. " item-data invalidation replaces cached negative")
    h.t.facts[3300].quality = 1; h.fj.InvalidateItemRules(3300)
    check(not h.fj.AnyBlizzardVendorJunkInBags(), family .. " per-item rules invalidate positive availability")
    h.t.facts[3300].quality = 0; h.fj.InvalidateRules()
    check(h.fj.AnyBlizzardVendorJunkInBags(), family .. " global rules invalidate negative availability")
    if family == "live" or family == "forever" then
        h.t.facts[3300].quality = 1; h.fj.OnItemDataLoaded(3300)
        check(not h.fj.AnyBlizzardVendorJunkInBags(), family .. " native zero allows negative cache")
        h.native = 1
        check(h.fj.AnyBlizzardVendorJunkInBags(), family .. " fresh native positive overrides cached negative")
        h.native = 0; h.t.facts[3300].quality = 0
        check(h.fj.AnyBlizzardVendorJunkInBags(), family .. " native transition allows fresh fallback")
    end
    -- Without a ready generation, keep retrying rather than caching unavailable data.
    h.generation = nil; h.fj.InvalidateJunkSlotCount()
    local reads = h.reads
    h.fj.AnyBlizzardVendorJunkInBags(); h.fj.AnyBlizzardVendorJunkInBags()
    check(h.reads > reads, family .. " unready generation retains live fallback")
    h.generation = 5; h.ready = false; reads = h.reads
    h.fj.AnyBlizzardVendorJunkInBags(); h.fj.AnyBlizzardVendorJunkInBags()
    check(h.reads > reads, family .. " unreliable snapshot retains live fallback")
end
print(("Vendor-open work: %d checks, %d failures"):format(checks, failures))
if failures > 0 and not measure then os.exit(1) end
