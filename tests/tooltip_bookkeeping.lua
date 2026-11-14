-- Executes actual tooltip owners against a native-table write trap. This checks
-- ownership/content/lifecycle only; ordinary Lua cannot model WoW's taint VM.
local root = os.getenv("FLUX_TOOLTIP_SOURCE_ROOT") or "."
local function read(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local source = f:read("*a"):gsub("\r\n", "\n"); f:close(); return source
end
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local function nativeTip()
    local state = { lines = {}, hooks = {}, shown = true }
    local methods = {
        IsForbidden = function() return false end,
        IsShown = function() return state.shown end,
        GetOwner = function() return state.owner end,
        AddLine = function(_, text) state.lines[#state.lines + 1] = text end,
        NumLines = function() return #state.lines end,
        Show = function() state.shown = true end,
        HookScript = function(_, key, fn)
            state.hooks[key] = state.hooks[key] or {}
            table.insert(state.hooks[key], fn)
        end,
    }
    local tip = setmetatable({}, {
        __index = methods,
        __newindex = function(_, key) error("native tooltip field written: " .. key) end,
    })
    function state.Fire(key)
        if key == "OnTooltipCleared" then state.lines = {} end
        for _, fn in ipairs(state.hooks[key] or {}) do fn(tip) end
    end
    return tip, state
end

for _, client in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    local env = setmetatable({}, { __index = _G }); env._G = env
    local tip, state = nativeTip()
    local queued, pre, post = {}, {}, {}
    env.GameTooltip = tip
    env.C_Timer = { After = function(_, fn) queued[#queued + 1] = fn end }
    env.Enum = { TooltipDataLineType = { SellPrice = 1 }, TooltipDataType = {
        Item = 2, Spell = 3, Macro = 4, Toy = 5, PetAction = 6, Mount = 7,
    } }
    env.TooltipDataProcessor = {
        AddLinePreCall = function(kind, fn) pre[kind] = fn end,
        AddTooltipPostCall = function(kind, fn)
            post[kind] = post[kind] or {}; table.insert(post[kind], fn)
        end,
    }
    env.hooksecurefunc = function() error("unexpected native method replacement") end
    local ns = { FluxBadgeHost = { GetSlotBadges = function() return { { icon = 123 } } end } }
    assert(load(read("Binding/Core/BindingTooltip.lua"), "@binding-tooltip", "t", env))("_FluxUI", ns)
    local bt = ns.FluxBindingTooltip
    bt.InstallHooks(); bt.InstallHooks()
    check(#state.hooks.OnHide == 1 and #state.hooks.OnTooltipCleared == 1, client .. ": hooks installed once")
    -- These callbacks run even when the last tooltip belonged entirely to WoW.
    state.Fire("OnTooltipCleared"); state.Fire("OnHide")
    local owner = { _fluxBarSlotIndex = 1, GetAttribute = function() return 1 end, IsMouseOver = function() return true end }
    state.owner = owner
    check(bt.AppendForButton(owner, tip) and #state.lines == 3, client .. ": badge header and content preserved")
    check(not bt.AppendForButton(owner, tip) and #state.lines == 3, client .. ": duplicate sync append suppressed")
    for _, fn in ipairs(post[3]) do fn(tip) end
    check(#state.lines == 3, client .. ": processor append shares deduplication")
    bt.OnLabTooltip(owner)
    local queue = queued; queued = {}; for _, fn in ipairs(queue) do fn() end
    check(#state.lines == 3, client .. ": late retry preserves completed fill")
    state.Fire("OnTooltipCleared")
    bt.OnLabTooltip(owner)
    check(#state.lines == 3, client .. ": cleared native tooltip permits fresh binding lines")
    state.Fire("OnHide"); state.lines = {}
    check(bt.AppendForButton(owner, tip), client .. ": hide resets private ownership")
    local second, secondState = nativeTip()
    check(bt.AppendForButton(owner, second) and #secondState.lines == 3, client .. ": tooltip instances have independent state")

    -- Gear-set callbacks are another unconditional writer during native clears.
    local merchant, protected, inventoryProtected = true, true, true
    local lock = {
        MESSAGE = "Protected gear", ResolveBagSlotFromTooltip = function() return 0, 1 end,
        IsSlotProtected = function() return protected end,
        IsInventorySlotProtected = function() return inventoryProtected end,
        IsMerchantSellContext = function() return merchant end,
        IsDisenchantContext = function() return not merchant end,
    }
    env.FluxRespec = { GearSetLock = lock }
    env.CreateColor = function() return { GetRGB = function() return 1, 0, 0 end } end
    env.CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
    local nativeMoney = function() end
    env.GameTooltip_OnTooltipAddMoney = nativeMoney
    env.GameTooltip_ClearMoney = function() end
    assert(load(read("Respec/FluxRespec_GearSetTooltip.lua"), "@gear-tooltip", "t", env))()
    lock.InstallTooltipHooks(); lock.InstallTooltipHooks()
    state.Fire("OnTooltipCleared")
    check(pre[1](tip, {}) == true and #state.lines == 1, client .. ": protected sale keeps one warning")
    check(pre[1](tip, {}) == true and #state.lines == 1, client .. ": duplicate sale warning suppressed")
    state.Fire("OnTooltipCleared")
    check(pre[1](tip, {}) == true and #state.lines == 1, client .. ": clear permits next protected sale warning")
    protected = false
    check(pre[1](tip, {}) == false, client .. ": ordinary items keep native sell price")
    protected, merchant = true, false
    state.Fire("OnTooltipCleared")
    check(pre[1](tip, {}) == false, client .. ": nonmerchant sale line remains native")
    lock.DecorateProtectedTooltip(tip, 0, 1)
    lock.DecorateProtectedTooltip(tip, 0, 1)
    check(#state.lines == 1, client .. ": disenchant warning deduplicated")
    state.Fire("OnTooltipCleared")
    lock.DecorateProtectedInventoryTooltip(tip, 1)
    lock.DecorateProtectedInventoryTooltip(tip, 1)
    check(#state.lines == 1, client .. ": equipped protection warning preserved")
    inventoryProtected = false; state.Fire("OnTooltipCleared")
    lock.DecorateProtectedInventoryTooltip(tip, 1)
    check(#state.lines == 0, client .. ": ordinary equipped item remains native")
    check(env.GameTooltip_OnTooltipAddMoney == nativeMoney and next(tip) == nil, client .. ": native callback and table stay untouched")

    -- Both the loaded owner and retained reference implementation keep one gap.
    for _, path in ipairs({ "ExtraButtonSystem/Engine/ConsumableBind.lua", "ExtraButtonSystem/Shared/FluxEBSConsumableBridge.lua" }) do
        local source = read(path)
        local start = source:find("local tooltipGaps", 1, true)
            or assert(source:find("function Bridge.ResetFluxTooltipGap", 1, true))
        local stop = assert(source:find("function Bridge.AppendConjureSpellLines", start, true))
        local bridge = {}
        assert(load("local Bridge = ...\n" .. source:sub(start, stop - 1), "@consumable-gap", "t", env))(bridge)
        state.Fire("OnTooltipCleared")
        bridge.ResetFluxTooltipGap(tip)
        bridge._EnsureFluxTooltipGap(tip); bridge._EnsureFluxTooltipGap(tip)
        check(#state.lines == 1, client .. ": one consumable gap: " .. path)
        bridge.ResetFluxTooltipGap(tip); bridge._EnsureFluxTooltipGap(tip)
        check(#state.lines == 2, client .. ": explicit gap reset: " .. path)
        bridge._EnsureFluxTooltipGap(second)
        check(#secondState.lines == 4, client .. ": consumable gaps are per tooltip: " .. path)
        secondState.lines = { "header", "badge", "hint" }
    end
end
print("tooltip_bookkeeping: " .. checks .. " checks passed; native taint/secret VM NOT RUN")
