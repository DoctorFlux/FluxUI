-- Actual TM/Paint/Charges/Manager bag-pulse regression. Run from project root.
-- Optional: --source path/to/FluxTrinketMenu.lua; --measure reports the budget.
-- Native/UI/timer/provider endpoints are modeled. No native FPS/taint claim.
local corePath = "ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua"
local selectedSource, measure = corePath, false
local i = 1
while arg and i <= #arg do
    if arg[i] == "--source" then i = i + 1; selectedSource = assert(arg[i])
    elseif arg[i] == "--measure" then measure = true
    else error("Expected --source path or --measure", 0) end
    i = i + 1
end
local unpackValues = table.unpack or unpack
local nativePairs, nativePcall = pairs, pcall
local function loadEnvironment(body, label, env)
    if _VERSION == "Lua 5.1" then
        local f, err = loadstring(body, label)
        if f then setfenv(f, env) end
        return f, err
    end
    return load(body, label, "t", env)
end
local checks = 0
local failures = {}
local function check(ok, message)
    checks = checks + 1
    if not ok then failures[#failures + 1] = message end
end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local sourceRoot = "."
local function fixture(client)
    local s = { now = 100, equipped = { [13] = 900001, [14] = 900002 }, usable = true,
        slotCD = { 0, 0, 1 }, itemCD = { 0, 0, 1 }, frames = {}, timers = {},
        slotReads = 0, itemReads = 0, hasSpell = true }
    local e = setmetatable({}, { __index = _G }); e._G = e
    e.FluxButton = {}
    e.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    e.GetTime = function() return s.now end
    e.GetBindingKey = function() return nil end -- Mouse/wheel path must wake and retire.
    e.IsMouseButtonDown = function() return s.mouse end
    e.IsKeyDown = function() return false end
    e.GetInventoryItemID = function(_, slot) return s.equipped[slot] end
    e.GetInventoryItemCooldown = function(_, slot)
        check(slot == 13 or slot == 14, "only equipped trinket slots queried")
        s.slotReads = s.slotReads + 1
        if not s.equipped[slot] then return 0, 0, 0 end
        return unpackValues(s.slotCD)
    end
    e.UnitClass = function() return "Mage", "MAGE" end
    e.RAID_CLASS_COLORS = { MAGE = { r = .2, g = .6, b = 1 } }
    e.C_Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end }
    local function frame()
        local f = { shown = true, scripts = {}, events = {} }
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:IsShown() return self.shown end
        function f:RegisterEvent(name) self.events[name] = true end
        function f:SetScript(name, fn) self.scripts[name] = fn end
        function f:GetScript(name) return self.scripts[name] end
        function f:HookScript(name, fn)
            local old = self.scripts[name]
            self.scripts[name] = function(...) if old then old(...) end; fn(...) end
        end
        function f:SetAllPoints() end
        function f:SetColorTexture() end
        function f:CreateTexture() return frame() end
        function f:SetButtonState(value, locked) assert(not locked); self.state = value end
        function f:UnlockHighlight() end
        function f:SetChecked(value) self.checked = value end
        function f:SetAttribute() error("visual refresh must not write secure actions") end
        return f
    end
    e.CreateFrame = function() local f = frame(); s.frames[#s.frames + 1] = f; return f end
    e.CooldownFrame_Clear = function(cd) cd:Clear() end
    e.CooldownFrame_Set = function(cd, start, duration, enable)
        if enable and enable ~= 0 and start > 0 and duration > 0 then cd:SetCooldown(start, duration)
        else cd:Clear() end
    end
    local flux = { EBS = { buttons = {}, badges = {} }, Client = { isAnyClassic = client ~= "retail" and client ~= "forever" },
        Inventory = { IsReliable = function() return true end, GetCount = function() return 0 end,
            GetLiveCount = function() return 0 end },
        Item = {
            IsUsable = function() return false, false end,
            GetSpell = function() if s.hasSpell then return "Use Effect", 123 end end,
            GetCooldown = function() s.itemReads = s.itemReads + 1; return unpackValues(s.itemCD) end,
            IsConsumable = function() return false end, UsesConsumableCharges = function() return false end,
        },
        Spell = { IsUsable = function() return s.usable, false end },
    }
    local ns = { Flux = flux }
    for _, path in ipairs({ "Core/ButtonFX/Charges.lua", "ExtraButtonSystem/Engine/Paint.lua",
        "ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua" }) do
        local base = path == "Core/ButtonFX/Charges.lua" and "." or sourceRoot
        local owner = path == corePath and selectedSource or (base .. "/" .. path)
        assert(loadEnvironment(read(owner), "@" .. path, e))("_FluxUI", ns)
    end
    local tm, paint = e.FluxTrinketMenu, flux.EBS.Paint
    s.tm, s.paint, s.env, s.watch = tm, paint, e, s.frames[1]
    tm.Frame, tm.VisibilityState = frame(), "both_equipped"
    tm.Buttons = {}
    for index = 0, 1 do
        local icon = { color = { 1, 1, 1 } }
        function icon:SetVertexColor(r, g, b) self.color = { r, g, b } end
        function icon:GetVertexColor() return unpackValues(self.color) end
        function icon:SetDesaturated(value) self.desaturated = value end
        local widget, cd = frame(), frame()
        function cd:ClearAllPoints() end
        function cd:SetPoint() end
        function cd:SetCooldown(start, duration) self.start, self.duration = start, duration; self.shown = true end
        function cd:Clear() self.start, self.duration, self.shown = 0, 0, false end
        function cd:SetDrawBling() end
        local b = { WIcon = icon, Widget = widget, WCooldown = cd,
            WNormalTexture = { SetVertexColor = function() end },
            inventorySlot = index + 13, ActionType = "macrotext", ActionValue = "/use " .. (index + 13), categoryScope = "class" }
        widget.icon, widget.FluxButton, widget.cooldown = icon, b, cd
        tm.Buttons[index] = b
        tm.SyncEquippedFace(b)
        tm.HookTrinketClickScripts(widget)
    end
    tm.SyncKeybindPushWatch()
    s.flux, s.ns = flux, ns
    return s
end


local function run(spec)
    local s = fixture(spec.client or "forever")
    local e, tm, flux = s.env, s.tm, s.flux
    e.Syndicator = spec.provider and { API = {} } or nil
    local m = { scan = 0, instant = 0, nativeSlots = 0, cancelled = 0, executed = 0,
        privateMaps = 0, privateWrapperRows = 0, reentries = 0 }
    local marker, reads, slots = {}, {}, {}
    local ready = not (spec.cold or spec.arrive or spec.fail)
    for slot = 1, spec.rows do
        local id = 100 + (slot - 1) % spec.unique + 1
        slots[slot] = { itemID = id, count = 1, link = "item:" .. id }
    end
    local byBag = { [0] = slots }
    if spec.crossbag then
        local other = {}; byBag[1] = other
        for slot = math.floor(spec.rows / 2) + 1, spec.rows do other[slot], slots[slot] = slots[slot], nil end
    end
    local expected = {}
    for bag, rows in nativePairs(byBag) do
        for slot, rec in nativePairs(rows) do expected[rec.itemID] = { bag = bag, slot = slot } end
    end
    if spec.record or spec.recordError then
        for slot, rec in nativePairs(slots) do
            local backing, at = rec, slot
            slots[slot] = setmetatable({}, { __index = function(_, key)
                reads[#reads + 1] = key
                if key == "count" then
                    backing.link = "changed:" .. at
                    if spec.recordError then error(marker, 0) end
                end
                return backing[key]
            end })
        end
    end
    if spec.invalid then slots[1], slots[2] = { itemID = false }, {} end
    flux.Inventory.snapshots = { bags = { byBag = byBag } }
    flux.Inventory.Containers = { GetCarriedBagIDs = function() return { 0 } end }
    s.combat = spec.combat
    e.InCombatLockdown = function() return s.combat == true end
    e.GetInventoryItemLink = function(_, slot) return s.equipped[slot] and ("item:" .. s.equipped[slot]) end
    e.GetInventoryItemTexture = function(_, slot) return s.equipped[slot] end
    e.GetInventorySlotInfo = function() return 13, 13 end
    e.ClearOverrideBindings = function() end
    e.SetOverrideBindingClick = function() error("Unbound fixture must not set keys", 0) end
    e.GetBindingText = function(key) return key end
    local canonical = { scan = tm.ScanBagsForTrinkets, visibility = tm.UpdateTrinketVisibility,
        keybindings = tm.UpdateKeybindings }
    local seenMaps = {}
    local function observePrivateRows()
        -- Count actual location-wrapper records once per private map, at the
        -- metadata boundary. This observes records, not heap bytes or CPU.
        for level = 2, 20 do
            local info = debug.getinfo(level, "f")
            if not info then break end
            if info.func == canonical.scan then
                for index = 1, 80 do
                    local name, value = debug.getlocal(level, index)
                    if not name then break end
                    if name == "uniqueItems" then
                        -- Native-slot fallback has no uniqueItems map; it is a valid query path.
                        if value == nil then return end
                        assert(type(value) == "table", "scan location map exists at query boundary")
                        if seenMaps[value] then return end
                        seenMaps[value] = true; m.privateMaps = m.privateMaps + 1
                        for _, row in nativePairs(value) do
                            if type(row) == "table" and rawget(row, "bag") ~= nil and rawget(row, "slot") ~= nil then
                                m.privateWrapperRows = m.privateWrapperRows + 1
                            end
                        end
                        return
                    end
                end
                error("Cannot observe original scan location map", 0)
            end
        end
    end
    local function parse(id) return type(id) == "string" and tonumber(id:match("item:(%d+)")) or id end
    flux.Item.GetInfo = function(id)
        id = parse(id)
        if spec.fail then error(marker, 0) end
        if not ready then return end
        return { itemName = "Item" .. id, itemLink = "item:" .. id,
            itemEquipLoc = (id >= 900000 or id <= 100 + spec.trinkets) and "INVTYPE_TRINKET" or "", itemTexture = id }
    end
    e.C_Item = { GetItemInfoInstant = function(id)
        observePrivateRows(); m.instant = m.instant + 1
        if spec.foreign and s.foreign[id] then
            local row = s.foreign[id]; row.bag, row.slot = row.bag + 1, row.slot + 1
        end
        if spec.reenter and m.reentries == 0 then
            m.reentries = 1; e.FluxTrinketMenuManager:Refresh()
        end
        local wasReady = ready
        if spec.arrive and m.instant == spec.unique then ready = true end
        return id, nil, nil, wasReady and (id <= 100 + spec.trinkets and "INVTYPE_TRINKET" or "") or nil
    end }
    e.C_Container = {
        GetContainerNumSlots = function() return spec.rows end,
        GetContainerItemLink = function(_, slot) m.nativeSlots = m.nativeSlots + 1; return slots[slot] and slots[slot].link end,
    }
    if spec.fallback or spec.foreign or spec.foreignError then flux.Inventory.snapshots.bags.byBag = {} end
    if spec.foreign or spec.foreignError or spec.invalid then
        s.foreign = { [101] = { bag = 0, slot = 4 }, [102] = { bag = 1, slot = 6 } }
        local rows = {}
        for id, row in nativePairs(s.foreign) do
            local backing = row
            rows[id] = setmetatable({}, { __index = function(_, key) return backing[key] end })
        end
        e.FluxInv = { Bags = { GetUniqueItems = function()
            if spec.foreignError or spec.invalid then error(marker, 0) end
            return rows
        end } }
    end
    local function augment(f)
        function f:GetName() return self.name or "TMModelWidget" end
        function f:SetTexture(v) self.texture = v end
        function f:SetTexCoord(...) self.texcoord = { ... } end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:SetAlpha(v) self.alpha = v end
        function f:SetSize(w, h) self.width, self.height = w, h end
        function f:SetWidth(v) self.width = v end
        function f:SetHeight(v) self.height = v end
        function f:GetWidth() return self.width or 54 end
        function f:GetHeight() return self.height or 108 end
        function f:ClearAllPoints() end
        function f:SetPoint(...) self.point = { ... } end
        function f:SetAttribute(k, v) self.attrs = self.attrs or {}; self.attrs[k] = v end
        function f:UnregisterEvent(k) self.events[k] = nil end
        return f
    end
    augment(tm.Frame)
    for index = 0, 1 do
        local b = tm.Buttons[index]; augment(b.Widget); augment(b.WIcon)
        b.SlotFrame = augment({ shown = true, scripts = {}, events = {}, IsShown = function(f) return f.shown end })
    end
    local oldCreate = e.CreateFrame
    e.CreateFrame = function(...) return augment(oldCreate(...)) end
    local timers = {}
    e.C_Timer = { NewTimer = function(delay, fn)
        local t = { at = s.now + delay, fn = fn }
        function t:Cancel() if not self.cancelled then m.cancelled = m.cancelled + 1 end; self.cancelled = true end
        timers[#timers + 1] = t; return t
    end }
    e.C_Timer.After = function(delay, fn) return e.C_Timer.NewTimer(delay, fn) end
    flux.Module = { Register = function() end }; flux.securePhaseReady = true
    local listener
    flux.Inventory.Register = function(key, fn, options)
        check(key == "TrinketMenu" and options.tier == "scan" and options.deferHeavy, "actual inventory registration")
        listener = fn
    end
    flux.EBS.Flyout = { SetButtons = function() end, GetPopup = function() end }
    e.SlashCmdList = {}; e.pcall = nativePcall
    assert(loadEnvironment(read("ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua"),
        "@ExtraButtonSystem/TrinketMenu/FluxTrinketMenuManager.lua", e))("_FluxUI", s.ns)
    local manager = e.FluxTrinketMenuManager
    manager.Initialized, manager._startupReady = true, true
    local eventFrame = s.frames[#s.frames]
    local event = assert(eventFrame.scripts.OnEvent)
    local function drain(delta)
        local finish = s.now + delta
        for _ = 1, 20 do
            local nextIndex
            for index, t in ipairs(timers) do
                if not t.cancelled and t.at <= finish and (not nextIndex or t.at < timers[nextIndex].at) then nextIndex = index end
            end
            if not nextIndex then s.now = finish; return end
            local t = table.remove(timers, nextIndex); s.now = t.at; m.executed = m.executed + 1; t.fn()
        end
        error("Bounded timer drain exceeded", 0)
    end
    local function hook(kind)
        if (kind == "call" or kind == "tail call") and debug.getinfo(2, "f").func == canonical.scan then m.scan = m.scan + 1 end
    end
    assert(debug.gethook() == nil, "no preexisting hook")
    debug.sethook(hook, "c")
    local ok, err = nativePcall(function()
        assert(type(listener) == "function")
        for _ = 1, spec.burst or 1 do listener({ regions = { bags = true }, changeKind = "countOnly" }) end
        drain(.21)
    end)
    debug.sethook()
    local beforeRegen = m.scan
    if spec.combat and ok then
        check(m.scan == 1 and tm._pendingVisibilityUpdate, spec.name .. ": combat retains deferred visibility")
        s.combat = false; debug.sethook(hook, "c")
        ok, err = nativePcall(function() event(eventFrame, "PLAYER_REGEN_ENABLED") end)
        debug.sethook()
    end
    check(debug.gethook() == nil and tm.ScanBagsForTrinkets == canonical.scan
        and tm.UpdateTrinketVisibility == canonical.visibility and tm.UpdateKeybindings == canonical.keybindings,
        spec.name .. ": observer retired and public owners untouched")
    if spec.fail or spec.recordError or spec.foreignError then
        check(not ok and err == marker, spec.name .. ": exact opaque error identity")
        check(next(tm.BaggedTrinkets) == nil, spec.name .. ": error does not publish rows")
        if spec.recordError then check(#reads == 2 and reads[1] == "itemID" and reads[2] == "count", "count error precedes link read") end
        return m
    end
    check(ok, spec.name .. ": actual callback succeeds: " .. tostring(err))
    check(m.scan == (spec.reenter and 5 or 3), spec.name .. ": original scan cadence")
    if spec.combat then check(beforeRegen == 1 and m.scan == 3, "regen retains both later scans") end
    if spec.burst then check(m.cancelled == spec.burst - 1 and m.executed == 1, "burst coalesces existing timer") end
    local wanted = {}
    if not spec.cold and not spec.invalid then
        for id = 101, 100 + spec.trinkets do
            local location = spec.foreign and s.foreign[id] or expected[id]
            if spec.fallback then location = { bag = 0, slot = id - 100 } end
            if location then wanted[#wanted + 1] = { id = id, bag = location.bag, slot = location.slot } end
        end
        table.sort(wanted, function(a, b) return a.bag == b.bag and a.slot < b.slot or a.bag < b.bag end)
    end
    check(tm.NumberOfTrinkets == #wanted and #tm.BaggedTrinkets == #wanted, spec.name .. ": exact selected rows")
    for index, want in ipairs(wanted) do
        local got = tm.BaggedTrinkets[index]
        check(got and got.id == want.id and got.bag == want.bag and got.slot == want.slot and got.name == "Item" .. want.id,
            spec.name .. ": selected location and order")
        local a, b = tm._trinketBagCacheByItemID[want.id], tm._trinketBagCacheByName["Item" .. want.id]
        check(a and b and a.bag == want.bag and a.slot == want.slot and b.bag == want.bag and b.slot == want.slot,
            spec.name .. ": both public caches match selected location")
    end
    local unique = spec.invalid and 0 or spec.unique
    check(m.instant == m.scan * unique, spec.name .. ": native metadata calls retained")
    check(m.nativeSlots == (spec.fallback and spec.rows * m.scan or 0), spec.name .. ": native slot fallback calls")
    if spec.fallback then check(m.privateMaps == 0, "native fallback has no private location map") end
    if spec.record then
        check(#reads == spec.rows * m.scan * 3, "all record reads retained")
        for at = 1, #reads, 3 do check(reads[at] == "itemID" and reads[at + 1] == "count" and reads[at + 2] == "link", "itemID-count-link read order") end
    end
    return m
end

local specs = {
    { name = "dense32-burst", rows = 32, unique = 32, trinkets = 4, burst = 3, client = "retail" },
    { name = "duplicate32", rows = 32, unique = 4, trinkets = 1, client = "forever", provider = true },
    { name = "small1", rows = 1, unique = 1, trinkets = 1, client = "classic" },
    { name = "no-trinket8", rows = 8, unique = 8, trinkets = 0 },
    { name = "cold8", rows = 8, unique = 8, trinkets = 2, cold = true, client = "anniversary" },
    { name = "metadata-arrives", rows = 8, unique = 8, trinkets = 2, arrive = true },
    { name = "combat-regen", rows = 8, unique = 8, trinkets = 2, combat = true },
    { name = "native-fallback", rows = 8, unique = 8, trinkets = 2, fallback = true, client = "era" },
    { name = "opaque-metadata", rows = 8, unique = 8, trinkets = 2, fail = true },
    { name = "refresh-reentry", rows = 8, unique = 8, trinkets = 2, reenter = true },
    { name = "crossbag-duplicate", rows = 8, unique = 2, trinkets = 2, crossbag = true },
    { name = "record-order", rows = 2, unique = 2, trinkets = 2, record = true },
    { name = "record-error", rows = 2, unique = 2, trinkets = 2, recordError = true },
    { name = "foreign-map", rows = 2, unique = 2, trinkets = 2, foreign = true },
    { name = "foreign-error", rows = 2, unique = 2, trinkets = 2, foreignError = true },
    { name = "invalid-authoritative", rows = 0, unique = 0, trinkets = 0, invalid = true },
    { name = "empty-authoritative", rows = 0, unique = 0, trinkets = 0 },
}
local dense
for _, spec in ipairs(specs) do
    local result = run(spec)
    if spec.name == "dense32-burst" then dense = result end
end
for _, message in ipairs(failures) do io.stderr:write(message .. "\n") end
print(("trinket bag scan: %d semantic checks; %d failures; modeled endpoints"):format(checks, #failures))
assert(#failures == 0, "trinket bag scan semantic regression")
assert(dense.privateMaps == 3, "one private map observed per actual dense scan")
local budgetPass = dense.privateWrapperRows == 0
print(("private location-wrapper records: %d across %d scans; budget=0; pass=%s; not heap bytes"):format(
    dense.privateWrapperRows, dense.scan, tostring(budgetPass)))
if not measure then assert(budgetPass, "private location-wrapper allocation budget exceeded") end
