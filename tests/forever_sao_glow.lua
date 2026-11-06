-- Focused Forever SAO 2.8.9 bridge and renderer regression.
local source = assert(loadfile((arg and arg[1]) or "Core/ButtonFX/Glow.lua"))
local checks = 0
local function check(value, label)
	checks = checks + 1
	assert(value, label)
end

local calls = { show = 0, hide = 0, notify = 0, snap = 0 }
local function newOverlay()
	local overlay = { shown = true, out = false }
	function overlay:IsShown() return self.shown end
	overlay.animOut = { IsPlaying = function() return overlay.out end }
	overlay.animIn = {
		IsPlaying = function() return true end,
		Stop = function() calls.snap = calls.snap + 1 end,
		GetScript = function() return function() end end,
	}
	return overlay
end
local lbg = {
	ShowOverlayGlow = function(widget)
		calls.show = calls.show + 1
		widget.__LBGoverlay = widget.__LBGoverlay or newOverlay()
		widget.__LBGoverlay.out = false
	end,
	HideOverlayGlow = function(widget)
		calls.hide = calls.hide + 1
		if widget.__LBGoverlay then
			widget.__LBGoverlay.out = true
		end
	end,
}
_G.LibStub = function(name)
	if name == "LibButtonGlow-1.0" then return lbg end
end
_G.C_SpellActivationOverlay = { IsSpellOverlayed = function() return false end }
_G.SpellActivationOverlayLABBinder = {}
local sao = {
	AddGlow = function() end,
	AddGlowNumber = function() end,
	RemoveGlow = function() end,
}
_G.SpellActivationOverlayAddonFrame = {
	GetScript = function()
		local privateSAO = sao
		return function()
			if privateSAO then return end
		end
	end,
	HookScript = function() end,
}
local handlers = {}
local ns = { Flux = {
	Client = { isForever = true, isPreDF = false, isAnyClassic = false },
	Events = { Register = function(event, fn) handlers[event] = fn end },
	ButtonFX = {},
} }
source("_FluxUI", ns)
local glow = ns.Flux.ButtonFX.Glow
glow.OnChange(function() calls.notify = calls.notify + 1 end)
glow.Start()
check(not glow.Want(1337), "inactive Forever spell stays dark")
sao:AddGlowNumber(9001, 1337)
check(glow.Want(1337), "private Forever SAO AddGlowNumber reaches Flux")
check(calls.notify > 0, "SAO activation requests shared bar/EBS refresh")

for _, kind in ipairs({ "bar", "extra", "badge" }) do
	local widget = { kind = kind }
	if kind == "extra" then
		-- A pre-library template fallback must not mask the live LBG frame.
		widget._fluxProcAlert = {
			shown = true,
			IsShown = function(self) return self.shown end,
			Hide = function(self) self.shown = false end,
		}
	end
	glow.InstallSAO(widget)
	glow.Set(widget, true, false)
	check(widget.__LBGoverlay and glow.IsLive(widget), kind .. " uses SAO renderer")
	if kind == "extra" then
		check(not widget._fluxProcAlert.shown, "old empty template yields to SAO art")
	end
	check(widget._fluxForeverSaoGlow, kind .. " records LBG ownership")
	glow.Set(widget, false)
	check(widget.__LBGoverlay.out, kind .. " hides through LBG")
	glow.Set(widget, true, true)
	check(glow.IsLive(widget), kind .. " can reappear during fade out")
	check(calls.snap > 0, kind .. " skips birth when glow is already active")
end
local from, to = {}, {}
glow.Set(from, true)
check(glow.Transfer(from, to), "paged face transfers the live LBG overlay")
check(from.__LBGoverlay == nil and to.__LBGoverlay ~= nil,
	"transfer moves the overlay reference")
check(not from._fluxForeverSaoGlow and to._fluxForeverSaoGlow,
	"transfer moves LBG lifecycle ownership")
glow.Set(to, false)
check(to.__LBGoverlay.out, "transferred overlay hides through LBG")
check(calls.show == 7 and calls.hide == 4, "one show and hide per transition")
sao:RemoveGlow(9001)
-- This fixture's SAO stub does not maintain its private table; the hook still
-- proves notification, while production's RemoveGlow supplies the paired state.
check(calls.notify > 1, "SAO deactivation requests shared refresh")
print("Forever SAO glow: " .. checks .. " checks passed")
