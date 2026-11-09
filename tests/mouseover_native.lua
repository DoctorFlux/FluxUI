-- Loaded addon + Blizzard targeting/control functions; no WoW taint/FPS claim.
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function read(path)
    local f = assert(io.open(path, "r")); local s = f:read("*a"); f:close()
    return s:gsub("\r\n", "\n")
end
local source = read(arg[1] or "Core/Engine/MouseoverCast.lua")
local function run(s, env, ns)
    return assert(load(s, "@mouseover_native", "t", env))("_FluxUI", ns)
end
local function fixture(supported, cvar, wraps)
    local f = { value = cvar, supported = supported, modifier = "NONE", held = false,
        queue = {}, events = {}, deferred = {}, frames = {}, wrapCount = 0, notifications = 0, opens = 0 }
    local e = setmetatable({}, { __index = _G }); e._G = e
    f.env = e
    local function frame(kind, name)
        local w = { attrs = {}, scripts = {}, name = name, shown = false,
            scale = 1, strata = "MEDIUM", level = 2, points = {} }
        function w:SetAttribute(k, v)
            check((not f.combat or f.secure) and not f.nativeStack, "protected changes leave combat/native callback stack")
            self.attrs[k] = v
        end
        function w:GetAttribute(k) return self.attrs[k] end
        function w:SetScript(k, fn) self.scripts[k] = fn end
        function w:SetChecked(v) self.checked = v end
        function w:GetChecked() return self.checked end
        function w:Show() self.shown = true end
        function w:Hide() self.shown = false end
        function w:IsShown() return self.shown end
        function w:IsVisible() return self.shown end
        function w:GetParent() return self.parent end
        function w:WrapScript(widget, script, body) widget.scripts[script] = body end
        function w:UnwrapScript(widget, script) widget.scripts[script] = nil end
        function w:SetParent(parent)
            check(not f.nativeStack and not f.combat, "checkbox ownership changes outside native stack/combat")
            self.parent = parent; f.parentWrites = (f.parentWrites or 0) + 1
        end
        function w:GetNumPoints() return #self.points end
        function w:GetPoint(i) return table.unpack(self.points[i]) end
        function w:SetPoint(...) self.points[#self.points + 1] = {...} end
        function w:ClearAllPoints() self.points = {} end
        function w:GetScale() return self.scale end
        function w:SetScale(v) self.scale = v end
        function w:GetFrameStrata() return self.strata end
        function w:SetFrameStrata(v) self.strata = v end
        function w:GetFrameLevel() return self.level end
        function w:SetFrameLevel(v) self.level = v end
        function w:GetStringWidth() return 90 end
        function w:CreateFontString() return frame() end
        function w:CreateTexture() return frame() end
        for _, k in ipairs({"SetSize", "SetText", "SetTextColor", "SetAllPoints",
            "SetColorTexture", "SetBlendMode", "SetHitRectInsets"}) do w[k] = function() end end
        function w:CalculateAction() return 1 end
        f.frames[#f.frames + 1] = w
        if name then e[name] = w end
        return w
    end
    f.frame = frame
    local flux = { Cap = { hasRestrictedClosures = wraps }, Client = { isRetail = true },
        Timer = { After = function(_, fn) f.queue[#f.queue + 1] = fn end },
        Combat = { InLockdown = function() return f.combat end,
            Defer = function(k, fn) f.deferred[k] = fn end },
        Events = { Register = function(k, fn) f.events[k] = fn end },
        Restricted = { SetSnippet = function() end, Execute = function() end,
            UnwrapScript = function(_, w, script) w.scripts[script] = nil end,
            WrapScript = function(_, w, script, body) w.scripts[script] = body; f.wrapCount = f.wrapCount + 1 end },
        SpellBookChrome = { Observe = function(_, show, hide, update, poll)
            f.showBook, f.hideBook, f.updateBook, f.pollBook = show, hide, update, poll
        end, GetHost = function() return f.book end,
            Layout = function(opts) if opts.mouseover then opts.mouseover:SetParent(f.book); opts.mouseover:Show() end end } }
    f.flux = flux
    e.CreateFrame, e.UIParent = frame, frame()
    e.C_CVar = { GetCVar = function() return f.value end }
    e.GetCVarBool = function() return f.value == "1" end
    e.IsMouseoverCastSupported = supported ~= nil and function() return f.supported end or nil
    e.GetModifiedClick = function() return f.modifier end
    e.IsModifiedClick = function() return f.held end
    e.IsShiftKeyDown = function() return false end
    e.IsControlKeyDown = function() return false end
    e.IsAltKeyDown = function() return false end
    e.UnitExists = function() return f.mouseover ~= false end
    e.SecureCmdOptionParse = function(condition)
        if not e.UnitExists("mouseover") then return nil end
        if condition:find(",help", 1, true) and not f.friendly then return nil end
        if condition:find(",harm", 1, true) and f.friendly then return nil end
        return "mouseover"
    end
    e.GetTime = function() return 100 end
    f.book = frame(); f.book.shown = true
    e.ClickBindingFrame_LoadUI = function()
        if e.ClickBindingFrame then return end
        local panel, checkbox = frame(), frame()
        checkbox.parent = panel
        checkbox:SetPoint("TOPLEFT", panel, "TOPLEFT", 60, -30)
        checkbox.Label = frame()
        checkbox.scripts.OnClick = e.ClickableBindingsEnableMouseoverCastCheckboxMixin.OnClick
        checkbox.scripts.OnEnter = e.ClickableBindingsEnableMouseoverCastCheckboxMixin.OnEnter
        panel.EnableMouseoverCastCheckbox = checkbox
        e.ClickBindingFrame, f.nativeCheckbox = panel, checkbox
    end
    e.ToggleClickBindingFrame = function()
        e.ClickBindingFrame_LoadUI(); f.opens = f.opens + 1
        e.ClickBindingFrame.shown = not e.ClickBindingFrame.shown
    end
    e.PlaySound = function() end
    e.SOUNDKIT = {}
    e.FluxBinding = { NotifySettingsChanged = function()
        check(not f.nativeStack, "binding notification leaves native callback stack")
        f.notifications = f.notifications + 1
    end }
    f.db = { mouseoverCast = false }
    e.FluxOptions = { GetActionbarsDB = function() return f.db end }
    e._FluxUI_CharSavedVars = { mouseoverCast = true }
    e.SetCVar = function(_, value)
        check(f.nativeStack, "only Blizzard's control writes the native CVar")
        f.value = value
        f.events.CVAR_UPDATE("CVAR_UPDATE", "enableMouseoverCast", value)
    end
    function f.flush()
        local queue = f.queue; f.queue = {}
        for _, fn in ipairs(queue) do fn() end
    end
    run(source, e, { Flux = flux })
    f.mc = flux.MouseoverCast
    return f
end

for _, branch in ipairs({ "live", "forever" }) do
    local f = fixture(true, "0", branch == "live")
    local mc, e = f.mc, f.env
    -- Also verify the legacy global getter when C_CVar is unavailable.
    local namespaced = e.C_CVar
    e.GetCVar, e.C_CVar = namespaced.GetCVar, nil
    check(mc.UsesNativeCVar(), branch .. " native detection supports the global CVar getter")
    e.C_CVar = namespaced
    check(mc.UsesNativeCVar(), branch .. " uses Blizzard support despite wrap capability")
    check(not mc.IsEnabled(), branch .. " native off wins over saved custom on")
    f.db.mouseoverCast = true
    check(not mc.IsEnabled(), branch .. " scoped custom preference cannot turn native on")
    local w = f.frame(); w.attrs.type = "action"
    mc.AttachHost(w); mc.Start()
    check(w.attrs.checkmouseovercast == true, branch .. " native checks stay prepared while off")
    check(f.wrapCount == 0, branch .. " native clients install no custom unit-pick wrap")
    -- Execute the supplied Blizzard checkbox, including synchronous CVAR_UPDATE.
    local native = read("../__AddonsForRef/wow-ui-source-" .. branch .. "/Interface/AddOns/Blizzard_ClickBindingUI/Blizzard_ClickBindingUI.lua")
    local start = assert(native:find("ClickableBindingsEnableMouseoverCastCheckboxMixin =", 1, true))
    run(native:sub(start), e, {})
    f.showBook()
    check(not e.FluxMouseoverCastCheckbox, branch .. " no duplicate custom spellbook checkbox")
    check(f.nativeCheckbox and f.nativeCheckbox.shown and f.nativeCheckbox.parent == f.book,
        branch .. " actual native toggle remains directly visible in spellbook")
    check(f.nativeCheckbox.scripts.OnClick == e.ClickableBindingsEnableMouseoverCastCheckboxMixin.OnClick
        and f.nativeCheckbox.scripts.OnEnter == e.ClickableBindingsEnableMouseoverCastCheckboxMixin.OnEnter,
        branch .. " actual native click/tooltip script identities retained")
    local parentWrites = f.parentWrites
    for i = 1, 20 do f.pollBook() end
    check(f.parentWrites == parentWrites, branch .. " idle native toggle does not reparent/layout repeatedly")
    f.nativeStack = true; f.nativeCheckbox.scripts.OnClick(f.nativeCheckbox); f.nativeStack = false
    check(mc.IsEnabled() and #f.queue == 1, branch .. " native click updates state and queues one refresh")
    f.events.CVAR_UPDATE("CVAR_UPDATE", "ENABLE_MOUSEOVER_CAST")
    check(#f.queue == 1 and f.notifications == 0, branch .. " repeated native events coalesce outside native stack")
    f.flush()
    check(f.notifications == 1, branch .. " native change refreshes bindings once")
    check(f.db.mouseoverCast and e._FluxUI_CharSavedVars.mouseoverCast, branch .. " saved fallback data preserved")
    check(mc.IsActive(), branch .. " modifier None activates native casting")
    f.modifier = "ALT"
    check(not mc.IsActive(), branch .. " native modifier not held disables mouseover range")
    f.held = true
    check(mc.IsActive(), branch .. " native modifier held activates mouseover range")

    -- Execute Blizzard's actual target selection against the prepared Flux host.
    native = read("../__AddonsForRef/wow-ui-source-" .. branch .. "/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua")
    start = assert(native:find("function SecureButton_GetModifiedUnit(", 1, true))
    local stop = assert(native:find("function SecureButton_GetUnit(", start, true))
    e.SecureButton_GetModifiedAttribute = function(button, key) return button.attrs[key] end
    e.UnitIsFriend = function() return f.friendly ~= false end
    e.C_ActionBar = { IsHelpfulAction = function() return f.helpful ~= false end,
        IsHarmfulAction = function() return f.helpful == false end }
    e.SpellIsTargeting, e.UnitHasVehicleUI = function() return false end, function() return false end
    run(native:sub(start, stop - 1), e, {})
    check(e.SecureButton_GetModifiedUnit(w, "LeftButton") == "mouseover", branch .. " native helpful target")
    f.held = false
    check(e.SecureButton_GetModifiedUnit(w, "LeftButton") == nil, branch .. " native modifier blocks targeting")
    f.held = true; f.friendly = false
    check(e.SecureButton_GetModifiedUnit(w, "LeftButton") == nil, branch .. " native helpful action rejects hostile unit")
    f.helpful = false
    check(e.SecureButton_GetModifiedUnit(w, "LeftButton") == "mouseover", branch .. " native harmful target")
    f.mouseover = false
    check(e.SecureButton_GetModifiedUnit(w, "LeftButton") == nil, branch .. " native missing-unit fallback")
    f.mouseover, f.friendly, f.helpful = true, true, true

    -- Combat changes read the new native CVar without protected attribute writes.
    f.combat = true
    f.nativeStack = true; e.ClickableBindingsEnableMouseoverCastCheckboxMixin.OnClick({}); f.nativeStack = false
    check(not mc.IsEnabled() and w.attrs.checkmouseovercast, branch .. " combat off uses prepared native check")
    check(e.SecureButton_GetModifiedUnit(w, "LeftButton") == nil, branch .. " native combat off immediately stops mouseover")
    f.flush()
    check(f.deferred["mouseovercast.apply"], branch .. " Flux attribute refresh defers in combat")
    f.nativeStack = true; e.ClickableBindingsEnableMouseoverCastCheckboxMixin.OnClick({}); f.nativeStack = false
    check(e.SecureButton_GetModifiedUnit(w, "LeftButton") == "mouseover", branch .. " native combat on works immediately")
    f.flush(); f.combat = false; f.deferred["mouseovercast.apply"]()
    check(w.attrs.unit == nil and f.wrapCount == 0, branch .. " native targeting retains no custom unit/wrap")
    local before = f.value
    mc.SetEnabled(false)
    check(f.opens == 1 and f.value == before, branch .. " API shortcut opens real native control without CVar write")
    f.pollBook()
    check(f.nativeCheckbox.parent == e.ClickBindingFrame and f.nativeCheckbox.points[1][4] == 60,
        branch .. " Click Casting recovers its own checkbox and original anchors")
    f.db = { mouseoverCast = false }; mc.Apply()
    check(mc.IsEnabled(), branch .. " profile change preserves native on state")
    for _, kind in ipairs({"action", "spell", "item", "macro", "click", "macrotext"}) do
        local button = f.frame(); button.attrs.type = kind; mc.ApplyNativeCheck(button)
        local nativeCheck = kind == "action" or (branch == "forever" and (kind == "spell" or kind == "item"))
        check(button.attrs.checkmouseovercast == nativeCheck, branch .. " type policy " .. kind)
    end

    if branch == "live" then
        for _, kind in ipairs({"spell", "item"}) do
            local extra = f.frame(); extra.attrs.type = kind
            mc.RegisterButton(extra)
            if kind == "spell" then mc.SetButtonSpell(extra, 133) else mc.SetButtonItem(extra, 123) end
            check(extra.attrs.checkmouseovercast == false and type(extra.scripts.PreClick) == "string",
                "standalone " .. kind .. " retains adapter instead of classifying unrelated native slot 1")
            local clickEnv = setmetatable({ self = extra, button = "LeftButton" }, { __index = e })
            f.held = false
            assert(load(extra.scripts.PreClick, "@standalone_preclick", "t", clickEnv))()
            check(extra.attrs.unit == nil, "standalone " .. kind .. " respects native modifier")
            f.held = true
            assert(load(extra.scripts.PreClick, "@standalone_preclick", "t", clickEnv))()
            check(extra.attrs.unit == "mouseover", "standalone " .. kind .. " keeps existing mouseover targeting")
            assert(load(extra.scripts.PostClick, "@standalone_postclick", "t", clickEnv))()
            check(extra.attrs.unit == nil, "standalone " .. kind .. " clears click-time unit")
            extra.attrs.type = "action"; mc.SetButtonSpell(extra, nil)
            check(extra.attrs.checkmouseovercast and extra.scripts.PreClick == nil, "native slot transition retires standalone adapter")
        end
        -- Modified-click changes use the native binding event, with no polling.
        f.modifier = "CTRL"; f.events.UPDATE_BINDINGS()
        check(#f.queue == 1, "native modifier changes queue a coalesced adapter refresh")
        f.flush()
    end

    -- Production macro compiler gate must not bake a modifier-bypassing tail.
    local apply = read("Binding/Core/Apply.lua")
    start = assert(apply:find("local function MouseoverCastEnabled()", 1, true))
    stop = assert(apply:find("-- Native slot inspection", start, true))
    local get = assert(load("local ns=...\n" .. apply:sub(start, stop - 1) .. "\nreturn MouseoverCastEnabled", "@binding_gate", "t", e))({ Flux = f.flux })
    check(get() == mc.IsEnabled(), branch .. " factory automatic mouseover follows the authoritative setting")
    local args = { Flux = f.flux, FluxOptionsActionBars = { MouseoverCast = function() return mc end } }
    run(read("AddonOptions/FluxOptionsActionBars_Bar.lua"), e, args)
    local options = args.FluxOptionsActionBars.GetBarGroup().args
    check(options.mouseoverCast.hidden() and not options.mouseoverCastNative.hidden(), branch .. " options select native control")
    check(options.mouseoverCastNative.name():find("On", 1, true), branch .. " option displays current native state")
    options.mouseoverCastNative.func()
    check(f.opens == 2, branch .. " options open actual Blizzard UI")
    f.pollBook()
    check(f.nativeCheckbox.parent == f.book and f.nativeCheckbox.shown,
        branch .. " closing Click Casting restores directly usable spellbook toggle")

    f.flux.Context = { IsUfPeek = function() return true end }
    run(read("Core/Engine/Range.lua"), e, { Flux = f.flux })
    f.held = false
    check(f.flux.Range.ResolveUnit(w) == "target", branch .. " range respects released native modifier")
    f.held = true
    check(f.flux.Range.ResolveUnit(w) == "mouseover", branch .. " range respects held native modifier")
    f.held = false
    check(f.flux.Range.ResolveUnit(nil, "mouseover") == "mouseover", branch .. " explicit user macro keeps its chosen unit")

    -- A late native capability must retire a previously created fallback even
    -- when a different spellbook control invokes the shared layout service.
    local old = f.frame(); old.shown = true; e.FluxMouseoverCastCheckbox = old
    e.PlayerSpellsFrame = { SpellBookFrame = f.book }
    run(read("Core/Engine/SpellBookChrome.lua"), e, { Flux = f.flux })
    f.flux.SpellBookChrome.Layout()
    check(not old.shown, branch .. " shared layout cannot revive a duplicate custom checkbox")
    check(f.nativeCheckbox.shown and f.nativeCheckbox.parent == f.book, branch .. " shared layout retains real native spellbook toggle")
    f.book.shown = false; f.hideBook()
    check(f.nativeCheckbox.parent == e.ClickBindingFrame, branch .. " book close restores native checkbox owner")
    f.book.shown = true; f.showBook()
    check(f.nativeCheckbox.parent == f.book and f.nativeCheckbox.shown, branch .. " book reopen restores visible native toggle")
    -- Exercise the actual shared observer, including a native panel opened
    -- beside a book whose own visibility/page did not change.
    f.flux.SpellBookChrome.Observe("mouseover", f.showBook, f.hideBook, f.updateBook, f.pollBook)
    local driver = f.frames[#f.frames]
    driver.scripts.OnUpdate(driver, 0.1)
    e.ClickBindingFrame.shown = true
    driver.scripts.OnUpdate(driver, 0.1)
    check(f.nativeCheckbox.parent == e.ClickBindingFrame, branch .. " shared observer returns toggle when native panel opens")
    e.ClickBindingFrame.shown = false
    driver.scripts.OnUpdate(driver, 0.1)
    check(f.nativeCheckbox.parent == f.book, branch .. " shared observer restores spellbook toggle when native panel closes")
    f.combat = true; f.book.shown = false
    driver.scripts.OnUpdate(driver, 0.1)
    check(f.deferred["mouseovercast.spellbook"] and f.nativeCheckbox.parent == f.book,
        branch .. " checkbox parent changes defer in combat")
    f.combat = false; f.deferred["mouseovercast.spellbook"]()
    check(f.nativeCheckbox.parent == e.ClickBindingFrame, branch .. " deferred checkbox restore resolves current visibility")
    local refresh = mc.Refresh
    check(refresh ~= mc.RefreshSetting, branch .. " learned-spell classification retains its separate debounce API")
end

for _, case in ipairs({{false, "1"}, {nil, "1"}, {true}}) do
    local f = fixture(case[1], case[2], true)
    check(not f.mc.UsesNativeCVar(), "unsupported/missing capability or CVar keeps custom route")
    check(not f.mc.IsEnabled(), "custom account false preserved")
    f.mc.Start(); f.mc.SetEnabled(true)
    check(f.mc.IsEnabled() and f.db.mouseoverCast and f.env._FluxUI_CharSavedVars.mouseoverCast, "custom setting still updates saved scopes")
    f.showBook()
    check(f.env.FluxMouseoverCastCheckbox and f.env.FluxMouseoverCastCheckbox.shown, "custom spellbook checkbox retained")
    local w = f.frame(); w.attrs.type = "action"; f.mc.AttachHost(w)
    check(f.wrapCount == 2 and w.attrs.checkmouseovercast == false, "custom PreClick/PostClick retained without native check")
end

-- Native utility attributes and their key proxies share modifier-aware target
-- metadata. Execute the production restricted click bodies with a secure-write
-- model; this does not certify the native restricted VM.
for _, branch in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    local native = branch == "live" or branch == "forever"
    local f = fixture(native, "1", branch ~= "forever")
    local e, mc = f.env, f.mc
    f.flux.Restricted.PagingWorks = function() return true end
    f.db.mouseoverCast = true
    local chord = ""
    local function held(key) return ("-" .. chord .. "-"):find("-" .. key .. "-", 1, true) ~= nil end
    e.IsShiftKeyDown = function() return held("SHIFT") end
    e.IsControlKeyDown = function() return held("CTRL") end
    e.IsAltKeyDown = function() return held("ALT") end
    e.SecureButton_GetModifierPrefix = function()
        local prefix = ""
        if held("SHIFT") then prefix = "shift-" .. prefix end
        if held("CTRL") then prefix = "ctrl-" .. prefix end
        if held("ALT") then prefix = "alt-" .. prefix end
        return prefix
    end
    e.C_Spell = { IsSpellHelpful = function(id) return id == 101 end,
        IsSpellHarmful = function(id) return id == 102 end }
    e.C_Item = { IsHelpfulItem = function(id) return id == 201 end,
        IsHarmfulItem = function(id) return id == 202 end }
    e.SecureCmdOptionParse = function(condition)
        if not f.mo then return end
        if condition:find(",help", 1, true) and not f.friend then return end
        if condition:find(",harm", 1, true) and f.friend then return end
        return "mouseover"
    end
    local slots = { [""] = { type = "spell", id = 101 }, SHIFT = { type = "item", id = 202 },
        CTRL = { type = "spell", id = 102 }, ALT = { type = "item", id = 201 },
        ["SHIFT-CTRL"] = { type = "spell", id = 103 } }
    local w, keyer = f.frame(), f.frame(); keyer.parent = w
    w:SetAttribute("flux-utility-native", true)
    w._fluxUtilityNative = true
    check(mc.ConfigureUtility(w, slots, slots[""]), branch .. " modifier-aware native utility mouseover attached")
    check(mc.AttachUtilityKeyer(keyer), branch .. " native key proxy shares mouseover target metadata")
    f.flux.Context = { IsUfPeek = function() return true end }
    run(read("Core/Engine/Range.lua"), e, { Flux = f.flux })
    local frames, timers = #f.frames, #f.queue
    local function clickBody(widget, script)
        local body = assert(widget.scripts[script], script)
        f.secure = true
        assert(load("local self = ...\n" .. body, "@utility-target-" .. script, "t", e))(widget)
        f.secure = false
    end
    for _, enabled in ipairs({ true, false }) do
        f.combat = false; f.value = enabled and "1" or "0"; f.db.mouseoverCast = enabled
        mc.Apply()
        for _, combat in ipairs({ false, true }) do
            f.combat = combat
            for _, value in ipairs({ "", "SHIFT", "CTRL", "ALT", "SHIFT-CTRL", "SHIFT-ALT", "CTRL-ALT", "SHIFT-CTRL-ALT", "" }) do
                chord = value; local entry = slots[chord] or slots[""]
                for _, target in ipairs({ "friendly", "hostile", "missing", "dead-friendly" }) do
                    f.mo, f.friend = target ~= "missing", target == "friendly" or target == "dead-friendly"
                    local help = entry.id == 101 or entry.id == 201
                    local harm = entry.id == 102 or entry.id == 202
                    local want = enabled and f.mo and ((help and f.friend) or (harm and not f.friend) or (not help and not harm))
                    check(f.flux.Range.ResolveUnit(w) == (want and "mouseover" or "target"),
                        "utility range uses the same selected mouseover reaction gate")
                    for _, widget in ipairs({ w, keyer }) do
                        clickBody(widget, "PreClick")
                        check(widget.attrs.unit == (want and "mouseover" or nil),
                            branch .. " selected utility target " .. chord .. " " .. target)
                        clickBody(widget, "PostClick")
                        check(widget.attrs.unit == nil, "utility drops mouseover unit after every click")
                    end
                end
            end
        end
    end
    if native then
        f.combat = false; f.value = "1"; f.modifier = "CTRL"; f.held = false; mc.Apply()
        f.combat = true; chord = ""; f.mo, f.friend = true, true
        clickBody(keyer, "PreClick"); check(keyer.attrs.unit == nil, "native mouseover modifier gate remains respected")
        f.held = true; clickBody(keyer, "PreClick")
        check(keyer.attrs.unit == "mouseover", "native mouseover modifier enables selected utility target")
        clickBody(keyer, "PostClick")
    end
    check(#f.frames == frames and #f.queue == timers, "utility hover/clicks add no polling frames or timers")
    -- Clearing/reassigning the host leaves cached key-proxy hooks inert.
    f.combat = false; w:SetAttribute("flux-utility-native", nil)
    f.combat = true; clickBody(keyer, "PreClick")
    check(keyer.attrs.unit == nil, "cleared utility cannot retain a key-proxy mouseover target")
end

local unavailable = fixture(true, "1", false)
unavailable.flux.Restricted.PagingWorks = function() return false end
local unsupported = unavailable.frame(); unsupported:SetAttribute("flux-utility-native", true)
check(not unavailable.mc.ConfigureUtility(unsupported, {}, nil), "failed native VM probe does not claim working mouseover")
local partial = fixture(true, "1", true)
local rejected = partial.frame(); rejected:SetAttribute("flux-utility-native", true)
partial.mc.ConfigureUtility(rejected, {}, nil)
local hub = partial.env.FluxActionStripMouseoverHub
local wrap = hub.WrapScript
hub.WrapScript = function(self, widget, script, body)
    if script == "PostClick" then error("model rejected post wrapper") end
    return wrap(self, widget, script, body)
end
check(not partial.mc.ConfigureUtility(rejected, {}, nil), "partial native wrapper installation is rejected")
check(not rejected.scripts.PreClick and not rejected.scripts.PostClick and rejected.attrs.unit == nil,
    "partial wrapper failure leaves no target picker or latched unit")

local defaults = read("FluxDefaultSettings.lua")
check(not defaults:find('["enableMouseoverCast"] =', 1, true), "default CVar pack preserves native setting")
check(not defaults:find('setCVar("enableMouseoverCast"', 1, true), "Combat defaults preserve native setting")
check(not defaults:find('SetShownValue("enableMouseoverCast"', 1, true), "shown Settings preserve native setting")
check(not defaults:find('SetModifiedClick("MOUSEOVERCAST"', 1, true)
    and not defaults:find('SetModifiedClick, "MOUSEOVERCAST"', 1, true), "first-login/reset/binding save preserve native modifier")
print("native mouseover: " .. checks .. " checks passed; native taint/visual/input/FPS pending")
