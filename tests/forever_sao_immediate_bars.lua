-- A Forever SAO callback must settle bars in combat without waiting for Timer.Defer.
local checks = 0
local function check(ok, why)
	checks = checks + 1
	assert(ok, why)
end

local inCombat, changed = false, nil
local deferred = {}
_G.InCombatLockdown = function() return inCombat end
local Flux = {
	Client = { isForever = true },
	ButtonFX = { Glow = {
		Start = function() end,
		OnChange = function(fn) changed = fn end,
	} },
	Timer = { Defer = function(fn) deferred[#deferred + 1] = fn end },
	Events = { Register = function() end },
	Bars = { NUM_COLUMNS = 2, GetHost = function() end },
}
assert(loadfile("Bars/Effects.lua"))("_FluxUI", { Flux = Flux })
local effects = Flux.Bars.Effects
effects.Start()
check(type(changed) == "function", "bar effects subscribes to proc state")
check(#deferred == 1, "normal startup glow pass stays batched")
deferred[1]()
deferred = {}
inCombat = true
local before = effects.GlowDiagnostics()
changed("sao.overlay")
local after = effects.GlowDiagnostics()
check(after ~= before and after:find("bars=1/", 1, true),
	"screen activation settles bars on the callback")
check(#deferred == 0, "screen activation does not wait for Timer.Defer")
changed("sao.glow")
check(effects.GlowDiagnostics():find("bars=2/", 1, true),
	"all SAO button proc signals settle on the callback")
changed("native.glow")
check(effects.GlowDiagnostics():find("bars=3/", 1, true),
	"native button proc signals also settle on the callback")
changed()
check(#deferred == 1, "ordinary refresh keeps the existing cadence")
print("Forever immediate bar glow: " .. checks .. " checks passed")
