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
-- Exercise the real options Escape code. Registering an addon handler sorts
-- Blizzard's shared secure entries; even a late priority is unsafe there.
local shellSource = read("AddonOptions/FluxOptionsShell.lua")
local escapeStart = assert(shellSource:find("local escapeInstalled = false", 1, true))
local escapeEnd = assert(shellSource:find("function Shell:EnsureFrame()", escapeStart, true))
local escapeSource = shellSource:sub(escapeStart, escapeEnd - 1)
local function optionsEscapeCase(branch)
    local registrations, bindings, clears, hides, combat, menuOpen = 0, 0, 0, 0, false, false
    local frames = {}
    local frame = { shown = true }
    function frame:IsShown() return self.shown end
    local shell = { frame = frame }
    function shell:Hide() hides = hides + 1; self.frame.shown = false end
    local env = setmetatable({ Shell = shell, UISpecialFrames = {"OtherAddon", "FluxUIOptionsFrame"},
        GameMenuEscPriority = {AddOnPost2=10,World=11},
        RegisterGameMenuEscHandler = function() registrations = registrations + 1 end,
        InCombatLockdown = function() return combat end,
        SetOverrideBindingClick = function(owner, priority, key, button, click)
            check(not combat and owner == frame and priority and key == "ESCAPE"
                and button == "FluxUIOptionsEscapeButton" and click == "LeftButton", branch..": options-only Escape binding")
            bindings = bindings + 1
        end,
        ClearOverrideBindings = function(owner) check(owner == frame, "only options bindings cleared"); clears = clears + 1 end,
        Menu = {GetManager = function() return {HandleESC = function() local open=menuOpen;menuOpen=false;return open end} end},
        CreateFrame = function(kind, name, parent)
            local f = {events={},scripts={}}
            function f:SetSize() end; function f:SetPoint() end; function f:EnableMouse() end
            function f:SetScript(key, fn) self.scripts[key] = fn end
            function f:RegisterEvent(event) self.events[event] = true end
            function f:UnregisterEvent(event) self.events[event] = nil end
            frames[#frames+1] = f
            return f
        end,
    }, {__index=_G})
    env._G = env
    local install, arm, disarm = assert(load(escapeSource.."\nreturn InstallEscapeClose, ArmEscapeBinding, DisarmEscapeBinding", "@options-escape", "t", env))()
    install(frame); install(frame)
    check(registrations == 0, branch..": options never modifies Blizzard's Escape handler table")
    check(#frames == 1 and shell._escapeBinding, branch..": one reusable Escape button")
    check(#env.UISpecialFrames == 1 and env.UISpecialFrames[1] == "OtherAddon", branch..": unrelated special frames preserved")
    arm(frame)
    menuOpen = true; frames[1].scripts.OnClick()
    check(hides == 0 and not menuOpen, branch..": dropdown consumes first Escape")
    frames[1].scripts.OnClick();disarm(frame)
    check(hides == 1 and bindings == 1 and clears == 1, branch..": options closes and restores native Escape")
    combat = true;frame.shown = true;arm(frame)
    check(bindings == 1 and frames[2].events.PLAYER_REGEN_ENABLED, branch..": combat defers binding changes")
    combat = false;frames[2].scripts.OnEvent(frames[2])
    check(bindings == 2 and not frames[2].events.PLAYER_REGEN_ENABLED, branch..": deferred binding restored once")
    combat = true;arm(frame);frame.shown = false;disarm(frame)
    check(frames[2].events.PLAYER_REGEN_ENABLED, branch..": combat close retains pending cleanup")
    combat = false;frames[2].scripts.OnEvent(frames[2])
    check(bindings == 2 and clears == 2 and not frames[2].events.PLAYER_REGEN_ENABLED, branch..": hidden options clears Escape after combat")
end
for _, branch in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
    microCase(branch); tooltipCase(true); tooltipCase(false); optionsEscapeCase(branch)
end
local old = microHook:gsub('Flux.Client.isRetail and Flux.Client.isPostDF', 'Flux.Client.isForever')
    :gsub('FLUX_API.isRetail and FLUX_API.isPostDF', 'FLUX_API.isForever')
check(not pcall(microCase, "live", old), "negative control rejects Forever-only menu protection")
print("Native menu/input ownership: " .. checks .. " checks; five client models; negative control passed")
