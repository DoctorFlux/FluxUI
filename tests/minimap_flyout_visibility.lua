-- Runs production flyout positioning/secure bodies with protected-write guards.
-- Native input dispatch, frame protection/taint, pixels and controller NOT RUN.
-- Optional first argument replaces the repository source root for comparisons.
local root = arg[1] or '.'
local function read(path)
    local f = assert(io.open(root .. '/' .. path, 'rb'))
    local s = f:read('*a'):gsub('\r\n', '\n'); f:close(); return s
end
local sources = {
    secure = read('ExtraButtonSystem/FlyoutEngine/Secure.lua'),
    popup = read('ExtraButtonSystem/FlyoutEngine/Popup.lua'),
    arrow = read('ExtraButtonSystem/FlyoutEngine/Arrow.lua'),
    layout = read('Minimap/FluxMinimapButtons.lua'),
}
local checks = 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function run(src, client)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local combat, depth, writes, wraps, blocked = false, 0, 0, 0, 0
    local frames, methods = {}, {}
    local flyout = { attached = {}, OPENER_ATTR = '_FLUXFLYOUT_OPENER', OPENER_TYPE = 'FLUXFLYOUT_OPENER' }
    local ns = { Flux = { EBS = { Flyout = flyout } } }
    local restricted = {
        Works = function() return client ~= 'forever' and client ~= 'legacy' end,
        PagingWorks = function() return client ~= 'legacy' end,
        SetSnippet = function(frame, key, body)
            if client ~= 'forever' and client ~= 'legacy' then frame:SetAttribute(key, body); return true end
            return false
        end,
    }
    ns.Flux.Restricted = restricted
    e.InCombatLockdown = function() return combat end
    flyout.InLockdown = e.InCombatLockdown
    flyout.HostOf = function(host) return flyout.attached[host] end
    flyout.DirOk = function(dir) return dir or 'UP' end
    flyout.DirPoints = function() return 'BOTTOM', 'TOP', 0, 2 end
    flyout.EnsureDummy = function() return e.UIParent end
    local function legal()
        assert(not combat or depth > 0, client .. ': insecure protected write in combat')
        writes = writes + 1
    end
    local function execute(header, frame, body)
        local env = setmetatable({ self = frame, control = header, button = 'LeftButton', down = false }, { __index = e })
        depth = depth + 1
        assert(load(body, '@production-secure-body', 't', env))()
        depth = depth - 1
    end
    local function event(frame, name)
        for _, w in ipairs(frame.wraps[name] or {}) do execute(w.header, frame, w.body) end
        local fn = frame.scripts[name]
        if fn then
            local previous = depth; depth = 0; fn(frame); depth = previous
        end
    end
    local function shown(frame, value)
        legal()
        local was = {}
        for _, f in ipairs(frames) do was[f] = f:IsVisible() end
        frame.shown = value
        for _, f in ipairs(frames) do
            if was[f] and not f:IsVisible() then event(f, 'OnHide') end
        end
    end
    function methods:GetParent() return self.parent end
    function methods:SetParent(parent) legal(); self.parent = parent end
    function methods:IsShown() return self.shown end
    function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function methods:Show() shown(self, true) end
    function methods:Hide() shown(self, false) end
    function methods:GetName() return self.name end
    function methods:GetFrameLevel() return self.level end
    function methods:SetFrameLevel(v) legal(); self.level = v end
    function methods:GetFrameStrata() return self.strata end
    function methods:SetFrameStrata(v) legal(); self.strata = v end
    function methods:SetScale(v) legal(); self.scale = v end
    function methods:SetSize(w, h) legal(); self.width, self.height = w, h end
    function methods:GetEffectiveScale() return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1) end
    function methods:ClearAllPoints() legal(); self.point = nil end
    function methods:SetPoint(...) legal(); self.point = { ... } end
    function methods:SetToplevel() legal() end
    function methods:GetAttribute(k) return self.attrs[k] end
    function methods:SetAttribute(k, v) legal(); self.attrs[k] = v end
    function methods:GetFrameRef(k) return self.refs[k] end
    function methods:SetFrameRef(k, frame) legal(); self.refs[k] = frame end
    function methods:SetScript(k, fn) self.scripts[k] = fn end
    function methods:SetBindingClick(_, key) assert(depth > 0); self.binds[key] = true end
    function methods:ClearBindings()
        if combat and depth == 0 then blocked = blocked + 1; error('insecure Escape release') end
        self.binds = {}; self.cleared = self.cleared + 1
    end
    function methods:WrapScript(frame, name, body)
        legal(); wraps = wraps + 1
        local list = frame.wraps[name] or {}; frame.wraps[name] = list
        list[#list + 1] = { header = self, body = body }
    end
    local function frame(name, parent, scale)
        local f = setmetatable({ name = name, parent = parent, scale = scale or 1, level = 25,
            strata = 'MEDIUM', shown = true, attrs = {}, refs = {}, scripts = {}, wraps = {}, binds = {}, cleared = 0 }, { __index = methods })
        frames[#frames + 1] = f; return f
    end
    e.UIParent = frame('UIParent', nil, 1.25)
    e.FluxUnifiedBorderFrame = frame('FluxUnifiedBorderFrame', e.UIParent)
    e.FluxUnifiedBorderFrame.FluxBorderFrame = frame('Border', e.FluxUnifiedBorderFrame)
    e.SecureHandler_OnLoad = function() end
    local function loadfile(body, name) return assert(load(body, '@' .. name, 't', e))('_FluxUI', ns) end
    loadfile(src.secure, 'FlyoutEngine/Secure.lua')
    loadfile(src.arrow, 'FlyoutEngine/Arrow.lua')
    local place = assert(src.popup:match('(function Popup.Place%(host%).-)\nfunction Popup.Layout'))
    local onHide = assert(src.popup:match('popup:SetScript%("OnHide", (function%(self%).-)\n\tend%)')) .. '\nend'
    e.Popup, e.Flyout = {}, flyout
    e.HideRestockEdit = function() assert(not combat, 'combat attempted to hide protected edit child') end
    loadfile(place, 'FlyoutEngine/Popup.Place')
    local hide = assert(load('return ' .. onHide, '@FlyoutEngine/Popup.OnHide', 't', e))()
    flyout.Arrow.SetOpen = function(host) flyout.Arrow.ConfigureLayer(flyout.attached[host].arrow, host) end
    local owner = frame('VisibilityRoot', e.UIParent)
    local slot = frame('Slot', owner, 0.8)
    local host = frame('Button', slot, 0.6)
    local popup = frame('Popup', e.UIParent)
    popup:Hide(); popup.host, popup.kids = host, { {} }; popup:SetScript('OnHide', hide)
    local arrow = frame('Arrow', e.UIParent)
    local opts = { visibilityParent = slot, direction = 'UP' }
    flyout.attached[host] = { popup = popup, arrow = arrow, opts = opts }
    e.Popup.Place(host)
    flyout.Arrow.ConfigureLayer(arrow, host)
    flyout.Secure.InstallOpener(arrow, popup, host)
    check(popup:GetParent() == slot and arrow:GetParent() == slot, client .. ': full flyout tree follows slot')
    check(math.abs(popup:GetEffectiveScale() - host:GetEffectiveScale()) < 0.00001, client .. ': popup parent-relative scale')
    check(math.abs(arrow:GetEffectiveScale() - host:GetEffectiveScale()) < 0.00001, client .. ': arrow parent-relative scale')
    check(arrow:GetFrameRef('visibilityParent') == slot, client .. ': secure opener keeps visibility owner')
    local initialWraps = wraps
    for _ = 1, 8 do e.Popup.Place(host); flyout.Secure.InstallOpener(arrow, popup, host) end
    check(wraps == initialWraps, client .. ': no repeated hide wrappers')
    if client == 'legacy' then
        check(wraps == 0, 'broken closures install no secure wrapper')
        return
    end
    check(wraps == 1, client .. ': one popup-header hide wrapper')
    -- Execute the real strip layout while the existing popup is closed. Its
    -- next open may happen in combat, when Popup.Place cannot repair scale.
    flyout.PlacePopup = e.Popup.Place
    flyout.IsOpen = function(widget) return flyout.attached[widget].popup:IsShown() end
    local layout = assert(src.layout:match('(function M:LayoutSlots%(%).-)\nfunction M:RefreshAppearanceAccent'))
    local layoutMethod = assert(load([[
local M, containerFrame, visibilityFrame, buttonWidgets, layoutMode = ...
local InCombat = InCombatLockdown
local Engine = function() return {Flyout = Flyout} end
local NativeSize = function() return 44 end
local SideGeometry = function() return 1, 1, 13.2, 500, 500, 1 end
local LayoutIndices = function() return {1} end
local UIUnits = function() return 800 end
local CONFIG = {ContainerPadding = 4}
]] .. layout .. '\nreturn M.LayoutSlots', '@actual strip closed-popup sizing', 't', e))(
        { GetSetting = function() return 1 end }, owner, owner, {{ Widget = host, SlotFrame = slot }}, 'side')
    layoutMethod({ GetSetting = function() return 1 end })
    check(not popup:IsShown(), client .. ': resizing strip keeps closed popup closed')
    check(math.abs(popup:GetEffectiveScale() - host:GetEffectiveScale()) < 0.00001,
        client .. ': actual strip layout prepares closed popup scale')
    combat = true
    execute(arrow, arrow, flyout.Secure.OPENER_SCRIPT)
    check(math.abs(popup:GetEffectiveScale() - host:GetEffectiveScale()) < 0.00001,
        client .. ': closed-resized popup opens at current scale during combat')
    combat = false
    check(popup:IsVisible() and popup:GetParent() == slot, client .. ': actual opener cannot escape owner')
    check(popup.binds.ESCAPE, client .. ': open popup captures Escape')
    local before = writes
    combat = true; depth = depth + 1; owner:Hide(); depth = depth - 1
    check(not popup:IsVisible() and not arrow:IsVisible() and not host:IsVisible(), client .. ': inherited combat hide removes all hit areas')
    check(not popup:IsShown() and not next(popup.binds), client .. ': secure owner hide closes popup and releases Escape')
    check(blocked == 0, client .. ': callback attempted no blocked binding write')
    execute(arrow, arrow, flyout.Secure.OPENER_SCRIPT)
    check(not popup:IsShown() and not next(popup.binds), client .. ': hidden opener cannot reopen')
    e.Popup.Place(host); flyout.Arrow.ConfigureLayer(arrow, host); flyout.Secure.InstallOpener(arrow, popup, host)
    check(writes == before + 2, client .. ': no insecure combat layout writes')
    combat = false; owner:Show()
    check(not popup:IsShown() and arrow:IsVisible(), client .. ': combat exit retains closed popup')
    execute(arrow, arrow, flyout.Secure.OPENER_SCRIPT)
    slot:Hide()
    check(not popup:IsShown() and not next(popup.binds), client .. ': removed slot closes and releases popup')
    slot:Show()
    check(not popup:IsShown(), client .. ': restored slot stays closed')
    local newSlot = frame('NewSlot', owner, 0.7)
    opts.visibilityParent = newSlot
    e.Popup.Place(host); flyout.Secure.InstallOpener(arrow, popup, host)
    execute(arrow, arrow, flyout.Secure.OPENER_SCRIPT)
    slot:Hide()
    check(popup:IsShown(), client .. ': retired visibility owner is inert')
    newSlot:Hide()
    check(not popup:IsShown() and not next(popup.binds), client .. ': new owner closes popup')
    opts.visibilityParent = nil
    e.Popup.Place(host); flyout.Arrow.ConfigureLayer(arrow, host); flyout.Secure.InstallOpener(arrow, popup, host)
    check(popup:GetParent() == e.UIParent and arrow:GetParent() == e.FluxUnifiedBorderFrame, client .. ': ordinary host parenting preserved')
    execute(arrow, arrow, flyout.Secure.OPENER_SCRIPT)
    check(popup:GetParent() == e.UIParent and popup:IsVisible(), client .. ': ordinary secure open preserved')
    check(math.abs(popup:GetEffectiveScale() - host:GetEffectiveScale()) < 0.00001, client .. ': ordinary popup scale preserved')
end
for _, client in ipairs({ 'retail', 'forever', 'classic', 'legacy' }) do run(sources, client) end
local mutants = {
    { key = 'secure', from = 'popup:SetParent(visibilityParent or uiParent)', to = 'popup:SetParent(uiParent)' },
    { key = 'secure', from = 'control:ClearBindings()', to = '-- removed binding release' },
    { key = 'secure', from = 'control:Hide()', to = '-- removed popup close' },
    { key = 'popup', from = 'popup:SetParent(parent)', to = 'popup:SetParent(UIParent)' },
    { key = 'arrow', from = 'arrowFrame:SetParent(visibilityParent)', to = 'arrowFrame:SetParent(UIParent)' },
    { key = 'popup', from = 'local us = parent:GetEffectiveScale() or 1', to = 'local us = UIParent:GetEffectiveScale() or 1' },
    { key = 'popup', from = 'if self.ClearBindings and not (self._fluxVisibilityParent and Flyout.InLockdown()) then', to = 'if self.ClearBindings then' },
    { key = 'popup', from = 'if self.kids and not (self._fluxVisibilityParent and Flyout.InLockdown()) then', to = 'if self.kids then' },
    { key = 'layout', from = 'if flyout and flyout.PlacePopup then flyout.PlacePopup(widget) end', to = 'if flyout and flyout.PlacePopup and flyout.IsOpen(widget) then flyout.PlacePopup(widget) end' },
}
for i, mutant in ipairs(mutants) do
    local src = { secure = sources.secure, popup = sources.popup, arrow = sources.arrow, layout = sources.layout }
    local count; src[mutant.key], count = src[mutant.key]:gsub(mutant.from:gsub('([^%w])', '%%%1'), mutant.to, 1)
    check(count == 1, 'mutation anchor ' .. i)
    local ok = pcall(run, src, 'retail')
    check(not ok, 'harmful control rejected ' .. i)
end
print('PASS minimap flyout visibility: ' .. checks .. ' checks; 4 client models; ' .. #mutants .. ' harmful controls')
