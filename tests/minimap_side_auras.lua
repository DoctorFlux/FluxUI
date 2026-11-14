-- Production aura placement and shared strip lifecycle. Desktop frame models
-- verify geometry/ownership only; native taint, pixels, input and FPS NOT RUN.
local function read(path)
    local f = assert(io.open(path, 'rb')); local s = f:read('*a'):gsub('\r\n', '\n'); f:close(); return s
end
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
local function near(a, b, why) check(math.abs(a - b) < .001, why .. ': ' .. tostring(a) .. ' / ' .. tostring(b)) end
local function replace(s, old, new)
    local a = assert(s:find(old, 1, true), old)
    return s:sub(1, a - 1) .. new .. s:sub(a + #old)
end
local auraSource = read(os.getenv('FLUX_MINIMAP_AURA_SOURCE') or 'Minimap/FluxBuffDebuffFrames.lua')
local extraSource = read(os.getenv('FLUX_MINIMAP_EXTRA_SOURCE') or 'Minimap/FluxMinimapButtons.lua')
local fixtureSource = read('tests/minimap_extra_layout.lua')
fixtureSource = fixtureSource:sub(1, assert(fixtureSource:find('local function physical(frame)', 1, true)) - 1)
local function model(extra, aura, client, uiScale, buffScale, debuffScale)
    local env = setmetatable({}, { __index = _G })
    env.os = setmetatable({ getenv = function(key)
        if key == 'FLUX_MINIMAP_EXTRA_SOURCE' then return '__candidate__' end
        return os.getenv(key)
    end }, { __index = os })
    local realOpen = io.open
    env.io = setmetatable({ open = function(path, mode)
        if path == '__candidate__' then return { read = function() return extra end, close = function() end } end
        return realOpen(path, mode)
    end }, { __index = io })
    local boot = assert(load(fixtureSource .. '\nreturn boot', '@strict shared strip fixture', 't', env))()
    local t = boot()
    local e = t.env
    t.editing, t.callbacks, t.auraHooks = false, {}, {}
    e.UIParent:SetScale(uiScale)
    e.FluxEditModeBusy = function() return t.editing end
    e.FluxMinimap.GetNormalWidth = function() return (client == 'era' or client == 'anniversary') and 175 or 190 end
    e.EventRegistry = { RegisterCallback = function(_, event, callback) t.callbacks[event] = callback end }
    e.hooksecurefunc = function(frame, method, callback)
        check((frame == e.BuffFrame or frame == e.DebuffFrame) and method == 'ApplySystemAnchor', 'only native layout method hooked')
        check(not t.auraHooks[frame], 'one aura layout hook per frame')
        t.auraHooks[frame] = callback
    end
    local function createAura(name, scale, legacy)
        local f = e.CreateFrame('Frame', name, e.UIParent)
        f:SetScale(scale); f:SetSize(300, 100)
        f.writes, f.nativePaints = 0, 0
        local clear, point = f.ClearAllPoints, f.SetPoint
        local function nativeClear(self)
            assert(not t.editing, 'native aura changed during Edit Mode')
            self.writes = self.writes + 1; clear(self)
        end
        local function nativePoint(self, ...)
            assert(not t.editing, 'native aura changed during Edit Mode')
            self.writes = self.writes + 1; point(self, ...)
        end
        if legacy then f.ClearAllPoints, f.SetPoint = nativeClear, nativePoint
        else
            f.ClearAllPointsBase, f.SetPointBase = nativeClear, nativePoint
            f.ClearAllPoints, f.SetPoint = function() error('EditMode widget override touched') end, function() error('EditMode widget override touched') end
        end
        f.ApplySystemAnchor = function() end
        f.OnEvent = function(self, event) if event == 'UNIT_AURA' then self.nativePaints = self.nativePaints + 1 end end
        f.events.UNIT_AURA = true
        return f
    end
    e.BuffFrame = createAura('BuffFrame', buffScale, client == 'era' or client == 'anniversary')
    e.DebuffFrame = createAura('DebuffFrame', debuffScale, client == 'era' or client == 'anniversary')
    local handlers = { e.BuffFrame.OnEvent, e.DebuffFrame.OnEvent }
    local framesBefore = #t.frames
    assert(load(aura, '@actual native aura placement', 't', e))('_FluxUI', { Flux = e.Flux })
    check(#t.frames == framesBefore + 1, 'one existing aura watcher, no replacement aura frame')
    t:event('PLAYER_LOGIN'); t:flush()
    local function position(offset, label)
        local normal = -(e.FluxMinimap:GetNormalWidth() + 10)
        for i, f in ipairs({ e.BuffFrame, e.DebuffFrame }) do
            local p, relative, rp, x, y = f:GetPoint()
            check(p == 'TOPRIGHT' and relative == e.UIParent and rp == 'TOPRIGHT', label .. ': screen anchor retained')
            near(x * f:GetScale(), normal + offset + (i == 2 and -15 or 0), label .. ': side offset converts to native scale')
            near(y * f:GetScale(), i == 1 and -10 or -155, label .. ': vertical separation retained')
            check(f:GetParent() == e.UIParent and f:IsShown() and f.events.UNIT_AURA and f.OnEvent == handlers[i], label .. ': native ownership/visibility/events retained')
        end
    end
    position(0, client .. ': disabled default')
    t.api:SetSetting('sideStart', 'top')
    t.api:SetSetting('sideEnabled', true)
    local offset = t.api:GetMinimapOffset()
    check(offset < 0, 'beside strip reserves width')
    position(offset, client .. ': immediate enable')
    t.api:SetSetting('count', 60)
    offset = t.api:GetMinimapOffset()
    position(offset, client .. ': immediate automatic column change')
    t.api:SetSetting('count', 2)
    local smaller = t.api:GetMinimapOffset()
    check(smaller > offset, 'automatic count reflow reduces aura reservation')
    position(smaller, client .. ': immediate automatic size change')
    for _, percent in ipairs({25, 200, 100}) do
        t.api:SetSetting('sideScale', percent)
        local root = e.FluxMinimapButtonsContainer
        near(-t.api:GetMinimapOffset(), root:GetWidth() * root:GetEffectiveScale()
            / e.UIParent:GetEffectiveScale(), 'aura reservation matches whole scaled grid')
        position(t.api:GetMinimapOffset(), client .. ': scaled automatic grid ' .. percent)
    end
    t.api:SetSetting('sideStart', 'below')
    position(0, client .. ': below map retains original aura dock')
    t.api:SetSetting('sideStart', 'top')
    position(smaller, client .. ': beside mode restored')
    t.api:SetSetting('sideVisibility', 'mouseover')
    position(0, client .. ': mouseover mode restores native aura dock')
    t.api:SetSetting('sideVisibility', 'always')
    position(smaller, client .. ': always shown automatically reserves aura space')
    t.api:SetSetting('sideEnabled', false)
    position(0, client .. ': immediate disable including no-layout early return')
    t.api:SetSetting('sideEnabled', true)
    t:embed(250)
    position(0, client .. ': PositionInWindow releases aura reservation')
    t.api:OnEmbedStateChanged(false)
    position(0, client .. ': inactive embedded tab remains at normal aura dock')
    -- The actual map restore changes IsEmbedded before notifying this callback.
    t.embedded = false
    t.api:OnEmbedStateChanged(false)
    position(t.api:GetMinimapOffset(), client .. ': restore callback immediately reclaims aura reservation')
    local writes = e.BuffFrame.writes + e.DebuffFrame.writes
    t.combat = true
    t.api:SetSetting('count', 120)
    e.FluxMinimap:PositionBuffFrames()
    check(e.BuffFrame.writes + e.DebuffFrame.writes == writes, 'combat settings/direct refresh leave native geometry untouched')
    for _ = 1, 60 do
        e.BuffFrame:OnEvent('UNIT_AURA'); e.DebuffFrame:OnEvent('UNIT_AURA')
    end
    check(e.BuffFrame.nativePaints == 60 and e.DebuffFrame.nativePaints == 60, 'native aura painting continues independently during combat')
    t.combat = false; t:event('PLAYER_REGEN_ENABLED'); t:flush()
    position(t.api:GetMinimapOffset(), client .. ': existing regen path applies latest reservation')
    t.editing = true; t.callbacks['EditMode.Enter']()
    writes = e.BuffFrame.writes + e.DebuffFrame.writes
    t.api:SetSetting('count', 1)
    t:event('EDIT_MODE_LAYOUT_APPLIED'); t:flush()
    check(e.BuffFrame.writes + e.DebuffFrame.writes == writes, 'active EditMode blocks all aura geometry writes')
    t.editing = false; t.callbacks['EditMode.Exit'](); t:flush()
    position(t.api:GetMinimapOffset(), client .. ': existing EditMode exit applies latest reservation')
    writes = e.BuffFrame.writes + e.DebuffFrame.writes
    t.auraHooks[e.BuffFrame](); t.auraHooks[e.DebuffFrame]()
    check(#t.timers == 1 and e.BuffFrame.writes + e.DebuffFrame.writes == writes, 'native layout hooks coalesce and defer until pass ends')
    t:flush()
    position(t.api:GetMinimapOffset(), client .. ': deferred native layout reconciliation')
end
for _, client in ipairs({ 'retail', 'forever', 'classic', 'era', 'anniversary' }) do
    for _, scales in ipairs({ {.7, .75, 1.5}, {1, 1, 1}, {1.4, 1.6, .5} }) do
        model(extraSource, auraSource, client, scales[1], scales[2], scales[3])
    end
end
-- These alterations must each fail observable geometry/lifecycle expectations.
local controls = {
    { extra = extraSource, aura = replace(auraSource, 'local x = -(width + GAP) + offset', 'local x = -(width + GAP)') },
    { extra = extraSource, aura = replace(auraSource, 'x / scale, y / scale', 'x, y') },
    { extra = extraSource, aura = replace(auraSource, 'if Blocked() then self._pending = true; return end', '-- removed native layout guard') },
}
-- Find the integration callback as a whole so removing it catches direct embed,
-- restore and disabled-layout transitions as well as ordinary option callbacks.
local callback = '    if FluxMinimap and FluxMinimap.PositionBuffFrames then FluxMinimap:PositionBuffFrames() end'
if extraSource:find(callback, 1, true) then
    controls[#controls + 1] = { extra = replace(extraSource, callback, ''), aura = auraSource }
else
    local candidate = extraSource:gsub('FluxMinimap:PositionBuffFrames%(%)', 'do end', 1)
    check(candidate ~= extraSource, 'production strip calls existing aura placement service')
    controls[#controls + 1] = { extra = candidate, aura = auraSource }
end
for i, control in ipairs(controls) do
    check(not pcall(model, control.extra, control.aura, 'retail', 1, .75, 1.5), 'harmful control rejected ' .. i)
end
print('Minimap side aura positioning: ' .. checks .. ' checks; 5 client models; 15 scale cases; ' .. #controls .. ' harmful controls PASS')
