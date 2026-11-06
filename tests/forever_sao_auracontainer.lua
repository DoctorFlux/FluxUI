-- Forever SAO secret auras use AuraContainer buttons, bypassing legacy show hooks.
local checks = 0
local function check(ok, why)
	checks = checks + 1
	assert(ok, why)
end

local inCombat = false
_G.InCombatLockdown = function() return inCombat end
_G.SpellActivationOverlayLABBinder = {}
_G.SpellActivationOverlayDB = { glow = { enabled = true } }
_G.C_SpellActivationOverlay = { IsSpellOverlayed = function() return false end }
_G.C_UnitAuras = { GetPlayerAuraBySpellID = function() return nil end }
_G.hooksecurefunc = function(tbl, key, hook)
	local original = assert(tbl[key])
	tbl[key] = function(...)
		original(...)
		hook(...)
	end
end

local function button()
	local b = { shown = false, scripts = {} }
	function b:HookScript(kind, fn) self.scripts[kind] = fn end
	function b:IsShown() return self.shown end
	function b:SetShown(shown)
		if self.shown == shown then return end
		self.shown = shown
		local fn = self.scripts[shown and "OnShow" or "OnHide"]
		if fn then fn(self) end
	end
	return b
end

local left, right = button(), button()
_G.SpellActivationOverlayAddon = {
	AddGlow = function() end,
	AddGlowNumber = function() end,
	RemoveGlow = function() end,
	ShowAllOverlays = function() end,
	HideOverlays = function() end,
	AuraContainer = { items = {
		missileBarrage = { spellID = 400589, auraButtons = { left, right } },
	} },
}
local handlers = {}
local Flux = {
	Client = { isForever = true },
	ButtonFX = {},
	Spell = { GetName = function(id)
		if id == 5143 then return "Arcane Missiles" end
	end },
	Events = { Register = function(event, fn) handlers[event] = fn end },
}
assert(loadfile("Core/ButtonFX/Glow.lua"))("_FluxUI", { Flux = Flux })
local glow = Flux.ButtonFX.Glow
local changes, lastReason = 0, nil
glow.OnChange(function(reason)
	changes, lastReason = changes + 1, reason
end)
glow.Start()
check(glow.Diagnostics():find("container=2/0/0", 1, true),
	"both SAO AuraContainer overlay buttons are hooked out of combat")
check(not glow.Want(5143), "inactive secure overlay keeps button dark")
inCombat = true
left:SetShown(true)
check(glow.Want(5143) and lastReason == "sao.overlay",
	"secure AuraContainer show activates matching button in combat")
local once = changes
right:SetShown(true)
check(changes == once, "second half of screen art does not duplicate activation")
left:SetShown(false)
check(glow.Want(5143), "one remaining overlay half keeps button glowing")
right:SetShown(false)
check(not glow.Want(5143) and changes == once + 1,
	"last secure overlay half clears the button in combat")
check(glow.Diagnostics():find("container=2/2/2", 1, true),
	"visibility counters record secure screen show and hide")
inCombat = false
_G.SpellActivationOverlayAddon = nil
local globalLeft, globalRight = button(), button()
local function slot(frame)
	return {
		GetCandidateFilters = function() return { includeSpellIDs = { [400589] = true } } end,
		GetAuraFrame = function() return frame end,
	}
end
_G.SpellActivationOverlayAuraContainer = {
	auraSlotManager = { auraSlots = { slot(globalLeft), slot(globalRight) } },
}
local Flux2 = {
	Client = { isForever = true },
	ButtonFX = {},
	Spell = Flux.Spell,
	Events = Flux.Events,
}
assert(loadfile("Core/ButtonFX/Glow.lua"))("_FluxUI", { Flux = Flux2 })
local publicGlow = Flux2.ButtonFX.Glow
publicGlow.Start()
check(publicGlow.Diagnostics():find("container=2/0/0", 1, true),
	"global AuraContainer slot registry works without SAO private namespace")
check(publicGlow.Diagnostics():find("registry=1/2/2", 1, true),
	"global registry diagnostics show mapped static aura slots")
inCombat = true
globalLeft:SetShown(true)
check(publicGlow.Want(5143), "global secure slot activates combat button glow")
globalRight:SetShown(true)
globalLeft:SetShown(false)
check(publicGlow.Want(5143), "global slot keeps second overlay half active")
globalRight:SetShown(false)
check(not publicGlow.Want(5143), "global slot clears after last half hides")
print("Forever SAO AuraContainer: " .. checks .. " checks passed")
