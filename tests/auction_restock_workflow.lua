-- Workflow boundaries: shortage-only scans, authoritative mail and shared bank.
local checks, profiles = 0, 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local export = setmetatable({ FLUX_FOLLOWUP_FIXTURE_EXPORT = true }, { __index = _G })
local chunk = assert(loadfile("tests/auction_restock_followup.lua", "t", export))
if setfenv then setfenv(chunk, export) end
local Fixture = chunk()
local function Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for key, child in pairs(value) do out[key] = Copy(child) end; return out
end
local function Book(legacy, id, quantity, price)
    return { commodity = not legacy, offers = legacy and { { itemID = id, quantity = quantity, total = quantity * price } }
        or { { itemID = id, quantity = quantity, unitPrice = price } } }
end
local function Direct(legacy, provider)
    local A, st, env, F = Fixture(legacy, provider)
    st.recipes, st.recipeItems = {}, {}
    st.entries = { { itemID = 100, name = "Direct", target = 5 } }; st.bags[100] = 0
    st.books = { [100] = Book(legacy, 100, 5, 10) }
    st.openAH(); st.press()
    if legacy then st.legacyReceipt()
    else st.emit("COMMODITY_PRICE_UPDATED", 10, 50); st.emit("COMMODITY_PURCHASE_SUCCEEDED") end
    st.drain(); A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
    st.mailboxOpen = true; st.emit("MAIL_SHOW")
    return A, st, env, F
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    local legacy = client == "Era" or client == "Anniversary"
    for _, provider in ipairs({ "absent", "ready" }) do
        profiles = profiles + 1
        local A, st, env, F = Fixture(legacy, provider)
        st.recipes, st.recipeItems = {}, {}
        st.entries = {
            { itemID = 100, name = "Missing", target = 3 },
            { itemID = 101, name = "Full", target = 10 },
            { itemID = 102, name = "Disabled", target = 0 },
            { itemID = 201, name = "Full vendor", target = 4 },
        }
        st.bags[100], st.bags[101], st.bags[201] = 1, 10, 4
        st.books = { [100] = Book(legacy, 100, 2, 10), [101] = Book(legacy, 101, 20, 10),
            [102] = Book(legacy, 102, 20, 10), [201] = Book(legacy, 201, 20, 1) }
        st.openAH()
        check(st.searchedIDs[100] and not st.searchedIDs[101] and not st.searchedIDs[102] and not st.searchedIDs[201],
            "only the actual shortage is queried, including hidden vendor candidates")
        check(A.offer and A.offer.itemID == 100 and A.offer.quantity == 2, "remaining shortage is prepared automatically")
        st.press()
        check(not F.Clear() and (A.transaction or A.state == "quoting"), "clear cannot discard a submitted transaction")
        st.ack()
        check(F.GetMailItems()[100] == 2, "only acknowledged physical quantity becomes collection work")
        A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
        st.mailboxOpen = true; st.emit("MAIL_SHOW")
        st.inventory.snapshots.mail.counts[100] = 2
        local providerCount = st.inventory.Mail.GetCount(100)
        F.MailSnapshotComplete({})
        check(not next(F.GetMailItems()) and not A.Settings().pending[100] and not F.GetState(),
            "authoritatively empty inbox clears receipt, reservation and direct reminder")
        check(st.inventory.Mail.GetCount(100) == providerCount, "native reconciliation never writes the provider's mail map")
        st.mailboxOpen = false; st.emit("MAIL_CLOSED")
        local row = A.FindRow(100, true)
        check(A.MailUnits(row) == 0 and A.Need(row) == 2, "stale provider prediction cannot keep false pending in AH cells")

        -- Clear preserves permanent targets and cached mailbox ownership.
        A.Settings().pending[100] = { units = 2, unitScale = 1, accepted = true }
        local target, mail = st.entries[1].target, st.inventory.snapshots.mail.counts[100]
        check(F.HasWork() and F.Clear() and not F.HasWork(), "manual clear retires temporary work")
        check(st.entries[1].target == target and st.inventory.snapshots.mail.counts[100] == mail,
            "clear leaves permanent stock targets and mailbox records intact")
        A.Settings().pending[100] = { units = 1, unitScale = 1, accepted = true }
        st.inventory.snapshots.mail.counts[100] = 0
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); A.ScanQueue()
        check(A.queue ~= nil, "a read-only scan can coexist with older pending work")
        check(F.Clear() and not A.queue and not A.search and A.state == "idle",
            "manual clear cancels read-only preparation instead of leaving a stranded pricing queue")
        st.drain()
        check(not F.HasWork() and not A.queue, "late scan callbacks cannot resurrect cleared temporary work")

        -- A plan can be persisted before any auction purchase is necessary.
        A, st, env, F = Fixture(legacy, provider)
        st.openAH()
        local saved = Copy(A.Settings()); saved.followup, saved.pending = nil, {}
        A, st, env, F = Fixture(legacy, provider, saved)
        st.reliable = false; st.emit("PLAYER_LOGIN")
        check(not F.GetState() and st.inventoryListeners["AuctionRestock.Followup.Resume"],
            "saved recipe work waits for reliable login inventory without requiring a receipt")
        st.reliable = true; st.inventoryListeners["AuctionRestock.Followup.Resume"]()
        check(F.GetState() and F.GetState().kind == "waiting" and not next(F.GetMailItems())
            and not st.inventoryListeners["AuctionRestock.Followup.Resume"],
            "readiness restores the exact saved recipe work and detaches its temporary listener")

        -- Bank quantities are physical; normal owner performs the transfer.
        A, st, env, F = Fixture(legacy, provider)
        st.openAH(); st.press(); st.ack(); A.frame:Hide(); st.emit("AUCTION_HOUSE_CLOSED")
        st.bags[200] = 2
        local stored, requests, invalidations, refreshes = 2, 0, 0, 0
        env.FluxRestock.Inv.Bank = env.FluxRestock.Inv.Bank or {}
        env.FluxRestock.Inv.Bank.IsOpen = function() return true end
        env.FluxRestock.Inv.Bank.IsLive = function() return true end
        env.FluxBankRestock = {
            RunAuctionFollowup = function(manual)
                local goals = F.GetBankTargets()
                check(manual == true and #goals == 1 and goals[1].itemID == 201 and goals[1].target == 2,
                    "HUD delegates only this job's physical ingredient goal to the live bank owner")
                requests = requests + 1; return true
            end,
            InvalidateCanRunCache = function() invalidations = invalidations + 1 end,
            RunFastButtonRefresh = function() refreshes = refreshes + 1; F.GetBankTargets() end,
        }
        A.GetCraftBankAvailable = function(id) return id == 201 and stored or 0 end
        F.Refresh()
        check(F.GetState().kind == "bank" and F.GetState().items[201] == 2, "bank-held vendor ingredients prepare retrieval before vendor buying")
        local targets = F.GetBankTargets()
        check(#targets == 1 and targets[1].itemID == 201 and targets[1].target == 2 and targets[1].mode == "stack",
            "bank owner receives a temporary physical bag target")
        targets[1].target = 999
        check(F.GetBankTargets()[1].target == 2, "callers cannot mutate the shared temporary target")
        check(invalidations == 1 and refreshes == 1, "new bank goals invalidate the normal button cache once without recursive refresh")
        st.followPress()
        check(requests == 1 and #st.crafts == 0 and #st.vendorBuys == 0, "HUD delegates bank retrieval without crafting or buying")
        st.bags[201], stored = 2, 0; st.emit("BAG_UPDATE_DELAYED")
        check(F.GetState().kind == "craft" and F.GetState().task.operations == 2 and #F.GetBankTargets() == 0,
            "bank arrival automatically advances to the exact craft and removes temporary bank work")
        check(#st.crafts == 0 and #st.opens == 0, "stage progression consumes no player press and starts no protected operation")
        check(invalidations == 2 and refreshes == 2, "fulfilled bank goals invalidate the cache once; unchanged reads do no extra work")

        -- Real ACK predictions must not obscure snapshot-first attachment proof.
        for _, ownedTake in ipairs({ false, true }) do
            A, st, env, F = Direct(legacy, provider)
            st.bagStorm = true
            if ownedTake then check(F.MailTakeStarted(100, 3), "owned take starts with an acknowledged five-item receipt") end
            F.MailSnapshotComplete({ [100] = 2 })
            if ownedTake then F.MailTakeFinished(100, 3) end
            check(F.GetMailItems()[100] == 2, "native snapshot leaves two uncollected items")
            st.bags[100], st.bagStorm = 3, false; st.emit("BAG_UPDATE_DELAYED")
            check(F.GetMailItems()[100] == 2, "delayed bags cannot credit snapshot-confirmed collection a second time")
        end
        A, st, env, F = Direct(legacy, provider)
        st.inventory.snapshots.mail.counts[100] = 5
        F.MailSnapshotComplete({})
        check(not F.GetState(), "complete empty inbox clears the collection HUD")
        F.MailSnapshotComplete({ [100] = 1 })
        local native = A.SetItemUnits({ itemID = 100 })
        check(A.MailUnits(native) == 1 and not F.GetState(), "later native mail replaces an old zero fact without creating unrelated HUD work")
        st.inventory.snapshots.mail.counts[100] = 2
        check(A.MailUnits(native) == 2, "a changed provider count is no longer shadowed by the older native override")

    end
end
print(("Auction restock workflow: %d checks PASS; %d client/provider profiles; native delivery/permissions NOT RUN"):format(checks, profiles))
