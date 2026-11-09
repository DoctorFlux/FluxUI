-- Cursor loot alerts and optional fast pickup. Inspired by Looti's event coverage
-- (Finlay McKinnon, MIT) and the installed FasterLoot 20261016 behavior. No code
-- or saved variables from either addon are imported.
local addonName, ns = ...
local Item = ns.Flux and ns.Flux.Item
local MAX_ROWS, PICKUP_DELAY = 3, 0.3
local SESSION_TTL, MAX_SESSIONS = 30, 32
local rows, pool, seen = {}, {}, {}
local sincePickup = -100
local claimsSinceSweep = 0
local originSerial = 0
local anchor = CreateFrame("Frame", nil, UIParent)
anchor:SetSize(250, 1)
anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
anchor:EnableMouse(false)
anchor:Hide()

local function Settings()
    return FluxOptions and FluxOptions.db and FluxOptions.db.profile and FluxOptions.db.profile.loot
end

local function Readable(value)
    return type(value) == "string" and not (issecretvalue and issecretvalue(value))
end

local function CursorOrigin()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = (x or 0) / scale, (y or 0) / scale
    x = math.max(0, math.min(x + 24, UIParent:GetWidth() - 250))
    y = math.max(72, math.min(y - 20, UIParent:GetHeight()))
    originSerial = originSerial + 1
    return { x = x, y = y, id = originSerial }
end

local function MakeRow()
    local row = CreateFrame("Frame", nil, UIParent)
    row:SetSize(250, 28)
    row:EnableMouse(false)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(22, 22)
    row.icon:SetPoint("LEFT", row, "LEFT", 1, 0)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
    row.text:SetWidth(220)
    row.text:SetJustifyH("LEFT")
    return row
end

local function Reflow()
    local offsets = {}
    for _, row in ipairs(rows) do
        local key = row.origin.x .. ":" .. row.origin.y
        local offset = offsets[key] or 0
        offsets[key] = offset + 1
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", row.origin.x, row.origin.y - offset * 29)
    end
end

local function Show(textValue, icon, quality, whiteText, origin)
    local db = Settings()
    if not db or not db.alerts or not Readable(textValue) then return end
    if issecretvalue and issecretvalue(quality) then quality = nil end
    if issecretvalue and issecretvalue(icon) then icon = nil end
    if quality and quality < (db.quality or 0) then return end
    local row = table.remove(pool) or (#rows >= MAX_ROWS and table.remove(rows, MAX_ROWS)) or MakeRow()
    table.insert(rows, 1, row)
    row.origin = origin or CursorOrigin()
    row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Bag_10")
    row.text:SetText(textValue)
    if whiteText then
        row.text:SetTextColor(1, 1, 1)
    elseif quality and GetItemQualityColor then
        local r, g, b = GetItemQualityColor(quality)
        row.text:SetTextColor(r or 1, g or 1, b or 1)
    else
        row.text:SetTextColor(1, 0.82, 0)
    end
    row.deadline = GetTime() + (db.duration or 3)
    Reflow()
    row:Show()
    anchor:Show()
end

anchor:SetScript("OnUpdate", function(self)
    local now = GetTime()
    local changed = false
    for index = #rows, 1, -1 do
        local row = rows[index]
        if row.deadline > now then
            row:SetAlpha(math.min(1, (row.deadline - now) * 2))
        else
            row:Hide()
            row.deadline = nil
            table.remove(rows, index)
            pool[#pool + 1] = row
            changed = true
        end
    end
    if changed then
        Reflow()
    end
    if #rows == 0 then self:Hide() end
end)

local function ItemKey(link, count)
    local id = link:match("|Hitem:(%d+)") or link
    return id .. ":" .. tostring(count or 1)
end

-- A slot and its chat line are two reports of one pickup. Opposite reports
-- cancel one another; repeated pickups of the same stack still each show.
local function Claim(link, count, source, origin)
    local key, now = ItemKey(link, count), GetTime()
    if origin then key = origin.id .. ":" .. key end
    -- Chat-only rewards can arrive without LOOT_CLOSED. Expire old tokens.
    claimsSinceSweep = claimsSinceSweep + 1
    if claimsSinceSweep >= 32 then
        claimsSinceSweep = 0
        for oldKey, old in pairs(seen) do
            if old.untilTime < now then seen[oldKey] = nil end
        end
    end
    local entry = seen[key]
    if not entry or entry.untilTime < now then
        entry = { slot = 0, chat = 0, untilTime = now + (origin and 30 or 4) }
        seen[key] = entry
    end
    local opposite = source == "slot" and "chat" or "slot"
    if entry[opposite] > 0 then
        entry[opposite] = entry[opposite] - 1
        return false
    end
    entry[source] = entry[source] + 1
    entry.untilTime = now + (origin and 30 or 4)
    return true
end

local function NotifyItem(link, count, source, origin)
    if type(count) ~= "number" or (issecretvalue and issecretvalue(count)) then count = 1 end
    if not Readable(link) or not Claim(link, count, source, origin) then return end
    local name, _, quality, _, _, _, _, _, _, icon
    if Item and Item.GetInfo then
        name, _, quality, _, _, _, _, _, _, icon = Item.GetInfo(link)
    end
    local label = (Readable(name) and name) or link:match("|h%[(.-)%]|h") or link
    if count and count > 1 then label = label .. " x" .. count end
    Show(label, icon or (Item and Item.GetIcon and Item.GetIcon(link)), quality, nil, origin)
end

local formats = {
    { "LOOT_ITEM_SELF_MULTIPLE", true }, { "LOOT_ITEM_SELF", true },
    { "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE", false },
    { "LOOT_ITEM_BONUS_ROLL_SELF", false },
}

local function ExpandForms(textValue)
    local forms = { textValue }
    for _ = 1, 4 do
        local expanded, changed = {}, false
        for _, form in ipairs(forms) do
            local before, choices, after = form:match("^(.-)|4([^;]*);(.*)$")
            if choices then
                changed = true
                for choice in (choices .. ":"):gmatch("([^:]*):") do
                    expanded[#expanded + 1] = before .. choice .. after
                end
            else
                local prefix, first, second, suffix = form:match("^(.-)|1([^;]*);([^;]*);(.*)$")
                if first then
                    changed = true
                    expanded[#expanded + 1] = prefix .. first .. suffix
                    expanded[#expanded + 1] = prefix .. second .. suffix
                else
                    expanded[#expanded + 1] = form
                end
            end
        end
        forms = expanded
        if not changed then break end
    end
    return forms
end

local function CompilePattern(formatText, anchored)
    local kinds = {}
    local pattern = formatText:gsub("%%[%d%$]*[sd]", function(token)
        local kind = token:sub(-1)
        kinds[#kinds + 1] = kind
        return kind == "d" and "\002" or "\001"
    end)
    pattern = pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        :gsub("\001", "(.+)"):gsub("\002", "(%%d+)")
    return (anchored and "^" or "") .. pattern .. (anchored and "$" or ""), kinds
end

local selfPatterns = {}
for _, spec in ipairs(formats) do
    local formatText = _G[spec[1]]
    if type(formatText) == "string" then
        for _, form in ipairs(ExpandForms(formatText)) do
            local pattern, kinds = CompilePattern(form, true)
            local countIndex
            for index, kind in ipairs(kinds) do
                if kind == "d" then countIndex = index; break end
            end
            selfPatterns[#selfPatterns + 1] = {
                pattern = pattern, countIndex = countIndex, needsWindow = spec[2],
            }
        end
    end
end

local moneyMessages = {}
for _, key in ipairs({ "YOU_LOOT_MONEY_GUILD", "YOU_LOOT_MONEY", "LOOT_MONEY_SPLIT_GUILD", "LOOT_MONEY_SPLIT_MOD", "LOOT_MONEY_SPLIT" }) do
    local formatText = _G[key]
    if type(formatText) == "string" then
        for _, form in ipairs(ExpandForms(formatText)) do
            local pattern, kinds = CompilePattern(form, true)
            local amountIndices = {}
            for index, kind in ipairs(kinds) do
                if kind == "s" then
                    amountIndices[#amountIndices + 1] = index
                end
            end
            if #amountIndices > 0 then
                moneyMessages[#moneyMessages + 1] = { pattern = pattern, amountIndices = amountIndices }
            end
        end
    end
end

local moneyUnits = {}
for _, unit in ipairs({ { "GOLD_AMOUNT", 10000 }, { "SILVER_AMOUNT", 100 }, { "COPPER_AMOUNT", 1 } }) do
    local formatText = _G[unit[1]]
    local patterns = {}
    if type(formatText) == "string" then
        for _, form in ipairs(ExpandForms(formatText)) do
            patterns[#patterns + 1] = CompilePattern(form, false)
        end
    end
    moneyUnits[#moneyUnits + 1] = { value = unit[2], patterns = patterns }
end

local function ParseMoney(message)
    if not Readable(message) then return nil end
    for _, form in ipairs(moneyMessages) do
        local values = { message:match(form.pattern) }
        for _, index in ipairs(form.amountIndices) do
            local amount = values[index]
            if amount then
                local copper = 0
                for _, unit in ipairs(moneyUnits) do
                    for _, pattern in ipairs(unit.patterns) do
                        local quantity = tonumber(amount:match(pattern))
                        if quantity then
                            copper = copper + quantity * unit.value
                            break
                        end
                    end
                end
                if copper > 0 then return copper end
            end
        end
    end
    return nil
end

local COIN = "Interface\\MoneyFrame\\UI-"
local function MoneyDisplay(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor(copper % 10000 / 100)
    local small = copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. "|T" .. COIN .. "GoldIcon:0:0:2:0|t" end
    if silver > 0 then parts[#parts + 1] = silver .. "|T" .. COIN .. "SilverIcon:0:0:2:0|t" end
    if small > 0 then parts[#parts + 1] = small .. "|T" .. COIN .. "CopperIcon:0:0:2:0|t" end
    local icon = copper >= 10000 and "GoldIcon" or (copper >= 100 and "SilverIcon" or "CopperIcon")
    return table.concat(parts, " "), COIN .. icon
end

local function SelfLootCount(message)
    if not Readable(message) then return nil end
    for _, form in ipairs(selfPatterns) do
        local values = { message:match(form.pattern) }
        if values[1] then
            return form.countIndex and (tonumber(values[form.countIndex]) or 1) or 1,
                form.needsWindow
        end
    end
    return nil
end

local captured = {}
local lootWindowOpen, lootWindowStarted, lootWindowClosed = false, -100, -100
local lootOrigin
local sessions, activeSession = {}, nil

local function PruneSessions()
    local now = GetTime()
    for index = #sessions, 1, -1 do
        local session = sessions[index]
        if session ~= activeSession and session.expires < now then
            table.remove(sessions, index)
        end
    end
    while #sessions > MAX_SESSIONS do table.remove(sessions, 1) end
end

local function StartLootWindow()
    if not lootWindowOpen then
        wipe(captured)
        lootOrigin = CursorOrigin()
        activeSession = {
            origin = lootOrigin, expires = GetTime() + SESSION_TTL,
            expectedSlots = 0, knownSlots = 0, slotKnown = {},
            items = {}, chatAssigned = {}, fallbackUsed = 0,
            currencies = {}, currencyAssigned = {},
            moneySlot = false, moneyAssigned = false,
        }
        sessions[#sessions + 1] = activeSession
        PruneSessions()
    end
    lootWindowOpen, lootWindowStarted = true, GetTime()
end
local function RecentLootWindow()
    local now = GetTime()
    return (lootWindowOpen and now - lootWindowStarted <= 60)
        or now - lootWindowClosed <= 1
end

local function Capture()
    if not (GetNumLootItems and GetLootSlotLink and GetLootSlotInfo) then return end
    local count = GetNumLootItems()
    if activeSession then
        activeSession.expectedSlots = math.max(activeSession.expectedSlots, count)
    end
    for slot = 1, count do
        if activeSession and GetLootSlotType and LOOT_SLOT_MONEY
            and GetLootSlotType(slot) == LOOT_SLOT_MONEY then
            activeSession.moneySlot = true
            if not activeSession.slotKnown[slot] then
                activeSession.slotKnown[slot] = true
                activeSession.knownSlots = activeSession.knownSlots + 1
            end
        end
        if not captured[slot] then
            local link = GetLootSlotLink(slot)
            if Readable(link) and link:find("|Hitem:", 1, true) then
                local _, _, count = GetLootSlotInfo(slot)
                count = (type(count) == "number" and not (issecretvalue and issecretvalue(count))) and count or 1
                captured[slot] = { link = link, count = count, session = activeSession }
                if activeSession and not activeSession.slotKnown[slot] then
                    activeSession.slotKnown[slot] = true
                    activeSession.knownSlots = activeSession.knownSlots + 1
                    local key = ItemKey(link, count)
                    activeSession.items[key] = (activeSession.items[key] or 0) + 1
                end
            elseif Readable(link) and activeSession then
                local currencyID = link:match("|Hcurrency:(%d+)")
                if currencyID and not activeSession.slotKnown[slot] then
                    activeSession.currencies[currencyID] = (activeSession.currencies[currencyID] or 0) + 1
                    activeSession.slotKnown[slot] = true
                    activeSession.knownSlots = activeSession.knownSlots + 1
                end
            end
        end
    end
end

local function MatchItemSession(link, count)
    PruneSessions()
    local key = ItemKey(link, count)
    for _, session in ipairs(sessions) do
        local assigned = session.chatAssigned[key] or 0
        if (session.items[key] or 0) > assigned then
            session.chatAssigned[key] = assigned + 1
            return session
        end
    end
    -- Another addon may empty the window before GetLootSlotLink can see it.
    for _, session in ipairs(sessions) do
        local unknown = session.expectedSlots - session.knownSlots
        if session.expectedSlots == 0 then unknown = 1 end
        if session.fallbackUsed < unknown then
            session.fallbackUsed = session.fallbackUsed + 1
            return session
        end
    end
    return nil
end

local function MatchCurrencySession(currencyID)
    PruneSessions()
    if currencyID then
        for _, session in ipairs(sessions) do
            local assigned = session.currencyAssigned[currencyID] or 0
            if (session.currencies[currencyID] or 0) > assigned then
                session.currencyAssigned[currencyID] = assigned + 1
                return session
            end
        end
    end
    if RecentLootWindow() then return activeSession or sessions[#sessions] end
    return nil
end

local function MatchMoneySession()
    PruneSessions()
    for _, session in ipairs(sessions) do
        if session.moneySlot and not session.moneyAssigned then
            session.moneyAssigned = true
            return session
        end
    end
    if RecentLootWindow() then return activeSession or sessions[#sessions] end
    return nil
end

local function ExternalFasterLoot()
    if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded("FasterLoot") end
    return IsAddOnLoaded and IsAddOnLoaded("FasterLoot")
end

local function FastPickup()
    local db = Settings()
    if not db or not db.fast or ExternalFasterLoot() then return end
    if not (GetCVarBool and IsModifiedClick and GetNumLootItems and LootSlot) then return end
    if GetCVarBool("autoLootDefault") == IsModifiedClick("AUTOLOOTTOGGLE") then return end
    local now = GetTime()
    if now - sincePickup < PICKUP_DELAY then return end
    local destroy = _G.TSMDestroyBtn
    if destroy and destroy:IsShown() and destroy:GetButtonState() == "DISABLED" then
        sincePickup = now
        return
    end
    for slot = GetNumLootItems(), 1, -1 do LootSlot(slot) end
    sincePickup = now
end

FluxLoot = FluxLoot or {}
local eventFrame = CreateFrame("Frame")
function FluxLoot:Refresh()
    local db = Settings()
    eventFrame:UnregisterAllEvents()
    if not db then return end
    if (db.fast and not ExternalFasterLoot()) or db.alerts then eventFrame:RegisterEvent("LOOT_READY") end
    if db.alerts then
        for _, event in ipairs({ "LOOT_OPENED", "LOOT_SLOT_CLEARED", "LOOT_CLOSED", "LOOT_ITEM_ROLL_WON", "CHAT_MSG_LOOT", "CHAT_MSG_MONEY", "CHAT_MSG_CURRENCY" }) do
            eventFrame:RegisterEvent(event)
        end
    else
        lootWindowOpen, lootWindowStarted, lootWindowClosed = false, -100, -100
        lootOrigin = nil
        activeSession = nil
        wipe(sessions)
        anchor:Hide()
        for index = #rows, 1, -1 do
            local row = table.remove(rows, index)
            row:Hide()
            row.deadline = nil
            pool[#pool + 1] = row
        end
        wipe(captured)
        wipe(seen)
    end
end

function FluxLoot:Preview()
    Show("FluxUI loot preview", "Interface\\Icons\\INV_Misc_Bag_10", 0)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local db = Settings()
    if not db then return end
    if event == "LOOT_READY" then
        if db.alerts then
            StartLootWindow()
            Capture()
        end
        FastPickup()
    elseif event == "LOOT_OPENED" then
        StartLootWindow()
        Capture()
    elseif event == "LOOT_SLOT_CLEARED" then
        local slot = ...
        local data = captured[slot]
        if data then
            captured[slot] = nil
            NotifyItem(data.link, data.count, "slot", data.session and data.session.origin)
        end
    elseif event == "LOOT_CLOSED" then
        lootWindowOpen, lootWindowClosed = false, GetTime()
        if activeSession then activeSession.expires = GetTime() + SESSION_TTL end
        activeSession = nil
        for key, entry in pairs(seen) do
            if entry.untilTime < GetTime() then seen[key] = nil end
        end
    elseif event == "LOOT_ITEM_ROLL_WON" then
        local link, count = ...
        NotifyItem(link, count or 1, "slot")
    elseif event == "CHAT_MSG_LOOT" then
        local message = ...
        local count, needsWindow = SelfLootCount(message)
        if count then
            local link = message:match("(|Hitem:.-|h%[.-%]|h)")
            if link then
                local session = needsWindow and MatchItemSession(link, count) or nil
                if not needsWindow or session then
                    NotifyItem(link, count, "chat", session and session.origin)
                end
            end
        end
    elseif event == "CHAT_MSG_MONEY" and db.money then
        local copper = ParseMoney(...)
        if copper then
            local amount, icon = MoneyDisplay(copper)
            local session = MatchMoneySession()
            Show(amount, icon, nil, true, session and session.origin)
        end
    elseif event == "CHAT_MSG_CURRENCY" and db.currency then
        local message = ...
        if Readable(message) then
            local currencyID = message:match("|Hcurrency:(%d+)")
            local session = MatchCurrencySession(currencyID)
            if session then
                local info = currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
                    and C_CurrencyInfo.GetCurrencyInfo(tonumber(currencyID))
                Show(message, info and info.iconFileID or "Interface\\Icons\\INV_Misc_Coin_01", nil, nil, session.origin)
            end
        end
    end
end)

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, loaded)
    if loaded ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    FluxLoot:Refresh()
    if FluxOptions and FluxOptions.db then
        for _, event in ipairs({ "OnProfileChanged", "OnProfileCopied", "OnProfileReset" }) do
            FluxOptions.db.RegisterCallback(FluxLoot, event, FluxLoot.Refresh)
        end
    end
end)
