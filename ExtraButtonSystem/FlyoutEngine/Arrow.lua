-- ExtraButtonSystem/FlyoutEngine/Arrow.lua — TGA opener arrow above unified border.
local addonName, ns = ...
local Flux = ns.Flux
local Flyout = Flux.EBS and Flux.EBS.Flyout
if not Flyout then
	return
end

local Arrow = {}
Flyout.Arrow = Arrow

local ARROW_TEX = "Interface\\Buttons\\ActionBarFlyoutButton"
local ARROW_TEX_COORDS = { 0.62500000, 0.98437500, 0.74218750, 0.82812500 }
local ARROW_SIZE_W = 23
local ARROW_SIZE_H = 11
local ARROW_OFFSET = 6
-- FluxUnifiedBorderFrame is MEDIUM ~8; FluxBorder atlas is FluxBorderFrame at parentLevel+10.
-- Parent the arrow onto the unified border so it sits above atlas art, not UIParent HIGH.
local ARROW_STRATA = "MEDIUM"
local ARROW_FRAME_LEVEL = 9 -- UIParent fallback only; below FluxWindowFrame (10)
local ARROW_ABOVE_BORDER_ART = 5
-- Default opener is WoW gold/yellow. Class color is class-teleport only.
local ARROW_YELLOW_R, ARROW_YELLOW_G, ARROW_YELLOW_B = 1, 0.82, 0

local function SqueezeX()
	if FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor then
		return FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor() or 1
	end
	return 1
end

function Arrow.ConfigureLayer(arrowFrame, anchorWidget)
	if not arrowFrame or not anchorWidget then
		return
	end
	if Flyout.InLockdown and Flyout.InLockdown() then
		return
	end
	-- Parent onto FluxUnifiedBorderFrame above FluxBorderFrame so the glyph
	-- draws over the atlas without HIGH / FULLSCREEN_DIALOG.
	local ub = _G.FluxUnifiedBorderFrame
	local borderArt = ub and ub.FluxBorderFrame
	if ub and ub.IsShown and ub:IsShown() and borderArt then
		arrowFrame:SetParent(ub)
		arrowFrame:SetFrameStrata((ub.GetFrameStrata and ub:GetFrameStrata()) or ARROW_STRATA)
		local bLevel = (borderArt.GetFrameLevel and borderArt:GetFrameLevel()) or 0
		arrowFrame:SetFrameLevel(math.min(bLevel + ARROW_ABOVE_BORDER_ART, 65535))
	else
		arrowFrame:SetParent(UIParent)
		arrowFrame:SetFrameStrata(ARROW_STRATA)
		arrowFrame:SetFrameLevel(ARROW_FRAME_LEVEL)
	end
	if arrowFrame.SetScale and anchorWidget.GetEffectiveScale and UIParent.GetEffectiveScale then
		local us = UIParent:GetEffectiveScale() or 1
		if us > 0 then
			arrowFrame:SetScale((anchorWidget:GetEffectiveScale() or us) / us)
		end
	end
end

function Arrow.Rotation(direction, isOpen)
	direction = Flyout.DirOk(direction)
	if direction == "LEFT" then
		return isOpen and 90 or 270
	end
	if direction == "RIGHT" then
		return isOpen and 270 or 90
	end
	if direction == "DOWN" then
		return isOpen and 0 or 180
	end
	return isOpen and 180 or 0
end

function Arrow.Anchor(arrow, widget, direction)
	if not arrow or not widget then
		return
	end
	-- SecureActionButton: SetSize / SetPoint are protected in combat.
	if Flyout.InLockdown() then
		return
	end
	direction = Flyout.DirOk(direction)
	local xF = SqueezeX()
	local aw = math.max(10, ARROW_SIZE_W * xF)
	arrow:SetSize(aw, ARROW_SIZE_H)
	arrow:ClearAllPoints()
	local rec = Flyout.HostOf(widget)
	local relative = (rec and rec.opts and rec.opts.anchorFrame) or widget
	local ok = pcall(function()
		if direction == "LEFT" then
			arrow:SetPoint("LEFT", relative, "LEFT", -ARROW_OFFSET, 0)
		elseif direction == "RIGHT" then
			arrow:SetPoint("RIGHT", relative, "RIGHT", ARROW_OFFSET, 0)
		elseif direction == "DOWN" then
			arrow:SetPoint("BOTTOM", relative, "BOTTOM", 0, -ARROW_OFFSET)
		else
			arrow:SetPoint("TOP", relative, "TOP", 0, ARROW_OFFSET)
		end
	end)
	if not ok then
		arrow:Hide()
	end
end

function Arrow.SetTint(arrow, r, g, b, desaturate)
	if not arrow or not arrow.texture then
		return
	end
	if desaturate and arrow.texture.SetDesaturated then
		arrow.texture:SetDesaturated(true)
	elseif arrow.texture.SetDesaturated then
		arrow.texture:SetDesaturated(false)
	end
	if r then
		arrow.texture:SetVertexColor(r, g or r, b or r, 1)
	end
end

local function ClassColorRGB()
	local _, classFilename = UnitClass and UnitClass("player")
	local c = classFilename and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename]
	if c then
		return c.r, c.g, c.b
	end
	return ARROW_YELLOW_R, ARROW_YELLOW_G, ARROW_YELLOW_B
end

local function ApplyTintFromOpts(arrow, opts)
	if not arrow then
		return
	end
	opts = opts or {}
	if opts.classColorArrow then
		local r, g, b = ClassColorRGB()
		arrow._fluxArrowTint = { r, g, b }
		arrow._fluxArrowDesaturate = true
	elseif opts.arrowTint then
		arrow._fluxArrowTint = opts.arrowTint
		arrow._fluxArrowDesaturate = opts.desaturate ~= false
	end
	Arrow.ApplyAccent(arrow)
end

function Arrow.ApplyAccent(arrow)
	if not arrow or not arrow.texture then
		return
	end
	if arrow._fluxArrowTint then
		local t = arrow._fluxArrowTint
		Arrow.SetTint(arrow, t[1], t[2], t[3], arrow._fluxArrowDesaturate)
		return
	end
	Arrow.SetTint(arrow, ARROW_YELLOW_R, ARROW_YELLOW_G, ARROW_YELLOW_B, true)
end

function Arrow.Ensure(widget, opts)
	local rec = Flyout.HostOf(widget)
	if not rec or not widget then
		return nil
	end
	if rec.arrow then
		ApplyTintFromOpts(rec.arrow, opts or rec.opts)
		return rec.arrow
	end
	if Flyout.InLockdown() then
		return rec.arrow
	end
	Flyout._overlaySeq = (Flyout._overlaySeq or 0) + 1
	local name = "FluxFlyoutArrow" .. Flyout._overlaySeq
	local arrow = CreateFrame("Button", name, widget, "SecureActionButtonTemplate")
	arrow:SetSize(ARROW_SIZE_W, ARROW_SIZE_H)
	arrow:RegisterForClicks("AnyUp")
	arrow:EnableMouse(true)
	arrow:SetFrameLevel((widget.GetFrameLevel and widget:GetFrameLevel() or 1) + 6)
	local tex = arrow:CreateTexture(nil, "OVERLAY", nil, 7)
	tex:SetTexture(ARROW_TEX)
	tex:SetAllPoints()
	tex:SetTexCoord(ARROW_TEX_COORDS[1], ARROW_TEX_COORDS[2], ARROW_TEX_COORDS[3], ARROW_TEX_COORDS[4])
	arrow.texture = tex
	arrow.host = widget
	widget.FluxFlyoutArrow = arrow
	rec.arrow = arrow
	ApplyTintFromOpts(arrow, opts or rec.opts)
	if Flyout.Secure and Flyout.Secure.HandlerOnLoad then
		Flyout.Secure.HandlerOnLoad(arrow)
	end
	local dir = Flyout.DirOk((opts and opts.direction) or (rec.opts and rec.opts.direction) or "UP")
	arrow:SetAttribute("flyoutDirection", dir)
	Arrow.ConfigureLayer(arrow, widget)
	Arrow.Anchor(arrow, widget, dir)
	if SetClampedTextureRotation then
		SetClampedTextureRotation(tex, Arrow.Rotation(dir, false))
	end
	arrow:Hide()
	arrow:SetScript("OnEnter", nil)
	arrow:SetScript("OnLeave", nil)
	return arrow
end

function Arrow.Update(widget, direction, isOpen)
	local rec = Flyout.HostOf(widget)
	local arrow = rec and rec.arrow or (widget and widget.FluxFlyoutArrow)
	if not arrow then
		return
	end
	direction = Flyout.DirOk(direction or (rec and rec.opts and rec.opts.direction) or "UP")
	Arrow.ConfigureLayer(arrow, widget)
	Arrow.Anchor(arrow, widget, direction)
	if SetClampedTextureRotation and arrow.texture then
		SetClampedTextureRotation(arrow.texture, Arrow.Rotation(direction, isOpen))
	end
end

function Arrow.SetOpen(widget, isOpen)
	local rec = Flyout.HostOf(widget)
	local dir = rec and rec.opts and rec.opts.direction or "UP"
	Arrow.Update(widget, dir, isOpen and true or false)
end

function Arrow.Show(widget)
	local rec = Flyout.HostOf(widget)
	local arrow = rec and rec.arrow
	if not arrow then
		return
	end
	if Flyout.InLockdown() then
		Flyout.Defer("flyout.arrow.vis." .. tostring(widget), function()
			Arrow.Show(widget)
		end)
		return
	end
	Arrow.Update(widget, rec.opts and rec.opts.direction, Flyout.IsOpen(widget))
	arrow:Show()
	if arrow.texture then
		arrow.texture:Show()
	end
	-- Show can reset parent/level on SecureActionButton; re-apply after.
	Arrow.ConfigureLayer(arrow, widget)
	Arrow.Anchor(arrow, widget, rec.opts and rec.opts.direction or "UP")
end

function Arrow.Hide(widget)
	local rec = Flyout.HostOf(widget)
	local arrow = rec and rec.arrow
	if not arrow then
		return
	end
	if Flyout.InLockdown() then
		Flyout.Defer("flyout.arrow.vis." .. tostring(widget), function()
			Arrow.Hide(widget)
		end)
		return
	end
	arrow:Hide()
end

function Arrow.RefreshAll()
	for widget, rec in pairs(Flyout.attached) do
		if widget and rec and rec.arrow and rec.arrow:IsShown() then
			Arrow.Update(widget, rec.opts and rec.opts.direction, Flyout.IsOpen(widget))
		end
	end
end
