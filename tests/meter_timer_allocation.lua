-- Actual complete skin, reusing its existing explicit native ownership mocks.
local source = arg[1] or "Battlezonemap/FluxMeterSkin.lua"
local baseline = arg[2] == "--baseline"
local checks, failures = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local function read(path)
    local f = assert(io.open(path, "rb")); local text = f:read("*a"); f:close(); return text
end
local fixture = read("tests/native_meter_skin.lua")
local stop = assert(fixture:find("\nlocal h = boot(true)", 1, true))
local env = setmetatable({ arg = { source } }, { __index = _G }); env._G = env
local loader = fixture:sub(1, stop - 1) .. "\nreturn boot"
local boot
if setfenv then local f = assert(loadstring(loader)); setfenv(f, env); boot = f()
else boot = assert(load(loader, "@existing-native-meter-mocks", "t", env))() end
local h = boot(true)
local work = { visible = 0, top = 0, left = 0, scale = 0, alpha = 0, text = 0 }
local function visibleWindow(kind, top, left, scale)
    local window = h.window(kind)
    window.visible, window.top, window.left, window.scale = true, top, left, scale
    function window:IsVisible() work.visible = work.visible + 1; return self.visible end
    function window:GetTop() work.top = work.top + 1; if self.failTop then error("transient top failure") end; return self.top end
    function window:GetLeft() work.left = work.left + 1; return self.left end
    function window:GetEffectiveScale() work.scale = work.scale + 1; return self.scale end
    local font = window.timerFont
    if font then
        local setAlpha = font.SetAlpha
        function font:SetAlpha(alpha) work.alpha = work.alpha + 1; setAlpha(self, alpha) end
    end
    return window
end
local first = visibleWindow("session", 500, 100, 1)
local second = visibleWindow("session", 500, 300, 1)
first.timerFont.alpha, second.timerFont.alpha = .37, .82
h.skin:ApplyToWindow(first, 1); h.skin:ApplyToWindow(second, 1)
local owned = visibleWindow("source", 500, 0, 1)
owned.Title = h.font()
function owned.Title:SetText(value) self.text = value end
function owned.Title:GetStringWidth() return 40 end
function owned:GetWidth() return 200 end
function owned:CreateFontString()
    local font = h.font(); self.clock = font
    function font:SetText(value) work.text = work.text + 1; self.text = value end
    local setAlpha = font.SetAlpha
    function font:SetAlpha(alpha)
        work.alpha = work.alpha + 1; setAlpha(self, alpha)
        if self.reenter then local callback = self.reenter; self.reenter = nil; callback() end
    end
    return font
end
h.skin:ApplyToOwnedPane(owned, "Threat", 1, true)
local function emit(window, payload)
    for _, callback in ipairs(h.nativeHooks[window.timerFont].SetText) do callback(window.timerFont, payload) end
end
local function sync() h.skin:SyncNativeTimer() end
local function only(which, alpha, label)
    check(first.timerFont:GetAlpha() == (which == first and alpha or 0)
        and second.timerFont:GetAlpha() == (which == second and alpha or 0)
        and owned.clock:GetAlpha() == (which == owned and alpha or 0), label)
end
emit(first, "[0:12] "); emit(second, "[9:99] "); sync()
only(owned, .37, "highest leftmost owned timer uses selected native donor")
check(owned.clock.text == "[0:12] ", "native text forwarded without competing donor overwrite")
local opaque = setmetatable({ opaque = true }, {
    __tostring = function() error("opaque text stringified") end,
    __concat = function() error("opaque text concatenated") end,
    __lt = function() error("opaque text compared") end,
})
emit(first, opaque); sync()
check(rawequal(owned.clock.text, opaque), "opaque native timer payload reaches owned sink unchanged")
owned.top = 400; sync(); only(first, .37, "native timer wins when owned pane moves lower")
owned.top, owned.scale = 1200, .5; sync(); only(owned, .37, "physical coordinates include effective scale")
first.top, first.left, first.scale = 600, 0, 1; sync(); only(first, .37, "exact position ties use original registration order")
first.visible = false; sync(); only(owned, .82, "hidden native donor immediately yields to next visible native")
check(owned.clock.text == "[9:99] ", "donor text follows visibility election")
second.visible = false; h.skin:SetOwnedTimerText(owned, "[0:03] "); sync()
only(owned, 1, "owned fallback uses full alpha with no visible native donor")
check(owned.clock.text == "[0:03] ", "fallback text preserved separately")
owned.visible = false; sync(); only(nil, 0, "all hidden panes clear timer election")
owned.visible = true; first.visible = true; first.top, first.left, first.scale = 500, 100, 1
owned.top, owned.left, owned.scale = 500, 0, 1
first.failTop = true
local ok = pcall(sync); check(not ok, "getter errors keep original propagation policy")
first.failTop = nil; sync(); only(owned, .37, "next synchronization recovers after getter error")
h.combat = true; emit(first, opaque); sync()
check(rawequal(owned.clock.text, opaque), "combat synchronization preserves opaque forwarding")
h.combat = false
first.visible = false
owned.clock.reenter = function() h.skin:SetOwnedTimerText(owned, "[0:04] "); sync() end
sync(); only(owned, 1, "reentrant owned paint keeps independent election locals")
check(owned.clock.text == "[0:04] ", "reentrant fallback update remains current")
first.visible, second.visible = true, true; emit(first, "[0:20] "); sync()
for key in pairs(work) do work[key] = 0 end
collectgarbage("collect"); collectgarbage("stop"); local memory = collectgarbage("count")
for _ = 1, 10000 do sync() end
local allocated = collectgarbage("count") - memory; collectgarbage("restart")
check(work.visible == 30000 and work.top == 30000 and work.left == 30000 and work.scale == 30000,
    "allocation change retains all fresh visibility and physical geometry reads")
check(work.alpha == 30000 and work.text == 10000, "all native/owned timer setters retained")
check(owned.clock.text == "[0:20] ", "settled election forwards current donor text")
if not baseline then check(allocated < 32, "settled timer election avoids per-call capture allocation") end
print(("SAMPLE syncs=10000 panes=3 visible=%d top=%d left=%d scale=%d alpha=%d text=%d uncollectedHeapKB=%.3f"):format(
    work.visible, work.top, work.left, work.scale, work.alpha, work.text, allocated))
h.skin:ReleaseWindow(first); sync()
check(owned.clock:GetAlpha() == .82 and second.timerFont:GetAlpha() == 0 and first.timerFont:GetAlpha() == .37,
    "retired native window restores its alpha and leaves the active election")
h.skin:ReleaseWindow(second); sync()
check(owned.clock:GetAlpha() == 1 and second.timerFont:GetAlpha() == .82, "last native retirement restores owned fallback")
check(owned.clock.text == "[0:04] ", "retirement preserves latest fallback text")
h.skin:ReleaseWindow(owned)
check(owned.clock:GetAlpha() == 0 and owned.clock.text == "", "owned release resets original display lifecycle")
print(("meter timer allocation: %d checks, %d failures"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
