-- Actual Clicks binding installation; exact modifier dispatch must not rely on
-- a modeled native bare-key fallback. No native key event/taint claim.
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local file=assert(io.open("Bars/Watch.lua","rb"))
local watchSource=file:read("*a"):gsub("\r\n","\n")
file:close()
local watchStart=assert(watchSource:find('Watch.bindingEvents = Ev.Register("UPDATE_BINDINGS"',1,true))
local watchEnd=assert(watchSource:find("-- Vehicle/override enter:",watchStart,true))
local watchBody=watchSource:sub(watchStart,watchEnd-1)
for _, wrapped in ipairs({ false, true }) do
    local native, installed, made, blocked = {}, {}, {}, false
    local e = setmetatable({ UIParent = {} }, { __index = _G }); e._G = e
    e.InCombatLockdown = function() return blocked end
    local flux = { Bars = {}, Combat = { InLockdown = e.InCombatLockdown },
        ButtonFX = { Click = { UsesWrap = function() return wrapped end } } }
    local bars = flux.Bars
    bars.NUM_COLUMNS, bars.hosts, bars.Strip = 2, {}, { frame = {} }
    local methods = {}
    function methods:GetName() return self.name end
    function methods:GetAttribute(k) return self.attrs[k] end
    function methods:SetAttribute(k, v) check(not blocked, "no protected writes in combat"); self.attrs[k] = v end
    function methods:SetParent(p) self.parent = p end
    function methods:GetParent() return self.parent end
    function methods:SetFrameRef(name, value) self.refs = self.refs or {}; self.refs[name] = value end
    function methods:GetFrameRef(name) return self.refs and self.refs[name] end
    function methods:SetID() end
    function methods:RegisterForClicks(...) self.clicks = { ... } end
    function methods:Hide() end
    function methods:SetSize() end
    function methods:EnableMouse() end
    e.CreateFrame = function(_, name, parent)
        local f = setmetatable({ name = name, parent = parent, attrs = {} }, { __index = methods })
        e[name] = f; made[#made + 1] = f; return f
    end
    for i = 1, 2 do
        bars.hosts[i] = { main = { bindingCommand = "ACTIONBUTTON" .. i,
            widget = e.CreateFrame("Button", "FluxActionStripButton" .. i) } }
    end
    bars.ForEachHost = function(fn) for i = 1, 2 do fn(bars.hosts[i].main) end end
    local firstKey, reads = "HALF", 0
    e.GetBindingKey = function(cmd)
        reads = reads + 1
        if cmd == "ACTIONBUTTON1" then return firstKey, "Q" else return "ALT-X" end
    end
    e.GetBindingAction = function(key, overrides)
        check(overrides == false, "synthetic routes inspect native exact claims")
        return native[key] or ""
    end
    local lastOwner
    e.ClearOverrideBindings = function(owner) installed = {};lastOwner=owner end
    e.SetOverrideBindingClick = function(_, priority, key, frame, button)
        check(priority == false, "bar overrides retain ordinary priority")
        installed[key] = { frame, button }
    end
    local ns = { Flux = flux }
    assert(loadfile("Bars/SlotMath.lua", "t", e))("_FluxUI", ns)
    assert(loadfile("Bars/State.lua", "t", e))("_FluxUI", ns)
    bars.State.headers = { main = e.CreateFrame("Frame", "KeyHeader") }
    bars.State.headers.main.attrs.actionpage = 1
    for i = 1, 2 do bars.State.Attach(bars.State.headers.main, bars.hosts[i].main.widget, i, "main") end
    assert(loadfile("Bars/Clicks.lua", "t", e))("_FluxUI", ns)
    check(bars.Clicks.RefreshKeys(), "keys install")
    for _, key in ipairs({ "HALF", "SHIFT-HALF", "CTRL-HALF", "Q", "SHIFT-Q", "CTRL-Q" }) do
        local target = assert(installed[key], "missing direct route " .. key)
        check(target[1] == (wrapped and "FluxActionStripButton1" or "FluxActionStripKey1"), "modified key retains column owner")
        check(target[2] == (wrapped and "KeyBind" or "LeftButton"), "modified key retains client click policy")
    end
    check(installed["ALT-HALF"] == nil and installed["CTRL-SHIFT-HALF"] == nil, "free chords keep their own owner")
    check(installed["SHIFT-ALT-X"] == nil, "already modified native key is not expanded")
    native["SHIFT-HALF"], native["CTRL-Q"] = "TOGGLECHARACTER0", "ACTIONBUTTON2"
    native["CTRL-HALF"], native["SHIFT-Q"] = "NONE", "ACTIONBUTTON1"
    bars.Clicks.InvalidateKeys(); check(bars.Clicks.RefreshKeys(), "changed native claims reconcile")
    check(installed["SHIFT-HALF"] == nil and installed["CTRL-Q"] == nil, "foreign command and another column retained")
    check(installed["CTRL-HALF"] and installed["SHIFT-Q"], "unassigned and same-column chords use bar route")
    local count = #made
    check(bars.Clicks.RefreshKeys() and #made == count, "unchanged refresh reuses proxies")
    if not wrapped then
        local keyer = e.FluxActionStripKey1
        check(keyer.attrs.action == 1 and keyer.attrs.type == "action", "new keyboard route starts with the live main bundle")
        keyer.attrs.action = nil
        check(bars.Clicks.RefreshKeys() and keyer.attrs.action == 1 and #made == count,
            "cached binding signature cannot leave a missing main action bundle")
        keyer.attrs.type1, keyer.attrs.macrotext1 = "macro", "/cast obsolete"
        bars.Clicks.InvalidateKeys(); check(bars.Clicks.RefreshKeys(), "obsolete specific selectors reconcile")
        check(keyer.attrs.type1 == nil and keyer.attrs.macrotext1 == nil and keyer.attrs.action == 1,
            "legacy selector cleanup preserves the authoritative live main bundle")
    end

    local onBindings, pending, token
    local watch = {}
    bars.Watch = watch
    bars.RequestPaint = function(value) token=value end
    flux.Combat.Defer = function(key,fn) check(key=="bars.keys","key defer uses existing token");pending=fn end
    local function RegisterWatch(available)
        flux.Events = {Register=function(event,fn)
            check(event=="UPDATE_BINDINGS","hover reuse watches binding changes")
            onBindings=available and fn or nil
            return available
        end}
        local install=assert(load("local Bars, Watch, Flux, Ev, InLockdown=...\n"..watchBody,"@actual-binding-event","t",e))
        install(bars,watch,flux,flux.Events,e.InCombatLockdown)
    end
    RegisterWatch(true)
    reads=0
    check(bars.Clicks.RefreshKeys(true) and reads==0, "pure hover uses settled keys under the live binding watcher")
    check(bars.Clicks:RefreshKeys() and reads==2, "ordinary refreshes retain native key sampling")
    firstKey="Z"
    onBindings()
    check(reads>0 and installed.Z and not installed.HALF and token=="bars.hotkey","native binding events immediately replace routes")
    reads=0
    check(bars.Clicks.RefreshKeys(true) and reads==0, "hover uses the routes installed by the binding event")

    if not wrapped then
        e.FluxActionStripKey1.attrs.action=nil
        reads=0
        check(bars.Clicks.RefreshKeys(true) and reads>0 and e.FluxActionStripKey1.attrs.action==1,
            "hover recovers a missing native proxy action")
    end
    bars.Strip.frame={}
    reads=0
    check(bars.Clicks.RefreshKeys(true) and reads>0 and lastOwner==bars.Strip.frame,
        "a replaced override owner receives the current routes even with identical keys")
    local main=bars.hosts[1].main
    local old=main.widget
    main.widget=e.CreateFrame("Button",old.name)
    for k,v in pairs(old.attrs) do main.widget.attrs[k]=v end
    reads=0
    check(bars.Clicks.RefreshKeys(true) and reads>0,"replacing a same-name host refreshes its routes")
    if not wrapped then check(e.FluxActionStripKey1:GetParent()==main.widget,"native proxy adopts the replacement host") end
    count=#made

    RegisterWatch(false)
    firstKey="G"
    reads=0
    check(bars.Clicks.RefreshKeys(true) and reads>0 and installed.G and not installed.Z,
        "clients without a binding event subscription keep live key sampling")
    RegisterWatch(true)
    blocked = true
    firstKey="H"
    reads=0
    onBindings()
    check(pending and installed.G and reads==0 and not installed.H,"combat binding changes defer safely")
    check(bars.Clicks.RefreshKeys(true) == false and #made == count, "combat does not rewrite keys")
    blocked=false
    pending()
    check(reads>0 and installed.H and not installed.G,"deferred binding refresh installs the latest keys")

    local setter=e.SetOverrideBindingClick
    local invalidate=true
    e.SetOverrideBindingClick=function(...)
        setter(...)
        if invalidate then
            invalidate=false
            bars.Clicks.InvalidateKeys()
        end
    end
    check(bars.Clicks.RefreshKeys() and not invalidate,"the fixture invalidates while installing routes")
    reads=0
    check(bars.Clicks.RefreshKeys(true) and reads>0 and installed.H,
        "a refresh invalidated during install cannot certify its routes for hover")
end
print(("Explicit bar modifier bindings: %d checks PASS across wrapped and proxy click policies"):format(checks))
