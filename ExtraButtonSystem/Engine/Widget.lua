-- ExtraButtonSystem/Engine/Widget.lua — one FluxButton primitive
-- kind extra: Extra window / pet / stance (dummy action=10000, Extra paint)
-- kind badge: corner rank (visual only, Extra CD paint, no Extra hop index)
-- kind strip: occupancy host (type=action|click, Bars.Paint, skip Extra list)
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS

local Widget = {}
EBS.Widget = Widget

function Widget.SyncCVars()
	if Flux.ButtonFX and Flux.ButtonFX.Click and Flux.ButtonFX.Click.SyncCVars then
		Flux.ButtonFX.Click.SyncCVars()
	end
end

local function ResolveChild(widget, key, suffix)
	if widget[key] then
		return widget[key]
	end
	local name = widget.GetName and widget:GetName()
	if name then
		return _G[name .. suffix]
	end
	return nil
end

local SEQ = 1

local function ApplyClickWrap(widget)
	if Flux.ButtonFX and Flux.ButtonFX.Click and Flux.ButtonFX.Click.Apply then
		return Flux.ButtonFX.Click.Apply(widget)
	end
	widget:RegisterForClicks("AnyUp")
	return true
end

function Widget.ResolveKind(config)
	config = config or {}
	if config.kind == "strip" or config.kind == "badge" or config.kind == "extra" then
		return config.kind
	end
	if config.badgeMode then
		return "badge"
	end
	if config.occupancy or config.stripMode then
		return "strip"
	end
	return "extra"
end

local function HideFlyoutChrome(w)
	if w.FlyoutBorder then
		w.FlyoutBorder:Hide()
	end
	if w.FlyoutBorderShadow then
		w.FlyoutBorderShadow:Hide()
	end
	if w.FlyoutArrow then
		w.FlyoutArrow:Hide()
	end
	if w.FlyoutArrowContainer then
		w.FlyoutArrowContainer:Hide()
	end
	if w.Arrow then
		w.Arrow:Hide()
	end
	if w._fluxNativeFlyoutHost then
		w._fluxNativeFlyoutHost:Hide()
	end
end

-- Mixin Arrow defaults to OVERLAY 2; Extra slot rings are OVERLAY 6.
-- Keep the chevron on the button (not UIParent/HIGH) so Extra chrome stays above it.
local NATIVE_ARROW_DRAW = 7

local function RestoreNativeFlyoutParent(region, widget)
	if region and region.SetParent and widget then
		pcall(region.SetParent, region, widget)
	end
end

local function LayerNativeFlyoutArrow(widget)
	local arrow = widget.Arrow or widget.FlyoutArrow
	RestoreNativeFlyoutParent(arrow, widget)
	if arrow and arrow.SetDrawLayer then
		pcall(arrow.SetDrawLayer, arrow, "OVERLAY", NATIVE_ARROW_DRAW)
	end
	local container = widget.FlyoutArrowContainer
	RestoreNativeFlyoutParent(container, widget)
	if container then
		if container.FlyoutArrowNormal and container.FlyoutArrowNormal.SetDrawLayer then
			pcall(container.FlyoutArrowNormal.SetDrawLayer, container.FlyoutArrowNormal, "OVERLAY", NATIVE_ARROW_DRAW)
		end
		if container.FlyoutArrowPushed and container.FlyoutArrowPushed.SetDrawLayer then
			pcall(container.FlyoutArrowPushed.SetDrawLayer, container.FlyoutArrowPushed, "OVERLAY", NATIVE_ARROW_DRAW)
		end
		if container.FlyoutArrowHighlight and container.FlyoutArrowHighlight.SetDrawLayer then
			pcall(container.FlyoutArrowHighlight.SetDrawLayer, container.FlyoutArrowHighlight, "OVERLAY", NATIVE_ARROW_DRAW)
		end
		if container.SetFrameLevel and widget.GetFrameLevel then
			pcall(container.SetFrameLevel, container, (widget:GetFrameLevel() or 0) + 1)
		end
	end
	if widget._fluxNativeFlyoutHost then
		widget._fluxNativeFlyoutHost:Hide()
	end
end

local function LockSetChecked(widget)
	if widget._fluxCheckedLocked then
		return
	end
	widget._fluxCheckedLocked = true
	widget._fluxPaintChecked = false
	local nativeSetChecked = widget.SetChecked
	if not nativeSetChecked then
		return
	end
	widget.SetChecked = function(w, checked)
		local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
		local on
		if ov and ov.IsCheckedSuppressed and ov.IsCheckedSuppressed(w) then
			on = false
		elseif w._fluxCheckedFromPaint then
			on = checked and true or false
		else
			on = w._fluxPaintChecked and true or false
		end
		nativeSetChecked(w, on)
		local ct = w.CheckedTexture or (w.GetCheckedTexture and w:GetCheckedTexture())
		if ct and ct.Hide then
			pcall(ct.Hide, ct)
		end
		local gold = w._fluxGoldChecked
		if gold then
			local show = on
			if show and ov and ov.IsLiveReticle and ov.IsLiveReticle(w) then
				show = false
			end
			if show then
				pcall(gold.Show, gold)
			else
				pcall(gold.Hide, gold)
			end
		end
	end
end

local function BindChrome(widget)
	if widget.TextOverlayContainer and widget.TextOverlayContainer.SetFrameLevel then
		pcall(widget.TextOverlayContainer.SetFrameLevel, widget.TextOverlayContainer, (widget:GetFrameLevel() or 0) + 1)
	end
	if widget.TextOverlayContainer and widget.TextOverlayContainer.EnableMouse then
		pcall(widget.TextOverlayContainer.EnableMouse, widget.TextOverlayContainer, false)
	end
	if widget.SetHitRectInsets then
		widget:SetHitRectInsets(0, 0, 0, 0)
	end
	if widget.SlotArt then
		widget.SlotArt:Hide()
	end
	-- SlotBackground is UI-Quickslot; SizeRing hides it so it does not double the plate.
	-- Forever/DF SlotArt+SlotBackground are IconFrame plates SizeRing replaces.
	if widget.SlotBackground then
		widget.SlotBackground:Hide()
	end
	if widget.NewActionTexture then
		widget.NewActionTexture:Hide()
	end
	if widget.SpellHighlightTexture then
		widget.SpellHighlightTexture:Hide()
	end
	-- Leave HighlightTexture on the C++ HIGHLIGHT layer (ButtonForge).
	HideFlyoutChrome(widget)
end

local function BindParts(self, widget)
	self.Widget = widget
	self.WIcon = ResolveChild(widget, "icon", "Icon")
	self.WNormalTexture = widget.NormalTexture
		or (widget.GetNormalTexture and widget:GetNormalTexture())
		or ResolveChild(widget, "NormalTexture", "NormalTexture")
	self.WCooldown = widget.cooldown or ResolveChild(widget, "cooldown", "Cooldown")
	if self.WCooldown and self.WCooldown.EnableMouse then
		pcall(self.WCooldown.EnableMouse, self.WCooldown, false)
	end
	self.WCount = (widget.TextOverlayContainer and widget.TextOverlayContainer.Count)
		or ResolveChild(widget, "Count", "Count")
	self.WBorder = ResolveChild(widget, "Border", "Border")
	self.WFlashTexture = ResolveChild(widget, "Flash", "Flash")
	self.WHotKey = (widget.TextOverlayContainer and widget.TextOverlayContainer.HotKey)
		or ResolveChild(widget, "HotKey", "HotKey")
	self.WName = ResolveChild(widget, "Name", "Name")
	if self.WIcon then
		self.WIcon:ClearAllPoints()
		self.WIcon:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 0)
		self.WIcon:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", 0, 0)
		self.WIcon:SetTexCoord(0, 1, 0, 1)
	end
	if self.WHotKey then
		self.WHotKey:SetText("")
		self.WHotKey:Hide()
	end
	if self.WName and not self.macroText then
		self.WName:SetText("")
		self.WName:Hide()
	end
	if self.WBorder then
		self.WBorder:Hide()
	end
	if self.WFlashTexture then
		self.WFlashTexture:Hide()
	end
	if self.WNormalTexture and not self.showBorder then
		self.WNormalTexture:SetAlpha(0)
	end
end

local function BindOverlayCast(self, config)
	local widget = self.Widget
	local FX = Flux.ButtonFX
	if not (config and config.skipOverlay) then
		if FX and FX.Overlay and FX.Overlay.Attach then
			FX.Overlay.Attach(widget)
		end
		if FX and FX.Overlay and FX.Overlay.EnsureCheckedTexture then
			FX.Overlay.EnsureCheckedTexture(widget)
		end
	end
	if config and config.skipCast then
		return
	end
	if not (FX and FX.Cast and FX.Cast.Register) then
		return
	end
	local rank
	if self.kind == "badge" or self.badgeMode then
		rank = FX.Cast.RANK_BADGE
	elseif self.kind == "strip" then
		local row = config and config.row
		rank = (row == "main" or row == nil) and FX.Cast.RANK_MAIN or FX.Cast.RANK_MINI
		if row == "sec" or row == "tert" then
			rank = FX.Cast.RANK_MINI
		end
	else
		rank = FX.Cast.RANK_EBS
	end
	if self.kind == "strip" then
		FX.Cast.Register(widget, function(w)
			local host = w._fluxHost
			-- host.slot is the visible occupant. The action attribute freezes
			-- at combat entry on clients that cannot ChildUpdate, so VFX that
			-- keyed off that attribute stayed on the row the fight started on.
			local slot
			local Hosts = Flux.Bars and Flux.Bars.Hosts
			if Hosts and Hosts.LiveSlot and host then
				slot = Hosts.LiveSlot(host)
			elseif host then
				slot = host.slot
			end
			if not slot then
				slot = tonumber(w.GetAttribute and w:GetAttribute("action"))
					or tonumber(w.action)
			end
			return FX.SpellIdFromAction and FX.SpellIdFromAction(slot)
		end, rank, config and config.castUnit)
		return
	end
	FX.Cast.Register(widget, function(w)
		local btn = w.FluxButton
		return FX.SpellIdFromEBS and FX.SpellIdFromEBS(btn)
	end, rank, config and config.castUnit)
end

-- Lua OnEnter is tooltip-only. C++ CheckButton owns HighlightTexture.
local function ApplyTooltipScripts(self)
	local widget = self.Widget
	if widget.EnableMouse then
		pcall(widget.EnableMouse, widget, true)
	end
	widget:SetScript("OnEnter", function()
		if self.TooltipEnabled == false or self.tooltipEnabled == false then
			return
		end
		if EBS.Action and EBS.Action.OnEnter then
			EBS.Action.OnEnter(self)
		end
	end)
	widget:SetScript("OnLeave", function()
		if EBS.Action and EBS.Action.OnLeave then
			EBS.Action.OnLeave(self)
		else
			local Guard = _G.FluxTooltipGuard
			if Guard and Guard.HideForButton then
				Guard.HideForButton(self)
			elseif GameTooltip then
				GameTooltip:Hide()
			end
		end
	end)
end

local function ApplyExtraScripts(self)
	local widget = self.Widget
	if not widget._fluxExtraPressHooked then
		widget:HookScript("OnMouseDown", function(w)
			local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
			if ov and ov.NotePressed then
				ov.NotePressed(w)
			end
		end)
		widget._fluxExtraPressHooked = true
	end
	widget:SetScript("OnDragStart", function()
		if EBS.Action and EBS.Action.OnDragStart then
			EBS.Action.OnDragStart(self)
		end
	end)
	widget:SetScript("OnReceiveDrag", function()
		if EBS.Action and EBS.Action.OnReceiveDrag then
			EBS.Action.OnReceiveDrag(self)
		end
	end)
	local function WrapClicks()
		local Click = Flux.ButtonFX and Flux.ButtonFX.Click
		if Click and Click.UsesWrap then
			return Click.UsesWrap()
		end
		return true
	end
	widget:SetScript("PreClick", function(w, button, down)
		if InCombatLockdown and InCombatLockdown() then
			return
		end
		if not WrapClicks() then
			return
		end
		if button == "KeyBind" or button == "ConjureBind" or down then
			return
		end
		if GetCursorInfo and GetCursorInfo() then
			w._backupType = w:GetAttribute("type")
			w._backupTypeRelease = w:GetAttribute("typerelease")
			w:SetAttribute("type", "")
			w:SetAttribute("typerelease", "")
			w._hasCursorItem = true
		end
	end)
	widget:SetScript("PostClick", function(w, _, down)
		if WrapClicks() and w._hasCursorItem and not down then
			if w._backupType then
				w:SetAttribute("type", w._backupType)
				w:SetAttribute("typerelease", w._backupTypeRelease or w._backupType)
			end
			w._backupType = nil
			w._backupTypeRelease = nil
			w._hasCursorItem = nil
			if EBS.Action and EBS.Action.OnReceiveDrag then
				EBS.Action.OnReceiveDrag(self)
			end
		end
		if not down then
			local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
			if ov and ov.ReleasePress then
				ov.ReleasePress(w)
			end
			Widget.AfterClickPaint(self, w, down)
		end
	end)
end

--- Extra PostClick paint (checked, CD, reticle). Used by Extra-window scripts
--- and skipScripts hosts (NC grid flyout openers).
function Widget.AfterClickPaint(btn, widget, down)
	if down or not btn then
		return
	end
	widget = widget or btn.Widget
	if not widget then
		return
	end
	local okT, targeting = false, false
	if SpellIsTargeting then
		okT, targeting = pcall(SpellIsTargeting)
	end
	if okT and targeting then
		widget._fluxHadReticle = true
		if Flux.ButtonFX and Flux.ButtonFX.Cast and Flux.ButtonFX.Cast.NoteTargeting then
			Flux.ButtonFX.Cast.NoteTargeting(widget)
		end
	end
	if EBS.Paint and EBS.Paint.UpdateChecked then
		EBS.Paint.UpdateChecked(btn)
	end
	-- Empty extras have no current-spell face. C++ CheckButton still
	-- toggles after PostClick, so the gold hilight would stick until
	-- the next occupied paint. Clear again next frame.
	if (not btn.ActionType or not btn.ActionValue) and C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			if btn and EBS.Paint and EBS.Paint.UpdateChecked then
				EBS.Paint.UpdateChecked(btn)
			end
		end)
	end
	if EBS.Paint and EBS.Paint.RequestCheckedSettle then
		EBS.Paint.RequestCheckedSettle()
	end
	if EBS.Paint and EBS.Paint.UpdateCooldown then
		EBS.Paint.UpdateCooldown(btn)
	end
end

--- skipScripts extras (NC grid, HUD trinkets): Extra press/cast/checked/CD
--- without Extra-window drag/pickup. Left-click only notes press so middle/
--- right (mode toggle / flyout) do not steal the fill.
function Widget.BindLockedExtraHost(btn)
	if not btn or not btn.Widget then
		return false
	end
	local widget = btn.Widget
	local Click = Flux.ButtonFX and Flux.ButtonFX.Click
	if Click and Click.Apply then
		if Click.Apply(widget, { onDown = true }) == false then return false end
	end
	if not widget._fluxLockedExtraHostHooked then
		widget._fluxLockedExtraHostHooked = true
		widget:HookScript("OnMouseDown", function(w, button)
			if button ~= "LeftButton" then
				return
			end
			local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
			if ov and ov.NotePressed then
				ov.NotePressed(w)
			end
		end)
		widget:HookScript("PostClick", function(w, button, down)
			if button == "LeftButton" and not down then
				local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
				if ov and ov.ReleasePress then
					ov.ReleasePress(w)
				end
			end
			-- HUD craft is on-down; C++ CheckButton would leave gold if we wait for up.
			-- Do not AfterClickPaint: RequestCheckedSettle would re-gold after First Aid opens.
			if button == "RightButton" then
				local Bridge = _G.FluxEBSConsumableBridge
				if Bridge and Bridge.SuppressCheckedVisualSettle then
					Bridge.SuppressCheckedVisualSettle(btn)
				elseif Bridge and Bridge.SuppressCheckedVisual then
					Bridge.SuppressCheckedVisual(btn)
				end
				return
			end
			Widget.AfterClickPaint(btn, w, down)
		end)
	end
	local G = Flux.ButtonFX and Flux.ButtonFX.Glow
	if G and G.NotifySAO then
		G.NotifySAO(widget)
	end
	return true
end

--- Attach a FluxButton env to an existing CheckButton (strip occupancy wrapper).
function Widget.Attach(widget, config)
	if not widget then
		return nil
	end
	config = config or {}
	local kind = Widget.ResolveKind(config)
	if widget.FluxButton and widget.FluxButton.kind == kind and widget.FluxButton._fluxWidgetAttached then
		return widget.FluxButton
	end

	local FluxButton = _G.FluxButton
	local self = widget.FluxButton or setmetatable({}, FluxButton)
	widget.FluxButton = self
	widget.ParentButton = self
	self.kind = kind
	self.config = config
	self.showBorder = config.showBorder and true or false
	self.tooltipEnabled = config.tooltip ~= false
	self.macroText = config.macroText and true or false
	self.badgeMode = (kind == "badge") or (config.badgeMode and true or false)
	self.locked = config.locked and true or false
	if kind == "strip" then
		self._fluxStripFace = true
		widget._fluxOccupancy = true
	elseif kind == "extra" then
		widget._fluxExtraButton = true
	end

	LockSetChecked(widget)
	BindParts(self, widget)
	BindChrome(widget)

	if kind == "extra" then
		local emptyBG = self.WEmptyBG
		if not emptyBG then
			emptyBG = widget:CreateTexture(nil, "BACKGROUND", nil, -8)
			emptyBG:SetTexture("Interface\\Buttons\\UI-EmptySlot-Disabled")
			emptyBG:SetPoint("CENTER", widget, "CENTER")
			local sz = widget.GetWidth and widget:GetWidth() or 0
			if type(sz) ~= "number" or sz < 1 then
				sz = config.size or 32
			end
			emptyBG:SetSize(sz * 1.5, sz * 1.5)
			emptyBG:SetAlpha(0.85)
			emptyBG:Hide()
			self.WEmptyBG = emptyBG
		end
	end

	if self.badgeMode then
		widget:EnableMouse(false)
		pcall(widget.RegisterForClicks, widget)
		pcall(widget.RegisterForDrag, widget)
	end

	-- skipScripts only skips Extra-window drag/pickup. NC grid / HUD trinket
	-- hosts still get mouseover-cast like Extra slots.
	if not self.badgeMode and kind ~= "strip" and not config.skipMouseover then
		local MC = Flux.MouseoverCast
		if MC and MC.RegisterButton then
			MC.RegisterButton(widget)
		end
	end

	-- skipScripts skips Extra-window drag/pickup only. Tooltip scripts stay
	-- on every Extra host; C++ CheckButton owns the native slot highlight.
	if kind == "extra" and not self.badgeMode and not config.skipHover then
		ApplyTooltipScripts(self)
	end

	if not config.skipScripts and kind == "extra" then
		if ApplyClickWrap(widget) == false then return nil end
		ApplyExtraScripts(self)
	end

	BindOverlayCast(self, config)

	if kind == "extra" then
		EBS.RegisterButton(self)
		if EBS.Paint and EBS.Paint.UpdateEmpty then
			EBS.Paint.UpdateEmpty(self)
		end
	elseif kind == "badge" then
		if EBS.RegisterBadge then
			EBS.RegisterBadge(self)
		end
	end

	if config.autocast and EBS.Paint and EBS.Paint.EnsureAutocast then
		EBS.Paint.EnsureAutocast(self)
	end
	if kind ~= "badge" and EBS.Flyout and EBS.Flyout.BindHost then
		EBS.Flyout.BindHost(widget, {
			direction = (widget.GetAttribute and widget:GetAttribute("flyoutDirection"))
				or config.flyoutDirection
				or "UP",
		})
	end
	self._fluxWidgetAttached = true
	return self
end

function Widget.Create(parent, config)
	config = config or {}
	if InCombatLockdown and InCombatLockdown() then
		return nil
	end

	local kind = Widget.ResolveKind(config)
	config.kind = kind
	if kind == "badge" then
		config.badgeMode = true
	end

	local name = config.name
	if type(name) ~= "string" or name == "" then
		name = "FluxEBSButton" .. SEQ
		SEQ = SEQ + 1
	end
	local existing = _G[name]
	if existing and existing.FluxButton and existing.FluxButton._fluxWidgetCreated then
		if existing.FluxButton.kind ~= kind then return nil end
		return existing.FluxButton
	end

	local template = "ActionButtonTemplate, SecureActionButtonTemplate"
	local C = Flux.Client
	if kind == "strip" and C and C.isPostDF and not C.isAnyClassic and not (C.isCamelot or C.isForever) then
		template = "ActionBarButtonTemplate, SecureActionButtonTemplate"
	end
	local function create()
		-- Named frames survive a failed initializer. Reconfigure that same
		-- surface on retry instead of allocating a second immutable name.
		local created = existing or CreateFrame("CheckButton", name, parent or UIParent, template)
		if created then
			created.eventsRegistered = true
		end
		return created
	end
	local widget
	if Flux.Action and Flux.Action.WithRegistrationSuppressed then
		widget = Flux.Action.WithRegistrationSuppressed(create)
	else
		widget = create()
	end
	widget:SetSize(config.size or 32, config.size or 32)
	local loadedAction = widget.action

	if kind ~= "strip" then
		widget.action = 10000
		widget._fluxExtraButton = (kind == "extra")
	else
		widget._fluxOccupancy = true
	end

	if widget.UnregisterAllEvents then
		widget:UnregisterAllEvents()
	end
	widget:SetScript("OnEvent", nil)
	widget:SetScript("OnHide", nil)
	widget:SetScript("OnShow", function(w)
		local btn = w.FluxButton
		if btn and btn.kind == "strip" then
			return
		end
		if btn and btn.ActionType and EBS.Paint and EBS.Paint.RequestShown then
			EBS.Paint.RequestShown(btn)
		end
	end)
	if not (Flux.Action.LeaveBlizzardCollector and Flux.Action.LeaveBlizzardCollector()) then
		Flux.Action.DetachFromCollectors(widget, loadedAction)
	end
	if kind ~= "strip" and widget.UnregisterActionBarButtonCheckFrames then
		pcall(widget.UnregisterActionBarButtonCheckFrames, widget, 10000)
	end
	widget.eventsRegistered = true

	if kind ~= "strip" then
		function widget:UpdateFlyout()
			local btn = self.FluxButton
			if not btn or btn.ActionType ~= "flyout" then
				HideFlyoutChrome(self)
				if self.ClearPopup then
					pcall(self.ClearPopup, self)
				else
					self.popup = nil
				end
				return
			end
			local dir = self:GetAttribute("flyoutDirection") or "UP"
			if self.SetPopupDirection then
				pcall(self.SetPopupDirection, self, dir)
			else
				self.popupDirection = dir
			end
			if SpellFlyout then
				if self.SetPopup then
					pcall(self.SetPopup, self, SpellFlyout)
				else
					self.popup = SpellFlyout
				end
			end
			LayerNativeFlyoutArrow(self)
			if self.FlyoutArrowContainer then
				self.FlyoutArrowContainer:Show()
			elseif self.Arrow then
				self.Arrow:Show()
			elseif self.FlyoutArrow then
				self.FlyoutArrow:Show()
			end
		end
		widget:SetScript("OnAttributeChanged", function(w)
			if w.UpdateFlyout then
				pcall(w.UpdateFlyout, w)
			end
		end)
	end

	function widget:UpdateCooldown()
		local btn = self.FluxButton
		if btn and btn.kind == "strip" then
			return
		end
		if btn and EBS.Paint and EBS.Paint.UpdateCooldown then
			EBS.Paint.UpdateCooldown(btn)
		end
	end

	widget:SetAttribute("checkselfcast", true)
	widget:SetAttribute("checkfocuscast", true)
	widget:SetAttribute("checkmouseovercast", false)
	if kind == "strip" then
		widget:SetAttribute("type", "action")
		widget:SetAttribute("typerelease", "action")
		widget:SetAttribute("useparent-actionpage", false)
	else
		widget:SetAttribute("useparent-actionpage", true)
	end
	widget:SetAttribute("flyoutDirection", widget:GetAttribute("flyoutDirection") or "UP")
	-- Explicit skipScripts (HUD trinkets) plus strip/badge: no Extra-window
	-- drag/tooltip scripts, and no dummy-action pickup.
	local skipScripts = config.skipScripts or (kind == "strip") or (kind == "badge")
	config.skipScripts = skipScripts and true or false
	if kind ~= "badge" and not skipScripts then
		widget:RegisterForDrag("LeftButton", "RightButton")
	end
	local button = Widget.Attach(widget, config)
	if button then button._fluxWidgetCreated = true end
	return button
end
