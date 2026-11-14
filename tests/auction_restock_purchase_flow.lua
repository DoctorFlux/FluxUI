-- Real session + learned-material planner + incoming receipts in one purchase flow.
-- These models establish item/quantity/press ownership, not native AH permission.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local export = setmetatable({ FLUX_INCOMING_FIXTURE_EXPORT = true }, { __index = _G })
local chunk = assert(loadfile("tests/auction_incoming_mail.lua", "t", export))
if setfenv then setfenv(chunk, export) end
local fixture = chunk()
local function Purchases(st)
    return (st.calls.confirm or 0) + (st.calls.buyStack or 0) + (st.calls.buyItem or 0)
end
local function Book(legacy, id, quantity, unit)
    return { commodity = not legacy, offers = legacy and { { itemID = id, quantity = quantity, total = quantity * unit } }
        or { { itemID = id, quantity = quantity, unitPrice = unit, numOwnerItems = 0 } } }
end
local function Open(A, st)
    st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
end
local function Complete(st, legacy, unit, total)
    if legacy then st.legacyReceipt()
    else st.emit("COMMODITY_PRICE_UPDATED", unit, total); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
    st.drain()
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, provider in ipairs({ "absent", "ready" }) do
        for _, excess in ipairs({ false, true }) do
            profiles = profiles + 1
            local A, st, env, saved, external = fixture(legacy, provider)
            st.entries = {
                { itemID = 100, name = "A Potion", texture = 100, target = 5 },
                { itemID = 101, name = "B Bandage", texture = 101, target = 20 },
                { itemID = 300, name = "Z Next item", texture = 300, target = 1 },
            }
            st.bags[100], st.bags[101] = 4, 19
            st.recipeItems = { [101] = 7 }
            st.recipes = { { recipeID = 77, outputItemID = 101, name = "B Bandage", learned = true,
                legacy = true, quantityMin = 1, reagents = { { itemID = 200, count = 2 } } } }
            st.books = { [100] = Book(legacy, 100, 1, 338), [101] = Book(legacy, 101, 1, 500),
                [200] = Book(legacy, 200, legacy and 2 or 38, 10), [300] = Book(legacy, 300, 1, 7) }
            -- Old AH offers include a larger stack too; exact need wins when present.
            if legacy then st.books[200].offers[2] = { itemID = 200, quantity = 38, total = 380 }
            else
                local listing = st.books[200].offers[1]
                listing.auctionID, listing.itemKey, listing.itemLink = 987654, env.C_AuctionHouse.MakeItemKey(200), "item:200"
            end
            A.Settings().allowExcessStacks = excess
            Open(A, st)
            check(not A.craftPlans[101] and not A.FindRow(200)
                and st.searchedIDs and st.searchedIDs[100] and not st.searchedIDs[101]
                and not st.searchedIDs[200] and not st.searchedIDs[300],
                "initial preparation searches only the next potion without scanning later recipes or targets")
            check(A.offer and A.offer.itemID == 100 and A.offer.quantity == 1 and Purchases(st) == 0,
                "opening automatically prepares one missing potion without buying")
            st.press()
            if not legacy then
                check(st.calls.quote == 1 and st.last.args[1] == 100 and st.last.args[2] == 1 and not st.calls.confirm,
                    "first press authorizes only potion quantity one")
            end
            Complete(st, legacy, 338, 338)
            if not legacy then st.emit("AUCTION_HOUSE_PURCHASE_COMPLETED", 987654) end
            local material = A.FindRow(200, true)
            check(A.craftPlans[101] and material and material.target == 2 and material.need == 2,
                "potion receipt prepares the next known bandage with exactly two material units")
            check(A.FindRow(100).pending == 1 and material.pending == 0 and material.need == 2,
                "confirmed potion one cannot reserve the unbought cloth stack of 38")
            check(A.offer and A.offer.itemID == 200 and A.offer.quantity == 2 and Purchases(st) == 1,
                "exactly two required cloth remain buyable after potion receipt")
            check(st.inventory.Mail.GetCount(200) == 0 and #saved.mail == (provider == "ready" and 0 or 1),
                "unmatched item completion cannot add cloth to either incoming ledger")
            st.press()
            if not legacy then
                check(st.last.name == "quote" and st.last.args[1] == 200 and st.last.args[2] == 2,
                    "material press quotes two units despite 38 available")
            end
            Complete(st, legacy, 10, 20)
            material = A.FindRow(200, true)
            check(material.pending == 2 and material.need == 0 and A.Settings().pending[200].units == 2,
                "actual cloth purchase reserves exactly two units once")
            check(st.inventory.Mail.GetCount(200) == (provider == "ready" and 0 or 2),
                "built-in receipt publication preserves the exact material quantity and provider ownership")
            check(A.offer and A.offer.itemID == 300 and A.offer.quantity == 1 and not A.transaction and Purchases(st) == 2,
                "material receipt prepares the next row using information queries only")
            local quotes = st.calls.quote or 0
            st.advance(1); st.drain()
            check(Purchases(st) == 2 and (st.calls.quote or 0) == quotes,
                "prepared next item has no purchase intent until another player press")
            st.press(); Complete(st, legacy, 7, 7)
            check(Purchases(st) == 3 and A.FindRow(300, true).pending == 1,
                "third item consumes a distinct third press")
            if provider == "ready" then
                check(st.storeWrites == 0 and #saved.mail == 0 and #external.mail == 0,
                    "ready external provider never receives speculative built-in writes")
            else
                check(#saved.mail == 3 and st.publications == 3,
                    "three bought items produce exactly three built-in incoming records")
            end
            check(#st.errors == 0, "purchase/material flow raises no API exception")
        end

        do
            -- The receipt ledger stores physical items; restock converts to uses.
            local A, st, env = fixture(legacy, provider)
            st.charged, st.charges, st.entries[1].target = 100, 5, 9
            st.books = { [100] = Book(legacy, 100, 2, 7) }
            A.SetMaxPrice(100, 7)
            Open(A, st)
            check(A.offer and A.offer.quantity == 2 and A.offer.total == 14 and A.PurchaseLimit(100) == 7,
                "nine required uses quote two five-use items at a physical-item price limit")
            st.press(); Complete(st, legacy, 7, 14)
            local row = A.FindRow(100, true)
            check(Purchases(st) == 1 and row.pending == 10 and row.need == 0 and A.Settings().pending[100].units == 10,
                "two purchased physical items count as ten incoming uses exactly once")
            check(st.inventory.Mail.GetCount(100) == (provider == "ready" and 0 or 2)
                and st.inventory.Builtin.Mail.GetPredictedCount(100) == (provider == "ready" and 0 or 2),
                "native receipt and built-in predictions retain physical quantity two")
            st.press(); st.drain()
            check(Purchases(st) == 1, "covered charged-item target cannot buy again")
        end

        if not legacy then
            local function Stale(wallet, foreignOnly)
                local A, st, env, saved = fixture(false, provider)
                st.entries[1].target = 38
                st.books = { [100] = Book(false, 100, 50, 5) }
                Open(A, st)
                check(A.offer and A.offer.quantity == 38 and A.offer.total == 190,
                    "stale-offer fixture first prepares the original 38-unit shortage")
                st.bags[100], st.money = 36, wallet
                -- Another cached item must never supply this SKU's price or stock.
                st.offers = { { itemID = 999, quantity = 100, unitPrice = 1 } }
                if not foreignOnly then st.offers[2] = { itemID = 100, quantity = 50, unitPrice = 5 } end
                return A, st, env, saved
            end
            for _, excess in ipairs({ false, true }) do
                local A, st, env, saved = Stale(10, false)
                A.Settings().allowExcessStacks = excess
                st.press()
                check(st.last.name == "quote" and st.last.args[1] == 100 and st.last.args[2] == 2 and st.last.args[3] == 5,
                    "fresh press rebuilds stale 38 to live need two using only matching cached commodity rows")
                check(A.offer.quantity == 2 and A.offer.total == 10 and A.intent.quantity == 2,
                    "rebuilt offer and one-use quote intent agree before native confirmation")
                Complete(st, false, 5, 10)
                check(Purchases(st) == 1 and A.FindRow(100, true).pending == 2 and A.Settings().pending[100].units == 2,
                    "wallet for two can buy two while the stale 38-unit total is discarded")
                check(st.inventory.Mail.GetCount(100) == (provider == "ready" and 0 or 2),
                    "stale quantity cannot leak into incoming publication")
                A, st = Stale(9, false)
                A.Settings().allowExcessStacks = excess
                st.press()
                check(not st.calls.quote and Purchases(st) == 0 and A.status == "money" and not A.Settings().pending[100],
                    "wallet below rebuilt two-unit cost prevents the purchase before quoting")
            end
            local A, st = Stale(10, true)
            st.press()
            check(not st.calls.quote and Purchases(st) == 0 and not A.Settings().pending[100],
                "a cached foreign item alone cannot authorize this item's quote")
        end
    end
end
print(("Auction restock purchase flow: %d checks PASS; %d client/provider/excess profiles; native purchasing/taint/latency NOT RUN"):format(checks, profiles))
