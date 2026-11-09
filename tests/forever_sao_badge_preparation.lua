-- A reverse badge need not name the bar's proc spell in its saved action.
local checks = 0
local function check(ok, label)
	checks = checks + 1
	assert(ok, label)
end

local combat = false
local prepared = 0
local badges = {}
_G.HasAction = function() return false end
local rows = {
	main = { widget = {}, slot = 1, row = "main" },
	sec = { widget = {}, slot = 61, row = "sec" },
	tert = { widget = {}, slot = 25, row = "tert" },
}
local glow = {
	CanPrepareSecureAura = function() return true end,
	IsSecureAuraSpell = function(id) return id == 5143 end,
	MayShowSecureAuraText = function() return false end,
	EnsureSecureAura = function(widget)
		check(not combat, "badge secure frame is prepared outside combat")
		if not widget._fluxSecureMissileGlow then
			widget._fluxSecureMissileGlow = {}
			prepared = prepared + 1
		end
	end,
}
local badgeAPI = {
	New = function()
		local badge = { Widget = {} }
		badges[#badges + 1] = badge
		return badge
	end,
	Layout = function(badge, host)
		badge.Widget._fluxBadgeHost = host
		badge.SlotFrame = {
			clip = true,
			SetClipsChildren = function(self, clip) self.clip = clip end,
		}
	end,
	HideVisual = function(badge)
		badge.Widget._fluxBadgeCombatVisHidden = true
	end,
}
local bars = {
	NUM_COLUMNS = 1,
	GetHost = function() return rows end,
	State = {
		GetSecondarySlot = function() return 61 end,
		GetTertiarySlot = function() return 25 end,
		GetMainSlot = function(_, page)
			return (page == 0 or page == 1) and 1 or page * 12 + 1
		end,
	},
}
local flux = {
	Bars = bars,
	Combat = { InLockdown = function() return combat end },
	ButtonFX = { Glow = glow },
	EBS = { Badge = badgeAPI },
}
assert(loadfile((arg and arg[1]) or "Bars/BadgeHost.lua"))("_FluxUI", { Flux = flux })
local host = bars.BadgeHost
host.SetSlotBadges(1, { { spellId = 1337, key = "unrelated badge" } })
check(prepared == 0, "unrelated saved badge does not prewarm on its own")
host.PrepareSecureAuraForSlot(1)
check(prepared == 9, "proc bar slot prepares all badge positions on all three rows")
check(#badges == 9, "three reusable badges exist for each row")
for i = 1, #badges do
	check(badges[i].SlotFrame.clip == false,
		"prepared badge proc border can extend beyond its icon")
end
for _, row in pairs(rows) do
	local set = host.GetVisibleBadgesForButton(row.widget)
	check(set == nil, "hidden badge stays out of visible-face list")
end
combat = true
host.PrepareSecureAuraForSlot(1)
check(prepared == 9, "combat does not create another secure badge frame")
print("Forever SAO badge preparation: " .. checks .. " checks passed")
