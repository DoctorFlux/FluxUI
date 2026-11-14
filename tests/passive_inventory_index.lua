-- Full production Index owner; native count and stored snapshot fixtures only.
-- Args: exact Index.lua source, --measure to report old allocation budgets.
local source = arg[1] or "Inventory/Index.lua"
local measure = arg[2] == "--measure"
local f = assert(io.open(source, "rb")); local code = f:read("*a"):gsub("\r\n", "\n"); f:close()
local checks, trace, metrics = 0, {}, {}
local function eq(a, b, label)
    checks = checks + 1
    assert(a == b, label .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
end
local function budget(a, b, label) if not measure then eq(a, b, label) end end
local function sameRow(a, b, label)
    eq(type(a), type(b), label .. " row presence")
    if not a then trace[#trace + 1] = label .. ":nil"; return end
    local keys = { "bag", "slot", "count", "region", "invSlot", "link" }
    for _, key in ipairs(keys) do eq(a[key], b[key], label .. " " .. key) end
    for key in pairs(a) do
        local known = false; for _, wanted in ipairs(keys) do if wanted == key then known = true end end
        eq(known, true, label .. " no extra returned fields")
    end
    local parts = {label}
    for _, key in ipairs(keys) do parts[#parts + 1] = key .. "=" .. tostring(a[key]) end
    trace[#trace + 1] = table.concat(parts, ":")
end
local optionsFields = { "bags", "bank", "warband", "equipped", "mail", "void", "auctions", "guild" }
local regionNames = { "bags", "bank", "warband", "equip", "mail", "void", "auctions", "guild" }
local function boot(family)
    local s = { hasWarband = family == "retail" or family == "forever", reliable = true, native = 3,
        nativeCalls = 0, capCalls = 0, slotVisits = 0, maps = {}, optionTrace = {} }
    local env = setmetatable({}, {__index = _G}); env._G = env
    local inv = { snapshots = {}, HasWarband = function()
        s.capCalls = s.capCalls + 1; s.optionTrace[#s.optionTrace + 1] = "HasWarband"
        if s.onCap then s.onCap() end
        return s.hasWarband
    end, IsReliable = function() return s.reliable end }
    for i, region in ipairs(regionNames) do
        local count = 2^(i-1)
        local row = {itemID = 123, count = count, link = "item:123:" .. region}
        local snap = { counts = {[123] = count}, byBag = {[i] = {[i+1] = row}}, bySlot = {[i] = row},
            byIndex = {[i+10] = row} }
        inv.snapshots[region] = snap
        s.maps[snap.byBag[i]], s.maps[snap.bySlot], s.maps[snap.byIndex] = true, true, true
    end
    env.pairs = function(t)
        local iter, state, key = pairs(t)
        return function(st, old)
            local k, value = iter(st, old)
            if k ~= nil and s.maps[t] then s.slotVisits = s.slotVisits + 1 end
            return k, value
        end, state, key
    end
    local flux = { Inventory = inv, Item = {GetCount = function(...)
        s.nativeCalls = s.nativeCalls + 1; s.nativeArgs = {...}
        if s.onNative then s.onNative() end
        return s.native
    end}, Secrets = {SafeGetNumber = function(value, default)
        if type(value) == "table" and value.safeCount then return value.safeCount end
        return default
    end} }
    assert(load(code, "@production-inventory-index", "t", env))("_FluxUI", {Flux = flux})
    s.env, s.inv, s.flux = env, inv, flux
    return s
end

local function referenceCount(s, opts)
    opts = opts or {}
    local flags = {}
    for _, key in ipairs(optionsFields) do flags[key] = key == "bags" and opts[key] ~= false or opts[key] == true end
    if opts.includeBank == false then flags.bank, flags.warband = false, false
    elseif opts.includeBank == true then flags.bank = true end
    if not s.hasWarband then flags.warband = false end
    local n = 0
    for i, region in ipairs(regionNames) do if flags[optionsFields[i]] then n = n + s.inv.snapshots[region].counts[123] end end
    return n
end
local function noBags(extra)
    local opts = {bags = false}; for key, value in pairs(extra or {}) do opts[key] = value end; return opts
end
local function record(label, value) trace[#trace + 1] = label .. ":" .. tostring(value) end

for _, family in ipairs({"retail", "forever", "era", "anniversary", "mists"}) do
    local s = boot(family); local inv = s.inv
    for _, cap in ipairs({false, true}) do
        s.hasWarband = cap
        for mask = 0, 255 do
            local opts, bits = {}, mask
            for _, key in ipairs(optionsFields) do opts[key] = bits % 2 == 1; bits = math.floor(bits / 2) end
            for _, alias in ipairs({"unset", "on", "off"}) do
                opts.includeBank = alias == "on" and true or (alias == "off" and false or nil)
                -- Lua's and/or expression cannot represent a false middle value.
                if alias == "off" then opts.includeBank = false end
                local count = inv.GetCount("123", opts)
                eq(count, referenceCount(s, opts), family .. " count option matrix")
                record(family .. ":" .. tostring(cap) .. ":" .. mask .. ":" .. alias, count)
                sameRow(inv.GetFirst("123", opts), inv.Find("123", opts)[1], family .. " first option matrix")
            end
        end
    end
    eq(inv.GetCount(123), 1, "nil options keep bags default")
    eq(inv.GetCount(123, false), 1, "false options keep bags default")
    eq(inv.GetCount("bad", 99), 0, "invalid ID bypasses invalid option reads")
    eq(inv.GetFirst("bad", 99), nil, "invalid first ID returns nil before options")
    local ok = pcall(inv.GetCount, 123, 99); eq(ok, false, "invalid truthy option type still errors")
    -- Distinct fresh output rows protect stored facts from caller mutation.
    local first = inv.GetFirst(123); local firstAgain = inv.GetFirst(123)
    eq(rawequal(first, firstAgain), false, "GetFirst returns independent row")
    first.count, first.link = 999, "mutated-return"
    eq(inv.GetFirst(123).count, 1, "GetFirst caller mutation cannot change stored count")
    eq(inv.GetFirst(123).link, "item:123:bags", "GetFirst caller mutation cannot change stored link")
    local rec = inv.snapshots.bags.byBag[1][2]
    rec.count, rec.link = 9, "item:123:changed"
    inv.snapshots.bags.counts[123] = 9
    eq(inv.GetFirst(123).count, 9, "in-place slot mutation visible immediately")
    eq(inv.GetFirst(123).link, "item:123:changed", "in-place slot link visible immediately")
    eq(inv.GetCount(123), 9, "in-place aggregate mutation visible immediately")
    record(family .. "mutated-first", inv.GetFirst(123).link)
    -- Indexed locations and equipped invSlot retain their existing shapes.
    for _, key in ipairs({"equipped", "mail", "void", "auctions", "guild"}) do
        local opts = noBags({[key] = true})
        sameRow(inv.GetFirst(123, opts), inv.Find(123, opts)[1], "stored location " .. key)
    end
    inv.snapshots.bags.byBag = {[41] = {[93] = {itemID = 123, count = 7, link = nil},
        [2] = {itemID = "123", count = 12}, [501] = {itemID = 456, count = 2}}}
    sameRow(inv.GetFirst(123), inv.Find(123)[1], "sparse bag and exact numeric item identity")
    eq(inv.GetFirst(999), nil, "missing item returns nil")
    -- Public extension seams keep both their dynamic lookup and argument shape.
    local index, original = inv.Index, inv.Index.Find
    local chosen, overrides = {count = 55, region = "extension"}, 0
    index.Find = function(...)
        overrides = overrides + 1; eq(select("#", ...), 2, "Find override keeps two arguments")
        return {chosen}
    end
    eq(rawequal(inv.GetFirst(123, noBags()), chosen), true, "GetFirst honors current Find override")
    eq(overrides, 1, "Find override called once")
    index.Find = original
    local originalCount = index.GetCount
    index.GetCount = function(id, opts)
        eq(id, 123, "live count dynamic seam item")
        eq(opts.bags, true, "live count seam sees normalized bags")
        eq(opts.includeBank, nil, "live count seam sees normalized shape")
        return 17
    end
    s.reliable, s.native = false, 0
    eq(inv.GetLiveCount(123), 17, "live count preserves dynamic GetCount seam")
    index.GetCount = originalCount
    s.reliable = true
    for _, native in ipairs({0, "6", -1, false, {safeCount = 8}}) do
        s.native = native
        local expected = type(native) == "table" and 8 or (tonumber(native) or 0)
        eq(inv.GetLiveCount(123), expected, "same native count conversion")
    end
    s.native, s.reliable = 0, false
    eq(inv.GetLiveCount(123), 9, "loading snapshot count remains authoritative")
    s.reliable = true; eq(inv.GetLiveCount(123), 0, "reliable live zero wins stale snapshot")
    inv.snapshots.bags.counts[123], s.native, s.reliable = 0, 7, false
    eq(inv.GetLiveCount(123), 7, "live newly carried item wins empty loading snapshot")
    inv.snapshots.bags.counts[123], s.reliable = 9, true
    local conversion = s.flux.Secrets.SafeGetNumber
    s.flux.Secrets.SafeGetNumber = function() error("transient conversion failure") end
    s.native = {}
    eq(pcall(inv.GetLiveCount, 123), false, "conversion error remains observable")
    s.flux.Secrets.SafeGetNumber = conversion; s.native = {safeCount = 12}
    eq(inv.GetLiveCount(123), 12, "conversion retries on next call")
    s.native = 23
    inv.GetLiveCount(123, {bags = false, bank = true, warband = true, charges = false})
    eq(s.nativeArgs[1], 123, "native item ID")
    eq(s.nativeArgs[2], true, "native include bank")
    eq(s.nativeArgs[3], false, "native charge flag")
    eq(s.nativeArgs[4], true, "native account inclusion alias")
    eq(s.nativeArgs[5], true, "native warband capability")
    record(family .. "live-zero", inv.GetLiveCount(123, {charges = false}))
    -- Exact public option read order, including the alias's second read and
    -- unused charges field after the capability call, is observable to adapters.
    for _, alias in ipairs({"unset", "on", "off"}) do
        s.optionTrace = {}
        local opts = setmetatable({}, {__index = function(_, key)
            s.optionTrace[#s.optionTrace + 1] = key
            if key == "includeBank" then
                if alias == "on" then return true elseif alias == "off" then return false end
            end
        end, __newindex = function() error("caller options mutated") end})
        inv.GetCount(123, opts)
        local expected = "bags,bank,warband,equipped,mail,void,auctions,guild,includeBank,"
            .. (alias == "off" and "" or "includeBank,") .. "HasWarband,charges"
        eq(table.concat(s.optionTrace, ","), expected, "exact GetCount options read order " .. alias)
    end
    -- Reentrant option/capability reads cannot share a normalized scratch row.
    local entered = false
    s.onCap = function()
        if not entered then
            entered = true; eq(inv.GetCount(123, noBags({equipped = true})), 8, "nested GetCount remains independent")
        end
    end
    eq(inv.GetCount(123, noBags({bank = true, mail = true})), 18, "outer GetCount flags survive nested read")
    s.onCap = nil
    record(family .. "nested", inv.GetCount(123, noBags({bank = true, mail = true})))
    inv.snapshots.mail = nil
    eq(inv.GetFirst(123, noBags({mail = true})), nil, "missing optional indexed snapshot remains empty")
end

-- Meter actual constructor lines and helper identities without changing source.
local allocationLines, asCountLine, line, inDefault = {}, nil, 0, false
for text in (code .. "\n"):gmatch("(.-)\n") do
    line = line + 1
    if text:find("local function DefaultOpts(opts)", 1, true) then inDefault = true end
    if inDefault and text == "end" then inDefault = false end
    if inDefault and text == "\treturn {" then allocationLines[line] = "normalizedTables" end
    if text:find("local function asCount(n)", 1, true) then asCountLine = line end
    if text:find("out[#out + 1] = {", 1, true) or text:find("locations[#locations + 1] = {", 1, true)
        or text:find("return { bag =", 1, true) then allocationLines[line] = "locationTables" end
end
local s = boot("forever"); local opts = {bags = true, bank = false, warband = false}
local function sample(name, fn)
    local out, functions = {}, {}; s.nativeCalls, s.slotVisits = 0, 0
    debug.sethook(function(event, n)
        if event == "call" then
            local info = debug.getinfo(2, "Sf")
            if info and info.source == "@production-inventory-index" and info.linedefined == asCountLine and not functions[info.func] then
                functions[info.func] = true; out.helperIdentities = (out.helperIdentities or 0) + 1
            end
            return
        end
        local key = allocationLines[n]
        if key and debug.getinfo(2, "S").source == "@production-inventory-index" then out[key] = (out[key] or 0) + 1 end
    end, "cl")
    fn(); debug.sethook()
    out.nativeCalls, out.slotVisits = s.nativeCalls, s.slotVisits
    metrics[name] = out
    return out
end
local counts = sample("GetCount20000", function() for _ = 1, 20000 do assert(s.inv.GetCount(123, opts) == 1) end end)
budget(counts.normalizedTables or 0, 0, "GetCount constructs no normalized option tables")
s.native = 3
local live = sample("GetLiveCount20000", function() for _ = 1, 20000 do assert(s.inv.GetLiveCount(123, opts) == 3) end end)
budget(live.normalizedTables or 0, 20000, "GetLiveCount retains one normalized options table")
budget(live.helperIdentities or 0, 1, "GetLiveCount uses one hoisted conversion helper")
eq(live.nativeCalls, 20000, "native live count query cadence unchanged")
s.inv.snapshots.bags.byBag = {}; s.maps = {}
for bag = 0, 4 do
    local slots = {}; s.inv.snapshots.bags.byBag[bag] = slots; s.maps[slots] = true
    for slot = 1, 20 do slots[slot] = {itemID = 123, count = 1, link = "item:123"} end
end
local first = sample("GetFirst1000x100Matches", function()
    for _ = 1, 1000 do local row = assert(s.inv.GetFirst(123, opts)); assert(row.count == 1 and row.region == "bags") end
end)
budget(first.locationTables or 0, 1000, "GetFirst only constructs its returned row")
budget(first.slotVisits, 1000, "GetFirst stops at the first occupied match")
local all = s.inv.Find(123, opts); eq(#all, 100, "Find still returns every matching row")

local hash = 0
for _, value in ipairs(trace) do for i = 1, #value do hash = (hash * 31 + value:byte(i)) % 2147483647 end end
if arg[3] then local out = assert(io.open(arg[3], "wb")); out:write(table.concat(trace, "\n"), "\n"); out:close() end
local function json(value)
    if type(value) ~= "table" then return type(value) == "string" and string.format("%q", value) or tostring(value) end
    local keys, out = {}, {}; for key in pairs(value) do keys[#keys + 1] = key end; table.sort(keys)
    for _, key in ipairs(keys) do out[#out + 1] = string.format("%q", key) .. ":" .. json(value[key]) end
    return "{" .. table.concat(out, ",") .. "}"
end
print(json({checks = checks, metrics = metrics, traceHash = hash, traceSamples = #trace}))
