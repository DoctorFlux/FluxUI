-- Execute the contracts that used to depend on historical comments/file boundaries.
-- Lua mocks exercise ordinary Lua and stored secure snippets, not WoW's secure VM.
local sourcePath = debug.getinfo(1, "S").source:sub(2)
local root = (sourcePath:match("^(.*)[/\\]") or ".") .. "/../"
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end
local function near(actual, expected, message)
    check(type(actual) == "number" and math.abs(actual - expected) < 0.00001, message)
end
local function read(path)
    local file = assert(io.open(root .. path, "rb"))
    local text = file:read("*a"):gsub("\r\n", "\n")
    file:close()
    return text
end
local originals = {}
local function module(path, env, flux, replacements)
    originals[path] = originals[path] or read(path)
    local source = replacements and replacements[path] or originals[path]
    return assert(load(source, "@" .. root .. path, "t", env))("_FluxUI", { Flux = flux })
end
local function environment(client)
    local classic = client:find("classic", 1, true) ~= nil
    local flux = { Client = { branch = client, isForever = client == "forever", isCamelot = client == "forever",
        isAnyClassic = classic, isPostDF = not classic, isRetail = not classic }, Bars = {}, EBS = {}, ButtonFX = {} }
    local env = setmetatable({ locked = false, created = {}, UIParent = {}, FluxButton = {} }, { __index = _G })
    env._G = env
    env.InCombatLockdown = function() return env.locked end
    flux.Combat = { InLockdown = env.InCombatLockdown, Defer = function(key, fn)
        env.pending = env.pending or {}; env.pending[key] = fn
    end }
    local methods = {}
    function methods:GetAttribute(key) return self.attributes[key] end
    function methods:SetAttribute(key, value)
        assert(not env.locked, "protected attribute mutation attempted in combat")
        self.attributes[key] = value
    end
    function methods:GetParent() return self.parent end
    function methods:SetParent(parent)
        assert(not env.locked, "protected parenting attempted in combat")
        self.parent = parent
    end
    function methods:SetID(id) self.id = id end
    function methods:SetSize(width, height)
        assert(not env.locked, "protected sizing attempted in combat")
        self.width, self.height = width, height
    end
    function methods:GetWidth() return self.width or 44 end
    function methods:GetHeight() return self.height or 44 end
    function methods:SetScale(scale)
        assert(not env.locked, "protected scaling attempted in combat")
        self.scale = scale
    end
    function methods:GetScale() return self.scale or 1 end
    function methods:GetEffectiveScale() return self.scale or 1 end
    function methods:SetFrameLevel(level) self.level = level end
    function methods:GetFrameLevel() return self.level or 5 end
    function methods:SetPoint(...)
        assert(not env.locked, "protected anchor mutation attempted in combat")
        self.point = { ... }
    end
    function methods:ClearAllPoints()
        assert(not env.locked, "protected anchor clearing attempted in combat")
        self.point = nil
    end
    function methods:SetTexture(value) self.texture = value end
    function methods:SetText(value) self.text = value end
    function methods:SetAlpha(value) self.alpha = value end
    function methods:SetShown(value) self.hidden = not value end
    function methods:Show() self.hidden = false end
    function methods:Hide() self.hidden = true end
    function methods:IsShown() return not self.hidden end
    function methods:EnableMouse(value)
        assert(not env.locked, "protected mouse mutation attempted in combat")
        self.mouse = value; self.mouseWrites = (self.mouseWrites or 0) + 1
    end
    function methods:RegisterForClicks(...) self.clicks = { ... } end
    function methods:SetScript(key, fn) self.scripts[key] = fn end
    function methods:HookScript(key, fn) self.scripts[key] = fn end
    local noop = function() end
    local mt = { __index = function(_, key)
        if methods[key] then return methods[key] end
        if key:match("^Set") or key:match("^Register") or key:match("^Unregister")
            or key == "Execute" or key == "WrapScript" then return noop end
    end }
    env.CreateFrame = function(_, name, parent)
        assert(not env.locked, "protected fixture creation attempted in combat")
        local frame = setmetatable({ attributes = {}, scripts = {}, parent = parent }, mt)
        if name then env[name] = frame end
        env.created[#env.created + 1] = frame
        return frame
    end
    return env, flux
end
-- Reach private production helpers through closures, without copying their source.
local function closure(fn, wanted, seen)
    seen = seen or {}
    if type(fn) ~= "function" or seen[fn] then return end
    seen[fn] = true
    local children = {}
    for i = 1, math.huge do
        local name, value = debug.getupvalue(fn, i)
        if not name then break end
        if name == wanted then return value end
        if type(value) == "function" then children[#children + 1] = value end
    end
    for _, child in ipairs(children) do
        local found = closure(child, wanted, seen)
        if found then return found end
    end
end

local function inputCase(client, replacements)
    local env, flux = environment(client)
    module("Bars/SlotMath.lua", env, flux, replacements)
    module("Bars/State.lua", env, flux, replacements)
    local state = flux.Bars.State
    local host = env.CreateFrame("CheckButton")
    state.Attach(env.UIParent, host, 1, "main")
    -- Run the actual snippet captured by Attach, including its modifier routing.
    env.self, env.message = host, "101"
    host:SetAttribute("flux-has-sec", 1)
    host:SetAttribute("flux-has-tert", 1)
    env.GetActionInfo = function(slot) return "spell", slot end
    env.IsPressHoldReleaseSpell = function(id) return id == 61 end
    assert(load(host:GetAttribute("_childupdate-state"), "secure-child-update", "t", env))()
    check(host:GetAttribute("action") == 61 and host:GetAttribute("shift-action*") == 61,
        client .. ": modifier display and click resolve secondary slot")
    check(host:GetAttribute("IsEmpowerSpell") == true and host:GetAttribute("ctrl-IsEmpowerSpell*") == false,
        client .. ": empower gates follow each live modifier spell")
    check(host:GetAttribute("pressAndHoldAction") == (client ~= "forever"),
        client .. ": wrap clients retain hold routing; Forever mouse releases remain native")
    if client == "forever" then
        local keyer = env.CreateFrame("CheckButton", "FluxActionStripKey1")
        host:SetAttribute("flux-p-61", "/cast Test")
        state.StampLiveClick(host, 61)
        check(keyer:GetAttribute("macrotext1") == "/cast Test" and keyer:GetAttribute("useOnKeyDown") == true,
            "Forever macro proxy casts its actual macro on key-down")
        check(keyer:GetAttribute("pressAndHoldAction") == false and keyer.clicks[1] == "AnyDown" and keyer.clicks[2] == "AnyUp",
            "Forever macro proxy explicitly clears hold without changing host release semantics")
    end
end

local function raidCase(client, replacements)
    local env, flux = environment(client)
    local secret = {}
    env.UnitExists = function() return env.exists end
    env.FluxRaidCompat = { IsSecret = function(value) return value == secret end, UnitTokenValid = function(unit)
        return type(unit) == "string" and unit ~= "" and env.exists ~= false
    end }
    env.FluxRaidState = { frameArray = {}, mtmaHeader = {} }
    local tooltipCalls, anchors = 0, 0
    env.GameTooltip = { SetUnit = function(_, token)
        assert(type(token) == "string" and token ~= "", "SetUnit received missing token")
        tooltipCalls = tooltipCalls + 1; return env.tooltipSuccess
    end, Show = function() end }
    env.GameTooltip_SetDefaultAnchor = function() anchors = anchors + 1 end
    module("RaidFrame/FluxRaidUnit.lua", env, flux, replacements)
    local button = { mouseOverHighlight = env.CreateFrame("Texture") }
    for _, token in ipairs({ false, "", 42, {} }) do
        button.unit = token; env.FluxRaidUnit_OnEnter(button)
        check(button.UpdateTooltip == nil and tooltipCalls == 0 and anchors == 0,
            client .. ": invalid raid tokens never reach native tooltip")
    end
    button.unit = nil; env.FluxRaidUnit_OnEnter(button)
    check(tooltipCalls == 0, client .. ": nil raid token does not reach SetUnit")
    button.unit, env.tooltipSuccess = "raid1", true
    env.FluxRaidUnit_OnEnter(button)
    check(tooltipCalls == 1 and type(button.UpdateTooltip) == "function", client .. ": valid raid tooltip refresh remains active")
    env.tooltipSuccess = false; button:UpdateTooltip()
    check(button.UpdateTooltip == nil, client .. ": tooltip refresh stops on native rejection")
    local mini, wrap = env.CreateFrame("Button"), env.CreateFrame("Frame")
    mini.unit, mini._fluxWrap = "raid1target", wrap
    button._fluxMTMATarget = mini
    for _, modern in ipairs({ false, true }) do
        if modern then
            wrap.SetAlphaFromBoolean = function(self, value, yes, no)
                self.secretAlpha = value
                if value ~= secret then self.alpha = value and yes or no end
            end
        else wrap.SetAlphaFromBoolean = false end
        env.locked, env.exists = false, false
        mini.mouse = true
        env.FluxRaid_AttachOrUpdateMTMATarget(button, nil)
        check(wrap.alpha == 0 and mini.mouse == false, client .. ": invisible mini disables mouse on both alpha APIs")
        env.exists = true; env.FluxRaid_AttachOrUpdateMTMATarget(button, nil)
        check(wrap.alpha == 1 and mini.mouse == true, client .. ": visible mini restores mouse")
        local writes = mini.mouseWrites
        env.locked, env.exists = true, false
        env.FluxRaid_AttachOrUpdateMTMATarget(button, nil)
        check(wrap.alpha == 0 and mini.mouseWrites == writes, client .. ": combat alpha updates perform no protected mouse mutation")
        env.locked = false; env.FluxRaid_AttachOrUpdateMTMATarget(button, nil)
        check(mini.mouse == false and mini.mouseWrites == writes + 1, client .. ": post-combat refresh reconciles mouse once")
    end
    env.exists = secret
    env.FluxRaid_AttachOrUpdateMTMATarget(button, nil)
    check(wrap.secretAlpha == secret, client .. ": secret existence passes directly to native boolean-alpha API")
    env.exists = false
    wrap.SetAlphaFromBoolean = function() error("native alpha unavailable") end
    env.FluxRaid_AttachOrUpdateMTMATarget(button, nil)
    check(wrap.alpha == 0 and mini.mouse == false, client .. ": failing native alpha helper uses readable fallback and disables mouse")
end

local function stanceHiderCase(client, replacements)
    local env, flux = environment(client)
    module("Bars/Blizzard.lua", env, flux, replacements)
    local park = assert(closure(flux.Bars.Blizzard.KillLeftoverMouse, "ParkStockStanceBar"), "actual stance hider closure exists")
    local bar = env.CreateFrame("Frame", nil, env.UIParent)
    local classic = flux.Client.isAnyClassic
    for _, policy in ipairs({ { true, true }, { false, false }, { false, true }, { true, false } }) do
        local paging, generic = table.unpack(policy)
        flux.Restricted = { PagingWorks = function() return paging end, Works = function() return generic end }
        bar.parent = env.UIParent
        env.locked = true; park(bar)
        check(bar.parent == env.UIParent, client .. ": stance parenting respects lockdown")
        env.locked = false; park(bar)
        local shouldPark = classic or (client == "forever" and not paging) or (client ~= "forever" and not generic)
        check((bar.parent == env.FluxStanceHider) == shouldPark, client .. ": stance parenting follows classic and restricted-handler capabilities")
        if shouldPark then
            local count = #env.created; park(bar)
            check(bar.parent == env.FluxStanceHider and #env.created == count, client .. ": stance hider is idempotent")
        end
    end
end

local function stockControllerCase(client, replacements)
    local env, flux = environment(client)
    local wraps, nativeCalls, hides, failed = {}, 0, 0, false
    local create = env.CreateFrame
    env.CreateFrame = function(...)
        local f = create(...)
        function f:SetFrameRef(key, bar)
            self.refs = self.refs or {}
            -- Restricted HANDLE:Hide invokes the captured widget method, not
            -- the stock bar's Lua HideOverride (see RestrictedFrames.lua).
            self.refs[key] = { Hide = function(_, skipAttr)
                check(skipAttr == true, "stock controller does not write statehidden on native bars")
                bar.hidden = true; hides = hides + 1
            end, SetAlpha = function(_, value) bar.alpha = value end,
                EnableMouse = function(_, value) bar.mouse = value end }
        end
        function f:GetFrameRef(key) return self.refs[key] end
        function f:Execute(body)
            local e = setmetatable({ self = self, control = self }, { __index = env })
            return assert(load(body, "secure-stock-controller", "t", e))()
        end
        function f:WrapScript(button, script, pre, post)
            check(not env.locked, "stock controller handler setup waits for combat")
            if failed then error("simulated handler setup failure") end
            check(wraps[button] == nil, "stock controller never accumulates wrappers")
            wraps[button] = { header = self, pre = pre, post = post, script = script }
        end
        return f
    end
    env.SecureCmdOptionParse = function() return env.possess and "1" or nil end
    flux.Restricted = { PagingWorks = function() return true end }
    module("Bars/Blizzard.lua", env, flux, replacements)
    local suppress = assert(closure(flux.Bars.Blizzard.KillLeftoverMouse, "SecureHideRetailStanceBar"))
    local possess = assert(closure(flux.Bars.Blizzard.KillLeftoverMouse, "HideStockPossessBars"))
    local bar = create("Frame", nil, env.UIParent)
    local button = create("CheckButton", nil, bar)
    function button:IsProtected() return true, true end
    bar.actionButtons = { button }
    function bar:Hide() error("native Lua HideOverride must never run from addon code") end
    env.locked = true
    check(suppress(bar) == "pending" and next(wraps) == nil, client .. ": combat startup retains native controller")
    env.locked = false; failed = true
    check(suppress(bar) == "failed", client .. ": failed wrapper install is reported")
    failed = false
    check(suppress(bar) == "secured", client .. ": failed setup is retryable")
    local count = #env.created
    check(suppress(bar) == "secured" and #env.created == count, client .. ": repeated suppression reuses the handler")
    local function nativeShow()
        bar.hidden = false
        button.hidden = false
        local w = assert(wraps[button])
        local handle = { Hide = function(_, skipAttr)
            check(skipAttr == true, "stock button does not write statehidden")
            button.hidden = true
        end }
        local e = setmetatable({ self = handle, control = w.header }, { __index = env })
        local allow, message = assert(load(w.pre, "stock-OnShow-pre", "t", e))()
        if allow ~= false then nativeCalls = nativeCalls + 1 end
        -- Blizzard CreateSimpleWrapper's exact dispatch contract: message is
        -- the SECOND return from pre; nil prevents post execution.
        if message ~= nil then
            e.message = message
            assert(load(w.post, "stock-OnShow-post", "t", e))()
        end
    end
    env.locked = true; nativeShow()
    check(button.hidden and bar.alpha == 0 and bar.mouse == false and nativeCalls == 1,
        client .. ": native OnShow executes and secure stance hide survives combat")
    check(not bar.hidden, client .. ": stance callback cannot reenter parent OnShow/Update")
    bar.hidden = false -- Native StanceBarMixin.Update's final SetShown(true).
    check(button.hidden, client .. ": native update tail cannot reveal replaced stance buttons")
    env.locked = false
    -- Use the real possess coordinator, including its replacement readiness.
    bar = create("Frame", nil, env.UIParent)
    button = create("CheckButton", nil, bar)
    function button:IsProtected() return true, true end
    bar.actionButtons = { button }
    function bar:Hide() error("native Lua HideOverride must never run from addon code") end
    env.PossessActionBar = bar
    flux.Bars.secureReady = false; bar.hidden = false; possess()
    check(not bar.hidden and wraps[button] == nil, "possess fallback remains until Flux input is ready")
    flux.Bars.secureReady = true
    possess(); check(bar.hidden and wraps[button], "empty Edit Mode possess bar is suppressed")
    env.locked = true; nativeShow()
    check(bar.hidden, "empty possess bar remains suppressed in combat")
    env.possess = true; nativeShow()
    check(not bar.hidden and not button.hidden, "real native possession/cancel controls remain visible and usable in combat")
    env.locked = false; possess()
    check(not bar.hidden, "out-of-combat reconciliation retains native possession controls")
    env.possess = false; possess(); check(bar.hidden, "possession ending reconciles empty stock bar")
    check(nativeCalls == 3 and hides > 0, "native callbacks remain intact across controller transitions")
end

local function badgeCase(client, replacements)
    local env, flux = environment(client)
    flux.Spell = { GetTexture = function(id) return env.icons and env.icons[id] end }
    module("ExtraButtonSystem/Engine/Paint.lua", env, flux, replacements)
    local btn = { badgeMode = true, ActionType = "spell", ActionValue = 100, WIcon = env.CreateFrame("Texture") }
    flux.EBS.Paint.UpdateIcon(btn)
    check(btn.WIcon.texture == "Interface\\Icons\\INV_Misc_QuestionMark" and not btn.WIcon.hidden,
        client .. ": unresolved corner stays occupied with its existing placeholder")
    env.icons = { [100] = 999, [200] = 888 }
    flux.EBS.Paint.UpdateIcon(btn)
    check(btn.WIcon.texture == 999, client .. ": arriving spell data replaces badge placeholder")
    btn.ActionValue, btn._fluxWant = 300, { spellId = 200 }
    flux.EBS.Paint.UpdateIcon(btn)
    check(btn.WIcon.texture == 888, client .. ": badge uses requested spell identity while action data loads")
    btn.ActionType, btn.ActionValue = nil, nil
    flux.EBS.Paint.UpdateIcon(btn)
    check(btn.WIcon.hidden, client .. ": genuinely empty badge clears its previous icon")
    module("ExtraButtonSystem/Engine/Badge.lua", env, flux, replacements)
    local host, widget = env.CreateFrame("Button"), env.CreateFrame("Button")
    host:SetSize(33, 44)
    local badge = { Widget = widget }
    flux.EBS.Badge.Layout(badge, host, 2)
    near(widget.width, 33, client .. ": badge face uses native authored width with x squeeze")
    near(widget.height, 44, client .. ": badge retains authored native height")
    near(widget.scale, 1 / 3, client .. ": badge scales native VFX with the widget")
    near(badge.SlotFrame.width, 11, client .. ": badge SlotFrame packs visual width")
    near(badge.SlotFrame.height, 44 / 3, client .. ": badge SlotFrame packs visual height")
end

local function geometryCase(client, replacements)
    local env, flux = environment(client)
    module("Core/ButtonFX/Overlay.lua", env, flux, replacements)
    local overlay = flux.ButtonFX.Overlay
    local layoutCast = assert(closure(overlay.PlayCast, "LayoutCastFrame"))
    for _, size in ipairs({ { 44, 44 }, { 33, 44 }, { 22, 22 } }) do
        local widget, cf = env.CreateFrame("Button"), env.CreateFrame("Frame")
        widget:SetSize(size[1], size[2])
        cf.Fill, cf.EndBurst = env.CreateFrame("Frame"), env.CreateFrame("Frame")
        cf.Fill.FillMask = env.CreateFrame("Texture"); cf.Fill.FillMask:SetSize(36, 36)
        layoutCast(widget, cf, true)
        near(cf.width, 128 * size[1] / 44, client .. ": SpellFX frame uses 44px authored x ratio")
        near(cf.height, 128 * size[2] / 44, client .. ": SpellFX frame uses 44px authored y ratio")
        near(cf.Fill.FillMask.width, 36 * size[1] / 44, client .. ": native masks scale once per axis")
        layoutCast(widget, cf, true)
        near(cf.Fill.FillMask.width, 36 * size[1] / 44, client .. ": repeated VFX layout does not compound mask sizing")
    end
    local frame, widget = env.CreateFrame("Frame"), env.CreateFrame("Button")
    local btn = { Widget = widget }
    local stance = { STANCE_SIZE = 20, STANCE_SPACING = 2, MAX_ROWS_PER_COLUMN = 5, BORDER_PAD_H = 2,
        BORDER_PAD_V = 2, PET_SLOT_LAYOUT_PAD_H = 2, PET_SLOT_LAYOUT_PAD_V = 2,
        GetFrame = function() return frame end, Catalog = function() return 1, {}, {}, 1 end,
        ShouldAnchorToPlayerBorder = function() return true end, GetSavedOrder = function() return {} end,
        BuildPermutation = function() return { 1 } end, EnsureFormButton = function() return btn end,
        ApplyBorderChrome = function() end, ReassignBindings = function() return true end }
    flux.Bars.Stance, flux.Bars.CONFIG = stance, { buttonSize = 44 }
    env.FluxUILayoutSqueeze = { GetEffectiveEmulatedDependentXFactorForUnitFrames = function() return env.squeeze end }
    module("Bars/Stance/Layout.lua", env, flux, replacements)
    for _, squeeze in ipairs({ 1, 0.75 }) do
        env.squeeze = squeeze
        check(stance.ApplyLayout(), client .. ": stance layout completes")
        local size = widget._fluxStanceButtonSize
        near(widget.width, 44 * squeeze, client .. ": stance face preserves per-axis native squeeze")
        near(widget.height, 44, client .. ": stance face retains native authored height")
        near(widget.scale, size / 44, client .. ": stance visual scale follows computed button size")
        near(btn.SlotFrame.width, size * squeeze, client .. ": stance SlotFrame tracks squeezed visual width")
        near(btn.SlotFrame.height, size, client .. ": stance SlotFrame tracks live button height")
        check(widget.parent == btn.SlotFrame and widget.point[1] == "CENTER", client .. ": stance widget remains centered in persistent SlotFrame")
    end
    local count, width = #env.created, frame.width
    env.locked = true
    check(stance.ApplyLayout() == false and #env.created == count and frame.width == width,
        client .. ": combat stance relayout defers before structural writes")
end

local function run(replacements)
    for _, client in ipairs({ "live", "classic_era", "classic_anniversary", "classic", "forever" }) do
        inputCase(client, replacements)
        raidCase(client, replacements)
        stanceHiderCase(client, replacements)
        stockControllerCase(client, replacements)
        badgeCase(client, replacements)
        geometryCase(client, replacements)
    end
end
run()
local productionChecks = checks
local mutations = {
    { "Bars/State.lua", 'self:GetAttribute("flux-native-click") ~= 1', "false", "wrap-client hold gate", "wrap clients retain hold" },
    { "RaidFrame/FluxRaidUnit.lua", 'if type(unit) ~= "string" or unit == "" then\n        self.UpdateTooltip',
        'if false then\n        self.UpdateTooltip', "raid token guard", "SetUnit received missing token" },
    { "RaidFrame/FluxRaidUnit.lua", 'alphaApplied = pcall(wrap.SetAlphaFromBoolean, wrap, ex, 1, 0)',
        'alphaApplied = pcall(wrap.SetAlphaFromBoolean, wrap, ex, 1, 0)\n            return', "native alpha early return", "invisible mini disables mouse" },
    { "Bars/Blizzard.lua", 'if not UseStanceHider() or InLockdown() then', 'if InLockdown() then', "stance client/capability gate", "stance parenting follows" },
    { "Bars/Blizzard.lua", 'local STANCE_SHOW_PRE = [[ return nil, true ]]',
        'local STANCE_SHOW_PRE = [[ return nil ]]', "secure OnShow post dispatch", "secure stance hide survives combat" },
    { "Bars/Blizzard.lua", 'elseif not SecureCmdOptionParse("[possessbar] 1") then', 'elseif true then',
        "native possess controls", "possession/cancel controls remain visible" },
    { "Bars/Blizzard.lua", 'self:Hide(true)', '', "stance child visibility", "secure stance hide survives combat" },
    { "Bars/Blizzard.lua", 'self:Hide(true)', 'self:Hide(true)\n            bar:Hide(true)',
        "stance parent OnShow reentry", "stance callback cannot reenter parent OnShow/Update" },
    { "ExtraButtonSystem/Engine/Paint.lua", 'SetIconTexture(btn, QUESTION)', 'SetIconTexture(btn, nil)', "occupied badge placeholder", "unresolved corner stays" },
    { "ExtraButtonSystem/Engine/Badge.lua", 'widget:SetSize(faceW, native)', 'widget:SetSize(43, 43)', "badge native authoring size", "badge face uses native" },
    { "Core/ButtonFX/Overlay.lua", 'local CAST_REF_W = 44', 'local CAST_REF_W = 43', "VFX authoring size", "SpellFX frame uses" },
    { "Bars/Stance/Layout.lua", 'btn.Widget:SetSize(faceW, faceH)', 'btn.Widget:SetSize(native, native)', "stance per-axis squeeze", "stance face preserves" },
    { "Bars/Stance/Layout.lua", 'slot:SetSize(slotW, size)', 'slot:SetSize(size, size)', "stance live slot width", "stance SlotFrame tracks" },
}
for _, mutation in ipairs(mutations) do
    local path, before, after, label, expectedFailure = table.unpack(mutation)
    local source = assert(originals[path])
    local first, last = source:find(before, 1, true)
    check(first ~= nil, "mutation anchor exists: " .. label)
    local mutated = source:sub(1, first - 1) .. after .. source:sub(last + 1)
    local ok, err = pcall(run, { [path] = mutated })
    check(not ok and tostring(err):find(expectedFailure, 1, true),
        "behavioral coverage rejects mutation at the intended assertion: " .. label .. ": " .. tostring(err))
end
print(("bars contract regression: %d production checks across five clients; %d mutations rejected"):format(productionChecks, #mutations))
return { pressAndHold = true, raidTooltip = true, mtmaMouse = true, stanceHider = true,
    badgeIcon = true, vfxGeometry = true, stanceGeometry = true }
