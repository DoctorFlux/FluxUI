-- ExtraButtonSystem/Engine/Badge.lua — visual-only corner widget (no click, no dual-split)
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS

local Badge = _G.FluxBadgeButton or {}
_G.FluxBadgeButton = Badge
EBS.Badge = Badge

-- Three tiles fill the host edge. 0.33 + 1px gap rounded up past the button
-- (15*3+2 > 44) and stacking the native-44 widget by visual px overlaps
-- neighbors (same Stance/EBS SlotFrame packing).
Badge.CORNER_FRACTION = 1 / 3
Badge.CORNER_STACK_GAP = 0
Badge.DEFAULT_ALPHA = 0.75
-- On-screen item/charge/reagent digits vs minirow count size.
Badge.COUNT_FONT_SCALE = 0.75

function Badge.StackCount()
	local n = tonumber(_G.FluxBindingMaxCornerBadges)
		or (Flux.Bars and Flux.Bars.BadgeHost and Flux.Bars.BadgeHost.MAX_BADGES)
		or 3
	if n < 1 then
		n = 1
	end
	return n
end

local pendingLevels = {}

local function InLockdown()
	return InCombatLockdown and InCombatLockdown()
end

-- Overlay fill is cooldown+1, interrupt cooldown+2, reticle host+2,
-- glow host+5, assisted rotation host+6, text overlay host+8.
-- Badges must sit above that whole host VFX band (SetFrameLevel is OOC-only).
local CD_VFX_PAD = 3
local HOST_VFX_PAD = 10

local function HostCooldownLevel(host)
	local base = (host and host.GetFrameLevel and host:GetFrameLevel()) or 0
	local cdLevel = base
	local function consider(cd)
		if cd and cd.GetFrameLevel then
			local lv = cd:GetFrameLevel()
			if type(lv) == "number" and lv > cdLevel then
				cdLevel = lv
			end
		end
	end
	if host then
		consider(host.cooldown)
		consider(host.chargeCooldown)
		consider(host.lossOfControlCooldown)
		local hostName = host.GetName and host:GetName()
		if hostName then
			consider(_G[hostName .. "Cooldown"])
		end
	end
	return cdLevel
end

local function HostVfxCeiling(host)
	local base = (host and host.GetFrameLevel and host:GetFrameLevel()) or 0
	local top = math.max(HostCooldownLevel(host) + CD_VFX_PAD, base + HOST_VFX_PAD)
	local function consider(frame)
		if frame and frame.GetFrameLevel then
			local ok, lv = pcall(frame.GetFrameLevel, frame)
			if ok and type(lv) == "number" and lv >= top then
				top = lv + 1
			end
		end
	end
	if host then
		consider(host.SpellCastAnimFrame)
		consider(host.InterruptDisplay)
		consider(host.TargetReticleAnimFrame)
		consider(host.overlay)
		consider(host.__LBGoverlay)
		consider(host._fluxProcAlert)
		consider(host._ProcGlow)
		consider(host.SpellActivationAlert)
		consider(host.TextOverlayContainer)
		local cf = host.SpellCastAnimFrame
		if cf then
			consider(cf.EndBurst)
		end
	end
	return top
end

--- Item / charge / reagent digits are 25% smaller than minirow count on screen.
--- Badge widgets are native 44 with SetScale(corner); minis are 44 at 0.5.
function Badge.SyncCountFont(badge)
	local fs = badge and badge.WCount
	if not fs or not fs.SetFont then
		return
	end
	if not (NumberFontNormal and NumberFontNormal.GetFont) then
		return
	end
	local font, _, flags = NumberFontNormal:GetFont()
	if not font then
		return
	end
	local Hosts = Flux.Bars and Flux.Bars.Hosts
	local miniPx = Hosts and Hosts.MiniCountFontSize and Hosts.MiniCountFontSize()
		or math.floor(((Flux.Client and Flux.Client.isPostDF) and 19 or 16) * 1.6)
	local miniScale = (Hosts and Hosts.MINI_WIDGET_SCALE) or 0.5
	local widget = badge.Widget
	local badgeScale = badge.ButtonScale
		or (widget and widget.GetScale and widget:GetScale())
		or Badge.CORNER_FRACTION
	if type(badgeScale) ~= "number" or badgeScale <= 0 then
		badgeScale = Badge.CORNER_FRACTION
	end
	local host = badge._fluxBadgeHost
	local hostScale = 1
	if host and host.GetScale then
		local ok, sc = pcall(host.GetScale, host)
		if ok and type(sc) == "number" and sc > 0 then
			hostScale = sc
		end
	end
	local effective = badgeScale * hostScale
	if effective <= 0 then
		effective = Badge.CORNER_FRACTION
	end
	local shrink = Badge.COUNT_FONT_SCALE or 0.75
	local size = math.max(10, math.min(96, math.floor(miniPx * miniScale * shrink / effective + 0.5)))
	if fs._fluxCountFontPx == size then
		return
	end
	fs._fluxCountFontPx = size
	pcall(fs.SetFont, fs, font, size, flags or "OUTLINE")
end

function Badge.SyncFrameLevel(badge, stackIndex)
	if not badge or not badge.Widget then
		return
	end
	local idx = tonumber(stackIndex) or badge._fluxBadgeIndex or 1
	if idx < 1 then
		idx = 1
	end
	if InLockdown() then
		pendingLevels[badge] = idx
		if Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("ebs.badge.level", function()
				local copy = pendingLevels
				pendingLevels = {}
				for b, i in pairs(copy) do
					Badge.SyncFrameLevel(b, i)
				end
			end)
		end
		return
	end
	pendingLevels[badge] = nil
	local host = badge._fluxBadgeHost
	local level = HostVfxCeiling(host) + idx
	local slot = badge.SlotFrame
	if slot and slot.SetFrameLevel then
		pcall(slot.SetFrameLevel, slot, level)
	end
	pcall(badge.Widget.SetFrameLevel, badge.Widget, level + 1)
end

local function NativeSize()
	local Bars = Flux.Bars
	return (Bars and Bars.CONFIG and Bars.CONFIG.buttonSize) or 44
end

-- Extra Buttons pack a visual SlotFrame and SetScale the native 44px widget
-- inside it. Anchoring the 44px widget on visual-size steps overlaps neighbors.
local function EnsureSlot(badge, host)
	local slot = badge.SlotFrame
	if slot then
		if host and slot.SetParent then
			pcall(slot.SetParent, slot, host)
		end
		return slot
	end
	if InLockdown() then
		return nil
	end
	slot = CreateFrame("Frame", nil, host)
	if slot.EnableMouse then
		pcall(slot.EnableMouse, slot, false)
	end
	badge.SlotFrame = slot
	return slot
end

local function SuppressBadgeChrome(badge)
	if not badge then
		return
	end
	if badge.WEmptyBG then
		badge.WEmptyBG:Hide()
	end
	if badge.WNormalTexture then
		badge.WNormalTexture:SetAlpha(0)
	end
	if badge.WBorder then
		badge.WBorder:Hide()
	end
	local widget = badge.Widget
	if not widget then
		return
	end
	local tex = widget.GetNormalTexture and widget:GetNormalTexture()
	if tex and tex.SetAlpha then
		tex:SetAlpha(0)
	end
	if widget.SlotBackground then
		widget.SlotBackground:Hide()
	end
	if widget.SlotArt then
		widget.SlotArt:Hide()
	end
end

function Badge.Layout(badge, host, stackIndex)
	if not badge or not badge.Widget or not host then
		return
	end
	if InLockdown() then
		return
	end
	badge._fluxBadgeHost = host
	badge._fluxBadgeIndex = tonumber(stackIndex) or 1
	local widget = badge.Widget
	widget._fluxBadgeHost = host
	local native = NativeSize()
	local hw = host.GetWidth and host:GetWidth() or native
	local hh = host.GetHeight and host:GetHeight() or hw
	if not hw or hw <= 0 then
		hw = native
	end
	if not hh or hh <= 0 then
		hh = native
	end
	local n = Badge.StackCount()
	local gapY = Badge.CORNER_STACK_GAP or 0
	-- Keep gap:width ratio on a squeezed host (44*xF x 44).
	local gapX = gapY
	if hh > 0 then
		gapX = gapY * (hw / hh)
	end
	local visualW = (hw - (n - 1) * gapX) / n
	local visualH = (hh - (n - 1) * gapY) / n
	if visualW < 8 then
		visualW = 8
	end
	if visualH < 8 then
		visualH = 8
	end
	-- Native height 44; face width follows host xF so Binding corner badges
	-- match the squeezed action-bar slot (same as HUD extras).
	local faceW = native
	if visualH > 0 then
		faceW = native * (visualW / visualH)
	end
	widget:SetSize(faceW, native)
	local scale = visualH / native
	if widget.SetScale then
		widget:SetScale(scale)
	end
	badge.ButtonScale = scale
	local y = -((badge._fluxBadgeIndex - 1) * (visualH + gapY))
	local slot = EnsureSlot(badge, host)
	if slot then
		slot:SetSize(visualW, visualH)
		slot:ClearAllPoints()
		slot:SetPoint("TOPLEFT", host, "TOPLEFT", 0, y)
		widget:SetParent(slot)
		widget:ClearAllPoints()
		widget:SetPoint("CENTER", slot, "CENTER", 0, 0)
		slot:Show()
	else
		widget:SetParent(host)
		widget:ClearAllPoints()
		widget:SetPoint("TOPLEFT", host, "TOPLEFT", 0, y)
	end
	SuppressBadgeChrome(badge)
	if slot and slot.SetClipsChildren then
		pcall(slot.SetClipsChildren, slot, true)
	end
	Badge.SyncFrameLevel(badge, badge._fluxBadgeIndex)
	Badge.SyncCountFont(badge)
end

function Badge.ShowVisual(badge)
	if not badge or not badge.Widget then
		return
	end
	local widget = badge.Widget
	local wasParked = widget._fluxBadgeCombatVisHidden
	widget._fluxBadgeCombatVisHidden = nil
	widget:SetAlpha(badge._fluxBadgeAlpha or Badge.DEFAULT_ALPHA)
	-- Paint sweeps skip an alpha-0 badge, so a returning one is stale.
	if wasParked and EBS.Paint and EBS.Paint.RequestShown then
		EBS.Paint.RequestShown(badge)
	end
	-- Extra CheckButtons are protected in combat. Alpha-only when locked;
	-- Show() is create-path / OOC repair only.
	if not InLockdown() then
		if not widget.IsShown or not widget:IsShown() then
			widget:Show()
		end
		Badge.SyncFrameLevel(badge, badge._fluxBadgeIndex)
	end
end

function Badge.HideVisual(badge)
	if not badge or not badge.Widget then
		return
	end
	local widget = badge.Widget
	widget:SetAlpha(0)
	widget._fluxBadgeCombatVisHidden = true
	widget._fluxPaintChecked = false
	if widget.SetChecked then
		widget._fluxCheckedFromPaint = true
		widget._fluxCheckedApplied = false
		pcall(widget.SetChecked, widget, false)
		widget._fluxCheckedFromPaint = nil
	end
	-- Do not hide the Extra CheckButton — protected in combat.
end

function Badge.ApplyVisualSpellTexture(badge, spellId)
	if not badge then
		return
	end
	local tex
	if Flux.Spell and Flux.Spell.GetIcon then
		tex = Flux.Spell.GetIcon(spellId)
	end
	if badge.WIcon then
		if tex then
			badge.WIcon:SetTexture(tex)
			badge.WIcon:SetTexCoord(0, 1, 0, 1)
			badge.WIcon:Show()
		else
			badge.WIcon:SetTexture(nil)
			badge.WIcon:Hide()
		end
	end
	if badge.WEmptyBG then
		badge.WEmptyBG:Hide()
	end
end

function Badge.Clear(badge)
	if not badge then
		return
	end
	if badge.ClearAction then
		badge:ClearAction()
	end
	if badge.WIcon then
		badge.WIcon:SetTexture(nil)
		badge.WIcon:Hide()
	end
	Badge.HideVisual(badge)
end

function Badge.New(parent, config)
	config = config or {}
	config.badgeMode = true
	config.kind = "badge"
	config.showBorder = false
	config.tooltip = false
	config.macroText = false
	-- Native 44 height + SetScale. Layout squeezes width to the host xF;
	-- do not SetSize to the corner px (SpellFX fill / ring are authored for 44).
	config.size = NativeSize()
	local btn = FluxBtn and FluxBtn.Create and FluxBtn.Create(parent, config)
	if not btn then
		return nil
	end
	btn._fluxBadgeAlpha = Badge.DEFAULT_ALPHA
	btn.Widget:EnableMouse(false)
	btn.Widget:SetAlpha(Badge.DEFAULT_ALPHA)
	if btn.WCount then
		btn.WCount:Show()
		btn.WCount:SetText("")
	end
	if btn.WHotKey then
		btn.WHotKey:Hide()
	end
	if btn.WName then
		btn.WName:Hide()
	end
	Badge.SyncCountFont(btn)
	SuppressBadgeChrome(btn)
	local G = Flux.ButtonFX and Flux.ButtonFX.Glow
	if G and btn.Widget and G.NotifySAO then
		G.NotifySAO(btn.Widget)
	end
	btn.Layout = function(self, host, stackIndex)
		Badge.Layout(self, host, stackIndex)
	end
	btn.ShowVisual = function(self)
		Badge.ShowVisual(self)
	end
	btn.HideVisual = function(self)
		Badge.HideVisual(self)
	end
	btn.ApplyVisualSpellTexture = function(self, spellId)
		Badge.ApplyVisualSpellTexture(self, spellId)
	end
	btn.Clear = function(self)
		Badge.Clear(self)
	end
	return btn
end
