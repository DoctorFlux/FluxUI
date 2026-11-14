-- Real settings/options/runtime plus Blizzard's native single-choice handler.
-- Desktop behavior only: native server interaction, input, pixels and taint pending.
local checks = 0
local function check(ok, message) checks = checks + 1; assert(ok, message) end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local runtime = os.getenv("FLUX_VENDOR_GOSSIP_SOURCE") or "Inventory/Restock/Vendor/FluxVendorGossip.lua"
local nativeCache = os.getenv("FLUX_VENDOR_GOSSIP_NATIVE_CACHE")
local function fixture(client, saved, locale, missingIcons)
    local env = setmetatable({unpack = unpack or table.unpack}, { __index = _G }); env._G = env
    local hooks, afterLogin, frames, roots = {}, {}, {}, {}
    local t = { selections = {}, reads = 0, iconReads = 0, registrations = 0, unregistrations = 0,
        options = {{icon = 132060, status = 0, orderIndex = 7, gossipOptionID = 96317}},
        active = 0, available = 0, force = true, shift = false, created = 0, iconMissing = missingIcons, optionRefreshes = 0 }
    local ns = { Flux = {Client = {isCamelot = client == "forever", isAnyClassic = client:find("classic") ~= nil}} }
    ns.Flux.Events = {
        Register = function(event, fn)
            check(event == "GOSSIP_SHOW" or event == "GOSSIP_CLOSED" or event == "GOSSIP_OPTIONS_REFRESHED", "only gossip lifecycle is subscribed")
            hooks[event] = hooks[event] or {}; hooks[event][fn] = true
            t.registrations = t.registrations + 1; return true
        end,
        Unregister = function(event, fn)
            check(hooks[event] and hooks[event][fn], "unsubscribe the owned handler")
            hooks[event][fn] = nil; t.unregistrations = t.unregistrations + 1
        end,
        IsValid = function(event) return event ~= "GOSSIP_OPTIONS_REFRESHED" or client == "forever" end,
    }
    ns.Flux.AfterLogin = function(fn) afterLogin[#afterLogin + 1] = fn end
    ns.FluxOptionsShell = {IsShown = function() return t.optionsShown == true end}
    env.GetFileIDFromPath = function(path)
        check(path == "Interface\\GossipFrame\\VendorGossipIcon.blp" or path == "Interface\\GossipFrame\\BankerGossipIcon.blp", "resolve named native service icons")
        t.iconReads = t.iconReads + 1
        return t.iconMissing and 0 or (path:find("Banker", 1, true) and 132050 or 132060)
    end
    env.IsShiftKeyDown = function() return t.shift end
    env.Enum = { GossipOptionStatus = {Available = 0, Unavailable = 1, Locked = 2, AlreadyComplete = 3} }
    env.C_GossipInfo = {
        GetOptions = function() t.reads = t.reads + 1; return t.options end,
        GetNumAvailableQuests = function() return t.available end,
        GetNumActiveQuests = function() return t.active end,
        ForceGossip = function() return t.force end,
        SelectOptionByIndex = function(...)
            check(select("#", ...) == 1, "never auto-confirm or provide a coded response")
            t.selections[#t.selections + 1] = (...)
        end,
    }
    env.GossipFrame = {IsShown = function() return t.frameShown ~= false end, GreetingPanel = {GetFrameLevel = function() return 10 end}}
    env.GameTooltip = {
        IsOwned = function(self, owner) return self.owner == owner end,
        SetOwner = function(self, owner) self.owner = owner end,
        SetText = function(self, text) self.text = text end,
        AddLine = function(self, text) self.help = text end,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false; self.owner = nil end,
    }
    env.CreateFrame = function(kind, name, parent, template)
        local f = { events = {}, scripts = {}, parent = parent, template = template, shown = true }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:UnregisterEvent(event) self.events[event] = nil end
        function f:SetScript(event, fn) self.scripts[event] = fn; if event == "OnEvent" then self.onEvent = fn end end
        function f:Hide() local was = self.shown; self.shown = false; if was and self.scripts.OnHide then self.scripts.OnHide(self) end end
        function f:Show() self.shown = true end
        function f:IsShown() return self.shown and t.frameShown ~= false end
        function f:SetSize(w, h) self.width, self.height = w, h end
        function f:SetPoint(...) self.point = {...} end
        function f:SetFrameLevel(n) self.level = n end
        function f:SetHitRectInsets(...) self.hitInsets = {...} end
        function f:SetChecked(value) self.checked = value and true or false end
        function f:GetChecked() return self.checked end
        function f:SetPropagateMouseClicks() error("protected input setter must not run") end
        function f:SetPropagateMouseMotion() error("protected input setter must not run") end
        if kind == "CheckButton" then
            t.created = t.created + 1
            f.Text = {
                SetWidth = function(self, value) self.width = value end,
                SetJustifyH = function() end, SetWordWrap = function() end,
                SetText = function(self, value) self.text = value end,
                GetText = function(self) return self.text end,
            }
            t.widget = f
        end
        if name then env[name] = f end
        frames[#frames + 1] = f; return f
    end
    env._FluxUI_CharSavedVars = {Restock = saved}
    local built = {}
    env.FluxOptions = {
        RegisterModuleOptions = function(_, id, fn) roots[id] = fn end,
        ResolveModuleOptions = function(_, id)
            if not built[id] and roots[id] then built[id] = roots[id]() end
            return built[id]
        end,
        GetModuleGen = function() return 1 end,
        RefreshOpenPage = function()
            t.optionRefreshes = t.optionRefreshes + 1
            t.refreshSelections = #t.selections
        end,
    }
    if locale then ns.FluxOptionsLocale = locale end
    local function run(path) assert(load(read(path), "@" .. path, "t", env))("_FluxUI", ns) end
    run("Inventory/Restock/Core/FluxRestockSettings.lua")
    run(runtime)
    run("AddonOptions/FluxOptionsVendor.lua")
    run("AddonOptions/FluxOptionsCatalog.lua")
    run("AddonOptions/FluxOptionsRender.lua")
    run("AddonOptions/FluxOptionsNavigation.lua")
    for _, f in ipairs(frames) do if f.events.ADDON_LOADED then f.onEvent(f, "ADDON_LOADED", "_FluxUI") end end
    for _, fn in ipairs(afterLogin) do fn() end
    t.env, t.ns = env, ns
    t.control = env.FluxOptions:ResolveModuleOptions("vendor").args.vendor.args.autoOpenVendorGossip
    t.bankControl = env.FluxOptions:ResolveModuleOptions("vendor").args.vendor.args.autoOpenBankGossip
    t.search = function()
        return ns.FluxOptionsRender.Search(ns.FluxOptionsNavigation.Resolve("lootItems"), "auto open vendor")
    end
    t.settings = function() return env.FluxVendorAuto.EnsureSettings() end
    t.fire = function(event)
        event = event or "GOSSIP_SHOW"
        for fn in pairs(hooks[event] or {}) do fn(event) end
    end
    t.eventCount = function() local n = 0; for _, list in pairs(hooks) do for _ in pairs(list) do n = n + 1 end end; return n end
    t.click = function(value, button)
        local control = assert(t.widget); control.checked = value
        control.scripts.OnClick(control, button or "LeftButton")
    end
    t.native = function()
        if not t.nativeShow then
            local branch = client == "retail" and "live" or client
            local path = nativeCache and nativeCache .. "/" .. branch .. "/Interface__AddOns__Blizzard_UIPanels_Game__Shared__GossipFrameShared.lua"
                or "../__AddonsForRef/wow-ui-source-" .. branch .. "/Interface/AddOns/Blizzard_UIPanels_Game/Shared/GossipFrameShared.lua"
            local source = read(path)
            local first = assert(source:find("function GossipFrameSharedMixin:HandleShow(_textureKit)", 1, true))
            local last = assert(source:find("\nend", first, true)) + 3
            env.GossipFrameSharedMixin = {}
            env.GossipOptionSort = function(a, b) return a.orderIndex < b.orderIndex end
            env.ShowUIPanel = function(f) f.shown = true end
            assert(load(source:sub(first, last), "@native-gossip-HandleShow", "t", env))()
            t.nativeShow = env.GossipFrameSharedMixin.HandleShow
        end
        t.nativeShow({IsShown = function() return true end})
    end
    return t
end

for _, client in ipairs({"forever", "classic", "classic_era", "classic_anniversary"}) do
    local t = fixture(client)
    check(not t.control.hidden(), client .. ": visible option")
    local count, sub = t.search()
    check(count == 1 and sub == "vendor", "search finds the new control exactly once in Loot & Items > Vendor")
    check(not t.control.get() and t.settings().autoOpenVendorGossip == false, "new preference defaults off")
    local events = client == "forever" and 3 or 2
    check(t.registrations == events and t.iconReads == 2 and t.created == 0, "prime two icons at login; lifecycle enables a lazy visible checkbox")
    t.fire(); check(#t.selections == 0 and t.reads == 1 and t.created == 1 and t.widget:IsShown(), "automation off shows the unchecked checkbox without selecting")
    check(not t.widget.checked and t.widget.Text.text == "Auto open vendor", "vendor footer label/value")
    check(t.widget.template == "UICheckButtonTemplate" and t.widget.parent == t.env.GossipFrame.GreetingPanel and t.widget.point[1] == "BOTTOMLEFT", "native template stays in the gossip footer")
    t.control.set(nil, true)
    check(t.control.get() and t.widget.checked and t.registrations == events and t.iconReads == 2, "options update the same checkbox immediately")
    t.env.FluxVendorAuto.RefreshVendorGossip()
    check(t.registrations == events and t.iconReads == 2, "refresh does not duplicate registration or lookup")
    t.fire(); check(#t.selections == 1 and t.selections[1] == 7, "select exact orderIndex synchronously")
    t.options[1].gossipOptionID = nil
    t.options[1].flags = 2
    t.options[1].name = "Je voudrais voir vos marchandises."
    t.fire(); check(#t.selections == 2, "hidden IDs and localized text do not block vendor selection")
    t.options[1].overrideIconID = 999
    t.fire(); check(#t.selections == 3, "original vendor identity survives decorative icon overrides")
    t.options[1].overrideIconID = 132060
    local function rejected(change, restore, message)
        local before = #t.selections; change(); t.fire()
        check(#t.selections == before, client .. ": " .. message); restore()
    end
    rejected(function() t.shift = true end, function() t.shift = false end, "Shift preserves gossip")
    rejected(function() t.active = 1 end, function() t.active = 0 end, "active quests preserved")
    rejected(function() t.available = 1 end, function() t.available = 0 end, "available quests preserved")
    rejected(function() t.options[2] = {icon = 132060, status = 0, orderIndex = 2} end,
        function() t.options[2] = nil end, "two vendor choices preserved")
    rejected(function() t.options[2] = {icon = 132053, status = 0, orderIndex = 2} end,
        function() t.options[2] = nil end, "vendor plus another choice preserved")
    for _, icon in ipairs({132053, 132050, 132057, 132052, 132058}) do
        rejected(function() t.options[1].icon = icon end, function() t.options[1].icon = 132060 end,
            "gossip/bank/taxi/binder/trainer not selected even with an overridden vendor icon")
    end
    for _, status in ipairs({1, 2, 3}) do
        rejected(function() t.options[1].status = status end, function() t.options[1].status = 0 end, "unavailable/locked/completed choice preserved")
    end
    rejected(function() t.options[1].orderIndex = nil end, function() t.options[1].orderIndex = 7 end, "missing orderIndex preserved")
    local original = t.options
    rejected(function() t.options = {} end, function() t.options = original end, "empty options preserved")
    rejected(function() t.options = nil end, function() t.options = original end, "missing options preserved")
    t.control.set(nil, false)
    local reads = t.reads; t.fire()
    check(t.unregistrations == 0 and t.reads == reads + 1 and t.widget:IsShown() and not t.widget.checked, "automation off retains the requested checkbox")
    t.control.set(nil, true); t.fire()
    check(t.registrations == events, "reenable retains one lifecycle registration")
    local saved = t.settings(); saved.autoRepair = true; saved.restockItems[123] = {targetQuantity = 8}
    local reloaded = fixture(client, saved)
    check(reloaded.control.get() and reloaded.registrations == events, "saved opt-in and lifecycle survive reload")
    check(reloaded.settings() == saved and saved.autoRepair and saved.restockItems[123].targetQuantity == 8, "saved store and other vendor choices retained")
    for _, nativeFirst in ipairs({true, false}) do
        for _, force in ipairs({true, false}) do
            for _, auto in ipairs({true, false}) do
                local u = fixture(client, {autoOpenVendorGossip = true})
                u.options[1].selectOptionWhenOnlyOption = auto; u.force = force
                if nativeFirst then u.native(); u.fire() else u.fire(); u.native() end
                check(#u.selections == 1, "exactly one selection with native handler in either event order")
            end
        end
    end
    local missing = fixture(client)
    missing.env.C_GossipInfo.SelectOptionByIndex = nil
    check(missing.control.hidden(), "unsupported API hides the option")
    missing.control.set(nil, true)
    check(missing.eventCount() == 0, "missing API detaches the owned lifecycle")
    local iconMissing = fixture(client, nil, nil, true)
    iconMissing.control.set(nil, true)
    iconMissing.fire()
    check(#iconMissing.selections == 0 and iconMissing.created == 0, "unresolved icons never match unrelated options")
    iconMissing.iconMissing = false; iconMissing.env.FluxVendorAuto.RefreshVendorGossip()
    iconMissing.fire()
    check(#iconMissing.selections == 1, "failed asset lookup can recover on refresh")

    local bank = fixture(client)
    bank.options[1].icon = 132050; bank.fire()
    check(bank.widget:IsShown() and bank.widget.Text.text == "Auto open bank" and not bank.widget.checked, "bank gossip shows its independent unchecked control")
    bank.optionsShown = true; bank.click(true)
    check(bank.bankControl.get() and not bank.control.get() and #bank.selections == 1 and bank.selections[1] == 7, "checking bank saves only bank and opens immediately")
    check(bank.optionRefreshes == 1 and bank.refreshSelections == 1, "selection is submitted before refreshing simultaneously open options")
    check(not bank.widget:IsShown(), "selection hides the owned control")
    bank.shift = true; bank.fire()
    check(bank.widget:IsShown() and bank.widget.checked and #bank.selections == 1, "Shift reveals the saved bank checkbox")
    bank.click(false)
    check(not bank.bankControl.get() and bank.widget:IsShown() and not bank.widget.checked, "uncheck disables bank from the gossip window")
    check(bank.optionRefreshes == 2, "uncheck also refreshes open options")
    bank.shift = false; bank.fire()
    check(#bank.selections == 1 and bank.created == 1, "disabled bank stays open and reuses one checkbox")
    bank.bankControl.set(nil, true); check(bank.widget.checked, "bank options sync to the visible gossip checkbox")
    bank.fire(); check(#bank.selections == 2, "enabled bank selects in the same event")
    bank.fire("GOSSIP_OPTIONS_REFRESHED"); check(#bank.selections == 2 and not bank.widget:IsShown(), "refresh does not duplicate selection or resurrect a pending checkbox")
    local bankReload = fixture(client, bank.settings()); bankReload.options[1].icon = 132050; bankReload.fire()
    check(#bankReload.selections == 1 and bankReload.bankControl.get(), "bank preference survives modeled reload")
    local fast = fixture(client, {autoOpenVendorGossip = true, autoOpenBankGossip = true})
    fast.optionsShown = true
    for _, icon in ipairs({132060, 132050}) do
        fast.options[1].icon = icon; fast.fire()
        fast.fire("GOSSIP_OPTIONS_REFRESHED")
        check(fast.created == 0 and fast.iconReads == 2 and fast.optionRefreshes == 0, "automatic first/warm opens allocate no checkbox and resolve no icons or options UI")
    end
    check(#fast.selections == 2, "both services select synchronously on the fast path")
    local stale = fixture(client); stale.fire(); stale.options[1].icon = 132050; stale.click(true)
    check(not stale.control.get() and not stale.bankControl.get() and #stale.selections == 0 and not stale.widget:IsShown(), "stale vendor click cannot change the bank preference")
    stale.fire(); stale.fire("GOSSIP_CLOSED"); stale.click(true)
    check(not stale.widget:IsShown() and #stale.selections == 0 and not stale.bankControl.get(), "close clears stale checkbox owner")
    stale.fire("GOSSIP_OPTIONS_REFRESHED"); check(not stale.widget:IsShown(), "closed refresh never resurrects a checkbox")
    local vendor = fixture(client); vendor.fire(); vendor.click(true)
    check(vendor.control.get() and not vendor.bankControl.get() and #vendor.selections == 1, "vendor checkbox saves vendor and selects now")
    check(vendor.optionRefreshes == 0, "closed options cause no refresh work")
    vendor.shift = true; vendor.fire(); vendor.widget.scripts.OnEnter(vendor.widget)
    check(vendor.env.GameTooltip.shown and type(vendor.env.GameTooltip.help) == "string", "full localized help is available")
    vendor.fire("GOSSIP_CLOSED"); check(not vendor.env.GameTooltip.shown, "closing hides only the owned tooltip")
    local ineligible = fixture(client)
    for _, mutate in ipairs({
        function() ineligible.options = {{icon = 132053, status = 0, orderIndex = 1}} end,
        function() ineligible.options = {{icon = 132060, status = 1, orderIndex = 1}} end,
        function() ineligible.options = {{icon = 132050, status = 0, orderIndex = 1}}; ineligible.active = 1 end,
        function() ineligible.active = 0; ineligible.options[2] = {icon = 132060, status = 0, orderIndex = 2} end,
    }) do mutate(); ineligible.fire(); check(ineligible.created == 0, "ineligible gossip never creates or displays a checkbox") end
end
local retail = fixture("retail", {autoOpenVendorGossip = true})
check(retail.control.hidden() and retail.registrations == 0 and retail.iconReads == 0, "Retail stays outside the requested automation scope")
check(retail.search() == 0, "hidden Retail control is excluded from search")
local invalid = fixture("forever", {autoOpenVendorGossip = "true"})
check(invalid.settings().autoOpenVendorGossip == false and not invalid.settings().autoOpenBankGossip, "invalid saved preference does not opt in")
local localized = fixture("forever", nil, {AUTO_OPEN_VENDOR = "Ouvrir le marchand automatiquement"})
check(localized.control.name == "Ouvrir le marchand automatiquement" and type(localized.control.desc) == "string", "partial locale keeps override and English help fallback")
check(localized.settings().autoOpenVendorGossip == false, "locale leaves stable saved key intact")
print("vendor_gossip: " .. checks .. " checks PASS; native input/taint/rendering/server interaction NOT RUN")
