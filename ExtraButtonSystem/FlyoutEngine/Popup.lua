-- ExtraButtonSystem/FlyoutEngine/Popup.lua — per-host secure popup + SAB kids.
local addonName, ns = ...
local Flux = ns.Flux
local Flyout = Flux.EBS and Flux.EBS.Flyout
if not Flyout then
	return
end

local Popup = {}
Flyout.Popup = Popup

local CELL = 40
local SPACING = 2
local PAD = 6
local ICON_INSET_FRAC = 0.1125
local MIN_XF = 0.4

local function HostXFactor(host)
	local function aspect(frame)
		if not frame or not frame.GetWidth or not frame.GetHeight then
			return nil
		end
		local w = frame:GetWidth()
		local h = frame:GetHeight()
		if type(w) ~= "number" or type(h) ~= "number" or h <= 0 or w ~= w or h ~= h then
			return nil
		end
		local f = w / h
		if f ~= f or f <= 0 then
			return nil
		end
		return math.max(MIN_XF, math.min(1, f))
	end
	local hostAspect = aspect(host)
	local parent = host and host.GetParent and host:GetParent()
	local parentAspect = aspect(parent)
	if parentAspect and (not hostAspect or math.abs(hostAspect - 1) < 0.01) then
		return parentAspect
	end
	if hostAspect then
		return hostAspect
	end
	if FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor then
		return FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor() or 1
	end
	return 1
end

local function KidTemplate()
	return "ActionButtonTemplate,SecureActionButtonTemplate"
end

local function HideNativeChrome(w)
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
	if w.SlotBackground then
		w.SlotBackground:Hide()
	end
	if w.NewActionTexture then
		w.NewActionTexture:Hide()
	end
	local name = w.GetName and w:GetName()
	local hotKey = w.HotKey or (name and _G[name .. "HotKey"])
	if hotKey then
		hotKey:SetText("")
		hotKey:Hide()
	end
	local nm = w.Name or (name and _G[name .. "Name"])
	if nm then
		nm:SetText("")
		nm:Hide()
	end
	-- Keep SpellCastAnimFrame / reticle / interrupt for ButtonFX. Only
	-- steal mouse so they cannot block left-click.
	for _, key in ipairs({
		"SpellCastAnimFrame",
		"TargetReticleAnimFrame",
		"InterruptDisplay",
		"cooldown",
		"Cooldown",
		"chargeCooldown",
		"CooldownFlash",
		"Flash",
		"AutoCastShine",
		"SpellHighlightTexture",
	}) do
		local child = w[key]
		if child then
			if child.EnableMouse then
				child:EnableMouse(false)
			end
		end
	end
	if w.SpellHighlightTexture and w.SpellHighlightTexture.Hide then
		w.SpellHighlightTexture:Hide()
	end
	if w.AutoCastShine and w.AutoCastShine.Hide then
		w.AutoCastShine:Hide()
	end
end

local function ResolveIcon(kid)
	if kid.icon then
		return kid.icon
	end
	local name = kid.GetName and kid:GetName()
	return name and _G[name .. "Icon"] or nil
end

local function ResolveCooldown(kid)
	if kid.cooldown then
		return kid.cooldown
	end
	local name = kid.GetName and kid:GetName()
	return name and _G[name .. "Cooldown"] or nil
end

local function ClearKidAttributes(kid)
	if not kid or not kid.SetAttribute then
		return
	end
	kid:SetAttribute("type", nil)
	kid:SetAttribute("typerelease", nil)
	kid:SetAttribute("type1", nil)
	kid:SetAttribute("type2", nil)
	kid:SetAttribute("*type1", nil)
	kid:SetAttribute("*type2", nil)
	kid:SetAttribute("*type3", nil)
	kid:SetAttribute("spell", nil)
	kid:SetAttribute("item", nil)
	kid:SetAttribute("macro", nil)
	kid:SetAttribute("macrotext", nil)
	kid:SetAttribute("macrotext1", nil)
	kid:SetAttribute("macrotext2", nil)
	kid:SetAttribute("doCloseOnClick", nil)
end

local function ItemID(value)
	if type(value) == "number" then
		return value
	end
	if type(value) == "string" then
		return tonumber(value:match("item:(%d+)")) or tonumber(value)
	end
	return nil
end

local function IsReagentDef(def)
	return def and (def.isReagent or def.skipUse) and true or false
end

local function ReagentItemId(kid, def)
	def = def or (kid and kid._fluxFlyoutDef)
	if kid and kid._reagentItemId then
		return tonumber(kid._reagentItemId) or kid._reagentItemId
	end
	return def and ItemID(def.item) or nil
end

local function BagCount(itemId)
	itemId = tonumber(itemId)
	if not itemId then
		return 0
	end
	local inv = Flux.Inventory
	if inv and inv.GetCount then
		return inv.GetCount(itemId, { bags = true, bank = false, warband = false }) or 0
	end
	if C_Item and C_Item.GetItemCount then
		return C_Item.GetItemCount(itemId, false, true) or 0
	end
	if GetItemCount then
		return GetItemCount(itemId, false, true) or 0
	end
	return 0
end

local function GetRestockTarget(itemId)
	itemId = tonumber(itemId)
	if not itemId then
		return 0
	end
	local TP = _G.FluxNCTeleportPortal
	if TP and TP.GetRestockTarget then
		return TP.GetRestockTarget(itemId) or 0
	end
	local FV = _G.FluxVendorAuto
	if FV and FV.GetRestockTargetForItem then
		return FV.GetRestockTargetForItem(itemId) or 0
	end
	local FR = _G.FluxRestock
	if FR and FR.GetTargetQuantity then
		return FR.GetTargetQuantity(itemId) or 0
	end
	return 0
end

local function CommitRestockTarget(itemId, value)
	itemId = tonumber(itemId)
	if not itemId then
		return
	end
	value = math.max(0, math.min(999, tonumber(value) or 0))
	local Cons = _G.FluxNCConsumables
	if Cons and Cons.IsChronoboonItem and Cons.IsChronoboonItem(itemId) then
		if Cons.SetPresetRestockTarget then
			Cons.SetPresetRestockTarget(itemId, value)
		elseif Cons.SetChronoboonRestockTarget then
			Cons.SetChronoboonRestockTarget(value)
		end
		return
	end
	local TP = _G.FluxNCTeleportPortal
	if TP and TP.SetRestockTarget then
		TP.SetRestockTarget(itemId, value)
		return
	end
	local FV = _G.FluxVendorAuto
	if FV and FV.SetRestockTarget then
		FV.SetRestockTarget(itemId, value)
	elseif FV and value > 0 and FV.AddRestockItem then
		FV.AddRestockItem(itemId, value)
	elseif FV and value <= 0 and FV.RemoveRestockItem then
		FV.RemoveRestockItem(itemId)
	end
end

local function CountFont(kid)
	return kid.WCount or kid.Count or (kid.GetName and _G[kid:GetName() .. "Count"])
end

local function PaintReagentCount(kid, def)
	local fs = CountFont(kid)
	if not fs then
		return
	end
	if kid.editBox and kid.editBox:IsShown() then
		fs:Hide()
		return
	end
	local itemId = ReagentItemId(kid, def)
	local count = BagCount(itemId)
	local target = GetRestockTarget(itemId)
	if def then
		def.currentCount = count
		def.targetCount = target
	end
	local countColor = "|cffffffff"
	local slashColor = "|cff888888"
	local targetColor = "|cff888888"
	if target > 0 then
		if count == 0 then
			countColor = "|cffff4444"
		elseif count < target then
			countColor = "|cffffff00"
		else
			countColor = "|cff00ff00"
		end
	end
	fs:SetText(countColor .. count .. slashColor .. "/" .. targetColor .. target .. "|r")
	fs:Show()
end

local function HideRestockEdit(kid)
	local box = kid and kid.editBox
	if not box then
		return
	end
	box:ClearFocus()
	box:Hide()
	local fs = CountFont(kid)
	if fs then
		fs:Show()
	end
end

local function EnsureRestockEdit(kid)
	if not kid then
		return nil
	end
	if kid.editBox then
		return kid.editBox
	end
	local editBox = CreateFrame("EditBox", nil, kid, "InputBoxTemplate")
	editBox:SetSize(20, 14)
	editBox:SetPoint("BOTTOMRIGHT", kid, "BOTTOMRIGHT", 0, 0)
	editBox:SetFontObject("GameFontNormalSmall")
	editBox:SetJustifyH("RIGHT")
	editBox:SetJustifyV("BOTTOM")
	editBox:SetAutoFocus(false)
	editBox:SetNumeric(true)
	editBox:SetMaxLetters(3)
	editBox:SetTextColor(1, 1, 1, 1)
	editBox:Hide()
	editBox:SetFrameLevel((kid.GetFrameLevel and kid:GetFrameLevel() or 0) + 5)
	editBox:SetScript("OnEnterPressed", function(self)
		local value = tonumber(self:GetText()) or 0
		local itemId = ReagentItemId(kid)
		if itemId then
			CommitRestockTarget(itemId, value)
			local def = kid._fluxFlyoutDef
			if def then
				def.targetCount = value
			end
		end
		self._fluxRestockEnterCommit = true
		self:Hide()
		PaintReagentCount(kid, kid._fluxFlyoutDef)
		self:ClearFocus()
	end)
	editBox:SetScript("OnEscapePressed", function(self)
		self._fluxRestockEscapeCancel = true
		self:ClearFocus()
		local itemId = ReagentItemId(kid)
		if itemId then
			self:SetText(tostring(GetRestockTarget(itemId)))
		end
		self:Hide()
		PaintReagentCount(kid, kid._fluxFlyoutDef)
		self._fluxRestockEscapeCancel = nil
	end)
	editBox:SetScript("OnEditFocusLost", function(self)
		if self._fluxRestockEnterCommit then
			self._fluxRestockEnterCommit = nil
			return
		end
		if self._fluxRestockEscapeCancel then
			return
		end
		local value = tonumber(self:GetText()) or 0
		local itemId = ReagentItemId(kid)
		if itemId then
			CommitRestockTarget(itemId, value)
			local def = kid._fluxFlyoutDef
			if def then
				def.targetCount = value
			end
		end
		self:Hide()
		PaintReagentCount(kid, kid._fluxFlyoutDef)
	end)
	kid.editBox = editBox
	return editBox
end

local function ToggleRestockEdit(kid)
	if not kid then
		return
	end
	local def = kid._fluxFlyoutDef
	if not IsReagentDef(def) then
		return
	end
	local box = EnsureRestockEdit(kid)
	if not box then
		return
	end
	if box:IsShown() then
		HideRestockEdit(kid)
		PaintReagentCount(kid, def)
		return
	end
	local itemId = ReagentItemId(kid, def)
	kid._reagentItemId = itemId
	box._fluxRestockEnterCommit = nil
	box._fluxRestockEscapeCancel = nil
	box:SetText(tostring(GetRestockTarget(itemId)))
	box:HighlightText(0, 0)
	box:Show()
	box:SetFocus()
	local fs = CountFont(kid)
	if fs then
		fs:Hide()
	end
end

local function SpellAttr(spell)
	if spell == nil then
		return nil
	end
	if type(spell) == "number" then
		return tostring(spell)
	end
	return spell
end

local function ApplyKidAttributes(kid, def)
	ClearKidAttributes(kid)
	if kid.RegisterForDrag then
		if def and def.onDragStart then kid:RegisterForDrag("LeftButton") else kid:RegisterForDrag() end
	end
	if not def then
		return
	end
	-- Reagent rows: no secure use/cast. Click opens the restock target box.
	if IsReagentDef(def) then
		kid:SetAttribute("doCloseOnClick", false)
		kid._fluxSkipFavorites = true
		kid._reagentItemId = ItemID(def.item)
		EnsureRestockEdit(kid)
		return
	end
	kid:SetAttribute("doCloseOnClick", true)
	kid._fluxSkipFavorites = def.skipFavorite and true or nil
	kid._reagentItemId = nil
	if def.skipFavorite then
		return
	end
	-- Left-click only (*type1). Right-click is Lua favorites; middle does nothing.
	-- Do not set typerelease: AnyDown+AnyUp would fire the action twice.
	local t = def.type
	if t == "spell" and def.spell then
		kid:SetAttribute("*type1", "spell")
		kid:SetAttribute("spell", SpellAttr(def.spell))
	elseif t == "item" and def.item then
		kid:SetAttribute("*type1", "item")
		kid:SetAttribute("item", Flyout.Def and Flyout.Def.ItemAttr(def.item) or def.item)
	elseif t == "macro" and def.macro then
		kid:SetAttribute("*type1", "macro")
		kid:SetAttribute("macro", def.macro)
	elseif (t == "macrotext" or t == "macro") and def.macrotext then
		kid:SetAttribute("*type1", "macro")
		kid:SetAttribute("macrotext", def.macrotext)
	end
end

local function PaintKidRing(kid)
	local Style = Flux.EBS and Flux.EBS.Style
	if not Style then
		return
	end
	local env = kid._fluxStyleEnv
	if not env then
		env = { Widget = kid, categoryScope = "class" }
		kid._fluxStyleEnv = env
	end
	env.Widget = kid
	if Style.ApplySlotRing then
		Style.ApplySlotRing(env, "class")
	elseif Style.SizeRing then
		Style.SizeRing(env)
		local tex = kid.NormalTexture or (kid.GetNormalTexture and kid:GetNormalTexture())
		if tex then
			tex:SetAlpha(1)
			tex:Show()
		end
	end
end

local function BindKidPaintEnv(kid, def)
	if not kid then
		return
	end
	kid.Widget = kid
	kid.FluxButton = kid
	kid.WIcon = ResolveIcon(kid)
	kid.WCooldown = ResolveCooldown(kid)
	kid.Cooldown = kid.WCooldown
	kid.WCount = kid.Count or (kid.GetName and _G[kid:GetName() .. "Count"])
	kid.WBorder = kid.Border or (kid.GetName and _G[kid:GetName() .. "Border"])
	kid.WNormalTexture = kid.NormalTexture or (kid.GetNormalTexture and kid:GetNormalTexture())
	kid.categoryScope = "class"
	if not def then
		kid.ActionType = nil
		kid.ActionValue = nil
		kid.SpellId = nil
		kid.ItemId = nil
		kid.IconOverrideTexture = nil
		kid._fluxAdoptedByHost = nil
		kid._fluxHostAdopted = nil
		return
	end
	local t = def.type
	if t == "spell" then
		kid.ActionType = "spell"
		kid.SpellId = tonumber(def.spell) or def.spell
		kid.ActionValue = kid.SpellId
		kid.ItemId = nil
	elseif t == "item" then
		kid.ActionType = "item"
		kid.ItemId = tonumber(def.item) or def.item
		kid.ActionValue = kid.ItemId
		kid.SpellId = nil
	elseif t == "macro" or t == "macrotext" then
		kid.ActionType = def.macrotext and "macrotext" or "macro"
		kid.ActionValue = def.macrotext or def.macro
		kid.SpellId = tonumber(def.spell)
		kid.ItemId = tonumber(def.item)
		if kid.SpellId then
			kid.MacroMode = "spell"
		elseif kid.ItemId then
			kid.MacroMode = "item"
		else
			kid.MacroMode = nil
		end
	else
		kid.ActionType = t
		kid.ActionValue = def.spell or def.item
		kid.SpellId = tonumber(def.spell)
		kid.ItemId = tonumber(def.item)
	end
	kid.IconOverrideTexture = def.icon
	kid._fluxAdoptedByHost = nil
	kid._fluxHostAdopted = nil
end

local function PaintKidFace(kid, def)
	BindKidPaintEnv(kid, def)
	local Paint = Flux.EBS and Flux.EBS.Paint
	if not Paint then
		return
	end
	if Paint.UpdateCount then
		Paint.UpdateCount(kid)
	end
	if IsReagentDef(def) then
		PaintReagentCount(kid, def)
	end
	if Paint.UpdateCooldown then
		Paint.UpdateCooldown(kid)
	end
	if Paint.UpdateEquipped then
		Paint.UpdateEquipped(kid)
	end
	if Paint.UpdateRange then
		Paint.UpdateRange(kid)
	end
	if Paint.UpdateUsable then
		Paint.UpdateUsable(kid)
	end
	if Paint.UpdateGlow then
		Paint.UpdateGlow(kid)
	end
	local itemId = kid.ItemId
	local U = _G.FluxButtonUsability
	if itemId and U and U.CheckMountItemUsability then
		local isMount = (FluxItemDetection and FluxItemDetection.IsItemAMount and FluxItemDetection.IsItemAMount(itemId))
			or (_G.FluxInv and FluxInv.Spells and FluxInv.Spells.IsItemAMount and FluxInv.Spells.IsItemAMount(itemId))
		if isMount then
			local state, mana = U:CheckMountItemUsability(itemId)
			if state and state ~= U.STATE_USABLE and state ~= U.STATE_UNKNOWN and U.ApplyVisualFeedback then
				U:ApplyVisualFeedback(kid, state, mana)
			end
		end
	end
end

local function RefreshShownKids(popup)
	if not popup or not popup.kids then
		return
	end
	for i = 1, #(popup.kids) do
		local kid = popup.kids[i]
		if kid and kid.IsShown and kid:IsShown() then
			PaintKidFace(kid, kid._fluxFlyoutDef)
		end
	end
end

local function PaintKid(kid, def)
	HideNativeChrome(kid)
	PaintKidRing(kid)
	local icon = ResolveIcon(kid)
	if icon then
		local size = math.min(kid:GetWidth() or CELL, kid:GetHeight() or CELL)
		local inset = math.max(1, size * ICON_INSET_FRAC)
		icon:ClearAllPoints()
		icon:SetPoint("TOPLEFT", kid, "TOPLEFT", inset, -inset)
		icon:SetPoint("BOTTOMRIGHT", kid, "BOTTOMRIGHT", -inset, inset)
		if icon.SetTexCoord then
			icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		end
		if def and def.icon then
			icon:SetTexture(def.icon)
			icon:Show()
		else
			icon:SetTexture(nil)
		end
	end
	PaintKidFace(kid, def)
	if kid.SetChecked then
		kid:SetChecked(false)
	end
end

local function KidOnEnter(self)
	local def = self._fluxFlyoutDef
	if not def or not GameTooltip then
		return
	end
	if def.onEnter then
		def.onEnter(self)
		return
	end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 4, 4)
	GameTooltip:ClearLines()
	local shown = false
	if def.bag and def.slot and GameTooltip.SetBagItem then
		shown = pcall(GameTooltip.SetBagItem, GameTooltip, def.bag, def.slot)
	end
	local itemId = ItemID(def.item)
	if not shown and itemId then
		if GameTooltip.SetItemByID then
			shown = pcall(GameTooltip.SetItemByID, GameTooltip, itemId)
		elseif GameTooltip.SetHyperlink then
			shown = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. tostring(itemId))
		end
	end
	local spellId = tonumber(def.spell)
	if not shown and spellId and GameTooltip.SetSpellByID then
		shown = pcall(GameTooltip.SetSpellByID, GameTooltip, spellId)
	end
	if not shown then
		GameTooltip:SetText(def.name or "", 1, 1, 1)
	end
	if def.tooltip then
		GameTooltip:AddLine(def.tooltip, 0.7, 0.7, 0.7)
	end
	if IsReagentDef(def) then
		local currentCount = BagCount(itemId)
		local restockTarget = GetRestockTarget(itemId)
		local itemPrice = 0
		local FR = _G.FluxRestock
		if FR and FR.GetItemUnitPrice then
			itemPrice = FR.GetItemUnitPrice(itemId) or 0
		end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Restock Settings", 1, 0.82, 0)
		if itemPrice > 0 then
			local priceStr = GetMoneyString and GetMoneyString(itemPrice) or (itemPrice .. "c")
			GameTooltip:AddLine("Unit Price: " .. priceStr, 1, 1, 1)
		end
		GameTooltip:AddLine("Current: " .. currentCount .. " | Target: " .. restockTarget, 1, 1, 1)
		if itemId and FR and FR.AppendSpellsUsingReagentToTooltip then
			FR.AppendSpellsUsingReagentToTooltip(GameTooltip, itemId)
		end
		if restockTarget > 0 then
			local needed = math.max(0, restockTarget - currentCount)
			if needed > 0 then
				GameTooltip:AddLine("Will restock " .. needed .. " at vendor", 0, 1, 0)
				if itemPrice > 0 then
					local restockCost = needed * itemPrice
					local moneyString = GetMoneyString and GetMoneyString(restockCost) or (restockCost .. "c")
					GameTooltip:AddLine("Total Cost: " .. moneyString, 1, 0.82, 0)
				end
			else
				GameTooltip:AddLine("Stock sufficient", 0, 0.5, 0)
			end
		else
			GameTooltip:AddLine("Restock disabled (target = 0)", 0.5, 0.5, 0.5)
		end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Left- or right-click: set restock target", 0.8, 0.8, 0.8)
		GameTooltip:Show()
		return
	end
	if not def.skipFavorite and not self._fluxSkipFavorites and Flyout.Favorites and Flyout.Favorites.AppendTooltip then
		local popup = self:GetParent()
		local host = popup and popup.host
		local category = (Flyout.Favorites.GetButtonCategory and Flyout.Favorites.GetButtonCategory(host))
			or (host and host._fluxFlyoutFavoritesCategory)
			or (def and def.favoriteCategory)
		if category then
			Flyout.Favorites.AppendTooltip(self, category, itemId, spellId)
			return
		end
	end
	GameTooltip:Show()
end

local function KidOnLeave(self)
	local def = self and self._fluxFlyoutDef
	if def and def.onLeave then
		def.onLeave(self)
	end
	if GameTooltip then
		GameTooltip:Hide()
	end
end

local function KidHost(kid)
	local popup = kid and kid.GetParent and kid:GetParent()
	return popup and popup.host
end

--- Pin the Extra host to this kid before UNIT_SPELLCAST_START. The popup
--- hides on mouse-up; fill on the kid would die with it.
local function AdoptKidCastOnHost(kid)
	if not kid then
		return false
	end
	local def = kid._fluxFlyoutDef
	if not def or def.skipFavorite or def.isReagent or def.skipUse or kid._fluxSkipFavorites then
		return false
	end
	local host = KidHost(kid)
	if not host then
		return false
	end
	local rec = Flyout.attached and Flyout.attached[host]
	if rec and rec.opts and rec.opts.adoptHostCast == false then
		return false
	end
	local btn = host.FluxButton or host
	local widget = (btn and btn.Widget) or host
	local spellId = tonumber(def.spell) or tonumber(kid.SpellId)
	local itemId = tonumber(def.item) or tonumber(kid.ItemId)
	if not spellId and not itemId then
		return false
	end
	if spellId then
		btn._fluxManagedFaceSpellId = spellId
		btn.SpellId = spellId
		btn.MacroMode = "spell"
		btn.ItemId = nil
		btn._fluxManagedFaceItemId = nil
	else
		btn._fluxManagedFaceItemId = itemId
		btn.ItemId = itemId
		btn.MacroMode = "item"
		btn._fluxManagedFaceSpellId = nil
	end
	local icon = def.icon
	if icon then
		btn.IconOverrideTexture = icon
		btn.MacroTexture = icon
		if btn.WIcon and btn.WIcon.SetTexture then
			btn.WIcon:SetTexture(icon)
			if btn.WIcon.Show then
				btn.WIcon:Show()
			end
		end
		if widget.icon and widget.icon.SetTexture then
			widget.icon:SetTexture(icon)
		end
	end
	widget._fluxCastLockSpellId = spellId or widget._fluxCastLockSpellId
	kid._fluxAdoptedByHost = true
	kid._fluxHostAdopted = true
	local FX = Flux.ButtonFX
	if FX and FX.Overlay and FX.Overlay.NotePressed then
		FX.Overlay.NotePressed(widget)
	end
	if def.onClick then
		def.onClick(kid, "LeftButton")
	end
	if FX and FX.Cast and FX.Cast.AdoptFace then
		FX.Cast.AdoptFace(kid, widget)
	elseif FX and FX.Overlay and FX.Overlay.Transfer then
		FX.Overlay.Transfer(kid, widget)
	end
	return true
end

local function KidPostClick(self, mouse, down)
	if down then
		return
	end
	local def = self._fluxFlyoutDef
	if self.SetChecked then
		self:SetChecked(false)
	end
	if IsReagentDef(def) then
		if mouse == "LeftButton" or mouse == "RightButton" or mouse == nil then
			ToggleRestockEdit(self)
		end
		return
	end
	if def and def.onClick and not self._fluxHostAdopted then
		def.onClick(self, mouse)
	end
	local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
	if ov and ov.ReleasePress then
		ov.ReleasePress(self)
	end
	if self._fluxHostAdopted then
		local host = KidHost(self)
		local widget = host and ((host.FluxButton and host.FluxButton.Widget) or host)
		local FX = Flux.ButtonFX
		if widget and FX and FX.Cast and FX.Cast.AdoptFace then
			FX.Cast.AdoptFace(self, widget)
		elseif widget and ov and ov.Transfer then
			ov.Transfer(self, widget)
		end
	end
	local okT, targeting = false, false
	if SpellIsTargeting then
		okT, targeting = pcall(SpellIsTargeting)
	end
	if okT and targeting then
		local target = self
		if self._fluxHostAdopted then
			local host = KidHost(self)
			target = (host and ((host.FluxButton and host.FluxButton.Widget) or host)) or self
		end
		target._fluxHadReticle = true
		if Flux.ButtonFX and Flux.ButtonFX.Cast and Flux.ButtonFX.Cast.NoteTargeting then
			Flux.ButtonFX.Cast.NoteTargeting(target)
		end
	end
	if mouse == "RightButton" then
		local popup = self:GetParent()
		local host = popup and popup.host
		if Flyout.Favorites and Flyout.Favorites.OnKidRightClick then
			Flyout.Favorites.OnKidRightClick(self, host)
		end
		return
	end
	if not Flyout.InLockdown() then
		local popup = self:GetParent()
		if popup and popup.Hide and popup:IsShown() and (not popup.GetAttribute or popup:GetAttribute("doCloseOnClick") ~= false) then
			local dummy = Flyout.Dummy and Flyout.Dummy()
			if not dummy or dummy:GetAttribute("doCloseOnClick") ~= false then
				popup:Hide()
			end
		end
	end
end

local function CreateKid(popup, index)
	local name = popup:GetName() .. "Btn" .. index
	local kid = CreateFrame("CheckButton", name, popup, KidTemplate())
	if Flux.Action and Flux.Action.DetachFromCollectors then
		Flux.Action.DetachFromCollectors(kid)
	end
	kid:SetSize(CELL, CELL)
	kid:Hide()
	kid:EnableMouse(true)
	-- SecureActionButton_OnClick uses ActionButtonUseKeyDown: AnyUp alone never
	-- receives DOWN, so left-click never uses the spell/item on retail.
	kid:RegisterForClicks("AnyDown", "AnyUp")
	local checkedTex = kid.CheckedTexture or (kid.GetCheckedTexture and kid:GetCheckedTexture())
	if checkedTex then
		checkedTex:SetAlpha(0)
		checkedTex:Hide()
	end
	HideNativeChrome(kid)
	BindKidPaintEnv(kid, nil)
	local FX = Flux.ButtonFX
	if FX and FX.Overlay and FX.Overlay.Attach then
		FX.Overlay.Attach(kid)
	end
	if FX and FX.Cast and FX.Cast.Register then
		FX.Cast.Register(kid, function(w)
			if w._fluxAdoptedByHost then
				return nil
			end
			return FX.SpellIdFromEBS and FX.SpellIdFromEBS(w)
		end, FX.Cast.RANK_EBS)
	end
	if FX and FX.Glow and FX.Glow.NotifySAO then
		FX.Glow.NotifySAO(kid)
	end
	kid:HookScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then
			return
		end
		if AdoptKidCastOnHost(self) then
			return
		end
		if FX and FX.Overlay and FX.Overlay.NotePressed then
			FX.Overlay.NotePressed(self)
		end
	end)
	if Flyout.Secure and Flyout.Secure.HandlerOnLoad then
		Flyout.Secure.HandlerOnLoad(kid)
	end
	kid:SetScript("OnEnter", KidOnEnter)
	kid:SetScript("OnLeave", KidOnLeave)
	kid:SetScript("OnDragStart", function(self)
		if Flyout.InLockdown() then return end
		local def = self._fluxFlyoutDef
		if def and def.onDragStart then def.onDragStart(self) end
	end)
	kid:SetScript("PostClick", KidPostClick)
	if Flyout.Secure and Flyout.Secure.InstallKidClose then
		Flyout.Secure.InstallKidClose(kid, popup)
	end
	return kid
end

local function MakePopup(host)
	if Flyout.InLockdown() then
		return nil
	end
	Flyout._menuSeq = (Flyout._menuSeq or 0) + 1
	local name = "FluxFlyoutMenu" .. Flyout._menuSeq
	local popup
	local ok, frame = pcall(CreateFrame, "Frame", name, UIParent, "SecureFrameTemplate")
	if ok then
		popup = frame
	else
		popup = CreateFrame("Frame", name, UIParent)
	end
	popup:Hide()
	popup:SetFrameStrata("FULLSCREEN_DIALOG")
	popup:SetFrameLevel(5500)
	if popup.SetToplevel then
		popup:SetToplevel(true)
	end
	popup:SetClampedToScreen(true)
	popup:EnableMouse(true)
	popup.host = host
	popup.direction = "UP"
	popup.kids = {}
	if Flyout.Secure and Flyout.Secure.HandlerOnLoad then
		Flyout.Secure.HandlerOnLoad(popup)
	end
	if Flyout.Chrome and Flyout.Chrome.Attach then
		Flyout.Chrome.Attach(popup)
	end
	for i = 1, Flyout.MAX_BUTTONS do
		popup.kids[i] = CreateKid(popup, i)
	end
	popup:SetScript("OnShow", function(self)
		if Flyout.Popup and Flyout.Popup.Place and self.host then
			Flyout.Popup.Place(self.host)
		end
		if Flyout.Arrow and Flyout.Arrow.SetOpen then
			Flyout.Arrow.SetOpen(self.host, true)
		end
		if Flyout.Chrome and Flyout.Chrome.Layout then
			Flyout.Chrome.Layout(self, self.direction)
		end
		RefreshShownKids(self)
		self._fluxKidElapsed = 0
		self:SetScript("OnUpdate", function(popup, elapsed)
			popup._fluxKidElapsed = (popup._fluxKidElapsed or 0) + (elapsed or 0)
			if popup._fluxKidElapsed < 0.2 then
				return
			end
			popup._fluxKidElapsed = 0
			RefreshShownKids(popup)
		end)
	end)
	popup:SetScript("OnHide", function(self)
		self:SetScript("OnUpdate", nil)
		if self.ClearBindings then
			pcall(self.ClearBindings, self)
		end
		if self.kids then
			for i = 1, #(self.kids) do
				HideRestockEdit(self.kids[i])
			end
		end
		if Flyout.Arrow and Flyout.Arrow.SetOpen then
			Flyout.Arrow.SetOpen(self.host, false)
		end
	end)
	return popup
end

function Popup.Ensure(host)
	local rec = Flyout.HostOf(host)
	if not rec then
		return nil
	end
	if rec.popup then
		return rec.popup
	end
	if Flyout.InLockdown() then
		return nil
	end
	rec.popup = MakePopup(host)
	return rec.popup
end

function Popup.Place(host)
	local rec = Flyout.HostOf(host)
	local popup = rec and rec.popup
	if not popup or not host then
		return
	end
	if Flyout.InLockdown() then
		return
	end
	local opts = rec.opts or {}
	local dir = Flyout.DirOk(opts.direction or popup.direction or "UP")
	popup.direction = dir
	local anchor = opts.anchorFrame or host
	popup:ClearAllPoints()
	popup:SetParent(UIParent)
	popup:SetFrameStrata("FULLSCREEN_DIALOG")
	popup:SetFrameLevel(5500)
	if popup.SetToplevel then
		popup:SetToplevel(true)
	end
	if opts.placePoint and opts.placeRelPoint and anchor then
		popup:SetPoint(opts.placePoint, anchor, opts.placeRelPoint, opts.placeX or 0, opts.placeY or 0)
	else
		local p, rel, x, y = Flyout.DirPoints(dir)
		popup:SetPoint(p, anchor, rel, x, y)
	end
	if opts.matchAnchorScale ~= false and popup.SetScale and anchor and anchor.GetEffectiveScale and UIParent.GetEffectiveScale then
		local us = UIParent:GetEffectiveScale() or 1
		if us > 0 then
			popup:SetScale((anchor:GetEffectiveScale() or us) / us)
		end
	end
end

function Popup.Layout(host, buttons, opts)
	local rec = Flyout.HostOf(host)
	local popup = rec and rec.popup
	if not popup then
		return
	end
	if Flyout.InLockdown() then
		return
	end
	opts = opts or rec.opts or {}
	local list = buttons or rec.buttons or {}
	local n = #list
	local dir = Flyout.DirOk(opts.direction or rec.opts and rec.opts.direction or popup.direction)
	popup.direction = dir
	popup._fluxFlyoutChromeMode = opts.chrome or popup._fluxFlyoutChromeMode
	local cell = tonumber(opts.cellSize) or CELL
	local xF = HostXFactor(host)
	local cellX = cell * xF
	popup._fluxFlyoutCell = cell
	popup._fluxFlyoutCellX = cellX
	local spacing = opts.spacing or SPACING
	local spacingX = spacing * xF
	local pad = opts.padding or PAD
	local cols = tonumber(opts.columns)
	if not cols or cols < 1 then
		cols = 1
	end
	if dir == "LEFT" or dir == "RIGHT" then
		cols = n > 0 and n or 1
	end
	if n <= 0 then
		for i = 1, Flyout.MAX_BUTTONS do
			local kid = popup.kids[i]
			kid._fluxFlyoutDef = nil
			ClearKidAttributes(kid)
			HideRestockEdit(kid)
			kid:Hide()
		end
		if dir == "LEFT" or dir == "RIGHT" then
			popup:SetSize(cellX + pad * 2, cell)
		else
			popup:SetSize(cellX, cell + pad * 2)
		end
		Popup.Place(host)
		if Flyout.Chrome and Flyout.Chrome.Layout then
			Flyout.Chrome.Layout(popup, dir)
		end
		return
	end
	-- UP/DOWN stay a wrapping grid when columns is set (1..N wide forms).
	if (dir == "UP" or dir == "DOWN") and not opts.columns then
		cols = 1
	end
	local rows = math.ceil(n / cols)
	local actualCols = math.min(n, cols)
	for i = 1, Flyout.MAX_BUTTONS do
		local kid = popup.kids[i]
		local def = list[i]
		if def then
			kid._fluxFlyoutDef = def
			kid:SetSize(cellX, cell)
			ApplyKidAttributes(kid, def)
			PaintKid(kid, def)
			local category = (opts and opts.favoriteCategory)
				or (rec.opts and rec.opts.favoriteCategory)
				or (host and host._fluxFlyoutFavoritesCategory)
			if Flyout.Favorites and Flyout.Favorites.PaintKidStar then
				Flyout.Favorites.PaintKidStar(kid, category)
			end
			local col = (i - 1) % cols
			local row = math.floor((i - 1) / cols)
			-- Cross-axis hugs the cells so the 37px TGA (drawn around a 28px
			-- CustomFlyout kid) can hang outside and wrap the rings.
			local x
			local y
			if dir == "LEFT" or dir == "RIGHT" then
				x = pad + col * (cellX + spacingX)
				y = row * (cell + spacing)
			elseif dir == "DOWN" then
				x = col * (cellX + spacingX)
				y = -pad - row * (cell + spacing)
			else
				x = col * (cellX + spacingX)
				y = pad + row * (cell + spacing)
			end
			kid:ClearAllPoints()
			if dir == "DOWN" then
				kid:SetPoint("TOPLEFT", popup, "TOPLEFT", x, y)
			else
				kid:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", x, y)
			end
			kid:Show()
			if popup.GetFrameLevel then
				kid:SetFrameLevel((popup:GetFrameLevel() or 5500) + 20)
			end
			if Flyout.Secure and Flyout.Secure.InstallKidClose then
				Flyout.Secure.InstallKidClose(kid, popup)
			end
		else
			kid._fluxFlyoutDef = nil
			ClearKidAttributes(kid)
			HideRestockEdit(kid)
			kid:Hide()
		end
	end
	local stackW = (actualCols * cellX) + ((actualCols - 1) * spacingX)
	local stackH = (rows * cell) + ((rows - 1) * spacing)
	local width, height
	if dir == "LEFT" or dir == "RIGHT" then
		width = stackW + (pad * 2)
		height = stackH
	else
		width = stackW
		height = stackH + (pad * 2)
	end
	popup:SetSize(width, height)
	Popup.Place(host)
	if Flyout.Chrome and Flyout.Chrome.Layout then
		Flyout.Chrome.Layout(popup, dir)
	end
	if Flyout.Chrome and Flyout.Chrome.ApplyAccent then
		Flyout.Chrome.ApplyAccent(popup)
	end
end
