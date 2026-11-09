-- An action slot's badge must paint on a row that was dormant before combat.
local checks = 0
local function check(ok, label)
	checks = checks + 1
	assert(ok, label)
end
local combat = false
_G.HasAction = function() return true end
local rows = {
	main = { slot = 1, row = "main", widget = {} },
	sec = { slot = 61, row = "sec", widget = {} },
	tert = { slot = 25, row = "tert", widget = {} },
}
for _, host in pairs(rows) do
	host.widget._fluxHost = host
end
local badges = {}
local badgeAPI = {
	New = function()
		local widget = {
			SetAlpha = function(self, alpha) self.alpha = alpha end,
			GetAlpha = function(self) return self.alpha or 0 end,
		}
		local badge = { Widget = widget }
		function badge:SetAction(kind, id)
			check(not combat, "SetAction stays outside combat")
			self.ActionType, self.ActionValue = kind, id
			self.SpellId = kind == "spell" and id or nil
			self.ItemId = kind == "item" and id or nil
		end
		badges[#badges + 1] = badge
		return badge
	end,
	Layout = function(badge, host)
		badge.Widget._fluxBadgeHost = host
	end,
	ShowVisual = function(badge)
		badge.Widget._fluxBadgeCombatVisHidden = nil
		badge.Widget:SetAlpha(0.75)
	end,
	HideVisual = function(badge)
		badge.Widget._fluxBadgeCombatVisHidden = true
		badge.Widget:SetAlpha(0)
	end,
	ApplyVisualSpellTexture = function(badge, id)
		badge.Widget.icon = id
	end,
}
local paint = {
	UpdateIcon = function(badge)
		badge.Widget.icon = badge.ActionType == "spell" and badge.SpellId or nil
	end,
	UpdateCount = function(badge)
		badge.Widget.count = badge.ActionType and "ready" or nil
	end,
	UpdateCooldown = function(badge)
		badge.Widget.cooldown = badge.ActionType and "ready" or nil
	end,
	ClearCache = function() end,
}
local bars = {
	NUM_COLUMNS = 1,
	GetHost = function() return rows end,
	Hosts = { LiveSlot = function(host) return host.slot end },
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
	EBS = { Badge = badgeAPI, Paint = paint },
}
assert(loadfile((arg and arg[1]) or "Bars/BadgeHost.lua"))("_FluxUI", { Flux = flux })
local host = bars.BadgeHost
host.SetSlotBadges(1, { { key = "arcane", spellId = 5143 } })
check(#badges == 9, "all three row badge stacks are prepared")
local mainBadge = host.GetVisibleBadgesForButton(rows.main.widget)[1]
check(mainBadge.Widget.icon == 5143, "main row badge paints before combat")

combat = true
rows.main.slot, rows.sec.slot = 61, 1
host.NotifyDisplay(rows.main)
host.NotifyDisplay(rows.sec)
local mini = host.GetVisibleBadgesForButton(rows.sec.widget)
check(mini and mini[1].Widget.icon == 5143,
	"dormant mini badge paints its spell icon during combat")
check(mini[1].Widget.count == "ready" and mini[1].Widget.cooldown == "ready",
	"dormant mini badge paints its count and cooldown")
check(mainBadge.Widget.alpha == 0, "previous main badge is hidden")

rows.main.slot, rows.sec.slot = 1, 61
host.NotifyDisplay(rows.sec)
host.NotifyDisplay(rows.main)
check(host.GetVisibleBadgesForButton(rows.main.widget)[1].Widget.icon == 5143,
	"badge icon returns to main row during combat")
print("Forever badge combat row swap: " .. checks .. " checks passed")
