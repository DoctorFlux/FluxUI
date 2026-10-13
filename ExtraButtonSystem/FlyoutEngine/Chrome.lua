-- ExtraButtonSystem/FlyoutEngine/Chrome.lua — CustomFlyout / SpellFlyout TGA tube.
-- Vertex-tinted from Flux appearance (class / custom). Tooltip-border only if TGA is missing.
local addonName, ns = ...
local Flux = ns.Flux
local Flyout = Flux.EBS and Flux.EBS.Flyout
if not Flyout then
	return
end

local Chrome = {}
Flyout.Chrome = Chrome

local CAP_TEX = "Interface\\Buttons\\ActionBarFlyoutButton"
local HORIZ_TEX = "Interface\\Buttons\\ActionBarFlyoutButton-FlyoutMidLeft"
local VERT_TEX = "Interface\\Buttons\\ActionBarFlyoutButton-FlyoutMid"

-- CustomFlyout uses 0.7 gray. Class/custom accent tints the same TGA.
local function AccentRGB()
	if FluxBorder and FluxBorder.GetAccentColor then
		local r, g, b, mode = FluxBorder:GetAccentColor()
		if mode == "atlas" then
			return 0.7, 0.7, 0.7
		end
		return r, g, b
	end
	if FluxBorder and FluxBorder.GetThemedVertexRGB then
		return FluxBorder:GetThemedVertexRGB()
	end
	return 0.7, 0.7, 0.7
end

local function FillRGB()
	local r, g, b = AccentRGB()
	return r * 0.35, g * 0.35, b * 0.35
end

local function TextureLooksValid(tex)
	if not tex or not tex.GetTexture then
		return false
	end
	local ok, value = pcall(tex.GetTexture, tex)
	if not ok or value == nil or value == "" then
		return false
	end
	return true
end

local function ApplyBackdrop(popup)
	if not popup then
		return
	end
	if BackdropTemplateMixin and not popup.SetBackdrop then
		pcall(Mixin, popup, BackdropTemplateMixin)
	end
	if not popup.SetBackdrop then
		return
	end
	popup:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	local fr, fg, fb = FillRGB()
	popup:SetBackdropColor(fr, fg, fb, 0.92)
	local r, g, b = AccentRGB()
	popup:SetBackdropBorderColor(r, g, b, 1)
	popup._fluxFlyoutBackdrop = true
end

function Chrome.Attach(popup)
	if not popup or popup._fluxFlyoutChrome then
		return popup
	end
	popup._fluxFlyoutChrome = true

	local bgEnd = popup:CreateTexture(nil, "BACKGROUND")
	bgEnd:SetTexture(CAP_TEX)
	bgEnd:SetSize(37, 22)
	bgEnd:SetTexCoord(0.01562500, 0.59375000, 0.74218750, 0.91406250)
	popup.BgEnd = bgEnd
	popup.origBgEndW, popup.origBgEndH = 37, 22

	local horiz = popup:CreateTexture(nil, "BACKGROUND")
	horiz:SetTexture(HORIZ_TEX)
	if horiz.SetHorizTile then
		horiz:SetHorizTile(true)
	end
	horiz:SetSize(32, 37)
	horiz:SetTexCoord(0, 1, 0, 0.578125)
	popup.HorizBg = horiz
	popup.origHorizBgW, popup.origHorizBgH = 32, 37

	local vert = popup:CreateTexture(nil, "BACKGROUND")
	vert:SetTexture(VERT_TEX)
	if vert.SetVertTile then
		vert:SetVertTile(true)
	end
	vert:SetSize(37, 32)
	vert:SetTexCoord(0, 0.578125, 0, 1)
	popup.VertBg = vert
	popup.origVertBgW, popup.origVertBgH = 37, 32

	local tgaOk = TextureLooksValid(bgEnd)
	popup._fluxFlyoutHasTga = tgaOk
	if tgaOk then
		Chrome.ApplyAccent(popup)
		return popup
	end
	bgEnd:Hide()
	horiz:Hide()
	vert:Hide()
	ApplyBackdrop(popup)
	Chrome.ApplyAccent(popup)
	return popup
end

function Chrome.ApplyAccent(popup)
	if not popup then
		return
	end
	local r, g, b = AccentRGB()
	if popup.BgEnd then
		popup.BgEnd:SetVertexColor(r, g, b)
	end
	if popup.HorizBg then
		popup.HorizBg:SetVertexColor(r, g, b)
	end
	if popup.VertBg then
		popup.VertBg:SetVertexColor(r, g, b)
	end
	if popup._fluxFlyoutBackdrop and popup.SetBackdropBorderColor then
		local fr, fg, fb = FillRGB()
		popup:SetBackdropColor(fr, fg, fb, 0.92)
		popup:SetBackdropBorderColor(r, g, b, 1)
	end
end

function Chrome.Layout(popup, direction)
	if not popup then
		return
	end
	direction = Flyout.DirOk(direction or popup.direction)
	local pw = math.max(1, popup:GetWidth() or 40)
	local ph = math.max(1, popup:GetHeight() or 40)
	if not popup._fluxFlyoutHasTga or not popup.BgEnd then
		if popup.BgEnd then
			popup.BgEnd:Hide()
		end
		if popup.HorizBg then
			popup.HorizBg:Hide()
		end
		if popup.VertBg then
			popup.VertBg:Hide()
		end
		if not popup._fluxFlyoutBackdrop then
			ApplyBackdrop(popup)
		end
		Chrome.ApplyAccent(popup)
		return
	end
	if popup._fluxFlyoutBackdrop and popup.SetBackdrop then
		popup:SetBackdrop(nil)
		popup._fluxFlyoutBackdrop = nil
	end
	-- CustomFlyout: 37px tube around 28px kids. Scale that ratio to the cell
	-- and leave the TGA at native aspect — stretching to popup width pulls the
	-- opaque walls off the rings.
	local KID_REF = 28
	local cell = popup._fluxFlyoutCell or KID_REF
	local scale = cell / KID_REF
	local wRatio = 1
	if direction == "LEFT" or direction == "RIGHT" then
		if ph > 0 and cell > 0 then
			wRatio = ph / cell
		end
	elseif pw > 0 and cell > 0 then
		wRatio = pw / cell
	end
	local tubeW = (popup.origVertBgW or 37) * scale * wRatio
	local tubeH = (popup.origHorizBgH or 37) * scale * wRatio
	-- Cap art is 37 wide x 22 tall. Side flyouts rotate it 90/270, which swaps
	-- those axes. SetSize before that rotation is undone on the next layout:
	-- SetClampedTextureRotation returns early once the angle is already set,
	-- so the cap stays short and the tube walls never meet it.
	local capAlong = (popup.origBgEndH or 22) * scale
	popup.BgEnd:Show()
	popup.BgEnd:ClearAllPoints()
	if direction == "LEFT" or direction == "RIGHT" then
		if popup.HorizBg.SetHorizTile then
			popup.HorizBg:SetHorizTile(true)
		end
		popup.HorizBg:SetHeight(tubeH)
		popup.HorizBg:SetWidth(popup.origHorizBgW or 32)
		popup.VertBg:SetSize(popup.origVertBgW or 37, popup.origVertBgH or 32)
	else
		if popup.VertBg.SetVertTile then
			popup.VertBg:SetVertTile(true)
		end
		popup.VertBg:SetWidth(tubeW)
		popup.HorizBg:SetSize(popup.origHorizBgW or 32, popup.origHorizBgH or 37)
	end

	local function SpinCap(rotation, capW, capH)
		if SetClampedTextureRotation then
			SetClampedTextureRotation(popup.BgEnd, rotation)
		end
		popup.BgEnd:SetSize(capW, capH)
	end

	if direction == "DOWN" then
		popup.BgEnd:SetPoint("BOTTOM")
		SpinCap(180, tubeW, capAlong)
		popup.HorizBg:Hide()
		popup.VertBg:Show()
		popup.VertBg:ClearAllPoints()
		popup.VertBg:SetPoint("BOTTOM", popup.BgEnd, "TOP")
		popup.VertBg:SetPoint("TOP", popup, "TOP", 0, 0)
	elseif direction == "LEFT" then
		popup.BgEnd:SetPoint("LEFT")
		SpinCap(270, capAlong, tubeH)
		popup.VertBg:Hide()
		popup.HorizBg:Show()
		popup.HorizBg:ClearAllPoints()
		popup.HorizBg:SetHeight(tubeH)
		popup.HorizBg:SetPoint("LEFT", popup.BgEnd, "RIGHT", -1, 0)
		popup.HorizBg:SetPoint("RIGHT", popup, "RIGHT", 0, 0)
	elseif direction == "RIGHT" then
		popup.BgEnd:SetPoint("RIGHT")
		SpinCap(90, capAlong, tubeH)
		popup.VertBg:Hide()
		popup.HorizBg:Show()
		popup.HorizBg:ClearAllPoints()
		popup.HorizBg:SetHeight(tubeH)
		popup.HorizBg:SetPoint("RIGHT", popup.BgEnd, "LEFT", 1, 0)
		popup.HorizBg:SetPoint("LEFT", popup, "LEFT", 0, 0)
	else
		popup.BgEnd:SetPoint("TOP")
		SpinCap(0, tubeW, capAlong)
		popup.HorizBg:Hide()
		popup.VertBg:Show()
		popup.VertBg:ClearAllPoints()
		popup.VertBg:SetPoint("TOP", popup.BgEnd, "BOTTOM")
		popup.VertBg:SetPoint("BOTTOM", popup, "BOTTOM", 0, 0)
	end
	Chrome.ApplyAccent(popup)
end
