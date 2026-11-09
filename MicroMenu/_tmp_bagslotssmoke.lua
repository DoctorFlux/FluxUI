-- lua MicroMenu/_tmp_bagslotssmoke.lua
-- Executes the actual header module; mocks check layout and bag-slot dispatch,
-- not the WoW engine's protected calls or real inventory transactions.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local unpack = table.unpack or unpack
local function Compile(source, env)
    if setfenv then local f = assert(loadstring(source)); setfenv(f, env); return f end
    return assert(load(source, "native bag fixture", "t", env))
end
local nativeFile = assert(io.open(root .. "../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua"))
local nativeSource = nativeFile:read("*a"); nativeFile:close()
local toggleStart = assert(nativeSource:find("function ToggleBag(id)", 1, true))
local toggleEnd = assert(nativeSource:find("\nlocal ContainerFrame_GetBestFilterIcon", toggleStart, true))
local function Boot(family, options)
    options = options or {}
    local frames, hooks, equipped, cursor, calls = {}, {}, {}, nil, {}
    local showKeyring = options.showKeyring or false
    local tooltip = {}
    local function Region()
        return {
            SetTexture = function(self, v) self.texture = v end,
            SetAtlas = function(self, v) self.atlas = v end,
            SetText = function(self, v) self.text = v end,
            SetSize = function(self, w, h) self.width, self.height = w, h end,
            SetShown = function(self, v) self.shown = v end,
            AddMaskTexture = function(self, mask) self.mask = mask end,
            Show = function(self) self.shown = true end,
            Hide = function(self) self.shown = false end,
            SetPoint = function(self, ...) self.point = { ... } end,
            SetAllPoints = function(self, owner) self.allPoints = owner end,
            ClearAllPoints = function(self) self.point, self.allPoints = nil, nil end,
            SetTexCoord = function() end,
            SetVertexColor = function() end, SetBlendMode = function() end,
            SetAlpha = function() end,
        }
    end
    local function Frame(kind, name, parent)
        local f = { kind = kind, name = name, parent = parent, scripts = {}, width = 36, height = 36, shown = true }
        frames[#frames + 1] = f
        function f:GetParent() return self.parent end
        function f:SetParent(p) self.parent = p end
        function f:SetSize(w, h) self.width, self.height = w, h end
        function f:SetScale(scale) self.scale = scale end
        function f:SetHeight(h) self.height = h end
        function f:GetHeight() return self.height end
        function f:GetWidth() return self.width end
        function f:GetFrameLevel() return 2 end
        function f:SetFrameLevel() end
        function f:SetAlpha() end
        function f:SetPoint(...) self.point = { ... } end
        function f:ClearAllPoints() self.point = nil end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:IsShown() return self.shown end
        function f:RegisterForClicks(...) self.clicks = { ... } end
        function f:RegisterForDrag(...) self.drags = { ... } end
        function f:RegisterEvent() end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        function f:HookScript(event, fn) self.scripts[event] = fn end
        function f:CreateTexture() return Region() end
        function f:CreateMaskTexture() return Region() end
        function f:CreateFontString() return Region() end
        function f:SetNormalTexture() self.normal = Region() end
        function f:SetHighlightTexture() self.highlight = Region() end
        function f:SetPushedTexture() self.pushed = Region() end
        function f:SetNormalAtlas(atlas) self.normal = Region(); self.normal:SetAtlas(atlas) end
        function f:SetPushedAtlas(atlas) self.pushed = Region(); self.pushed:SetAtlas(atlas) end
        function f:SetHighlightAtlas(atlas) self.highlight = Region(); self.highlight:SetAtlas(atlas) end
        function f:GetNormalTexture() return self.normal end
        function f:GetHighlightTexture() return self.highlight end
        function f:GetPushedTexture() return self.pushed end
        if kind == "ItemButton" then f.icon = Region() end
        return f
    end
    local bag = Frame("Frame", "ContainerFrameCombinedBags")
    bag.height, bag.Items = 170, {}
    for i = 1, 16 do
        local item = Frame("ItemButton", nil, bag)
        item:SetSize(37, 37)
        item.GetBagID = function() return 0 end
        item.GetID = function() return i end
        bag.Items[i] = item
    end
    bag.CloseButton = Frame("Button", nil, bag)
    function bag:IsCombinedBagContainer() return true end
    function bag:GetColumns() return 10 end
    function bag:GetBagSize() return #self.Items end
    function bag:UpdateFrameSize() self.height = 170 end
    function bag:UpdateSearchBox() end
    function bag:UpdateItemLayout() end
    function bag:OnBagSlotEnter() end
    local forbidden = function() error("native gamepad bag controls were touched") end
    local nativeBar = setmetatable({}, { __index = forbidden, __newindex = forbidden })
    local forever = family == "forever"
    local env = setmetatable({
        CreateFrame = Frame,
        ContainerFrameCombinedBags = bag,
        GamepadBagBar = (forever or options.gamepadBar) and nativeBar or nil,
        GamepadBackpackButton = (forever or options.gamepadBar) and nativeBar or nil,
        CharacterReagentBag0Slot = options.reagent and {} or nil,
        BagItemAutoSortButton = Frame("Button", "Sort", bag),
        REAGENTBAG_CONTAINER = options.reagent and 5 or nil,
        KEYRING_CONTAINER = not options.noKeyring and -1 or nil,
        C_ActionBar = { ShouldShowKeyring = function() return not options.noKeyring end },
        -- This obsolete API can say false even though the native Camelot API supports it.
        IsKeyRingEnabled = function() return false end,
        GetCVarBool = function(name) assert(name == "showKeyring"); return showKeyring end,
        C_CVar = { SetCVar = function(name, value) assert(name == "showKeyring"); showKeyring = value == "1" end },
        CursorHasItem = function() return cursor ~= nil end,
        PutKeyInKeyRing = function() calls[#calls + 1] = { "key-drop", -1 }; cursor = nil end,
        ContainerFrame_AllowedToOpenBags = function() return true end,
        ContainerFrameSettingsManager = { IsUsingCombinedBags = function(_, id) return id ~= -1 end },
        ToggleBag_Individual = function(id) calls[#calls + 1] = { "toggle", id } end,
        ToggleBag_Combined = function(id) calls[#calls + 1] = { "toggle-combined", id } end,
        GameTooltip = {
            SetOwner = function() end, SetText = function(_, title) tooltip.title = title end,
            AddLine = function(_, line) tooltip.line = line end, Show = function() end,
            Hide = function() end,
        },
        FluxUI_UsesAlternativeBagUI = function() return options.alt end,
        InputUtil = { IsGamepadUIEnabled = function() return options.gamepad end },
        C_Container = {
            ContainerIDToInventoryID = function(id) return 29 + id end,
            CalculateTotalNumberOfFreeBagSlots = function() return 12 end,
            GetBagName = function(id) return equipped[29 + id] end,
        },
        GetInventoryItemTexture = function(_, inv) return equipped[inv] end,
        PutItemInBag = function(inv)
            calls[#calls + 1] = { "drop", inv }
            if not cursor or cursor == "invalid" then return false end
            equipped[inv], cursor = cursor, equipped[inv]
            return true
        end,
        PickupBagFromSlot = function(inv)
            calls[#calls + 1] = { "pickup", inv }
            equipped[inv], cursor = cursor, equipped[inv]
        end,
        hooksecurefunc = function(obj, name, fn)
            assert(obj ~= nativeBar, "native gamepad function was hooked")
            hooks[#hooks + 1] = { obj, name }
            local original = assert(obj[name])
            obj[name] = function(...)
                local result = { original(...) }; fn(...); return unpack(result)
            end
        end,
    }, { __index = _G })
    env._G = env
    Compile(nativeSource:sub(toggleStart, toggleEnd - 1), env)()
    local ns = { Flux = { Client = { isForever = forever, isCamelot = forever, isEra = family == "era" },
        Cap = { IsForeverGamepadUI = function() return forever and options.gamepad end } } }
    local chunk
    if setfenv then chunk = assert(loadfile(root .. "MicroMenu/FluxCombinedBagHeader.lua")); setfenv(chunk, env)
    else chunk = assert(loadfile(root .. "MicroMenu/FluxCombinedBagHeader.lua", "t", env)) end
    chunk("_FluxUI", ns)
    local buttons, watcher
    for _, frame in ipairs(frames) do
        if frame.scripts.OnEvent then watcher = frame end
        if frame.name == "FluxCombinedBagHeader" then
            buttons = {}
            for _, button in ipairs(frames) do
                if button.parent == frame then buttons[button.bagID or "key"] = button end
            end
        end
    end
    return { bag = bag, buttons = buttons, hooks = hooks, watcher = watcher, calls = calls, env = env,
        event = function(event) watcher.scripts.OnEvent(watcher, event) end,
        cursor = function(value) cursor = value end, held = function() return cursor end,
        equipped = equipped, tooltip = tooltip, keyringShown = function() return showKeyring end }
end

for _, reagent in ipairs({ false, true }) do
    local ui = Boot("forever", { reagent = reagent })
    assert(ui.buttons, "Forever still depends on unanchored GamepadBagBar")
    assert(ui.buttons[0].icon.texture == "Interface\\Icons\\ui-hud-actionbar-bag")
    assert(ui.buttons[1]:GetNormalTexture().atlas == "ui-hud-actionbar-iconframe-bags")
    assert(ui.buttons[1].icon.mask.atlas == "UI-HUD-ActionBar-IconFrame-Mask")
    for _, button in pairs(ui.buttons) do
        local key = button.kind == "key"
        assert(button.width == (key and 33 or 45) and button.height == 45 and button.scale == 0.8,
            "native slot proportions/row scale were lost")
        assert(button.icon.width == (key and 27 or 40) and button.icon.height == 40,
            "icon stretched into the wrong slot shape")
        assert(button.icon.point[1] == "CENTER" and not button.icon.allPoints)
        assert(button.SquareMask.width == 64 and button.SquareMask.height == 64
            and button.SquareMask.point[1] == "CENTER" and not button.SquareMask.allPoints,
            "padded mask was fitted to the icon and cropped it again")
        assert(button:GetNormalTexture().width == (key and 33 or 46)
            and button:GetNormalTexture().height == 45 and not button:GetNormalTexture().allPoints,
            "native frame artwork was stretched to the hitbox")
    end
    local keyring = assert(ui.buttons[-1], "missing Forever keyring button")
    assert(keyring:GetNormalTexture().atlas == "UI-HUD-ActionBar-IconFrame-Small")
    assert(keyring.icon.atlas == "UI-HUD-ActionBar-Keyring-Small")
    assert(not ui.keyringShown(), "layout changed keyring preference")
    keyring.scripts.OnClick(keyring)
    assert(ui.keyringShown() and ui.calls[#ui.calls][1] == "toggle" and ui.calls[#ui.calls][2] == -1,
        "native ToggleBag still refuses to open keyring")
    keyring.scripts.OnClick(keyring)
    assert(ui.calls[#ui.calls][1] == "toggle", "second keyring click failed")
    ui.cursor("key"); keyring.scripts.OnReceiveDrag(keyring)
    assert(ui.calls[#ui.calls][1] == "key-drop" and not ui.held())
    local beforeEmptyDrop = #ui.calls
    keyring.scripts.OnReceiveDrag(keyring)
    assert(#ui.calls == beforeEmptyDrop, "empty keyring drop toggled the window")
    keyring.scripts.OnEnter(keyring); assert(ui.tooltip.title == "Keyring")
    if reagent then
        local reagentSlot = assert(ui.buttons[5])
        assert(reagentSlot:GetNormalTexture().atlas == "UI-HUD-ActionBar-IconFrame")
        assert(reagentSlot.ReagentMarker.atlas == "bags-icon-reagents")
        reagentSlot.scripts.OnEnter(reagentSlot)
        assert(ui.tooltip.title == "Reagent Bag" and ui.tooltip.line == "Equip Reagent Bag")
    end
    for id = 1, (reagent and 5 or 4) do
        local button = assert(ui.buttons[id], "missing equipped/empty bag slot")
        assert(button.shown and button.point and button.drags[1] == "LeftButton")
        assert(button.invID == 29 + id)
        ui.cursor("Bag " .. id)
        button.scripts.OnReceiveDrag(button)
        assert(ui.equipped[29 + id] == "Bag " .. id and not ui.held())
        ui.event("PLAYER_EQUIPMENT_CHANGED")
        assert(button.icon.texture == "Bag " .. id)
        if id == 5 then
            button.scripts.OnEnter(button)
            assert(ui.tooltip.title == "Reagent Bag" and ui.tooltip.line == "Bag 5")
        end
        ui.cursor("Replacement " .. id)
        button.scripts.OnReceiveDrag(button)
        assert(ui.held() == "Bag " .. id and ui.equipped[29 + id] == "Replacement " .. id)
        ui.cursor(nil)
        button.scripts.OnDragStart(button)
        assert(ui.held() == "Replacement " .. id and not ui.equipped[29 + id])
        ui.cursor("invalid")
        local before = #ui.calls
        button.scripts.OnReceiveDrag(button)
        assert(ui.held() == "invalid" and #ui.calls == before + 1 and ui.calls[#ui.calls][1] == "drop")
    end
    for _ = 1, 4 do
        ui.bag:UpdateItemLayout()
        ui.event("BAG_UPDATE")
        assert(ui.bag.Items[1].point[5] == -106, "item grid overlaps bag slots")
        assert(ui.bag:GetHeight() == 238, "header height accumulates across refreshes")
    end
end
assert(Boot("live").buttons, "Live lost its existing slot row")
for _, family in ipairs({ "live", "forever" }) do
    local ui = Boot(family)
    local env, timers, opened = ui.env, {}, 0
    local settings = env.ContainerFrameSettingsManager
    settings.OnBagClosed = function() error("shared manager must remain unhooked") end
    local native = settings.OnBagClosed
    ui.event("PLAYER_ENTERING_WORLD")
    assert(settings.OnBagClosed == native, "bag-close manager replaced or hooked")
    env.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
    env.OpenBag = function(id) assert(id == 0); opened = opened + 1 end
    local afterEvent = assert(ui.bag.scripts.OnEvent)
    ui.bag:Hide()
    afterEvent(ui.bag, "BAG_CLOSED", 1)
    assert(#timers == 0, "normal bag close reopened the window")
    settings.checkReopenBags = { 1, 2 }
    afterEvent(ui.bag, "BAG_CLOSED", 0)
    assert(#timers == 0, "closing backpack reopened it")
    afterEvent(ui.bag, "BAG_CLOSED", 1); afterEvent(ui.bag, "BAG_CLOSED", 2)
    assert(#timers == 1, "unequip callbacks were not coalesced")
    timers[1](); assert(opened == 1, "unequipping a bag lost the open combined window")
    afterEvent(ui.bag, "BAG_CLOSED", 1); ui.bag:Show(); timers[2]()
    assert(opened == 1, "already reopened bag was opened again")
    ui.bag:Hide(); afterEvent(ui.bag, "BAG_CLOSED", 1)
    settings.IsUsingCombinedBags = function() return false end; timers[3]()
    assert(opened == 1, "stale callback reopened after switching bag UI")
end
assert(not Boot("forever", { noKeyring = true }).buttons[-1], "unsupported keyring was exposed")
for _, opts in ipairs({ { gamepad = true }, { alt = true } }) do
    local ui = Boot("forever", opts)
    assert(not ui.buttons and #ui.hooks == 0, "gamepad/alternative bag UI was changed")
end
assert(not Boot("era").buttons, "Era's own combined bag was modified")
print("Bag slot smoke OK (Forever native art/masks, reagent marker/tooltips, native keyring toggle with showKeyring off, key drops, bag equip/swap/unequip, refresh/layout, Live/gamepad/alternative UI guards)")
