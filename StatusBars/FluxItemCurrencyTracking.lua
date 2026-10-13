-- FluxItemCurrencyTracking.lua
-- Show bag counts for specific item IDs (e.g. TBC-style badge items) on the gold strip.
-- Item currency data: FluxOptions:GetItemCurrencyDB (char.itemCurrency) — always per character.

local addonName, addonTable = ...

-- Total rows (includes one trailing empty slot for "add next item"); max 39 tracked + 1 empty = 40
local MAX_ITEM_CURRENCY_SLOT_ROWS = 40
-- Pool of segment buttons on the bar when many items are on bar
local MAX_ITEM_CURRENCY_BUTTONS = 50

FluxItemCurrencyTracking = FluxItemCurrencyTracking or {}

--- Enforces: one empty slot at the end for adding, collapses duplicate trailing empties, and caps row count.
function FluxItemCurrencyTracking.MaintainItemCurrencySlotList(ic)
    if not ic or type(ic) ~= "table" or type(ic.slots) ~= "table" then
        return
    end
    for i, row in ipairs(ic.slots) do
        if type(row) ~= "table" then
            ic.slots[i] = { itemId = 0, show = false }
        else
            if type(row.itemId) == "string" then
                row.itemId = tonumber(row.itemId) or 0
            end
            if type(row.itemId) ~= "number" then
                row.itemId = 0
            end
            if row.itemId < 0 then
                row.itemId = 0
            end
            -- No separate "on bar" flag: an item in a slot is tracked on the bar; empty is not.
            row.show = (row.itemId and row.itemId > 0) and true or false
        end
    end
    while #ic.slots >= 2 do
        local a = ic.slots[#ic.slots]
        local b = ic.slots[#ic.slots - 1]
        if (a and (a.itemId or 0) == 0) and (b and (b.itemId or 0) == 0) then
            table.remove(ic.slots, #ic.slots)
        else
            break
        end
    end
    if #ic.slots < 1 then
        ic.slots[1] = { itemId = 0, show = false }
    end
    local last = ic.slots[#ic.slots]
    if (last and (last.itemId or 0) > 0) and #ic.slots < MAX_ITEM_CURRENCY_SLOT_ROWS then
        table.insert(ic.slots, { itemId = 0, show = false })
    end
    while #ic.slots > MAX_ITEM_CURRENCY_SLOT_ROWS do
        table.remove(ic.slots, #ic.slots)
    end
    if #ic.slots < 1 then
        ic.slots[1] = { itemId = 0, show = false }
    end
end

--- Always reads FluxOptions:GetItemCurrencyDB (char.itemCurrency, per-character only).
function FluxItemCurrencyTracking.EnsureItemCurrencyData()
    if not FluxOptions or not FluxOptions.GetItemCurrencyDB then
        return nil
    end
    local ic = FluxOptions:GetItemCurrencyDB()
    if not ic then
        return nil
    end
    if not ic.slots or type(ic.slots) ~= "table" then
        ic.slots = {}
    end
    for i = 1, #ic.slots do
        local row = ic.slots[i]
        if not row or type(row) ~= "table" then
            ic.slots[i] = { itemId = 0, show = false }
        else
            if type(row.itemId) == "string" then
                row.itemId = tonumber(row.itemId) or 0
            end
            if type(row.itemId) ~= "number" then
                row.itemId = 0
            end
            if row.itemId < 0 then
                row.itemId = 0
            end
            row.show = (row.itemId and row.itemId > 0) and true or false
        end
    end
    if ic.enabled == nil then
        ic.enabled = true
    end
    return ic
end

function FluxItemCurrencyTracking.NotifyItemCurrencyChanged()
    if FluxOptions and FluxOptions.RefreshStatusBarScopedModules then
        FluxOptions:RefreshStatusBarScopedModules()
    end
    if _G.UpdateGoldBar then
        pcall(_G.UpdateGoldBar)
    end
    local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if ACR then
        ACR:NotifyChange("FluxUI")
    end
    if FluxItemCurrencyTracking._RefreshSlotsUIFromAce then
        pcall(FluxItemCurrencyTracking._RefreshSlotsUIFromAce)
    end
end

--- Resolves the item on the cursor from a bag pick / drag. Shared with options drag slots and the gold bar.
function FluxItemCurrencyTracking.GetItemIdFromCursor()
    if not GetCursorInfo then
        return nil
    end
    local t, a, b, c, d = GetCursorInfo()
    if t ~= "item" then
        return nil
    end
    if _G.FluxButtonUtil and _G.FluxButtonUtil.GetItemIDFromIdentifier then
        local id = _G.FluxButtonUtil.GetItemIDFromIdentifier(a)
        if type(id) == "number" and id > 0 then
            return math.floor(id)
        end
    end
    if type(a) == "number" and a > 0 then
        return math.floor(a)
    end
    if type(b) == "string" and b:find("item", 1, true) then
        local m = b:match("item:(%d+)")
        if m then
            return tonumber(m)
        end
    end
    if type(c) == "number" and type(d) == "number" then
        if C_Container and C_Container.GetContainerItemID then
            local iid = C_Container.GetContainerItemID(c, d)
            if iid and iid > 0 then
                return math.floor(iid)
            end
        end
        if GetContainerItemID then
            local iid = GetContainerItemID(c, d)
            if iid and iid > 0 then
                return math.floor(iid)
            end
        end
    end
    return nil
end

--- Puts an item into the next empty slot, enables item currency, or reuses a slot with the same item. Gold bar + config use this.
function FluxItemCurrencyTracking.AcceptItemDropOnCurrencyBar(itemId)
    if not itemId or type(itemId) ~= "number" or itemId < 1 then
        return false
    end
    local ic = FluxItemCurrencyTracking.EnsureItemCurrencyData()
    if not ic or not ic.slots then
        return false
    end
    itemId = math.floor(itemId)
    ic.enabled = true
    for s = 1, #ic.slots do
        if ic.slots[s] and (ic.slots[s].itemId or 0) == itemId then
            ic.slots[s].show = true
            FluxItemCurrencyTracking.MaintainItemCurrencySlotList(ic)
            FluxItemCurrencyTracking.NotifyItemCurrencyChanged()
            return true
        end
    end
    for s = 1, #ic.slots do
        if (ic.slots[s].itemId or 0) < 1 then
            ic.slots[s].itemId = itemId
            ic.slots[s].show = true
            FluxItemCurrencyTracking.MaintainItemCurrencySlotList(ic)
            FluxItemCurrencyTracking.NotifyItemCurrencyChanged()
            return true
        end
    end
    return false
end

--- Remove one slot (same as clearing in the Status Bar options), then refresh the bar and open config UI.
function FluxItemCurrencyTracking.ClearItemCurrencySlot(slotIndex)
    if type(slotIndex) ~= "number" or slotIndex < 1 then
        return
    end
    local ic = FluxItemCurrencyTracking.EnsureItemCurrencyData()
    if not ic or not ic.slots or not ic.slots[slotIndex] or slotIndex > #ic.slots then
        return
    end
    ic.slots[slotIndex].itemId = 0
    ic.slots[slotIndex].show = false
    FluxItemCurrencyTracking.MaintainItemCurrencySlotList(ic)
    FluxItemCurrencyTracking.NotifyItemCurrencyChanged()
end

-- Match FluxStatusBar / FluxPVPTracking number formatting
local function FormatNumber(number)
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 10000 then
        return string.format("%.0fK", number / 1000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

-- Icon resolve: cache + instant APIs first; RequestLoad only for tracked IDs that miss.
local ICON_FALLBACK = "Interface/Icons/INV_Misc_QuestionMark"
local iconCache = {} -- [itemID] = texture
local pendingIcons = {} -- [itemID] = true
local iconRefreshQueued = false
local loginIconRetryGen = 0

local function NormalizeIcon(tex)
    if type(tex) == "number" and tex > 0 then
        return tex
    end
    if type(tex) == "string" and tex ~= "" and tex ~= ICON_FALLBACK then
        return tex
    end
    return nil
end

local function RequestIconLoad(itemId, force)
    itemId = tonumber(itemId)
    if not itemId or itemId < 1 then
        return
    end
    if pendingIcons[itemId] and not force then
        return
    end
    pendingIcons[itemId] = true
    local IC = _G.FluxItemClass
    if IC and IC.RequestLoad then
        IC.RequestLoad(itemId)
    elseif C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemId)
    elseif GetItemInfo then
        -- Side-effect request on older clients.
        pcall(GetItemInfo, itemId)
    end
end

local function ResolveItemIcon(itemId)
    itemId = tonumber(itemId)
    if not itemId or itemId < 1 then
        return nil
    end
    local cached = iconCache[itemId]
    if cached then
        return cached
    end

    local IC = _G.FluxItemClass
    if IC then
        if IC.GetStatic then
            local st = IC.GetStatic(itemId)
            local tex = st and NormalizeIcon(st.icon)
            if tex then
                iconCache[itemId] = tex
                pendingIcons[itemId] = nil
                return tex
            end
        end
    end

    if C_Item and C_Item.GetItemIconByID then
        local ok, ic = pcall(C_Item.GetItemIconByID, itemId)
        local tex = ok and NormalizeIcon(ic)
        if tex then
            iconCache[itemId] = tex
            pendingIcons[itemId] = nil
            return tex
        end
    elseif GetItemIcon then
        local ok, ic = pcall(GetItemIcon, itemId)
        local tex = ok and NormalizeIcon(ic)
        if tex then
            iconCache[itemId] = tex
            pendingIcons[itemId] = nil
            return tex
        end
    end

    local GetInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
    if GetInstant then
        local r1, _, _, _, icon = GetInstant(itemId)
        local tex
        if type(r1) == "table" then
            tex = NormalizeIcon(r1.iconFileID or r1.icon or r1.itemIcon)
        else
            tex = NormalizeIcon(icon)
        end
        if tex then
            iconCache[itemId] = tex
            pendingIcons[itemId] = nil
            return tex
        end
    end

    if C_Item and C_Item.GetItemInfo then
        local info = C_Item.GetItemInfo(itemId)
        if type(info) == "table" then
            local tex = NormalizeIcon(info.iconFileID or info.itemIcon or info.iconID)
            if tex then
                iconCache[itemId] = tex
                pendingIcons[itemId] = nil
                return tex
            end
        end
    end
    if GetItemInfo then
        local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
        local tex = NormalizeIcon(itemTexture)
        if tex then
            iconCache[itemId] = tex
            pendingIcons[itemId] = nil
            return tex
        end
    end

    return nil
end

--- Public: resolve icon for a tracked currency item (bar + options). Requests load if missing.
function FluxItemCurrencyTracking.GetItemIcon(itemId, opts)
    opts = opts or {}
    itemId = tonumber(itemId)
    if not itemId or itemId < 1 then
        return ICON_FALLBACK
    end
    local tex = ResolveItemIcon(itemId)
    if tex then
        return tex
    end
    if opts.requestLoad ~= false then
        RequestIconLoad(itemId)
    end
    return ICON_FALLBACK
end

local function GetItemIconFileIDOrPath(itemId)
    return FluxItemCurrencyTracking.GetItemIcon(itemId)
end

local function IsTrackedCurrencyItem(itemId)
    itemId = tonumber(itemId)
    if not itemId or itemId < 1 then
        return false
    end
    if pendingIcons[itemId] then
        return true
    end
    local ic = FluxItemCurrencyTracking.EnsureItemCurrencyData()
    local slots = ic and ic.slots
    if not slots then
        return false
    end
    for i = 1, #slots do
        local row = slots[i]
        if row and tonumber(row.itemId) == itemId then
            return true
        end
    end
    return false
end

local function ScheduleTrackedIconRefresh()
    if iconRefreshQueued then
        return
    end
    iconRefreshQueued = true
    local after = (C_Timer and C_Timer.After) or function(_, fn) fn() end
    after(0.12, function()
        iconRefreshQueued = false
        if _G.UpdateGoldBar then
            pcall(_G.UpdateGoldBar)
        end
        if FluxItemCurrencyTracking._RefreshSlotsUIFromAce then
            pcall(FluxItemCurrencyTracking._RefreshSlotsUIFromAce)
        end
    end)
end

--- Soft login retries only while tracked icons are still pending (no portal spam).
function FluxItemCurrencyTracking.EnsureTrackedIconsLoaded(isLogin)
    local ic = FluxItemCurrencyTracking.EnsureItemCurrencyData()
    if not ic or not ic.enabled or not ic.slots then
        return
    end
    local anyPending = false
    for i = 1, #ic.slots do
        local row = ic.slots[i]
        local id = row and tonumber(row.itemId)
        if id and id > 0 then
            if not ResolveItemIcon(id) then
                RequestIconLoad(id, isLogin and true or false)
                anyPending = true
            end
        end
    end
    if not anyPending or not isLogin then
        return
    end
    loginIconRetryGen = loginIconRetryGen + 1
    local gen = loginIconRetryGen
    local after = (C_Timer and C_Timer.After) or function(_, fn) fn() end
    after(0.5, function()
        if gen ~= loginIconRetryGen then
            return
        end
        if next(pendingIcons) then
            for id in pairs(pendingIcons) do
                RequestIconLoad(id, true)
            end
            ScheduleTrackedIconRefresh()
        end
    end)
    after(2.0, function()
        if gen ~= loginIconRetryGen then
            return
        end
        if next(pendingIcons) then
            for id in pairs(pendingIcons) do
                RequestIconLoad(id, true)
            end
            ScheduleTrackedIconRefresh()
        end
    end)
end

--- Kept for compatibility: item counts are drawn by LayoutGoldItemHovers (enables per-item tooltips).
function FluxItemCurrencyTracking.GetText()
    return ""
end

--- Total width of money (GoldBar.text) + gap + GoldBar.suffixText when the suffix is used.
function FluxItemCurrencyTracking.GetGoldTextBlockWidth(goldBar)
    local t = goldBar and goldBar.text
    if not t then
        return 0
    end
    pcall(function()
        if t.SetWidth then
            t:SetWidth(0)
        end
    end)
    local st = goldBar.suffixText
    if st and st.SetWidth then
        pcall(function()
            st:SetWidth(0)
        end)
    end
    local twM = (t.GetStringWidth and t:GetStringWidth()) or 0
    if st
        and st.GetStringWidth
        and st.GetText
        and st:GetText()
        and st:GetText() ~= ""
        and (not st.IsShown or st:IsShown()) then
        return twM + 2 + (st:GetStringWidth() or 0)
    end
    return twM
end

--- Match count labels to the gold strip font (same as GoldBar.text in FluxStatusBar.lua).
local function ApplyGoldBarFontToItemCount(goldBar, countStr)
    if not countStr or not countStr.SetFont or not goldBar or not goldBar.text then
        return
    end
    local font, size, flags = goldBar.text:GetFont()
    if font then
        pcall(function()
            countStr:SetFont(font, size, flags)
        end)
    end
    if countStr.SetTextColor then
        countStr:SetTextColor(1, 1, 1, 1)
    end
    if countStr.SetJustifyV then
        countStr:SetJustifyV("MIDDLE")
    end
    if countStr.SetJustifyH then
        countStr:SetJustifyH("RIGHT")
    end
end

-- Center the whole "money + game currencies + honor" line together with item icons: one block, horizontally centered
-- on the bar, with item segments immediately to the right of the string (not pinned to the bar's far right edge).
function FluxItemCurrencyTracking.AnchorGoldBarTextBlock(goldBar, itemHostW)
    local t = goldBar and goldBar.text
    if not t then
        return
    end
    local st = goldBar.suffixText
    t:ClearAllPoints()
    if st and st.ClearAllPoints then
        pcall(function()
            st:ClearAllPoints()
        end)
    end
    local wHost = (type(itemHostW) == "number" and itemHostW) or 0
    pcall(function()
        if t.SetWidth then
            t:SetWidth(0)
        end
    end)
    if st and st.SetWidth then
        pcall(function()
            st:SetWidth(0)
        end)
    end
    local hBarH = 18
    if goldBar.GetHeight then
        hBarH = goldBar:GetHeight() or 18
    end
    if type(hBarH) ~= "number" or hBarH < 1 then
        hBarH = 18
    end
    hBarH = math.max(10, hBarH)
    local hasSuffix = st
        and st.GetText
        and st.GetStringWidth
        and st:GetText()
        and st:GetText() ~= ""
        and (not st.IsShown or st:IsShown())
    local function moneyWidth()
        local a = (t.GetStringWidth and t:GetStringWidth()) or 0
        if a < 0.1 then
            a = 1
        end
        return a
    end
    local function lineWidth()
        local twM = moneyWidth()
        if hasSuffix and st and st.GetStringWidth then
            return twM + 2 + (st:GetStringWidth() or 0)
        end
        return twM
    end
    local function layoutCenteredTextBlock()
        local barW = (goldBar.GetWidth and goldBar:GetWidth()) or 0
        if barW < 4 then
            barW = 200
        end
        local block = lineWidth()
        local left = (barW - block) * 0.5
        if left < 2 then
            left = 2
        end
        if left + block > barW - 2 then
            left = math.max(2, barW - 2 - block)
        end
        local twM = moneyWidth()
        t:SetPoint("TOPLEFT", goldBar, "TOPLEFT", left, 0)
        t:SetSize(twM, hBarH)
        t:SetJustifyH("LEFT")
        t:SetJustifyV("MIDDLE")
        if hasSuffix and st then
            pcall(function()
                st:SetPoint("TOPLEFT", t, "TOPRIGHT", 2, 0)
                st:SetSize(st:GetStringWidth() or 1, hBarH)
                st:SetJustifyH("LEFT")
                st:Show()
            end)
        elseif st and st.Hide then
            pcall(function()
                st:Hide()
            end)
        end
    end
    if wHost < 2 or not goldBar._fluxICHost then
        layoutCenteredTextBlock()
        return
    end
    local barW = (goldBar.GetWidth and goldBar:GetWidth()) or 0
    if barW < 4 then
        barW = 200
    end
    local tw = lineWidth()
    if tw < 0.1 then
        tw = 1
    end
    local pad = 4
    local totalW = tw + pad + wHost
    local left = (barW - totalW) * 0.5
    if left < 2 then
        left = 2
    end
    if left + totalW > barW - 2 then
        left = math.max(2, barW - 2 - totalW)
    end
    local twM = moneyWidth()
    t:SetPoint("TOPLEFT", goldBar, "TOPLEFT", left, 0)
    t:SetSize(twM, hBarH)
    t:SetJustifyH("LEFT")
    t:SetJustifyV("MIDDLE")
    if hasSuffix and st then
        pcall(function()
            st:SetPoint("TOPLEFT", t, "TOPRIGHT", 2, 0)
            st:SetSize((st.GetStringWidth and st:GetStringWidth()) or 1, hBarH)
            st:SetJustifyH("LEFT")
            st:Show()
        end)
    elseif st and st.Hide then
        pcall(function()
            st:Hide()
        end)
    end
    local host = goldBar._fluxICHost
    host:ClearAllPoints()
    if host.SetSize then
        host:SetSize(wHost, hBarH)
    end
    if host.SetPoint then
        host:SetPoint("TOPLEFT", goldBar, "TOPLEFT", left + tw + pad, 0)
    end
end

--- Place interactive segments to the right of the gold / honor / currency string (one centered block, not at the far edge).
function FluxItemCurrencyTracking.LayoutGoldItemHovers(goldBar, onItemDrop)
    if not goldBar or not goldBar.text then
        return
    end
    local ic = FluxItemCurrencyTracking.EnsureItemCurrencyData()

    local hBar = 18
    if goldBar.GetHeight then
        hBar = goldBar:GetHeight() or 18
    elseif goldBar.GetSize then
        local w0, h0 = goldBar:GetSize()
        if type(h0) == "number" and h0 > 0 then
            hBar = h0
        end
    end
    hBar = math.max(10, hBar)
    if goldBar._fluxICHost and (not goldBar._fluxICItemScroll) then
        pcall(goldBar._fluxICHost.Hide, goldBar._fluxICHost)
        pcall(goldBar._fluxICHost.SetParent, goldBar._fluxICHost, nil)
        goldBar._fluxICHost = nil
    end
    if not goldBar._fluxICItemScroll then
        local sc = CreateFrame("ScrollFrame", "FluxGoldBarICScroll", goldBar)
        local c = CreateFrame("Frame", "FluxGoldBarICItemContent", sc)
        sc:SetScrollChild(c)
        c:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, 0)
        c._itemBtns = {}
        sc:EnableMouse(true)
        pcall(function()
            sc:EnableMouseWheel(true)
        end)
        sc:SetScript("OnMouseWheel", function(self, d)
            local n = d or 0
            if n == 0 then
                return
            end
            local rng = (self.GetHorizontalScrollRange and self:GetHorizontalScrollRange()) or 0
            if rng < 0.5 then
                return
            end
            local cur = (self.GetHorizontalScroll and self:GetHorizontalScroll()) or 0
            local step = 20 * (n > 0 and 1 or -1)
            local m = rng
            pcall(self.SetHorizontalScroll, self, math.max(0, math.min(m, cur - step)))
        end)
        if sc.SetFrameStrata then
            sc:SetFrameStrata("MEDIUM")
        end
        if sc.SetFrameLevel and goldBar.GetFrameLevel then
            sc:SetFrameLevel(goldBar:GetFrameLevel() + 3)
        end
        goldBar._fluxICItemScroll = sc
        goldBar._fluxICItemContent = c
        goldBar._fluxICHost = sc
    end
    local sc = goldBar._fluxICItemScroll
    local content = goldBar._fluxICItemContent
    if not sc or not content or not content._itemBtns then
        return
    end
    sc:ClearAllPoints()
    for i = 1, MAX_ITEM_CURRENCY_BUTTONS do
        local b = content._itemBtns[i]
        if b and b.Hide then
            b:Hide()
        end
    end
    if not ic or not ic.enabled then
        pcall(sc.Hide, sc)
        FluxItemCurrencyTracking.AnchorGoldBarTextBlock(goldBar, 0)
        return
    end
    local segments = {}
    for s = 1, (ic.slots and #ic.slots or 0) do
        local row = ic.slots and ic.slots[s]
        if row and type(row.itemId) == "number" and row.itemId > 0 then
            local id = row.itemId
            local c = 0
            local inv = _G.FluxInv
            if inv and inv.GetLiveCount then
                c = inv.GetLiveCount(id, { includeBank = false, charges = true, bags = true, equipped = true }) or 0
            elseif inv and inv.GetCount then
                c = inv.GetCount(id, {
                    bags = true,
                    bank = false,
                    warband = false,
                    equipped = true,
                    charges = true,
                }) or 0
            elseif _G.FluxGetItemCount then
                c = _G.FluxGetItemCount(id, { includeBank = false, charges = true }) or 0
            elseif GetItemCount then
                c = GetItemCount(id) or 0
            end
            table.insert(segments, { itemId = id, count = c, slot = s })
        end
    end
    if #segments < 1 then
        pcall(sc.Hide, sc)
        FluxItemCurrencyTracking.AnchorGoldBarTextBlock(goldBar, 0)
        return
    end

    content._goldBar = goldBar
    goldBar._fluxICOnItemDrop = onItemDrop
    local x = 0
    for k, seg in ipairs(segments) do
        local id = seg.itemId
        local c = seg.count
        local btn = content._itemBtns[k]
        if not btn then
            btn = CreateFrame("Button", "FluxGBarIt" .. k, content)
            btn:SetToplevel(false)
            btn:EnableMouse(true)
            pcall(function()
                btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            end)
            pcall(function()
                btn:RegisterForDrag("LeftButton")
            end)
            btn._icon = btn:CreateTexture(nil, "ARTWORK")
            btn._icon:SetSize(16, 16)
            btn._icon:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
            btn._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            btn.countStr = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.countStr:SetPoint("RIGHT", btn._icon, "LEFT", -2, 0)
            -- Flux idle FPS: install scripts once; read btn._itemId / _slotIdx / host drop fn.
            btn:SetScript("OnEnter", function(self)
                local itemId = self._itemId
                if not itemId or not GameTooltip or not GameTooltip.SetOwner then
                    return
                end
                GameTooltip:Hide()
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                if GameTooltip.SetItemByID then
                    pcall(function()
                        GameTooltip:SetItemByID(itemId)
                    end)
                elseif GetItemInfo and GameTooltip.SetHyperlink then
                    local _, l = GetItemInfo(itemId)
                    if l then
                        pcall(GameTooltip.SetHyperlink, GameTooltip, l)
                    else
                        pcall(function()
                            if GameTooltip.ClearLines then
                                GameTooltip:ClearLines()
                            end
                        end)
                        GameTooltip:AddLine("Item " .. tostring(itemId), 1, 1, 1)
                    end
                else
                    GameTooltip:SetText("Item " .. tostring(itemId), 1, 1, 1)
                end
                if GameTooltip.AddLine then
                    GameTooltip:AddLine("Right-click: remove from bar. Mouse wheel: scroll if icons are clipped.", 0.65, 0.7, 0.75, true)
                end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function()
                if GameTooltip then
                    GameTooltip:Hide()
                end
            end)
            btn:SetScript("OnMouseUp", function(self, bname)
                if bname == "RightButton" or bname == "RightButtonUp" then
                    local slotIdx = self._slotIdx
                    if slotIdx and FluxItemCurrencyTracking.ClearItemCurrencySlot then
                        FluxItemCurrencyTracking.ClearItemCurrencySlot(slotIdx)
                    end
                    return
                end
                local gb = content._goldBar
                local dropFn = gb and gb._fluxICOnItemDrop
                if (bname == "LeftButton" or bname == "LeftButtonUp")
                    and dropFn
                    and GetCursorInfo
                    and select(1, GetCursorInfo()) == "item" then
                    dropFn()
                end
            end)
            btn:SetScript("OnReceiveDrag", function()
                local gb = content._goldBar
                local dropFn = gb and gb._fluxICOnItemDrop
                if dropFn then
                    dropFn()
                end
            end)
            content._itemBtns[k] = btn
        end
        btn._itemId = id
        btn._slotIdx = seg.slot
        ApplyGoldBarFontToItemCount(goldBar, btn.countStr)
        local btnW = 4 + 8 * (math.min(8, tostring(FormatNumber(c)):len() + 2)) + 18
        btnW = math.max(40, math.min(110, btnW))
        btn:SetSize(btnW, hBar)
        local tx = GetItemIconFileIDOrPath(id)
        btn._icon:SetTexture(tx)
        btn._icon:Show()
        btn.countStr:SetText(FormatNumber(c))
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", x, 0)
        local lvl = (goldBar.GetFrameLevel and goldBar:GetFrameLevel() or 2) + 4
        if btn.SetFrameLevel then
            btn:SetFrameLevel(lvl)
        end
        x = x + btnW + 1
        btn:Show()
    end
    local contentW = math.max(1, x - 1)
    content:SetSize(contentW, hBar)
    local barW = (goldBar.GetWidth and goldBar:GetWidth()) or 0
    if barW < 2 then
        barW = 500
    end
    local tw = 0
    if FluxItemCurrencyTracking.GetGoldTextBlockWidth then
        tw = FluxItemCurrencyTracking.GetGoldTextBlockWidth(goldBar) or 0
    elseif goldBar.text and goldBar.text.GetStringWidth then
        tw = goldBar.text:GetStringWidth() or 0
    end
    local margin = 4
    local viewCap = barW - tw - 4 - margin * 2
    if viewCap < 32 then
        viewCap = math.max(32, (barW - 20) * 0.3)
    end
    local viewW = math.min(contentW, viewCap)
    pcall(function()
        sc:SetSize(viewW, hBar)
    end)
    pcall(function()
        if contentW <= viewW + 0.5 and sc.SetHorizontalScroll then
            sc:SetHorizontalScroll(0)
        else
            local m = (sc.GetHorizontalScrollRange and sc:GetHorizontalScrollRange()) or 0
            if m < 0 then
                m = math.max(0, contentW - viewW)
            end
            if m >= 0 and sc.GetHorizontalScroll and sc.SetHorizontalScroll then
                sc:SetHorizontalScroll(math.min(m, sc:GetHorizontalScroll() or 0))
            end
        end
    end)
    pcall(sc.Show, sc)
    FluxItemCurrencyTracking.AnchorGoldBarTextBlock(goldBar, viewW)
end

-- Async icon resolve: only refresh when a tracked / pending currency item loads.
if CreateFrame then
    local infoFrame = CreateFrame("Frame", "FluxItemCurrencyInfoFrame", UIParent)
    local sessionSawLoginPew = false
    if infoFrame and infoFrame.RegisterEvent then
        infoFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
            if event == "PLAYER_ENTERING_WORLD" then
                local isLogin = (arg1 == true or arg2 == true) or not sessionSawLoginPew
                sessionSawLoginPew = true
                if FluxItemCurrencyTracking.EnsureTrackedIconsLoaded then
                    FluxItemCurrencyTracking.EnsureTrackedIconsLoaded(isLogin)
                end
                return
            end
            -- GET_ITEM_INFO_RECEIVED(itemID, success) / ITEM_DATA_LOAD_RESULT(itemID, success)
            local itemID = tonumber(arg1)
            if not itemID then
                return
            end
            if not IsTrackedCurrencyItem(itemID) then
                return
            end
            if arg2 == false then
                pendingIcons[itemID] = nil
                return
            end
            iconCache[itemID] = nil
            pendingIcons[itemID] = nil
            -- Re-resolve; if still missing, keep pending for login retries.
            if not ResolveItemIcon(itemID) then
                RequestIconLoad(itemID)
            end
            ScheduleTrackedIconRefresh()
        end)
        pcall(function()
            infoFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        end)
        pcall(function()
            infoFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
        end)
        pcall(function()
            infoFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        end)
    end
end

-- Bag/equip count changes via FluxInv (no direct bag walks)
do
    -- Tracked item counts are the only bag facts on the gold strip.
    local function AnyTrackedItemChanged(changedItemIDs)
        for itemId in pairs(changedItemIDs) do
            if IsTrackedCurrencyItem(itemId) then
                return true
            end
        end
        return false
    end
    local function RefreshGoldBarFromInv(ctx)
        local changed = ctx and ctx.changedItemIDs
        if changed and not AnyTrackedItemChanged(changed) then
            return
        end
        if _G.UpdateGoldBar then
            pcall(_G.UpdateGoldBar)
        end
    end
    local function TryRegister()
        local inv = _G.FluxInv
        if inv and inv.RegisterListener then
            inv.RegisterListener("FluxItemCurrencyTracking", RefreshGoldBarFromInv, {
                tier = "instant",
                regions = { "bags", "equip" },
            })
            -- One gold-strip refresh per pulse: this listener replaces the
            -- status bar's own bag listener.
            FluxItemCurrencyTracking.invListenerRegistered = true
            if inv.UnregisterListener then
                inv.UnregisterListener("FluxStatusBar_GoldBar")
            end
            return true
        end
        return false
    end
    if not TryRegister() then
        local boot = CreateFrame("Frame")
        boot:RegisterEvent("PLAYER_LOGIN")
        boot:SetScript("OnEvent", function(self)
            if TryRegister() then
                self:UnregisterAllEvents()
            end
        end)
    end
end

