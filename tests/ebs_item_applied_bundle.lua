-- Actual consumable Module.Update + EBS Action.SetAction/Core.Combat producers.
-- Public native-boundary spies measure calls and applied identities, not FPS,
-- native security or rendering. Optional arg[1] loads an archived Action.lua.
-- Inventory/Best/Paint bootstrap follows the existing consumable smoke fixture.
local root = ""
local checks = 0
local function eq(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, (label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function read(path)
    local file = assert(io.open(root .. path)); local source = file:read("*a"); file:close(); return source
end
local function compile(source, env)
    if setfenv then local chunk = assert(loadstring(source)); setfenv(chunk, env); return chunk end
    return assert(load(source, "consumables fixture", "t", env))
end
local families = {
    forever = { "1.16.0", 1, 16001 }, retail = { "12.0.1", 1, 120001 },
    era = { "1.15.9", 2, 11509 }, anniversary = { "2.5.6", 5, 20506 },
    wrath = { "3.4.3", 11, 30403 }, cata = { "4.4.2", 14, 40402 }, mists = { "5.5.4", 19, 50504 },
}
local items = {
    [117] = { kind = "food", effective = 60 }, [2287] = { kind = "food", effective = 120 },
    [159] = { kind = "water", effective = 100 }, [1251] = { kind = "bandage", effective = 66 },
    [2581] = { kind = "bandage", effective = 114 }, [118] = { kind = "healPotion", effective = 80 },
    [2455] = { kind = "manaPotion", effective = 120 }, [999] = { kind = "food", effective = 1000, minLevel = 80 },
    [5512] = { kind = "healthstone", effective = 90, maxStack = 1 },
    [5514] = { kind = "managem", effective = 100, maxStack = 1 },
    [22044] = { kind = "managem", effective = 1000, maxStack = 1 },
}
local kinds = { food = "IsFoodButton", water = "IsWaterButton", bandage = "IsBandageButton",
    healPotion = "IsHealPotionButton", manaPotion = "IsManaPotionButton", healthstone = "IsHealthstoneButton", managem = "IsManaGemButton" }
local function boot(family, legacy)
    local s = { now = 10, timers = {}, events = {}, frames = {}, tokens = {}, slots = { [0] = {}, [1] = {} }, bagSizes = { [0] = 16, [1] = 8 },
        uses = {}, combat = false, cached = true, writes = 0, scans = 0, bankOpen = false }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local Flux = { EBS = { buttons = {}, badges = {} }, Cap = {}, Module = { Register = function() end } }
    local ns = { Flux = Flux }; env.Flux = Flux; env.FluxButton = {}; env.SlashCmdList = {}
    local function load(path)
        local source = read(path)
        if path == "ExtraButtonSystem/Engine/Action.lua" and arg[1] then
            local file=assert(io.open(arg[1]));source=file:read("*a");file:close()
        end
        return compile(source, env)("_FluxUI", ns)
    end
    env.wipe = function(t) for key in pairs(t) do t[key] = nil end; return t end
    env.GetTime = function() return s.now end
    env.C_Timer = { After = function(delay, fn) s.timers[#s.timers + 1] = { at = s.now + delay, fn = fn } end }
    Flux.Timer = env.C_Timer
    env.CreateFrame = function()
        local f = { events = {}, scripts = {}, attrs = {} }
        function f:ClearAllPoints() end
        function f:SetPoint() end
        function f:SetAllPoints() end
        function f:SetParent(parent) self.parent=parent end
        function f:GetParent() return self.parent end
        function f:Show() self.shown=true end
        function f:Hide() self.shown=false end
        function f:IsShown() return self.shown~=false end
        function f:GetFrameLevel() return 1 end
        function f:SetFrameLevel() end
        function f:SetDrawLayer() end
        function f:GetSize() return 44,44 end
        function f:SetSize() end
        function f:SetAlpha() end
        function f:SetCooldown() end
        function f:Clear() end
        function f:RegisterEvent(event) self.events[event] = true end
        function f:RegisterUnitEvent(event) self.events[event] = true end
        function f:SetScript(event, fn) self.scripts[event] = fn end
        function f:HookScript(event, fn) self.scripts[event] = fn end
        function f:RegisterForDrag() assert(not s.combat, "protected drag in combat") end
        function f:SetAttribute(key, value)
            assert(not s.combat, "protected attribute in combat")
            s.attrWrites = (s.attrWrites or 0) + 1
            if s.failNative then s.failNative=false; error("injected native setter failure") end
            self.attrs[key] = value
        end
        function f:GetAttribute(key)
            s.attrReads=(s.attrReads or 0)+1
            if s.privateNativeRead then return s.privateNativeRead end
            if s.failNativeRead then error("injected unreadable native attribute") end
            return self.attrs[key]
        end
        f._name = "FixtureWidget" .. (#s.frames+1)
        function f:GetName() return self._name end
        s.frames[#s.frames + 1] = f; return f
    end
    Flux.Safecall = function(fn, ...) return fn(...) end
    Flux.Events = { Register = function(event, fn)
        s.events[event] = s.events[event] or {}; table.insert(s.events[event], fn)
    end, RegisterUnit = function(event, _, fn)
        s.events[event] = s.events[event] or {}; table.insert(s.events[event], fn); return true
    end }
    Flux.Scheduler = { Request = function(_, token) s.tokens[token] = true end,
        Register = function(_, fn) s.inventoryFlush = fn end }
    function s:event(event, ...)
        for _, fn in ipairs(self.events[event] or {}) do fn(event, ...) end
        for _, f in ipairs(self.frames) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end end
    end
    function s:advance(seconds)
        local target, iterations = self.now + seconds, 0
        while true do
            iterations = iterations + 1; assert(iterations < 1000, "unbounded refresh loop")
            if next(self.tokens) then
                local tokens = self.tokens; self.tokens = {}
                if self.inventoryFlush then self.inventoryFlush(tokens)
                else
                    if Flux.Inventory.source == "builtin" then Flux.Inventory.Builtin.Flush(tokens) end
                    Flux.Inventory.Notify(tokens)
                end
            end
            local first, at
            for i, t in ipairs(self.timers) do if t.at <= target and (not at or t.at < at) then first, at = i, t.at end end
            if not first then break end
            local t = table.remove(self.timers, first); self.now = t.at; t.fn()
        end
        self.now = target
    end
    env.WOW_PROJECT_ID = families[family][2]
    env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC, env.WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 1, 2, 5
    env.WOW_PROJECT_WRATH_CLASSIC, env.WOW_PROJECT_CATACLYSM_CLASSIC, env.WOW_PROJECT_MISTS_CLASSIC = 11, 14, 19
    env.GetBuildInfo = function() return families[family][1], "70000", "", families[family][3] end
    env.InCombatLockdown = function() return s.combat end
    env.UnitHealthMax = function() return 500 end; env.UnitPowerMax = function() return 1000 end
    env.UnitLevel = function() return 10 end
    env.UnitClass = function() return "Mage", "MAGE" end
    local function info(id)
        local d = items[id]; if not d or not s.cached then return end
        return "item" .. id, "item:" .. id, 1, 1, d.minLevel or 1, "Consumable", "Other", d.maxStack or 20, "", 1, 0, 0, 0
    end
    local function count(id, bank, uses, ...)
        if legacy then assert(select("#", ...) == 0, "legacy count called with unsupported arguments") end
        if uses then return s.uses[id] or 0 end
        local n = bank and 100 or 0
        for _, bag in pairs(s.slots) do for _, slot in pairs(bag) do if slot.itemID == id then n = n + slot.stackCount end end end
        return n
    end
    local function slots(bag) return s.bagSizes[bag] or 0 end
    env.C_Item = { GetItemInfo = info, GetItemCount = not legacy and count or nil,
        IsConsumableItem = function(id) return items[id] ~= nil end, IsUsableItem = function() return true, false end }
    env.GetItemInfo = info; env.GetItemCount = legacy and count or nil
    if legacy then
        env.GetContainerNumSlots = slots
        env.GetContainerItemInfo = function(bag, slot)
            local rec = s.slots[bag] and s.slots[bag][slot]
            if rec then return 1, rec.stackCount, false, 1, false, false, rec.hyperlink, false, false, rec.itemID end
        end
    else
        env.C_Container = { GetContainerNumSlots = slots,
            GetContainerItemInfo = function(bag, slot) return s.slots[bag] and s.slots[bag][slot] end,
            GetContainerItemID = function(bag, slot) local rec = s.slots[bag] and s.slots[bag][slot]; return rec and rec.itemID end }
    end
    load("Core/Client.lua"); load("Core/API/Item.lua"); load("Core/API/Container.lua")
    load("Inventory/Init.lua"); load("Inventory/Containers.lua"); load("Inventory/Index.lua")
    local Inv = Flux.Inventory; s.inv = Inv
    Inv.Builtin.Bank = { Refresh = function() end, IsOpen = function() return s.bankOpen end }
    Inv.Builtin.Equip = { Refresh = function() end, Invalidate = function() end }
    load("Inventory/Builtin/Bags.lua"); load("Inventory/Builtin/Watch.lua"); load("Inventory/LegacyBridge.lua")
    load("Inventory/Craft.lua")
    Inv.Builtin.Start(); s:advance(0)
    load("Inventory/FluxConsumableBest/Init.lua"); load("Inventory/FluxConsumableBest/Score.lua")
    local Best = env.FluxConsumableBest; s.best = Best
    Best.Persist = { GetRoot = function() end, GetRef = function() end, MaybeUpdateRef = function() end }
    Best.VendorMemory = { HookMerchantIndex = function() end, GetVendorCandidates = function() return {} end }
    env.FluxConsumableClassify = { Classify = function(id) return items[id] end }
    -- Only item classification data and persistence are fixtures; use the real
    -- bounded scanner, ranking, owned ladders, event dispatch and button code.
    load("Inventory/FluxConsumableBest/Scan.lua")
    local recompute = Best.Scan.Recompute
    Best.Scan.Recompute = function(opts) s.scans = s.scans + 1; return recompute(opts) end
    load("Inventory/FluxConsumableBest/FluxConsumableBest.lua"); s:advance(0)
    env.GetBindingKey = function(name) return (s.keys and s.keys[1]) or "Q", (s.keys and s.keys[2]) or "SHIFT-Q" end
    env.ClearOverrideBindings = function(owner) assert(not s.combat,"binding clear in combat"); s.bindClears=(s.bindClears or 0)+1;s.bindingRoutes=s.bindingRoutes or {};s.bindingRoutes[owner:GetName()]={} end
    env.SetOverrideBindingClick = function(owner, priority, key, widget, click)
        assert(not s.combat,"binding write in combat")
        s.bindWrites=(s.bindWrites or 0)+1; s.bindingRoutes=s.bindingRoutes or {}; s.bindingRoutes[owner:GetName()]=s.bindingRoutes[owner:GetName()]or{};s.bindingRoutes[owner:GetName()][key]={widget,click}
    end
    Flux.Cap.ClientSupportsSingleButtonAssistant=function() return false end
    load("Core/Engine/Combat.lua"); load("ExtraButtonSystem/Engine/Paint.lua"); load("ExtraButtonSystem/Engine/Action.lua"); load("ExtraButtonSystem/Engine/ConsumableBind.lua")
    local paint = Flux.EBS.Paint; s.paint = paint; s.bridge = env.FluxEBSConsumableBridge
    Inv.Register("smoke.counts", function(ctx) paint.FlushCounts(ctx) end, { tier = "instant", sync = true, regions = { "bags" } })
    local gridSource = read("ExtraButtonSystem/CombatGrid/Grid.lua")
    local first = assert(gridSource:find("function btn:SetCount(count, opts)", 1, true))
    local last = assert(gridSource:find("function btn:ShowTooltip()", first, true))
    function s:button(kind, craft, modulePath, coalesce)
        local text = { ClearAllPoints=function()end, SetPoint=function()end, GetDrawLayer=function()return "OVERLAY",0 end, SetDrawLayer=function()end, value = "", Show = function() end, IsShown = function() return true end,
            SetText = function(self, value) self.value = tostring(value) end, GetText = function(self) return self.value end, SetAlpha = function() end }
        local icon = { SetVertexColor = function(self, r, g, b) self.color = { r, g, b } end,
            SetDesaturated = function() end, SetTexture = function() end, Show = function() end, SetTexCoord = function() end }
        local btn = { Widget = env.CreateFrame(), WCount = text, WIcon = icon }
        function btn:SetAction(action, id)
            assert(not s.combat, "rebound a consumable in combat"); s.writes = s.writes + 1
            if s.reenterActionOnce then
                s.reenterActionOnce=false;s.combat=true
                return Flux.EBS.Action.SetAction(self,action,id)
            end
            if s.deferActionOnce then
                s.deferActionOnce=false
                local oldSet = self.Widget.SetAttribute
                self.Widget.SetAttribute=function() error("injected native setter failure") end
                local ok,err=pcall(Flux.EBS.Action.SetAction,self,action,id)
                self.Widget.SetAttribute=oldSet
                if not ok then error(err,0) end
                return
            end
            return Flux.EBS.Action.SetAction(self,action,id)
        end
        function btn:ClearPlaceholder() self.PlaceholderTexture = nil; self.PlaceholderHideCount = nil end
        function btn:SetPlaceholder(texture)
            assert(not s.combat, "placeholder in combat")
            self.PlaceholderTexture = texture; self.PlaceholderHideCount = true
            self.ActionType, self.ActionValue = nil, nil
        end
        function btn:SetLocked() end
        function btn:FullRefresh() paint.UpdateCount(self); paint.UpdateUsable(self) end
        compile("local btn = ...\n" .. gridSource:sub(first, last - 1), env)(btn)
        btn.UpdateUsable = function(self) paint.UpdateUsable(self) end
        btn.ClearAction=function(self) Flux.EBS.Action.Clear(self)end
        local ps=assert(gridSource:find("function btn:SetPlaceholder(icon, label)",1,true))
        local pe=assert(gridSource:find("function btn:SetLocked(locked)",ps,true))
        compile("local btn,ebs=...\n"..gridSource:sub(ps,pe-1),env)(btn,Flux.EBS)
        local module = {}
        Flux.EBS.buttons[#Flux.EBS.buttons + 1] = btn
        if modulePath then
            module = load(modulePath)
            module.Create({ ButtonSize = 44, CreateButton = function() return btn end })
        else
            env.FluxEBSButtonRefresh.Attach({ module = module, btn = btn, kind = kind, kindFlag = kinds[kind],
                charges = kind == "managem" or kind == "healthstone", listenerKey = "smoke." .. kind, bindingName="FIXTURE_"..kind,
                combatGridCoalesce = coalesce,
                placeholderIcon = "placeholder", placeholderLabel = kind, reapplyCraftOnBag = craft,
                applyRightClick = function()
                    s.rightClicks = (s.rightClicks or 0) + 1
                    if craft then s.bridge.ApplyCraftOrRestockRightClick(btn, kind) end
                    if s.rightSpell then s.bridge.ApplyRightClickSpell(btn,s.rightSpell)end
                    if s.shiftRightSpell then s.bridge.ApplyShiftRightClickSpell(btn,s.shiftRightSpell)end
                    if s.rightMacro then s.bridge.ApplyRightClickMacro(btn,s.rightMacro)end
                end })
        end
        return btn, module
    end
    function s:set(bag, slot, id, n)
        self.slots[bag] = self.slots[bag] or {}
        self.slots[bag][slot] = n > 0 and { itemID = id, stackCount = n, hyperlink = "item:" .. id } or nil
    end
    function s:bags(delay)
        self:event("BAG_UPDATE", 0); self:event("BAG_UPDATE", 1); self:event("BAG_UPDATE_DELAYED")
        self:advance(delay or 0.4)
    end
    function s:expect(btn, id, n, label)
        eq(btn.ItemId, id, label .. " item"); eq(btn.WCount.value, tostring(n), label .. " count")
        paint.UpdateUsable(btn); eq(btn.WIcon.color[1], n > 0 and 1 or 0.4, label .. " tint")
    end
    s.load, s.env = load, env
    return s
end


local selected={"retail","forever","mists","era","anniversary"}
local ids={{"food",117},{"water",159},{"bandage",1251},{"healPotion",118},{"manaPotion",2455},{"managem",5514},{"healthstone",5512}}
local rows={}
local function reset(s) s.writes,s.attrWrites,s.attrReads,s.bindClears,s.bindWrites=0,0,0,0,0 end
local function summary(s) return string.format("actions=%d|attributes=%d|attributeReads=%d|clearBindings=%d|binds=%d",s.writes,s.attrWrites or 0,s.attrReads or 0,s.bindClears or 0,s.bindWrites or 0)end
for _,family in ipairs(selected)do
 local s=boot(family,family=="era"or family=="anniversary")
 for i,p in ipairs(ids)do s:set(0,i,p[2],5);s.uses[p[2]]=5 end;s:bags()
 local buttons,mods={},{}
 for _,p in ipairs(ids)do local btn,m=s:button(p[1],false);buttons[#buttons+1]=btn;mods[#mods+1]=m end
 s:advance(.5)
 for i,btn in ipairs(buttons)do eq(btn.ItemId,ids[i][2],family.." prepared identity");eq(btn.Widget.attrs.type,"item",family.." prepared native type")end
 reset(s)
 for cycle=1,10 do s.combat=true;s:event("PLAYER_REGEN_DISABLED");eq(s.attrWrites,2*7*(cycle-1),family.." entry no secure writes");s.combat=false;s:event("PLAYER_REGEN_ENABLED");s:advance(.05)end
 print("CLEAN|"..family.."|"..summary(s))
 for i,btn in ipairs(buttons)do eq(btn.ItemId,ids[i][2],family.." stable desired");eq(btn.Widget.attrs.type,"item",family.." stable native type");eq(btn.Widget.attrs.item,"item"..ids[i][2],family.." stable native item")end
 -- A failed native application updates desired tracked state before throwing.
 -- Reapply after a later combat boundary must restore the actual native bundle.
 local b,m=buttons[3],mods[3]
 s:set(0,3,2581,5);s:bags();m.Update(true)
 eq(b.ItemId,2581,family.." higher bandage selected")
 b.Widget.attrs.item="old-native-item";s.deferActionOnce=true
 local ok,err=pcall(m.Update,true);eq(ok,false,family.." failed native apply surfaced")
 eq(m._trackedItemID,2581,family.." desired already committed on failed native write")
 eq(b.Widget.attrs.item,"old-native-item",family.." actual native still old after failure")
 reset(s);s.combat=true;s:event("PLAYER_REGEN_DISABLED");s.combat=false;s:event("PLAYER_REGEN_ENABLED");s:advance(.05)
 eq(b.Widget.attrs.item,"item2581",family.." pending/native failure restored at boundary")


 print("FAILURE_RECOVERY|"..family.."|"..summary(s))
 -- Legacy fixtures without GetAttribute remain on the original full write path.
 local getter,setter=b.Widget.GetAttribute,b.Widget.SetAttribute
 b.Widget.GetAttribute=nil;reset(s);m.Update(true);eq(s.attrWrites,17,family.." missing getter full write fallback")
 reset(s);m.Update(true);eq(s.attrWrites,17,family.." missing getter never caches success")
 b.Widget.GetAttribute=getter;reset(s);m.Update(true);eq(s.attrWrites,17,family.." restored getter establishes completed bundle")
 reset(s);m.Update(true);eq(s.attrWrites,2,family.." completed bundle enables bounded reuse")
 -- Active native method replacements must establish their own completed bundle.
 b.Widget.SetAttribute=function(self,k,v)return setter(self,k,v)end
 reset(s);m.Update(true);eq(s.attrWrites,17,family.." replacement setter invalidates applied method owner")
 reset(s);m.Update(true);eq(s.attrWrites,2,family.." replacement setter reused only after completed write")
 b.Widget.GetAttribute=function(self,k)return getter(self,k)end
 reset(s);m.Update(true);eq(s.attrWrites,17,family.." replacement getter invalidates applied method owner")
 reset(s);m.Update(true);eq(s.attrWrites,2,family.." replacement getter reused only after completed write")
 local replacementGetter=b.Widget.GetAttribute
 local replaced=false
 b.Widget.GetAttribute=function(self,k)
  if not replaced then replaced=true;self.SetAttribute=function(w,kk,vv)return setter(w,kk,vv)end end
  return getter(self,k)
 end
 reset(s);m.Update(true);eq(s.attrWrites,17,family.." replacement during snapshot cannot reuse older owner")
 reset(s);m.Update(true);eq(s.attrWrites,17,family.." changed snapshot method requires another completed full write")
 reset(s);m.Update(true);eq(s.attrWrites,2,family.." settled replacement becomes eligible")
 b.Widget.GetAttribute=replacementGetter;b.Widget.SetAttribute=setter;m.Update(true)
 -- Public native tampering, getter denial/private values, changed widget identity.
 b.Widget.attrs.spell="stale-other-owner";m.Update(true);eq(b.Widget.attrs.spell,nil,family.." actual foreign native field repaired")
 s.failNativeRead=true;m.Update(true);s.failNativeRead=false;eq(b.Widget.attrs.item,"item2581",family.." unreadable native getter takes full repair path")
 local opaque=setmetatable({},{__eq=function()error("private equality")end,__tostring=function()error("private string")end})
 s.env.issecretvalue=function(v)return rawequal(v,opaque)end;s.privateNativeRead=opaque;m.Update(true);s.privateNativeRead=nil
 eq(b.Widget.attrs.item,"item2581",family.." opaque native getter takes full repair path")
 local oldWidget=b.Widget;b.Widget=s.env.CreateFrame();m.Update(true)
 eq(b.Widget.attrs.type,"item",family.." same desired ID new widget receives native type")
 eq(b.Widget.attrs.item,"item2581",family.." same desired ID new widget receives native item")
 -- All RC/key/conjure/craft work remains live even when LEFT bundle is reused.
 s.keys={"F","CTRL-SHIFT-F"};s.rightSpell="ConjurePublicA";s.shiftRightSpell="ConjurePublicB";m.Update(true)
 local routes=s.bindingRoutes[b.Widget:GetName()]
 eq(routes.F[1],b.Widget:GetName(),family.." changed bare key routes current widget")
 eq(routes["CTRL-SHIFT-F"][1],b.Widget:GetName(),family.." changed modifier key routes current widget")
 local expectedClick=routes.F[2];assert(expectedClick=="LeftButton"or expectedClick=="KeyBind")
 local beforeRC=b.Widget.attrs.macrotext2 or b.Widget.attrs.spell2
 s.rightSpell="ConjurePublicC";m.Update(true)
 local afterRC=b.Widget.attrs.macrotext2 or b.Widget.attrs.spell2
 eq(beforeRC~=afterRC,true,family.." fresh conjure RC config despite LEFT reuse")
 s.rightSpell=nil;s.shiftRightSpell=nil;s.rightMacro="/cast PublicCraftA";m.Update(true)
 eq(b.Widget.attrs.macrotext2,s.rightMacro,family.." fresh craft RC macro")
 s.rightMacro="/cast PublicCraftB";m.Update(true)
 eq(b.Widget.attrs.macrotext2,s.rightMacro,family.." changed craft RC macro kept live")
 s.env.Flux.ButtonFX={Click={UsesWrap=function()return true end}}
 m.Update(true);eq(s.bindingRoutes[b.Widget:GetName()].F[2],"KeyBind",family.." wrapped click ID remains current")
 s.env.Flux.ButtonFX.Click.UsesWrap=function()return false end
 m.Update(true);eq(s.bindingRoutes[b.Widget:GetName()].F[2],"LeftButton",family.." unwrapped click ID remains current")
 local nativeChecks,itemClassifications=0,0
 s.env.Flux.MouseoverCast={ApplyNativeCheck=function(w)nativeChecks=nativeChecks+1;w:SetAttribute("unit",s.moUnit)end,SetButtonItem=function(w,id)itemClassifications=itemClassifications+1;eq(id,2581,family.." fresh item classification ID")end}
 s.moUnit="target";m.Update(true);s.moUnit="mouseover";m.Update(true)
 eq(b.Widget.attrs.unit,"mouseover",family.." native mouseover config remains current")
 eq(nativeChecks,2,family.." native check helper called on both applications")
 eq(itemClassifications,2,family.." item classifier called on both applications")
 s.env.Flux.MouseoverCast=nil;s.env.Flux.ButtonFX=nil;s.rightMacro=nil
 -- A real desired identity change during combat defers native work until drain.
 s.combat=true;s:event("PLAYER_REGEN_DISABLED");s:set(0,3,2581,0);s.uses[2581]=0;s:bags();m.Update(true)
 eq(m._pendingUpdate,true,family.." combat selection keeps pending update")
 eq(b.Widget.attrs.type,"item",family.." combat depletion keeps applied native until regen")
 s.combat=false;s:event("PLAYER_REGEN_ENABLED");s:advance(.1)
 eq(b.Widget.attrs.type,nil,family.." depleted identity clears actual native at regen")
 s:set(0,3,1251,3);s.uses[1251]=3;s:bags();m.Update(true)
 eq(b.Widget.attrs.item,"item1251",family.." fresh replacement ID applied")
 s.combat=true;s:set(0,3,1251,0);s:set(0,8,2581,4);s.uses[1251]=0;s.uses[2581]=4;s:bags();m.Update(true)
 eq(b.Widget.attrs.item,"item1251",family.." new best remains deferred during combat")
 s.combat=false;s:event("PLAYER_REGEN_ENABLED");s:advance(.1)
 eq(b.Widget.attrs.item,"item2581",family.." fresh new best applied after combat")
 -- Reentrant lockdown after desired latch commit: actual Combat.Defer drains.
 b.Widget.attrs.item="old-before-defer";s.reenterActionOnce=true;m.Update(true)
 eq(s.combat,true,family.." injected reentrant combat reached actual Action")
 eq(b.Widget.attrs.item,"old-before-defer",family.." deferred action has not published native bundle")
 eq(s.env.Flux.Combat.HasPending(),true,family.." actual named combat queue owns deferred apply")
 s.combat=false;s:event("PLAYER_REGEN_ENABLED");s:advance(.1)
 eq(b.Widget.attrs.item,"item2581",family.." actual deferred drain restores native item")
 eq(s.env.Flux.Combat.HasPending(),false,family.." actual queue fully drains")
 -- Food/water eligibility is recomputed after combat; conjured charge counts live.
 for _,i in ipairs{1,2,6,7}do
  local bb,mm=buttons[i],mods[i];s.combat=true;s:set(0,i,ids[i][2],0);s.uses[ids[i][2]]=0;s:bags();mm.Update(true)
  eq(mm._pendingUpdate,true,family.." kind"..i.." combat depletion pending")
  s.combat=false;s:event("PLAYER_REGEN_ENABLED");s:advance(.1)
  eq(bb.Widget.attrs.type,nil,family.." kind"..i.." depleted native cleared")
  s:set(0,i,ids[i][2],3);s.uses[ids[i][2]]=3;s:bags();mm.Update(true)
  eq(bb.Widget.attrs.type,"item",family.." kind"..i.." conjure/refill native restored")
  eq(bb.Widget.attrs.item,"item"..ids[i][2],family.." kind"..i.." correct native ID")
 end
 print("MATRIX|"..family.."|public-native-repair/private/denial/new-widget/keys/mods/click/conjure/craft/mouseover/depletion/new-best/reentrant-drain PASS")
end
print("EBS applied item bundle: "..checks.." checks PASS; actual Module/Action/native-boundary work; no native FPS/pixels/taint claim")
