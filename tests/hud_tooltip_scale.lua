-- Exercise the real HUD owner/anchor code after a foreign hover shrinks the
-- shared tooltip. These are desktop scale/ownership checks, not native pixels.
local path = arg[1] or "Other/FluxHUDTooltip.lua"
local f = assert(io.open(path, "rb")); local source = f:read("*a"); f:close()
local checks = 0
local function check(ok, why) checks = checks + 1; assert(ok, why) end
for _, client in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do
    local env = setmetatable({}, { __index = _G }); env._G = env
    local hooks, timers, frames = {}, {}, {}
    local busy, forbidden, combat = false, false, false
    local secret = setmetatable({}, { __lt = function() error("secret scale compared") end,
        __sub = function() error("secret scale subtracted") end })
    env.issecretvalue = function(v) return rawequal(v, secret) end
    -- WoW secret numeric values keep their numeric type; make the opaque token
    -- take that path so removing the secret guard reaches trapped arithmetic.
    env.type = function(v) if rawequal(v, secret) then return "number" end; return type(v) end
    local function frame(parent, scale)
        local w = { parent = parent, scale = scale or 1, writes = 0, scripts = {} }
        function w:GetParent() return self.parent end
        function w:GetScale() return self.scale end
        function w:GetEffectiveScale() return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1) end
        function w:SetScale(v) self.scale = v; self.writes = self.writes + 1 end
        function w:IsForbidden() return forbidden end
        function w:SetOwner(owner, anchor) self.owner, self.anchor = owner, anchor end
        function w:ClearAllPoints() self.point = nil end
        function w:SetPoint(...) self.point = { ... } end
        function w:RegisterEvent() end
        function w:SetScript(k, fn) self.scripts[k] = fn end
        return w
    end
    env.UIParent = frame(nil, .64)
    env.GameTooltip = frame(env.UIParent, 1)
    if client == "live" or client == "forever" then env.GameTooltipDefaultContainer = frame(env.UIParent, .8) end
    local tip, container = env.GameTooltip, env.GameTooltipDefaultContainer
    local hud = frame(env.UIParent, .45)
    local owner = frame(env.UIParent, .5)
    env.FluxWindowFrame = { GetFrame = function() return hud end }
    env.CreateFrame = function() local w = frame(); frames[#frames + 1] = w; return w end
    env.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
    env.FluxEditModeBusy = function() return busy end
    env.InCombatLockdown = function() return combat end
    env.GameTooltip_SetDefaultAnchor = function(t, parent) t:SetOwner(parent, "ANCHOR_NONE") end
    env.hooksecurefunc = function(name, fn) hooks[name] = fn end
    local ns = {}
    assert(load(source, "@HUD-tooltip-scale", "t", env))("_FluxUI", ns)

    for _, leakedScale in ipairs({ .2, .35, .64, 1.8 }) do
        tip.scale = leakedScale
        check(ns.SetHUDTooltipOwner(tip, owner), client .. ": HUD placement remains available")
        check(math.abs(tip:GetEffectiveScale() - env.UIParent:GetEffectiveScale()) < 1e-8,
            client .. ": normal size restored after foreign tooltip scale " .. leakedScale)
        check(tip.owner == owner and tip.anchor == "ANCHOR_NONE", client .. ": real owner retained")
        check(tip.point[1] == "BOTTOMLEFT" and tip.point[2] == hud and tip.point[3] == "TOPLEFT"
            and tip.point[4] == 0 and tip.point[5] == 30, client .. ": exact HUD anchor retained")
        local writes = tip.writes
        ns.ApplyHUDTooltipPosition(tip)
        check(tip.writes == writes, client .. ": stable tooltips do not repeat scale writes")
    end
    env.TacoTipConfig = { tooltip_scale = 1.3 }
    tip.scale = .2; ns.ApplyHUDTooltipPosition(tip)
    check(tip.scale == 1.3, client .. ": explicit existing tooltip preference retained")
    env.TacoTipConfig.tooltip_scale = 1.1; ns.ApplyHUDTooltipPosition(tip)
    check(tip.scale == 1.1, client .. ": preference changes read live")
    for _, invalid in ipairs({ false, "small", 0, -1, math.huge, 0/0, secret }) do
        env.TacoTipConfig.tooltip_scale = invalid; tip.scale = .25
        ns.ApplyHUDTooltipPosition(tip)
        check(tip.scale == 1, client .. ": invalid or opaque setting cannot shrink tooltip")
    end
    env.TacoTipConfig = nil
    tip.parent = owner; tip.scale = .3; ns.ApplyHUDTooltipPosition(tip)
    check(math.abs(tip:GetEffectiveScale() - env.UIParent:GetEffectiveScale()) < 1e-8,
        client .. ": scaled parent cannot shrink HUD tooltip")
    tip.parent = env.UIParent
    env.UIParent.scale = .8; tip.scale = .3; ns.ApplyHUDTooltipPosition(tip)
    check(tip.scale == 1 and tip:GetEffectiveScale() == .8, client .. ": native UI scale retained")

    tip.scale = .2; hooks.GameTooltip_SetDefaultAnchor(tip, owner)
    check(tip.scale == 1, client .. ": unit/happiness default anchor repairs size before Show")
    tip.scale = .2; hooks.GameTooltip_SetDefaultAnchor(tip, env.UIParent)
    check(tip.scale == 1 and tip.point[5] == 30, client .. ": world default anchor repairs size and position")
    local foreign = frame(env.UIParent, .3)
    hooks.GameTooltip_SetDefaultAnchor(foreign, env.UIParent)
    check(foreign.scale == .3 and foreign.writes == 0, client .. ": unrelated tooltip scale untouched")
    if container then
        ns.ApplyHUDTooltipPosition(container)
        check(container.scale == .8 and container.writes == 0, client .. ": native Edit Mode container scale untouched")
    end
    busy = true; tip.scale = .2; local writes = tip.writes
    hooks.GameTooltip_SetDefaultAnchor(tip, env.UIParent); ns.ApplyHUDTooltipPosition(tip)
    check(tip.writes == writes and tip.scale == .2, client .. ": Edit Mode retains layout control")
    busy = false; forbidden = true
    hooks.GameTooltip_SetDefaultAnchor(tip, owner)
    check(tip.writes == writes, client .. ": forbidden tooltip has no scale writes")
    forbidden = false
    tip.scale = secret; ns.ApplyHUDTooltipPosition(tip)
    check(tip.writes == writes, client .. ": opaque current scale neither compared nor overwritten")
    tip.scale = .2; combat = true; ns.SetHUDTooltipOwner(tip, owner)
    check(tip.scale == 1, client .. ": ordinary combat tooltip restores public scale")
    tip.IsProtected = function() return true end
    tip.scale = .2; writes = tip.writes
    hooks.GameTooltip_SetDefaultAnchor(tip, owner)
    check(tip.writes == writes, client .. ": protected combat tooltip receives no scale write")
    tip.IsProtected = nil
    check(#frames == 1 and #timers == 0, client .. ": no added frame, polling or delayed correction")
end
print("hud_tooltip_scale: " .. checks .. " checks PASS across five clients; native pixels/taint NOT RUN")
