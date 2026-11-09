-- Actual badge owner and cooldown adapters; opaque boundary objects are not
-- WoW's secret-value VM. Timers, rendering and secure input remain unverified.
local badgePath = arg[1] or "Bars/BadgeHost.lua"
local actionPath = arg[2] or "Core/API/Action.lua"
local spellPath = arg[3] or "Core/API/Spell.lua"
local checks = 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local function read(path)
	local f = assert(io.open(path, "rb")); local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local base = read("tests/forever_badge_combat_row_swap.lua")
base = base:sub(1, assert(base:find('assert(loadfile((arg and arg[1])', 1, true)) - 1)

local function fixture(client, spellTable)
	local f = { client = client, modern = client == "retail" or client == "forever",
		action = { startTime = 0, duration = 0, isEnabled = true, isActive = false, isOnGCD = false },
		spell = { startTime = 0, duration = 0, isEnabled = true, isActive = false, isOnGCD = false },
		reads = { action = 0, spell = 0, charges = 0, secret = 0 }, operations = 0 }
	local opaque = {}
	function f.secret(kind)
		local function bad() f.operations = f.operations + 1; error("opaque cooldown operation") end
		local value = setmetatable({}, { __lt = bad, __le = bad, __eq = bad,
			__tostring = bad, __add = bad, __sub = bad })
		opaque[value] = kind or "number"; return value
	end
	local env = setmetatable({}, { __index = _G }); env._G = env
	env.type = function(value) return opaque[value] or type(value) end
	env.tonumber = function(value) if opaque[value] then return value end return tonumber(value) end
	env.issecretvalue = function(value) f.reads.secret = f.reads.secret + 1; return opaque[value] ~= nil end
	env.canaccessvalue = function() return true end -- Does not declassify secrets.
	local function action()
		f.reads.action = f.reads.action + 1
		if f.modern then return f.action end
		local a = f.action; return a.startTime, a.duration, a.isEnabled, a.modRate
	end
	local function spell()
		f.reads.spell = f.reads.spell + 1
		if f.modern or spellTable then return f.spell end
		local a = f.spell; return a.startTime, a.duration, a.isEnabled, a.modRate
	end
	local function charges() f.reads.charges = f.reads.charges + 1; return f.charges end
	if f.modern then
		env.C_ActionBar = { GetActionCooldown = action, GetActionCharges = charges }
		env.C_Spell = { GetSpellCooldown = spell, GetSpellCharges = charges }
	else
		env.GetActionCooldown, env.GetSpellCooldown, env.GetSpellCharges = action, spell, charges
	end
	local setup = assert(load(base .. [[
return { flux=flux, bars=bars, rows=rows, badges=badges,
    setCombat=function(value) combat=value end }
]], "@badge-cooldown-fixture", "t", env))()
	f.flux, f.bars, f.rows, f.badges, f.setCombat = setup.flux, setup.bars, setup.rows, setup.badges, setup.setCombat
	f.flux.AfterLoad = function() end
	f.flux.Secrets = { IsSecretValue = env.issecretvalue, CanAccessValue = env.canaccessvalue }
	local ns = { Flux = f.flux }
	assert(loadfile(actionPath, "t", env))("_FluxUI", ns)
	assert(loadfile(spellPath, "t", env))("_FluxUI", ns)
	assert(loadfile(badgePath, "t", env))("_FluxUI", ns)
	f.host, f.env = f.bars.BadgeHost, env
	function f.install(want)
		f.host.SetSlotBadges(1, { want or { key = "cd", spellId = 5143, hiddenUnlessCd = true } })
	end
	function f.visible(row)
		local visible = f.host.GetVisibleBadgesForButton(f.rows[row or "main"].widget)
		return visible and #visible > 0 or false
	end
	return f
end

local function long(f, which, opaque)
	local cd = f[which]
	cd.startTime, cd.duration = opaque and f.secret() or 10, opaque and f.secret() or 30
	cd.isEnabled, cd.isActive, cd.isOnGCD = true, true, false
end

-- Regression first: the baseline reaches a comparison on the opaque duration.
local restricted = fixture("forever")
long(restricted, "action", true); restricted.install()
check(restricted.visible() and restricted.operations == 0, "opaque non-GCD slot cooldown keeps the badge without inspection")

for _, client in ipairs({ "retail", "forever", "era", "anniversary", "classic" }) do
	local ready = fixture(client); ready.install()
	check(not ready.visible(), client .. ": ready slot and badge spell hide")
	local gcd = fixture(client)
	gcd.action.startTime, gcd.action.duration, gcd.action.isActive, gcd.action.isOnGCD = 10, 1.5, true, true
	gcd.spell.startTime, gcd.spell.duration, gcd.spell.isActive, gcd.spell.isOnGCD = 10, 1.5, true, true
	gcd.install(); check(not gcd.visible(), client .. ": GCD alone hides")
	local slot = fixture(client); long(slot, "action"); slot.install()
	check(slot.visible(), client .. ": slot cooldown shows")
	local spell = fixture(client); long(spell, "spell"); spell.install()
	check(spell.visible(), client .. ": badge spell cooldown shows even when slot is ready")
	local strings = fixture(client)
	strings.action.startTime, strings.action.duration, strings.action.isActive = "10", "30", true
	strings.install(); check(strings.visible(), client .. ": public numeric strings retain the legacy path")
	local threshold = fixture(client)
	threshold.action.startTime, threshold.action.duration, threshold.action.isActive = 10, 1.50001, true
	threshold.install(); check(threshold.visible(), client .. ": readable legacy threshold remains above 1.5 seconds")
	local disabled = fixture(client); long(disabled, "action"); disabled.action.isEnabled = false
	disabled.install(); check(disabled.visible(), client .. ": readable timers retain the old result even with a stale disabled flag")
	local inactive = fixture(client); long(inactive, "action"); inactive.action.isActive = false
	inactive.install(); check(inactive.visible(), client .. ": readable timers retain the old result even with a stale inactive flag")
	local remaining = fixture(client)
	remaining.charges = { currentCharges = 1, maxCharges = 2, isActive = true }
	remaining.install(); check(not remaining.visible() and remaining.reads.charges == 0,
		client .. ": recharge with a usable charge retains ordinary cooldown visibility")
	local exhausted = fixture(client); long(exhausted, "action")
	exhausted.charges = { currentCharges = 0, maxCharges = 2, isActive = true }
	exhausted.install(); check(exhausted.visible() and exhausted.reads.charges == 0,
		client .. ": all-charge cooldown shows without a new charge scan")
	local unfiltered = fixture(client)
	unfiltered.install({ key = "always", spellId = 5143 })
	check(unfiltered.visible() and unfiltered.reads.action == 0 and unfiltered.reads.spell == 0,
		client .. ": badges without this option do no cooldown work")
	local absent = fixture(client); absent.flux.Action.GetCooldown, absent.flux.Spell.GetCooldown = nil, nil
	absent.install(); check(not absent.visible(), client .. ": missing cooldown APIs retain the old hidden result")
end

for _, which in ipairs({ "action", "spell" }) do
	local opaqueGcd = fixture("forever"); long(opaqueGcd, which, true); opaqueGcd[which].isOnGCD = true
	opaqueGcd.install(); check(not opaqueGcd.visible() and opaqueGcd.operations == 0, which .. ": public GCD flag excludes opaque timers")
	local opaqueReady = fixture("forever"); long(opaqueReady, which, true); opaqueReady[which].isActive = false
	opaqueReady.install(); check(not opaqueReady.visible() and opaqueReady.operations == 0, which .. ": public inactive flag excludes opaque timers")
	local opaqueDisabled = fixture("forever"); long(opaqueDisabled, which, true); opaqueDisabled[which].isEnabled = false
	opaqueDisabled.install(); check(not opaqueDisabled.visible() and opaqueDisabled.operations == 0, which .. ": disabled opaque timers do not show")
	local unknown = fixture("forever"); long(unknown, which, true)
	unknown[which].isActive, unknown[which].isOnGCD = nil, nil
	unknown.install(); check(unknown.visible() and unknown.operations == 0, which .. ": unavailable flags conservatively keep an opaque timer")
	local longGcd = fixture("forever"); long(longGcd, which); longGcd[which].isOnGCD = true
	longGcd.install(); check(longGcd.visible(), which .. ": readable long timers preserve the old cutoff despite a stale GCD flag")
end

local swapped = fixture("forever"); long(swapped, "spell", true); swapped.install()
swapped.setCombat(true); swapped.rows.main.slot, swapped.rows.sec.slot = 61, 1
swapped.host.NotifyDisplay(swapped.rows.main); swapped.host.NotifyDisplay(swapped.rows.sec)
check(not swapped.visible("main") and swapped.visible("sec") and #swapped.badges == 9,
	"secret cooldown badge follows combat main-to-mini without creating a new stack")
swapped.rows.main.slot, swapped.rows.sec.slot = 1, 61
swapped.host.NotifyDisplay(swapped.rows.sec); swapped.host.NotifyDisplay(swapped.rows.main)
check(swapped.visible("main") and not swapped.visible("sec") and swapped.operations == 0,
	"secret cooldown badge returns from mini to main")

local raw = fixture("forever")
raw.action = { startTime = raw.secret(), duration = raw.secret(), isEnabled = false,
	isActive = true, modRate = raw.secret(), isOnGCD = true, enable = true }
local a, b, enabled, active, rate, gcd = raw.flux.Action.GetCooldown(1)
check(rawequal(a, raw.action.startTime) and rawequal(b, raw.action.duration)
	and enabled == false and active == true and rawequal(rate, raw.action.modRate) and gcd == true,
	"action adapter retains its five return positions, false and opaque fields; appends GCD")
raw.spell = { startTime = raw.secret(), duration = raw.secret(), isEnabled = false,
	modRate = raw.secret(), isActive = true, isOnGCD = true }
a, b, enabled, rate, active, gcd = raw.flux.Spell.GetCooldown(5143)
check(rawequal(a, raw.spell.startTime) and rawequal(b, raw.spell.duration)
	and enabled == false and active == true and rawequal(rate, raw.spell.modRate) and gcd == true,
	"spell adapter retains its different return order and appends GCD")
local fallback = fixture("classic", true)
fallback.spell = { startTime = fallback.secret(), duration = fallback.secret(), isEnabled = false,
	modRate = fallback.secret(), isActive = true, isOnGCD = true, enable = true }
a, b, enabled, rate, active, gcd = fallback.flux.Spell.GetCooldown(5143)
check(rawequal(a, fallback.spell.startTime) and enabled == false and gcd == true,
	"legacy spell table fallback also forwards opaque fields without truth-testing")
local old = fixture("classic")
old.action = { startTime = 10, duration = 30, isEnabled = 1, modRate = 0.8 }
a, b, enabled, active, rate, gcd = old.flux.Action.GetCooldown(1)
check(a == 10 and b == 30 and enabled == 1 and active == nil and rate == 0.8 and gcd == nil,
	"legacy action tuples retain their original return positions")
local aliases = { start = 10, duration = 30, enable = 0, timeMod = 0.75, isActive = true, isOnGCD = false }
a, b, enabled, active, rate, gcd = raw.flux.Action.UnpackCooldown(aliases)
check(a == 10 and b == 30 and enabled == 0 and active == true and rate == 0.75 and gcd == false,
	"action table aliases retain legacy fields and the appended public flag")
raw.action.isEnabled, raw.action.isActive = raw.secret("boolean"), raw.secret("boolean")
a, b, enabled, active = raw.flux.Action.GetCooldown(1)
check(rawequal(enabled, raw.action.isEnabled) and rawequal(active, raw.action.isActive),
	"opaque boolean metadata passes through the adapter without selecting a fallback")
raw.action.isOnGCD = raw.secret("boolean"); raw.install()
check(raw.visible() and raw.operations == 0, "unreadable metadata with opaque timers conservatively keeps the badge")
print("Badge cooldown secrets: " .. checks .. " checks passed (desktop boundary only)")
