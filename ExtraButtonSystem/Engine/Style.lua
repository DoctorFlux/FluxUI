-- ExtraButtonSystem/Engine/Style.lua — ring / empty / character scope (minimap)
-- Create may hide the template ring (showBorder=false). ApplyStyle shows the themed ring.
-- Post-DF ActionButtonTemplate OnLoad applies AddRow 51x51 when .bar is nil; replace with IconFrame.
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS

local Style = {}
EBS.Style = Style

-- Quickslot2 is authored with transparent pad; slot-sizing hides the ring.
-- Backup used 1.65× with full texcoords on every pre-DF client (not Forever),
-- plus backpack plate + EmptySlot-Disabled 1.5×. SlotBackground (UI-Quickslot) stays hidden.
local PRE_DF_RING_SCALE = 1.65
local EMPTY_DISABLED_SCALE = 1.5
local DF_RING_W, DF_RING_H, DF_SLOT = 46, 45, 44
local QUICKSLOT2 = "Interface\\Buttons\\UI-Quickslot2"
local QUICKSLOT_DEPRESS = "Interface\\Buttons\\UI-Quickslot-Depress"
local BACKPACK_EMPTY = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
local EMPTY_DISABLED = "Interface\\Buttons\\UI-EmptySlot-Disabled"

-- Forever is 1.x but post-DF. Era/Anni stay on Quickslot2. Live 12.x is not
-- Forever even if CharacterStatsPaneScrollBox exists.
function Style.UseQuickslotRing()
	local C = Flux.Client
	if not C then
		return true
	end
	if C.isAnyClassic then
		return true
	end
	if C.isForever or C.isCamelot then
		return false
	end
	return not C.isPostDF
end

local function ClassRGB()
	local _, classFilename = UnitClass("player")
	local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename]
	if c then
		return c.r, c.g, c.b
	end
	return 0.6, 0.6, 0.6
end

-- scopeOnly: ExtraButtons hosts ignore General → Appearance accent.
local function ThemedRGB(scope, scopeOnly)
	scope = scope or "character"
	if scope == "character" or scope == "class" then
		if not scopeOnly and FluxBorder and FluxBorder.GetThemedVertexRGB then
			return FluxBorder:GetThemedVertexRGB()
		end
		return ClassRGB()
	end
	return 0.8, 0.8, 0.8
end

local function ResolveNormal(button)
	local widget = button and button.Widget
	if widget then
		local tex = widget.NormalTexture
			or (widget.GetNormalTexture and widget:GetNormalTexture())
		if not tex then
			local name = widget.GetName and widget:GetName()
			if name then
				tex = _G[name .. "NormalTexture"]
			end
		end
		if tex then
			button.WNormalTexture = tex
			return tex
		end
	end
	return button and button.WNormalTexture
end

local function SizeChrome(tex, widget, w, h)
	if not tex then
		return
	end
	tex:SetSize(w, h)
	tex:ClearAllPoints()
	tex:SetPoint("CENTER", widget, "CENTER", 0, 0)
	if tex.SetDrawLayer then
		pcall(tex.SetDrawLayer, tex, "OVERLAY", 6)
	end
end

local function FaceDim(stored, measured, fallback)
	if type(stored) == "number" and stored == stored and stored > 0 then
		return stored
	end
	if type(measured) == "number" and measured == measured and measured > 0 then
		return measured
	end
	return fallback
end

-- GetWidth stays on the pre-squeeze size in the same frame as SetSize. Stamp the
-- face we just applied so the ring, border, and highlight follow X squeeze.
local function SlotWH(widget)
	local measuredW = widget.GetWidth and widget:GetWidth() or 0
	local measuredH = widget.GetHeight and widget:GetHeight() or 0
	return FaceDim(widget._fluxLayoutW, measuredW, 32), FaceDim(widget._fluxLayoutH, measuredH, 32)
end

function Style.StampFace(button, faceW, faceH)
	local widget = button and (button.Widget or button)
	if not widget then
		return
	end
	if type(faceW) == "number" and faceW == faceW and faceW > 0 then
		widget._fluxLayoutW = faceW
	end
	if type(faceH) == "number" and faceH == faceH and faceH > 0 then
		widget._fluxLayoutH = faceH
	end
end

function Style.RefreshSqueezeChrome(button, faceW, faceH)
	if not button then
		return
	end
	Style.StampFace(button, faceW, faceH)
	Style.SizeRing(button)
	local Util = _G.FluxButtonUtil
	if Util and Util.SyncFluxButtonLayerSizesToWidget then
		Util:SyncFluxButtonLayerSizesToWidget(button)
	end
	if EBS.Paint and EBS.Paint.UpdateEmpty then
		EBS.Paint.UpdateEmpty(button)
	elseif button.UpdateEmptyBackground then
		button:UpdateEmptyBackground()
	end
end

-- Backup: NormalTexture is a child of the CheckButton and draws outside the
-- 44px box. SlotFrame / squeeze clipping is what hides Quickslot2's ring pad.
local function AllowRingOverhang(widget, button)
	if widget.SetClipsChildren then
		pcall(widget.SetClipsChildren, widget, false)
	end
	local slot = button and button.SlotFrame
	if slot and slot.SetClipsChildren then
		pcall(slot.SetClipsChildren, slot, false)
	end
	local parent = widget.GetParent and widget:GetParent()
	if parent and parent.SetClipsChildren then
		pcall(parent.SetClipsChildren, parent, false)
	end
end

-- Classic mixin uses 1-arg SetDrawLayer("OVERLAY"). Never pass a sublevel
-- (2-arg SetDrawLayer can blank the C++ CheckButton NormalTexture).
local function SizePreDFRing(tex, widget, w, h)
	if not tex then
		return
	end
	tex:SetSize(w * PRE_DF_RING_SCALE, h * PRE_DF_RING_SCALE)
	tex:ClearAllPoints()
	tex:SetPoint("CENTER", widget, "CENTER", 0, 0)
	if tex.SetDrawLayer then
		pcall(tex.SetDrawLayer, tex, "OVERLAY")
	end
end

-- Depress has no transparent pad; 1.65× (ring scale) overflows the slot.
local function SizePreDFDepress(tex, widget, w, h)
	if not tex then
		return
	end
	tex:SetSize(w, h)
	tex:ClearAllPoints()
	tex:SetPoint("CENTER", widget, "CENTER", 0, 0)
	if tex.SetDrawLayer then
		pcall(tex.SetDrawLayer, tex, "OVERLAY")
	end
end

-- Backup DF aniso: native 46×45 TOPLEFT, scaled by slot/44. 1-arg OVERLAY.
local function SizeIconFrame(tex, widget, w, h)
	if not tex then
		return
	end
	local sw = tonumber(w)
	local sh = tonumber(h)
	if not sw or sw < 1 then
		sw = DF_SLOT
	end
	if not sh or sh < 1 then
		sh = DF_SLOT
	end
	tex:SetSize(DF_RING_W * (sw / DF_SLOT), DF_RING_H * (sh / DF_SLOT))
	tex:ClearAllPoints()
	tex:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 0)
	if tex.SetDrawLayer then
		pcall(tex.SetDrawLayer, tex, "OVERLAY")
	end
end

local function EnsureWidgetRing(widget, w, h)
	-- Lua overlay on the CheckButton itself (not SlotFrame parent). Extra
	-- SetScale(1.2/1.3) then keeps the ring in the widget's space.
	local ring = widget._fluxQuickslotRing
	if not ring then
		ring = widget:CreateTexture(nil, "OVERLAY", nil, 7)
		widget._fluxQuickslotRing = ring
		ring:SetTexture(QUICKSLOT2)
		if ring.SetTexCoord then
			ring:SetTexCoord(0, 1, 0, 1)
		end
	end
	ring:ClearAllPoints()
	ring:SetPoint("CENTER", widget, "CENTER", 0, 0)
	ring:SetSize(w * PRE_DF_RING_SCALE, h * PRE_DF_RING_SCALE)
	ring:SetAlpha(1)
	ring:Show()
	return ring
end

local function EnsureBackpackPlate(widget, w, h)
	local bg = widget.BackgroundTexture
	if not bg then
		bg = widget:CreateTexture(nil, "BACKGROUND", nil, -2)
		widget.BackgroundTexture = bg
		bg:SetTexture(BACKPACK_EMPTY)
		if bg.SetTexCoord then
			bg:SetTexCoord(0, 1, 0, 1)
		end
	end
	bg:ClearAllPoints()
	bg:SetPoint("CENTER", widget, "CENTER", 0, 0)
	bg:SetSize(w, h)
	bg:SetAlpha(1)
	bg:Show()
	return bg
end

local function EnsureEmptyDisabled(button, widget, w, h)
	local empty = button.WEmptyBG
	if not empty then
		empty = widget:CreateTexture(nil, "BACKGROUND", nil, -8)
		button.WEmptyBG = empty
		empty:SetTexture(EMPTY_DISABLED)
		empty:SetPoint("CENTER", widget, "CENTER", 0, 0)
		empty:Hide()
	end
	empty:SetSize(w * EMPTY_DISABLED_SCALE, h * EMPTY_DISABLED_SCALE)
	return empty
end

local function HideSlotBackground(widget)
	local bg = widget and widget.SlotBackground
	if not bg then
		return
	end
	bg:Hide()
	if bg.SetAlpha then
		bg:SetAlpha(0)
	end
end

local function TintPlate(tex, r, g, b)
	if tex and tex.SetVertexColor then
		tex:SetVertexColor(r, g, b, 1)
	end
end

local function NormalRingVisible(tex)
	if not tex then
		return false
	end
	if tex.IsShown and not tex:IsShown() then
		return false
	end
	if tex.GetAlpha then
		local a = tex:GetAlpha()
		if type(a) == "number" and a < 0.01 then
			return false
		end
	end
	if tex.GetTexture then
		local path = tex:GetTexture()
		if path == nil or path == false or path == "" then
			return false
		end
	end
	return true
end

local function HideOverlayRing(widget)
	local overlay = widget and widget._fluxQuickslotRing
	if not overlay then
		return
	end
	overlay:Hide()
	if overlay.SetAlpha then
		overlay:SetAlpha(0)
	end
end

local function EnsurePreDFChromeOnShow(widget)
	if not widget or widget._fluxPreDFChromeOnShow then
		return
	end
	if type(widget.HookScript) ~= "function" then
		return
	end
	widget._fluxPreDFChromeOnShow = true
	widget:HookScript("OnShow", function(self)
		local bw, bh = SlotWH(self)
		local normal = (self.GetNormalTexture and self:GetNormalTexture()) or self.NormalTexture
		SizePreDFRing(normal, self, bw, bh)
		local pushed = self.PushedTexture or (self.GetPushedTexture and self:GetPushedTexture())
		SizePreDFDepress(pushed, self, bw, bh)
		HideSlotBackground(self)
		if NormalRingVisible(normal) then
			HideOverlayRing(self)
		end
	end)
end

local function StampPreDFRing(button, widget, w, h)
	AllowRingOverhang(widget, button)
	HideSlotBackground(widget)
	EnsureBackpackPlate(widget, w, h)
	if button.kind == "extra" or widget._fluxExtraButton then
		EnsureEmptyDisabled(button, widget, w, h)
	end
	if widget.SetNormalTexture then
		pcall(widget.SetNormalTexture, widget, QUICKSLOT2)
	end
	local tex = (widget.GetNormalTexture and widget:GetNormalTexture())
		or widget.NormalTexture
	if not tex then
		local name = widget.GetName and widget:GetName()
		if name then
			tex = _G[name .. "NormalTexture"]
		end
	end
	if tex then
		widget.NormalTexture = tex
		button.WNormalTexture = tex
		if tex.SetTexture then
			tex:SetTexture(QUICKSLOT2)
		end
		if tex.SetTexCoord then
			tex:SetTexCoord(0, 1, 0, 1)
		end
		SizePreDFRing(tex, widget, w, h)
		tex:SetAlpha(1)
		tex:Show()
	end
	-- One ring: C++ NormalTexture. Overlay is only a fallback if that texture is blank.
	if NormalRingVisible(tex) then
		HideOverlayRing(widget)
	else
		EnsureWidgetRing(widget, w, h)
	end
	if widget.SetPushedTexture then
		pcall(widget.SetPushedTexture, widget, QUICKSLOT_DEPRESS)
	end
	local pushed = widget.PushedTexture
		or (widget.GetPushedTexture and widget:GetPushedTexture())
	SizePreDFDepress(pushed, widget, w, h)
	EnsurePreDFChromeOnShow(widget)
	return tex
end

-- C++ CheckButton shows HighlightTexture on the HIGHLIGHT layer. Do not
-- move it to OVERLAY or Hide() it (ButtonForge leaves the template alone).
local function SizeHighlight(tex, widget, w, h)
	if not tex then
		return
	end
	tex:SetSize(w, h)
	tex:ClearAllPoints()
	tex:SetPoint("CENTER", widget, "CENTER", 0, 0)
end

-- Classic ActionButtonTemplate: 36×36 slot, Border 62×62 (UI-ActionButton-Border).
-- Extra slots are 32–45; keep that 62/36 glow ratio so the green frame matches the button.
local CLASSIC_SLOT = 36
local CLASSIC_EQUIP_BORDER = 62

local function SizeEquipBorder(border, widget, w, h, postDF)
	if not border then
		return
	end
	if postDF then
		SizeChrome(border, widget, w, h)
	else
		local bw = w * (CLASSIC_EQUIP_BORDER / CLASSIC_SLOT)
		local bh = h * (CLASSIC_EQUIP_BORDER / CLASSIC_SLOT)
		border:SetSize(bw, bh)
		border:ClearAllPoints()
		border:SetPoint("CENTER", widget, "CENTER", 0, 0)
	end
	if border.SetDrawLayer then
		pcall(border.SetDrawLayer, border, "OVERLAY", 7)
	end
end

local function ResolveSlotTex(widget, key, getter)
	if widget[key] then
		return widget[key]
	end
	if getter and widget[getter] then
		return widget[getter](widget)
	end
	return nil
end

function Style.SizeRing(button)
	local widget = button and button.Widget
	if not widget then
		return
	end
	local w, h = SlotWH(widget)
	local useQuickslot = Style.UseQuickslotRing()

	if widget.SlotArt then
		widget.SlotArt:Hide()
	end
	HideSlotBackground(widget)
	if useQuickslot then
		StampPreDFRing(button, widget, w, h)
	else
		HideOverlayRing(widget)
		EnsureBackpackPlate(widget, w, h)
		if widget.SetNormalAtlas then
			pcall(widget.SetNormalAtlas, widget, "UI-HUD-ActionBar-IconFrame", false)
		end
		if widget.SetPushedAtlas then
			pcall(widget.SetPushedAtlas, widget, "UI-HUD-ActionBar-IconFrame-Down", false)
		end
	end
	-- Gold CheckButtonHilight on every client. Overlay owns the texture.
	local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
	if ov and ov.EnsureCheckedTexture then
		ov.EnsureCheckedTexture(widget)
	else
		if widget.SetCheckedTexture then
			pcall(widget.SetCheckedTexture, widget, "Interface\\Buttons\\CheckButtonHilight")
		end
		local checkedTex = ResolveSlotTex(widget, "CheckedTexture", "GetCheckedTexture")
		if checkedTex then
			if checkedTex.SetTexture then
				pcall(checkedTex.SetTexture, checkedTex, "Interface\\Buttons\\CheckButtonHilight")
			end
			if checkedTex.SetBlendMode then
				pcall(checkedTex.SetBlendMode, checkedTex, "ADD")
			end
			checkedTex:SetVertexColor(1, 0.82, 0, 0.55)
			SizeChrome(checkedTex, widget, w, h)
		end
	end

	local tex = ResolveNormal(button)
	if tex then
		if not useQuickslot then
			SizeIconFrame(tex, widget, w, h)
		end
		tex:SetAlpha(1)
		tex:Show()
	end
	local border = button.WBorder
		or widget.Border
		or ResolveSlotTex(widget, "Border", nil)
	if not border then
		local name = widget.GetName and widget:GetName()
		if name then
			border = _G[name .. "Border"]
		end
	end
	if border then
		button.WBorder = border
		if (not useQuickslot) and border.SetAtlas then
			pcall(border.SetAtlas, border, "UI-HUD-ActionBar-IconFrame-Border", false)
		elseif border.SetTexture then
			border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
		end
		if border.SetBlendMode then
			pcall(border.SetBlendMode, border, "ADD")
		end
		SizeEquipBorder(border, widget, w, h, not useQuickslot)
	end
	if not useQuickslot then
		SizeIconFrame(ResolveSlotTex(widget, "PushedTexture", "GetPushedTexture"), widget, w, h)
		SizeChrome(ResolveSlotTex(widget, "CheckedTexture", "GetCheckedTexture"), widget, w, h)
	end
	local highlight = ResolveSlotTex(widget, "HighlightTexture", "GetHighlightTexture")
	if not highlight then
		if (not useQuickslot) and widget.SetHighlightAtlas then
			pcall(widget.SetHighlightAtlas, widget, "UI-HUD-ActionBar-IconFrame-Mouseover", false)
		elseif widget.SetHighlightTexture then
			pcall(widget.SetHighlightTexture, widget, "Interface\\Buttons\\ButtonHilight-Square", "ADD")
		end
		highlight = ResolveSlotTex(widget, "HighlightTexture", "GetHighlightTexture")
	end
	SizeHighlight(highlight, widget, w, h)
	local Flash = Flux.ButtonFX and Flux.ButtonFX.Flash
	if Flash and Flash.Ensure then
		Flash.Ensure(widget)
	end
end

local function TintQuickslotChrome(button, widget, r, g, b)
	local tex = ResolveNormal(button)
	if tex then
		tex:SetVertexColor(r, g, b, 1)
		tex:SetAlpha(1)
		tex:Show()
	end
	TintPlate(widget._fluxQuickslotRing, r, g, b)
	TintPlate(widget.BackgroundTexture, r, g, b)
end

function Style.Apply(button, scope)
	if not button then
		return
	end
	button.categoryScope = scope or button.categoryScope or "character"
	local widget = button.Widget
	local tex = ResolveNormal(button)
	if button.badgeMode then
		if tex then
			tex:SetAlpha(0)
		end
		if widget and widget._fluxQuickslotRing then
			widget._fluxQuickslotRing:Hide()
		end
	else
		Style.SizeRing(button)
		if widget then
			local r, g, b = ThemedRGB(button.categoryScope, button._fluxScopeOnlyTint)
			TintQuickslotChrome(button, widget, r, g, b)
		end
	end
	if EBS.Paint and EBS.Paint.UpdateEmpty then
		EBS.Paint.UpdateEmpty(button)
	elseif button.UpdateEmptyBackground then
		button:UpdateEmptyBackground()
	end
end

--- Ring only (flyout kids). Skip empty-slot paint so icons stay.
function Style.ApplySlotRing(button, scope)
	if not button then
		return
	end
	button.categoryScope = scope or button.categoryScope or "class"
	Style.SizeRing(button)
	local widget = button.Widget
	if widget then
		local r, g, b = ThemedRGB(button.categoryScope, button._fluxScopeOnlyTint)
		TintQuickslotChrome(button, widget, r, g, b)
	end
end
