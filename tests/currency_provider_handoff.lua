-- Production currency/store/adapter replay; WoW APIs and unrelated region scans are mocked.
-- Run: lua tests/currency_provider_handoff.lua
-- For matched replay: --source <saved Currency.lua> --measure (reports failures without a failing exit).
local currencySource, measureOnly = "Inventory/Builtin/Currency.lua", false
local i = 1
while arg and i <= #arg do
    if arg[i] == "--source" then
        i = i + 1
        currencySource = assert(arg[i], "--source needs a Currency.lua path")
    elseif arg[i] == "--measure" then
        measureOnly = true
    else
        error("unknown argument: " .. tostring(arg[i]))
    end
    i = i + 1
end
local checks, failures = 0, {}
local function check(value, message)
    checks = checks + 1
    if not value then failures[#failures + 1] = message end
end

local function harness(tokens, warband)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local h = { events = {}, callbacks = {}, requests = 0, moneyReads = 0, scans = 0,
        money = 123, ready = false, binds = 0, registrations = 0 }
    env.UnitName = function() return "Test" end
    env.GetNormalizedRealmName = function() return "Realm" end
    env.GetMoney = function() h.moneyReads = h.moneyReads + 1; return h.money end
    env.GetTime = function() return 0 end
    env.Enum = { BankType = { Account = 2 } }
    env.C_Bank = { FetchDepositedMoney = function() return 321 end }
    env.C_CurrencyInfo = {
        GetCurrencyListSize = function() h.scans = h.scans + 1; return 1 end,
        GetCurrencyListInfo = function() return { discovered = true, quantity = 7 } end,
        GetCurrencyListLink = function() return "|Hcurrency:55|hTest|h" end,
    }
    local inv = { Builtin = {}, Syndicator = {}, Containers = { NewItemSetLog = function() return {} end },
        snapshots = { currencies = { money = 0, counts = {}, generation = 0 } },
        HasWarband = function() return warband end }
    local flux = { Inventory = inv, Cap = { hasCurrencyTokens = tokens },
        Timer = { After = function(_, fn) fn() end },
        Scheduler = { Request = function(tier, token)
            assert(tier == "inventory" and token)
            h.requests = h.requests + 1
        end },
        Events = { Register = function(event, fn)
            h.registrations = h.registrations + 1
            assert(not h.events[event], "currency event must be registered once")
            h.events[event] = fn
        end } }
    local ns = { Flux = flux }
    for _, file in ipairs({ "Inventory/Store.lua", currencySource, "Inventory/Syndicator/Adapter.lua" }) do
        assert(loadfile(file, "t", env))("_FluxUI", ns)
    end
    -- Preserve the real readiness transition and currency snapshot builders.
    inv.Syndicator.RebuildAll = function()
        h.binds = h.binds + 1
        inv.Syndicator.RebuildCurrencies()
        inv.Syndicator.RebuildWarbandCurrency()
    end
    inv.Builtin.Start = function()
        inv.source = "builtin"
        inv.Builtin.Currency.Start()
    end
    function h.installProvider()
        h.character = { money = 999, currencies = { [55] = 88 } }
        env.Syndicator = { API = {
            IsReady = function() return h.ready end,
            GetCurrentCharacter = function() return "Test-Realm" end,
            GetCharacter = function() return h.character end,
            GetWarband = function() return { money = 777 } end,
        }, CallbackRegistry = { RegisterCallback = function(_, event, fn)
            assert(not h.callbacks[event], "provider callback must be registered once")
            h.callbacks[event] = fn
        end } }
    end
    function h.fire(event)
        if h.events[event] then h.events[event](event) end
    end
    function h.resetCounts() h.requests, h.moneyReads, h.scans = 0, 0, 0 end
    h.inv, h.env = inv, env
    return h
end

local events = { "PLAYER_MONEY", "CURRENCY_DISPLAY_UPDATE", "ACCOUNT_MONEY", "BANKFRAME_OPENED" }
for _, client in ipairs({
    { "era", false, false }, { "anniversary", false, false }, { "mists", true, false },
    { "retail", true, true }, { "forever", true, true },
}) do
    local label, tokens, warband = client[1], client[2], client[3]
    local h = harness(tokens, warband)
    local inv = h.inv
    check(inv.Syndicator.Start() == false, label .. " absent provider can retry")
    inv.Builtin.Start()
    local snapshot = inv.snapshots.currencies
    local saved = inv.Store.GetDB().Characters["Test-Realm"]
    check(snapshot.money == 123 and saved.money == 123, label .. " builtin startup primes money")
    check(not tokens or snapshot.counts[55] == 7, label .. " builtin startup primes tokens")
    h.resetCounts()
    inv.Builtin.Currency.Start()
    check(h.registrations == 4 and h.requests == 0 and h.moneyReads == 0, label .. " startup is idempotent")
    h.money = 456
    h.fire("PLAYER_MONEY")
    check(snapshot.money == 456 and saved.money == 456 and h.requests == 1 and h.moneyReads == 1,
        label .. " builtin money is synchronous before provider exists")
    h.installProvider()
    inv.Syndicator.Start()
    check(inv.source == "builtin" and not inv.Store.UsesSyndicator() and h.callbacks.Ready,
        label .. " pending provider keeps builtin facts")
    h.resetCounts()
    h.money = 654
    h.fire("PLAYER_MONEY")
    check(snapshot.money == 654 and saved.money == 654 and h.requests == 1 and h.moneyReads == 1,
        label .. " pending provider keeps synchronous builtin money")
    h.resetCounts()
    for _, event in ipairs(events) do h.fire(event) end
    check(h.requests == (warband and 4 or 3), label .. " builtin currency events keep cadence")
    inv.Builtin.Currency.Refresh()
    check(h.scans == (tokens and 1 or 0), label .. " dirty token refresh respects capability")
    check(not warband or snapshot.warbandMoney == 321, label .. " builtin bank money refreshed")

    h.ready = true
    h.callbacks.Ready()
    check(inv.source == "syndicator" and inv.Store.UsesSyndicator() and h.binds == 1,
        label .. " readiness transfers provider ownership")
    check(snapshot.money == 999 and snapshot.counts[55] == 88 and snapshot.warbandMoney == 777,
        label .. " provider currency facts are installed")
    local generation = snapshot.generation
    local savedMoney = saved.money
    for repetition = 1, 5 do
        -- Each repetition starts with provider facts, independently of prior failures.
        inv.Syndicator.RebuildCurrencies()
        generation = snapshot.generation
        h.resetCounts()
        for i = 1, 100 do
            for _, event in ipairs(events) do h.fire(event) end
        end
        inv.Builtin.Currency.Refresh()
        print(string.format("%s repetition=%d events=400 moneyReads=%d requests=%d scans=%d money=%d generationDelta=%d",
            label, repetition, h.moneyReads, h.requests, h.scans, snapshot.money, snapshot.generation - generation))
        check(h.moneyReads == 0 and h.requests == 0 and h.scans == 0,
            label .. " handed-off builtin events perform no currency work (run " .. repetition .. ")")
        check(snapshot.money == 999 and snapshot.counts[55] == 88 and snapshot.generation == generation,
            label .. " builtin events preserve provider snapshots (run " .. repetition .. ")")
        check(saved.money == savedMoney, label .. " handoff preserves saved standalone ledger")
    end
    h.resetCounts()
    h.callbacks.Ready(); inv.Syndicator.Start(); inv.Builtin.Currency.Start()
    check(h.binds == 1 and h.requests == 0 and h.moneyReads == 0 and h.registrations == 4,
        label .. " repeated readiness and starts do not reinstall either provider")
    h.character.money = 1001
    h.callbacks.CurrencyCacheUpdate(nil, "Test-Realm")
    check(snapshot.money == 1001 and h.requests == 1, label .. " external updates remain responsive")

    local readyFirst = harness(tokens, warband)
    readyFirst.installProvider(); readyFirst.ready = true; readyFirst.inv.Syndicator.Start()
    readyFirst.inv.Builtin.Currency.Start(); readyFirst.inv.Builtin.Currency.Refresh()
    check(readyFirst.registrations == 0 and readyFirst.moneyReads == 0,
        label .. " initially ready provider never starts builtin currency")
end
print(string.format("currency provider handoff: %d checks, %d failures; desktop operation counts only", checks, #failures))
for _, message in ipairs(failures) do print("FAIL " .. message) end
if not measureOnly then assert(#failures == 0, "currency provider handoff regressions") end
