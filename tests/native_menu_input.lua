-- Preserve native menu callback ownership and protected-gear tooltip behavior.
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local micro = read("MicroMenu/FluxMicroMenu.lua")
local a = assert(micro:find("local fluxSkipUpdateMicroButtonsHook", 1, true))
local b = assert(micro:find("-- Public API to force a full rebuild", a, true))
local microHook = micro:sub(a, b - 1)
local function microCase(branch, source)
    local modern = branch == "live" or branch == "forever"
    local client = { isRetail = modern, isPostDF = modern, isForever = branch == "forever", isCamelot = branch == "forever" }
    local hooks = 0
    local env = { Flux = { Client = client }, FLUX_API = client, UpdateMicroButtons = function() end,
        hooksecurefunc = function() hooks = hooks + 1 end }
    assert(load(source or microHook, "@native-micro-hook", "t", env))()
    check(hooks == (modern and 0 or 1), branch .. ": native secure menu refresh is free of addon hooks on modern clients")
end
local tooltipSource = read("Respec/FluxRespec_GearSetTooltip.lua")
local function tooltipCase(processors)
    local env = setmetatable({}, { __index = _G }); env._G = env
    local hooks, pre, posts, nativeCalls, cleared, added = {}, {}, {}, 0, 0, 0
    local merchant, protected = true, true
    local tip = { IsForbidden = function() return false end, Show = function() end,
        AddLine = function() added = added + 1 end, HookScript = function() end }
    env.GameTooltip = tip
    env.GameTooltip_OnTooltipAddMoney = function() nativeCalls = nativeCalls + 1; return "native return" end
    local original = env.GameTooltip_OnTooltipAddMoney
    env.GameTooltip_ClearMoney = function() cleared = cleared + 1 end
    env.CreateColor = function() return { GetRGB = function() return 1, 0, 0 end } end
    env.CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
    env.hooksecurefunc = function(name, fn) hooks[name] = fn end
    env.Enum = { TooltipDataLineType = { SellPrice = 1 }, TooltipDataType = { Item = 2 } }
    if processors then env.TooltipDataProcessor = {
        AddLinePreCall = function(kind, fn) pre[kind] = fn end,
        AddTooltipPostCall = function(kind, fn) posts[kind] = fn end,
    } end
    local lock = { MESSAGE = "Protected gear", ResolveBagSlotFromTooltip = function() return 0, 1 end,
        IsSlotProtected = function() return protected end, IsMerchantSellContext = function() return merchant end }
    env.FluxRespec = { GearSetLock = lock }
    assert(load(tooltipSource, "@gear-tooltip", "t", env))()
    lock.InstallTooltipHooks(); lock.InstallTooltipHooks()
    check(env.GameTooltip_OnTooltipAddMoney == original, "native money callback identity never replaced")
    if processors then
        check(pre[1] and posts[2] and not hooks.GameTooltip_OnTooltipAddMoney, "modern tooltip processors own filtering")
        check(pre[1](tip, {}) == true and added == 1, "protected merchant sell price replaced with protection line")
        protected = false; check(pre[1](tip, {}) == false, "unprotected gear keeps native sell-price line")
        protected, merchant = true, false; check(pre[1](tip, {}) == false, "non-merchant tooltip remains intact")
    else
        check(hooks.GameTooltip_OnTooltipAddMoney, "legacy money filtering remains available")
        check(original(tip, 25) == "native return", "native callback return preserved")
        hooks.GameTooltip_OnTooltipAddMoney(tip, 25)
        check(nativeCalls == 1 and cleared == 1 and added == 1, "legacy protected price removed after native display")
        protected = false; hooks.GameTooltip_OnTooltipAddMoney(tip, 25)
        check(cleared == 1 and added == 1, "legacy unprotected money remains unchanged")
    end
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    microCase(branch); tooltipCase(true); tooltipCase(false)
end
local old = microHook:gsub('Flux.Client.isRetail and Flux.Client.isPostDF', 'Flux.Client.isForever')
    :gsub('FLUX_API.isRetail and FLUX_API.isPostDF', 'FLUX_API.isForever')
check(not pcall(microCase, "live", old), "negative control rejects Forever-only menu protection")
print("Native menu/input ownership: " .. checks .. " checks; five client models; negative control passed")
