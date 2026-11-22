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
-- Keep the secure opener on its existing input and visibility layer.
local ARROW_STRATA = "MEDIUM"
local ARROW_FRAME_LEVEL = 9 -- UIParent fallback only; below FluxWindowFrame (10)
local ARROW_ABOVE_BORDER_ART = 5
-- Default opener is WoW gold/yellow. Class color is class-teleport only.
local ARROW_YELLOW_R, ARROW_YELLOW_G, ARROW_YELLOW_B = 1, 0.82, 0

local artOwners = setmetatable({}, { __mode = "k" })
local function SetArtLayer(frame, owner)
	local strata, level = owner:GetFrameStrata(), owner:GetFrameLevel()
	if issecretvalue and (issecretvalue(strata) or issecretvalue(level)) then return end
	local junctions = FluxBorder and FluxBorder.Junctions
	if junctions and junctions.GetArrowBorderLevel then
		level = junctions:GetArrowBorderLevel(owner, strata, level)
	end
	-- Keep the host's stratum and use the first level above its own chrome.
	level = math.min(level + 1, 65535)
	if frame:GetFrameStrata() ~= strata then frame:SetFrameStrata(strata) end
	if frame:GetFrameLevel() ~= level then frame:SetFrameLevel(level) end
end

function Arrow.RefreshArtLayers()
	if Flyout.InLockdown() then return end
	for frame, owner in pairs(artOwners) do SetArtLayer(frame, owner) end
end

local function CreateArtHost(owner)
	local frame = CreateFrame("Frame", nil, owner)
	frame:SetAllPoints(owner)
	frame:EnableMouse(false)
	return frame
end

function Arrow.LayerNative(widget)
	if Flyout.InLockdown() then return end
	local container = widget.FlyoutArrowContainer
	if container then
		artOwners[container] = widget
		SetArtLayer(container, widget)
	end
	local texture = widget.Arrow or widget.FlyoutArrow
	if not texture or not texture.SetParent then return end
	local art = widget._fluxNativeFlyoutHost
	if not art then
		art = CreateArtHost(widget)
		widget._fluxNativeFlyoutHost = art
		artOwners[art] = widget
	end
	if texture:GetParent() ~= art then texture:SetParent(art) end
	SetArtLayer(art, widget)
end

local function SqueezeX()
	if FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor then
		return FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor() or 1
	end
	return 1
end

local function LayerMatches(arrow, parent, strata, level)
	local actualParent, actualStrata, actualLevel = arrow:GetParent(), arrow:GetFrameStrata(), arrow:GetFrameLevel()
	if issecretvalue and (issecretvalue(actualParent) or issecretvalue(actualStrata) or issecretvalue(actualLevel)
		or issecretvalue(parent) or issecretvalue(strata) or issecretvalue(level)) then return false end
	return rawequal(actualParent, parent) and actualStrata == strata and actualLevel == level
end

function Arrow.ConfigureLayer(arrowFrame, anchorWidget, reuseLayout)
	if not arrowFrame or not anchorWidget then
		return
	end
	if Flyout.InLockdown and Flyout.InLockdown() then
		return
	end
	-- Keep visibility and input with the existing opener parent. The glyph
	-- has its own passive layer.
	local ub = _G.FluxUnifiedBorderFrame
	local borderArt = ub and ub.FluxBorderFrame
	local rec = Flyout.HostOf(anchorWidget)
	local visibilityParent = rec and rec.opts and rec.opts.visibilityParent
	local parent, strata, level = UIParent, ARROW_STRATA, ARROW_FRAME_LEVEL
	if visibilityParent then
		parent = visibilityParent
		strata = (anchorWidget.GetFrameStrata and anchorWidget:GetFrameStrata()) or ARROW_STRATA
		level = math.min((anchorWidget:GetFrameLevel() or 1) + 6, 65535)
	elseif ub and ub.IsShown and ub:IsShown() and borderArt then
		parent = ub
		strata = (ub.GetFrameStrata and ub:GetFrameStrata()) or ARROW_STRATA
		local bLevel = (borderArt.GetFrameLevel and borderArt:GetFrameLevel()) or 0
		level = math.min(bLevel + ARROW_ABOVE_BORDER_ART, 65535)
	end

	-- Relative anchors follow the strip as it moves. Keep a settled layer
	-- during that refresh, but repair missing or changed native values.
	local ok, matches
	if reuseLayout then ok, matches = pcall(LayerMatches, arrowFrame, parent, strata, level) end
	if not (ok and matches) then
		arrowFrame:SetParent(parent)
		arrowFrame:SetFrameStrata(strata)
		arrowFrame:SetFrameLevel(level)
	end
	if arrowFrame._fluxArrowArt then SetArtLayer(arrowFrame._fluxArrowArt, anchorWidget) end
	local scaleParent = visibilityParent or UIParent
	if arrowFrame.SetScale and anchorWidget.GetEffectiveScale and scaleParent.GetEffectiveScale then
		local us = scaleParent:GetEffectiveScale() or 1
		if us > 0 then
			local scale = (anchorWidget:GetEffectiveScale() or us) / us
			if reuseLayout and arrowFrame.GetScale then
				local read, current = pcall(arrowFrame.GetScale, arrowFrame)
				if read and not (issecretvalue and (issecretvalue(current) or issecretvalue(scale))) and current == scale then return end
			end
			arrowFrame:SetScale(scale)
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

local function ArrowSizeMatches(arrow, width)
	local w, h = arrow:GetSize()
	if issecretvalue and (issecretvalue(w) or issecretvalue(h)) then return false end
	return w == width and h == ARROW_SIZE_H
end

local function ArrowPointMatches(arrow, point, relative, x, y)
	local count = arrow:GetNumPoints()
	if (issecretvalue and issecretvalue(count)) or count ~= 1 then return false end
	local p, frame, rp, ox, oy = arrow:GetPoint(1)
	if issecretvalue and (issecretvalue(p) or issecretvalue(frame) or issecretvalue(rp)
		or issecretvalue(ox) or issecretvalue(oy)) then return false end
	return p == point and rawequal(frame, relative) and rp == point and ox == x and oy == y
end

local function SetArrowPoint(arrow, point, relative, x, y)
	arrow:SetPoint(point, relative, point, x, y)
end

function Arrow.Anchor(arrow, widget, direction, reuseLayout)
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
	local sizeOK, sameSize
	if reuseLayout and arrow.GetSize then sizeOK, sameSize = pcall(ArrowSizeMatches, arrow, aw) end
	if not (sizeOK and sameSize) then arrow:SetSize(aw, ARROW_SIZE_H) end
	local rec = Flyout.HostOf(widget)
	local relative = (rec and rec.opts and rec.opts.anchorFrame) or widget
	local point, x, y = "TOP", 0, ARROW_OFFSET
	if direction == "LEFT" then point, x, y = "LEFT", -ARROW_OFFSET, 0
	elseif direction == "RIGHT" then point, x, y = "RIGHT", ARROW_OFFSET, 0
	elseif direction == "DOWN" then point, y = "BOTTOM", -ARROW_OFFSET end
	-- The native point already follows a moved button or slot. Rebind it
	-- only when the live anchor changed or could not be read on this client.
	if reuseLayout and arrow.GetNumPoints and arrow.GetPoint then
		local ok, matches = pcall(ArrowPointMatches, arrow, point, relative, x, y)
		if ok and matches then return end
	end
	arrow:ClearAllPoints()
	local ok = pcall(SetArrowPoint, arrow, point, relative, x, y)
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
	local art = CreateArtHost(arrow)
	arrow._fluxArrowArt = art
	artOwners[art] = widget
	local tex = art:CreateTexture(nil, "OVERLAY", nil, 7)
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

function Arrow.Update(widget, direction, isOpen, reuseLayout)
	local rec = Flyout.HostOf(widget)
	local arrow = rec and rec.arrow or (widget and widget.FluxFlyoutArrow)
	local container = widget and widget.FlyoutArrowContainer
	if widget and (widget._fluxNativeFlyoutHost or (container and artOwners[container])) then
		Arrow.LayerNative(widget)
	end
	if not arrow then
		return
	end
	direction = Flyout.DirOk(direction or (rec and rec.opts and rec.opts.direction) or "UP")
	Arrow.ConfigureLayer(arrow, widget, reuseLayout)
	Arrow.Anchor(arrow, widget, direction, reuseLayout)
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
			Arrow.Update(widget, rec.opts and rec.opts.direction, Flyout.IsOpen(widget), true)
		end
	end
end
