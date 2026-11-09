-- ButtonFX/Overlay.lua — attach SpellFX children + crash-safe stubs.
-- Lifted from unused ExtraButtonSystem/Engine/Core.lua SetupOverlayFrames.
-- Never inherit ActionButtonSpellFXTemplate. Do not call ActionButton_UpdateCooldown.
-- Transfer reparents live cast/reticle/interrupt frames so SWAP/macros do not
-- restart Setup / PlayCast.
local addonName, ns = ...
local Flux = ns.Flux

local ButtonFX = Flux.ButtonFX or {}
Flux.ButtonFX = ButtonFX

local Overlay = {}
ButtonFX.Overlay = Overlay

local CAST = 1
local CHANNEL = 2
local EMPOWER = 3
if ActionButtonCastType then
	CAST = ActionButtonCastType.Cast or CAST
	CHANNEL = ActionButtonCastType.Channel or CHANNEL
	EMPOWER = ActionButtonCastType.Empowered or EMPOWER
end
Overlay.CAST = CAST
Overlay.CHANNEL = CHANNEL
Overlay.EMPOWER = EMPOWER

--- ActionButtonTemplate.xml: Classic uses a=0.8, Retail uses a=0.64.
--- Match Blizzard's default cooldown transparency per client.
local ACTION_BUTTON_SWIPE_A
if Flux.Client and Flux.Client.isAnyClassic then
	ACTION_BUTTON_SWIPE_A = 0.8
else
	ACTION_BUTTON_SWIPE_A = 0.64
end

local function VfxAllowed()
	local CastMod = ButtonFX.Cast
	if CastMod and CastMod.IsSpellCastVFXEnabled then
		return CastMod.IsSpellCastVFXEnabled()
	end
	return true
end

local function NativeCastFrame(widget)
	local cf = widget and widget.SpellCastAnimFrame
	if cf and cf.Setup then
		return cf
	end
	return nil
end

local CAST_CENTER = 45
local CAST_TRAVEL = 43
local CAST_REF_W = 44
local OVERLAY_TEMPLATE = 128

-- Native channel atlas pixels are already ~see-through. SetAlpha on that
-- atlas does not change what you see. Channel density comes from a color
-- body under the atlas, under the ring — a tint, not a slab.
local FILL_ALPHA = 0.80
local CHANNEL_FILL_ALPHA = 0.62
local CHANNEL_UNDER_ALPHA = 0.38
local CHANNEL_UNDER_R = 0.22
local CHANNEL_UNDER_G = 0.95
local CHANNEL_UNDER_B = 0.42

local function FillAlphaForKind(kind)
	if kind == CHANNEL or kind == EMPOWER then
		return CHANNEL_FILL_ALPHA
	end
	return FILL_ALPHA
end

local function ApplyFillOpacity(tex)
	if not tex then
		return
	end
	if tex.SetVertexColor then
		pcall(tex.SetVertexColor, tex, 1, 1, 1, 1)
	end
	if tex.SetAlpha then
		pcall(tex.SetAlpha, tex, 1)
	end
end

-- Blizzard SpellFX uses useParentLevel so ARTWORK fill sits under the OVERLAY
-- IconFrame ring. Raising these frames (+10 / +25) composites them on top of
-- the ring. Keep VFX in the button's own level band.
local function ApplyParentLevel(frame, parent)
	if not frame then
		return
	end
	parent = parent or (frame.GetParent and frame:GetParent())
	if frame.SetUsingParentLevel then
		pcall(frame.SetUsingParentLevel, frame, true)
		return
	end
	if frame.SetFrameLevel and parent and parent.GetFrameLevel then
		pcall(frame.SetFrameLevel, frame, parent:GetFrameLevel() or 0)
	end
end

local function SetDraw(tex, layer, sub)
	if not tex or not tex.SetDrawLayer then
		return
	end
	sub = tonumber(sub) or 0
	if sub > 7 then
		sub = 7
	elseif sub < -8 then
		sub = -8
	end
	pcall(tex.SetDrawLayer, tex, layer, sub)
end

-- Channel/cast fill must sit above the cooldown child so GCD/spell swipe
-- still paints, while the fill stays readable on the same icon.
local FILL_ABOVE_COOLDOWN = 1

-- Shown cooldown only. Showing a cleared swipe is a full-dark slab that
-- does not progress (Extra Button cast/channel looked fully darkened).
local function ShownCooldownLevel(widget)
	local cd = widget and widget.cooldown
	if not cd or not cd.GetFrameLevel then
		return nil
	end
	if cd.IsShown then
		local ok, shown = pcall(cd.IsShown, cd)
		if not ok or not shown then
			return nil
		end
	end
	local ok, level = pcall(cd.GetFrameLevel, cd)
	if ok and type(level) == "number" then
		return level
	end
	return nil
end

local function ApplyFillAboveCooldown(frame, widget)
	if not frame or not widget then
		return
	end
	pcall(frame.SetParent, frame, widget)
	if frame.SetUsingParentLevel then
		pcall(frame.SetUsingParentLevel, frame, false)
	end
	local level = ShownCooldownLevel(widget)
	if not level then
		level = (widget.GetFrameLevel and widget:GetFrameLevel()) or 0
	end
	if frame.SetFrameLevel then
		pcall(frame.SetFrameLevel, frame, level + FILL_ABOVE_COOLDOWN)
	end
end

-- Targeting reticle composites above the IconFrame ring (OVERLAY 6).
-- Live fill is a child above the cooldown so GCD/spell swipe still shows.
-- InterruptDisplay matches backup 128 CENTER, same extra level as reticle.
local RETICLE_ABOVE_RING = 2

local function ApplyInterruptLayers(frame, parent)
	if not frame then
		return
	end
	parent = parent or (frame.GetParent and frame:GetParent())
	if frame.SetUsingParentLevel then
		pcall(frame.SetUsingParentLevel, frame, false)
	end
	-- Kick sits above the cooldown swipe so interrupt and CD show together.
	local level = ShownCooldownLevel(parent)
	if not level and parent and parent.GetFrameLevel then
		level = parent:GetFrameLevel() or 0
	end
	level = level or 0
	if frame.SetFrameLevel then
		pcall(frame.SetFrameLevel, frame, level + RETICLE_ABOVE_RING)
	end
	ApplyParentLevel(frame.Highlight, frame)
	ApplyParentLevel(frame.Base, frame)
	local hl = frame.Highlight
	SetDraw(hl and hl.HighlightTexture, "ARTWORK", 0)
	local base = frame.Base
	SetDraw(base and (base.Base or base), "ARTWORK", 1)
end

local function ApplyReticleLevel(frame, parent)
	if not frame then
		return
	end
	parent = parent or (frame.GetParent and frame:GetParent())
	if frame.SetUsingParentLevel then
		pcall(frame.SetUsingParentLevel, frame, false)
	end
	if frame.SetFrameLevel and parent and parent.GetFrameLevel then
		pcall(frame.SetFrameLevel, frame, (parent:GetFrameLevel() or 0) + RETICLE_ABOVE_RING)
	end
	SetDraw(frame.Base, "OVERLAY", 6)
	SetDraw(frame.Highlight, "OVERLAY", 7)
end

local nativeWatch = {}
local nativeTicker

local function CoerceTime(value)
	if Flux.Secrets and Flux.Secrets.CoerceNumberLoose then
		return Flux.Secrets.CoerceNumberLoose(value, 0)
	end
	local n = tonumber(value)
	return n or 0
end

local function NativeFillPlaying(widget)
	local cf = widget and widget.SpellCastAnimFrame
	local anim = cf and cf.Fill and cf.Fill.CastingAnim
	if not anim or not anim.IsPlaying then
		return false
	end
	local ok, playing = pcall(anim.IsPlaying, anim)
	return ok and playing and true or false
end

local function EndBurstShown(widget)
	local burst = widget and widget.SpellCastAnimFrame and widget.SpellCastAnimFrame.EndBurst
	if not burst or not burst.IsShown then
		return false
	end
	local ok, shown = pcall(burst.IsShown, burst)
	return ok and shown and true or false
end

local function FreezeNativeAnim(cf)
	if not cf then
		return
	end
	local fill = cf.Fill
	local anim = fill and fill.CastingAnim
	if anim and anim.Stop then
		pcall(anim.Stop, anim)
	end
	-- Do not Stop FinishCastAnim here: Stop fires OnFinished and hides the
	-- whole SpellCastAnimFrame (kills fill and the later burst).
	local endBurst = cf.EndBurst
	if endBurst then
		Overlay._suppressBurstHide = true
		if endBurst.FinishCastAnim and endBurst.FinishCastAnim.Stop then
			pcall(endBurst.FinishCastAnim.Stop, endBurst.FinishCastAnim)
		end
		if endBurst.Hide then
			pcall(endBurst.Hide, endBurst)
		end
		Overlay._suppressBurstHide = nil
	end
	if fill and fill.Show then
		pcall(fill.Show, fill)
	end
	if cf.Show then
		pcall(cf.Show, cf)
	end
end

-- Face GetWidth is squeezed (44*xF); GetHeight stays native 44. Parent SetScale
-- still applies to overlay children. Overlay chrome uses 128/44 per axis;
-- OverlayXRatio is fill travel on X only.
local function OverlayButtonWidth(widget)
	if not widget then
		return CAST_REF_W
	end
	local w = widget.GetWidth and widget:GetWidth()
	w = tonumber(w)
	if w and w > 0 then
		return w
	end
	return CAST_REF_W
end

local function OverlayButtonHeight(widget)
	if not widget then
		return CAST_REF_W
	end
	local h = widget.GetHeight and widget:GetHeight()
	h = tonumber(h)
	if h and h > 0 then
		return h
	end
	return CAST_REF_W
end

local function OverlayXRatio(widget)
	return OverlayButtonWidth(widget) / CAST_REF_W
end

local function OverlayYRatio(widget)
	return OverlayButtonHeight(widget) / CAST_REF_W
end

local function OverlayTemplateSize(widget)
	local w = OverlayButtonWidth(widget)
	local h = OverlayButtonHeight(widget)
	return OVERLAY_TEMPLATE * (w / CAST_REF_W), OVERLAY_TEMPLATE * (h / CAST_REF_W)
end

local function SetOverlaySize(region, ow, oh)
	if region and region.SetSize then
		pcall(region.SetSize, region, ow, oh)
	end
end

-- Atlas textures are not 128. Stamp native size once, then * (w/44) x (h/44).
local function ScaleNativeRegion(region, xR, yR)
	if not region or not region.SetSize then
		return
	end
	local nw, nh = region._fluxNativeW, region._fluxNativeH
	if not nw or not nh then
		nw = region.GetWidth and tonumber(region:GetWidth())
		nh = region.GetHeight and tonumber(region:GetHeight())
		if not nw or nw <= 0 or not nh or nh <= 0 then
			return
		end
		region._fluxNativeW = nw
		region._fluxNativeH = nh
	end
	pcall(region.SetSize, region, nw * xR, nh * yR)
end

local function NativeFillOffset(widget, progress)
	local scale = OverlayXRatio(widget)
	if progress < 0 then
		progress = 0
	elseif progress > 1 then
		progress = 1
	end
	return (-CAST_CENTER + CAST_TRAVEL * progress) * scale
end

local function ApplyNativeFillProgress(widget, progress)
	local cf = widget and widget.SpellCastAnimFrame
	if not cf then
		return
	end
	local fill = cf.Fill
	-- PreDF slot-fill owns travel. Retail CastFill SetPoint owns travel.
	-- Do not call both: ApplyCastBarLayoutFromButton can reset atlas layout.
	if widget._fluxSpellCastAnimSlotFill and cf.ApplyCastBarLayoutFromButton then
		pcall(cf.ApplyCastBarLayoutFromButton, cf, progress)
	elseif fill and fill.CastFill then
		local ox = NativeFillOffset(widget, progress)
		if fill.CastFill.ClearAllPoints then
			pcall(fill.CastFill.ClearAllPoints, fill.CastFill)
		end
		pcall(fill.CastFill.SetPoint, fill.CastFill, "CENTER", ox, 0)
		ApplyFillOpacity(fill.CastFill)
		if fill.CastFill.Show then
			pcall(fill.CastFill.Show, fill.CastFill)
		end
	elseif cf.ApplyCastBarLayoutFromButton then
		pcall(cf.ApplyCastBarLayoutFromButton, cf, progress)
	end
	if fill and fill.InnerGlowTexture then
		ApplyFillOpacity(fill.InnerGlowTexture)
		if fill.InnerGlowTexture.Show then
			pcall(fill.InnerGlowTexture.Show, fill.InnerGlowTexture)
		end
	end
	if fill and fill.Show then
		pcall(fill.Show, fill)
	end
	if cf.Show then
		pcall(cf.Show, cf)
	end
end

-- Native channel atlas is a wash. Paint a body on SpellCastAnimFrame (same
-- stack as the visible fill). Extra textures on Fill are wiped by Setup.
local function HideChannelUnderlay(cf)
	local tex = cf and cf._fluxChannelUnder
	if tex and tex.Hide then
		tex:Hide()
	end
end

local function ApplyChannelUnderlay(widget, progress, kind)
	if not widget then
		return
	end
	local cf = widget.SpellCastAnimFrame
	if kind ~= CHANNEL and kind ~= EMPOWER then
		HideChannelUnderlay(cf)
		return
	end
	if not cf or not cf.CreateTexture then
		return
	end
	local tex = cf._fluxChannelUnder
	if not tex then
		tex = cf:CreateTexture(nil, "ARTWORK", nil, 0)
		cf._fluxChannelUnder = tex
		if tex.SetBlendMode then
			pcall(tex.SetBlendMode, tex, "BLEND")
		end
		local mask = widget.IconMask or (cf.Fill and cf.Fill.FillMask)
		if mask and tex.AddMaskTexture then
			pcall(tex.AddMaskTexture, tex, mask)
		end
	end
	if progress < 0 then
		progress = 0
	elseif progress > 1 then
		progress = 1
	end
	local w = OverlayButtonWidth(widget)
	if tex.ClearAllPoints then
		tex:ClearAllPoints()
	end
	tex:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 0)
	tex:SetPoint("BOTTOMLEFT", widget, "BOTTOMLEFT", 0, 0)
	tex:SetWidth(math.max(1, w * progress))
	tex:SetColorTexture(CHANNEL_UNDER_R, CHANNEL_UNDER_G, CHANNEL_UNDER_B, 1)
	tex:SetAlpha(CHANNEL_UNDER_ALPHA)
	SetDraw(tex, "ARTWORK", 0)
	tex:Show()
end

local function LayoutCastFrame(widget, cf, overCooldown)
	if not widget or not cf then
		return
	end
	pcall(cf.SetParent, cf, widget)
	if cf.ClearAllPoints then
		pcall(cf.ClearAllPoints, cf)
	end
	pcall(cf.SetPoint, cf, "CENTER", widget, "CENTER", 0, 0)
	local xR = OverlayXRatio(widget)
	local yR = OverlayYRatio(widget)
	local ow, oh = OverlayTemplateSize(widget)
	SetOverlaySize(cf, ow, oh)
	local fill = cf.Fill
	SetOverlaySize(fill, ow, oh)
	-- IconFrame-Mask matches the icon, not the 128 overlay.
	ScaleNativeRegion(fill and fill.FillMask, xR, yR)
	ScaleNativeRegion(fill and fill.InnerGlowTexture, xR, yR)
	if overCooldown then
		ApplyFillAboveCooldown(cf, widget)
	else
		ApplyParentLevel(cf, widget)
	end
	ApplyParentLevel(fill, cf)
	local burst = cf.EndBurst
	if burst then
		SetOverlaySize(burst, ow, oh)
		ScaleNativeRegion(burst.EndMask, xR, yR)
		ScaleNativeRegion(burst.GlowRing, xR, yR)
		ApplyParentLevel(burst, cf)
	end
	SetDraw(fill and fill.CastFill, "ARTWORK", 1)
	SetDraw(fill and fill.InnerGlowTexture, "ARTWORK", 0)
	SetDraw(burst and burst.GlowRing, "ARTWORK", 2)
end

-- Interrupt inner frames are 128; textures/masks stay atlas-native * ratios.
local function LayoutInterruptDisplay(widget, frame)
	if not widget or not frame then
		return
	end
	pcall(frame.SetParent, frame, widget)
	if frame.ClearAllPoints then
		pcall(frame.ClearAllPoints, frame)
	end
	pcall(frame.SetPoint, frame, "CENTER", widget, "CENTER", 0, 0)
	local xR = OverlayXRatio(widget)
	local yR = OverlayYRatio(widget)
	local ow, oh = OverlayTemplateSize(widget)
	SetOverlaySize(frame, ow, oh)
	SetOverlaySize(frame.Highlight, ow, oh)
	SetOverlaySize(frame.Base, ow, oh)
	local hl = frame.Highlight
	ScaleNativeRegion(hl and hl.Mask, xR, yR)
	ScaleNativeRegion(hl and hl.HighlightTexture, xR, yR)
	local base = frame.Base
	ScaleNativeRegion(base and (base.Base or base.BaseTexture), xR, yR)
	ScaleNativeRegion(base and base.Mask, xR, yR)
	ApplyInterruptLayers(frame, widget)
end

local function LayoutReticle(widget, frame)
	if not widget or not frame then
		return
	end
	pcall(frame.SetParent, frame, widget)
	if frame.ClearAllPoints then
		pcall(frame.ClearAllPoints, frame)
	end
	pcall(frame.SetPoint, frame, "CENTER", widget, "CENTER", 0, 0)
	local xR = OverlayXRatio(widget)
	local yR = OverlayYRatio(widget)
	local ow, oh = OverlayTemplateSize(widget)
	SetOverlaySize(frame, ow, oh)
	ScaleNativeRegion(frame.Base, xR, yR)
	ScaleNativeRegion(frame.Highlight, xR, yR)
	ScaleNativeRegion(frame.Mask, xR, yR)
	ApplyReticleLevel(frame, widget)
end

local function ApplyCastAtlas(cf, kind)
	local fill = cf and cf.Fill
	if not fill or not fill.CastFill or not fill.CastFill.SetAtlas then
		return
	end
	if kind == CHANNEL then
		pcall(fill.CastFill.SetAtlas, fill.CastFill, "UI-HUD-ActionBar-Channel-Fill", true)
		if fill.InnerGlowTexture and fill.InnerGlowTexture.SetAtlas then
			pcall(fill.InnerGlowTexture.SetAtlas, fill.InnerGlowTexture, "UI-HUD-ActionBar-Channel-InnerGlow", true)
		end
	else
		pcall(fill.CastFill.SetAtlas, fill.CastFill, "UI-HUD-ActionBar-Cast-Fill", true)
		if fill.InnerGlowTexture and fill.InnerGlowTexture.SetAtlas then
			pcall(fill.InnerGlowTexture.SetAtlas, fill.InnerGlowTexture, "UI-HUD-ActionBar-Casting-InnerGlow", true)
		end
	end
	ApplyFillOpacity(fill.CastFill)
	ApplyFillOpacity(fill.InnerGlowTexture)
end

local function VfxUnit(widget)
	if widget and widget._fluxVfxUnit == "pet" then
		return "pet"
	end
	return "player"
end

local function UnitCastTimes(kind, widget)
	local fn = UnitCastingInfo
	if kind == CHANNEL or kind == EMPOWER then
		fn = UnitChannelInfo
	end
	if type(fn) ~= "function" then
		return nil, nil
	end
	local ok, _, _, _, startTime, endTime = pcall(fn, VfxUnit(widget))
	if not ok then
		return nil, nil
	end
	startTime = CoerceTime(startTime)
	endTime = CoerceTime(endTime)
	if startTime <= 0 or endTime <= 0 or endTime <= startTime then
		return nil, nil
	end
	return startTime, endTime
end

function Overlay._tickNativeFill(widget)
	if not widget or widget._fluxVfxMode ~= "native" then
		return
	end
	ApplyFillAboveCooldown(widget.SpellCastAnimFrame, widget)
	local kind = widget.actionButtonCastType or CAST
	local startTime, endTime = UnitCastTimes(kind, widget)
	local data = widget.vfxCastData
	if startTime and endTime then
		local duration = (endTime - startTime) / 1000
		if duration <= 0 then
			duration = 0.0001
		end
		data = data or {}
		data.start = startTime / 1000
		data.duration = duration
		data.type = kind
		widget.vfxCastData = data
		local CastMod = ButtonFX.Cast
		if CastMod and CastMod.NoteChannelTimes then
			-- Pet fill must not stamp player Cast._active channel times.
			CastMod.NoteChannelTimes(startTime, endTime, VfxUnit(widget))
		end
	else
		-- Unit APIs empty: freeze last frame. Do not walk stale duration to p=1
		-- (that is the stuck full-bar). Stop/Succeeded/FollowColumn hide it.
		return
	end
	local now = (GetTime and GetTime()) or 0
	local p = (now - data.start) / (data.duration > 0 and data.duration or 0.0001)
	if p < 0 then
		p = 0
	elseif p > 1 then
		p = 1
	end
	if kind == CHANNEL then
		p = 1 - p
	end
	ApplyNativeFillProgress(widget, p)
	ApplyChannelUnderlay(widget, p, kind)
end

function Overlay._tickFinish(widget)
	if not widget or widget._fluxVfxMode ~= "finish" then
		return
	end
	local start = widget._fluxFinishStart or 0
	local now = (GetTime and GetTime()) or 0
	local limit = (Overlay.BURST_DURATION or 0.45) + 0.15
	if now - start < limit then
		return
	end
	Overlay.ForceClear(widget)
end

local function EnsureNativeTicker()
	if nativeTicker or not CreateFrame then
		return nativeTicker
	end
	nativeTicker = CreateFrame("Frame")
	nativeTicker:Hide()
	nativeTicker:SetScript("OnUpdate", function()
		local any = false
		for w in pairs(nativeWatch) do
			if w and w._fluxVfxMode == "native" then
				Overlay._tickNativeFill(w)
				any = true
			elseif w and w._fluxVfxMode == "finish" then
				Overlay._tickFinish(w)
				any = true
			else
				nativeWatch[w] = nil
			end
		end
		if not any then
			nativeTicker:Hide()
		end
	end)
	return nativeTicker
end

function Overlay.WatchNativeFill(widget)
	if not widget then
		return
	end
	nativeWatch[widget] = true
	local ticker = EnsureNativeTicker()
	if ticker and ticker.Show then
		ticker:Show()
	end
end

function Overlay.UnwatchNativeFill(widget)
	if widget then
		nativeWatch[widget] = nil
	end
end

local function SetSwipeCasting(widget, casting)
	local cd = widget and widget.cooldown
	if cd and cd.SetSwipeColor then
		if casting then
			pcall(cd.SetSwipeColor, cd, 0, 0, 0, 0)
			widget.hideCooldownFrame = true
		else
			pcall(cd.SetSwipeColor, cd, 0, 0, 0, ACTION_BUTTON_SWIPE_A)
			widget.hideCooldownFrame = nil
		end
	end
end

local function HideCooldownCover(widget, hide)
	SetSwipeCasting(widget, hide and true or false)
	local cd = widget and widget.cooldown
	if not cd then
		return
	end
	if hide then
		-- Paint/Charges.Apply run every cooldown event. Snapshot IsShown once
		-- so a second Hide does not record "already hidden" and skip restore.
		if not widget._fluxCdCoverHidden then
			widget._fluxCdCoverHidden = true
			if cd.IsShown then
				local ok, shown = pcall(cd.IsShown, cd)
				if ok then
					widget._fluxCdWasShown = shown and true or false
				end
			end
		end
		if cd.Hide then
			pcall(cd.Hide, cd)
		end
		return
	end
	local wasHidden = widget._fluxCdCoverHidden
	widget._fluxCdCoverHidden = nil
	if wasHidden and widget._fluxCdWasShown and cd.Show then
		pcall(cd.Show, cd)
	end
	widget._fluxCdWasShown = nil
end

function Overlay.HideCooldownCover(widget, hide)
	HideCooldownCover(widget, hide)
end

local function HideNativeCast(widget)
	local cf = widget and widget.SpellCastAnimFrame
	if cf and cf.Hide then
		pcall(cf.Hide, cf)
	end
end

local BURST_DURATION = 0.45
local INTERRUPT_HOLD = 0.35
local INTERRUPT_FADE = 0.25
Overlay.BURST_DURATION = BURST_DURATION
Overlay.INTERRUPT_HOLD = INTERRUPT_HOLD
Overlay.INTERRUPT_FADE = INTERRUPT_FADE

local function SafeOverrideAnimGroupFinished(animGroup, handler)
	if not animGroup then
		return
	end
	animGroup.OnFinished = handler
	pcall(function()
		animGroup:SetScript("OnFinished", handler)
	end)
end

local function OverrideSpellCastAnimScripts(frame)
	if not frame then
		return
	end

	local safeOnHide = function(self)
		if Overlay._transferring or Overlay._clearing then
			return
		end
		local parent = self:GetParent()
		if parent and parent.ClearReticle then
			pcall(parent.ClearReticle, parent)
		end
		SetSwipeCasting(parent, false)
		-- Skip ActionButton_UpdateCooldown — crashes on custom / detached hosts.
	end

	pcall(function()
		frame:SetScript("OnHide", nil)
	end)
	rawset(frame, "OnHide", safeOnHide)
	pcall(function()
		frame:SetScript("OnHide", safeOnHide)
	end)

	pcall(function()
		if frame.EndBurst and frame.EndBurst.FinishCastAnim then
			SafeOverrideAnimGroupFinished(frame.EndBurst.FinishCastAnim, function(self)
				if Overlay._suppressBurstHide or Overlay._clearing then
					return
				end
				pcall(function()
					local spellCastFrame = self:GetParent() and self:GetParent():GetParent()
					local parentButton = spellCastFrame and spellCastFrame:GetParent()
					if spellCastFrame then
						local savedScript = spellCastFrame:GetScript("OnHide")
						local savedMixin = rawget(spellCastFrame, "OnHide")
						spellCastFrame:SetScript("OnHide", nil)
						rawset(spellCastFrame, "OnHide", nil)
						spellCastFrame:Hide()
						if savedScript then
							spellCastFrame:SetScript("OnHide", savedScript)
						end
						if savedMixin then
							rawset(spellCastFrame, "OnHide", savedMixin)
						end
					end
					if parentButton then
						SetSwipeCasting(parentButton, false)
						parentButton.actionButtonCastType = nil
						parentButton._fluxVfxMode = nil
					end
				end)
			end)
		end
	end)
	-- Manual fill owns CastFill. CastingAnim:Stop (Hide / ForceClear / Freeze)
	-- fires OnFinished; the mixin would Show EndBurst and loop the finish flash
	-- on empty buttons. Overlay.PlayBurst / StopCast owns the burst.
	pcall(function()
		if frame.Fill and frame.Fill.CastingAnim then
			SafeOverrideAnimGroupFinished(frame.Fill.CastingAnim, function()
				return
			end)
		end
	end)
end

local function InstallStubs(widget)
	widget.ClearReticle = function(self)
		local rf = self.TargetReticleAnimFrame
		if rf then
			if rf.HighlightAnim and rf.HighlightAnim.Stop then
				pcall(rf.HighlightAnim.Stop, rf.HighlightAnim)
			end
			pcall(rf.Hide, rf)
		end
	end

	widget.StopTargettingReticleAnim = function(self)
		local rf = self.TargetReticleAnimFrame
		if rf then
			if rf.HighlightAnim and rf.HighlightAnim.Stop then
				pcall(rf.HighlightAnim.Stop, rf.HighlightAnim)
			end
			pcall(rf.Hide, rf)
		end
	end

	widget.ClearInterruptDisplay = function(self)
		if self.InterruptDisplay then
			pcall(function()
				self.InterruptDisplay:Hide()
			end)
		end
		if self._fluxInterruptFlash then
			self._fluxInterruptFlash:Hide()
		end
	end

	-- LAB: force-hide on interrupt; FinishAnimAndPlayBurst on success if fill is playing.
	widget.StopSpellCastAnim = function(self, interrupted)
		Overlay.StopCast(self, interrupted and true or false)
	end

	widget.PlaySpellInterruptedAnim = function(self)
		Overlay.PlayInterrupt(self)
	end

	widget.PlayTargettingReticleAnim = function(self)
		if self.InterruptDisplay and self.InterruptDisplay.IsShown and self.InterruptDisplay:IsShown() then
			self.InterruptDisplay:Hide()
		end
		local host = self._fluxHost
		if self._fluxAssistedCombat then
			return
		end
		if host and host.slot and Flux.Action and Flux.Action.IsAssistedCombat then
			if Flux.Action.IsAssistedCombat(host.slot) then
				return
			end
		end
		local rf = self.TargetReticleAnimFrame
		if rf then
			if rf._fluxLuaSpellFX and not rf._fluxHasArt then
				return
			end
			if rf.Setup then
				pcall(rf.Setup, rf)
			end
			pcall(rf.Show, rf)
		end
	end

	widget.PlaySpellCastAnim = function(self, kind)
		Overlay.PlayCast(self, kind or CAST)
	end
end

local INTERRUPT_MASK_ATLAS = "UI-HUD-ActionBar-Interrupt-Mask"
local TARGET_MASK_ATLAS = "UI-HUD-ActionBar-Target-Mask"
local MEDIA = "Interface\\AddOns\\" .. tostring(addonName) .. "\\Media\\ActionBar\\"
local INTERRUPT_MASK_FILE = MEDIA .. "UI-HUD-ActionBar-Interrupt-Mask"
local TARGET_MASK_FILE = MEDIA .. "UI-HUD-ActionBar-Target-Mask"

local function HasAtlas(name)
	local Cap = Flux.Cap
	if Cap and Cap.HasAtlas then
		return Cap.HasAtlas(name)
	end
	if C_Texture and C_Texture.GetAtlasInfo then
		local ok, info = pcall(C_Texture.GetAtlasInfo, name)
		return ok and info ~= nil
	end
	if GetAtlasInfo then
		local ok, w = pcall(GetAtlasInfo, name)
		return ok and w ~= nil
	end
	return false
end

local function MixInto(obj, mixin)
	if not obj or not mixin then
		return
	end
	if Mixin then
		pcall(Mixin, obj, mixin)
		return
	end
	for k, v in pairs(mixin) do
		if obj[k] == nil then
			obj[k] = v
		end
	end
end

local function ApplyAtlas(tex, atlas)
	if not tex or not atlas or not HasAtlas(atlas) then
		return false
	end
	if tex.SetAtlas then
		return pcall(tex.SetAtlas, tex, atlas, true)
	end
	return false
end

local function ApplyMask(mask, atlas, file, w, h)
	if not mask then
		return
	end
	if HasAtlas(atlas) and mask.SetAtlas then
		pcall(mask.SetAtlas, mask, atlas, true)
	elseif file then
		pcall(mask.SetTexture, mask, file, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		if w and mask.SetSize then
			pcall(mask.SetSize, mask, w, h or w)
		end
	end
end

local function ButtonMaskSize(widget)
	local w = OverlayButtonWidth(widget)
	local h = OverlayButtonHeight(widget)
	if type(w) ~= "number" or w < 8 then
		w = 36
	end
	if type(h) ~= "number" or h < 8 then
		h = 36
	end
	return w, h
end

local function BuildInterruptFrame(widget)
	local frame = CreateFrame("Frame", nil, widget)
	frame._fluxLuaSpellFX = true
	frame:Hide()

	local highlight = CreateFrame("Frame", nil, frame)
	highlight:SetSize(128, 128)
	highlight:SetPoint("CENTER")
	frame.Highlight = highlight

	local ht = highlight:CreateTexture(nil, "ARTWORK")
	ht:SetPoint("CENTER", 0, 50)
	ht:SetAlpha(1)
	if ht.SetBlendMode then
		pcall(ht.SetBlendMode, ht, "ADD")
	end
	highlight.HighlightTexture = ht
	local hasHL = ApplyAtlas(ht, "UI-HUD-ActionBar-Interrupt-Highlight")

	if highlight.CreateMaskTexture then
		local mask = highlight:CreateMaskTexture()
		mask:SetPoint("CENTER", 2, -1)
		ApplyMask(mask, INTERRUPT_MASK_ATLAS, INTERRUPT_MASK_FILE, ButtonMaskSize(widget))
		if ht.AddMaskTexture then
			pcall(ht.AddMaskTexture, ht, mask)
		end
		highlight.Mask = mask
	end

	local hlAnim = highlight:CreateAnimationGroup()
	highlight.AnimIn = hlAnim
	local trans = hlAnim:CreateAnimation("Translation")
	trans:SetDuration(0.5)
	trans:SetOrder(1)
	trans:SetOffset(0, -150)
	if trans.SetChildKey then
		pcall(trans.SetChildKey, trans, "HighlightTexture")
	elseif trans.SetTarget then
		pcall(trans.SetTarget, trans, ht)
	end

	local base = CreateFrame("Frame", nil, frame)
	base:SetSize(128, 128)
	base:SetPoint("CENTER")
	frame.Base = base

	local bt = base:CreateTexture(nil, "ARTWORK")
	bt:SetPoint("CENTER")
	bt:SetAlpha(1)
	base.Base = bt
	local hasBase = ApplyAtlas(bt, "UI-HUD-ActionBar-Interrupt")

	local baseAnim = base:CreateAnimationGroup()
	base.AnimIn = baseAnim
	local fade = baseAnim:CreateAnimation("Alpha")
	fade:SetDuration(0.25)
	fade:SetOrder(1)
	if fade.SetStartDelay then
		pcall(fade.SetStartDelay, fade, 1)
	end
	if fade.SetFromAlpha then
		pcall(fade.SetFromAlpha, fade, 1)
		pcall(fade.SetToAlpha, fade, 0)
	elseif fade.SetChange then
		pcall(fade.SetChange, fade, -1)
	end
	if fade.SetSmoothing then
		pcall(fade.SetSmoothing, fade, "OUT")
	end
	if fade.SetChildKey then
		pcall(fade.SetChildKey, fade, "Base")
	elseif fade.SetTarget then
		pcall(fade.SetTarget, fade, bt)
	end
	MixInto(baseAnim, _G.ActionButtonInterruptAnimInMixin)
	if baseAnim.OnFinished then
		baseAnim:SetScript("OnFinished", baseAnim.OnFinished)
	end

	MixInto(frame, _G.ActionButtonInterruptFrameMixin)
	if frame.OnShow then
		frame:SetScript("OnShow", frame.OnShow)
	end
	if frame.OnHide then
		frame:SetScript("OnHide", frame.OnHide)
	end

	frame._fluxHasArt = (hasHL or hasBase) and true or false
	return frame
end

local function BuildReticleFrame(widget)
	local frame = CreateFrame("Frame", nil, widget)
	frame._fluxLuaSpellFX = true
	frame:SetSize(128, 128)
	frame:SetPoint("CENTER")
	frame:Hide()

	local base = frame:CreateTexture(nil, "OVERLAY", nil, 7)
	base:SetPoint("CENTER")
	frame.Base = base
	local hasBase = ApplyAtlas(base, "UI-HUD-ActionBar-Target")

	local hl = frame:CreateTexture(nil, "OVERLAY", nil, 7)
	hl:SetPoint("CENTER")
	hl:SetAlpha(0.8)
	if hl.SetBlendMode then
		pcall(hl.SetBlendMode, hl, "ADD")
	end
	if hl.SetSnapToPixelGrid then
		pcall(hl.SetSnapToPixelGrid, hl, false)
	end
	if hl.SetTexelSnappingBias then
		pcall(hl.SetTexelSnappingBias, hl, 0)
	end
	frame.Highlight = hl
	local hasHL = ApplyAtlas(hl, "UI-HUD-ActionBar-Target-Highlight")

	if frame.CreateMaskTexture then
		local mask = frame:CreateMaskTexture()
		mask:SetPoint("CENTER")
		ApplyMask(mask, TARGET_MASK_ATLAS, TARGET_MASK_FILE, ButtonMaskSize(widget))
		if hl.AddMaskTexture then
			pcall(hl.AddMaskTexture, hl, mask)
		end
		frame.Mask = mask
	end

	local ag = frame:CreateAnimationGroup()
	ag:SetLooping("REPEAT")
	frame.HighlightAnim = ag
	local rot = ag:CreateAnimation("Rotation")
	rot:SetDuration(5)
	rot:SetOrder(1)
	rot:SetDegrees(360)
	if rot.SetOrigin then
		pcall(rot.SetOrigin, rot, "CENTER", 0, 0)
	end
	if rot.SetChildKey then
		pcall(rot.SetChildKey, rot, "Highlight")
	elseif rot.SetTarget then
		pcall(rot.SetTarget, rot, hl)
	end

	MixInto(frame, _G.ActionButtonTargetReticleFrameMixin)
	frame._fluxHasArt = (hasHL or hasBase) and true or false
	return frame
end

local function EnsureChild(widget, key, template, layout)
	if widget[key] then
		return widget[key], false
	end
	local ok, frame = pcall(CreateFrame, "Frame", nil, widget, template)
	if not ok or not frame then
		return nil, false
	end
	widget[key] = frame
	if layout then
		layout(frame)
	end
	return frame, true
end

local function EnsureInterruptDisplay(widget)
	if widget.InterruptDisplay then
		return widget.InterruptDisplay, false
	end
	local frame
	if HasAtlas(INTERRUPT_MASK_ATLAS) then
		local ok, created = pcall(CreateFrame, "Frame", nil, widget, "ActionButtonInterruptTemplate")
		if ok then
			frame = created
		end
	end
	if not frame then
		frame = BuildInterruptFrame(widget)
	end
	widget.InterruptDisplay = frame
	return frame, true
end

local function EnsureReticleFrame(widget)
	if widget.TargetReticleAnimFrame then
		return widget.TargetReticleAnimFrame, false
	end
	local frame
	if HasAtlas(TARGET_MASK_ATLAS) then
		local ok, created = pcall(CreateFrame, "Frame", nil, widget, "ActionButtonTargetReticleFrameTemplate")
		if ok then
			frame = created
		end
	end
	if not frame then
		frame = BuildReticleFrame(widget)
	end
	widget.TargetReticleAnimFrame = frame
	return frame, true
end

function Overlay.StopClassicFill(widget)
	if not widget then
		return
	end
	widget._fluxClassicKind = nil
	widget._fluxVfxMode = nil
	if widget._fluxCastFill then
		widget._fluxCastFill:Hide()
		widget._fluxCastFill:SetAlpha(FILL_ALPHA)
	end
	if widget._fluxInterruptFlash then
		widget._fluxInterruptFlash:Hide()
		widget._fluxInterruptFlash:SetAlpha(0.55)
	end
	if widget._fluxCastDriver then
		widget._fluxCastDriver:Hide()
		ApplyParentLevel(widget._fluxCastDriver, widget)
	end
end

local function HideDriverIfIdle(widget)
	if widget._fluxVfxMode then
		return
	end
	if widget._fluxCastDriver then
		widget._fluxCastDriver:Hide()
	end
end

function Overlay._classicOnUpdate(widget)
	if not widget then
		return
	end
	local mode = widget._fluxVfxMode
	if mode == "native" then
		Overlay._tickNativeFill(widget)
		return
	end
	local driver = widget._fluxCastDriver
	local tex = widget._fluxCastFill
	if mode == "interrupt" then
		local flash = widget._fluxInterruptFlash
		if not flash or not driver then
			return
		end
		local t = (GetTime() or 0) - (widget._fluxInterruptStart or 0)
		if t < INTERRUPT_HOLD then
			flash:SetAlpha(0.55)
			flash:Show()
			return
		end
		local fadeT = t - INTERRUPT_HOLD
		if fadeT < INTERRUPT_FADE then
			flash:SetAlpha(0.55 * (1 - fadeT / INTERRUPT_FADE))
			flash:Show()
			return
		end
		flash:Hide()
		widget._fluxVfxMode = nil
		HideCooldownCover(widget, false)
		HideDriverIfIdle(widget)
		return
	end
	if mode == "finish" then
		if not tex or not driver then
			return
		end
		local t = (GetTime() or 0) - (widget._fluxFinishStart or 0)
		local w = OverlayButtonWidth(widget)
		tex:ClearAllPoints()
		tex:SetPoint("TOPLEFT", driver, "TOPLEFT", 0, 0)
		tex:SetPoint("BOTTOMLEFT", driver, "BOTTOMLEFT", 0, 0)
		tex:SetWidth(math.max(1, w))
		if t < BURST_DURATION then
			tex:SetAlpha(0.55 * (1 - t / BURST_DURATION))
			tex:Show()
			return
		end
		tex:Hide()
		tex:SetAlpha(0.55)
		widget._fluxVfxMode = nil
		HideDriverIfIdle(widget)
		return
	end
	local kind = widget._fluxClassicKind
	if not kind or mode ~= "fill" then
		if mode == "native" then
			return
		end
		Overlay.StopClassicFill(widget)
		return
	end
	local startTime, endTime
	local vfxUnit = VfxUnit(widget)
	if kind == CHANNEL then
		local name, _, _, s, e = UnitChannelInfo(vfxUnit)
		if not name then
			return
		end
		startTime, endTime = CoerceTime(s), CoerceTime(e)
	else
		local name, _, _, s, e = UnitCastingInfo(vfxUnit)
		if not name then
			return
		end
		startTime, endTime = CoerceTime(s), CoerceTime(e)
	end
	if not startTime or not endTime then
		return
	end
	ApplyFillAboveCooldown(widget._fluxCastDriver, widget)
	local dur = endTime - startTime
	if dur <= 0 then
		return
	end
	local now = GetTime() * 1000
	local p = (now - startTime) / dur
	if p < 0 then
		p = 0
	elseif p > 1 then
		p = 1
	end
	if kind == CHANNEL then
		p = 1 - p
	end
	if not tex or not driver then
		return
	end
	local w = OverlayButtonWidth(widget)
	tex:ClearAllPoints()
	tex:SetPoint("TOPLEFT", driver, "TOPLEFT", 0, 0)
	tex:SetPoint("BOTTOMLEFT", driver, "BOTTOMLEFT", 0, 0)
	tex:SetWidth(math.max(1, w * p))
	tex:SetColorTexture(1, 0.95, 0.55, 1)
	tex:SetAlpha(FillAlphaForKind(kind))
	tex:Show()
end

local function EnsureClassicLayer(widget)
	local driver = widget._fluxCastDriver
	if not driver then
		local ok, created = pcall(CreateFrame, "Frame", nil, widget)
		if not ok or not created then
			return nil, nil
		end
		driver = created
		driver:SetAllPoints(widget)
		driver:Hide()
		if driver.EnableMouse then
			pcall(driver.EnableMouse, driver, false)
		end
		driver:SetScript("OnUpdate", function(self)
			local host = self.GetParent and self:GetParent() or widget
			if host and host._fluxVfxMode then
				Overlay._classicOnUpdate(host)
			end
		end)
		widget._fluxCastDriver = driver
	end
	ApplyFillAboveCooldown(driver, widget)
	-- Fill lives on the raised driver so the cooldown swipe still draws
	-- underneath. Mask keeps it in the icon.
	local tex = widget._fluxCastFill
	if not tex then
		tex = driver:CreateTexture(nil, "ARTWORK", nil, 1)
		tex:SetColorTexture(1, 0.95, 0.55, 1)
		tex:Hide()
		widget._fluxCastFill = tex
	end
	SetDraw(tex, "ARTWORK", 1)
	if tex.SetParent then
		pcall(tex.SetParent, tex, driver)
	end
	if tex.SetBlendMode then
		pcall(tex.SetBlendMode, tex, "BLEND")
	end
	local mask = widget.IconMask
	if mask and tex.AddMaskTexture then
		pcall(tex.AddMaskTexture, tex, mask)
	end
	return driver, tex
end

function Overlay.PlayClassicFill(widget, kind)
	if not widget or not VfxAllowed() then
		return
	end
	if widget._fluxInterruptFlash then
		widget._fluxInterruptFlash:Hide()
	end
	local driver, tex = EnsureClassicLayer(widget)
	if not driver then
		return
	end
	if tex then
		tex:SetColorTexture(1, 0.95, 0.55, 1)
	end
	widget._fluxClassicKind = kind or CAST
	widget._fluxVfxMode = "fill"
	driver:Show()
	Overlay._classicOnUpdate(widget)
end

function Overlay.PlayClassicFinish(widget)
	if not widget or not VfxAllowed() then
		return
	end
	if widget._fluxInterruptFlash then
		widget._fluxInterruptFlash:Hide()
	end
	local driver, tex = EnsureClassicLayer(widget)
	if not driver or not tex then
		return
	end
	widget._fluxClassicKind = nil
	widget._fluxVfxMode = "finish"
	HideCooldownCover(widget, false)
	widget._fluxFinishStart = GetTime() or 0
	local w = OverlayButtonWidth(widget)
	tex:ClearAllPoints()
	tex:SetPoint("TOPLEFT", driver, "TOPLEFT", 0, 0)
	tex:SetPoint("BOTTOMLEFT", driver, "BOTTOMLEFT", 0, 0)
	tex:SetWidth(math.max(1, w))
	tex:SetAlpha(0.55)
	tex:Show()
	driver:Show()
end

function Overlay.PlayClassicInterrupt(widget)
	if not widget or not VfxAllowed() then
		return
	end
	widget._fluxClassicKind = nil
	local driver = EnsureClassicLayer(widget)
	if not driver then
		return
	end
	local flash = widget._fluxInterruptFlash
	if not flash then
		flash = driver:CreateTexture(nil, "ARTWORK", nil, 3)
		flash:SetColorTexture(1, 0.2, 0.15, 0.55)
		widget._fluxInterruptFlash = flash
	end
	SetDraw(flash, "ARTWORK", 3)
	if flash.SetParent then
		pcall(flash.SetParent, flash, driver)
	end
	flash:ClearAllPoints()
	flash:SetAllPoints(driver)
	if widget._fluxCastFill then
		widget._fluxCastFill:Hide()
	end
	widget._fluxVfxMode = "interrupt"
	widget._fluxInterruptStart = GetTime() or 0
	local cdLevel = ShownCooldownLevel(widget)
	local base = (widget.GetFrameLevel and widget:GetFrameLevel()) or 0
	if driver.SetFrameLevel then
		pcall(driver.SetFrameLevel, driver, (cdLevel or base) + RETICLE_ABOVE_RING)
	end
	flash:SetAlpha(0.55)
	flash:Show()
	driver:Show()
	HideCooldownCover(widget, false)
end

local function ClearFillForBurst(widget, cf)
	if cf and cf.ApplyCastBarLayoutFromButton then
		pcall(cf.ApplyCastBarLayoutFromButton, cf, 0)
	end
	local fill = cf and cf.Fill
	if fill and fill.CastingAnim and fill.CastingAnim.Stop then
		Overlay._suppressBurstHide = true
		pcall(fill.CastingAnim.Stop, fill.CastingAnim)
		Overlay._suppressBurstHide = nil
	end
	if fill and fill.CastFill then
		if fill.CastFill.SetAlpha then
			pcall(fill.CastFill.SetAlpha, fill.CastFill, 0)
		end
		if fill.CastFill.Hide then
			pcall(fill.CastFill.Hide, fill.CastFill)
		end
	end
	if fill and fill.InnerGlowTexture then
		if fill.InnerGlowTexture.SetAlpha then
			pcall(fill.InnerGlowTexture.SetAlpha, fill.InnerGlowTexture, 0)
		end
		if fill.InnerGlowTexture.Hide then
			pcall(fill.InnerGlowTexture.Hide, fill.InnerGlowTexture)
		end
	end
	if fill and fill.CastDim and fill.CastDim.SetAlpha then
		pcall(fill.CastDim.SetAlpha, fill.CastDim, 0)
	end
	if fill and fill.CastSpark and fill.CastSpark.Hide then
		pcall(fill.CastSpark.Hide, fill.CastSpark)
	end
	HideChannelUnderlay(cf)
	if fill and fill.Hide then
		pcall(fill.Hide, fill)
	end
	if widget and widget._fluxCastFill then
		widget._fluxCastFill:Hide()
	end
end

--- Hide the swipe/glow fill. Does not hide EndBurst or the cast frame.
function Overlay.HideCastFill(widget)
	if not widget then
		return
	end
	Overlay.UnwatchNativeFill(widget)
	widget._fluxManualFill = nil
	widget.vfxCastData = nil
	if widget._fluxVfxMode == "native" then
		widget._fluxVfxMode = nil
	end
	ClearFillForBurst(widget, widget.SpellCastAnimFrame)
	local cf = widget.SpellCastAnimFrame
	if cf then
		ApplyParentLevel(cf, widget)
	end
	HideCooldownCover(widget, false)
end

--- Manual EndBurst. FinishAnimAndPlayBurst's CastingAnim:OnFinished would show
--- the flash while our CastFill is still on top — hide fill first, then play.
function Overlay.PlayBurst(widget)
	if not widget or not VfxAllowed() then
		return
	end
	local cf = widget.SpellCastAnimFrame
	local anim = cf and cf.EndBurst and cf.EndBurst.FinishCastAnim
	local playing = false
	if anim and anim.IsPlaying then
		local ok, v = pcall(anim.IsPlaying, anim)
		playing = ok and v and true or false
	end
	if playing and Overlay.IsLiveBurst(widget) then
		return
	end
	Overlay.HideCastFill(widget)
	cf = widget.SpellCastAnimFrame
	if not cf or not cf.EndBurst then
		Overlay.PlayClassicFinish(widget)
		return
	end
	HideCooldownCover(widget, false)
	LayoutCastFrame(widget, cf)
	Overlay._suppressBurstHide = true
	anim = cf.EndBurst.FinishCastAnim
	if anim and anim.Stop then
		pcall(anim.Stop, anim)
	end
	Overlay._suppressBurstHide = nil
	if cf.Show then
		pcall(cf.Show, cf)
	end
	if cf.EndBurst.Show then
		pcall(cf.EndBurst.Show, cf.EndBurst)
	end
	local glow = cf.EndBurst.GlowRing
	if glow then
		if glow.SetAlpha then
			pcall(glow.SetAlpha, glow, 1)
		end
		if glow.Show then
			pcall(glow.Show, glow)
		end
	end
	if anim and anim.Play then
		pcall(anim.Play, anim)
	end
	widget.actionButtonCastType = nil
	widget.vfxCastData = nil
	widget._fluxVfxMode = "finish"
	widget._fluxFinishStart = (GetTime and GetTime()) or 0
	Overlay.WatchNativeFill(widget)
end

function Overlay.PlayCast(widget, kind, skipSetup)
	if not widget or not VfxAllowed() then
		return
	end
	-- Keep _fluxVfxUnit so fill times stay on pet vs player.
	kind = kind or CAST
	widget.enableSpellFX = true
	widget.actionButtonCastType = kind
	widget._fluxInterruptSpell = nil
	widget._fluxInterruptFace = nil
	widget._fluxManualFill = true
	if widget.ClearInterruptDisplay then
		pcall(widget.ClearInterruptDisplay, widget)
	end
	if widget.ClearReticle then
		pcall(widget.ClearReticle, widget)
	end
	Overlay.UnwatchNativeFill(widget)
	Overlay.StopClassicFill(widget)
	local cf = widget.SpellCastAnimFrame
	local fillAtlas = (kind == CHANNEL) and "UI-HUD-ActionBar-Channel-Fill" or "UI-HUD-ActionBar-Cast-Fill"
	-- pre-DF classic fill when channel atlas missing
	if cf and cf.Fill and cf.Fill.CastFill and HasAtlas(fillAtlas) then
		LayoutCastFrame(widget, cf, true)
		-- skipSetup: appear mid-cast — do not restart Blizzard's t=0 translation.
		if cf.Setup and not skipSetup then
			pcall(cf.Setup, cf, kind)
		end
		-- Blizzard Setup plays CastFillTranslation from t=0. Duration 0 hides
		-- the frame before the next paint. Drive CastFill ourselves (LAB/backup).
		FreezeNativeAnim(cf)
		ApplyCastAtlas(cf, kind)
		LayoutCastFrame(widget, cf, true)
		local startTime, endTime = UnitCastTimes(kind, widget)
		if startTime and endTime then
			widget.vfxCastData = {
				start = startTime / 1000,
				duration = math.max(0.0001, (endTime - startTime) / 1000),
				type = kind,
			}
		elseif kind == CHANNEL or kind == EMPOWER then
			-- Channel/empower: no fake 0.0001s duration.
			-- Wait for UnitChannelInfo; ticker picks up times on the next tick.
			widget.vfxCastData = nil
		else
			widget.vfxCastData = {
				start = (GetTime and GetTime()) or 0,
				duration = 0.0001,
				type = kind,
			}
		end
		widget._fluxVfxMode = "native"
		Overlay.WatchNativeFill(widget)
		Overlay._tickNativeFill(widget)
		return
	end
	widget._fluxManualFill = nil
	-- Pre-DF / missing template: Classic slot fill (LAB has no SpellCastAnimFrame there).
	Overlay.PlayClassicFill(widget, kind)
end

function Overlay.StopCast(widget, interrupted)
	if not widget then
		return
	end
	Overlay.UnwatchNativeFill(widget)
	widget._fluxManualFill = nil
	if interrupted then
		-- Fill/channel gone before interrupt chrome. Do not leave CastFill or EndBurst.
		Overlay.HideCastFill(widget)
		Overlay._suppressBurstHide = true
		local cf = widget.SpellCastAnimFrame
		if cf then
			local burst = cf.EndBurst
			if burst then
				if burst.FinishCastAnim and burst.FinishCastAnim.Stop then
					pcall(burst.FinishCastAnim.Stop, burst.FinishCastAnim)
				end
				if burst.Hide then
					pcall(burst.Hide, burst)
				end
			end
		end
		HideNativeCast(widget)
		Overlay.StopClassicFill(widget)
		HideCooldownCover(widget, false)
		widget.actionButtonCastType = nil
		widget.vfxCastData = nil
		widget._fluxVfxMode = nil
		widget._fluxFinishStart = nil
		Overlay._suppressBurstHide = nil
		return
	end
	-- FinishAnimAndPlayBurst: PlayBurst owns EndBurst. Mixin Stop+OnFinished
	-- would show the flash while CastFill is still painted on top.
	if NativeFillPlaying(widget) or widget._fluxVfxMode == "native" or widget.vfxCastData then
		Overlay.PlayBurst(widget)
		return
	end
	if widget._fluxVfxMode == "fill" then
		Overlay.PlayClassicFinish(widget)
		widget.actionButtonCastType = nil
		widget.vfxCastData = nil
		return
	end
	HideNativeCast(widget)
	Overlay.StopClassicFill(widget)
	HideCooldownCover(widget, false)
	widget.actionButtonCastType = nil
	widget.vfxCastData = nil
	widget._fluxVfxMode = nil
end

local function KickInterruptAnim(display)
	if not display then
		return
	end
	-- Do not Stop() AnimIn: ActionButtonInterruptAnimInMixin OnFinished hides
	-- the whole display. Extra Buttons then fall through to the classic flash.
	-- Interrupt chrome is raised above the cooldown so both stay visible.
	local function play(anim)
		if not anim or not anim.Play then
			return
		end
		if anim.IsPlaying then
			local ok, playing = pcall(anim.IsPlaying, anim)
			if ok and playing then
				return
			end
		end
		pcall(anim.Play, anim)
	end
	local hl = display.Highlight
	play(hl and hl.AnimIn)
	local base = display.Base
	play(base and base.AnimIn)
end

local function EnsureInterruptSwipeHook(display)
	if not display or display._fluxSwipeHook then
		return
	end
	display._fluxSwipeHook = true
	if not display.HookScript then
		return
	end
	pcall(display.HookScript, display, "OnHide", function(self)
		if self._fluxRestarting then
			return
		end
		local parent = self.GetParent and self:GetParent()
		if parent then
			HideCooldownCover(parent, false)
			if parent._fluxVfxMode == "interrupt" then
				parent._fluxVfxMode = nil
			end
		end
	end)
end

function Overlay.PlayInterrupt(widget)
	if not widget or not VfxAllowed() then
		return
	end
	-- Keep _fluxVfxUnit (do not reset to player).
	Overlay.StopCast(widget, true)
	-- Keep the GCD/spell swipe running. Interrupt chrome sits above it.
	HideCooldownCover(widget, false)
	widget._fluxVfxMode = "interrupt"
	local display = widget.InterruptDisplay
	if display and not (display._fluxLuaSpellFX and not display._fluxHasArt) then
		LayoutInterruptDisplay(widget, display)
		EnsureInterruptSwipeHook(display)
		local shown = false
		if display.IsShown then
			local ok, v = pcall(display.IsShown, display)
			shown = ok and v and true or false
		end
		-- Backup ShowInterruptOnce: if already shown, do not Hide→Show restart.
		if shown then
			return
		end
		pcall(function()
			display:Show()
		end)
		-- Show() only. Do not Stop AnimIn — mixin OnFinished hides the frame.
		KickInterruptAnim(display)
		shown = false
		if display.IsShown then
			local ok, v = pcall(display.IsShown, display)
			shown = ok and v and true or false
		end
		if shown then
			return
		end
	end
	Overlay.PlayClassicInterrupt(widget)
end

function Overlay.PlayReticle(widget)
	if not widget or not VfxAllowed() then
		return
	end
	-- Keep _fluxVfxUnit (do not reset to player).
	-- Ground-target channel (Blizzard): SpellIsTargeting can stay true after
	-- CHANNEL_START. Do not tear down the live fill to show the reticle.
	if Overlay.IsLiveCast(widget) and not Overlay.IsLiveBurst(widget) then
		return
	end
	if widget._fluxVfxMode == "native" or widget._fluxVfxMode == "fill" then
		return
	end
	widget.enableSpellFX = true
	widget._fluxHadReticle = true
	Overlay.StopClassicFill(widget)
	HideNativeCast(widget)
	SetSwipeCasting(widget, false)
	Overlay.ReleasePress(widget)
	local reticle = widget.TargetReticleAnimFrame
	LayoutReticle(widget, reticle)
	if widget.PlayTargettingReticleAnim then
		pcall(widget.PlayTargettingReticleAnim, widget)
	end
	-- Idle ActionButtonTargetReticleFrameTemplate can sit shown; stamp live.
	widget._fluxReticleLive = true
	-- Gold checked and the 128px reticle must not stack on the same face.
	Overlay.ApplyChecked(widget, false)
end

local function StopReticleHighlight(widget)
	local reticle = widget and widget.TargetReticleAnimFrame
	if not reticle then
		return
	end
	local anim = reticle.HighlightAnim
	if anim and anim.Stop then
		pcall(anim.Stop, anim)
	end
	if reticle.Hide then
		pcall(reticle.Hide, reticle)
	end
end

function Overlay.ClearReticle(widget)
	if not widget then
		return
	end
	widget._fluxHadReticle = nil
	widget._fluxReticleLive = nil
	StopReticleHighlight(widget)
	if widget.ClearReticle then
		pcall(widget.ClearReticle, widget)
	end
	if widget.StopTargettingReticleAnim then
		pcall(widget.StopTargettingReticleAnim, widget)
	end
	StopReticleHighlight(widget)
end

local pressWatch
local pressedSet = {}

local function EnsurePressWatch()
	if pressWatch then
		return pressWatch
	end
	if not CreateFrame then
		return nil
	end
	pressWatch = CreateFrame("Frame")
	pressWatch:SetScript("OnEvent", function(self, event)
		if event ~= "GLOBAL_MOUSE_UP" then
			return
		end
		self:UnregisterEvent("GLOBAL_MOUSE_UP")
		-- Deferred: GLOBAL_MOUSE_UP lands before the button dispatches its
		-- mouse-up click. Clearing the pushed state inline would cancel it.
		local pending = {}
		for widget in pairs(pressedSet) do
			pending[#pending + 1] = widget
		end
		wipe(pressedSet)
		local function flush()
			for i = 1, #pending do
				Overlay.ReleasePress(pending[i])
			end
		end
		if C_Timer and C_Timer.After then
			C_Timer.After(0, flush)
		else
			flush()
		end
	end)
	return pressWatch
end

-- Targeting can steal mouse-up, leaving CheckButtons PUSHED (LAB GLOBAL_MOUSE_UP).
function Overlay.ForEachPressed(fn)
	if type(fn) ~= "function" then
		return
	end
	for widget in pairs(pressedSet) do
		fn(widget)
	end
end

function Overlay.NotePressed(widget)
	if not widget then
		return
	end
	pressedSet[widget] = true
	local watch = EnsurePressWatch()
	if watch then
		watch:RegisterEvent("GLOBAL_MOUSE_UP")
	end
end

function Overlay.ReleasePress(widget)
	if not widget then
		return
	end
	pressedSet[widget] = nil
	if widget.SetButtonState then
		pcall(widget.SetButtonState, widget, "NORMAL")
	end
	if widget.UnlockHighlight then
		pcall(widget.UnlockHighlight, widget)
	end
	local pushed = widget.PushedTexture or (widget.GetPushedTexture and widget:GetPushedTexture())
	if pushed and pushed.Hide then
		pcall(pushed.Hide, pushed)
	end
end

local CHECKED_HILIGHT = "Interface\\Buttons\\CheckButtonHilight"
local CHECKED_R, CHECKED_G, CHECKED_B, CHECKED_A = 1, 0.82, 0, 0.55

-- Extra Buttons inherit ActionButtonTemplate (not ActionBarButtonTemplate).
-- Live XML uses the mouseover atlas as CheckedTexture. Paint a gold region on
-- the button itself (same CheckButtonHilight + tint as the strip). Do not use
-- a raised holder: strip checked sits with the button textures, under cooldown.
-- The skin is constant apart from the owning button's size, so stamp it and
-- re-run only after an actual resize. This used to fire seven texture writes
-- per button on every checked paint across 57 strip hosts and every Extra face.
local function SkinCheckedTexture(tex, widget)
	if not tex or not widget then
		return
	end
	local w = (widget.GetWidth and widget:GetWidth()) or 36
	local h = (widget.GetHeight and widget:GetHeight()) or w
	if tex._fluxSkinOwner == widget and tex._fluxSkinW == w and tex._fluxSkinH == h then
		return
	end
	tex._fluxSkinOwner = widget
	tex._fluxSkinW = w
	tex._fluxSkinH = h
	if tex.SetTexture then
		tex:SetTexture(CHECKED_HILIGHT)
	end
	if tex.SetBlendMode then
		tex:SetBlendMode("ADD")
	end
	if tex.SetVertexColor then
		tex:SetVertexColor(CHECKED_R, CHECKED_G, CHECKED_B, CHECKED_A)
	end
	if tex.SetDrawLayer then
		tex:SetDrawLayer("OVERLAY", 6)
	end
	if tex.SetSize then
		tex:SetSize(w, h)
	end
	if tex.ClearAllPoints and tex.SetPoint then
		tex:ClearAllPoints()
		tex:SetPoint("CENTER", widget, "CENTER", 0, 0)
	end
end

--- C++ CheckButton can Show the hilight without Lua SetChecked (empty Extra
--- click, First Aid / Alchemy from RC). Hide it unless Extra paint asked for gold.
local function BindPaintOwnedChecked(widget, tex)
	if not widget or not tex or tex._fluxPaintOwnsShow or not tex.HookScript then
		return
	end
	tex._fluxPaintOwnsShow = true
	tex:HookScript("OnShow", function(t)
		if widget._fluxPaintChecked then
			return
		end
		t:Hide()
	end)
end

function Overlay.IsCheckedSuppressed(widget)
	local untilT = widget and widget._fluxSuppressCraftCheckedUntil
	return untilT and GetTime and GetTime() < untilT
end

local function EnsureGoldOverlay(widget)
	if not widget or not widget._fluxExtraButton then
		return nil
	end
	local ready = widget._fluxGoldChecked
	if ready and not widget._fluxGoldHolder and ready.GetParent and ready:GetParent() == widget then
		SkinCheckedTexture(ready, widget)
		BindPaintOwnedChecked(widget, ready)
		return ready
	end
	local holder = widget._fluxGoldHolder
	if holder then
		if holder.Hide then
			pcall(holder.Hide, holder)
		end
		widget._fluxGoldHolder = nil
	end
	local tex = widget._fluxGoldChecked
	if tex and tex.GetParent and tex:GetParent() ~= widget then
		if tex.Hide then
			pcall(tex.Hide, tex)
		end
		tex = nil
		widget._fluxGoldChecked = nil
	end
	if not tex then
		tex = widget:CreateTexture(nil, "OVERLAY", nil, 6)
		tex:Hide()
		widget._fluxGoldChecked = tex
	end
	SkinCheckedTexture(tex, widget)
	BindPaintOwnedChecked(widget, tex)
	return tex
end

-- Post-DF ActionButtonTemplate uses the mouseover atlas as checked. Gold is
-- CheckButtonHilight on every client (ButtonForge Bar.lua).
-- SetCheckedTexture swaps the region itself, so it only has to land once per
-- button. Re-running it every paint bought nothing and cost a texture rebuild.
function Overlay.EnsureCheckedTexture(widget)
	if not widget then
		return nil
	end
	local tex = widget._fluxCheckedTex
	if not tex or (tex.GetParent and tex:GetParent() ~= widget) then
		if widget.SetCheckedTexture then
			pcall(widget.SetCheckedTexture, widget, CHECKED_HILIGHT)
		end
		tex = widget.CheckedTexture or (widget.GetCheckedTexture and widget:GetCheckedTexture())
		widget._fluxCheckedTex = tex
	end
	SkinCheckedTexture(tex, widget)
	BindPaintOwnedChecked(widget, tex)
	local gold = EnsureGoldOverlay(widget)
	if gold then
		BindPaintOwnedChecked(widget, gold)
		return gold
	end
	return tex
end

--- User-visible gold, not the Lua cache. A skipped paint can leave the
--- CheckButtonHilight shown after _fluxCheckedApplied is already false.
--- A hidden extra gold overlay must not hide a C++ click lighting the
--- native CheckButton texture (empty Extra slots stay gold that way).
function Overlay.CheckedVisualOn(widget)
	if not widget then
		return false
	end
	local gold = widget._fluxGoldChecked
	if gold and gold.IsShown then
		local ok, shown = pcall(gold.IsShown, gold)
		if ok and shown then
			return true
		end
	end
	local tex = widget._fluxCheckedTex or widget.CheckedTexture
		or (widget.GetCheckedTexture and widget:GetCheckedTexture())
	if tex and tex.IsShown then
		local ok, shown = pcall(tex.IsShown, tex)
		if ok and shown then
			return true
		end
	end
	if widget.GetChecked then
		local ok, on = pcall(widget.GetChecked, widget)
		if ok and on then
			return true
		end
	end
	return false
end

function Overlay.ApplyChecked(widget, checked)
	if not widget or not widget.SetChecked then
		return
	end
	if Overlay.IsCheckedSuppressed(widget) then
		checked = false
	end
	checked = checked and true or false
	-- SetCheckedTexture while already checked can hide the region until the
	-- next SetChecked. Always install the texture first, then SetChecked.
	local tex = Overlay.EnsureCheckedTexture(widget)
	-- Authoritative stamp for callers that want to skip a redundant repaint.
	-- Every Flux writer goes through here, so the value cannot drift.
	-- Stamp paint-checked before SetChecked: Extra/strip occupancy lock
	-- SetChecked to Flux paint, and ignore C++ toggle / leftover mixin.
	widget._fluxCheckedApplied = checked
	widget._fluxPaintChecked = checked
	widget._fluxCheckedFromPaint = true
	pcall(widget.SetChecked, widget, checked)
	widget._fluxCheckedFromPaint = nil
	if tex then
		if checked then
			tex:Show()
		else
			tex:Hide()
		end
	end
	if widget._fluxExtraButton then
		local ct = widget._fluxCheckedTex or widget.CheckedTexture
			or (widget.GetCheckedTexture and widget:GetCheckedTexture())
		if ct and ct ~= tex and ct.Hide then
			ct:Hide()
		end
	end
end

function Overlay.IsPushed(widget)
	if not widget then
		return false
	end
	if pressedSet[widget] then
		return true
	end
	if widget.GetButtonState then
		local ok, state = pcall(widget.GetButtonState, widget)
		if ok and state == "PUSHED" then
			return true
		end
	end
	return false
end

--- Move PUSHED onto the visible host. Do not transfer gold checked:
--- each face paints independently (several actives can be gold at once).
function Overlay.FollowChrome(from, to)
	if not from or not to or from == to then
		return false
	end
	local moved = false
	local pushed = Overlay.IsPushed(from)
	if pushed then
		pressedSet[from] = nil
		pressedSet[to] = true
		local watch = EnsurePressWatch()
		if watch then
			watch:RegisterEvent("GLOBAL_MOUSE_UP")
		end
		if to.SetButtonState then
			pcall(to.SetButtonState, to, "PUSHED")
		end
		if from.SetButtonState then
			pcall(from.SetButtonState, from, "NORMAL")
		end
		local srcPushed = from.PushedTexture or (from.GetPushedTexture and from:GetPushedTexture())
		if srcPushed and srcPushed.Hide then
			pcall(srcPushed.Hide, srcPushed)
		end
		local destPushed = to.PushedTexture or (to.GetPushedTexture and to:GetPushedTexture())
		if destPushed and destPushed.Show then
			pcall(destPushed.Show, destPushed)
		end
		moved = true
	end
	return moved
end

function Overlay.ResetTargetChrome(widget)
	if not widget then
		return
	end
	Overlay.ReleasePress(widget)
	Overlay.ClearReticle(widget)
	if widget.SpellHighlightTexture then
		pcall(widget.SpellHighlightTexture.Hide, widget.SpellHighlightTexture)
	end
end

local function NoMouse(frame)
	if frame and frame.EnableMouse then
		pcall(frame.EnableMouse, frame, false)
	end
end

local function FrameShown(frame)
	if not frame or not frame.IsShown then
		return false
	end
	local ok, shown = pcall(frame.IsShown, frame)
	return ok and shown and true or false
end

local function FrameParentOf(frame)
	if not frame or not frame.GetParent then
		return nil
	end
	local ok, parent = pcall(frame.GetParent, frame)
	if ok then
		return parent
	end
	return nil
end

-- SetParent on a protected action-button child is blocked in combat. The
-- pcall succeeds as "handled" either way, so callers must verify the parent
-- before swapping Lua refs — otherwise ForceClear/PlayCast talk to the idle
-- frame while the live fill stays on the old row.
local function ReparentedTo(frame, host)
	if not frame or not host then
		return false
	end
	if not frame.GetParent then
		return true
	end
	return FrameParentOf(frame) == host
end

local function AnchorCenter(frame, host, extraLevel)
	if not frame or not host then
		return
	end
	pcall(frame.SetParent, frame, host)
	if frame.ClearAllPoints then
		pcall(frame.ClearAllPoints, frame)
	end
	pcall(frame.SetPoint, frame, "CENTER", host, "CENTER", 0, 0)
	ApplyParentLevel(frame, host)
	NoMouse(frame)
end

local function AnchorReticle(frame, host, extraLevel)
	LayoutReticle(host, frame)
	NoMouse(frame)
end

local function AnchorFill(frame, host, extraLevel)
	if not frame or not host then
		return
	end
	pcall(frame.SetParent, frame, host)
	if frame.ClearAllPoints then
		pcall(frame.ClearAllPoints, frame)
	end
	if frame.SetAllPoints then
		pcall(frame.SetAllPoints, frame, host)
	else
		pcall(frame.SetPoint, frame, "CENTER", host, "CENTER", 0, 0)
	end
	ApplyParentLevel(frame, host)
	NoMouse(frame)
end

local function AnchorInterrupt(frame, host, extraLevel)
	LayoutInterruptDisplay(host, frame)
	NoMouse(frame)
end

local function SwapKey(from, to, key, anchor)
	local live = from[key]
	if not live then
		return nil
	end
	local idle = to[key]
	if idle and idle ~= live and idle.Hide then
		pcall(idle.Hide, idle)
	end
	anchor(live, to, 10)
	if not ReparentedTo(live, to) then
		anchor(live, from, 10)
		if idle and idle ~= live then
			anchor(idle, to, 10)
			if idle.Show then
				pcall(idle.Show, idle)
			end
		end
		return nil
	end
	from[key] = idle
	to[key] = live
	if idle then
		anchor(idle, from, 10)
	end
	return live
end

local function BindClassicDriver(driver, widget)
	if not driver or not driver.SetScript then
		return
	end
	pcall(driver.SetScript, driver, "OnUpdate", function()
		Overlay._classicOnUpdate(widget)
	end)
end

local function AdoptClassicArt(tex, widget, sub)
	if not tex or not widget then
		return
	end
	if tex.SetParent then
		pcall(tex.SetParent, tex, widget)
	end
	SetDraw(tex, "ARTWORK", sub or 2)
end

local function TransferClassicDriver(from, to)
	local driver = from._fluxCastDriver
	if not driver then
		return false
	end
	local idle = to._fluxCastDriver
	local idleFill = to._fluxCastFill
	local idleFlash = to._fluxInterruptFlash
	AnchorFill(driver, to)
	if not ReparentedTo(driver, to) then
		AnchorFill(driver, from)
		return false
	end
	to._fluxCastDriver = driver
	to._fluxCastFill = from._fluxCastFill
	to._fluxInterruptFlash = from._fluxInterruptFlash
	from._fluxCastDriver = idle
	from._fluxCastFill = idleFill
	from._fluxInterruptFlash = idleFlash
	AdoptClassicArt(to._fluxCastFill, to, 2)
	AdoptClassicArt(to._fluxInterruptFlash, to, 3)
	BindClassicDriver(driver, to)
	if driver.Show then
		pcall(driver.Show, driver)
	end
	if idle and idle ~= driver then
		AnchorFill(idle, from)
		AdoptClassicArt(idleFill, from, 2)
		AdoptClassicArt(idleFlash, from, 3)
		BindClassicDriver(idle, from)
		if idle.Hide then
			pcall(idle.Hide, idle)
		end
	end
	return true
end

local function TakeCastFlags(from, to)
	to.enableSpellFX = true
	to.actionButtonCastType = from.actionButtonCastType
	to.vfxCastData = from.vfxCastData
	to._fluxVfxMode = from._fluxVfxMode
	to._fluxClassicKind = from._fluxClassicKind
	to._fluxFinishStart = from._fluxFinishStart
	to._fluxInterruptStart = from._fluxInterruptStart
	to._fluxCastSpell = from._fluxCastSpell
	to._fluxInterruptSpell = from._fluxInterruptSpell
	to._fluxInterruptFace = from._fluxInterruptFace
	from.actionButtonCastType = nil
	from.vfxCastData = nil
	from._fluxVfxMode = nil
	from._fluxClassicKind = nil
	from._fluxFinishStart = nil
	from._fluxInterruptStart = nil
	from._fluxCastSpell = nil
	from._fluxInterruptSpell = nil
	from._fluxInterruptFace = nil
	from.hideCooldownFrame = nil
end

function Overlay.IsLiveBurst(widget)
	if not widget then
		return false
	end
	if EndBurstShown(widget) then
		return true
	end
	if widget._fluxVfxMode == "finish" and widget._fluxCastFill then
		return true
	end
	return false
end

function Overlay.IsLiveCast(widget)
	if not widget then
		return false
	end
	if Overlay.IsLiveBurst(widget) then
		return true
	end
	local mode = widget._fluxVfxMode
	if mode == "fill" then
		return true
	end
	if widget.vfxCastData then
		return true
	end
	if NativeFillPlaying(widget) then
		return true
	end
	if mode == "native" then
		return FrameShown(widget.SpellCastAnimFrame)
	end
	return false
end

function Overlay.IsLiveReticle(widget)
	if not widget then
		return false
	end
	if widget._fluxReticleLive then
		return true
	end
	local rf = widget.TargetReticleAnimFrame
	if not rf then
		return false
	end
	-- Hidden ActionButtonTargetReticleFrameTemplate can keep HighlightAnim
	-- looping after a stray Setup(); that must not suppress gold on extras.
	if not FrameShown(rf) then
		return false
	end
	local anim = rf.HighlightAnim
	if anim and anim.IsPlaying then
		local ok, playing = pcall(anim.IsPlaying, anim)
		if ok and playing then
			return true
		end
	end
	return false
end

function Overlay.IsLiveInterrupt(widget)
	if not widget then
		return false
	end
	if widget._fluxVfxMode == "interrupt" then
		return true
	end
	return FrameShown(widget.InterruptDisplay)
end

-- Interrupt chrome is raised above the cooldown. Never hide the swipe so
-- GCD/spell CD and the kick can show at the same time.
function Overlay.ShouldHideCooldown(widget)
	return false
end

--- Hide fill/interrupt/burst/reticle without playing kick or finish.
function Overlay.ForceClear(widget)
	if not widget then
		return
	end
	Overlay._clearing = true
	Overlay._suppressBurstHide = true
	Overlay.UnwatchNativeFill(widget)
	widget._fluxManualFill = nil
	local cf = widget.SpellCastAnimFrame
	if cf then
		local fillAnim = cf.Fill and cf.Fill.CastingAnim
		if fillAnim and fillAnim.Stop then
			pcall(fillAnim.Stop, fillAnim)
		end
		local burstAnim = cf.EndBurst and cf.EndBurst.FinishCastAnim
		if burstAnim and burstAnim.Stop then
			pcall(burstAnim.Stop, burstAnim)
		end
		if cf.EndBurst and cf.EndBurst.Hide then
			pcall(cf.EndBurst.Hide, cf.EndBurst)
		end
	end
	HideNativeCast(widget)
	Overlay.StopClassicFill(widget)
	HideCooldownCover(widget, false)
	if widget.InterruptDisplay and widget.InterruptDisplay.Hide then
		pcall(widget.InterruptDisplay.Hide, widget.InterruptDisplay)
	end
	widget.actionButtonCastType = nil
	widget.vfxCastData = nil
	widget._fluxVfxMode = nil
	widget._fluxFinishStart = nil
	widget._fluxCastSpell = nil
	widget._fluxInterruptSpell = nil
	widget._fluxInterruptFace = nil
	widget._fluxCastLockSpellId = nil
	widget._fluxCastMigrateUntil = nil
	Overlay._suppressBurstHide = nil
	Overlay._clearing = nil
	Overlay.ClearReticle(widget)
end

--- Continue or appear at live UnitCastingInfo progress. skipSetup so paging
--- does not restart the fill from t=0.
function Overlay.SyncCast(widget, kind)
	if not widget then
		return
	end
	if Overlay.IsLiveBurst(widget) then
		return
	end
	if Overlay.IsLiveCast(widget) then
		if widget._fluxVfxMode == "fill" or widget._fluxVfxMode == "finish" then
			Overlay._classicOnUpdate(widget)
			return
		end
		widget._fluxManualFill = true
		widget._fluxVfxMode = widget._fluxVfxMode or "native"
		Overlay.WatchNativeFill(widget)
		Overlay._tickNativeFill(widget)
		return
	end
	Overlay.PlayCast(widget, kind, true)
end

function Overlay.SyncInterrupt(widget)
	if not widget then
		return
	end
	-- Cast/channel fill must be gone while interrupt chrome is up.
	-- Cooldown swipe stays (interrupt sits above it).
	Overlay.StopCast(widget, true)
	if Overlay.IsLiveInterrupt(widget) then
		return
	end
	Overlay.PlayInterrupt(widget)
end

function Overlay.SyncBurst(widget)
	if not widget then
		return
	end
	Overlay.HideCastFill(widget)
	if Overlay.IsLiveBurst(widget) then
		return
	end
	Overlay.PlayBurst(widget)
end

--- Drive dest fill after transfer/appear. Native ticker or classic OnUpdate.
function Overlay.TickFill(widget)
	if not widget then
		return
	end
	local mode = widget._fluxVfxMode
	if mode == "native" then
		Overlay.WatchNativeFill(widget)
		Overlay._tickNativeFill(widget)
		return
	end
	Overlay._classicOnUpdate(widget)
end

--- Reparent the live fill. Do not restart the fill animation.
function Overlay.TransferCast(from, to)
	if not from or not to or from == to then
		return false
	end
	if Overlay.IsLiveBurst(from) then
		Overlay._transferring = true
		local live = SwapKey(from, to, "SpellCastAnimFrame", AnchorCenter)
		Overlay._transferring = nil
		if not live then
			return false
		end
		TakeCastFlags(from, to)
		to._fluxVfxMode = "finish"
		HideCooldownCover(to, false)
		HideCooldownCover(from, false)
		LayoutCastFrame(to, live)
		if live.Show then
			pcall(live.Show, live)
		end
		if live.EndBurst and live.EndBurst.Show then
			pcall(live.EndBurst.Show, live.EndBurst)
		end
		Overlay.UnwatchNativeFill(from)
		Overlay.UnwatchNativeFill(to)
		return true
	end
	if not Overlay.IsLiveCast(from) then
		return false
	end
	local mode = from._fluxVfxMode
	if mode == "fill" or mode == "finish" then
		if not TransferClassicDriver(from, to) then
			return false
		end
		TakeCastFlags(from, to)
		if mode == "fill" then
			ApplyFillAboveCooldown(to._fluxCastDriver, to)
			HideCooldownCover(from, false)
		else
			HideCooldownCover(to, false)
			HideCooldownCover(from, false)
		end
		Overlay.UnwatchNativeFill(from)
		Overlay.TickFill(to)
		return true
	end
	Overlay._transferring = true
	local live = SwapKey(from, to, "SpellCastAnimFrame", AnchorCenter)
	Overlay._transferring = nil
	if not live then
		return false
	end
	TakeCastFlags(from, to)
	to._fluxVfxMode = to._fluxVfxMode or "native"
	HideCooldownCover(from, false)
	FreezeNativeAnim(live)
	LayoutCastFrame(to, live, true)
	if live.Show then
		pcall(live.Show, live)
	end
	Overlay.UnwatchNativeFill(from)
	Overlay.TickFill(to)
	return true
end

function Overlay.TransferReticle(from, to)
	if not from or not to or from == to then
		return false
	end
	if not Overlay.IsLiveReticle(from) then
		return false
	end
	Overlay._transferring = true
	local live = SwapKey(from, to, "TargetReticleAnimFrame", AnchorReticle)
	Overlay._transferring = nil
	if not live then
		return false
	end
	to._fluxHadReticle = true
	from._fluxHadReticle = nil
	to._fluxReticleLive = true
	from._fluxReticleLive = nil
	to.enableSpellFX = true
	if live.Show then
		pcall(live.Show, live)
	end
	StopReticleHighlight(from)
	return true
end

function Overlay.TransferInterrupt(from, to)
	if not from or not to or from == to then
		return false
	end
	if not Overlay.IsLiveInterrupt(from) then
		return false
	end
	if from._fluxVfxMode == "interrupt" then
		if not TransferClassicDriver(from, to) then
			return false
		end
		TakeCastFlags(from, to)
		to._fluxVfxMode = "interrupt"
		HideCooldownCover(to, false)
		HideCooldownCover(from, false)
		return true
	end
	Overlay._transferring = true
	local live = SwapKey(from, to, "InterruptDisplay", AnchorInterrupt)
	Overlay._transferring = nil
	if not live then
		return false
	end
	to._fluxInterruptSpell = from._fluxInterruptSpell or from._fluxCastSpell
	to._fluxInterruptFace = from._fluxInterruptFace or to._fluxInterruptFace
	from._fluxInterruptSpell = nil
	from._fluxInterruptFace = nil
	LayoutInterruptDisplay(to, live)
	if live.Show then
		pcall(live.Show, live)
	end
	HideCooldownCover(to, false)
	HideCooldownCover(from, false)
	to._fluxVfxMode = "interrupt"
	if from._fluxVfxMode == "interrupt" then
		from._fluxVfxMode = nil
	end
	return true
end

function Overlay.Transfer(from, to)
	if not from or not to or from == to then
		return false
	end
	local any = false
	if Overlay.IsLiveCast(from) then
		any = Overlay.TransferCast(from, to) or any
	end
	if Overlay.IsLiveReticle(from) then
		any = Overlay.TransferReticle(from, to) or any
	end
	if Overlay.IsLiveInterrupt(from) then
		any = Overlay.TransferInterrupt(from, to) or any
	end
	if any then
		if Overlay.IsLiveCast(to) and not Overlay.IsLiveBurst(to) then
			Overlay.TickFill(to)
		end
	end
	return any
end

local SPELLCAST_EVENTS = {
	"UNIT_SPELLCAST_START",
	"UNIT_SPELLCAST_STOP",
	"UNIT_SPELLCAST_SUCCEEDED",
	"UNIT_SPELLCAST_FAILED",
	"UNIT_SPELLCAST_INTERRUPTED",
	"UNIT_SPELLCAST_CHANNEL_START",
	"UNIT_SPELLCAST_CHANNEL_STOP",
	"UNIT_SPELLCAST_EMPOWER_START",
	"UNIT_SPELLCAST_EMPOWER_STOP",
	"UNIT_SPELLCAST_RETICLE_TARGET",
	"UNIT_SPELLCAST_RETICLE_CLEAR",
	"UNIT_SPELLCAST_SENT",
}

-- Dummy action 10000 / template OnLoad would play reticle on every Extra Button.
-- Drop every collector; do not replace mixin CheckNeedsUpdate /
-- RegisterActionBarButtonCheckFrames — those Flux closures taint
-- ActionBarButtonEventsFrame:OnEvent → UpdateAction → SetAttribute.
local function SilenceMixinVFX(widget)
	if not widget then
		return
	end
	for i = 1, #SPELLCAST_EVENTS do
		if widget.UnregisterEvent then
			pcall(widget.UnregisterEvent, widget, SPELLCAST_EVENTS[i])
		end
	end
	if Flux.Action and Flux.Action.DetachFromCollectors then
		Flux.Action.DetachFromCollectors(widget)
	end
	widget.MatchesActiveButtonSpellID = function()
		return false
	end
	NoMouse(widget.SpellCastAnimFrame)
	NoMouse(widget.TargetReticleAnimFrame)
	NoMouse(widget.InterruptDisplay)
	NoMouse(widget.cooldown)
	NoMouse(widget.chargeCooldown)
end

function Overlay.Attach(widget)
	if not widget or widget._fluxOverlayAttached then
		return widget
	end
	widget._fluxOverlayAttached = true
	widget.enableSpellFX = true

	InstallStubs(widget)

	if ButtonFX.Charges and ButtonFX.Charges.Ensure
		and not (InCombatLockdown and InCombatLockdown()) then
		ButtonFX.Charges.Ensure(widget)
	end
	if widget.chargeCooldown and widget.chargeCooldown.Hide then
		pcall(widget.chargeCooldown.Hide, widget.chargeCooldown)
	end

	-- Existing ActionBarButtonTemplate children: override OnHide immediately.
	if widget.SpellCastAnimFrame then
		OverrideSpellCastAnimScripts(widget.SpellCastAnimFrame)
		if widget.SpellCastAnimFrame.EndBurst then
			widget.SpellCastAnimFrame.EndBurst:SetScript("OnHide", function() end)
			rawset(widget.SpellCastAnimFrame.EndBurst, "OnHide", function() end)
		end
	end

	EnsureInterruptDisplay(widget)
	if widget.InterruptDisplay then
		local frame = widget.InterruptDisplay
		LayoutInterruptDisplay(widget, frame)
		NoMouse(frame)
		frame:Hide()
	end

	local castFrame = widget.SpellCastAnimFrame
	if not castFrame then
		castFrame = EnsureChild(widget, "SpellCastAnimFrame", "ActionButtonCastingAnimFrameTemplate", function(frame)
			OverrideSpellCastAnimScripts(frame)
			if frame.EndBurst then
				frame.EndBurst:SetScript("OnHide", function() end)
				rawset(frame.EndBurst, "OnHide", function() end)
			end
			frame:SetPoint("CENTER", widget, "CENTER", 0, 0)
			ApplyParentLevel(frame, widget)
			ApplyParentLevel(frame.Fill, frame)
			ApplyParentLevel(frame.EndBurst, frame)
			NoMouse(frame)
			frame:Hide()
		end)
	else
		OverrideSpellCastAnimScripts(castFrame)
		ApplyParentLevel(castFrame, widget)
		ApplyParentLevel(castFrame.Fill, castFrame)
		ApplyParentLevel(castFrame.EndBurst, castFrame)
	end

	EnsureReticleFrame(widget)
	if widget.TargetReticleAnimFrame then
		local frame = widget.TargetReticleAnimFrame
		LayoutReticle(widget, frame)
		NoMouse(frame)
		frame:Hide()
	end

	SilenceMixinVFX(widget)
	local GlowMod = ButtonFX.Glow
	if GlowMod and GlowMod.SilenceMixin then
		GlowMod.SilenceMixin(widget)
	end
	local FlashMod = ButtonFX.Flash
	if FlashMod and FlashMod.Ensure then
		FlashMod.Ensure(widget)
	end
	-- Pre-create the classic fill driver OOC so a combat SyncCast fallback
	-- does not have to CreateFrame a child of a protected action button.
	if not (InCombatLockdown and InCombatLockdown()) then
		EnsureClassicLayer(widget)
	end

	return widget
end
