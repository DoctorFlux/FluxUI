-- Production native-bag paint paths; desktop counts do not establish native FPS.
local root = arg[1] or "."
local file = assert(io.open(root .. "/Inventory/Restock/Junk/FluxJunkOverlay.lua"))
local source = file:read("*a")
file:close()
local checks, failures = 0, 0
local function check(ok, message)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. message) end
end
local noop = function() end

local function fixture(family, unified, alternative)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    local state = { now = 10, timers = {}, updates = {}, reads = {}, paints = {}, items = {} }
    env.GetTime = function() return state.now end
    env.wipe = function(t) for key in pairs(t) do t[key] = nil end end
    env.C_Timer = { After = function(delay, callback)
        state.timers[#state.timers + 1] = { at = state.now + delay, callback = callback }
    end }
    local function drain()
        local remaining = 100
        while #state.timers > 0 do
            remaining = remaining - 1; assert(remaining > 0, "unbounded timer fixture")
            table.sort(state.timers, function(a, b) return a.at < b.at end)
            local timer = table.remove(state.timers, 1)
            state.now = timer.at
            timer.callback()
        end
    end
    local function frame(id, shown, parent)
        local f = { shown = shown, parent = parent, id = id, scripts = {}, hooks = {}, Items = {} }
        function f:IsShown() return self.shown end
        function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        function f:GetID() return self.id end
        function f:HookScript(key, callback) self.hooks[key] = callback end
        function f:SetScript(key, callback) self.scripts[key] = callback end
        function f:RegisterEvent() end
        function f:UnregisterEvent() end
        function f:Update() state.updates[self.id] = (state.updates[self.id] or 0) + 1 end
        return f
    end
    local function texture()
        return { SetTexture = noop, SetVertexColor = noop, SetBlendMode = noop,
            SetPoint = noop, SetSize = noop, SetShown = noop, Hide = noop }
    end
    local function bag(id, shown, parent)
        local f = frame(id, shown, parent)
        local button = frame(1, true, f)
        button.bagID = id
        button.CreateTexture = texture
        f.Items[1] = button
        state.items[id] = 100 + id
        return f
    end
    env.CreateFrame = function() return frame(99, true) end
    env.hooksecurefunc = function(target, key, callback)
        assert(type(target) == "table", "fixture only expects method hooks")
        local original = target[key]
        target[key] = function(...)
            original(...)
            callback(...)
        end
    end
    env.FLUX_API = { isForever = family == "forever", HasUnifiedBankUI = function() return unified end }
    env.ContainerFrameItemButtonMixin = { UpdateJunkItem = noop }
    env.FluxUI_UsesAlternativeBagUI = function() return alternative end
    env.FluxVendorJunk = { GetDisplay = function() return { icons = true, glow = true } end,
        IsJunkForDisplay = function() return false end, RegisterListChanged = noop, RegisterVisualRefresh = noop }
    env.FluxRestock = { Inv = { Bank = { IsOpen = function() return false end,
        RegisterBankOpen = noop, IsBankContainer = function(id) return id < 0 end },
        GetContainerItemID = function(id)
            state.reads[id] = (state.reads[id] or 0) + 1
            return state.items[id]
        end, GetContainerItemInfo = function() return {} end } }
    local hiddenParent = frame(98, false)
    env.ContainerFrameCombinedBags = bag(0, true)
    env.ContainerFrame1 = bag(1, false)
    env.ContainerFrame2 = bag(2, true, hiddenParent)
    assert(load(source, "native bag overlay", "t", env))()
    if alternative then
        check(env.FluxJunkOverlay == nil, family .. " external bag UI bypasses native overlay")
        return
    end
    local overlay = env.FluxJunkOverlay
    overlay.EnsureHooks()
    overlay.RegisterSlotDecorator("FluxRespecGearSet", { Paint = function(_, id)
        state.paints[id] = state.items[id]
    end })
    for _ = 1, 3 do overlay.RepaintInferiorVisuals(); drain(); state.now = state.now + 1 end
    print(string.format("native bags %s unified=%s hidden updates=%d hidden item reads=%d visible item reads=%d",
        family, tostring(unified), (state.updates[1] or 0) + (state.updates[2] or 0),
        (state.reads[1] or 0) + (state.reads[2] or 0), state.reads[0] or 0))
    check((state.updates[1] or 0) == 0 and (state.updates[2] or 0) == 0, family .. " skips hidden native Update calls")
    check((state.reads[1] or 0) == 0 and (state.reads[2] or 0) == 0, family .. " skips hidden-parent item classification")
    check((state.reads[0] or 0) > 0 and state.paints[0] == 100, family .. " visible bags still repaint")
    local previousReads = state.reads[2] or 0
    env.ContainerFrameItemButtonMixin.UpdateJunkItem(env.ContainerFrame2.Items[1])
    check((state.reads[2] or 0) == previousReads, family .. " asynchronous native junk callback skips hidden parents")
    env.ContainerFrame1.shown = true
    hiddenParent.shown = true
    state.items[1], state.items[2] = 777, 888
    state.now = state.now + 1
    env.ContainerFrame1:Update(); env.ContainerFrame2:Update(); drain()
    check(state.paints[1] == 777 and state.paints[2] == 888, family .. " reveal paints current slots through existing Update hooks")
    hiddenParent.shown = false
    state.items[2] = 999
    state.now = state.now + 1
    overlay.RepaintInferiorVisuals(); drain()
    hiddenParent.shown = true
    -- Effective OnShow also fires when an ancestor becomes visible; Blizzard's
    -- ContainerFrame_OnShow does not itself refresh the current item paints.
    if env.ContainerFrame2.hooks.OnShow then
        env.ContainerFrame2.hooks.OnShow(env.ContainerFrame2)
    end
    drain()
    check(state.paints[2] == 999, family .. " ancestor reveal refreshes skipped slot paints")
    env.ContainerFrameCombinedBags.shown = false
    env.ContainerFrame1.shown = false
    hiddenParent.shown = false
    check(not overlay.ArePaintTargetsVisible(), family .. " hidden parents are not visible paint targets")
    state.items[2] = 1111
    overlay.RefreshProtectionContext()
    check(state.paints[2] == 999, family .. " protection context skips hidden parents")
    local combined = env.ContainerFrameCombinedBags
    combined.IsVisible, combined.Items[1].IsVisible = nil, nil
    check(not overlay.ArePaintTargetsVisible(), family .. " missing visibility API keeps hidden-frame fallback")
    local beforeFallback = state.reads[0] or 0
    combined.shown = true
    overlay.RepaintInferiorVisuals(); drain()
    check((state.reads[0] or 0) > beforeFallback, family .. " missing visibility API keeps shown-frame fallback")
    hiddenParent.shown = true
    local beforeReveal = state.reads[2] or 0
    env.ContainerFrame2.id = -1
    if env.ContainerFrame2.hooks.OnShow then
        env.ContainerFrame2.hooks.OnShow(env.ContainerFrame2)
    end
    check(#state.timers == 0 and (state.reads[2] or 0) == beforeReveal, family .. " inaccessible bank reveal does no work")
    env.ContainerFrame2.id = 2
    env.FluxVendorJunk.GetDisplay = function() return { icons = false, glow = false } end
    if env.ContainerFrame2.hooks.OnShow then
        env.ContainerFrame2.hooks.OnShow(env.ContainerFrame2)
    end
    check(#state.timers == 0 and (state.reads[2] or 0) == beforeReveal, family .. " disabled painting does no reveal work")
end

for _, config in ipairs({ {"era", false}, {"anniversary", false}, {"mists", false},
        {"retail", true}, {"forever", true} }) do
    fixture(config[1], config[2], false)
    fixture(config[1], config[2], true)
end
print(string.format("visible native bag work: %d checks, %d failures", checks, failures))
assert(failures == 0, "hidden native bag work regression")
