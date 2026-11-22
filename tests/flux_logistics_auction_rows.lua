local export = setmetatable({FLUX_AH_FIXTURE_EXPORT = true}, {__index = _G})
local boot = assert(loadfile("tests/auction_restock.lua", "t", export))()
local checks = 0
local function check(ok, label)
    checks = checks + 1
    assert(ok, label)
end
local function cellFor(frame, id, job)
    for _, cell in ipairs(frame.cells) do
        local row = cell.row
        if row and row.itemID == id
            and (job and row.logistics and row.logistics.jobId == job or not job and not row.logistics) then return cell end
    end
end
local function prepare(A, row, authorize, observe)
    local request = {
        kind = "auction", itemID = row.itemID, quantity = row.quantity, jobId = row.jobId, id = row.id,
        planRevision = row.planRevision, groupRevision = row.groupRevision,
        maxUnitPrice = row.price, maxTotalPrice = row.price * row.quantity,
    }
    return A.PrepareLogistics(request, row.quantity, authorize, observe, true)
end
for _, legacy in ipairs({false, true}) do
    for _, tracking in ipairs({false, true}) do
        local A, st, env = boot(legacy, false, tracking)
        st.bags[100] = 10
        st.books = {
            [100] = {offers = {legacy and {quantity = 4, total = 220} or {quantity = 4, unitPrice = 55}}},
            [200] = {offers = {legacy and {quantity = 2, total = 120} or {quantity = 2, unitPrice = 60}}},
        }
        local first = {itemID = 100, quantity = 4, incoming = 0, jobId = 8, id = 1,
            planRevision = "original", groupRevision = "members:8,10", price = 60}
        local sameSKU = {itemID = 100, quantity = 0, incoming = 3, jobId = 9, id = 1, planRevision = "other", price = 30}
        local other = {itemID = 200, quantity = 2, incoming = 0, jobId = 8, id = 2, planRevision = "original", price = 70}
        local rows = {first, sameSKU, other}
        local calls, submitted, confirmed, projections = {}, {}, {}, 0
        local function select(row)
            calls[#calls + 1] = row
            return prepare(A, row, function(request, quantity)
                for _, current in ipairs(rows) do
                    if current.jobId == request.jobId and current.id == request.id
                        and current.planRevision == request.planRevision and current.itemID == request.itemID
                        and current.groupRevision == request.groupRevision then
                        return current.quantity >= quantity
                    end
                end
                return false
            end, function(event, receipt)
                if event == "submitted" then submitted[#submitted + 1] = receipt end
                if event == "confirmed" then
                    confirmed[#confirmed + 1] = receipt
                    for _, current in ipairs(rows) do
                        if current.jobId == receipt.jobId and current.id == receipt.id then
                            current.quantity = current.quantity - receipt.quantity
                            current.incoming = current.incoming + receipt.quantity
                            break
                        end
                    end
                    A.RefreshLogisticsRows()
                end
            end)
        end
        st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.drain()
        local frame = assert(A.frame)
        check(A.RegisterLogisticsRows({GetRows = function() projections = projections + 1; return rows end, Select = select}), "registers the optional provider")
        check(#A.GetRows(false) == 1 and cellFor(frame, 100) ~= nil and cellFor(frame, 100, 8) ~= nil
            and cellFor(frame, 100, 9) ~= nil and cellFor(frame, 200, 8) ~= nil, "same-SKU temporary rows coexist outside owner presets")
        local recorded = projections
        A.UpdateUI(); A.UpdateUI()
        check(projections == recorded, "ordinary owner paint reuses the published queue projection")
        local queued = cellFor(frame, 100, 8)
        check(queued._countStr:GetText() == "×4" and queued.route:GetText() == "Craft queue"
            and not queued._bankBtn:IsShown(), "queued cell displays missing units and has no bank editor")
        queued:Fire("OnClick", "RightButton")
        check(#calls == 0 and not queued.editBox:IsShown(), "queued target quantities cannot be edited here")
        queued._bankBtn:Fire("OnClick")
        check(#calls == 0, "a recycled bank control cannot mutate queued targets")
        queued:Fire("OnClick", "LeftButton")
        check(#calls == 1 and calls[1].jobId == 8 and not st.calls.quote and not st.calls.buyStack and not st.calls.buyItem,
            "selecting a temporary row only prepares its exact accepted job")
        check(not frame.noLimit:IsEnabled() and not frame.currencyGroup.gold:IsEnabled(), "accepted prices do not open editable preset controls")
        st.result()
        check(A.IsLogisticsPrimaryReady(first) and not A.IsLogisticsPrimaryReady(sameSKU)
            and frame.primary:IsEnabled(), "one ready offer belongs only to its job and exact row")
        first.groupRevision = "members:8,11"
        A.RefreshLogisticsRows()
        st.press(frame.primary)
        check(not A.IsLogisticsPrimaryReady(first) and #submitted == 0,
            "equal quantities and caps do not let replacement group members reuse the ready native offer")
        cellFor(frame, 100, 8):Fire("OnClick", "LeftButton")
        st.result()
        check(A.IsLogisticsPrimaryReady(first) and calls[#calls].groupRevision == first.groupRevision,
            "an explicit click prepares the new group's exact native offer")
        if not legacy then st.syncQuote, st.syncSuccess = {55, 220}, true end
        st.press(frame.primary)
        check(#submitted == 1 and submitted[1].jobId == 8 and submitted[1].itemID == 100
            and submitted[1].quantity == 4 and submitted[1].groupRevision == first.groupRevision,
            "the real primary button submits the approved group and reports its exact membership")
        if legacy then st.legacyReceipt() end
        A.RefreshLogisticsRows()
        local pending = cellFor(frame, 100, 8)
        check(#confirmed == 1 and pending and pending.row.logistics.quantity == 0
            and pending.incoming:GetText():find("4", 1, true) and not frame.primary:IsEnabled(), "confirmed auction mail stays visible until carried")
        st.press(frame.primary)
        check(#submitted == 1, "pending deliveries do not re-buy")
        table.remove(rows, 1)
        A.RefreshLogisticsRows()
        check(not cellFor(frame, 100, 8) and cellFor(frame, 100, 9) and cellFor(frame, 100), "only the specific carried row leaves")
        cellFor(frame, 200, 8):Fire("OnClick", "LeftButton")
        st.result()
        check(A.IsLogisticsPrimaryReady(other), "next exact queued row prepares in the same Restock session")
        other.quantity, other.incoming = 0, 2
        st.press(frame.primary)
        check(#submitted == 1 and not frame.primary:IsEnabled(), "unpainted provider change cannot buy the stale row")
        cellFor(frame, 100):Fire("OnClick", "LeftButton")
        check(frame.noLimit:IsEnabled() and not frame.logisticsChoice, "explicit preset selection restores the original editor")
        local before = #calls
        local moving = cellFor(frame, 100, 9)
        moving:Fire("OnMouseDown")
        sameSKU.planRevision = "replaced"
        A.RefreshLogisticsRows()
        moving:Fire("OnMouseUp")
        moving:Fire("OnClick", "LeftButton")
        check(#calls == before and not frame.logisticsChoice, "recycled row rejects a previous mouse capture")
        check(A.RegisterLogisticsRows(nil) and not cellFor(frame, 100, 9) and cellFor(frame, 100), "optional projection can be removed")
    end
end

for _, legacy in ipairs({false, true}) do
    local A, st = boot(legacy, false, false)
    st.books = {
        [100] = {offers = {legacy and {quantity = 2, total = 20} or {quantity = 2, unitPrice = 10}}},
        [101] = {offers = {legacy and {quantity = 1, total = 30} or {quantity = 1, unitPrice = 30}}},
    }
    st.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); st.result()
    check(A.active and A.offer and A.state == "ready", "initial standalone offer is ready and unsubmitted")
    local result, calls = nil, 0
    check(A.ScanLogisticsBooks({101}, function(books) result, calls = books, calls + 1 end),
        "explicit depth can replace an ordinary ready offer")
    check(A.state == "searching" and not A.offer, "unsubmitted owner offer is cleared before a new native search")
    st.press(A.frame.primary)
    check(not st.calls.quote and not st.calls.buyStack, "an in-progress replacement scan cannot submit the old listing")
    st.result()
    check(calls == 1 and result[101] and result[101].complete, "read-only depth publishes after replacing a ready offer")
end
print(("Temporary queued auction targets: %d focused actual-owner checks passed."):format(checks))
