-- Actual AH renderer/shared widgets, with native facts supplied by the existing fixture.
-- Counts establish widget work; native FPS, clipping, taint and controller remain separate.
local checks, profiles, traces = 0, 0, {}
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local fixture = assert(loadfile("tests/auction_restock.lua", "t", setmetatable({ FLUX_AH_FIXTURE_EXPORT = true }, { __index = _G })))()
local function find(f, id)
    for _, cell in ipairs(f.cells) do if cell.row and cell.row.itemID == id and not cell.row.upgradeOnly then return cell end end
end
local function serial(value)
    if type(value) == "table" then
        local out = {}; for i, v in ipairs(value) do out[i] = serial(v) end
        return "[" .. table.concat(out, ",") .. "]"
    end
    if type(value) == "string" then return string.format("%q", value) end
    if value == nil then return "null" end
    return tostring(value)
end
for _, client in ipairs({ "Retail", "Forever", "MoP", "Era", "Anniversary" }) do
    for _, provider in ipairs({ false, true }) do
        profiles = profiles + 1
        local legacy = client == "Era" or client == "Anniversary"
        local A, s, e = fixture(legacy, false, provider)
        s.entries = {}
        for id = 100001, 101000 do
            s.entries[#s.entries + 1] = { itemID = id, name = ("Item%06d"):format(id), target = 10, bankCount = 0 }
            s.bags[id] = 10
        end
        local m = getmetatable(e.UIParent).__index
        local work = { width = 0, text = 0, texture = 0, nativeFrames = 0 }
        local oldCreate = e.CreateFrame
        e.CreateFrame = function(...) work.nativeFrames = work.nativeFrames + 1; return oldCreate(...) end
        for _, pair in ipairs({ { "GetStringWidth", "width" }, { "SetText", "text" }, { "SetTexture", "texture" } }) do
            local original = m[pair[1]]
            m[pair[1]] = function(self, ...) work[pair[2]] = work[pair[2]] + 1; return original(self, ...) end
        end
        local before = s.frames
        s.emit("AUCTION_HOUSE_SHOW"); A.Toggle(); s.drain()
        local f, grid = A.frame, e.FluxConsumablesGridUI
        local optimized = type(f.PaintViewport) == "function"
        local opening = { s.frames - before, work.width, work.text, work.texture, work.nativeFrames }
        check(#A.rows == 1000 and #f.cells == 1000, "all logical configured targets retain native controls")
        check(f.content:GetHeight() == 125 * 84 and f.cells[1000].slotY == 124 * 84, "all rows retain the exact original scroll extent")
        if optimized then
            check(opening[1] <= 4 * 1000 + 11 * 64 + 100, "opening regions are limited to viewport/overscan, retaining four native frames per row")
            check(opening[2] <= 512, "opening does not measure the thousand offscreen count strings")
        end
        work.width, work.text, work.texture = 0, 0, 0
        for _ = 1, 20 do A.UpdateUI() end
        local warm = { work.width, work.text, work.texture }
        if optimized then
            check(warm[1] <= 2560 and warm[2] <= 11000 and warm[3] <= 1280, "twenty paints bound expensive count/icon/text work by viewport")
        end
        local unchanged = work.width
        f.scroll:SetVerticalScroll(1)
        check(work.width == unchanged, "scrolling within unchanged flow groups does not remeasure them")
        f.scroll:SetVerticalScroll(0)
        local scalar, scrollMeasurements = {}, work.width
        for offset = 0, f.maxScroll + 84, 84 do
            f.scroll:SetVerticalScroll(math.min(offset, f.maxScroll))
            local top = f.scroll:GetVerticalScroll()
            for _, cell in ipairs(f.cells) do
                if cell.row and cell.slotY + cell:GetHeight() + 25 > top and cell.slotY < top + f.viewportHeight then
                    check(cell._icon and cell._countStr and cell.route and cell.limit, "every partially visible row has all original regions")
                    check(cell:GetWidth() == 80 and cell:GetHeight() == 58, "visible count/font fit retains original cell geometry")
                    scalar[cell.row.itemID - 100000] = { cell.row.itemID, cell.slotX, cell.slotY, cell:GetHeight(), cell._countStr.text,
                        cell._bankCountStr.text or "", cell.route.text, cell.incoming.text, cell.limit.text, cell._icon.texture,
                        cell:IsEnabled(), cell._bankBtn:IsEnabled(), cell._bankBtn:IsShown() }
                end
            end
        end
        scrollMeasurements = work.width - scrollMeasurements
        for id = 1, 1000 do check(scalar[id] ~= nil, "full traversal visits every configured semantic target") end
        local visited = s.frames - before
        check(visited == 15000 + (legacy and 20 or 21), "visiting every row converges to original resident decoration count")
        local first, last = find(f, 100001), find(f, 101000)
        local nativeSlots = {}
        for i, cell in ipairs(f.cells) do nativeSlots[i] = { cell, cell._chrome, cell._bankBtn, cell.editBox } end
        local oldSettingsChanged = A.SettingsChanged
        local writes, changed = {}, 0
        e.FluxVendorAuto.SetRestockTarget = function(id, target) writes[#writes + 1] = { id, target } end
        e.FluxVendorAuto.SetRestockItemFlag = function(id, key, value) writes[#writes + 1] = { id, key, value } end
        A.SettingsChanged = function() changed = changed + 1; A.GetRows(true); A.UpdateUI() end
        -- Fixed price drafts stay attached to the selected item during all scrolling.
        A.Select(100001)
        local g = f.currencyGroup
        g.gold:SetFocus(); g.gold:SetText("123")
        f.scroll:SetVerticalScroll(f.maxScroll)
        check(g.gold:HasFocus() and g.gold:GetText() == "123" and g.itemID == 100001, "scrolling preserves focused price draft and semantic selection")
        g.gold:Fire("OnEscapePressed")
        -- An offscreen native target pointer can still receive activation after free scrolling.
        -- Reveal the same semantic target before activation, without querying native manager state.
        first:Fire("OnClick", "RightButton")
        if optimized then check(f.scroll:GetVerticalScroll() == 0, "offscreen focused row is revealed before activation") end
        check(first.editBox:HasFocus() and first.editBox:IsShown(), "quantity editor remains a native persistent focus target")
        first.editBox:SetText("27")
        f.scroll:SetVerticalScroll(f.maxScroll)
        check(first.editBox:HasFocus() and first.editBox:IsShown(), "free scrolling retains the offscreen quantity draft and focus")
        first.editBox:Fire("OnEnterPressed")
        check(writes[#writes][1] == 100001 and writes[#writes][2] == 27, "offscreen editor commits its original semantic owner")
        first = find(f, 100001)
        first:Fire("OnClick", "RightButton"); first.editBox:SetText("99")
        local priorWrites = #writes
        first.editBox:Fire("OnEscapePressed")
        check(#writes == priorWrites and not first.editBox:HasFocus(), "quantity Escape still cancels without writing")
        local priorBinding, priorHandler = first.binding, first.scripts.OnClick
        first:Fire("OnMouseDown")
        A.GetRows(true); A.UpdateUI()
        first:Fire("OnMouseUp"); first:Fire("OnClick", "RightButton")
        check(first.editBox:HasFocus() and first.editBox:IsShown(), "a same-owner fresh passive snapshot preserves a valid paired click")
        if optimized then check(first.binding == priorBinding and first.scripts.OnClick == priorHandler, "fresh metadata does not churn owner tokens or callback closures") end
        first.editBox:Fire("OnEscapePressed")
        -- Re-sort and same-ID metadata refresh must retain current owner and its native pointers.
        s.entries[1].name = "ZZZ first"; s.entries[1].bankCount = 7
        A.GetRows(true); A.UpdateUI()
        first = find(f, 100001)
        for i, cell in ipairs(f.cells) do
            check(cell == nativeSlots[i][1] and cell._chrome == nativeSlots[i][2] and cell._bankBtn == nativeSlots[i][3]
                and cell.editBox == nativeSlots[i][4], "sort preserves baseline slot, chrome, bank and editor native pointers")
        end
        f.scroll:SetVerticalScroll(f.maxScroll)
        check(first:GetHeight() == 68 and first._bankCountStr.text:find("7", 1, true), "refreshed bank-line height and text use current metadata")
        -- An old captured callback/paired press must never activate a replacement entry.
        local oldClick = first.scripts.OnClick
        first:Fire("OnMouseDown")
        local removed = table.remove(s.entries, 1)
        s.entries[#s.entries + 1] = { itemID = 101001, name = "Replacement", target = 10 }
        s.bags[101001] = 10
        A.GetRows(true); A.UpdateUI()
        check(#f.cells == 1000, "same-cardinality model replacement retains the original max-row pool bound")
        if optimized then
            local selected = A.editorID
            oldClick(first, "RightButton"); first:Fire("OnMouseUp"); first:Fire("OnClick", "RightButton")
            check(A.editorID == selected and not first.editBox:IsShown(), "replaced slot owner's captured click and held release are rejected")
            check(find(f, 101001) == first and first == nativeSlots[1000][1], "configuration changes reuse the original baseline native slot")
        end
        s.entries[#s.entries] = removed; A.GetRows(true); A.UpdateUI()
        first = find(f, 100001)
        if optimized then
            local selected = A.editorID
            oldClick(first, "RightButton")
            check(A.editorID == selected and not first.editBox:IsShown(), "reintroduced same-ID owner rejects a retired captured script")
            check(first._bankBtn == nativeSlots[1000][3] and first.editBox == nativeSlots[1000][4], "reintroduction retains original baseline slot roles")
        end
        -- Native disabled state remains authoritative and is refreshed even offscreen.
        A.transaction = {}; A.UpdateUI()
        local locked = #writes
        first._bankBtn:Fire("OnClick"); first:Fire("OnClick", "RightButton")
        check(not first:IsEnabled() and not first._bankBtn:IsEnabled() and #writes == locked, "offscreen controls obey transaction and native disabled state")
        A.transaction = nil; A.UpdateUI()
        check(first:IsEnabled() and first._bankBtn:IsEnabled(), "native enabled state is restored at the original repaint cadence")
        -- A raw native font error must propagate, then a normal retry can finish painting.
        f.scroll:SetVerticalScroll(0)
        local originalWidth, rawError = m.GetStringWidth, {}
        m.GetStringWidth = function() error(rawError, 0) end
        local ok, err = pcall(A.UpdateUI)
        check(not ok and err == rawError, "font failure propagates the exact original error")
        m.GetStringWidth = originalWidth; A.UpdateUI()
        check(find(f, 100002)._countStr.text ~= nil, "retry after a paint error remains usable")
        -- A native font callback can synchronously replace the committed model.
        if optimized then
            local nested = false
            m.GetStringWidth = function(self, ...)
                if not nested then
                    nested = true; s.entries[1].bankCount = 9; s.bags[s.entries[1].itemID] = 9
                    A.GetRows(true); A.UpdateUI(); f.scroll:SetVerticalScroll(f.maxScroll)
                end
                return originalWidth(self, ...)
            end
            A.UpdateUI(); m.GetStringWidth = originalWidth
            local current = find(f, s.entries[1].itemID)
            f.scroll:SetVerticalScroll(current.slotY)
            check(nested and current:GetHeight() == 68 and current._bankCountStr.text:find("9", 1, true), "newer same-stack model survives old font paint")
            local expected = grid.FormatTierCellCountLines(current.row.bagCount, current.row.bankCount, current.row.target, current.row.countBank, current.row.tierKind)
            check(current._countStr.text == expected, "interrupted offscreen target is dirty and repaints current counts on scroll back")
            check(current.row == A.FindRow(current.row.itemID), "font reentry preserves the current committed row binding")
        end
        A.SettingsChanged = oldSettingsChanged
        check(not s.calls.quote and not s.calls.confirm and not s.calls.buyStack, "scroll/model/editor work never dispatches a purchase")
        traces[#traces + 1] = { client, provider, scalar }
        print(("AH_VIEWPORT %s provider=%s optimized=%s openingWidgets=%d nativeFrames=%d openingWidth=%d warmWidth=%d warmText=%d warmTexture=%d fullVisitWidgets=%d scrollWidth=%d"):format(
            client, tostring(provider), tostring(optimized), opening[1], opening[5], opening[2], warm[1], warm[2], warm[3], visited, scrollMeasurements))
        f:Hide()
        check(not g.gold:HasFocus() and not first.editBox:HasFocus(), "hide releases native text focus")
    end
end
local trace = serial(traces)
local tracePath = os.getenv("FLUX_AH_VIEWPORT_TRACE")
if tracePath then local file = assert(io.open(tracePath, "wb")); file:write(trace); file:close() end
print(("AH viewport work: %d checks PASS; %d client/provider models; semanticTraceBytes=%d; native FPS/controller/taint NOT RUN"):format(checks, profiles, #trace))
