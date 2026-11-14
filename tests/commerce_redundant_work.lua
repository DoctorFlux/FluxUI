-- Real auction rows, receipts, potion tiers and retained native presentation.
-- Desktop getter/write counts are not native latency, rendering or FPS evidence.
local checks, profiles = 0, 0
local measure = os.getenv("FLUX_COMMERCE_MEASURE_ONLY") == "1"
local function check(value, label) checks = checks + 1; assert(value, label) end
local override = os.getenv("FLUX_COMMERCE_SOURCE")
if override then
    local original = loadfile
    loadfile = function(path, ...)
        local rel = path:gsub("\\", "/"):gsub("^%./", "")
        if rel == "Inventory/Restock/Auction/FluxAuctionRestockData.lua"
            or rel == "Inventory/Restock/Auction/FluxAuctionRestockPotions.lua"
            or rel == "Inventory/Restock/Auction/FluxAuctionRestockUI.lua" then path = override .. "/" .. rel end
        return original(path, ...)
    end
end
local function Export(path, flag)
    return assert(loadfile(path, "t", setmetatable({ [flag] = true }, { __index = _G })))()
end
local Fixture = Export("tests/auction_restock.lua", "FLUX_AH_FIXTURE_EXPORT")
local Potions = Export("tests/auction_restock_potions.lua", "FLUX_AH_POTIONS_FIXTURE_EXPORT")
local traces = {}
local function Trace(A, label)
    local values = { label, A.state or "", A.status or "" }
    for _, row in ipairs(A.rows) do
        values[#values + 1] = table.concat({ row.itemID, row.need or "nil", row.bagCount or 0,
            row.pending or 0, row.mailCount or 0, row.auctionTier or 0, row.unitsPerItem or "nil" }, ":")
    end
    traces[#traces + 1] = table.concat(values, ";")
end
for _, family in ipairs({ "retail", "forever", "mists", "era", "anniversary" }) do
 for _, provider in ipairs({ false, true }) do
    profiles = profiles + 1
    local legacy = family == "era" or family == "anniversary"
    local label = family .. "/" .. tostring(provider)
    local A, st, env = Potions(legacy, false, provider)
    env.FluxConsumableBest.Persist.MaybeUpdateRef("healPotion", { itemID = 201, effective = 600, source = "auction" })
    local counts, need, bag, mail = { need = 0, bag = 0, mail = 0 }, A.Need,
        env.FluxRestock.Inv.GetLiveCount, st.inventory.Mail.GetCount
    A.Need = function(...) counts.need = counts.need + 1; return need(...) end
    env.FluxRestock.Inv.GetLiveCount = function(...) counts.bag = counts.bag + 1; return bag(...) end
    st.inventory.Mail.GetCount = function(...) counts.mail = counts.mail + 1; return mail(...) end
    for _ = 1, 50 do
        local rows = A.GetRows(true)
        check(#rows == 2 and A.FindRow(201).need == 20 and A.FindRow(101).need == 1,
            "final potion targets retain all qualifying tier and live stock math")
    end
    print(("COMMERCE_WORK %s potion50 need=%d,bag=%d,mail=%d"):format(label, counts.need, counts.bag, counts.mail))
    if not measure then check(counts.need == 100 and counts.mail == 100,
        "compute each final potion deficit once after replacement and merge") end
    Trace(A, label .. "/potion50")
    local row = { itemID = 201, target = 23, unitsPerItem = 1, name = "Potion" }
    local before = counts.need
    local standalone = A.ApplyPotionReplacements({ row })
    check(standalone[1].need == 23 and standalone[1].auctionTier == 600 and counts.need == before + 1,
        "standalone replacement callers retain their populated need contract")
    local merged = A.ApplyPotionReplacements({ { itemID = 201, target = 23, unitsPerItem = 1 },
        { itemID = 201, target = 25, unitsPerItem = 1 } })
    check(#merged == 1 and merged[1].target == 25 and merged[1].need == 25,
        "standalone duplicate SKU merges keep the largest requested target and complete need")
    st.bags[201], st.mail[201] = 2, 3
    st.entries[#st.entries + 1] = { itemID = 201, name = "Direct potion", target = 25 }
    A.GetRows(true)
    check(A.FindRow(201).need == 20 and #A.rows == 2, "manual and tier sources merge before one final live deficit")
    row = A.FindRow(201)
    A.Reserve(row, 2); A.AcceptReservation({ itemID = 201 })
    A.GetRows(true)
    check(A.FindRow(201).pending == 5 and A.FindRow(201).need == 18,
        "acknowledged reservations join the final shared row exactly once")
    st.mail[201] = 5; A.GetRows(true)
    check(not A.Settings().pending[201] and A.FindRow(201).pending == 5 and A.FindRow(201).need == 18,
        "authoritative mail retires its receipt without a discarded premerge credit")
    st.reliable = false; A.GetRows(true)
    check(A.FindRow(201).need == nil, "unreliable stock remains unresolved")
    st.reliable = true
    local originalNeed, entered = A.Need, false
    A.Need = function(r)
        if not entered then entered = true; A.GetRows(true) end
        return originalNeed(r)
    end
    A.GetRows(true)
    check(entered and A.FindRow(201).need == 18, "same-stack nested row assembly has no shared deferred-need state")
    A.Need = function() error("need failure") end
    check(not pcall(A.GetRows, true), "live stock errors still propagate through row assembly")
    A.Need = originalNeed; A.GetRows(true)
    check(A.FindRow(201).need == 18, "a failed assembly cannot leave deferred state for the next publication")
    Trace(A, label .. "/receipt-reentry")

    A, st, env = Fixture(legacy, false, provider)
    st.charged, st.charges = 100, 5
    st.entries = { { itemID = 100, name = "Charged", target = 9 } }
    local replace = A.ApplyPotionReplacements
    A.ApplyPotionReplacements = function(rows) rows[1].itemID = 101; return rows end
    local replaced = A.GetRows(true)[1]
    check(replaced.itemID == 101 and not replaced.isCharge and replaced.unitsPerItem == 1 and replaced.need == 9,
        "the final stock pass refreshes units after an override changes the SKU")
    A.ApplyPotionReplacements = replace

    A, st, env = Fixture(legacy, false, provider)
    local methods = getmetatable(env.UIParent).__index
    methods.GetTexture = function(self) return self.texture end -- Native Texture getter absent from older broad fixture.
    st.entries = {}
    for id = 100, 179 do st.entries[#st.entries + 1] = { itemID = id, name = "Item" .. id, target = 0 } end
    A.GetRows(true); st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain(); A.UpdateUI()
    local work = {}
    for _, key in ipairs({ "SetText", "SetTexture", "SetEnabled", "SetShown", "SetChecked", "GetText", "GetTexture", "IsEnabled", "IsShown", "GetChecked" }) do
        local original = methods[key]
        methods[key] = function(self, ...) work[key] = (work[key] or 0) + 1; return original(self, ...) end
    end
    for _ = 1, 50 do A.UpdateUI() end
    print(("COMMERCE_WORK %s ui80x50 text=%d,texture=%d,enabled=%d,shown=%d,checked=%d,getText=%d,getTexture=%d,isEnabled=%d,isShown=%d,getChecked=%d"):format(
        label, work.SetText or 0, work.SetTexture or 0, work.SetEnabled or 0, work.SetShown or 0, work.SetChecked or 0,
        work.GetText or 0, work.GetTexture or 0, work.IsEnabled or 0, work.IsShown or 0, work.GetChecked or 0))
    -- A viewport can skip hidden rows while retaining ordinary native paints.
    -- Keep the original budget ceiling and reject broad getter guards; the
    -- following assertions still require live native-state repair on a row.
    if not measure then check(work.SetText > 0 and work.SetText <= 20350
        and work.SetTexture > 0 and work.SetTexture <= 4000
        and work.SetEnabled <= (legacy and 8350 or 8400)
        and work.SetShown <= (legacy and 24050 or 24100) and work.SetChecked == 150
        and (work.GetText or 0) == 0 and (work.GetTexture or 0) == 0,
        "visible-row paints stay within the original budget without broad native getter guards") end
    local cell, frame = A.frame.cells[1], A.frame
    local text, texture = cell.route:GetText(), cell._icon:GetTexture()
    cell.route.text, cell._icon.texture, cell.shown, cell.enabled = "native reset", 99999, false, false
    cell.selectionEdges[1].shown, frame.crafting.checked = false, false
    A.UpdateUI()
    check(cell.route:GetText() == text and cell._icon:GetTexture() == texture and cell:IsShown() and cell:IsEnabled()
        and cell.selectionEdges[1]:IsShown() and frame.crafting:GetChecked(), "native text/image/visibility/enabled/checked resets repair on the next original paint")
    frame.currencyGroup.gold.focus, frame.currencyGroup.gold.text = true, "editing"
    A.UpdateUI(); check(frame.currencyGroup.gold:GetText() == "editing", "focused currency input retains its current user text")
    frame.currencyGroup.gold.focus = false; A.UpdateUI()
    check(frame.currencyGroup.gold:GetText() == "0", "unfocused currency text restores its live saved cap")
    cell.route.GetText = function() error("unavailable native read") end
    cell.route.text = "wrong"; A.UpdateUI()
    check(cell.route.text == text, "painting does not require a potentially unavailable presentation getter")
    cell.route.GetText = nil
    local opaque = setmetatable({}, { __eq = function() error("opaque comparison") end })
    env.issecretvalue = function(v) return rawequal(v, opaque) end
    cell.route.GetText = function() return opaque end
    cell.route.text = "wrong"; A.UpdateUI()
    check(cell.route.text == text, "painting never reads or compares opaque native text")
    cell.route.GetText = nil
    local oldIcon, beforeTextures = env.FluxItemClass.GetIcon, work.SetTexture or 0
    local visibleImages = 0
    for _, painted in ipairs(A.frame.cells) do
        if painted.row and painted._icon and painted:IsShown() then visibleImages = visibleImages + 1 end
    end
    env.FluxItemClass.GetIcon = function() return opaque end
    A.UpdateUI(); A.UpdateUI()
    check(visibleImages > 0 and (work.SetTexture or 0) == beforeTextures + 2 * visibleImages,
        "identical opaque image values always forward for painted rows rather than authorizing a skip")
    env.FluxItemClass.GetIcon = oldIcon; A.UpdateUI()
    local originalSetText, nested = methods.SetText, false
    cell.route.text = "wrong"
    cell.route.SetText = function(self, value)
        originalSetText(self, value)
        check(self.text == value, "native presentation setter forwards the current value before reentry")
        if not nested then nested = true; A.UpdateUI() end
    end
    A.UpdateUI(); cell.route.SetText = nil
    check(nested and cell.route.text == text, "a setter can reenter the renderer without poisoning presentation state")
    local setterError = {}
    cell.route.text = "wrong"; cell.route.SetText = function() error(setterError, 0) end
    local painted, paintError = pcall(A.UpdateUI)
    check(not painted and paintError == setterError, "native setter errors propagate unchanged after renderer cleanup")
    cell.route.SetText = nil; A.UpdateUI()
    check(cell.route.text == text, "setter failure leaves no stale cache entry")
    A.transaction = {}; A.UpdateUI()
    check(not cell:IsEnabled() and not cell._bankBtn:IsEnabled() and not frame.currencyGroup.gold:IsEnabled(),
        "a submitted transaction disables its original input controls immediately")
    A.transaction = nil; A.UpdateUI()
    check(cell:IsEnabled() and cell._bankBtn:IsEnabled(), "ending a transaction immediately restores existing controls")
    st.entries[1].target, st.bags[100], st.mail[100] = 7, 2, 1
    A.GetRows(true); A.UpdateUI()
    check(cell.row.itemID == 100 and cell.row.need == 4 and cell.incoming:GetText() ~= "", "changed stock and pending labels update at the original publication")
    st.entries = { st.entries[2] }; A.GetRows(true); A.UpdateUI()
    check(A.frame.cells[1].row.itemID == 101 and not A.frame.cells[2]:IsShown(), "row replacement and retirement retain original cell ownership")
    frame:Hide(); A.UpdateUI(); check(not frame:IsShown(), "hidden AH content does not paint itself visible")
    A.Toggle(); st.drain(); check(frame:IsShown(), "reopening restores the existing content without rebuilding controls")
    Trace(A, label .. "/ui-transitions")
    check(not st.calls.quote and not st.calls.buyStack and not st.calls.confirm, "neither optimization can purchase or accept an upgrade")
 end
end
local tracePath = os.getenv("FLUX_COMMERCE_TRACE")
if tracePath then local f = assert(io.open(tracePath, "wb")); f:write(table.concat(traces, "\n")); f:close() end
print(("Commerce redundant work: %d checks PASS/%d models; native pixels/latency/FPS/taint/input NOT RUN"):format(checks, profiles))
