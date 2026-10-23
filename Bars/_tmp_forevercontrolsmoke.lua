-- lua Bars/_tmp_forevercontrolsmoke.lua
-- Actual Forever SecureStateDriver/SecureTemplates plus Flux Restricted,
-- State, Clicks, ButtonFX, Layout and SlotProgram. Engine taint is not modeled.
local root = (arg[0]:match('^(.*)[/\\]') or '.') .. '/../'
local function read(path)
    local f = assert(io.open(root .. path, 'r')); local s = f:read('*a'); f:close(); return s
end
local function compile(src, env) return assert(load(src, 'control fixture', 't', env)) end
local v8Math = assert(loadfile(root..'../__Backup/v8/_FluxUI/Bars/SlotMath.lua'))('_FluxUI', { Flux={Bars={}} })
local function boot(initialSwap, promotion, broken, normalPage)
    normalPage=normalPage or 1
    local locked, secure, kind, swap, casts = false, false, 'normal', initialSwap, {}
    local frames, binds, ns = {}, {}, { Flux = { Bars = {}, Cap = { hasRestrictedClosures = false } } }
    local env = setmetatable({}, { __index = _G }); env._G = env
    local F, B = ns.Flux, ns.Flux.Bars
    F.Client = { isCamelot = true, isForever = true, isPostDF = true, isRetail = true }
    F.Combat = { InLockdown = function() return locked end }
    env.InCombatLockdown = F.Combat.InLockdown
    local Frame = {}
    local function run(frame, body, args)
        local ctx = setmetatable({ self = frame, control = frame, owner = frame }, { __index = env })
        for k, v in pairs(args or {}) do ctx[k] = v end
        return compile(body, ctx)()
    end
    function Frame:GetAttribute(a, b, c)
        if not b then return self.attrs[a] end
        for _, key in ipairs({ a..b..c, '*'..b..c, a..b..'*', '*'..b..'*', a..b, b..c, b..'*', b }) do
            if self.attrs[key] ~= nil then return self.attrs[key] end
        end
    end
    function Frame:SetAttribute(name, value)
        assert(not locked or secure, 'insecure combat write: '..tostring(self.name)..':'..name)
        local changed = self.attrs[name] ~= value; self.attrs[name] = value
        if changed then
            if self.scripts.OnAttributeChanged then
                local old = secure; secure = self.name == 'SecureStateDriverManager' or secure
                self.scripts.OnAttributeChanged(self, name, value); secure = old
            end
            local state = name:match('^state%-(.+)$')
            if state and self.attrs['_onstate-'..state] then
                assert(secure or not locked)
                run(self, self.attrs['_onstate-'..state], { stateid = state, newstate = value })
            end
        end
    end
    function Frame:SetParent(parent)
        assert(not locked); self.parent = parent; parent.children = parent.children or {}; table.insert(parent.children, self)
    end
    function Frame:GetParent() return self.parent end
    function Frame:GetName() return self.name end
    function Frame:SetID(id) assert(not locked); self.id = id end
    function Frame:GetID() return self.id or 0 end
    function Frame:SetSize() assert(not locked or secure) end
    Frame.SetPoint, Frame.ClearAllPoints, Frame.SetScale = Frame.SetSize, Frame.SetSize, Frame.SetSize
    function Frame:Show() assert(not locked or secure); self.shown = true end
    function Frame:Hide() assert(not locked or secure); self.shown = false end
    function Frame:IsShown() return self.shown end
    function Frame:SetAlpha(alpha) self.alpha = alpha end
    function Frame:SetFrameLevel() assert(not locked) end
    function Frame:GetFrameLevel() return 1 end
    function Frame:EnableMouse(enabled) assert(not locked); self.mouse = enabled end
    function Frame:RegisterForClicks(...)
        assert(not locked); self.clicks = {}; for _, edge in ipairs({...}) do self.clicks[edge] = true end
    end
    function Frame:RegisterEvent(event) self.events[event] = true end
    function Frame:UnregisterEvent(event) self.events[event] = nil end
    function Frame:SetScript(name, fn) self.scripts[name] = fn end
    function Frame:SetFrameRef(name, frame) self.refs[name] = frame end
    function Frame:GetFrameRef(name) return self.refs[name] end
    function Frame:Execute(body)
        assert(not locked, 'insecure Execute in combat')
        if broken then error('early Forever nil loadstring_untainted') end
        local old = secure; secure = true; local result = run(self, body); secure = old; return result
    end
    function Frame:RunAttribute(name)
        local body=assert(self.attrs[name],name); return run(self,body)
    end
    function Frame:ChildUpdate(name, message)
        for _, child in ipairs(self.children or {}) do
            local body = child.attrs['_childupdate-'..name]
            if body then run(child, body, { message = message }) end
        end
    end
    env.CreateFrame = function(_, name, parent)
        assert(not locked)
        local frame = setmetatable({ attrs = {}, refs = {}, scripts = {}, events = {}, name = name,
            shown = true, alpha = 1 }, { __index = Frame })
        frames[#frames+1] = frame; if name then env[name] = frame end
        if parent then frame:SetParent(parent) end
        return frame
    end
    env.UIParent = env.CreateFrame('Frame', 'UIParent')
    env.NUM_ACTIONBAR_BUTTONS, env.NUM_ACTIONBAR_PAGES = 12, 6
    env.UnitClass = function() return 'Priest', 'PRIEST' end
    env.IsShiftKeyDown = function() return swap == 1 end
    env.IsControlKeyDown = function() return swap == 2 end
    env.IsAltKeyDown = function() return false end
    env.IsModifiedClick = function(key) return (key == 'SHIFT' and swap == 1) or (key == 'CTRL' and swap == 2) end
    env.GetCVarBool, env.UnitExists = function() return false end, function() return false end
    env.GetModifiedClick = function() return 'NONE' end
    env.GetCursorInfo = function() end
    env.SpellCanTargetItem, env.SpellCanTargetItemID = function() return false end, function() return false end
    env.issecretvalue = function() return false end
    env.issecure = function() return secure end
    env.securecallfunction = function(fn, ...) return fn(...) end
    env.securecall = function(fn, ...) if type(fn) == 'string' then fn = env[fn] end; if fn then return fn(...) end end
    env.strmatch, env.strlower, env.strupper = string.match, string.lower, string.upper
    env.strsplit = function(sep, value)
        local out = {}; for v in (value..sep):gmatch('(.-)'..sep) do out[#out+1] = v end; return table.unpack(out)
    end
    env.CopyTable = function(t) local out = {}; for k,v in pairs(t) do out[k]=v end; return out end
    env.GetFrameMetatable = function() return { __index = Frame } end
    env.table = setmetatable({ wipe = function(t) for k in pairs(t) do t[k] = nil end; return t end }, { __index = table })
    env.SecureCmdOptionParse = function(text)
        assert(not text:find('vehicleui') and not text:find('overridebar') and not text:find('possessbar')
            and not text:find('shapeshift'), 'unsupported Forever macro option')
        for clause in (text..';'):gmatch('(.-);') do
            clause = clause:match('^%s*(.-)%s*$')
            local cond, value = clause:match('^%[([^%]]*)%]%s*(.*)$')
            local yes = cond == 'bonusbar:5' and kind ~= 'normal'
                or cond == 'mod:shift' and swap == 1 or cond == 'mod:ctrl' and swap == 2
                or (cond and tonumber(cond:match('^bar:(%d+)$')) == normalPage)
            if (not cond and clause ~= '') or yes then return value or clause end
        end
    end
    env.GetActionInfo = function(slot) return 'spell', 1000+slot end
    env.HasAction = function(slot) return kind ~= 'normal' and slot >= 121 end
    env.UseAction = function(slot) casts[#casts+1] = slot end
    env.SpellFlyout = { Hide = function() end }
    env.C_ActionBar = { GetActionBarPage = function() return normalPage end,
        HasBonusActionBar = function() return kind ~= 'normal' end, GetBonusBarIndex = function() return 11 end,
        GetVehicleBarIndex = function() return 12 end, GetOverrideBarIndex = function() return 14 end,
        HasVehicleActionBar = function() return false end, HasOverrideActionBar = function() return false end,
        HasTempShapeshiftActionBar = function() return false end }
    env.C_PaperDollInfo = { GetInventorySlotInfo = function() return 16 end, IsRangedSlotShown = function() return false end }
    local native = '../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/'
    compile(read(native..'Blizzard_FrameXML/SecureTemplates.lua'), env)()
    compile(read(native..'Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua'), env)()
    function Frame:CalculateAction(button) return env.SecureActionButtonMixin.CalculateAction(self, button) end
    function Frame:Click(button, down)
        local edge = down and 'AnyDown' or 'AnyUp'
        if self.clicks and not self.clicks[edge] then return end
        return env.SecureActionButton_OnClick(self, button, down)
    end
    local macroRuns = 0
    env.C_Macro = { RunMacroText = function(body)
        macroRuns = macroRuns+1; assert(body == '/cast SavedProgram', 'routing macro entered normal input')
        casts[#casts+1] = 'SavedProgram'
    end }
    local function loadFlux(path) return compile(read(path), env)('_FluxUI', ns) end
    loadFlux('Core/ButtonFX/Click.lua'); loadFlux('Core/Engine/Restricted.lua')
    assert(not F.Restricted.Works(), 'v8 click policy changed')
    if broken then
        assert(not F.Restricted.PagingWorks() and not F.Cap.hasSecureBarPaging)
        return
    end
    locked=true; assert(not F.Restricted.PagingWorks(), 'probe must defer during combat'); locked=false
    assert(F.Restricted.PagingWorks() and F.Cap.hasSecureBarPaging)
    assert(not F.ButtonFX.Click.UsesWrap(), 'Forever input switched away from v8')
    loadFlux('Bars/SlotMath.lua'); loadFlux('Bars/State.lua'); loadFlux('Bars/Layout.lua'); loadFlux('Bars/Clicks.lua')
    B.NUM_NATIVE, B.NUM_COLUMNS, B.CONFIG = 12, 19, { buttonSize = 44, padding = 0, yOffset = 4 }
    B.Strip = { inner = env.CreateFrame('Frame', 'FluxInner', env.UIParent), frame = env.CreateFrame('Frame', 'FluxStrip') }
    B.hosts = {}; local all = {}
    B.ForEachHost = function(fn) for _,host in ipairs(all) do fn(host) end end
    B.Hosts = { IndexSlot = function(host, slot) host.slot = slot end }
    B.RequestLayout = function() assert(not locked, 'combat layout requested by fixture') end
    B.State.Create()
    for col=1,19 do
        B.hosts[col] = {}
        for _, row in ipairs({'main', 'sec', 'tert'}) do
            local w = env.CreateFrame('CheckButton', 'Flux'..row..col)
            B.State.Attach(B.State.HeaderFor(col,row), w,col,row)
            local host = { widget=w, column=col, row=row, bindingCommand = row == 'main' and 'ACTIONBUTTON'..col or nil }
            B.hosts[col][row] = host; all[#all+1] = host; B.Clicks.Prepare(w)
            if row == 'main' and col <= 12 then w:SetAttribute('flux-p-'..(120+col), '/cast WrongSavedControlProgram') end
        end
    end
    env.SetOverrideBindingClick = function(_,_,key,name,button) binds[key] = { env[name], button } end
    env.GetBindingKey = function(command) local n = tonumber(command:match('%d+')); if n<=12 then return 'KEY'..n end end
    env.ClearOverrideBindings = function() end
    B.Clicks.RefreshKeys()
    for _,host in ipairs(all) do
        host.widget:SetAttribute('flux-promoted', promotion)
        host.widget:SetAttribute('flux-has-sec', 1); host.widget:SetAttribute('flux-has-tert', 1)
    end
    B.ProgramFace = { SyncHost = function() end, TranslateHost = function() end }
    loadFlux('Bars/SlotProgram.lua')
    B.State.RegisterDrivers(); B.State.ForceApply(); B.Layout.ApplyVisual()
    for col=1,12 do
        assert(not B.Layout.IsColumnEmpty(col) and B.hosts[col].main.widget:IsShown(), 'empty main not reserved')
        assert(B.hosts[col].main.widget.clicks.AnyUp and not B.hosts[col].main.widget.clicks.AnyDown)
        assert(env['FluxActionStripKey'..col].clicks.AnyDown)
    end
    local function advance(nextKind, nextSwap)
        kind, swap = nextKind, nextSwap
        local old = secure; secure = true
        env.SecureStateDriverManager.scripts.OnUpdate(env.SecureStateDriverManager, 1)
        secure = old
        B.State.IndexLiveSlots()
    end
    local function press(col, key, row)
        local w = B.hosts[col][row or 'main'].widget
        local button = 'LeftButton'
        if key then w,button = table.unpack(assert(binds['KEY'..col])) end
        casts = {}; w:Click(button, true); w:Click(button, false)
        assert(#casts == 1, 'click must execute exactly once: '..#casts)
        return casts[1]
    end
    local function collectors()
        local function forbidden() error('native collector touched') end
        for _,name in ipairs({'ActionBarButtonEventsFrame','ActionBarActionEventsFrame','ActionBarButtonUpdateFrame'}) do
            env[name] = setmetatable({}, { __index = { RegisterFrame=forbidden, UnregisterFrame=forbidden,
                UnregisterEvent=forbidden, UnregisterAllEvents=forbidden, frames={} }, __newindex=forbidden })
        end
        loadFlux('Core/API/Action.lua')
        local a,b = F.Action.WithRegistrationSuppressed(function() return 1,2 end); assert(a==1 and b==2)
        F.Action.DetachFromCollectors(B.hosts[1].main.widget)
        loadFlux('Bars/Vehicle.lua')
    end
    return { B=B, env=env, advance=advance, press=press, collectors=collectors,
        lock=function() locked=true end, macros=function() return macroRuns end }
end

local checks=0
for _,normalPage in ipairs({1,2,6}) do
for promotion=0,3 do
    for held=0,2 do
        local t=boot(held,promotion,nil,normalPage)
        for col=1,12 do
            local want=v8Math.Resolve(col,'main',normalPage,held,{promoted=promotion,hasSec=true,hasTert=true})
            assert(t.press(col,false)==want and t.press(col,true)==want, 'out-of-combat v8 input mismatch')
        end
        t.collectors(); t.lock()
        for _,kind in ipairs({'normal','mindcontrol','normal','chess','normal'}) do
            for swap=0,2 do
                t.advance(kind,swap)
                local page=kind=='normal' and normalPage or 11
                assert(t.B.State.GetCurrentPage()==page)
                for col=1,12 do
                    local want=kind~='normal' and 120+col
                        or v8Math.Resolve(col,'main',normalPage,swap,{promoted=promotion,hasSec=true,hasTert=true})
                    for _,key in ipairs({false,true}) do
                        assert(t.press(col,key)==want, kind..' wrong main action'); checks=checks+1
                    end
                    for _,row in ipairs({'sec','tert'}) do
                        local mini=kind~='normal' and (row=='sec' and 60+col or 24+col)
                            or v8Math.Resolve(col,row,normalPage,swap,{promoted=promotion,hasSec=true,hasTert=true})
                        assert(t.press(col,false,row)==mini,kind..' wrong mini action'); checks=checks+1
                    end
                    assert(t.B.hosts[col].main.widget:IsShown())
                end
            end
        end
        assert(t.macros()==0,'plain native actions must not use routing macros')
    end
end
end
local t=boot(0,0)
t.B.SlotProgram.ApplyMap({[1]='/cast SavedProgram'})
t.B.State.ForceApply()
t.env.FluxActionStripHeaderMain:Execute([[ self:RunAttribute("_fluxForceApply") ]])
t.lock()
t.advance('normal',0)
local mouse,key=t.press(1,false),t.press(1,true)
assert(mouse=='SavedProgram' and key=='SavedProgram','overlay normal input: '..tostring(mouse)..' / '..tostring(key))
t.advance('mindcontrol',1); assert(t.press(1,false)==121 and t.press(1,true)==121)
t.advance('normal',0); assert(t.press(1,false)=='SavedProgram' and t.press(1,true)=='SavedProgram')
boot(0,0,true)
print('Forever control smoke passed: '..checks..' native mouse/key/mini actions; combat entry/exit, empty columns, modifiers, promotion, overlay restoration, v8 input, native collectors and failed-engine probe')
