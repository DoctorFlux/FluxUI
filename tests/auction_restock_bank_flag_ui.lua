-- Actual material cells write the canonical per-item bank flag and replan.
local checks, profiles = 0, 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local export = setmetatable({ FLUX_AH_SOURCES_FIXTURE_EXPORT = true }, { __index = _G })
local chunk = assert(loadfile("tests/auction_restock_sources.lua", "t", export))
if setfenv then setfenv(chunk, export) end
local boot = chunk()
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, auctionator in ipairs({ false, true }) do for _, syndicator in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.settings.restockItems = { [100] = { targetQuantity = 10 } }
        st.bankItems[200] = 5
        recipe(100, 200, 1)
        st.books = { [100] = book(100, 10, 100), [200] = book(200, 10, 1) }
        if legacy then st.books[200].offers[2] = { itemID = 200, quantity = 5, total = 5 } end
        load("Inventory/Restock/Core/FluxRestockList.lua")
        env.FluxRestockItemRegistry.IsChargeItem = function() return false end
        env.FluxVendorAuto.NotifyVendorSettingsChanged = function() end
        scan()
        local function Cell()
            for _, cell in ipairs(A.frame.cells) do if cell.row and cell.row.itemID == 200 then return cell end end
        end
        local cell = assert(Cell())
        check(cell.row.isCraftMaterial and cell._bankBtn:IsShown() and cell._bankBtn:IsEnabled(),
            "temporary AH ingredient exposes the normal Count bank coin")
        check(not cell.row.countBank and A.Need(cell.row) == 10 and A.offer.quantity == 10,
            "bank flag off prepares all ten missing bag items despite five banked")
        st.press(cell._bankBtn); st.drain()
        cell = assert(Cell())
        local flags = st.settings.restockItems[200]
        check(flags and flags.countBank and flags.targetQuantity == 0
            and env.FluxVendorAuto.GetRestockTargetForItem(200) == 0,
            "ingredient coin persists a flag-only entry without creating a permanent target")
        check(cell.row.countBank and A.Need(cell.row) == 5 and A.offer.quantity == 5,
            "turning bank count on reprices the real recipe and prepares only five")
        local permanent = env.FluxVendorAuto.GetRestockTargetItems({ forOptionsPanel = true })
        local leaked = false
        for _, entry in ipairs(permanent) do if entry.itemID == 200 then leaked = true end end
        check(not leaked, "flag-only ingredient is absent from permanent manual target rows")
        st.press(cell._bankBtn); st.drain()
        cell = assert(Cell())
        check(not st.settings.restockItems[200] and not cell.row.countBank
            and A.Need(cell.row) == 10 and A.offer.quantity == 10,
            "turning bank count off removes its flag-only shell and restores the full shortage")
        check(not st.calls.quote and not st.calls.confirm and not st.calls.buyStack,
            "bank toggles search/reprice without issuing a purchase")
        A.transaction = {}; A.UpdateUI()
        st.press(cell._bankBtn); cell._bankBtn:Fire("OnClick")
        check(not cell._bankBtn:IsEnabled() and not st.settings.restockItems[200],
            "a submitted transaction prevents changing the ingredient bank flag")
        A.transaction = nil

        A, st, env, load, book, recipe, scan = boot(legacy, auctionator, syndicator)
        st.settings.restockItems = { [100] = { targetQuantity = 10 }, [201] = { targetQuantity = 0, countBank = true } }
        st.settings.merchantSources = { [201] = { unlimited = true, unitPrice = 1 } }
        st.bankItems[201] = 5; recipe(100, 201, 1)
        st.books = { [100] = book(100, 10, 100) }
        load("Inventory/Restock/Core/FluxRestockList.lua")
        env.FluxRestockItemRegistry.IsChargeItem = function() return false end
        scan()
        local vendor
        for _, entry in ipairs(env.FluxVendorAuto.GetRestockTargetItems({ merchantAware = true })) do
            if entry.itemID == 201 then vendor = entry end
        end
        check(vendor and vendor.restockSource == "craftMaterial" and vendor.countBank and vendor.bankCount == 5
            and env.FluxRestockList.EntryNeed(vendor) == 5,
            "temporary vendor ingredient exposes its saved bank flag and physical five-bank/five-buy quantities")
    end end
end
print(("Auction ingredient bank UI: %d checks PASS; %d profiles; native clicks/pixels/controller NOT RUN"):format(checks, profiles))
