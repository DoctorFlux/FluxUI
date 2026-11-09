-- Focused Forever SAO 2.8.9 bridge and renderer regression.
local source = assert(loadfile((arg and arg[1]) or "Core/ButtonFX/Glow.lua"))
local checks = 0
local function check(value, label)
	checks = checks + 1
	assert(value, label)
end

local calls = { show = 0, hide = 0, notify = 0, snap = 0 }
local inCombat = false
local function newOverlay()
	local overlay = { shown = true, out = false }
	function overlay:IsShown() return self.shown end
	function overlay:Hide() self.shown = false end
	overlay.animOut = {
		IsPlaying = function() return overlay.out end,
		Stop = function() overlay.out = false end,
		Play = function(self)
			overlay.out = true
			if self.finished then self.finished() end
		end,
		SetScript = function(self, name, fn)
			if name == "OnFinished" then self.finished = fn end
		end,
	}
	overlay.animIn = {
		IsPlaying = function() return true end,
		Stop = function() calls.snap = calls.snap + 1 end,
		Play = function() overlay.shown = true; overlay.out = false end,
		GetScript = function() return function() end end,
	}
	return overlay
end
local lbg = {
	ShowOverlayGlow = function(widget)
		if inCombat and widget.GetSize then
			error("cannot create or parent glow on secure button in combat")
		end
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
local nativeResult = false
local secret = {}
_G.InCombatLockdown = function() return inCombat end
_G.issecretvalue = function(value) return value == secret end
_G.hooksecurefunc = function(tbl, key, hook)
	local original = assert(tbl[key])
	tbl[key] = function(...)
		original(...)
		hook(...)
	end
end
_G.C_SpellActivationOverlay = { IsSpellOverlayed = function() return nativeResult end }
local barrageAura
_G.C_UnitAuras = { GetPlayerAuraBySpellID = function(id)
	check(id == 400589, "Forever aura fallback queries Missile Barrage")
	return barrageAura
end }
_G.SpellActivationOverlayLABBinder = {}
_G.SpellActivationOverlayDB = { glow = { enabled = true } }
local sao = {
	AddGlow = function() end,
	AddGlowNumber = function() end,
	RemoveGlow = function() end,
	ShowAllOverlays = function() end,
	HideOverlays = function() end,
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
local rankReady = false
local ns = { Flux = {
	Client = { isForever = true, isPreDF = false, isAnyClassic = false },
	Events = { Register = function(event, fn) handlers[event] = fn end },
	ButtonFX = {},
	Spell = { GetName = function(id)
		if id == 5143 or (id == 5144 and rankReady) then return "Arcane Missiles" end
	end, GetTexture = function(id)
		if id == 5143 then return secret end
		if id == 1337 then return 111 end
	end },
} }
source("_FluxUI", ns)
local glow = ns.Flux.ButtonFX.Glow
glow.OnChange(function() calls.notify = calls.notify + 1 end)
glow.Start()
check(not glow.Want(1337), "inactive Forever spell stays dark")
check(not glow.Want(5143), "inactive Missile Barrage stays dark")
barrageAura = { spellId = 400589 }
check(glow.Want(5143), "Forever Missile Barrage lights Arcane Missiles")
check(not glow.Want(5144), "unknown rank waits for spell-name data")
rankReady = true
check(glow.Want(5144), "ranked Arcane Missiles also lights")
check(glow.FaceShowsSpell(12345, 5143) == nil,
	"unreadable combat spell texture is unknown, not a mismatched icon")
check(glow.FaceShowsSpell(222, 1337) == false, "known different icon still rejects a stale face")
SpellActivationOverlayDB.glow.enabled = false
check(not glow.Want(5143), "disabled SAO glow setting stays dark")
SpellActivationOverlayDB.glow.enabled = true
handlers.UNIT_AURA("UNIT_AURA", "player")
check(calls.notify > 0, "player aura change refreshes every Flux surface")
barrageAura = nil
check(not glow.Want(5143), "Missile Barrage expiration clears the glow")
inCombat = true
barrageAura = secret
sao.ShowAllOverlays({}, 400589)
check(glow.Want(5143), "SAO screen activation drives glow with restricted combat aura")
check(glow.Want(5144), "combat activation covers Arcane Missiles ranks")
local screen = { out = false }
function screen:IsShown() return true end
screen.animOut = { IsPlaying = function() return screen.out end }
sao.Frame = { overlaysInUse = { [400589] = { screen } } }
check(glow.Want(5143), "live SAO overlay confirms the combat proc")
screen.out = true
check(not glow.Want(5143), "fading SAO overlay cannot pin a stale button glow")
sao.HideOverlays({}, 400589)
check(not glow.Want(5143), "SAO combat deactivation clears the button glow")
sao.Frame = nil
barrageAura = nil
inCombat = false
nativeResult = secret
check(not glow.Want(1337), "secret native result cannot create a false glow")
handlers.SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(nil, secret)
check(not glow.Want(1337), "secret event ID cannot enter the glow set")
handlers.SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(nil, 1337)
check(glow.Want(1337), "native glow event still works with secret API result")
handlers.SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(nil, 1337)
check(not glow.Want(1337), "native hide clears a secret-backed glow")
nativeResult = false
inCombat = true
sao:AddGlowNumber(9001, 1337)
check(glow.Want(1337), "private Forever SAO AddGlowNumber reaches Flux")
check(calls.notify > 0, "SAO activation requests shared bar/EBS refresh")
inCombat = false

inCombat = true
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
inCombat = false
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
local prepared = { GetSize = function() return 36, 36 end }
glow.InstallSAO(prepared)
check(prepared._fluxSaoPrepared and prepared.__LBGoverlay and not prepared.__LBGoverlay.shown,
	"Forever LBG art is prepared and hidden before combat")
local prewarmShows = calls.show
inCombat = true
glow.Set(prepared, true)
check(glow.IsLive(prepared), "prepared Classic glow starts in combat")
glow.Set(prepared, false)
check(not glow.IsLive(prepared) and prepared.__LBGoverlay ~= nil,
	"combat hide keeps the frame ready for the next proc")
glow.Set(prepared, true)
check(glow.IsLive(prepared) and calls.show == prewarmShows,
	"second combat proc reuses the prepared frame without LBG parenting")
check(not glow.Transfer(prepared, {}), "prepared glow is never reparented in combat")
inCombat = false
sao:RemoveGlow(9001)
-- This fixture's SAO stub does not maintain its private table; the hook still
-- proves notification, while production's RemoveGlow supplies the paired state.
check(calls.notify > 1, "SAO deactivation requests shared refresh")
local modernStarts = 0
_G.C_Texture = { GetAtlasInfo = function() return {} end }
local modernLib = { ProcGlow_Start = function(widget)
	if inCombat then error("modern frame cannot be anchored in combat") end
	modernStarts = modernStarts + 1
	local frame = { shown = true, alpha = 1 }
	function frame:Show()
		if inCombat then error("secure child Show blocked in combat") end
		self.shown = true
	end
	function frame:Hide() self.shown = false end
	function frame:IsShown() return self.shown end
	function frame:SetAlpha(alpha) self.alpha = alpha end
	function frame:GetScript(which)
		if which == "OnShow" then
			return function(self) self.playing = true end
		end
	end
	frame.ProcLoopAnim = { Play = function() end, Stop = function() end }
	widget._ProcGlow = frame
end }
_G.LibStub = function(name)
	if name == "LibCustomGlow-1.0" then return modernLib end
	if name == "LibButtonGlow-1.0" then return lbg end
end
local modernWidget = { GetSize = function() return 36, 36 end }
glow.InstallSAO(modernWidget)
check(modernWidget._fluxModernGlowPrepared and modernWidget._ProcGlow.shown
	and modernWidget._ProcGlow.alpha == 0,
	"Retail flipbook is acquired and transparent before combat")
local oldClassicShows = calls.show
inCombat = true
glow.Set(modernWidget, true)
check(glow.IsLive(modernWidget) and modernWidget._ProcGlow.startAnim
	and modernWidget._ProcGlow.alpha == 1,
	"Retail proc intro appears on the secure button in combat")
glow.Set(modernWidget, false)
check(not glow.IsLive(modernWidget) and modernWidget._ProcGlow.shown
	and modernWidget._ProcGlow.alpha == 0,
	"Retail proc clears through alpha without hiding secure child")
glow.Set(modernWidget, true, true)
check(glow.IsLive(modernWidget) and not modernWidget._ProcGlow.startAnim,
	"retained Retail flipbook resumes without its intro")
check(modernStarts == 1 and calls.show == oldClassicShows,
	"combat uses the prepared Retail frame without reanchoring or Classic art")
check(not glow.Transfer(modernWidget, {}), "prepared Retail frame stays on its secure button")
check(type(glow.Diagnostics()) == "string", "combat diagnostic reads plain counters")

-- The Forever secret-aura bridge must let AuraContainer own both animation
-- edges. Flux cannot inspect the secret aura or call Show in combat.
inCombat = false
_G.C_Secrets = { GetSpellAuraSecrecy = function() return 1 end }
_G.C_AddOns = { IsAddOnLoaded = function() return true end }
local secureButton
_G.CreateFrame = function(kind, _, parent)
	if kind == "AuraContainer" then
		local box = { parent = parent }
		function box:SetAllPoints() end
		function box:EnableMouse() end
		function box:SetEditModePreviewEnabled() end
		function box:AddAuraSlot(key, filter, options)
			check(key == "missileBarrage" and filter == "HELPFUL"
				and options.candidateFilters.includeSpellIDs[400589],
				"secure slot filters the SAO Missile Barrage aura")
			secureButton = {
				SetAllPoints = function() end,
				EnableMouse = function() end,
				AddAuraShownAnimation = function(self, animation) self.animation = animation end,
			}
			options.initializeFrame(secureButton)
		end
		function box:SetUnit(unit)
			if inCombat then error("protected unit change in combat") end
			self.unit = unit
		end
		function box:SetEnabled(enabled) self.enabled = enabled end
		function box:SetShown(shown)
			if inCombat then error("protected show in combat") end
			self.shown = shown
		end
		function box:SetAlpha(alpha) self.alpha = alpha end
		function box:Hide() self.shown = false end
		return box
	end
	local alert = {
		ProcLoop = {
			Play = function(self) self.playing = true end,
			Stop = function(self) self.playing = false end,
		},
		SetSize = function() end, SetPoint = function() end,
		Show = function(self) self.shown = true end,
	}
	return alert
end
local missileWidget = { FluxButton = { SpellId = 5143 }, GetSize = function() return 36, 36 end }
glow.InstallSAO(missileWidget)
check(missileWidget._fluxSecureMissileGlow and secureButton.animation
	and missileWidget._fluxSecureMissileGlow.unit == "player"
	and missileWidget._fluxSecureMissileGlow.alpha == 1,
	"matching button gets an active secure aura slot before combat")
barrageAura = { spellId = 400589 }
check(not glow.Want(5143), "old readable fallback cannot paint a second stale glow")
inCombat = true
secureButton.animation:Play()
check(secureButton.animation.playing, "secure aura assignment starts Retail proc loop in combat")
secureButton.animation:Stop()
check(not secureButton.animation.playing, "secure aura removal stops Retail proc loop in combat")
inCombat = false
missileWidget.FluxButton.SpellId = 1337
glow.InstallSAO(missileWidget)
check(missileWidget._fluxSecureMissileGlow.unit == "player"
	and missileWidget._fluxSecureMissileGlow.alpha == 0,
	"out of combat action change masks the prepared aura slot")
missileWidget.FluxButton.SpellId = 5143
glow.InstallSAO(missileWidget)
check(missileWidget._fluxSecureMissileGlow.unit == "player"
	and missileWidget._fluxSecureMissileGlow.alpha == 1,
	"returning to Arcane Missiles restores its secure slot")
SpellActivationOverlayDB.glow.enabled = false
glow.InstallSAO(missileWidget)
check(missileWidget._fluxSecureMissileGlow.unit == "none"
	and missileWidget._fluxSecureMissileGlow.alpha == 0,
	"disabling SAO glow disables the prepared secure slot")
SpellActivationOverlayDB.glow.enabled = true
glow.InstallSAO(missileWidget)
check(missileWidget._fluxSecureMissileGlow.unit == "player"
	and missileWidget._fluxSecureMissileGlow.alpha == 1,
	"reenabling SAO glow restores the prepared secure slot")
check(glow.MayShowSecureAuraText("/cast [mod:shift] Arcane Missiles; Frostbolt"),
	"inactive modifier branch is recognized before combat")
local miniWidget = { FluxButton = { SpellId = 1337 }, GetSize = function() return 36, 36 end }
glow.EnsureSecureAura(miniWidget, true)
check(miniWidget._fluxSecureMissileGlow and miniWidget._fluxSecureMissileGlow.alpha == 0,
	"mini destination is prewarmed while it shows another spell")
local badgeWidget = { FluxButton = { SpellId = 1337 }, GetSize = function() return 36, 36 end }
glow.EnsureSecureAura(badgeWidget, true)
check(badgeWidget._fluxSecureMissileGlow and badgeWidget._fluxSecureMissileGlow.alpha == 0,
	"hidden badge destination is prewarmed before combat")
inCombat = true
glow.SyncSecureAura(missileWidget, 1337, true)
glow.SyncSecureAura(miniWidget, 5143, true)
check(missileWidget._fluxSecureMissileGlow.alpha == 0
	and miniWidget._fluxSecureMissileGlow.alpha == 1,
	"combat modifier swap moves visible Retail glow to the mini face")
glow.SyncSecureAura(miniWidget, 1337, true)
glow.SyncSecureAura(badgeWidget, 5143, true)
check(miniWidget._fluxSecureMissileGlow.alpha == 0
	and badgeWidget._fluxSecureMissileGlow.alpha == 1,
	"combat reverse badge swap moves visible glow to the badge")
glow.SyncSecureAura(badgeWidget, 5143, false)
check(badgeWidget._fluxSecureMissileGlow.alpha == 0,
	"hidden badge cannot retain the proc glow")
inCombat = false
print("Forever SAO glow: " .. checks .. " checks passed")
