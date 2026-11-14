-- Execute the real trinket owner, painter and cooldown cache together.
-- Desktop state transitions only: no native secure VM, rendering or FPS claim.
local checks = 0
local failures = {}
local function check(ok, message)
    checks = checks + 1
    if not ok then failures[#failures + 1] = message end
end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local sourceRoot = arg and arg[1] == "--root" and assert(arg[2]) or "."
local function fixture(client)
    local s = { now = 100, equipped = { [13] = 900001, [14] = 900002 }, usable = true,
        slotCD = { 0, 0, 1 }, itemCD = { 0, 0, 1 }, frames = {}, timers = {},
        slotReads = 0, itemReads = 0, hasSpell = true }
    local e = setmetatable({}, { __index = _G }); e._G = e
    e.FluxButton = {}
    e.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    e.GetTime = function() return s.now end
    e.GetBindingKey = function() return nil end -- Mouse/wheel path must wake and retire.
    e.IsMouseButtonDown = function() return s.mouse end
    e.IsKeyDown = function() return false end
    e.GetInventoryItemID = function(_, slot) return s.equipped[slot] end
    e.GetInventoryItemCooldown = function(_, slot)
        check(slot == 13 or slot == 14, "only equipped trinket slots queried")
        s.slotReads = s.slotReads + 1
        if not s.equipped[slot] then return 0, 0, 0 end
        return table.unpack(s.slotCD)
    end
    e.UnitClass = function() return "Mage", "MAGE" end
    e.RAID_CLASS_COLORS = { MAGE = { r = .2, g = .6, b = 1 } }
    e.C_Timer = { After = function(_, fn) s.timers[#s.timers + 1] = fn end }
    local function frame()
        local f = { shown = true, scripts = {}, events = {} }
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:IsShown() return self.shown end
        function f:RegisterEvent(name) self.events[name] = true end
        function f:SetScript(name, fn) self.scripts[name] = fn end
        function f:GetScript(name) return self.scripts[name] end
        function f:HookScript(name, fn)
            local old = self.scripts[name]
            self.scripts[name] = function(...) if old then old(...) end; fn(...) end
        end
        function f:SetAllPoints() end
        function f:SetColorTexture() end
        function f:CreateTexture() return frame() end
        function f:SetButtonState(value, locked) assert(not locked); self.state = value end
        function f:UnlockHighlight() end
        function f:SetChecked(value) self.checked = value end
        function f:SetAttribute() error("visual refresh must not write secure actions") end
        return f
    end
    e.CreateFrame = function() local f = frame(); s.frames[#s.frames + 1] = f; return f end
    e.CooldownFrame_Clear = function(cd) cd:Clear() end
    e.CooldownFrame_Set = function(cd, start, duration, enable)
        if enable and enable ~= 0 and start > 0 and duration > 0 then cd:SetCooldown(start, duration)
        else cd:Clear() end
    end
    local flux = { EBS = { buttons = {}, badges = {} }, Client = { isAnyClassic = client ~= "retail" and client ~= "forever" },
        Inventory = { IsReliable = function() return true end, GetCount = function() return 0 end,
            GetLiveCount = function() return 0 end },
        Item = {
            IsUsable = function() return false, false end,
            GetSpell = function() if s.hasSpell then return "Use Effect", 123 end end,
            GetCooldown = function() s.itemReads = s.itemReads + 1; return table.unpack(s.itemCD) end,
            IsConsumable = function() return false end, UsesConsumableCharges = function() return false end,
        },
        Spell = { IsUsable = function() return s.usable, false end },
    }
    local ns = { Flux = flux }
    for _, path in ipairs({ "Core/ButtonFX/Charges.lua", "ExtraButtonSystem/Engine/Paint.lua",
        "ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua" }) do
        local base = path == "Core/ButtonFX/Charges.lua" and "." or sourceRoot
        assert(load(read(base .. "/" .. path), "@" .. path, "t", e))("_FluxUI", ns)
    end
    local tm, paint = e.FluxTrinketMenu, flux.EBS.Paint
    s.tm, s.paint, s.env, s.watch = tm, paint, e, s.frames[1]
    tm.Frame, tm.VisibilityState = frame(), "both_equipped"
    tm.Buttons = {}
    for index = 0, 1 do
        local icon = { color = { 1, 1, 1 } }
        function icon:SetVertexColor(r, g, b) self.color = { r, g, b } end
        function icon:GetVertexColor() return table.unpack(self.color) end
        function icon:SetDesaturated(value) self.desaturated = value end
        local widget, cd = frame(), frame()
        function cd:ClearAllPoints() end
        function cd:SetPoint() end
        function cd:SetCooldown(start, duration) self.start, self.duration = start, duration; self.shown = true end
        function cd:Clear() self.start, self.duration, self.shown = 0, 0, false end
        function cd:SetDrawBling() end
        local b = { WIcon = icon, Widget = widget, WCooldown = cd,
            WNormalTexture = { SetVertexColor = function() end },
            inventorySlot = index + 13, ActionType = "macrotext", ActionValue = "/use " .. (index + 13), categoryScope = "class" }
        widget.icon, widget.FluxButton, widget.cooldown = icon, b, cd
        tm.Buttons[index] = b
        tm.SyncEquippedFace(b)
        tm.HookTrinketClickScripts(widget)
    end
    tm.SlotWidget = function(index) return tm.Buttons[index].Widget end
    tm.SyncKeybindPushWatch()
    function s:step(dt)
        self.now = self.now + dt
        if self.watch.shown then self.watch.scripts.OnUpdate(self.watch) end
        local timers = self.timers; self.timers = {}
        for _, fn in ipairs(timers) do fn() end
    end
    function s:press(b)
        self.mouse = true; b.Widget.scripts.OnMouseDown(b.Widget, "LeftButton")
    end
    function s:release()
        self.mouse = false; self.watch.scripts.OnEvent(self.watch, "GLOBAL_MOUSE_UP"); self:step(.01); self:step(.01)
    end
    return s
end

for _, client in ipairs({ "retail", "forever", "classic", "era", "anniversary" }) do
    local s = fixture(client)
    local b = s.tm.Buttons[0]
    s.tm.ApplyTrinketUsability(b)
    check(b.WIcon.color[1] == 1, client .. ": ready equipped face bright")
    s.usable = false; s.tm.ApplyTrinketUsability(b); s:press(b)
    check(math.abs(b.WIcon.color[1] - .4 * .62) < .0001, client .. ": unusable press tint retained")
    s.usable = true; s.tm.ApplyTrinketUsability(b)
    check(math.abs(b.WIcon.color[1] - .62) < .0001, client .. ": held press follows newest usable color")
    s:release()
    check(b.WIcon.color[1] == 1, client .. ": release cannot restore stale dark color")
    s.tm.ApplyTrinketUsability(b)
    check(b.WIcon.color[1] == 1, client .. ": cached repaint remains bright")
    check(not s.watch.shown, client .. ": mouse-only watcher sleeps after release")
    s:press(b); s.usable = false; s.tm.ApplyTrinketUsability(b); s:release()
    check(b.WIcon.color[1] == .4, client .. ": release retains new unusable tint")
    s.usable = true; s.tm.ApplyTrinketUsability(b)
    s.equipped[13] = nil; s.tm.ApplyTrinketUsability(b)
    check(b.WIcon.color[1] == .4 and b.WIcon.desaturated, client .. ": empty remains dark and desaturated")
    s.equipped[13] = 900001; s.tm.ApplyTrinketUsability(b)
    check(b.WIcon.color[1] == 1 and not b.WIcon.desaturated, client .. ": same item re-equipped restores cached white")
    s.hasSpell = false; s.tm.ApplyTrinketUsability(b)
    check(b.WIcon.color[1] == .4, client .. ": passive trinket remains dim")
    s.hasSpell = true; s.tm.ApplyTrinketUsability(b)
    s:press(b); s.tm.Frame:Hide(); s.tm.SyncKeybindPushWatch()
    check(not b.Widget._fluxTrinketPushShade.shown and b.WIcon.color[1] == 1, client .. ": hidden menu clears press shade")
    s.mouse = false; s.tm.Frame:Show(); s.tm.SyncKeybindPushWatch()

    -- Slot ready, item-ID cooldown stale: a usability event used to repaint the stale swipe.
    s.slotCD, s.itemCD = { 0, 0, 1 }, { 90, 120, 1 }
    s.tm.UpdateAllCooldowns()
    check(not b.WCooldown.shown and b.WCooldown.duration == 0, client .. ": ready slot clears stale item cooldown")
    s.tm.UpdateAllUsability()
    check(not b.WCooldown.shown, client .. ": usability refresh cannot reintroduce stale cooldown")
    -- Reverse disagreement must retain the real equipment/swap cooldown.
    s.slotCD, s.itemCD = { 100, 30, 1 }, { 0, 0, 1 }
    s.tm.UpdateAllCooldowns()
    check(b.WCooldown.shown and b.WCooldown.duration == 30, client .. ": real slot cooldown preserved")
    local second = s.tm.Buttons[1]
    check(second.WCooldown.shown and second.WCooldown.duration == 30, client .. ": second slot keeps real cooldown")
    s.slotCD = { 0, 0, 1 }; s.tm.UpdateAllCooldowns()
    check(not b.WCooldown.shown, client .. ": cooldown completion clears overlay")
    -- A slot refresh between two shared paints must update their common cache.
    s.slotCD = { 100, 30, 1 }; s.tm.UpdateTrinketCooldown(b)
    s.slotCD = { 0, 0, 1 }; s.tm.UpdateAllUsability()
    check(not b.WCooldown.shown, client .. ": intervening slot writer cannot leave cached stale swipe")
    check(s.itemReads == 0, client .. ": equipped faces use slot cooldown exclusively")
    local ordinary = { Widget = b.Widget, WIcon = b.WIcon, WCooldown = b.WCooldown,
        ActionType = "item", ActionValue = 900001, ItemId = 900001 }
    local reads = s.itemReads; s.paint.UpdateCooldown(ordinary)
    check(s.itemReads > reads, client .. ": ordinary items retain item-ID cooldown")
    -- Legacy widget fallback with no action metadata or global helper.
    s.env.CooldownFrame_Set = nil
    local legacy = { inventorySlot = 13, WCooldown = b.WCooldown }
    s.slotCD = { 100, 30, 1 }; s.tm.UpdateTrinketCooldown(legacy)
    check(b.WCooldown.duration == 30, client .. ": fallback paints live slot timer")
    s.slotCD = { 100, 30, 0 }; s.tm.UpdateTrinketCooldown(legacy)
    check(b.WCooldown.duration == 0 and not b.WCooldown.shown, client .. ": disabled fallback timer clears")
end
print(("trinket visual recovery: %d checks; %d failures; five desktop client models"):format(checks, #failures))
for _, message in ipairs(failures) do io.stderr:write(message .. "\n") end
assert(#failures == 0, "trinket visual recovery failed")
