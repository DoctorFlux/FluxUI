-- lua Core/_tmp_minimaplayoutsmoke.lua
-- Execute the real embedding/restore/position functions against strict native frames.
-- Does not simulate WoW taint; verifies that native layout methods/geometry stay intact.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local f = assert(io.open(root .. "Minimap/FluxMinimap.lua", "r"))
local source = f:read("*a"); f:close()
local function Slice(first, last)
    local start = assert(source:find(first, 1, true))
    local finish = assert(source:find(last, start + #first, true))
    return source:sub(start, finish - 1)
end
local code = Slice("function FluxMinimap:EnforcePosition()", "function FluxMinimap:PositionIndicators()")
    .. Slice("function FluxMinimap:EmbedInFrame(parentFrame)", "function FluxMinimap:IsEmbedded()")
local combat, writes = false, 0
local function NoNativeWrite() writes = writes + 1; error("native action-bar method or minimap cluster geometry changed", 2) end
local function Frame(width, height)
    local t = { width = width, height = height, shown = true, scripts = {}, point = {} }
    function t:GetSize() return self.width, self.height end
    function t:GetWidth() return self.width end
    function t:GetHeight() return self.height end
    function t:SetSize(w, h) self.width, self.height = w, h end
    function t:SetWidth(w) self.width = w end
    function t:SetHeight(h) self.height = h end
    function t:SetScale(scale) self.scale = scale end
    function t:SetParent(parent) assert(not combat); self.parent = parent end
    function t:GetParent() return self.parent end
    function t:ClearAllPoints() assert(not combat); self.point = {} end
    function t:SetPoint(...) assert(not combat); self.point = { ... } end
    function t:GetPoint() return (table.unpack or unpack)(self.point) end
    function t:Show() self.shown = true end
    function t:Hide() self.shown = false end
    function t:IsShown() return self.shown end
    function t:SetFrameStrata() end
    function t:SetFrameLevel() end
    function t:EnableMouse() end
    function t:SetMovable() end
    function t:RegisterEvent() end
    function t:SetScript(name, fn) self.scripts[name] = fn end
    return t
end
local ui, map, cluster, flux = Frame(1920, 1080), Frame(190, 190), Frame(256, 256), Frame(0, 0)
map.parent, map.point = ui, { "TOPRIGHT", ui, "TOPRIGHT", 0, -22 }
cluster.ClearAllPoints, cluster.SetAllPoints, cluster.SetSize, cluster.SetHeight = NoNativeWrite, NoNativeWrite, NoNativeWrite, NoNativeWrite
local nativeMethods = { SetScale = function() end, GetParent = function() return ui end }
local originals = {}
local env = setmetatable({
    UIParent = ui, Minimap = map, MinimapCluster = cluster, FluxMinimap = flux,
    FLUX_API = {}, CONFIG = { Size = 190, Scale = 1, Position = { "TOPRIGHT", ui, "TOPRIGHT", -25, -25 } },
    embeddedState = {}, minimapPositionQueue = {},
    HookMinimapClusterKeepHidden = function() end,
    FluxMinimap_TryRebuildMicroMenuPos3 = function() end,
    InCombatLockdown = function() return combat end,
    CreateFrame = function() return Frame(0, 0) end,
    unpack = table.unpack or unpack,
}, { __index = _G })
env._G = env
for _, name in ipairs({ "MultiBarRight", "MultiBarLeft", "MultiBarBottomRight", "MultiBarBottomLeft" }) do
    env[name] = setmetatable({}, { __index = nativeMethods, __newindex = NoNativeWrite })
    originals[name] = env[name].SetScale
end
flux.InfoBar = Frame(190, 24); flux.InfoBar.parent = ui
flux.InfoBar.point = { "BOTTOMRIGHT", map, "TOPRIGHT", 0, -2 }
flux.UpdateStyle, flux.PositionIndicators, flux.Refresh = function() end, function() end, function() end
flux.ProtectActionBarScales = NoNativeWrite -- old call sites must not survive
local chunk
if setfenv then chunk = assert(loadstring(code)); setfenv(chunk, env)
else chunk = assert(load(code, "minimap layout functions", "t", env)) end
chunk()
local function Tick(watcher, times)
    for _ = 1, times do
        local fn = watcher.scripts.OnUpdate
        if fn then fn(watcher, 0.016) end
    end
end
flux:EnforcePosition()
for _, size in ipairs({ 270, 1100, 420 }) do
    local window = Frame(900, size)
    assert(flux:EmbedInFrame(window))
    Tick(flux._embedSizeWatcher, 7)
    assert(map.parent == window and map.width == math.min(900, size - 22))
    assert(cluster:GetHeight() == 256, "embedded map size leaked into native layout")
    flux:RestoreToNormal()
    Tick(flux._restoreSizeWatcher, 10)
    assert(map.parent == ui and map.width == 190 and map.height == 190)
end
combat = true
assert(flux:EmbedInFrame(Frame(600, 800)))
flux:RestoreToNormal()
assert(#env.minimapPositionQueue == 2, "combat positioning was not deferred")
for name, original in pairs(originals) do assert(env[name].SetScale == original) end
assert(writes == 0 and cluster:GetHeight() == 256)
print("minimap layout smoke OK (embed/restore, tall windows, combat deferral, native bar methods and cluster geometry preserved)")
