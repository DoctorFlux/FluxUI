-- Secure proc art is prepared on every possible row before a combat swap.
local checks = 0
local function check(value, label)
	checks = checks + 1
	assert(value, label)
end

local combat = false
_G.InCombatLockdown = function() return combat end
local main = { widget = {}, slot = 1, row = "main" }
local sec = { widget = {}, slot = 61, row = "sec" }
local tert = { widget = {}, slot = 25, row = "tert" }
local badge = { SpellId = 1337, _fluxBadgeSlot = 1,
	_fluxBadgeWantIndex = 1, Widget = {} }
badge.Widget.FluxButton = badge
badge.Widget.SetAlpha = function(self, alpha) self.alpha = alpha end
local badgeVisible = false
local badgeSpell = 1337
local spells = { [1] = 5143, [61] = 1337, [25] = 1337 }
local prepared = 0
local glow = {
	CanPrepareSecureAura = function() return true end,
	MayShowSecureAuraSlot = function(slot) return slot == 1 end,
	EnsureSecureAura = function(widget)
		check(not combat, "secure slot creation stays outside combat")
		if not widget.prepared then
			widget.prepared = true
			widget._fluxSecureMissileGlow = {}
			prepared = prepared + 1
		end
	end,
	SyncSecureAura = function(widget, spellID, visible)
		widget.secureVisible = widget.prepared and visible and spellID == 5143 or false
	end,
	Want = function() return false end,
	IsLive = function() return false end,
	NotifySAO = function() end,
}
local bars = {
	NUM_COLUMNS = 1,
	GetHost = function() return { main = main, sec = sec, tert = tert } end,
	State = {
		GetMainSlot = function(_, page)
			return (page == 0 or page == 1) and 1 or (page * 12 + 1)
		end,
		GetSecondarySlot = function() return 61 end,
		GetTertiarySlot = function() return 25 end,
	},
	BadgeHost = {
		GetVisibleBadgesForButton = function(widget)
			return badgeVisible and widget == main.widget and { badge } or nil
		end,
		PrepareSecureAuraForSlot = function(slot)
			check(slot == 1, "badge preparation follows the proc-capable bar slot")
			glow.EnsureSecureAura(badge.Widget)
		end,
	},
}
local flux = {
	Client = { isForever = true },
	Bars = bars,
	EBS = {},
	ButtonFX = {
		Glow = glow,
		SpellIdFromAction = function(slot) return spells[slot] end,
		SpellIdFromEBS = function(btn) return btn.SpellId end,
	},
	Identity = {
		BadgeKey = function(slot, index) return slot .. ":" .. index end,
		Get = function(key)
			if key == "1:1" then return "spell", badgeSpell end
		end,
	},
}
assert(loadfile("ExtraButtonSystem/Engine/Badge.lua"))("_FluxUI", { Flux = flux })
local badgeVisual = flux.EBS.Badge
assert(loadfile((arg and arg[1]) or "Bars/Effects.lua"))("_FluxUI", { Flux = flux })
local effects = bars.Effects
effects.SyncColumn(1)
check(prepared == 4, "main, both mini rows, and reverse badge prewarm from one slot")
check(main.widget.secureVisible and not sec.widget.secureVisible,
	"ordinary face owns the secure proc art")

combat = true
main.slot, sec.slot = 61, 1
effects.SyncColumn(1)
check(not main.widget.secureVisible and sec.widget.secureVisible,
	"modifier swap masks old face and reveals prepared mini in combat")
check(prepared == 4, "modifier swap creates no protected frame in combat")

badgeVisible = true
main.slot, sec.slot = 1, 61
spells[1] = 1337
badgeSpell = 5143 -- The reverse badge changed, but its old SpellId lags.
badgeVisual.ShowVisual(badge)
effects.SyncColumn(1)
check(not main.widget.secureVisible and not sec.widget.secureVisible
	and badge.Widget.secureVisible,
	"bar to reverse badge uses the published face despite stale SpellId")
badgeVisible = false
badgeVisual.HideVisual(badge)
spells[1] = 5143
effects.SyncColumn(1)
check(main.widget.secureVisible and not badge.Widget.secureVisible,
	"reverse badge to bar restores art on the bar and masks the badge")
print("Forever SAO face paging: " .. checks .. " checks passed")
