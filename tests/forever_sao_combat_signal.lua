-- Installed SAO calls global ShowOverlay from a cached private method. The
-- low-level signal must work even when its private namespace is unavailable.
local source = assert(loadfile((arg and arg[1]) or "Core/ButtonFX/Glow.lua"))
local checks = 0
local function check(ok, why)
	checks = checks + 1
	assert(ok, why)
end
local secret = {}
_G.issecretvalue = function(value) return value == secret end
_G.InCombatLockdown = function() return true end
_G.SpellActivationOverlayLABBinder = {}
_G.SpellActivationOverlayAddonFrame = nil
_G.SpellActivationOverlayDB = { glow = { enabled = true } }
_G.C_SpellActivationOverlay = { IsSpellOverlayed = function() return false end }
_G.C_UnitAuras = { GetPlayerAuraBySpellID = function() return secret end }
_G.SpellActivationOverlay_ShowOverlay = function() end
_G.SpellActivationOverlayTexture_TerminateOverlay = function() end
_G.hooksecurefunc = function(tbl, key, hook)
	local original = assert(tbl[key])
	tbl[key] = function(...)
		original(...)
		hook(...)
	end
end

local handlers, changes, reason, timers = {}, 0, nil, {}
local Flux = {
	Client = { isForever = true },
	ButtonFX = {},
	Spell = { GetName = function(id)
		if id == 5143 or id == 5144 then return "Arcane Missiles" end
	end },
	Events = {
		Register = function(event, fn) handlers[event] = fn end,
		RegisterUnit = function() return false end,
	},
	Timer = { After = function(_, fn) timers[#timers + 1] = fn end },
}
source("_FluxUI", { Flux = Flux })
local glow = Flux.ButtonFX.Glow
glow.OnChange(function(why) changes = changes + 1; reason = why end)
glow.Start()
check(type(handlers.UNIT_AURA) == "function",
	"failed unit-event registration falls back to normal event bus")
check(not glow.Want(5143), "restricted aura cannot invent a button glow")
SpellActivationOverlay_ShowOverlay({}, 400589)
check(glow.Want(5143), "SAO screen show lights Arcane Missiles during combat")
check(changes == 1, "SAO screen show wakes the button refresh")
check(reason == "sao.overlay", "screen show requests same-callback button paint")
SpellActivationOverlayTexture_TerminateOverlay({ spellID = 400589 })
check(not glow.Want(5143), "SAO screen termination clears the button glow")
check(changes == 2, "SAO screen termination wakes the button refresh")
check(reason == "sao.overlay", "screen hide requests same-callback button clear")
_G.SpellActivationOverlayAddonFrame = { overlaysInUse = {} }
handlers.UNIT_AURA("UNIT_AURA", "player")
check(#timers == 1, "player aura queues one next-frame SAO screen check")
local screen = { IsShown = function() return true end,
	animOut = { IsPlaying = function() return false end } }
SpellActivationOverlayAddonFrame.overlaysInUse[400589] = { screen }
timers[1]()
check(glow.Want(5143), "global SAO screen frame drives combat glow without hooks")
check(changes == 3 and reason == "sao.overlay",
	"next-frame SAO screen activation paints the button")
screen.animOut.IsPlaying = function() return true end
handlers.UNIT_AURA("UNIT_AURA", "player")
check(not glow.Want(5143), "screen fade clears the button on player aura change")
check(changes == 4, "screen fade wakes the button clear")
SpellActivationOverlayAddonFrame.overlaysInUse[400589] = nil
handlers.SPELL_ACTIVATION_OVERLAY_SHOW("SPELL_ACTIVATION_OVERLAY_SHOW", 400589)
check(glow.Want(5143), "native screen event lights Arcane Missiles without SAO frame list")
check(changes == 5 and reason == "sao.overlay",
	"native screen activation paints the button on its callback")
handlers.SPELL_ACTIVATION_OVERLAY_HIDE("SPELL_ACTIVATION_OVERLAY_HIDE", 400589)
check(not glow.Want(5143), "native screen hide clears the button")
handlers.SPELL_ACTIVATION_OVERLAY_SHOW("SPELL_ACTIVATION_OVERLAY_SHOW", 5143)
check(glow.Want(5143), "native screen event may identify the target spell")
handlers.SPELL_ACTIVATION_OVERLAY_HIDE("SPELL_ACTIVATION_OVERLAY_HIDE", nil)
check(not glow.Want(5143), "nil native hide clears the mapped screen proc")
handlers.SPELL_ACTIVATION_OVERLAY_SHOW("SPELL_ACTIVATION_OVERLAY_SHOW", 5144)
check(glow.Want(5143), "native screen event may identify a ranked target spell")
handlers.SPELL_ACTIVATION_OVERLAY_HIDE("SPELL_ACTIVATION_OVERLAY_HIDE", 5144)
check(not glow.Want(5143), "ranked native hide clears the mapped proc")
print("Forever SAO combat signal: " .. checks .. " checks passed")
