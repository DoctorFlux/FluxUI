-- Bars/Hosts.lua — 19 Flux secure mains plus column registry.
--
-- Own ActionBarButtonTemplate (post-DF) / ActionButtonTemplate (Classic) hosts.
-- Stock ActionButton1-12 stay hidden; keys click-route onto these widgets.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Hosts = {}
Bars.Hosts = Hosts

-- Columns 13–19 borrow unused extra-bar commands (same keys as the defaults pack).
-- BlizzardOptions relabels these as Action Button 13–19. Do not invent ACTIONBUTTON13+.
local BORROWED_BINDING_ORDER = {
	"MULTIACTIONBAR2BUTTON8",
	"MULTIACTIONBAR2BUTTON9",
	"MULTIACTIONBAR2BUTTON10",
	"MULTIACTIONBAR2BUTTON11",
	"MULTIACTIONBAR2BUTTON12",
	"MULTIACTIONBAR4BUTTON8",
	"MULTIACTIONBAR4BUTTON9",
}

local BORROWED_BINDING = {}
local BORROWED_BINDING_SET = {}
for i = 1, #BORROWED_BINDING_ORDER do
	local cmd = BORROWED_BINDING_ORDER[i]
	BORROWED_BINDING[12 + i] = cmd
	BORROWED_BINDING_SET[cmd] = true
end

Hosts.BorrowedBindingOrder = BORROWED_BINDING_ORDER
Hosts.BorrowedBindingSet = BORROWED_BINDING_SET

local slotIndex = {}
local built = false

-- Minirow widgets are SetScale(0.5). Count font is enlarged so stack/charge
-- digits stay readable on that half-size face. Badges use the same on-screen size.
Hosts.MINI_WIDGET_SCALE = 0.5

function Hosts.MiniCountFontSize()
	return math.floor(((Flux.Client and Flux.Client.isPostDF) and 19 or 16) * 1.6)
end

local function AsRegion(value)
	if type(value) == "table" then
		return value
	end
	return nil
end

local function ResolveChild(widget, key, suffix)
	local direct = AsRegion(widget[key])
	if direct then
		return direct
	end
	local name = widget.GetName and widget:GetName()
	if name then
		return AsRegion(_G[name .. suffix])
	end
	return nil
end

function Hosts.ResolveParts(host)
	local widget = host.widget
	if not widget then
		return
	end
	local overlay = AsRegion(widget.TextOverlayContainer)
	host.WIcon = ResolveChild(widget, "icon", "Icon")
	host.WCooldown = AsRegion(widget.cooldown) or ResolveChild(widget, "cooldown", "Cooldown")
	-- Create the recharge edge OOC. First combat use cannot CreateFrame/SetPoint
	-- a child on a secure action button.
	if not (InCombatLockdown and InCombatLockdown()) then
		local FX = Flux.ButtonFX and Flux.ButtonFX.Charges
		if FX and FX.Ensure then
			FX.Ensure(widget)
		end
	end
	host.WCount = (overlay and AsRegion(overlay.Count)) or ResolveChild(widget, "Count", "Count")
	host.WHotKey = (overlay and AsRegion(overlay.HotKey)) or ResolveChild(widget, "HotKey", "HotKey")
	host.WBorder = ResolveChild(widget, "Border", "Border")
	host.WName = (overlay and AsRegion(overlay.Name)) or ResolveChild(widget, "Name", "Name")
	host.WNormalTexture = widget.NormalTexture
		or (widget.GetNormalTexture and widget:GetNormalTexture())
		or ResolveChild(widget, "NormalTexture", "NormalTexture")
end

function Hosts.BindingCommand(column)
	if column <= Bars.NUM_NATIVE then
		return "ACTIONBUTTON" .. column
	end
	return BORROWED_BINDING[column]
end

--- Indexed slot is the strip page/form occupant. CHILDUPDATE can lag one
--- frame behind IndexSlot; painting from the action attribute then keeps the
--- previous page's icon (ghost noform on bonus/override).
function Hosts.LiveSlot(host)
	if not host then
		return nil
	end
	if host.slot then
		return host.slot
	end
	local widget = host.widget
	if widget and widget.GetAttribute then
		local attr = tonumber(widget:GetAttribute("action"))
		if attr then
			return attr
		end
	end
	return widget and widget.action or nil
end

function Hosts.IndexSlot(host, newSlot)
	local old = host.slot
	if old and slotIndex[old] then
		local list = slotIndex[old]
		for i = #list, 1, -1 do
			if list[i] == host then
				table.remove(list, i)
			end
		end
	end
	host.slot = newSlot
	if host.widget then
		host.widget.action = newSlot
	end
	if newSlot then
		local list = slotIndex[newSlot]
		if not list then
			list = {}
			slotIndex[newSlot] = list
		end
		list[#list + 1] = host
	end
end

function Hosts.ForSlot(slot)
	return slotIndex[slot]
end

local function OnActionAttribute(widget, name, value)
	if name ~= "action" then
		return
	end
	local host = widget._fluxHost
	if not host then
		return
	end
	local slot = tonumber(value)
	-- SyncNativeHostSlots can IndexSlot before this fires. Still rebind the
	-- face: skipping ApplyLiveType left noform Identity on the bonus slot.
	if slot ~= host.slot then
		Hosts.IndexSlot(host, slot)
	elseif host._fluxFaceSlot == slot then
		return
	end
	local HL = Flux.HopLag
	local timed = HL and HL.enabled
	if timed then
		HL.Begin("attr.action", "root")
		HL.Count("attr.action")
	end
	-- Form burst used to skip ApplyLiveType; overlay Identity/_fluxFace then
	-- stayed on the previous form until settle (~0.25s). Rebind here; click
	-- type is CHILDUPDATE (ApplyLiveType SetAttribute is already combat-gated).
	local SP = Bars.SlotProgram
	if SP and SP.ApplyLiveType then
		SP.ApplyLiveType(host)
	else
		local PF = Bars.ProgramFace
		if PF and PF.TranslateHost then
			PF.TranslateHost(host)
		end
	end
	local contextOwns = false
	local C = Flux.Context
	if C and C.HasSubscribers and C.HasSubscribers() then
		contextOwns = true
	end
	-- One Watch MODIFIER paint flushes every swapped host. RequestPaint here
	-- scheduled a second eval before Context display could merge.
	if contextOwns and Bars.Paint and Bars.Paint.MarkDirty then
		Bars.Paint.MarkDirty(host)
	elseif Bars.Paint and Bars.Paint.Dirty then
		Bars.Paint.Dirty(host)
	elseif Bars.Paint and Bars.Paint.ClearCache then
		Bars.Paint.ClearCache(host)
		Bars.RequestPaint("bars")
	end
	local FormStorm = Flux.FormStorm
	local bursting = FormStorm and FormStorm.IsBursting and FormStorm.IsBursting()
	if not bursting then
		-- CHILDUPDATE just stamped the new slot. Context OnContext often
		-- SyncShownFaces before that, so badges were still painted on the
		-- previous row. Rehome this host now. Do not NotifyModifierPaging
		-- while Context owns: that deferred 57-host walk races Identity.
		local BadgeHost = Bars.BadgeHost or ns.FluxBadgeHost
		if BadgeHost and BadgeHost.NotifyDisplay then
			BadgeHost.NotifyDisplay(host)
		end
		if not contextOwns then
			if BadgeHost and BadgeHost.NotifyModifierPaging then
				BadgeHost.NotifyModifierPaging()
			end
		end
		-- Context owns overlay [mod] parse, not identity VFX. Fill/reticle/
		-- interrupt/burst have to leave with the spell on this attribute hop,
		-- including in combat when SetParent transfer will fall back to SyncCast.
		if Bars.Effects and Bars.Effects.Refresh then
			Bars.Effects.Refresh(host)
		end
	end
	if timed then
		HL.Stop("attr.action")
	end
end

--- Ellesmere detach: leave the collector, keep mixin methods stock.
--- Flux OnEvent/Update/UpdateSpellAlert closures on a widget still in
--- ActionBarButtonEventsFrame.frames taint the rest of that pairs loop
--- (OverrideActionBarButtonN:SetAttribute in combat).
local function DetachMixinEvents(widget)
	if widget.UnregisterEvent then
		pcall(widget.UnregisterEvent, widget, "ACTIONBAR_SLOT_CHANGED")
		pcall(widget.UnregisterEvent, widget, "ACTIONBAR_UPDATE_COOLDOWN")
		pcall(widget.UnregisterEvent, widget, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
		pcall(widget.UnregisterEvent, widget, "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
	end
	-- Forever: the widget was never inserted. Niling the shared collector taints
	-- gamepad buttons' pressAndHoldAction, then UseAction is forbidden.
	if not (Flux.Action.LeaveBlizzardCollector and Flux.Action.LeaveBlizzardCollector()) then
		Flux.Action.DetachFromCollectors(widget)
	end
	-- Mixin Update() re-RegisterFrame when eventsRegistered is nil. Stay off.
	widget.eventsRegistered = true
	if widget.SetScript then
		widget:SetScript("OnEvent", nil)
	end
end

local function ButtonTemplate()
	local C = Flux.Client
	-- Forever's art-only template avoids touching Blizzard's shared event
	-- collectors. The secure OnClick and v8 input registration stay the same.
	if C and C.isPostDF and not C.isAnyClassic and not (C.isCamelot or C.isForever) then
		return "ActionBarButtonTemplate, SecureActionButtonTemplate"
	end
	return "ActionButtonTemplate, SecureActionButtonTemplate"
end

local function CurrentSlot(widget)
	local host = widget and widget._fluxHost
	if host then
		return Hosts.LiveSlot(host)
	end
	if widget and widget.GetAttribute then
		return tonumber(widget:GetAttribute("action"))
	end
	return nil
end

local hoverWidget = nil

local function PeekingUf()
	local km = _G.FluxMouseoverKeybindModule or ns.FluxMouseoverKeybind
	return km and km.IsHovercastPeekMouseContext and km:IsHovercastPeekMouseContext() and true or false
end

local function ShownFace(widget)
	local host = widget and widget._fluxHost
	local slot = CurrentSlot(widget)
	if PeekingUf() then
		local PF = Bars.ProgramFace
		if host and PF and PF.Shown then
			return PF.Shown(host)
		end
	end
	local Identity = Flux.Identity
	if slot and Identity and Identity.Get and Identity.SlotKey then
		local kind, id = Identity.Get(Identity.SlotKey(slot))
		if kind then
			return kind, id
		end
	end
	local face = host and host._fluxFaceSlot == slot and host._fluxFace
	if face then
		if face.MacroMode == "spell" and face.SpellId then
			return "spell", face.SpellId
		end
		if face.MacroMode == "item" and face.ItemId then
			return "item", face.ItemId
		end
	end
	local PF = Bars.ProgramFace
	if slot and PF and PF.ShownForSlot then
		return PF.ShownForSlot(slot)
	end
	return nil
end

local function IdsMatch(a, b)
	if a == nil or b == nil then
		return false
	end
	if a == b then
		return true
	end
	local Match = Flux.Spell and Flux.Spell.IdsMatch
	if Match then
		return Match(a, b) and true or false
	end
	return tonumber(a) == tonumber(b)
end

local function NativeActionKindId(slot)
	slot = tonumber(slot)
	if not slot or slot <= 0 or not GetActionInfo then
		return nil
	end
	local ok, actionType, id, subType = pcall(GetActionInfo, slot)
	if not ok or not actionType then
		return nil
	end
	if actionType == "spell" and id then
		return "spell", id
	end
	if (actionType == "item" or actionType == "toy") and id then
		return "item", id
	end
	if actionType == "macro" then
		if subType == "spell" and id and id > 0 then
			return "spell", id
		end
		if GetMacroSpell then
			local sid = GetMacroSpell(id)
			sid = tonumber(sid)
			if sid and sid > 0 then
				return "spell", sid
			end
		end
		if GetMacroItem then
			local _, link = GetMacroItem(id)
			if type(link) == "string" then
				local iid = tonumber(link:match("item:(%d+)"))
				if iid then
					return "item", iid
				end
			end
		end
	end
	if actionType == "mount" then
		return "mount", id
	end
	if actionType == "flyout" then
		return "flyout", id
	end
	return actionType, id
end

local function TooltipSetSpell(id)
	if not GameTooltip or id == nil then
		return false
	end
	local sid = id
	if Flux.Spell and Flux.Spell.GetOverrideSpell then
		sid = Flux.Spell.GetOverrideSpell(sid) or sid
	end
	if type(sid) == "number" and GameTooltip.SetSpellByID then
		return pcall(GameTooltip.SetSpellByID, GameTooltip, sid)
	end
	if type(id) == "string" and GameTooltip.SetSpellByName then
		return pcall(GameTooltip.SetSpellByName, GameTooltip, id)
	end
	return false
end

local function TooltipSetItem(id)
	if not GameTooltip or not id then
		return false
	end
	if Flux.Inventory and Flux.Inventory.Find then
		local locs = Flux.Inventory.Find(id, {
			bags = true,
			bank = false,
			warband = false,
			equipped = true,
			includeBank = false,
		})
		if type(locs) == "table" then
			for i = 1, #locs do
				local loc = locs[i]
				if loc then
					if loc.region == "equip" and loc.slot and GameTooltip.SetInventoryItem then
						local ok = pcall(GameTooltip.SetInventoryItem, GameTooltip, "player", loc.slot)
						if ok then
							return true
						end
					elseif loc.bag ~= nil and loc.slot ~= nil and GameTooltip.SetBagItem then
						local ok = pcall(GameTooltip.SetBagItem, GameTooltip, loc.bag, loc.slot)
						if ok then
							return true
						end
					end
				end
			end
		end
	end
	if GameTooltip.SetItemByID then
		local ok = pcall(GameTooltip.SetItemByID, GameTooltip, id)
		if ok then
			return true
		end
	end
	if GameTooltip.SetHyperlink then
		return pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. tostring(id))
	end
	return false
end

local function AnchorTooltip(widget)
	local SetHUD = ns.SetHUDTooltipOwner or _G.FluxSetHUDTooltipOwner
	if SetHUD and SetHUD(GameTooltip, widget) then
		return
	end
	if GetCVar and GetCVar("UberTooltips") == "1" and GameTooltip_SetDefaultAnchor then
		GameTooltip_SetDefaultAnchor(GameTooltip, widget)
		return
	end
	GameTooltip:SetOwner(widget, "ANCHOR_RIGHT")
end

--- Native occupancy uses SetAction (same as pre-rewrite LAB). Overlay /
--- Identity faces that are not that occupancy use SetSpellByID / SetItemByID.
function Hosts.UpdateTooltip(widget)
	if not widget or not GameTooltip then
		return
	end
	if GameTooltip.IsForbidden and GameTooltip:IsForbidden() then
		return
	end
	local slot = CurrentSlot(widget)
	AnchorTooltip(widget)
	if FluxTooltipGuard and FluxTooltipGuard.Reset then
		FluxTooltipGuard.Reset(GameTooltip)
	elseif FluxTooltipGuard and FluxTooltipGuard.Unblock then
		FluxTooltipGuard.Unblock(GameTooltip)
	end
	local kind, id = ShownFace(widget)
	local nk, nid = NativeActionKindId(slot)
	local useFace = kind and id and (not nk or kind ~= nk or not IdsMatch(id, nid))
	local shown = false
	if useFace then
		if kind == "spell" then
			shown = TooltipSetSpell(id)
		elseif kind == "item" then
			shown = TooltipSetItem(id)
		end
	end
	if not shown and slot and GameTooltip.SetAction then
		shown = pcall(GameTooltip.SetAction, GameTooltip, slot)
	end
	-- Retail SetSpellByID/SetAction often return nil even when the tip shows.
	if shown or (GameTooltip.IsShown and GameTooltip:IsShown()) then
		GameTooltip:Show()
		local BT = ns.FluxBindingTooltip or _G.FluxBindingTooltip
		if BT and BT.OnLabTooltip then
			BT.OnLabTooltip(widget)
		elseif BT and BT.AppendForButton then
			BT.AppendForButton(widget)
		end
	end
end

function Hosts.RefreshHoverTooltip()
	if not hoverWidget then
		return
	end
	if not GameTooltip or not GameTooltip.GetOwner or GameTooltip:GetOwner() ~= hoverWidget then
		return
	end
	Hosts.UpdateTooltip(hoverWidget)
end

--- row = "main" | "sec" | "tert"
function Hosts.CreateSurface(column, row, name, parent)
	local widget = _G[name]
	if not widget then
		local function create()
			local ok, created = pcall(CreateFrame, "CheckButton", name, parent, ButtonTemplate())
			if not ok or not created then
				ok, created = pcall(CreateFrame, "CheckButton", name, parent,
					"ActionButtonTemplate, SecureActionButtonTemplate")
			end
			if ok and created then
				-- Before any later Update() can RegisterFrame.
				created.eventsRegistered = true
			end
			return ok, created
		end
		local ok, created
		if Flux.Action and Flux.Action.WithRegistrationSuppressed then
			ok, created = Flux.Action.WithRegistrationSuppressed(create)
		else
			ok, created = create()
		end
		if not ok or not created then
			return nil
		end
		widget = created
	elseif parent and widget.SetParent then
		widget:SetParent(parent)
	end
	widget.eventsRegistered = true

	local size = Bars.CONFIG.buttonSize
	widget:SetSize(size, size)
	-- ID>0 makes CalculateAction ignore the ChildUpdate "action" attribute and
	-- use actionpage / shift-actionpage (or C_ActionBar.GetActionBarPage() when
	-- useparent lookup misses). After a combat vehicle exit that fallback is
	-- page 1, so SHIFT still casts the nomod main spell. Ellesmere: SetID(0)
	-- so the click uses action / shift-action. Cannot SetID in combat.
	if widget.SetID then
		widget:SetID(0)
	end
	DetachMixinEvents(widget)
	-- Replace mixin OnAttributeChanged BEFORE any SetAttribute. Mixin
	-- OnAttributeChanged → UpdateFlyout → bar:GetSpellFlyoutDirection().
	-- Never assign widget.bar to a Flux header: it is not an ActionBar, and
	-- that nil call taints the button (UseAction forbidden on click).
	-- HookScript would still run the mixin (Update → SetCooldown secrets).
	if widget.SetScript and not widget._fluxActionHooked then
		widget._fluxActionHooked = true
		widget:SetScript("OnAttributeChanged", OnActionAttribute)
	end

	widget._fluxBarSlotIndex = column
	widget._fluxBarRow = row

	widget:SetAttribute("type", "action")
	widget:SetAttribute("typerelease", "action")
	widget:SetAttribute("useparent-actionpage", false)
	widget:SetAttribute("useparent-unit", true)
	widget:SetAttribute("checkselfcast", true)
	widget:SetAttribute("checkfocuscast", true)
	-- Wrap clients: native checkmouseovercast + CVar is the world-sweep hitch.
	-- PreClick covers click. Forever restamps true from MouseoverCast.ApplyNativeCheck.
	widget:SetAttribute("checkmouseovercast", false)
	widget:SetAttribute("flyoutDirection", "UP")
	widget:RegisterForDrag("LeftButton", "RightButton")

	local EBS = Flux.EBS
	if EBS and EBS.Widget and EBS.Widget.Attach then
		EBS.Widget.Attach(widget, {
			kind = "strip",
			skipScripts = true,
			row = row,
			size = size,
			tooltip = true,
			macroText = row == "main",
			showBorder = true,
		})
	end
	if EBS and EBS.Flyout and EBS.Flyout.BindHost then
		EBS.Flyout.BindHost(widget, { direction = "UP" })
	end

	if Bars.Clicks and Bars.Clicks.Prepare then
		Bars.Clicks.Prepare(widget)
	else
		widget:RegisterForClicks("AnyDown", "AnyUp")
	end
	-- Mixin OnLoad sets useparent-actionpage=true and may restore ID.
	-- CalculateAction ID>0 ignores action / shift-action.
	if not (InCombatLockdown and InCombatLockdown()) then
		if widget.SetID then
			widget:SetID(0)
		end
		widget:SetAttribute("useparent-actionpage", false)
	end
	if Bars.Flyout and Bars.Flyout.Attach then
		Bars.Flyout.Attach(widget)
	end
	-- Attach sets direction only. Hide the mixin Arrow so empty slots do not
	-- keep a SpellFlyout chevron from FlyoutButtonTemplate (Arrow starts shown).
	if Bars.Flyout and Bars.Flyout.Hide then
		Bars.Flyout.Hide(widget)
	end

	widget:HookScript("OnMouseDown", function(self)
		local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
		if ov and ov.NotePressed then
			ov.NotePressed(self)
		end
	end)
	-- No OnMouseUp press reset: it runs before the click is dispatched, and
	-- clearing the pushed state there suppresses the mouse-up click. PostClick
	-- and the GLOBAL_MOUSE_UP fallback already unstick the button.

	widget:SetScript("OnEnter", function(self)
		local hl = self.HighlightTexture or (self.GetHighlightTexture and self:GetHighlightTexture())
		if hl then
			hl:Show()
		end
		hoverWidget = self
		self.UpdateTooltip = Hosts.UpdateTooltip
		Hosts.UpdateTooltip(self)
	end)
	widget:SetScript("OnLeave", function(self)
		local hl = self.HighlightTexture or (self.GetHighlightTexture and self:GetHighlightTexture())
		if hl then
			hl:Hide()
		end
		if hoverWidget == self then
			hoverWidget = nil
		end
		self.UpdateTooltip = nil
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)

	local function AfterCursorChange(self)
		local host = self._fluxHost
		if host and Bars.Paint and Bars.Paint.Dirty then
			Bars.Paint.Dirty(host)
		end
		if Bars.Layout and Bars.Layout.InvalidateMappings then
			Bars.Layout.InvalidateMappings()
		end
		if Bars.Layout and Bars.Layout.Request then
			Bars.Layout.Request("cursor")
		end
		-- Extra peeks ACTIONBAR_SLOT_CHANGED before Watch Flush, then After(0)
		-- used to wipe the occupancy wave. Binding overlays must not wait on
		-- that race — notify from the pickup/place itself.
		local slot = CurrentSlot(self)
		if slot then
			local peek = _G.FluxActionBarPeekSlotOccupancyChanged
			if peek then
				peek(slot)
			end
			local FB = _G.FluxBinding
			if FB and FB.NotifyOccupancyChanged then
				FB.NotifyOccupancyChanged({ slot })
			end
		end
	end

	widget:SetScript("OnDragStart", function(self)
		if InCombatLockdown and InCombatLockdown() then
			return
		end
		if Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown() then
			return
		end
		if not PickupAction then
			return
		end
		local slot = CurrentSlot(self)
		if slot then
			PickupAction(slot)
			AfterCursorChange(self)
		end
	end)
	widget:SetScript("OnReceiveDrag", function(self)
		if InCombatLockdown and InCombatLockdown() then
			return
		end
		if Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown() then
			return
		end
		if not PlaceAction then
			return
		end
		local slot = CurrentSlot(self)
		if slot then
			PlaceAction(slot)
			AfterCursorChange(self)
		end
	end)
	-- ButtonForge guard: keys and the down pass must not touch type, or the up
	-- pass re-enters and backs up the already-blanked value, killing the button.
	-- Forever has no wrap: click-to-drop is UseAction with a cursor. Blanking
	-- type plus a second PlaceAction can leave type="" or pick the slot back up.
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
		if button == "KeyBind" or down then
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
			w:SetAttribute("type", w._backupType or "action")
			w:SetAttribute("typerelease", w._backupTypeRelease or w._backupType or "action")
			w._backupType = nil
			w._backupTypeRelease = nil
			w._hasCursorItem = nil
			if PlaceAction then
				local slot = CurrentSlot(w)
				if slot then
					PlaceAction(slot)
					AfterCursorChange(w)
				end
			end
		end
		if not down then
			local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
			if ov and ov.ReleasePress then
				ov.ReleasePress(w)
			end
			local okT, targeting = false, false
			if SpellIsTargeting then
				okT, targeting = pcall(SpellIsTargeting)
			end
			if okT and targeting then
				w._fluxHadReticle = true
				if Flux.ButtonFX and Flux.ButtonFX.Cast and Flux.ButtonFX.Cast.NoteTargeting then
					Flux.ButtonFX.Cast.NoteTargeting(w)
				end
			end
		end
		local host = w._fluxHost
		if host and Bars.Paint and Bars.Paint.UpdateChecked then
			Bars.Paint.UpdateChecked(host)
		end
	end)

	if widget.SlotArt then
		widget.SlotArt:Hide()
	end
	if widget.SlotBackground then
		widget.SlotBackground:Hide()
	end
	if widget.NewActionTexture then
		widget.NewActionTexture:Hide()
	end
	if widget.SpellHighlightTexture then
		widget.SpellHighlightTexture:Hide()
	end
	local hl = widget.HighlightTexture or (widget.GetHighlightTexture and widget:GetHighlightTexture())
	if hl then
		hl:Hide()
	end
	if widget.SetHitRectInsets then
		widget:SetHitRectInsets(0, 0, 0, 0)
	end
	if widget.icon then
		widget.icon:ClearAllPoints()
		widget.icon:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 0)
		widget.icon:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", 0, 0)
		widget.icon:SetTexCoord(0, 1, 0, 1)
	end
	if widget.cooldown and widget.cooldown.EnableMouse then
		pcall(widget.cooldown.EnableMouse, widget.cooldown, false)
	end
	if widget.TextOverlayContainer then
		if widget.TextOverlayContainer.EnableMouse then
			pcall(widget.TextOverlayContainer.EnableMouse, widget.TextOverlayContainer, false)
		end
		if widget.TextOverlayContainer.SetFrameLevel and widget.GetFrameLevel then
			pcall(widget.TextOverlayContainer.SetFrameLevel, widget.TextOverlayContainer, (widget:GetFrameLevel() or 0) + 8)
		end
	end
	-- Minis stay unlabeled. Main-row Name is painted as the macro overlay.
	if row ~= "main" then
		if widget.Name then
			widget.Name:SetText("")
			widget.Name:Hide()
		end
		if widget.HotKey then
			widget.HotKey:SetText("")
			widget.HotKey:Hide()
		end
	end
	return widget
end

function Hosts.Skin(host)
	local widget = host and host.widget
	if not widget then
		return
	end
	if Bars.Blizzard and Bars.Blizzard.SkinButton then
		Bars.Blizzard.SkinButton(widget)
	end
end

function Hosts.FinishSurface(host, column, row, defaultSlot)
	Hosts.ResolveParts(host)
	host.widget._fluxHost = host
	local btn = host.widget.FluxButton
	if btn then
		host.btn = btn
		host._fluxFace = btn
	end
	Hosts.IndexSlot(host, defaultSlot)
	DetachMixinEvents(host.widget)
	if row ~= "main" then
		host.widget:SetScale(Hosts.MINI_WIDGET_SCALE)
		if host.WHotKey then
			host.WHotKey:SetText("")
			host.WHotKey:Hide()
		end
		if host.WName then
			host.WName:SetText("")
			host.WName:Hide()
		end
		if host.WCount and host.WCount.SetFont and NumberFontNormal and NumberFontNormal.GetFont then
			local font, _, flags = NumberFontNormal:GetFont()
			pcall(host.WCount.SetFont, host.WCount, font, Hosts.MiniCountFontSize(), flags or "OUTLINE")
		end
	end
	Hosts.Skin(host)
	local G = Flux.ButtonFX and Flux.ButtonFX.Glow
	if G and host.widget then
		if G.SilenceMixin then
			G.SilenceMixin(host.widget)
		end
		if G.InstallSAO then
			G.InstallSAO(host.widget)
		end
	end
end

function Hosts.Build()
	if built then
		return
	end
	built = true
	local State = Bars.State
	if State and State.Create then
		State.Create()
	end

	for column = 1, Bars.NUM_COLUMNS do
		local header = State and State.HeaderFor(column, "main") or (Bars.Strip and Bars.Strip.inner)
		local name = "FluxActionStripButton" .. column
		local widget = Hosts.CreateSurface(column, "main", name, header)
		local slot = (State and State.GetMainSlot(column, 1)) or column
		if State and widget then
			State.Attach(header, widget, column, "main")
		end
		local host = {
			column = column,
			row = "main",
			slot = slot,
			widget = widget,
			pages = column <= Bars.NUM_NATIVE,
			bindingCommand = Hosts.BindingCommand(column),
		}
		if widget then
			Hosts.FinishSurface(host, column, "main", slot)
		end
		Bars.hosts[column] = {
			column = column,
			pages = column <= Bars.NUM_NATIVE,
			bindingCommand = host.bindingCommand,
			main = host,
		}
	end
	if Flux.Action and Flux.Action.SweepFluxFromCollectors
		and not (Flux.Action.LeaveBlizzardCollector and Flux.Action.LeaveBlizzardCollector()) then
		Flux.Action.SweepFluxFromCollectors()
	end
end

function Hosts.ApplyChrome()
	Bars.ForEachHost(function(host)
		Hosts.Skin(host)
	end)
end

function Hosts.InvalidateKeys()
	if Bars.Clicks and Bars.Clicks.InvalidateKeys then
		Bars.Clicks.InvalidateKeys()
	end
end

function Hosts.RefreshKeys()
	if Bars.Clicks and Bars.Clicks.RefreshKeys then
		Bars.Clicks.RefreshKeys()
		return
	end
end

function Hosts.PrepareClicks(widget)
	if Bars.Clicks and Bars.Clicks.Prepare then
		Bars.Clicks.Prepare(widget)
	end
end
