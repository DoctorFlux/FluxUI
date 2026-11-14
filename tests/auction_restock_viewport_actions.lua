-- Production native-control callbacks; no native purchases or controller simulation.
local checks, profiles = 0, 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local fixture = assert(loadfile("tests/auction_restock.lua", "t", setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })))()
local function find(f, id)
    for _, cell in ipairs(f.cells) do if cell.row and cell.row.itemID == id then return cell end end
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    for _, provider in ipairs({ false, true }) do
        profiles = profiles + 1
        local A, s, e = fixture(client == "Era" or client == "Anniversary", false, provider)
        s.entries = {}
        for id = 100, 179 do
            s.entries[#s.entries + 1] = { itemID = id, name = "Item" .. id, target = 10, bankCount = id % 11 == 0 and 7 or 0 }
            s.bags[id] = 10
        end
        local proposals = {}
        for i, source in ipairs({ { "healPotion", 100 }, { "manaPotion", 130 }, { "bandage", 179 } }) do
            proposals[i] = { kind = source[1], sourceID = source[2], candidate = { itemID = 200 + i, effective = 600 },
                previousRestore = 100, unitPrice = 10, target = 10 }
        end
        A.GetUpgradeProposals = function() return proposals end
        local resolutions = {}
        A.ResolveUpgrade = function(proposal, action) resolutions[#resolutions + 1] = { proposal, action } end
        local tooltip = e.GameTooltip
        tooltip.SetOwner = function(self, owner) self.owner = owner end
        tooltip.SetItemByID = function(self, id) self.itemID = id; self.itemReads = (self.itemReads or 0) + 1 end
        tooltip.Show = function(self) self.visible = true end
        tooltip.Hide = function(self) self.visible = false end
        s.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); s.drain()
        A.state = "upgrade"; A.UpdateUI()
        local f, grid = A.frame, e.FluxConsumablesGridUI
        local optimized = type(f.PaintViewport) == "function"
        for _, dims in ipairs({ { 800, 600 }, { 640, 450 }, { 1024, 768 } }) do
            f.owner:SetSize(dims[1], dims[2]); f:Fire("OnSizeChanged")
            local y, rowHeight = 0, 0
            for i, cell in ipairs(f.cells) do
                local col = (i - 1) % f.cols
                if col == 0 and i > 1 then y, rowHeight = y + rowHeight + 26, 0 end
                local _, bank = grid.FormatTierCellCountLines(cell.row.bagCount or 0, cell.row.bankCount or 0, cell.row.target or 0, cell.row.countBank, cell.row.tierKind)
                local height = grid.ROW_H + (bank ~= nil and grid.BANK_COUNT_H or 0)
                check(cell.slotX == col * 84 and cell.slotY == y and cell:GetHeight() == height, "mixed bank/proposal layout retains every logical rectangle")
                rowHeight = math.max(rowHeight, height + (cell.upgrade and cell.upgrade.proposal and 50 or 0))
            end
            check(f.content:GetHeight() == math.max(f.viewportHeight, y + rowHeight + 26), "upgrade flow preserves native content range")
            for _, offset in ipairs({ 0, 84, 123, f.maxScroll }) do
                offset = math.min(offset, f.maxScroll); f.scroll:SetVerticalScroll(offset)
                check(f.scroll.nativeVerticalScroll, "viewport hook composes the original native scrollbar callback")
                for _, cell in ipairs(f.cells) do
                    local tail = cell.upgrade and cell.upgrade.proposal and 72 or 25
                    if cell.slotY + cell:GetHeight() + tail > offset and cell.slotY < offset + f.viewportHeight then
                        check(cell._icon and cell._countStr and cell.incoming and cell.route, "partial annotations and upgrade rows are materialized")
                        if cell.upgrade and cell.upgrade.proposal then
                            check(cell.upgrade.icon.texture ~= nil, "partially visible upgrade has its current icon")
                            for _, action in ipairs({ "upgrade", "keep", "blacklist" }) do check(cell.upgrade[action]:IsEnabled(), "all three independent upgrade actions retain native availability") end
                        end
                    end
                end
            end
        end
        f.owner:SetSize(800, 600); f:Fire("OnSizeChanged")
        f.scroll:SetVerticalScroll(0)
        local first, last = find(f, 100), find(f, 179)
        first:Fire("OnEnter")
        check(tooltip.owner == first and tooltip.itemID == 100 and tooltip.visible, "ordinary native hover retains current item help")
        local hoverReads = tooltip.itemReads
        for _ = 1, 3 do A.UpdateUI(); A.GetRows(true); A.UpdateUI() end
        check(tooltip.itemReads == hoverReads, "same-owner passive snapshots retain original tooltip query cadence")
        local retiredEnter, retiredLeave = first.scripts.OnEnter, first.scripts.OnLeave
        first:Fire("OnMouseDown")
        s.entries[1].restockSource = "manual"
        A.GetRows(true); A.UpdateUI(); first = find(f, 100)
        if optimized then
            check(tooltip.itemReads == hoverReads + 1, "changed hovered owner refreshes its help exactly once")
            first:Fire("OnMouseUp"); first:Fire("OnClick", "RightButton")
            check(not first.editBox:IsShown(), "a changed quantity owner retires a held action")
            retiredLeave(first)
            check(tooltip.visible and f.hoveredCell == first, "retired leave cannot clear a refreshed hover owner")
            last:Fire("OnEnter"); retiredEnter(first)
            check(tooltip.owner == last and tooltip.itemID == 179, "retired enter cannot replace another current tooltip")
            first:Fire("OnLeave")
            check(tooltip.owner == last and tooltip.visible, "another row's leave cannot hide the current tooltip")
        end
        last:Fire("OnLeave")
        local card = last.upgrade
        f.scroll:SetVerticalScroll(0)
        card.upgrade:Fire("OnClick")
        check(resolutions[#resolutions][1] == proposals[3] and resolutions[#resolutions][2] == "upgrade", "offscreen native upgrade target resolves its exact current proposal")
        if optimized then check(f.scroll:GetVerticalScroll() > 0, "offscreen upgrade is revealed before action") end
        for _, action in ipairs({ "keep", "blacklist" }) do
            card[action]:Fire("OnClick")
            check(resolutions[#resolutions][1] == proposals[3] and resolutions[#resolutions][2] == action, "each upgrade card keeps its independent action")
        end
        card.keep:Fire("OnEnter")
        check(tooltip.owner == card.keep and tooltip.itemID == 203, "upgrade hover belongs to its candidate and action")
        hoverReads = tooltip.itemReads
        for _ = 1, 3 do A.UpdateUI(); A.GetRows(true); A.UpdateUI() end
        check(tooltip.itemReads == hoverReads, "unchanged hovered proposal adds no passive tooltip reads")
        local retiredClick, retiredTip, retiredTipLeave = card.keep.scripts.OnClick, card.keep.scripts.OnEnter, card.keep.scripts.OnLeave
        local priorProposal, before = proposals[3], #resolutions
        card.keep:Fire("OnMouseDown")
        proposals[3] = { kind = "bandage", sourceID = 179, candidate = { itemID = 303, effective = 900 }, previousRestore = 100, unitPrice = 20, target = 10 }
        A.UpdateUI()
        if optimized then
            check(tooltip.itemReads == hoverReads + 1, "replacement hovered proposal refreshes its help exactly once")
            retiredClick(card.keep); card.keep:Fire("OnMouseUp"); card.keep:Fire("OnClick")
            check(#resolutions == before, "stale proposal closure and paired release cannot resolve a new proposal")
            retiredTipLeave(card.keep)
            check(tooltip.visible and f.hoveredUpgrade == card.keep and tooltip.itemID == 303, "stale upgrade leave preserves refreshed candidate hover")
            first:Fire("OnEnter"); retiredTip(card.keep)
            check(tooltip.owner == first and tooltip.itemID == 100, "stale candidate tip cannot replace current ordinary help")
        end
        card.keep:Fire("OnClick")
        check(resolutions[#resolutions][1] == proposals[3] and resolutions[#resolutions][1] ~= priorProposal, "a fresh invocation resolves the fresh proposal")
        card.upgrade:SetEnabled(false); A.UpdateUI()
        check(card.upgrade:IsEnabled(), "ordinary repaint restores native action availability after external changes")
        A.transaction = {}; A.UpdateUI()
        check(not card.upgrade:IsEnabled() and not card.keep:IsEnabled() and not card.blacklist:IsEnabled(), "all proposal controls disable together during a transaction")
        A.transaction = nil; A.UpdateUI()
        local raw, oldResolve = {}, A.ResolveUpgrade
        A.ResolveUpgrade = function() error(raw, 0) end
        local ok, err = pcall(card.upgrade.scripts.OnClick, card.upgrade)
        check(not ok and err == raw, "action errors propagate unchanged without retiring the current card")
        A.ResolveUpgrade = oldResolve; card.upgrade:Fire("OnClick")
        check(resolutions[#resolutions][1] == proposals[3], "action retry retains the current proposal")
        proposals = {}; A.UpdateUI()
        check(not card:IsShown(), "removed proposal hides its original native card")
        if optimized then
            before = #resolutions; retiredClick(card.keep)
            check(#resolutions == before, "retired removed proposal remains inert")
        end
        -- Other shared-grid consumers retain fresh default editors, while AH opts into reuse.
        local ordinary = e.CreateFrame("Button", nil, f.content, grid.backdropTemplate)
        grid.SetupCellChrome(ordinary, { itemId = 100 })
        local oldEditor, oldChrome = ordinary.editBox, ordinary._chrome
        check(oldEditor.parent == ordinary and oldEditor:GetWidth() == 36 and oldEditor:GetHeight() == 15 and not oldEditor:IsShown(), "default shared-grid editor geometry/lifetime stays unchanged")
        grid.SetupCellChrome(ordinary, { itemId = 100 })
        check(ordinary.editBox ~= oldEditor and ordinary._chrome ~= oldChrome, "default setup still creates fresh controls")
        if optimized then
            oldEditor, oldChrome = ordinary.editBox, ordinary._chrome
            oldEditor:SetText("77"); oldEditor:Show(); oldEditor:SetFocus()
            grid.SetupCellChrome(ordinary, { itemId = 100, showBank = false, reuseEditBox = true, reuseChrome = true })
            check(ordinary.editBox == oldEditor and ordinary._chrome == oldChrome and oldEditor:HasFocus() and oldEditor:GetText() == "77", "explicit AH reuse retains exact native editor, draft and focus")
        end
        check(not s.calls.quote and not s.calls.confirm and not s.calls.buyStack, "visual/action routing tests never issue a native purchase")
        local originalScroll = f.scroll.GetVerticalScroll
        f.scroll.GetVerticalScroll = function() return {} end
        local geometryOK = pcall(A.UpdateUI)
        check(not geometryOK, "opaque native scroll geometry retains the original error policy")
        f.scroll.GetVerticalScroll = originalScroll; A.UpdateUI()
        check(f.scroll:GetVerticalScroll() <= f.maxScroll, "ordinary geometry retry recovers without a stuck latch")
        local resident, nativeSlots = s.frames, {}
        for i, cell in ipairs(f.cells) do nativeSlots[i] = cell end
        for batch = 1, 100 do
            s.entries = {}
            for i = 1, 20 do
                local id = 200000 + batch * 20 + i
                s.entries[i] = { itemID = id, name = "Item" .. id, target = 10 }; s.bags[id] = 10
            end
            A.GetRows(true); A.UpdateUI()
            check(#f.cells == 80 and s.frames == resident, "disjoint configuration churn does not retain per-key frames or decorations")
            for i, cell in ipairs(f.cells) do check(cell == nativeSlots[i], "churn retains each baseline native slot pointer") end
        end
        f:Hide()
    end
end
print(("AH viewport actions: %d checks PASS; %d client/provider models; native input/controller/FPS/taint NOT RUN"):format(checks, profiles))
