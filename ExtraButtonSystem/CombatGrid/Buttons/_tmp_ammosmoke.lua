-- lua ExtraButtonSystem/CombatGrid/Buttons/_tmp_ammosmoke.lua
-- Actual ammo module, current Paint engine and CombatGrid SetCount contract.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../../../"
local function Read(path)
    local f = assert(io.open(root .. path)); local s = f:read("*a"); f:close(); return s
end
local function Compile(s, env)
    if setfenv then local f = assert(loadstring(s)); setfenv(f, env); return f end
    return assert(load(s, "ammo fixture", "t", env))
end
local setCountSource = Read("ExtraButtonSystem/CombatGrid/Grid.lua")
local first = assert(setCountSource:find("function btn:SetCount(count, opts)", 1, true))
local last = assert(setCountSource:find("function btn:ShowTooltip()", first, true))
setCountSource = setCountSource:sub(first, last - 1)
local function Boot(family, legacy)
    local s = { current = 150, maximum = 200, count = 0, ranged = 100, ammo = nil,
        events = {}, timers = {}, attrs = 0, reads = 0, combat = false, frames = {} }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local Flux = { Client = { isCamelot = family == "forever" }, EBS = { buttons = {}, badges = {} },
        Inventory = { GetLiveCount = function(id, opts)
            assert(opts.charges and not opts.bank); return s.count
        end }, Item = { IsUsable = function() s.usabilityProbes = (s.usabilityProbes or 0) + 1; return false end },
        Range = { CheckItem = function() error("display-only ammo probed item range") end } }
    env.Flux, env.FLUX_API, env.FluxButton = Flux, Flux.Client, {}
    env.InCombatLockdown = function() return s.combat end
    env.GetInventorySlotInfo = function(token) return token == "AmmoSlot" and 0 or 18 end
    env.GetInventoryItemID = function(_, slot) if slot == 0 then return s.ammo end; return s.ranged end
    env.GetInventoryItemDurability = function(slot)
        assert(slot == 18, "durability read a bag copy or wrong equipment slot")
        s.reads = s.reads + 1; return s.current, s.maximum
    end
    local function ItemInstant(id)
        local thrown = id == 100 or id == 101
        if legacy then return id, "Weapon", "Thrown", thrown and "INVTYPE_THROWN" or "INVTYPE_RANGED", 1, 2, thrown and 16 or 2 end
        return { itemEquipLoc = thrown and "INVTYPE_THROWN" or "INVTYPE_RANGED", classID = 2, subClassID = thrown and 16 or 2 }
    end
    if legacy then env.GetItemInfoInstant = ItemInstant else env.C_Item = { GetItemInfoInstant = ItemInstant } end
    env.issecretvalue = function(v) return type(v) == "table" and v.secret end
    env.C_Timer = { NewTimer = function(_, fn)
        local timer = { fn = fn, Cancel = function(self) self.cancelled = true end }
        s.timers[#s.timers + 1] = timer; return timer
    end }
    env.CreateFrame = function()
        local f = { events = {} }
        function f:RegisterEvent(event) self.events[event] = true end
        function f:SetScript(_, fn) self.onEvent = fn end
        s.frames[#s.frames + 1] = f; return f
    end
    env.FluxCombatManager = { RegisterCombatRefresh = function(_, key, fn) assert(key == "Ammo"); s.tick = fn end,
        UnregisterCombatRefresh = function() s.tick = nil end }
    env.FluxInv = { RegisterListener = function(_, fn) s.inventoryChanged = fn end }
    local ns = { Flux = Flux }
    Compile(Read("ExtraButtonSystem/Engine/Paint.lua"), env)("_FluxUI", ns)
    local paint = Flux.EBS.Paint
    local icon = { SetVertexColor = function(self, ...) self.color = { ... } end,
        SetDesaturated = function(self, v) self.desaturated = v end }
    local text = { text = "", shown = true, Show = function(self) self.shown = true end,
        IsShown = function(self) return self.shown end, GetText = function(self) return self.text end,
        SetText = function(self, v) self.text = tostring(v) end, SetAlpha = function() end }
    local widget = { SetAttribute = function()
        assert(not s.combat, "ammo changed secure attributes in combat"); s.attrs = s.attrs + 1
    end }
    local btn = { Widget = widget, WIcon = icon, WCount = text, SlotFrame = {
        Show = function() assert(not s.combat, "ammo changed layout in combat") end,
        Hide = function() assert(not s.combat, "ammo changed layout in combat") end,
    } }
    Compile("local btn = ...\n" .. setCountSource, env)(btn)
    function btn:SetAction(kind, id)
        assert(not s.combat, "ammo rebound in combat")
        self.ActionType, self.ActionValue, self.ItemId = kind, id, id
    end
    function btn:SetLocked() end
    function btn:ClearPlaceholder() self.PlaceholderTexture = nil end
    function btn:ClearAction() self.ActionType, self.ActionValue, self.ItemId = nil, nil, nil end
    function btn:SetPlaceholder(tex) self.PlaceholderTexture = tex end
    function btn:FullRefresh()
        paint.UpdateCount(self); paint.UpdateRange(self); paint.UpdateUsable(self)
    end
    local grid = { ButtonSize = 45, CreateButton = function() return btn end }
    local module = Compile(Read("ExtraButtonSystem/CombatGrid/Buttons/Ammo.lua"), env)()
    module.Create(grid)
    function s:event(event)
        for _, frame in ipairs(self.frames) do
            if frame.events[event] then frame.onEvent(frame, event) end
        end
    end
    function s:flush()
        local timers = self.timers; self.timers = {}
        for _, timer in ipairs(timers) do if not timer.cancelled then timer.fn() end end
    end
    function s:bright()
        paint.UpdateRange(btn); paint.UpdateUsable(btn)
        assert(icon.color[1] == 1 and icon.color[2] == 1 and icon.color[3] == 1 and icon.desaturated == false)
        assert(not btn._outOfRange)
    end
    function s:countIs(value)
        assert(text.text == value, "expected " .. value .. ", got " .. text.text)
        paint.UpdateCount(btn)
        assert(text.text == value, "inventory paint overwrote ammo count")
    end
    return s, btn, module, paint
end

for _, legacy in ipairs({ false, true }) do
    local s, btn, module, paint = Boot("forever", legacy)
    s:countIs("150"); s:bright()
    assert(not btn._forcedCountLive, "durability enabled bag-count replacement")
    -- A stored OOR/rank state must not darken a display-only equipped weapon.
    btn._outOfRange, btn._fluxRankDesaturated = true, true
    btn._lastIconR = nil; s:bright(); assert(not btn._fluxRankDesaturated)
    s.combat = true; s:event("PLAYER_REGEN_DISABLED"); assert(s.tick)
    local attrs = s.attrs
    s.current = 149; s:event("UPDATE_INVENTORY_DURABILITY"); s:countIs("149"); s:bright()
    s.current = 148; s.tick(); s:countIs("148")
    s.current = 0; s:event("UPDATE_INVENTORY_DURABILITY"); s:countIs("0"); s:bright()
    assert(s.attrs == attrs, "durability refresh changed secure bindings")
    s.combat = false; s:event("PLAYER_REGEN_ENABLED"); assert(not s.tick)
    s.current = 200; s:event("UPDATE_INVENTORY_DURABILITY"); s:countIs("200")
    -- Legacy stack-based thrown weapons retain real counts when no durability
    -- exists. Switching back must clear the live bag-count override again.
    s.current, s.maximum, s.count = nil, nil, 80; module.Update(); s:countIs("80")
    assert(btn._forcedCountLive)
    s.current, s.maximum, s.count = 150, 200, 0; module.Update(); s:countIs("150")
    -- Nil/restricted durability is never formatted or compared as a number.
    s.current = setmetatable({ secret = true }, { __lt = function() error("compared secret durability") end,
        __tostring = function() error("serialized secret durability") end })
    s:event("UPDATE_INVENTORY_DURABILITY"); s:countIs("0")
    s.current = 150
    -- Equipping another durable thrown item refreshes its own instance.
    s.ranged, s.current, s.maximum = 101, 51, 100
    s:event("PLAYER_EQUIPMENT_CHANGED"); s:flush(); s:countIs("51")
    -- Bow + arrows uses the ammo count, never the bow's durability.
    s.ranged, s.ammo, s.count = 102, 200, 235
    s:event("PLAYER_EQUIPMENT_CHANGED"); s:flush(); s:countIs("235"); s:bright()
    s.ammo = nil; module.Update(); assert(btn.ActionType == "item") -- hidden slot preserves identity as before
    -- Ordinary item-use buttons still dim when unusable; the exemption is
    -- limited to the display-only flag, not every equipped item or weapon.
    btn.IgnoreUsabilityVisual, btn._lastIconR = nil, nil
    paint.UpdateUsable(btn)
    assert(btn.WIcon.color[1] == 0.4 and s.usabilityProbes > 0, "ordinary unusable item stopped dimming")
end
for _, family in ipairs({ "era", "anniversary", "mists", "live" }) do
    local s = Boot(family, true)
    s.count = 75; s.inventoryChanged({ changeKind = "countOnly" }); s:countIs("75"); s:bright()
    assert(s.reads == 0, family .. " unexpectedly switched to durability")
end
print("Ammo OK: Forever durability + repairs + combat ticks; count survives current Paint; bright display-only icon; real stack/ammo counts and other clients preserved")
