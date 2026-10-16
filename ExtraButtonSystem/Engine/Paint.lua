-- ExtraButtonSystem/Engine/Paint.lua — icon, empty slot, count, CD, usable, checked
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS
local FluxButton = _G.FluxButton

local Paint = {}
EBS.Paint = Paint

local EMPTY_ALPHA = 0.85
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

local function IsQuestionTex(tex)
	if tex == nil then
		return false
	end
	if tex == QUESTION or tex == 134400 then
		return true
	end
	return type(tex) == "string" and string.find(tex, "QuestionMark") ~= nil
end

local COLOR_USABLE = { 1, 1, 1 }
local COLOR_MANA = { 0.5, 0.5, 1 }
local COLOR_UNUSABLE = { 0.4, 0.4, 0.4 }
local COLOR_OOR = { 0.8, 0.1, 0.1 }
local RANDOM_MOUNT_ID = 268435455
local RANDOM_BATTLE_PET_ID = "BattlePet-0-FFFFFFFFFFFFFF"

local BAG_COUNT_OPTS = {
	bags = true,
	bank = false,
	warband = false,
	equipped = false,
	includeBank = false,
	charges = false,
}

local flyoutIconCache = {}
local professionNameSet

function Paint.InvalidateSpellCaches()
	professionNameSet = nil
	if wipe then
		wipe(flyoutIconCache)
	else
		for k in pairs(flyoutIconCache) do
			flyoutIconCache[k] = nil
		end
	end
	if Flux.Spell and Flux.Spell.ClearLiveFaceCache then
		Flux.Spell.ClearLiveFaceCache()
	end
end

function Paint.ClearCache(btn)
	if not btn then
		return
	end
	btn._lastIcon = nil
	btn._lastCountText = nil
	btn._lastCdStart = nil
	btn._lastCdDur = nil
	btn._lastCdEn = nil
	btn._lastCdSwipe = nil
	if btn.Widget and Flux.ButtonFX and Flux.ButtonFX.Charges and Flux.ButtonFX.Charges.ClearCache then
		Flux.ButtonFX.Charges.ClearCache(btn.Widget)
	end
	btn._lastIconR = nil
	btn._lastIconG = nil
	btn._lastIconB = nil
	btn._lastRingMana = nil
	btn._lastChecked = nil
	btn._lastEquipped = nil
end

--- A button whose own widget is hidden cannot show anything, so paint passes
--- skip it. Widget.Create hooks OnShow to ask for the repaint on the way back.
--- Range/need also treat parent-hidden Extra window children as parked
--- (IsShown stays true while the editor is closed). Do not Hide() badges.
function Paint.IsParked(btn)
	-- Occupancy strip hosts paint through Bars.Paint, never Extra FlushEval.
	if btn and (btn.kind == "strip" or btn._fluxStripFace) then
		return true
	end
	local widget = btn and btn.Widget
	if not widget or not widget.IsShown then
		return false
	end
	-- Badges never Hide() — the Extra CheckButton is protected in combat — so
	-- they park at alpha 0 instead. An invisible badge still cost a full icon /
	-- usable / checked / cooldown paint on every sweep.
	if widget._fluxBadgeCombatVisHidden then
		return true
	end
	if widget.IsVisible and not widget:IsVisible() then
		return true
	end
	return not widget:IsShown()
end

function Paint.RequestShown(btn)
	if not btn then
		return
	end
	Paint.ClearCache(btn)
	if Flux.Scheduler and Flux.Scheduler.Request then
		Flux.Scheduler.Request("eval", "ebs")
		return
	end
	Paint.Update(btn)
end

function Paint.HasPendingIcon()
	local list = EBS.buttons
	if not list then
		return false
	end
	for i = 1, #list do
		local btn = list[i]
		if btn and btn.ActionType and btn.ActionValue ~= nil and btn.ActionType ~= "macrotext" then
			if btn._lastIcon == nil or IsQuestionTex(btn._lastIcon) then
				return true
			end
		end
	end
	return false
end

local function SafeNum(value, default)
	if Flux.Secrets and Flux.Secrets.SafeGetNumber then
		return Flux.Secrets.SafeGetNumber(value, default or 0)
	end
	local n = tonumber(value)
	if n then
		return n
	end
	return default or 0
end

local function ThemedRGB(btn)
	local scope = btn and btn.categoryScope or "character"
	if scope == "character" or scope == "class" then
		-- ExtraButtons hosts follow category scope, not Appearance accent.
		if not (btn and btn._fluxScopeOnlyTint) and FluxBorder and FluxBorder.GetThemedVertexRGB then
			return FluxBorder:GetThemedVertexRGB()
		end
		local _, classFilename = UnitClass("player")
		local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename]
		if c then
			return c.r, c.g, c.b
		end
	end
	return 1, 1, 1
end

local PLACEHOLDER_RGB = 0.25

local function ApplyIconDesat(btn)
	local icon = btn and btn.WIcon
	if not icon or not icon.SetDesaturated then
		return
	end
	if btn.PlaceholderTexture and not btn.IsWispLockPlaceholder then
		icon:SetDesaturated(true)
		return
	end
	icon:SetDesaturated(btn._fluxRankDesaturated and true or false)
end

local function ApplyPlaceholderIcon(btn)
	if not btn or not btn.WIcon or not btn.PlaceholderTexture then
		return false
	end
	if btn.IsWispLockPlaceholder then
		return false
	end
	local icon = btn.WIcon
	local tex = btn.PlaceholderTexture
	btn._lastIcon = tex
	btn._lastIconR, btn._lastIconG, btn._lastIconB = nil, nil, nil
	icon:SetTexture(tex)
	icon:SetTexCoord(0, 1, 0, 1)
	if icon.SetDesaturated then
		icon:SetDesaturated(true)
	end
	icon:SetVertexColor(PLACEHOLDER_RGB, PLACEHOLDER_RGB, PLACEHOLDER_RGB, 1)
	icon:Show()
	if btn.WName then
		btn.WName:SetText("")
		btn.WName:Hide()
	end
	return true
end

local function SetIconTexture(btn, texture)
	local icon = btn.WIcon
	if not icon then
		return
	end
	if Flux.Secrets and Flux.Secrets.IsSecretValue and Flux.Secrets.IsSecretValue(texture) then
		btn._lastIcon = nil
		pcall(icon.SetTexture, icon, texture)
		icon:Show()
		return
	end
	if btn._lastIcon == texture then
		if texture then
			if not btn.PlaceholderTexture then
				ApplyIconDesat(btn)
			end
			icon:Show()
		else
			icon:Hide()
		end
		return
	end
	btn._lastIcon = texture
	if texture then
		icon:SetTexture(texture)
		icon:SetTexCoord(0, 1, 0, 1)
		ApplyIconDesat(btn)
		icon:Show()
	else
		icon:SetTexture(nil)
		icon:Hide()
	end
end

function Paint.UpdateEmpty(btn)
	if not btn or not btn.WEmptyBG then
		return
	end
	local empty = btn.WEmptyBG
	if btn.ActionType == "pet" or btn.ActionType == "shapeshift" then
		empty:Hide()
		return
	end
	-- Empty-slot placeholders keep the gray icon; do not show the class-tinted hole.
	if btn.PlaceholderTexture then
		empty:Hide()
		return
	end
	local occupied = btn.ActionType and btn.ActionValue ~= nil
	if occupied or btn.badgeMode then
		empty:Hide()
		return
	end
	local widget = btn.Widget
	local w = (widget and (widget._fluxLayoutW or (widget.GetWidth and widget:GetWidth()))) or 0
	local h = (widget and (widget._fluxLayoutH or (widget.GetHeight and widget:GetHeight()))) or 0
	if type(w) ~= "number" or w < 1 then
		w = 32
	end
	if type(h) ~= "number" or h < 1 then
		h = w
	end
	empty:SetSize(w * 1.5, h * 1.5)
	local r, g, b = ThemedRGB(btn)
	empty:SetVertexColor(r, g, b, EMPTY_ALPHA)
	empty:SetAlpha(EMPTY_ALPHA)
	empty:Show()
end

local function SpellIcon(spellId)
	if not spellId then
		return nil
	end
	if Flux.Spell and Flux.Spell.GetLiveFace then
		local face = Flux.Spell.GetLiveFace(spellId)
		if face then
			return face
		end
	end
	if Flux.Spell and Flux.Spell.GetOverrideSpell then
		spellId = Flux.Spell.GetOverrideSpell(spellId) or spellId
	end
	if Flux.Spell and Flux.Spell.GetTexture then
		local tex = Flux.Spell.GetTexture(spellId)
		if tex then
			return tex
		end
	end
	if Flux.Spell and Flux.Spell.GetIcon then
		local tex = Flux.Spell.GetIcon(spellId)
		if tex then
			return tex
		end
	end
	if C_Spell and C_Spell.GetSpellTexture then
		local ok, tex = pcall(C_Spell.GetSpellTexture, spellId)
		if ok and tex then
			return tex
		end
	end
	if GetSpellTexture then
		local ok, tex = pcall(GetSpellTexture, spellId)
		if ok and tex then
			return tex
		end
	end
	-- "Lesser Heal(Rank 1)" does not resolve on Forever until the bare name does.
	if type(spellId) == "string" then
		local bare = spellId:match("^(.-)%s*%b()$")
		if bare and bare ~= "" and bare ~= spellId then
			return SpellIcon(bare)
		end
	end
	return nil
end

local function PaintSpell(spellId)
	if not spellId then
		return spellId
	end
	if Flux.Spell and Flux.Spell.GetOverrideSpell then
		return Flux.Spell.GetOverrideSpell(spellId)
	end
	return spellId
end

local AUTOCAST_CLASSIC_OVERLAY = 26
local AUTOCAST_CLASSIC_CORNERS = 58
local AUTOCAST_RETAIL_OVERLAY = 31
local AUTOCAST_REF = 30

local function SizeCentered(layer, w, h, relativeTo)
	if not layer then
		return
	end
	local anchor = relativeTo or layer:GetParent()
	pcall(function()
		layer:ClearAllPoints()
		layer:SetSize(w, h)
		layer:SetPoint("CENTER", anchor, "CENTER", 0, 0)
		if layer.SetScale then
			layer:SetScale(1)
		end
	end)
end

function Paint.EnsureAutocast(btn)
	local widget = btn and btn.Widget
	if not widget then
		return
	end
	if widget.AutoCastOverlay or widget.AutoCastShine or widget.AutoCastable then
		return
	end
	local overlay
	local ok = pcall(function()
		overlay = CreateFrame("Frame", nil, widget, "AutoCastOverlayTemplate")
	end)
	if ok and overlay then
		widget.AutoCastOverlay = overlay
		overlay:SetPoint("CENTER")
		return
	end
	local shine
	ok = pcall(function()
		shine = CreateFrame("Frame", nil, widget, "AutoCastShineTemplate")
	end)
	if ok and shine then
		widget.AutoCastShine = shine
		shine:SetAllPoints(widget)
	end
	local tex = widget:CreateTexture(nil, "OVERLAY")
	tex:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
	tex:Hide()
	widget.AutoCastable = tex
end

function Paint.UpdateAutocast(btn, allowed, enabled)
	local widget = btn and btn.Widget
	if not widget then
		return
	end
	Paint.EnsureAutocast(btn)
	local w = widget:GetWidth() or AUTOCAST_REF
	local h = widget:GetHeight() or AUTOCAST_REF
	local xR, yR = w / AUTOCAST_REF, h / AUTOCAST_REF
	local overlay = widget.AutoCastOverlay
	if overlay then
		local corners = overlay.Corners
		local classicCorners = corners and corners.GetTexture and corners:GetTexture()
			and not (corners.GetAtlas and corners:GetAtlas())
		local postDF = Flux.Client and Flux.Client.isPostDF
		if classicCorners or (not postDF and corners) then
			SizeCentered(overlay, AUTOCAST_CLASSIC_OVERLAY * xR, AUTOCAST_CLASSIC_OVERLAY * yR, widget)
			SizeCentered(corners, AUTOCAST_CLASSIC_CORNERS * xR, AUTOCAST_CLASSIC_CORNERS * yR, overlay)
		else
			SizeCentered(overlay, AUTOCAST_RETAIL_OVERLAY * xR, AUTOCAST_RETAIL_OVERLAY * yR, widget)
			if corners then
				pcall(function()
					corners:ClearAllPoints()
					corners:SetAllPoints(overlay)
				end)
			end
		end
		if overlay.SetShown then
			overlay:SetShown(allowed and true or false)
		end
		if overlay.ShowAutoCastEnabled then
			pcall(overlay.ShowAutoCastEnabled, overlay, enabled and true or false)
		end
		return
	end
	if widget.AutoCastable then
		SizeCentered(widget.AutoCastable, AUTOCAST_CLASSIC_CORNERS * xR, AUTOCAST_CLASSIC_CORNERS * yR, widget)
		if allowed then
			widget.AutoCastable:Show()
		else
			widget.AutoCastable:Hide()
		end
	end
	if widget.AutoCastShine then
		SizeCentered(widget.AutoCastShine, w, h, widget)
		if allowed and enabled and AutoCastShine_AutoCastStart then
			pcall(AutoCastShine_AutoCastStart, widget.AutoCastShine)
		elseif AutoCastShine_AutoCastStop then
			pcall(AutoCastShine_AutoCastStop, widget.AutoCastShine)
		end
	end
end

local function PetActionTexture(btn)
	local slot = btn.PetSlot or btn.ActionValue
	local P = Flux.Pet
	if not P or not P.GetActionInfo or not slot then
		btn.PetHasAction = false
		return nil
	end
	local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = P.GetActionInfo(slot)
	btn.PetHasAction = texture and true or false
	btn.PetIsActive = isActive and true or false
	btn.PetAutoCastAllowed = autoCastAllowed and true or false
	btn.PetAutoCastEnabled = autoCastEnabled and true or false
	btn.SpellId = tonumber(spellID)
	if isToken then
		if type(texture) == "string" then
			texture = _G[texture]
		end
		if type(name) == "string" then
			btn.PetTooltipName = _G[name] or name
		end
	else
		btn.PetTooltipName = name
	end
	Paint.UpdateAutocast(btn, autoCastAllowed, autoCastEnabled)
	local flash = btn.WFlashTexture
	if flash then
		if isActive and P.IsAttackAction and P.IsAttackAction(slot) then
			flash:Show()
		else
			flash:Hide()
		end
	end
	return texture
end

-- Morph icon/CD/usable/tooltip/glow to the next rotation spell; clicks stay the action spell.
local function ShownSpellId(btn)
	if not btn then
		return nil
	end
	if btn.IsAssistedCombat then
		local nextId
		if EBS.Action and EBS.Action.GetAssistantNextSpell then
			nextId = EBS.Action.GetAssistantNextSpell()
		end
		if nextId ~= btn.AssistedNextSpellId then
			btn._lastIcon = nil
			btn._lastCountText = nil
			btn._lastCdStart = nil
			btn._lastCdDur = nil
			btn._lastCdEn = nil
			btn._lastIconR = nil
			btn._lastIconG = nil
			btn._lastIconB = nil
			if btn.Widget and Flux.ButtonFX and Flux.ButtonFX.Charges and Flux.ButtonFX.Charges.ClearCache then
				Flux.ButtonFX.Charges.ClearCache(btn.Widget)
			end
		end
		btn.AssistedNextSpellId = nextId
		if nextId then
			return nextId
		end
	else
		btn.AssistedNextSpellId = nil
	end
	return btn.SpellId or btn.ActionValue
end

local function ItemIcon(itemId)
	if not itemId then
		return nil
	end
	-- ButtonForge SetEnvItem: item texture, not the spell the item casts.
	if Flux.Item and Flux.Item.GetIcon then
		return Flux.Item.GetIcon(itemId)
	end
	if C_Item and C_Item.GetItemIconByID then
		local ok, tex = pcall(C_Item.GetItemIconByID, itemId)
		if ok and tex then
			return tex
		end
	end
	if GetItemIcon then
		local ok, tex = pcall(GetItemIcon, itemId)
		if ok and tex then
			return tex
		end
	end
	return nil
end

local function ToyIcon(toyId)
	if toyId and C_ToyBox and C_ToyBox.GetToyInfo then
		local ok, _, _, icon = pcall(C_ToyBox.GetToyInfo, toyId)
		if ok and icon then
			return icon
		end
	end
	return ItemIcon(toyId)
end

local function FlyoutIcon(flyoutId)
	if not flyoutId then
		return nil
	end
	local cached = flyoutIconCache[flyoutId]
	if cached then
		return cached
	end
	local tex
	local SB = C_SpellBook
	if SB and SB.GetSpellBookItemInfo and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo then
		local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
		local flyoutType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout
		local okLines, n = pcall(SB.GetNumSpellBookSkillLines)
		if okLines and type(n) == "number" then
			for i = 1, n do
				local okLine, line = pcall(SB.GetSpellBookSkillLineInfo, i)
				if okLine and line and line.itemIndexOffset and line.numSpellBookItems then
					for j = 1, line.numSpellBookItems do
						local index = line.itemIndexOffset + j
						local okInfo, info = pcall(SB.GetSpellBookItemInfo, index, bank)
						if okInfo and info then
							local isFlyout = (flyoutType and info.itemType == flyoutType)
								or info.actionID == flyoutId
								or info.itemID == flyoutId
							if isFlyout and (info.actionID == flyoutId or info.itemID == flyoutId or info.spellID == flyoutId) then
								if SB.GetSpellBookItemTexture then
									local okTex, bookTex = pcall(SB.GetSpellBookItemTexture, index, bank)
									if okTex and bookTex then
										tex = bookTex
										break
									end
								end
								if info.iconID then
									tex = info.iconID
									break
								end
							end
						end
					end
				end
				if tex then
					break
				end
			end
		end
	end
	if not tex then
		local S = Flux.Spell
		local numSlots
		if S and S.GetFlyoutInfo then
			local _, _, n = S.GetFlyoutInfo(flyoutId)
			numSlots = n
		end
		numSlots = numSlots or 8
		for i = 1, numSlots do
			local id
			if S and S.FlyoutSlotCastID then
				id = S.FlyoutSlotCastID(flyoutId, i)
			end
			if id then
				local slotTex = SpellIcon(id)
				if slotTex then
					tex = slotTex
					break
				end
			end
		end
	end
	tex = tex or QUESTION
	if tex ~= QUESTION then
		flyoutIconCache[flyoutId] = tex
	end
	return tex
end

local function IsMacroLike(btn)
	local t = btn and btn.ActionType
	return t == "macro" or t == "macrotext"
end

local function MacroShownSpell(btn)
	local managed = tonumber(btn and btn._fluxManagedFaceSpellId)
	if managed then
		return managed
	end
	if IsMacroLike(btn) and btn.MacroMode == "spell" then
		return btn.SpellId
	end
	return nil
end

local function MacroShownItem(btn)
	local managed = tonumber(btn and btn._fluxManagedFaceItemId)
	if managed then
		return managed
	end
	if IsMacroLike(btn) and btn.MacroMode == "item" then
		return btn.ItemId
	end
	return nil
end

local function MacroIcon(btn)
	local spell = MacroShownSpell(btn)
	if spell then
		local tex = SpellIcon(spell)
		if tex and not IsQuestionTex(tex) then
			return tex
		end
	end
	local iid = MacroShownItem(btn)
	if iid then
		local tex = ItemIcon(iid)
		if tex and not IsQuestionTex(tex) then
			return tex
		end
	end
	if btn.MacroTexture and not IsQuestionTex(btn.MacroTexture) then
		return btn.MacroTexture
	end
	if btn.ActionType == "macro" and btn.MacroIndex and GetMacroInfo then
		local _, icon = GetMacroInfo(btn.MacroIndex)
		if icon and not IsQuestionTex(icon) then
			return icon
		end
	end
	local want = btn._fluxWant
	if want then
		if want.spellId then
			local tex = SpellIcon(want.spellId)
			if tex and not IsQuestionTex(tex) then
				return tex
			end
		end
		if want.itemId then
			local tex = ItemIcon(want.itemId)
			if tex and not IsQuestionTex(tex) then
				return tex
			end
		end
	end
	return nil
end

local function UpdateMacroNameOverlay(btn)
	if not btn or not btn.WName then
		return
	end
	if not btn.macroText or btn.ActionType ~= "macro" or not btn.MacroName then
		btn.WName:SetText("")
		btn.WName:Hide()
		return
	end
	if btn._lastCountText and btn._lastCountText ~= "" then
		btn.WName:SetText("")
		btn.WName:Hide()
		return
	end
	btn.WName:SetText(btn.MacroName)
	btn.WName:Show()
end

function Paint.UpdateIcon(btn)
	if not btn then
		return
	end
	if btn.PlaceholderTexture then
		if btn.IsWispLockPlaceholder then
			SetIconTexture(btn, btn.PlaceholderTexture)
			return
		end
		ApplyPlaceholderIcon(btn)
		return
	end
	if not btn.ActionType or btn.ActionValue == nil then
		SetIconTexture(btn, nil)
		if btn.WName then
			btn.WName:SetText("")
			btn.WName:Hide()
		end
		return
	end
	local t = btn.ActionType
	local tex
	local override = btn.IconOverrideTexture
	if override ~= nil and override ~= "" then
		tex = override
	elseif t == "spell" then
		tex = SpellIcon(ShownSpellId(btn))
	elseif t == "toy" then
		tex = ToyIcon(btn.ToyId or btn.ItemId or btn.ActionValue)
	elseif t == "item" then
		tex = ItemIcon(btn.ItemId or btn.ActionValue)
	elseif t == "macro" or t == "macrotext" then
		tex = MacroIcon(btn)
	elseif t == "mount" then
		local mountId = btn.MountId or btn.ActionValue
		local name, spellID, icon
		if EBS.Action and EBS.Action.GetMountInfo then
			name, spellID, icon = EBS.Action.GetMountInfo(mountId)
		elseif C_MountJournal and C_MountJournal.GetMountInfoByID and mountId then
			name, spellID, icon = C_MountJournal.GetMountInfoByID(mountId)
		end
		if type(name) == "string" and name ~= "" then
			btn.MountName = name
		end
		if type(spellID) == "number" and spellID > 0 then
			btn.MountSpellId = spellID
			if Flux.Spell and Flux.Spell.GetName then
				btn.MountSpellName = Flux.Spell.GetName(spellID) or name or btn.MountSpellName
			elseif name then
				btn.MountSpellName = name
			end
		end
		tex = icon
		if (not tex or tex == "" or tex == QUESTION) and (btn.MountSpellId or spellID) then
			tex = SpellIcon(btn.MountSpellId or spellID)
		end
	elseif t == "flyout" then
		tex = FlyoutIcon(btn.FlyoutId or btn.ActionValue)
	elseif t == "battlepet" then
		local id = btn.BattlePetId or btn.ActionValue
		if id == "BattlePet-0-FFFFFFFFFFFFFF" then
			tex = "Interface/Icons/INV_Pet_Achievement_CaptureAPetFromEachFamily_Battle"
		elseif C_PetJournal and C_PetJournal.GetPetInfoByPetID and id then
			tex = select(9, C_PetJournal.GetPetInfoByPetID(id))
		end
	elseif t == "pet" then
		tex = PetActionTexture(btn)
	elseif t == "shapeshift" then
		local S = Flux.Shapeshift
		local index = btn.ShapeshiftIndex or btn.ActionValue
		if S and S.GetFormInfo and index then
			local texture, _, _, spellID = S.GetFormInfo(index)
			tex = texture
			if spellID then
				btn.SpellId = tonumber(spellID) or btn.SpellId
			end
			-- Stance bar keeps form art. Do not use the spell-action on-state
			-- face (wisp) here.
			if (not tex or tex == "") and btn.SpellId then
				if Flux.Spell and Flux.Spell.GetTexture then
					tex = Flux.Spell.GetTexture(btn.SpellId)
				elseif Flux.Spell and Flux.Spell.GetIcon then
					tex = Flux.Spell.GetIcon(btn.SpellId)
				end
			end
		end
	end
	if t == "pet" then
		SetIconTexture(btn, tex)
		local widget = btn.Widget
		if widget and widget.SetAlpha then
			local show = btn.PetHasAction or (btn.showgrid and btn.showgrid > 0)
			widget:SetAlpha(show and 1 or 0)
		end
	else
		if btn.badgeMode then
			if (not tex or tex == "") and btn._fluxWant and btn._fluxWant.spellId then
				tex = SpellIcon(btn._fluxWant.spellId)
			end
			if (not tex or tex == "") and btn._fluxWant and btn._fluxWant.itemId then
				tex = ItemIcon(btn._fluxWant.itemId)
			end
			-- Unlearned or still-loading spells still occupy the corner.
			if not tex or tex == "" or IsQuestionTex(tex) then
				SetIconTexture(btn, QUESTION)
			else
				SetIconTexture(btn, tex)
			end
		else
			SetIconTexture(btn, (tex and not IsQuestionTex(tex)) and tex or QUESTION)
		end
	end
	UpdateMacroNameOverlay(btn)
end

local function SnapshotStackCount(itemId)
	if not itemId then
		return 0
	end
	if Flux.Inventory and Flux.Inventory.GetCount then
		return SafeNum(Flux.Inventory.GetCount(itemId, BAG_COUNT_OPTS), 0)
	end
	if Flux.Item and Flux.Item.GetCount then
		return SafeNum(Flux.Item.GetCount(itemId, false, false), 0)
	end
	return 0
end

local function LiveChargeCount(itemId)
	if not itemId then
		return 0
	end
	-- Same SoT as combat-grid GemUses / BagCount (not C_Item, which can lag).
	if Flux.Inventory and Flux.Inventory.GetLiveCount then
		return SafeNum(Flux.Inventory.GetLiveCount(itemId, {
			includeBank = false,
			bank = false,
			warband = false,
			charges = true,
		}), 0)
	end
	if Flux.Item and Flux.Item.GetCount then
		return SafeNum(Flux.Item.GetCount(itemId, false, true), 0)
	end
	return 0
end

local function BagsAreReliable()
	local Inv = Flux.Inventory
	if Inv and Inv.IsReliable then
		return Inv.IsReliable() and true or false
	end
	local inv = _G.FluxInv
	if inv and inv.Bags and inv.Bags.IsReliable then
		return inv.Bags.IsReliable() and true or false
	end
	return true
end

local CHARGE_MANA_GEM_IDS = {
	[36799] = true,
	[33312] = true,
	[22044] = true,
}
local ALL_MANA_GEM_IDS = { 36799, 33312, 22044, 8008, 8007, 5513, 5514 }

local function IsChargeBasedManaGem(itemId)
	itemId = tonumber(itemId)
	return itemId and CHARGE_MANA_GEM_IDS[itemId] == true
end

local function IsVanillaManaGem(itemId)
	itemId = tonumber(itemId)
	if not itemId or IsChargeBasedManaGem(itemId) then
		return false
	end
	for i = 1, #ALL_MANA_GEM_IDS do
		if ALL_MANA_GEM_IDS[i] == itemId then
			return true
		end
	end
	return false
end

-- Any owned use: vanilla stack (Jade while Agate is still missing) or remaining charges.
local function AnyManaGemHasRemainingUse()
	for i = 1, #ALL_MANA_GEM_IDS do
		local id = ALL_MANA_GEM_IDS[i]
		if IsChargeBasedManaGem(id) then
			if LiveChargeCount(id) > 0 then
				return true
			end
		elseif SnapshotStackCount(id) > 0 then
			return true
		end
	end
	return false
end

local function IsConsumableItemId(itemId)
	if not itemId then
		return false
	end
	if Flux.Item and Flux.Item.IsConsumable then
		return Flux.Item.IsConsumable(itemId) and true or false
	end
	if C_Item and C_Item.IsConsumableItem then
		local ok, v = pcall(C_Item.IsConsumableItem, itemId)
		if ok and v then
			return true
		end
	end
	if IsConsumableItem then
		local ok, v = pcall(IsConsumableItem, itemId)
		if ok and v then
			return true
		end
	end
	return false
end

-- Extra window / minimap / badges: charged copies show remaining uses (2×3 = 6).
-- Combat gem / healthstone pass preferCopies so two stones show 2, not 6.
-- A single copy still shows remaining uses, including 0.
local function DisplayItemCount(itemId, opts)
	if not itemId then
		return nil
	end
	opts = opts or {}
	-- Flux window / minimap / Extra tab: charged copies show remaining uses.
	local copies = SnapshotStackCount(itemId)
	local uses = LiveChargeCount(itemId)
	if copies > 1 then
		if opts.preferCopies then
			return copies
		end
		if uses > copies then
			return uses
		end
		return copies
	end
	if copies == 0 then
		if IsConsumableItemId(itemId) then
			return 0
		end
		return nil
	end
	-- Zone load: charge count is 0 while the stack is still in bags (mana gem).
	if uses <= 0 then
		if not BagsAreReliable() then
			return copies
		end
		-- Vanilla jade/agate/ruby/citrine: no charges; a bag copy is still a use.
		if copies > 0 and IsVanillaManaGem(itemId) then
			return copies
		end
		if IsConsumableItemId(itemId) then
			return uses
		end
		return nil
	end
	if uses > copies then
		return uses
	end
	if IsConsumableItemId(itemId) then
		return uses
	end
	return nil
end

Paint.DisplayItemCount = DisplayItemCount

local function IsConsumableSpellId(spellId)
	if not spellId then
		return false
	end
	if C_Spell and C_Spell.IsConsumableSpell then
		local ok, v = pcall(C_Spell.IsConsumableSpell, spellId)
		if ok and v then
			return true
		end
	end
	if IsConsumableSpell then
		local ok, v = pcall(IsConsumableSpell, spellId)
		if ok and v then
			return true
		end
	end
	return false
end

local function SetCountText(fontString, value, btn)
	if not fontString then
		return false
	end
	if value == nil then
		value = ""
	end
	local secret = false
	if Flux.Secrets and Flux.Secrets.IsSecretValue then
		local ok, v = pcall(Flux.Secrets.IsSecretValue, value)
		secret = ok and v and true or false
	end
	if secret then
		fontString:Show()
		fontString:SetText(value)
		-- Keep last readable digit so 0-count dim still works when Midnight
		-- writes a secret count in combat.
		return true
	end
	local key
	if value == "" then
		key = ""
	else
		key = tostring(value)
	end
	-- Same rule as bar counts: never Hide. A cache hit still rewrites when
	-- the region is hidden or still blank, or 0→N stays empty forever.
	local hidden = not (fontString.IsShown and fontString:IsShown())
	local blank = false
	if fontString.GetText then
		local current = fontString:GetText()
		local curSecret = false
		if Flux.Secrets and Flux.Secrets.IsSecretValue then
			local ok, v = pcall(Flux.Secrets.IsSecretValue, current)
			curSecret = ok and v and true or false
		end
		if not curSecret then
			blank = current == nil or current == ""
		end
	end
	if btn and btn._lastCountText == key then
		if key == "" then
			if not hidden and blank then
				return false
			end
		elseif not hidden and not blank then
			return false
		end
	elseif btn then
		btn._lastCountText = key
	end
	fontString:Show()
	if key == "" then
		fontString:SetText("")
	else
		fontString:SetText(key)
	end
	return true
end

local function SpellCountText(spellId)
	if not spellId then
		return nil
	end
	spellId = PaintSpell(spellId)
	if Flux.Spell and Flux.Spell.GetDisplayCount then
		local display = Flux.Spell.GetDisplayCount(spellId)
		if display ~= nil then
			return display
		end
	end
	if Flux.Spell and Flux.Spell.GetCount then
		local n = Flux.Spell.GetCount(spellId)
		local secret = false
		if Flux.Secrets and Flux.Secrets.IsSecretValue then
			local ok, v = pcall(Flux.Secrets.IsSecretValue, n)
			secret = ok and v and true or false
		end
		if secret then
			return n
		end
		n = SafeNum(n, 0)
		if n ~= 0 or IsConsumableSpellId(spellId) then
			return n
		end
	end
	if Flux.Spell and Flux.Spell.GetCharges then
		local cur, maxC = Flux.Spell.GetCharges(spellId)
		if cur == nil then
			return nil
		end
		local ok, show = pcall(function()
			if Flux.Secrets and Flux.Secrets.IsSecretValue then
				if Flux.Secrets.IsSecretValue(cur) or Flux.Secrets.IsSecretValue(maxC) then
					return true
				end
			end
			local maxN = SafeNum(maxC, 0)
			return maxN > 1
		end)
		if ok and show then
			return cur
		end
	end
	return nil
end

-- Item charges (mana gem / healthstone) beat the use-spell reagent count of 1.
-- Item 0 must win over spell 1 or the gem count vanishes and the icon stays lit.
local function PreferChargeCount(spellText, itemText)
	if itemText ~= nil then
		return itemText
	end
	return spellText
end

local function ConsumableKindButton(btn)
	return btn and (
		btn.IsManaGemButton
		or btn.IsHealthstoneButton
		or btn.IsHealPotionButton
		or btn.IsHealingPotionButton
		or btn.IsManaPotionButton
		or btn.IsBandageButton
		or btn.IsConsumableButton
		or btn.IsFoodButton
		or btn.IsWaterButton
	) and true or false
end

-- Food/water kind flags stay on while Recuperate is bound. That face is a spell.
local function KindItemCountFace(btn)
	if not ConsumableKindButton(btn) then
		return false
	end
	if btn.IsRecuperateMode then
		return false
	end
	if btn.ActionType == "spell" then
		return false
	end
	return true
end

-- Unique charged items show charges; unique gear hides; copies > 1 or consumable show.
-- Consumable / gem count 0 stays on the button (do not blank the digit).
local function ItemCountText(itemId)
	return DisplayItemCount(itemId)
end

local function ItemSpellId(itemId)
	if not itemId then
		return nil
	end
	if Flux.Item and Flux.Item.GetSpell then
		local ok, a, b = pcall(Flux.Item.GetSpell, itemId)
		if ok then
			return tonumber(b) or tonumber(a)
		end
	end
	return nil
end

function Paint.UpdateCount(btn)
	local count = btn and btn.WCount
	if not count then
		return false
	end
	if btn.badgeMode and EBS.Badge and EBS.Badge.SyncCountFont then
		EBS.Badge.SyncCountFont(btn)
	end
	if btn.PlaceholderHideCount or (btn.PlaceholderTexture and not btn.IsWispLockPlaceholder) then
		btn._forcedCount = nil
		btn._forcedCountLive = nil
		btn._liveCountItemId = nil
		return SetCountText(count, nil, btn)
	end
	-- Combat-swap macro: digit follows the [combat] face, not the home latch.
	if btn._fluxCombatSwapBody then
		if btn.MacroMode == "item" and btn.ItemId then
			local n = DisplayItemCount(btn.ItemId, { preferCopies = true })
			if n == nil then
				n = 0
			end
			btn._forcedCountLive = true
			btn._liveCountItemId = btn.ItemId
			btn._forcedCount = n
			local changed = SetCountText(count, n, btn)
			UpdateMacroNameOverlay(btn)
			return changed
		end
		if btn.MacroMode == "spell" or btn.MacroMode == "" then
			local changed = SetCountText(count, nil, btn)
			UpdateMacroNameOverlay(btn)
			return changed
		end
	end
	-- Forced / live digits (including 0) must survive empty-action and paint
	-- passes. Combat-grid SetCount(0) used to lose the live flag, then this
	-- function blanked the gem/potion 0.
	if btn._forcedCountLive and btn._liveCountItemId and KindItemCountFace(btn) then
		local n = DisplayItemCount(btn._liveCountItemId, {
			preferCopies = ConsumableKindButton(btn),
		})
		if n == nil then
			n = SnapshotStackCount(btn._liveCountItemId)
		end
		if n == nil and ConsumableKindButton(btn) then
			n = 0
		end
		local changed = SetCountText(count, n, btn)
		UpdateMacroNameOverlay(btn)
		return changed
	end
	if btn._forcedCount ~= nil and not btn.IsRecuperateMode and btn.ActionType ~= "spell" then
		local changed = SetCountText(count, btn._forcedCount, btn)
		UpdateMacroNameOverlay(btn)
		return changed
	end
	if KindItemCountFace(btn) then
		local itemId = btn.ItemId or btn._liveCountItemId or MacroShownItem(btn)
		local n = DisplayItemCount(itemId, { preferCopies = true })
		if n == nil then
			n = 0
		end
		local changed = SetCountText(count, n, btn)
		UpdateMacroNameOverlay(btn)
		return changed
	end
	if not btn.ActionType or btn.ActionValue == nil then
		return SetCountText(count, nil, btn)
	end
	local t = btn.ActionType
	if t == "toy" or t == "mount" or t == "flyout" or t == "battlepet" or t == "pet" or t == "shapeshift" then
		return SetCountText(count, nil, btn)
	end
	local text
	if t == "item" then
		local itemId = btn.ItemId or btn.ActionValue
		local sid = ItemSpellId(itemId)
		local spellText = sid and SpellCountText(sid) or nil
		text = PreferChargeCount(spellText, ItemCountText(itemId))
	elseif t == "spell" then
		text = SpellCountText(ShownSpellId(btn))
	elseif IsMacroLike(btn) then
		local iid = MacroShownItem(btn)
		if iid then
			local sid = ItemSpellId(iid)
			local spellText = sid and SpellCountText(sid) or nil
			text = PreferChargeCount(spellText, ItemCountText(iid))
		else
			text = SpellCountText(MacroShownSpell(btn))
		end
	end
	local changed = SetCountText(count, text, btn)
	UpdateMacroNameOverlay(btn)
	return changed
end

local function IsSecretValue(value)
	local S = Flux.Secrets
	if S and S.IsSecretValue then
		local ok, secret = pcall(S.IsSecretValue, value)
		return ok and secret or false
	end
	return false
end

local function CooldownRemain(start, duration)
	if start == nil or duration == nil then
		return 0
	end
	if IsSecretValue(start) or IsSecretValue(duration) then
		return nil
	end
	local s = SafeNum(start, 0)
	local d = SafeNum(duration, 0)
	if s <= 0 or d <= 0 then
		return 0
	end
	local now = GetTime and GetTime() or 0
	local rem = d - (now - s)
	if rem < 0.05 then
		return 0
	end
	return rem
end

-- Extra Buttons are not action slots. Count lives in TextOverlayContainer
-- (often widget+1). Cooldown tracks parent level unless that is turned off,
-- so a bare SetFrameLevel leaves CD under the item/spell digits.
local function RaiseCooldown(btn)
	local widget = btn and btn.Widget
	local cd = btn and btn.WCooldown
	if not widget or not cd or not widget.GetFrameLevel then
		return
	end
	local base = widget:GetFrameLevel() or 0
	if cd.SetUsingParentLevel then
		pcall(cd.SetUsingParentLevel, cd, false)
	elseif cd.SetUseParentLevel then
		pcall(cd.SetUseParentLevel, cd, false)
	end
	if cd.SetIgnoreParentLevel then
		pcall(cd.SetIgnoreParentLevel, cd, true)
	end
	if cd.SetFrameLevel then
		pcall(cd.SetFrameLevel, cd, base + 20)
	end
	local toc = widget.TextOverlayContainer
	if toc and toc.SetFrameLevel then
		pcall(toc.SetFrameLevel, toc, base + 1)
	end
	local count = btn.WCount
	if count and count.SetDrawLayer then
		pcall(count.SetDrawLayer, count, "ARTWORK", 0)
	end
	-- OOC: lift Count out of TextOverlayContainer so OVERLAY draw cannot win.
	if not (InCombatLockdown and InCombatLockdown()) and count and count.SetParent then
		local holder = widget._fluxCountHolder
		if not holder then
			holder = CreateFrame("Frame", nil, widget)
			holder:SetAllPoints(widget)
			if holder.EnableMouse then
				holder:EnableMouse(false)
			end
			widget._fluxCountHolder = holder
		end
		if holder.SetFrameLevel then
			pcall(holder.SetFrameLevel, holder, base + 1)
		end
		local parent = count.GetParent and count:GetParent()
		if parent ~= holder then
			pcall(function()
				count:SetParent(holder)
				count:ClearAllPoints()
				count:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -2, 2)
			end)
		end
	end
	if cd.GetNumRegions then
		local n = cd:GetNumRegions() or 0
		for i = 1, n do
			local r = select(i, cd:GetRegions())
			if r and r.GetObjectType and r:GetObjectType() == "FontString" and r.SetDrawLayer then
				pcall(r.SetDrawLayer, r, "OVERLAY", 7)
			end
		end
	end
end

local function ResolveCooldownFrame(btn)
	local widget = btn and btn.Widget
	local cd = btn and btn.WCooldown
	if cd then
		return cd, widget
	end
	if not widget then
		return nil, nil
	end
	cd = widget.cooldown or widget.Cooldown
	if not cd then
		local name = widget.GetName and widget:GetName()
		if name then
			cd = _G[name .. "Cooldown"]
		end
	end
	if not cd then
		local ok, created = pcall(CreateFrame, "Cooldown", nil, widget, "CooldownFrameTemplate")
		if ok then
			cd = created
		end
	end
	if cd then
		btn.WCooldown = cd
		widget.cooldown = cd
	end
	return cd, widget
end

local function EnsureCooldownFrame(btn)
	local cd, widget = ResolveCooldownFrame(btn)
	if not cd or not widget then
		return nil
	end
	local icon = btn.WIcon or widget.icon or widget.Icon
	cd:ClearAllPoints()
	if icon then
		pcall(cd.SetPoint, cd, "TOPLEFT", icon, "TOPLEFT", 0, 0)
		pcall(cd.SetPoint, cd, "BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
	else
		pcall(cd.SetAllPoints, cd, widget)
	end
	if cd.SetDrawSwipe then
		pcall(cd.SetDrawSwipe, cd, true)
	end
	if cd.SetDrawEdge then
		pcall(cd.SetDrawEdge, cd, false)
	end
	if cd.SetSwipeColor then
		pcall(cd.SetSwipeColor, cd, 0, 0, 0, ACTION_BUTTON_SWIPE_A)
	end
	if cd.EnableMouse then
		pcall(cd.EnableMouse, cd, false)
	end
	RaiseCooldown(btn)
	return cd
end

local function HasPaintableTimer(start, duration)
	if start == nil or duration == nil then
		return false
	end
	if IsSecretValue(start) or IsSecretValue(duration) then
		return true
	end
	local t = type(duration)
	if t == "table" or t == "userdata" then
		return true
	end
	t = type(start)
	if t == "table" or t == "userdata" then
		return true
	end
	return SafeNum(start, 0) > 0 and SafeNum(duration, 0) > 0
end

local function CooldownSet(btn, start, duration, enable, charges, maxCharges, chargeStart, chargeDuration, spellId, fromItem)
	local widget = btn and btn.Widget
	local cd = EnsureCooldownFrame(btn)
	if not cd then
		return
	end
	if widget then
		if fromItem then
			widget.spellID = nil
			widget.action = nil
		elseif spellId then
			widget.spellID = spellId
			widget.action = nil
		end
	end
	local isActive, chargeIsActive
	if not fromItem and spellId and Flux.Spell then
		local ident = PaintSpell(spellId) or spellId
		if Flux.Spell.GetCooldown then
			local _, _, _, _, active = Flux.Spell.GetCooldown(ident)
			isActive = active
		end
		if Flux.Spell.GetCharges then
			local _, _, _, _, _, cActive = Flux.Spell.GetCharges(ident)
			chargeIsActive = cActive
		end
	end
	local durationObject
	-- Items: never GCD duration object. Midnight: duration object when isActive
	-- (NeverSecret). Ready spells must not pick up a GCD duration object.
	if not fromItem and spellId and Flux.Spell and Flux.Spell.GetCooldownDuration then
		if isActive then
			durationObject = Flux.Spell.GetCooldownDuration(spellId)
		elseif IsSecretValue(start) or IsSecretValue(duration) then
			durationObject = Flux.Spell.GetCooldownDuration(spellId)
		else
			local td, ts = type(duration), type(start)
			if td == "table" or td == "userdata" or ts == "table" or ts == "userdata" then
				durationObject = Flux.Spell.GetCooldownDuration(spellId)
			end
		end
	end
	-- Unique extra timers only. GCD-length (duration <= 2) numeric extras
	-- freeze as a frozen full-dark slab. Do not wipe a live duration object.
	-- Ready spells (0, 0) must not pick up a GCD duration object.
	if not fromItem and not durationObject then
		local d = SafeNum(duration, 0)
		if d > 0 and d <= 2 then
			start, duration, enable = 0, 0, 0
		end
	end
	local FX = Flux.ButtonFX and Flux.ButtonFX.Charges
	if FX and FX.Apply and widget then
		local chargeDurationObject
		if spellId and not fromItem and Flux.Spell and Flux.Spell.GetChargeDuration then
			if chargeIsActive ~= false then
				chargeDurationObject = Flux.Spell.GetChargeDuration(spellId)
			end
		end
		FX.Apply(widget, {
			cooldown = cd,
			start = start,
			duration = duration,
			enable = enable,
			current = fromItem and nil or charges,
			maxCharges = fromItem and nil or maxCharges,
			chargeStart = fromItem and nil or chargeStart,
			chargeDuration = fromItem and nil or chargeDuration,
			durationObject = durationObject,
			chargeDurationObject = fromItem and nil or chargeDurationObject,
			spellId = fromItem and nil or spellId,
			itemCooldown = fromItem and true or nil,
			skipDurationObject = fromItem and true or nil,
			isActive = isActive,
			chargeIsActive = chargeIsActive,
			hideWhenIdle = true,
		})
		RaiseCooldown(btn)
		return
	end
	if durationObject and cd.SetCooldownFromDurationObject then
		pcall(cd.SetCooldownFromDurationObject, cd, durationObject)
		if cd.Show then
			pcall(cd.Show, cd)
		end
		RaiseCooldown(btn)
		return
	end
	if IsSecretValue(start) or IsSecretValue(duration) then
		if cd.SetDrawBling then
			pcall(cd.SetDrawBling, cd, false)
		end
		if CooldownFrame_Clear then
			pcall(CooldownFrame_Clear, cd)
		elseif cd.Clear then
			pcall(cd.Clear, cd)
		end
		if cd.Hide then
			pcall(cd.Hide, cd)
		end
		RaiseCooldown(btn)
		return
	end
	local s = SafeNum(start, 0)
	local d = SafeNum(duration, 0)
	local on = not (enable == false or enable == 0)
	if on and d > 0 and s > 0 then
		if CooldownFrame_Set then
			pcall(CooldownFrame_Set, cd, start, duration, true, false)
		elseif cd.SetCooldown then
			pcall(cd.SetCooldown, cd, start, duration)
		end
		if cd.Show then
			pcall(cd.Show, cd)
		end
	else
		if cd.SetDrawBling then
			pcall(cd.SetDrawBling, cd, false)
		end
		if CooldownFrame_Clear then
			pcall(CooldownFrame_Clear, cd)
		elseif cd.Clear then
			pcall(cd.Clear, cd)
		end
		if cd.Hide then
			pcall(cd.Hide, cd)
		end
	end
	RaiseCooldown(btn)
end

local function SpellCooldown(spellId)
	if Flux.Spell and Flux.Spell.GetCooldown then
		return Flux.Spell.GetCooldown(spellId)
	end
	return 0, 0, 0
end

-- ButtonForge Classic/TBC: GetSpellCooldown(SpellNameRank) first. ID can
-- return GCD while the name returns the unique CD (or the reverse). Prefer
-- the unique timer (remain > 2), else the name, else the id.
local function SpellCooldownForButton(btn, spellId)
	local name = btn and (btn.SpellNameRank or btn.SpellName)
	local sName, dName, eName, mName
	if name and name ~= spellId then
		sName, dName, eName, mName = SpellCooldown(name)
	end
	local sId, dId, eId, mId = SpellCooldown(spellId)
	local rName = sName ~= nil and CooldownRemain(sName, dName) or 0
	local rId = CooldownRemain(sId, dId)
	if rName and rName > 2 then
		return sName, dName, eName, mName
	end
	if rId and rId > 2 then
		return sId, dId, eId, mId
	end
	if rName and rName > 0 then
		return sName, dName, eName, mName
	end
	if rId and rId > 0 then
		return sId, dId, eId, mId
	end
	if sName ~= nil then
		return sName, dName, eName, mName
	end
	return sId, dId, eId, mId
end

local function SpellCharges(spellId)
	if not spellId or not Flux.Spell or not Flux.Spell.GetCharges then
		return nil
	end
	return Flux.Spell.GetCharges(PaintSpell(spellId))
end

-- "empty" = 0 of a charged spell. "ready" = >=1. "none" = not charged.
local function ChargeReadyState(btn, spellId)
	local cur, maxC = SpellCharges(spellId)
	if cur == nil and maxC == nil then
		if btn then
			btn._fxChargeCur = nil
			btn._fxChargeMax = nil
		end
		return "none"
	end
	local secret = false
	if Flux.Secrets and Flux.Secrets.IsSecretValue then
		if Flux.Secrets.IsSecretValue(cur) or Flux.Secrets.IsSecretValue(maxC) then
			secret = true
		end
	end
	if secret then
		cur = btn and btn._fxChargeCur
		maxC = btn and btn._fxChargeMax
		if cur == nil or maxC == nil then
			return nil
		end
	else
		maxC = tonumber(maxC) or 0
		cur = tonumber(cur) or 0
		if btn then
			btn._fxChargeCur = cur
			btn._fxChargeMax = maxC
		end
	end
	if maxC <= 1 then
		return "none"
	end
	if cur <= 0 then
		return "empty"
	end
	return "ready"
end

local function ItemCooldown(itemId)
	if Flux.Item and Flux.Item.GetCooldown then
		return Flux.Item.GetCooldown(itemId)
	end
	if not itemId then
		return 0, 0, 0
	end
	if C_Item and C_Item.GetItemCooldown then
		local info = C_Item.GetItemCooldown(itemId)
		if type(info) == "table" then
			return info.startTime, info.duration, info.isEnabled
		end
		return C_Item.GetItemCooldown(itemId)
	end
	if C_Container and C_Container.GetItemCooldown then
		return C_Container.GetItemCooldown(itemId)
	end
	if GetItemCooldown then
		return GetItemCooldown(itemId)
	end
	return 0, 0, 0
end

local function ApplyButtonCountdownScale(btn)
	local widget = btn and btn.Widget
	local cd = btn and (btn.WCooldown or (widget and (widget.cooldown or widget.Cooldown)))
	if not cd or not widget then
		return
	end
	-- Mage-armor / consumable-buff remaining uses our own FontString. Blizzard CD digits ignore SetFont
	-- on extra-sized slots and must stay hidden while the aura timer is live.
	if btn.FluxStanceManagedCooldown or btn.FluxConsumableAuraCooldown then
		if cd.SetHideCountdownNumbers then
			pcall(cd.SetHideCountdownNumbers, cd, true)
		end
		cd.noCooldownCount = true
		local Stance = Flux.Bars and Flux.Bars.Stance
		if Stance and Stance.SyncAuraCountdown then
			Stance.SyncAuraCountdown(btn)
		end
		return
	end
	if cd._fluxHideCountdownNumbers then
		if cd.SetHideCountdownNumbers then
			pcall(cd.SetHideCountdownNumbers, cd, true)
		end
		return
	end
	if cd.SetHideCountdownNumbers then
		pcall(cd.SetHideCountdownNumbers, cd, false)
	end
	cd._fluxForceDigitScale = true
	local w = widget.GetWidth and widget:GetWidth() or 0
	local h = widget.GetHeight and widget:GetHeight() or 0
	if not w or w < 1 then
		w = 32
	end
	if not h or h < 1 then
		h = w
	end
	local Util = _G.FluxButtonUtil
	if Util and Util.ApplyCooldownCountdownHorizontalScale then
		Util:ApplyCooldownCountdownHorizontalScale(cd, widget, w, h)
	end
end

local ApplyStanceBuffCountdownScale = ApplyButtonCountdownScale

-- ActionButtonTemplate.xml: Classic uses a=0.8, Retail uses a=0.64.
-- Match Blizzard's default cooldown transparency per client.
local ACTION_BUTTON_SWIPE_A
if Flux.Client and Flux.Client.isAnyClassic then
	ACTION_BUTTON_SWIPE_A = 0.8
else
	ACTION_BUTTON_SWIPE_A = 0.64
end

local function PublicPaintNumber(v)
	if v == nil then
		return nil
	end
	local S = Flux.Secrets
	if S then
		if S.IsSecretValue and S.IsSecretValue(v) then
			return nil
		end
		if S.CanAccessValue and not S.CanAccessValue(v) then
			return nil
		end
	end
	local n = tonumber(v)
	if type(n) == "number" and n == n and n < math.huge and n > -math.huge then
		return n
	end
	return nil
end

-- Combat-potion extras: show remaining self-buff when there is no real item lockout.
-- Food/water extras must keep item/spell CD (eat, drink, Recuperate). Well Fed
-- remaining belongs on the consumables extra, not the eat/drink buttons.
local function IsEatDrinkExtra(btn)
	if not btn then
		return false
	end
	-- Swapped buttons show food/water out of combat and a potion in combat.
	if btn._fluxCombatSwapBody then
		return not (InCombatLockdown and InCombatLockdown())
	end
	return (btn.IsFoodButton or btn.IsWaterButton) and true or false
end

local function ClearClaimedConsumableAura(btn)
	if not btn then
		return
	end
	btn.FluxConsumableAuraCooldown = nil
	btn.StanceBuffCooldownStart = nil
	btn.StanceBuffCooldownDuration = nil
	btn.StanceBuffDurationObject = nil
	btn.StanceBuffExpirationTime = nil
	btn.StanceBuffTimeMod = nil
	local Stance = Flux.Bars and Flux.Bars.Stance
	if Stance and Stance.SyncAuraCountdown then
		Stance.SyncAuraCountdown(btn)
	end
end

local function ClaimConsumableItemAura(btn, itemId, itemDuration)
	if not btn or btn.IsConsumableButton or IsEatDrinkExtra(btn) then
		return false
	end
	if not itemId then
		return false
	end
	if not (ConsumableKindButton(btn) or IsConsumableItemId(itemId)) then
		return false
	end
	local itemDur = PublicPaintNumber(itemDuration)
	if itemDur and itemDur > 2.05 then
		return false
	end
	local Aura = Flux.Aura
	local spellId = ItemSpellId(itemId)
	if not (spellId and Aura and Aura.GetPlayerAuraBySpellID) then
		return false
	end
	local auraId = spellId
	if Aura.GetCooldownAuraBySpellID then
		auraId = Aura.GetCooldownAuraBySpellID(spellId) or spellId
	end
	local data = Aura.GetPlayerAuraBySpellID(auraId)
	if not data and auraId ~= spellId then
		data = Aura.GetPlayerAuraBySpellID(spellId)
	end
	if not data then
		return false
	end
	local exp, dur, inst, tmod
	pcall(function()
		exp = data.expirationTime
		dur = data.duration
		inst = data.auraInstanceID
		tmod = data.timeMod
	end)
	local expN = PublicPaintNumber(exp)
	local durN = PublicPaintNumber(dur)
	local instN = PublicPaintNumber(inst)
	local durObj
	if instN and Aura.GetAuraDuration then
		durObj = Aura.GetAuraDuration("player", instN)
	end
	local now = (GetTime and GetTime()) or 0
	if not ((expN and expN > now + 0.05) or durObj) then
		return false
	end
	local rem = 0
	if expN then
		rem = expN - now
	end
	if rem <= 1.5 and not durObj then
		return false
	end
	btn.FluxConsumableAuraCooldown = true
	btn.StanceBuffExpirationTime = expN
	btn.StanceBuffCooldownDuration = durN
	btn.StanceBuffDurationObject = durObj
	btn.StanceBuffTimeMod = PublicPaintNumber(tmod)
	if expN and durN and durN > 0 then
		btn.StanceBuffCooldownStart = expN - durN
	end
	return true
end

local function ApplyStanceAuraSwipeLook(cd, on)
	if not cd then
		return
	end
	if cd.SetUseAuraDisplayTime then
		pcall(cd.SetUseAuraDisplayTime, cd, on and true or false)
	end
	if cd.SetSwipeColor then
		if on then
			pcall(cd.SetSwipeColor, cd, 0, 0, 0, ACTION_BUTTON_SWIPE_A)
		else
			pcall(cd.SetSwipeColor, cd, 0, 0, 0, ACTION_BUTTON_SWIPE_A)
		end
	end
end

function Paint.UpdateCooldown(btn)
	if not btn then
		return
	end
	if not EnsureCooldownFrame(btn) then
		return
	end
	if IsEatDrinkExtra(btn) and btn.FluxConsumableAuraCooldown then
		ClearClaimedConsumableAura(btn)
	end
	if btn.FluxConsumableAuraCooldown and not btn.FluxStanceManagedCooldown then
		local exp = PublicPaintNumber(btn.StanceBuffExpirationTime)
		local now = (GetTime and GetTime()) or 0
		if (exp and exp <= now + 0.05) and not btn.StanceBuffDurationObject then
			btn.FluxConsumableAuraCooldown = nil
			btn.StanceBuffCooldownStart = nil
			btn.StanceBuffCooldownDuration = nil
			btn.StanceBuffDurationObject = nil
			btn.StanceBuffExpirationTime = nil
			btn.StanceBuffTimeMod = nil
		end
	end
	if btn.FluxStanceManagedCooldown or btn.FluxConsumableAuraCooldown then
		local widget = btn.Widget
		local cd = EnsureCooldownFrame(btn)
		local FX = Flux.ButtonFX and Flux.ButtonFX.Charges
		ApplyStanceAuraSwipeLook(cd, true)
		if FX and FX.Apply and widget then
			FX.Apply(widget, {
				cooldown = cd,
				start = btn.StanceBuffCooldownStart,
				duration = btn.StanceBuffCooldownDuration,
				enable = true,
				durationObject = btn.StanceBuffDurationObject,
				expirationTime = btn.StanceBuffExpirationTime,
				modRate = btn.StanceBuffTimeMod,
				-- Skip the spell GCD duration object. Keep an explicit aura object.
				skipDurationObject = not btn.StanceBuffDurationObject,
				hideWhenIdle = true,
			})
		elseif btn.StanceBuffDurationObject and cd and cd.SetCooldownFromDurationObject then
			pcall(cd.SetCooldownFromDurationObject, cd, btn.StanceBuffDurationObject)
		elseif btn.StanceBuffExpirationTime and btn.StanceBuffCooldownDuration and cd and cd.SetCooldownFromExpirationTime then
			pcall(cd.SetCooldownFromExpirationTime, cd, btn.StanceBuffExpirationTime, btn.StanceBuffCooldownDuration, btn.StanceBuffTimeMod or 1)
		else
			CooldownSet(btn, btn.StanceBuffCooldownStart, btn.StanceBuffCooldownDuration, true)
		end
		-- After Charges (which tints swipe a=1 once). Aura remaining must match
		-- the action-bar overlay, not Extra GCD black.
		ApplyStanceAuraSwipeLook(cd, true)
		ApplyButtonCountdownScale(btn)
		return
	end
	local widget = btn.Widget
	local cd = widget and (btn.WCooldown or widget.cooldown or widget.Cooldown)
	ApplyStanceAuraSwipeLook(cd, false)
	if not btn.ActionType or btn.ActionValue == nil then
		CooldownSet(btn, 0, 0, 0)
		ApplyButtonCountdownScale(btn)
		return
	end
	local t = btn.ActionType
	local start, duration, enable = 0, 0, 0
	local charges, maxCharges, chargeStart, chargeDuration
	local spellId
	local fromItem
	if t == "spell" then
		spellId = PaintSpell(ShownSpellId(btn))
		start, duration, enable = SpellCooldownForButton(btn, spellId)
		charges, maxCharges, chargeStart, chargeDuration = SpellCharges(spellId)
	elseif t == "item" or t == "toy" then
		local itemId = btn.ItemId or btn.ToyId or btn.ActionValue
		start, duration, enable = ItemCooldown(itemId)
		fromItem = true
		spellId = ItemSpellId(itemId)
		if spellId then
			charges, maxCharges, chargeStart, chargeDuration = SpellCharges(spellId)
		end
	elseif IsMacroLike(btn) then
		spellId = MacroShownSpell(btn)
		if spellId then
			start, duration, enable = SpellCooldownForButton(btn, spellId)
			charges, maxCharges, chargeStart, chargeDuration = SpellCharges(spellId)
		else
			local iid = MacroShownItem(btn)
			if iid then
				start, duration, enable = ItemCooldown(iid)
				fromItem = true
				spellId = ItemSpellId(iid)
				if spellId then
					charges, maxCharges, chargeStart, chargeDuration = SpellCharges(spellId)
				end
			end
		end
	elseif t == "mount" and btn.MountSpellId then
		if Flux.Client and Flux.Client.isMidnight then
			CooldownSet(btn, 0, 0, 0)
			ApplyButtonCountdownScale(btn)
			return
		end
		spellId = btn.MountSpellId
		start, duration, enable = SpellCooldownForButton(btn, spellId)
	elseif t == "pet" then
		local P = Flux.Pet
		local slot = btn.PetSlot or btn.ActionValue
		if P and P.GetActionCooldown and slot then
			start, duration, enable = P.GetActionCooldown(slot)
		end
		spellId = btn.SpellId
	elseif t == "shapeshift" then
		local S = Flux.Shapeshift
		local index = btn.ShapeshiftIndex or btn.ActionValue
		if S and S.GetFormCooldown and index then
			start, duration, enable = S.GetFormCooldown(index)
		end
		spellId = btn.SpellId
	end
	if fromItem and ClaimConsumableItemAura(btn, btn.ItemId or btn.ToyId or btn.ActionValue, duration) then
		return Paint.UpdateCooldown(btn)
	end
	CooldownSet(btn, start, duration, enable, charges, maxCharges, chargeStart, chargeDuration, spellId, fromItem)
	ApplyButtonCountdownScale(btn)
	local charge = ChargeReadyState(btn, spellId)
	local prev = btn._fxChargeState
	local active = btn._fxCdActive
	if not (IsSecretValue(duration) or IsSecretValue(enable)) then
		local dur = tonumber(duration) or 0
		local en = tonumber(enable)
		active = dur > 0 and en ~= 0
	end
	if btn._fxCdActive and not active then
		local maxC = btn._fxChargeMax
		if (charge == "empty" or charge == nil) and maxC and maxC > 1 then
			local cur = btn._fxChargeCur or 0
			if cur < maxC then
				btn._fxChargeCur = cur + 1
				charge = ChargeReadyState(btn, spellId)
			end
		end
	end
	btn._fxCdActive = active
	btn._fxChargeState = charge
	if charge ~= prev and (charge == "ready" or charge == "empty") then
		Paint.UpdateUsable(btn)
	end
end

function Paint.UpdateAllCooldowns()
	local list = EBS.buttons
	if not list then
		return
	end
	for i = 1, #list do
		local btn = list[i]
		if btn and btn.ActionType and not Paint.IsParked(btn) then
			pcall(Paint.UpdateCooldown, btn)
		end
	end
end

local function CanAccess(value)
	if value == nil then
		return true
	end
	if Flux.Secrets and Flux.Secrets.CanAccessValue then
		local ok, accessible = pcall(Flux.Secrets.CanAccessValue, value)
		if ok then
			return accessible and true or false
		end
	end
	return true
end

-- true / false / nil. Never compare secret values directly (Midnight).
local function AsBool(value)
	if value == nil then
		return nil
	end
	if not CanAccess(value) then
		return nil
	end
	if Flux.Secrets and Flux.Secrets.SafeBooleanTest then
		return Flux.Secrets.SafeBooleanTest(value, nil)
	end
	local ok, isTrue = pcall(function()
		return value == true or value == 1
	end)
	if ok and isTrue then
		return true
	end
	local okFalse, isFalse = pcall(function()
		return value == false or value == 0
	end)
	if okFalse and isFalse then
		return false
	end
	local okTruth, truthy = pcall(function()
		if value then
			return true
		end
		return false
	end)
	if okTruth then
		return truthy
	end
	return nil
end

-- Returns usable, noMana. Both nil means unknown — do not gray.
local function SpellUsable(spellId)
	if not spellId then
		return nil, nil
	end
	spellId = PaintSpell(spellId)
	if Flux.Spell and Flux.Spell.IsUsable then
		return Flux.Spell.IsUsable(spellId)
	end
	return nil, nil
end

local function ItemUsable(itemId)
	if not itemId then
		return nil, nil
	end
	if Flux.Item and Flux.Item.IsUsable then
		return Flux.Item.IsUsable(itemId)
	end
	return nil, nil
end

local function ItemSpellIdent(itemId)
	if not itemId or not Flux.Item or not Flux.Item.GetSpell then
		return nil
	end
	local name, spellId = Flux.Item.GetSpell(itemId)
	if type(spellId) == "number" and spellId > 0 then
		return spellId
	end
	if type(name) == "string" and name ~= "" then
		return name
	end
	return nil
end

local function HasToy(toyId)
	if not toyId or not PlayerHasToy then
		return false
	end
	local ok, has = pcall(PlayerHasToy, toyId)
	return ok and AsBool(has) == true
end

local function ProfessionNameSet()
	if professionNameSet then
		return professionNameSet
	end
	professionNameSet = {}
	if not GetProfessions or not GetProfessionInfo then
		return professionNameSet
	end
	local ok, p1, p2, arch, fish, cook = pcall(GetProfessions)
	if not ok then
		return professionNameSet
	end
	local function add(idx)
		if not idx then
			return
		end
		local name = GetProfessionInfo(idx)
		if type(name) == "string" and name ~= "" then
			professionNameSet[name] = true
		end
	end
	add(p1)
	add(p2)
	add(arch)
	add(fish)
	add(cook)
	return professionNameSet
end

local function IsProfessionSpell(spellId)
	if not spellId then
		return false
	end
	local name = Flux.Spell and Flux.Spell.GetName and Flux.Spell.GetName(spellId)
	if not name then
		return false
	end
	return ProfessionNameSet()[name] and true or false
end

-- Owned toys stay clickable without a bag copy, but indoor/combat/etc. still
-- comes from the toy's spell (and ToyBox/item APIs). Never force white on own.
local function ToyUsable(toyId)
	if not toyId then
		return false, false
	end
	if not HasToy(toyId) then
		return false, false
	end
	local spell = ItemSpellIdent(toyId)
	if spell then
		local usable, noMana = SpellUsable(spell)
		if usable ~= nil then
			return usable, noMana
		end
	end
	if C_ToyBox and C_ToyBox.GetToyInfo then
		local ok, _, toyName = pcall(C_ToyBox.GetToyInfo, toyId)
		if ok and type(toyName) == "string" and toyName ~= "" then
			local usable, noMana = SpellUsable(toyName)
			if usable ~= nil then
				return usable, noMana
			end
		end
	end
	if C_ToyBox and C_ToyBox.IsToyUsable then
		local ok, v = pcall(C_ToyBox.IsToyUsable, toyId)
		if ok and AsBool(v) == false then
			return false, false
		end
	end
	local usable, noMana = ItemUsable(toyId)
	if usable == true then
		return true, noMana
	end
	-- Item.IsUsable is false for many toys that are not in bags — do not gray
	-- solely from that. Owned + no spell result = assume usable.
	return true, false
end

local function CombineItemUsable(itemId)
	if not itemId then
		return nil, nil
	end
	if HasToy(itemId) then
		return ToyUsable(itemId)
	end
	local iu, im = ItemUsable(itemId)
	local spell = ItemSpellIdent(itemId)
	local su, sm
	if spell then
		su, sm = SpellUsable(spell)
	end
	-- Item.IsUsable is false while GetItemCount is still 0 after a loading screen.
	if iu == false and SnapshotStackCount(itemId) > 0 then
		iu = true
	end
	if su == false or iu == false then
		local noMana = (sm == true) or (im == true)
		return false, noMana
	end
	if su == true or iu == true then
		return true, (sm == true) or (im == true)
	end
	return nil, nil
end

local function ItemIsEquipped(itemId)
	if not itemId then
		return false
	end
	if Flux.Item and Flux.Item.IsEquipped then
		return Flux.Item.IsEquipped(itemId) and true or false
	end
	if C_Item and C_Item.IsEquippedItem then
		local ok, v = pcall(C_Item.IsEquippedItem, itemId)
		if ok and v then
			return true
		end
	elseif IsEquippedItem then
		local ok, v = pcall(IsEquippedItem, itemId)
		if ok and v then
			return true
		end
	end
	return false
end

-- Mana gem / emerald / WotLK sapphire and the rest of the consumable grid:
-- IsUsableItem stays true at 0 charges. Darken when bags are empty.
local function EmptyConsumableUnusable(btn, itemId)
	-- Recuperate (spell on the food Extra) uses SpellUsable like Extra window spells.
	if btn.IsRecuperateMode or btn.ActionType == "spell" then
		return false
	end
	-- Portal hold: snapshot count is still on the button, bags read 0.
	if btn._forcedCount ~= nil and not btn._forcedCountLive then
		local held = tonumber(btn._forcedCount)
		if held and held > 0 then
			return false
		end
	end
	-- Missing conjure ranks (Agate while Jade is in bags) must not gray the
	-- owned gem. Charge leftovers (emerald 0/3) still count as empty.
	if btn.IsManaGemButton then
		return not AnyManaGemHasRemainingUse()
	end
	-- The digit on the button is the source of truth (ApplyGemCount writes 0
	-- after FullRefresh, while C_Item / the bag snapshot can still say 1).
	if btn._forcedCount ~= nil and tonumber(btn._forcedCount) == 0 then
		return true
	end
	if btn._lastCountText == "0" then
		return true
	end
	-- Two bag copies stay usable while any copy remains (do not wait for summed uses).
	if itemId and SnapshotStackCount(itemId) > 1 then
		return false
	end
	if ConsumableKindButton(btn) then
		if btn.WCount and btn.WCount.GetText then
			local ok, text = pcall(btn.WCount.GetText, btn.WCount)
			if ok and text == "0" then
				return true
			end
		end
	end
	if not itemId then
		return false
	end
	if HasToy(itemId) or ItemIsEquipped(itemId) then
		return false
	end
	local copies = SnapshotStackCount(itemId)
	-- Two bag copies stay usable while any copy remains (do not wait for summed uses).
	if copies > 1 then
		return false
	end
	local charges = LiveChargeCount(itemId)
	local kind = ConsumableKindButton(btn) or IsConsumableItemId(itemId)
	if not kind then
		return false
	end
	-- Zone load: charge APIs are 0 while the stack is still in the snapshot.
	if not BagsAreReliable() and copies > 0 then
		return false
	end
	if charges > 0 then
		return false
	end
	-- Unique emerald / sapphire / Mana Gem: leftover stack of 1, 0 charges.
	-- Vanilla single-use gems never reach here (IsManaGemButton returned above).
	return true
end

local function MountEnvBlocked()
	if InCombatLockdown and InCombatLockdown() then
		return true
	end
	if IsIndoors then
		local ok, indoors = pcall(IsIndoors)
		if ok and AsBool(indoors) == true then
			return true
		end
	end
	return false
end

local function ApplyIconColor(btn, r, g, b)
	if btn.WIcon then
		btn.WIcon:SetVertexColor(r, g, b)
		ApplyIconDesat(btn)
	end
end

local function ApplyRingUsable(btn, noMana)
	local tex = btn.WNormalTexture
	if not tex or not tex.SetVertexColor then
		return
	end
	local scope = btn.categoryScope
	if noMana == true then
		tex:SetVertexColor(COLOR_MANA[1], COLOR_MANA[2], COLOR_MANA[3], 1)
		return
	end
	if scope == "character" or scope == "class" then
		local cr, cg, cb = ThemedRGB(btn)
		tex:SetVertexColor(cr, cg, cb, 1)
	else
		tex:SetVertexColor(1, 1, 1, 1)
	end
end

local function ApplyUsableVisual(btn, r, g, b, noMana)
	local mana = noMana and true or false
	if btn._lastIconR == r and btn._lastIconG == g and btn._lastIconB == b and btn._lastRingMana == mana then
		return
	end
	btn._lastIconR = r
	btn._lastIconG = g
	btn._lastIconB = b
	btn._lastRingMana = mana
	ApplyIconColor(btn, r, g, b)
	ApplyRingUsable(btn, mana)
end

local function KeepOr(btn, field, value)
	if value ~= nil then
		btn[field] = value
		return value
	end
	if btn[field] ~= nil then
		return btn[field]
	end
	return true
end

function Paint.UpdateUsable(btn)
	if not btn or not btn.WIcon then
		return
	end
	if btn.PlaceholderTexture then
		if btn.IsWispLockPlaceholder then
			return
		end
		ApplyPlaceholderIcon(btn)
		return
	end
	-- Ammo is a display-only equipped-item indicator, not an item-use action.
	-- IsUsableItem can return false for infinite/durability-based throwing knives.
	if btn.IgnoreUsabilityVisual then
		btn._outOfRange = false
		btn._fluxRankDesaturated = false
		if btn.Widget then btn.Widget._fluxRankDesaturated = false end
		ApplyUsableVisual(btn, 1, 1, 1, false)
		return
	end
	if not btn.ActionType or btn.ActionValue == nil then
		btn._fluxRankDesaturated = false
		if btn.Widget then
			btn.Widget._fluxRankDesaturated = false
		end
		ApplyUsableVisual(btn, 1, 1, 1, false)
		return
	end
	local SRM = _G.FluxSpellRankManager
	if SRM and SRM.ApplyRankDesaturation then
		local sid
		if btn.ActionType == "spell" then
			sid = ShownSpellId(btn)
		elseif IsMacroLike(btn) then
			sid = MacroShownSpell(btn) or btn.SpellId
		else
			sid = btn.SpellId
		end
		SRM:ApplyRankDesaturation(btn, sid)
	end
	if btn._outOfRange then
		ApplyUsableVisual(btn, COLOR_OOR[1], COLOR_OOR[2], COLOR_OOR[3], false)
		return
	end
	local usable, noMana
	local t = btn.ActionType
	if t == "spell" then
		local sid = ShownSpellId(btn)
		if IsProfessionSpell(sid) then
			usable = true
			noMana = false
		else
			usable, noMana = SpellUsable(sid)
		end
	elseif t == "toy" then
		usable, noMana = ToyUsable(btn.ToyId or btn.ItemId or btn.ActionValue)
	elseif t == "item" then
		if btn.IsManaGemButton then
			-- Mana gem usable tint ignores item-use spell / IsUsableItem
			-- (false on cooldown and at full mana). Count/charges tint below.
			usable = true
			noMana = false
		else
			usable, noMana = CombineItemUsable(btn.ItemId or btn.ActionValue)
		end
	elseif IsMacroLike(btn) then
		if btn.IsManaGemButton then
			usable = true
			noMana = false
		else
			local spell = MacroShownSpell(btn)
			if spell then
				usable, noMana = SpellUsable(spell)
			else
				local iid = MacroShownItem(btn)
				if iid then
					usable, noMana = CombineItemUsable(iid)
				else
					usable = true
					noMana = false
				end
			end
		end
	elseif t == "mount" then
		usable = true
		noMana = false
		if MountEnvBlocked() then
			usable = false
		end
		if usable and btn.MountSpellId then
			local spellOk, spellMana = SpellUsable(btn.MountSpellId)
			if spellOk == false then
				usable = false
				noMana = spellMana
			end
		end
		if usable ~= false and btn.MountId and btn.MountId ~= RANDOM_MOUNT_ID
			and C_MountJournal and C_MountJournal.GetMountInfoByID then
			local ok, isUsable = pcall(function()
				return select(5, C_MountJournal.GetMountInfoByID(btn.MountId))
			end)
			if ok and AsBool(isUsable) == false then
				usable = false
			end
		end
	elseif t == "flyout" then
		usable = true
		noMana = false
	elseif t == "battlepet" then
		usable = not (UnitIsDead and UnitIsDead("player"))
		noMana = false
	elseif t == "pet" then
		local P = Flux.Pet
		local slot = btn.PetSlot or btn.ActionValue
		usable = true
		noMana = false
		if P and P.IsSlotUsable and slot then
			usable = P.IsSlotUsable(slot)
		end
	elseif t == "shapeshift" then
		local S = Flux.Shapeshift
		local index = btn.ShapeshiftIndex or btn.ActionValue
		usable = true
		noMana = false
		if S and S.GetFormInfo and index then
			local _, _, isCastable = S.GetFormInfo(index)
			if isCastable == false then
				usable = false
			end
		end
	else
		usable = true
		noMana = false
	end

	-- NC mount hosts stay macrotext; apply the same indoor/combat / journal
	-- gate Extra uses for ActionType mount.
	if usable ~= false and (btn.IsMountButton or btn.IsUnifiedMountButton
		or btn.MountSpellId or btn.MountId) then
		if MountEnvBlocked() then
			usable = false
			noMana = false
		end
		if usable ~= false and btn.MountId and btn.MountId ~= RANDOM_MOUNT_ID
			and C_MountJournal and C_MountJournal.GetMountInfoByID then
			local ok, isUsable = pcall(function()
				return select(5, C_MountJournal.GetMountInfoByID(btn.MountId))
			end)
			if ok and AsBool(isUsable) == false then
				usable = false
			end
		end
	end

	local itemId = btn.ItemId
	if not itemId and t == "item" then
		itemId = btn.ActionValue
	end
	if not itemId then
		itemId = MacroShownItem(btn)
	end

	local sid
	if t == "spell" then
		sid = ShownSpellId(btn)
	elseif IsMacroLike(btn) then
		sid = MacroShownSpell(btn) or btn.SpellId
	else
		sid = btn.SpellId
	end
	local charge = ChargeReadyState(btn, sid)
	-- Item-use spell charges are not the gem's bag charges; 0 of that spell
	-- would keep a bound mana gem darkened even with uses left.
	if charge == "empty" and not btn.IsManaGemButton then
		btn._lastUsable = false
		ApplyUsableVisual(btn, COLOR_UNUSABLE[1], COLOR_UNUSABLE[2], COLOR_UNUSABLE[3], false)
		return
	end

	-- 0-charge mana gem / last potion: skip KeepOr so a leftover true does not stay lit.
	-- Firm 0-count wins even if a use-spell still looks charged.
	if EmptyConsumableUnusable(btn, itemId) then
		btn._lastUsable = false
		ApplyUsableVisual(btn, COLOR_UNUSABLE[1], COLOR_UNUSABLE[2], COLOR_UNUSABLE[3], false)
		return
	end

	usable = AsBool(usable)
	-- KeepOr of a leftover false is why 0→1 charges stayed gray when
	-- IsUsable was still nil/false for a frame after the swipe ended.
	if charge == "ready" then
		if usable == false then
			usable = true
		elseif usable == nil then
			usable = true
		end
		btn._lastUsable = usable
	else
		usable = KeepOr(btn, "_lastUsable", usable)
	end
	noMana = AsBool(noMana)
	if noMana == nil then
		noMana = btn._lastNoMana or false
	else
		btn._lastNoMana = noMana
	end

	if noMana == true then
		ApplyUsableVisual(btn, COLOR_MANA[1], COLOR_MANA[2], COLOR_MANA[3], true)
	elseif usable == false then
		ApplyUsableVisual(btn, COLOR_UNUSABLE[1], COLOR_UNUSABLE[2], COLOR_UNUSABLE[3], false)
	else
		ApplyUsableVisual(btn, COLOR_USABLE[1], COLOR_USABLE[2], COLOR_USABLE[3], false)
	end
end

function Paint.NotePlayerCast(spellId)
	spellId = tonumber(spellId)
	if not spellId or spellId <= 0 then
		return
	end
	local function one(btn)
		if not btn or Paint.IsParked(btn) then
			return
		end
		local sid
		if btn.ActionType == "spell" then
			sid = ShownSpellId(btn)
		elseif IsMacroLike(btn) then
			sid = MacroShownSpell(btn) or btn.SpellId
		else
			sid = btn.SpellId
		end
		local itemId = btn.ItemId
		if not itemId and btn.ActionType == "item" then
			itemId = btn.ActionValue
		end
		if not itemId then
			itemId = MacroShownItem(btn)
		end
		local itemSpell = ItemSpellId(itemId)
		if sid ~= spellId and itemSpell ~= spellId then
			return
		end
		local cur, maxC = SpellCharges(sid or itemSpell or spellId)
		local chargeSecret = false
		if Flux.Secrets and Flux.Secrets.IsSecretValue then
			if Flux.Secrets.IsSecretValue(cur) or Flux.Secrets.IsSecretValue(maxC) then
				chargeSecret = true
			end
		end
		local prev = btn._lastCountText
		Paint.UpdateCount(btn)
		if chargeSecret and btn._fxChargeCur and btn._fxChargeCur > 0 then
			btn._fxChargeCur = btn._fxChargeCur - 1
		end
		if (btn.ActionType == "item" or ConsumableKindButton(btn)) and btn._lastCountText == prev then
			local n = tonumber(prev)
			if n and n > 0 then
				SetCountText(btn.WCount, n - 1, btn)
			end
		end
		Paint.UpdateUsable(btn)
	end
	local list = EBS.buttons
	if list then
		for i = 1, #list do
			one(list[i])
		end
	end
	local badges = EBS.badges
	if badges then
		for i = 1, #badges do
			one(badges[i])
		end
	end
end

local function SpellIsCurrent(spellId, nameRank)
	local S = Flux.Spell
	if S and S.IsCurrent then
		if S.IsCurrent(spellId, nameRank) then
			return true
		end
		if S.IsAutoRepeat and S.IsAutoRepeat(spellId, nameRank) then
			return true
		end
		return false
	end
	if not spellId and (type(nameRank) ~= "string" or nameRank == "") then
		return false
	end
	local ident = PaintSpell(spellId) or nameRank
	if C_Spell then
		if C_Spell.IsCurrentSpell then
			local ok, v = pcall(C_Spell.IsCurrentSpell, ident)
			if ok and v then
				return true
			end
		end
		if C_Spell.IsAutoRepeatSpell then
			local ok, v = pcall(C_Spell.IsAutoRepeatSpell, ident)
			if ok and v then
				return true
			end
		end
	end
	if IsCurrentSpell then
		local ok, v = pcall(IsCurrentSpell, ident)
		if ok and v then
			return true
		end
	end
	if nameRank and nameRank ~= ident then
		if IsCurrentSpell then
			local ok, v = pcall(IsCurrentSpell, nameRank)
			if ok and v then
				return true
			end
		end
	end
	if IsAutoRepeatSpell then
		local ok, v = pcall(IsAutoRepeatSpell, ident)
		if ok and v then
			return true
		end
	end
	return false
end

local function ItemIsCurrent(itemId)
	if Flux.Item and Flux.Item.IsCurrent then
		return Flux.Item.IsCurrent(itemId)
	end
	if not itemId then
		return false
	end
	if C_Item and C_Item.IsCurrentItem then
		local ok, v = pcall(C_Item.IsCurrentItem, itemId)
		if ok then
			return v and true or false
		end
	end
	if IsCurrentItem then
		local ok, v = pcall(IsCurrentItem, itemId)
		if ok then
			return v and true or false
		end
	end
	return false
end

local function MountIsActive(mountId)
	if not mountId then
		return false
	end
	if mountId == RANDOM_MOUNT_ID then
		return IsMounted and IsMounted() and true or false
	end
	if C_MountJournal and C_MountJournal.GetMountInfoByID then
		local ok, isActive = pcall(function()
			return select(4, C_MountJournal.GetMountInfoByID(mountId))
		end)
		if ok and isActive then
			return true
		end
	end
	return false
end

local function MountSpellIsActive(spellId)
	if not spellId or not C_MountJournal then
		return false
	end
	if C_MountJournal.GetMountFromSpell then
		local ok, mountId = pcall(C_MountJournal.GetMountFromSpell, spellId)
		if ok and mountId then
			return MountIsActive(mountId)
		end
	end
	return false
end

-- One scan per FlushChecked. Retail mounts use C_MountJournal (do not walk
-- hundreds of MOUNT companions). Classic mounts have no GetMountFromSpell.
local companionCache

local function EnsureCompanionCache()
	if companionCache then
		return companionCache
	end
	local cache = {
		summonedSpell = {},
		summonedName = {},
		knownSpell = {},
		knownName = {},
	}
	companionCache = cache
	if not GetNumCompanions or not GetCompanionInfo then
		return cache
	end
	local function absorb(kind)
		local okN, n = pcall(GetNumCompanions, kind)
		if not okN or type(n) ~= "number" then
			return
		end
		for i = 1, n do
			-- creatureID, creatureName, creatureSpellID, icon, isSummoned
			local ok, _, creatureName, creatureSpellID, _, isSummoned = pcall(GetCompanionInfo, kind, i)
			if ok then
				local id = tonumber(creatureSpellID)
				if id then
					cache.knownSpell[id] = true
					if isSummoned then
						cache.summonedSpell[id] = true
					end
				end
				if type(creatureName) == "string" and creatureName ~= "" then
					cache.knownName[creatureName] = true
					if isSummoned then
						cache.summonedName[creatureName] = true
					end
				end
			end
		end
	end
	absorb("CRITTER")
	if not (C_MountJournal and C_MountJournal.GetMountFromSpell) then
		absorb("MOUNT")
	end
	return cache
end

local function CompanionSpellIsSummoned(spellId, nameRank)
	local cache = EnsureCompanionCache()
	local sid = tonumber(spellId)
	if sid and cache.summonedSpell[sid] then
		return true
	end
	if type(nameRank) == "string" and nameRank ~= "" and cache.summonedName[nameRank] then
		return true
	end
	return false
end

-- Mount/critter spells: IsCurrentSpell stays true after dismiss. Gold follows
-- journal / GetCompanionInfo isSummoned only.
local function SpellIsPersistSummon(spellId, nameRank)
	local sid = tonumber(spellId)
	if sid and C_MountJournal and C_MountJournal.GetMountFromSpell then
		local ok, mountId = pcall(C_MountJournal.GetMountFromSpell, sid)
		if ok and mountId then
			return true
		end
	end
	local cache = EnsureCompanionCache()
	if sid and cache.knownSpell[sid] then
		return true
	end
	if type(nameRank) == "string" and nameRank ~= "" and cache.knownName[nameRank] then
		return true
	end
	return false
end

local function BattlePetSpeciesIsSummoned(speciesId)
	speciesId = tonumber(speciesId)
	if not speciesId or not C_PetJournal or not C_PetJournal.GetSummonedPetGUID then
		return false
	end
	local okGuid, guid = pcall(C_PetJournal.GetSummonedPetGUID)
	if not okGuid or not guid or guid == "" then
		return false
	end
	if not C_PetJournal.GetPetInfoByPetID then
		return false
	end
	local ok, summonedSpecies = pcall(C_PetJournal.GetPetInfoByPetID, guid)
	return ok and tonumber(summonedSpecies) == speciesId
end

local function BattlePetItemSpecies(itemId)
	if not itemId or not C_PetJournal or not C_PetJournal.GetPetInfoByItemID then
		return nil
	end
	local ok, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, speciesID = pcall(C_PetJournal.GetPetInfoByItemID, itemId)
	if not ok then
		return nil
	end
	if type(a1) == "table" then
		speciesID = a1.speciesID or a1.speciesId
	end
	return tonumber(speciesID)
end

-- Pet/mount items: IsCurrentItem stays true after dismiss. Gold follows
-- summoned / mounted only.
local function ItemPersistSummon(itemId)
	if not itemId then
		return false, false
	end
	if C_MountJournal and C_MountJournal.GetMountFromItem then
		local ok, mountId = pcall(C_MountJournal.GetMountFromItem, itemId)
		if ok and mountId then
			return MountIsActive(mountId), true
		end
	end
	local species = BattlePetItemSpecies(itemId)
	if species then
		return BattlePetSpeciesIsSummoned(species), true
	end
	local ident = ItemSpellIdent(itemId)
	if ident then
		local sid = tonumber(ident)
		local hint = type(ident) == "string" and ident or nil
		if SpellIsPersistSummon(sid, hint) then
			local active = (sid and MountSpellIsActive(sid)) or CompanionSpellIsSummoned(sid, hint)
			return active and true or false, true
		end
	end
	return false, false
end

local function ItemIsActive(itemId)
	if not itemId then
		return false
	end
	local persistActive, isPersist = ItemPersistSummon(itemId)
	if isPersist then
		return persistActive
	end
	if ItemIsCurrent(itemId) then
		return true
	end
	local ident = ItemSpellIdent(itemId)
	if not ident then
		return false
	end
	local sid = tonumber(ident)
	local hint = type(ident) == "string" and ident or nil
	return SpellIsCurrent(sid or ident, hint)
end

local function SpellIsActive(spellId, nameRank)
	local sid = tonumber(spellId)
	if sid and MountSpellIsActive(sid) then
		return true
	end
	if CompanionSpellIsSummoned(sid, nameRank) then
		return true
	end
	if SpellIsPersistSummon(sid, nameRank) then
		return false
	end
	return SpellIsCurrent(spellId, nameRank)
end

local function BattlePetIsActive(petId)
	if not petId then
		return false
	end
	if C_PetJournal then
		if C_PetJournal.IsCurrentlySummoned then
			local ok, v = pcall(C_PetJournal.IsCurrentlySummoned, petId)
			if ok and v then
				return true
			end
		end
		if C_PetJournal.GetSummonedPetGUID then
			local ok, guid = pcall(C_PetJournal.GetSummonedPetGUID)
			if ok and guid and guid ~= "" then
				if petId == RANDOM_BATTLE_PET_ID or guid == petId then
					return true
				end
			end
		end
	end
	local idx = tonumber(petId)
	if idx and GetCompanionInfo then
		local ok, _, _, _, _, isSummoned = pcall(GetCompanionInfo, "CRITTER", idx)
		if ok and isSummoned then
			return true
		end
	end
	return false
end

local function FlyoutIsOpen(widget)
	if not widget then
		return false
	end
	if FluxFlyoutFrame and FluxFlyoutFrame.IsFlyoutOpenFor then
		local ok, open = pcall(FluxFlyoutFrame.IsFlyoutOpenFor, widget)
		if ok and open then
			return true
		end
	end
	if SpellFlyout and SpellFlyout.IsAttachedToButton then
		local ok, attached = pcall(SpellFlyout.IsAttachedToButton, SpellFlyout, widget)
		if ok and attached then
			if SpellFlyout.IsShown then
				local okShown, shown = pcall(SpellFlyout.IsShown, SpellFlyout)
				return okShown and shown and true or false
			end
			return true
		end
	end
	return false
end

function Paint.UpdateFlash(btn)
	local F = Flux.ButtonFX and Flux.ButtonFX.Flash
	if not (F and F.Set) then
		return
	end
	local widget = btn and btn.Widget
	if not widget then
		return
	end
	-- Strip occupancy is Bars.Paint.UpdateFlash. Do not clear that widget.
	if btn.kind == "strip" or btn._fluxStripFace then
		return
	end
	if Paint.IsParked(btn) then
		F.Set(widget, false)
		return
	end
	-- Pet attack still uses the template flash from PetActionTexture.
	if btn.ActionType == "pet" then
		return
	end
	local want = false
	local t = btn.ActionType
	local hint = btn.SpellNameRank or btn.SpellName
	if t == "spell" then
		want = F.WantSpell and F.WantSpell(ShownSpellId(btn), hint) or false
	elseif t == "item" or t == "toy" then
		want = F.WantItem and F.WantItem(btn.ItemId or btn.ToyId or btn.ActionValue) or false
	elseif IsMacroLike(btn) then
		if btn.MacroMode == "spell" then
			want = F.WantSpell and F.WantSpell(MacroShownSpell(btn) or btn.SpellId, hint) or false
		elseif btn.MacroMode == "item" then
			want = F.WantItem and F.WantItem(MacroShownItem(btn) or btn.ItemId) or false
		end
	end
	F.Set(widget, want and true or false)
end

function Paint.FlushFlash()
	local list = EBS.buttons
	if list then
		for i = 1, #list do
			Paint.UpdateFlash(list[i])
		end
	end
	local badges = EBS.badges
	if badges then
		for i = 1, #badges do
			Paint.UpdateFlash(badges[i])
		end
	end
end

function Paint.UpdateChecked(btn)
	if btn then
		Paint.UpdateFlash(btn)
	end
	if not btn or not btn.Widget or not btn.Widget.SetChecked then
		return
	end
	local widget = btn.Widget
	local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
	if btn.badgeMode and widget._fluxBadgeCombatVisHidden then
		if btn._lastChecked == false and widget._fluxCheckedApplied == false then
			return
		end
		widget._fluxPaintChecked = false
		widget._fluxCheckedFromPaint = true
		if ov and ov.ApplyChecked then
			ov.ApplyChecked(widget, false)
		else
			widget._fluxCheckedApplied = false
			widget:SetChecked(false)
		end
		widget._fluxCheckedFromPaint = nil
		btn._lastChecked = false
		return
	end
	local checked = false
	local t = btn.ActionType
	local stanceActive = btn.StanceActiveVisual and true or false
	local hint = btn.SpellNameRank or btn.SpellName
	if stanceActive then
		checked = true
	elseif t == "spell" then
		local sid = ShownSpellId(btn)
		checked = SpellIsActive(sid, hint)
	elseif t == "item" or t == "toy" then
		checked = ItemIsActive(btn.ItemId or btn.ToyId or btn.ActionValue)
	elseif IsMacroLike(btn) then
		if btn.MacroMode == "spell" then
			local sid = MacroShownSpell(btn) or btn.SpellId
			checked = SpellIsActive(sid, hint)
		elseif btn.MacroMode == "item" then
			checked = ItemIsActive(MacroShownItem(btn) or btn.ItemId)
		end
	elseif t == "mount" then
		checked = MountIsActive(btn.MountId or btn.ActionValue)
	elseif t == "battlepet" then
		checked = BattlePetIsActive(btn.BattlePetId or btn.ActionValue)
	elseif t == "pet" then
		local P = Flux.Pet
		local slot = btn.PetSlot or btn.ActionValue
		if P and P.GetActionInfo and slot then
			local _, _, _, isActive = P.GetActionInfo(slot)
			checked = isActive and true or false
			btn.PetIsActive = checked
		end
	elseif t == "shapeshift" then
		local S = Flux.Shapeshift
		local index = btn.ShapeshiftIndex or btn.ActionValue
		if S and S.GetFormInfo and index then
			local _, isActive = S.GetFormInfo(index)
			checked = isActive and true or false
		end
	elseif t == "flyout" then
		checked = FlyoutIsOpen(widget)
	elseif t == "equipmentset" then
		checked = false
	end
	local targeting = false
	if type(SpellIsTargeting) == "function" then
		local ok, v = pcall(SpellIsTargeting)
		targeting = ok and v and true or false
	end
	-- Gold checked and the AOE reticle must not stack, including stance/form extras.
	-- Do not uncheck every extra because SpellIsTargeting(); only this face.
	if ov and ov.IsLiveReticle and ov.IsLiveReticle(widget) then
		checked = false
	end
	if targeting then
		widget._fluxHadReticle = true
	elseif widget._fluxHadReticle then
		widget._fluxHadReticle = nil
	end
	-- Bar-hosted reverse face: if the strip Extra identity already golds this
	-- same spell, do not start a second checked overlay.
	if checked and btn.badgeMode then
		local strip = btn._fluxBadgeHost or widget._fluxBadgeHost
		local host = strip and strip._fluxHost
		if strip and host and (strip._fluxPaintChecked or host._checked) then
			local sid = MacroShownSpell(btn) or ShownSpellId(btn) or btn.SpellId
			local other
			local PF = Flux.Bars and Flux.Bars.ProgramFace
			if PF and PF.Shown then
				local kind, id = PF.Shown(host)
				if kind == "spell" then
					other = id
				end
			end
			if sid and other then
				local Match = Flux.Spell and Flux.Spell.IdsMatch
				if (Match and Match(sid, other)) or sid == other then
					checked = false
				end
			end
		end
	end
	if ov and ov.IsCheckedSuppressed and ov.IsCheckedSuppressed(widget) then
		checked = false
	end
	checked = checked and true or false
	if (not t or not btn.ActionValue) and not btn.badgeMode then
		checked = false
	end
	-- Same skip as the strip: btn._lastChecked is dropped by Paint.ClearCache
	-- and _fluxCheckedApplied is stamped by every Overlay.ApplyChecked caller.
	-- Visual must match too: leftover gold overlay is the stuck hilight.
	local visualOn = ov and ov.CheckedVisualOn and ov.CheckedVisualOn(widget) and true or false
	if btn._lastChecked == checked and widget._fluxCheckedApplied == checked
		and visualOn == checked
	then
		return
	end
	widget._fluxPaintChecked = checked
	widget._fluxCheckedFromPaint = true
	if ov and ov.ApplyChecked then
		ov.ApplyChecked(widget, checked)
	else
		widget._fluxCheckedApplied = checked
		widget:SetChecked(checked)
	end
	widget._fluxCheckedFromPaint = nil
	btn._lastChecked = checked
end

-- Icon morphs (override / conditional / #show) ride the shared eval lane.
-- No settle driver and no per-tick cache wipe: the scheduler no longer drops
-- eval behind a layout, and the live-face cache is invalidated by the events
-- that can actually change a face (form burst, SPELLS_CHANGED, SPELL_UPDATE_ICON).
function Paint.FlushIcons()
	local list = EBS.buttons
	if not list then
		return
	end
	local Perf = Flux.Perf
	if Perf then
		Perf.Begin("ebs.paint.icons")
	end
	for i = 1, #list do
		local btn = list[i]
		if btn and btn.ActionType and not Paint.IsParked(btn) then
			Paint.UpdateIcon(btn)
			local t = btn.ActionType
			if t == "spell" or t == "flyout" or t == "macro" or t == "macrotext" then
				Paint.UpdateGlow(btn)
			end
		end
	end
	if Perf then
		Perf.Stop("ebs.paint.icons")
	end
end

function Paint.RequestIcon()
	local FS = Flux.FormStorm
	if FS and FS.IsSettling and FS.IsSettling() then
		return
	end
	if Flux.Scheduler and Flux.Scheduler.Request then
		Flux.Scheduler.Request("eval", "ebs.icon")
		return
	end
	Paint.FlushIcons()
end

-- Checked rides the eval lane. Blizzard events every face except a companion,
-- mount or battle pet that simply goes away, so only those keep a slow watch,
-- only while one of them is actually lit, and the watch walks just those
-- buttons. A shapeshift face is fully evented, so standing in cat form no
-- longer costs a repeating walk of every extra button.
local CHECKED_RECHECK = 0.3
local CHECKED_POLL = 0.5

local POLL_PRONE = {
	spell = true,
	item = true,
	toy = true,
	macro = true,
	macrotext = true,
	mount = true,
	battlepet = true,
}

local pollArmed = false
local recheckQueued = false

--- polledOnly restricts the pass to lit summon-style faces (the watch tick).
function Paint.FlushChecked(polledOnly)
	companionCache = nil
	local list = EBS.buttons
	if not list then
		return false
	end
	local Perf = Flux.Perf
	if Perf then
		Perf.Begin(polledOnly and "ebs.paint.checkedpoll" or "ebs.paint.checked")
	end
	local anyPolled = false
	local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
	for i = 1, #list do
		local btn = list[i]
		local t = btn and btn.ActionType
		if t then
			local prone = POLL_PRONE[t] and true or false
			local visualStuck = false
			if polledOnly and prone and not btn._lastChecked then
				visualStuck = ov and ov.CheckedVisualOn and ov.CheckedVisualOn(btn.Widget) and true or false
			end
			if not polledOnly or (prone and (btn._lastChecked or visualStuck)) then
				Paint.UpdateChecked(btn)
			end
			if prone and (btn._lastChecked or (ov and ov.CheckedVisualOn and ov.CheckedVisualOn(btn.Widget))) then
				anyPolled = true
			end
		elseif btn and not polledOnly then
			-- Fully empty extras are not in POLL_PRONE; a click still golds
			-- the CheckButton and must be painted off.
			Paint.UpdateChecked(btn)
		end
	end
	if Perf then
		Perf.Stop(polledOnly and "ebs.paint.checkedpoll" or "ebs.paint.checked")
	end
	return anyPolled
end

local function AnyPollProneLit()
	local list = EBS.buttons
	if not list then
		return false
	end
	local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
	for i = 1, #list do
		local btn = list[i]
		if btn and btn._lastChecked and POLL_PRONE[btn.ActionType] then
			return true
		end
		if btn and POLL_PRONE[btn.ActionType] and ov and ov.CheckedVisualOn
			and ov.CheckedVisualOn(btn.Widget)
		then
			return true
		end
	end
	return false
end

local function PollTick()
	pollArmed = false
	local R = Flux.Range
	if R and R.IsHopBurst and R.IsHopBurst() then
		pollArmed = true
		Flux.Timer.After(CHECKED_POLL, PollTick)
		return
	end
	if Paint.FlushChecked(true) then
		pollArmed = true
		Flux.Timer.After(CHECKED_POLL, PollTick)
	end
end

--- Arm the dismiss watch only when a summon-style face is currently gold.
function Paint.ArmCheckedPoll()
	if pollArmed or not AnyPollProneLit() then
		return
	end
	pollArmed = true
	Flux.Timer.After(CHECKED_POLL, PollTick)
end

function Paint.RequestChecked()
	local FS = Flux.FormStorm
	if FS and FS.IsSettling and FS.IsSettling() then
		return
	end
	if Flux.Scheduler and Flux.Scheduler.Request then
		Flux.Scheduler.Request("eval", "ebs.checked")
		return
	end
	Paint.FlushChecked()
	Paint.ArmCheckedPoll()
end

--- Activate events (cast landed, mount summoned) resolve a moment after the
--- event. One coalesced re-check covers that; the old 0.5s at 50ms did the
--- same job ten times over.
function Paint.RequestCheckedSettle()
	Paint.RequestChecked()
	if recheckQueued then
		return
	end
	recheckQueued = true
	Flux.Timer.After(CHECKED_RECHECK, function()
		recheckQueued = false
		Paint.RequestChecked()
		Paint.ArmCheckedPoll()
	end)
end

function Paint.UpdateGlow(btn)
	if not btn or not btn.Widget then
		return
	end
	local G = Flux.ButtonFX and Flux.ButtonFX.Glow
	if not G or not G.Want then
		return
	end
	local widget = btn.Widget
	-- Bar-hosted badges: Bars.Effects.SyncColumn is the exclusive glow owner.
	-- Extra window / minimap (RANK_EBS, no _fluxBadgeHost) still paint here.
	if btn.badgeMode and (btn._fluxBadgeHost or widget._fluxBadgeHost) then
		if widget._fluxBadgeCombatVisHidden then
			local live = G.IsLive and G.IsLive(widget)
			if live or btn._glowing then
				if G.Set then
					G.Set(widget, false)
				end
			end
			btn._glowing = false
			if G.NoteHidden then
				G.NoteHidden(widget)
			else
				widget._fluxGlowSpell = nil
			end
		end
		return
	end
	local spellId
	local t = btn.ActionType
	if t == "spell" then
		spellId = ShownSpellId(btn)
	elseif t == "item" or t == "toy" then
		local ident = ItemSpellIdent(btn.ItemId or btn.ToyId or btn.ActionValue)
		if type(ident) == "number" then
			spellId = ident
		end
	elseif IsMacroLike(btn) then
		spellId = MacroShownSpell(btn)
	elseif t == "pet" or t == "shapeshift" then
		spellId = btn.SpellId
	end
	local shownTex = btn.Texture
	local icon = btn.WIcon or (widget and (widget.icon or widget.Icon))
	if icon and icon.GetTexture then
		local ok, tex = pcall(icon.GetTexture, icon)
		if ok and tex then
			shownTex = tex
		end
	end
	local want = G.Want(spellId) and true or false
	if want and shownTex and G.FaceShowsSpell and not G.FaceShowsSpell(shownTex, spellId) then
		want = false
	end
	-- Nil spell id: keep only while the icon is still the last overlayed spell.
	-- Item / empty macro faces must drop the glow even if the proc is still up.
	if not want and not spellId then
		local last = widget._fluxGlowSpell
		local mode = btn.MacroMode
		if mode == "item" or mode == "" then
			-- leave
		elseif last and G.Want(last) and shownTex and G.FaceShowsSpell and G.FaceShowsSpell(shownTex, last) then
			want = true
			spellId = last
		end
	end
	local live = G.IsLive and G.IsLive(widget)
	if want then
		if live then
			btn._glowing = true
			if G.NoteShown then
				G.NoteShown(widget, spellId)
			else
				widget._fluxGlowSpell = spellId
			end
			return
		end
		local skipBirth = (btn.IsAssistedCombat and btn._glowing and true or false)
			or (G.ShouldSkipBirth and G.ShouldSkipBirth(widget, spellId))
		btn._glowing = true
		if G.Set then
			G.Set(widget, true, skipBirth)
		end
		if G.NoteShown then
			G.NoteShown(widget, spellId)
		else
			widget._fluxGlowSpell = spellId
		end
		return
	end
	if live or btn._glowing then
		if G.Set then
			G.Set(widget, false)
		end
	end
	btn._glowing = false
	if G.NoteHidden then
		G.NoteHidden(widget)
	else
		widget._fluxGlowSpell = nil
	end
end

local EQUIP_R, EQUIP_G, EQUIP_B, EQUIP_A = 0, 1.0, 0, 0.5

local function ItemIsEquipped(itemId)
	if not itemId then
		return false
	end
	if C_Item and C_Item.IsEquippedItem then
		local ok, v = pcall(C_Item.IsEquippedItem, itemId)
		if ok then
			return v and true or false
		end
	end
	if IsEquippedItem then
		local ok, v = pcall(IsEquippedItem, itemId)
		if ok then
			return v and true or false
		end
	end
	return false
end

function Paint.UpdateEquipped(btn)
	local border = btn and btn.WBorder
	if not border then
		return
	end
	if btn.badgeMode or not btn.ActionType or btn.ActionValue == nil then
		if btn._lastEquipped ~= false then
			btn._lastEquipped = false
			border:Hide()
		end
		return
	end
	local itemId
	if btn.ActionType == "item" then
		itemId = btn.ItemId or btn.ActionValue
	elseif IsMacroLike(btn) then
		itemId = MacroShownItem(btn)
	end
	local show = itemId and ItemIsEquipped(itemId) and true or false
	if btn._lastEquipped == show then
		return
	end
	btn._lastEquipped = show
	if show then
		border:SetVertexColor(EQUIP_R, EQUIP_G, EQUIP_B, EQUIP_A)
		if border.SetBlendMode then
			pcall(border.SetBlendMode, border, "ADD")
		end
		border:Show()
	else
		border:Hide()
	end
end

local function UnitExistsSafe(unit)
	unit = unit or "target"
	if not UnitExists then
		return false
	end
	local ok, exists = pcall(UnitExists, unit)
	return ok and exists and true or false
end

-- true / false / nil. Second return true = keep last OOR (combat item range).
local function ProbeRange(btn)
	if not btn then
		return nil
	end
	local t = btn.ActionType
	if t ~= "spell" and t ~= "item" and t ~= "macro" and t ~= "macrotext" and t ~= "toy" then
		return nil
	end
	local macroUnit
	if IsMacroLike(btn) then
		if btn.MacroMode ~= "spell" and btn.MacroMode ~= "item" then
			return nil
		end
		macroUnit = btn.MacroTarget
	end
	-- Macros click with their own @unit; do not inherit leftover hub `unit`.
	-- Plain spells use the mouseover-cast widget attribute (toggle-gated).
	local R = Flux.Range
	local widget = IsMacroLike(btn) and nil or btn.Widget
	local unit = R and R.ResolveUnit and R.ResolveUnit(widget, macroUnit) or (macroUnit or "target")
	if not UnitExistsSafe(unit) then
		return nil
	end
	local function spellRange(ident)
		if not ident or not R or not R.CheckSpell then
			return nil
		end
		return R.CheckSpell(ident, unit)
	end
	local function itemRange(itemId)
		if not itemId or not R or not R.CheckItem then
			return nil
		end
		return R.CheckItem(itemId, unit)
	end
	if t == "spell" then
		return spellRange(PaintSpell(ShownSpellId(btn)))
	elseif t == "item" then
		local spell = ItemSpellIdent(btn.ItemId)
		if spell then
			local r = spellRange(spell)
			if r ~= nil then
				return r
			end
		end
		return itemRange(btn.ItemId)
	elseif t == "toy" then
		local toyId = btn.ToyId or btn.ItemId or btn.ActionValue
		local spell = ItemSpellIdent(toyId)
		if spell then
			local r = spellRange(spell)
			if r ~= nil then
				return r
			end
		end
		return itemRange(toyId)
	elseif IsMacroLike(btn) then
		local spell = MacroShownSpell(btn)
		if spell then
			return spellRange(spell)
		end
		local iid = MacroShownItem(btn)
		if iid then
			return itemRange(iid)
		end
	end
	return nil
end

function Paint.UpdateRange(btn)
	if not btn then
		return
	end
	if btn.IgnoreUsabilityVisual then
		btn._outOfRange = false
		return
	end
	local inRange, keepLast = ProbeRange(btn)
	if keepLast then
		return
	end
	local oor = (inRange == false)
	if btn._outOfRange ~= oor then
		btn._outOfRange = oor
		Paint.UpdateUsable(btn)
	end
end

function Paint.Update(btn)
	if not btn then
		return
	end
	if btn.IsAssistedCombat then
		ShownSpellId(btn)
	end
	Paint.UpdateEmpty(btn)
	Paint.UpdateIcon(btn)
	Paint.UpdateCount(btn)
	Paint.UpdateCooldown(btn)
	Paint.UpdateEquipped(btn)
	Paint.UpdateRange(btn)
	Paint.UpdateUsable(btn)
	Paint.UpdateChecked(btn)
	Paint.UpdateGlow(btn)
end

--- CD / range / usable / glow / checked without touching icon or count.
--- NC flyout hosts pin the face then call this instead of FluxButtonUsability.
function Paint.UpdateLiveFace(btn)
	if not btn then
		return
	end
	Paint.UpdateCooldown(btn)
	Paint.UpdateRange(btn)
	Paint.UpdateUsable(btn)
	Paint.UpdateGlow(btn)
	Paint.UpdateChecked(btn)
end

function Paint.FlushEval(tokens)
	-- Form/vehicle already painted form-sensitive extras on the burst.
	-- A full buttons+badges walk here is the hitch in /fluxhop (FlushEval).
	local FS = Flux.FormStorm
	if FS and FS.IsSettling and FS.IsSettling() then
		return
	end
	local full = tokens and tokens.ebs
	local range = full or (tokens and tokens["ebs.range"])
	local usable = full or (tokens and (tokens["ebs.usable"] or tokens["ebs.form"]))
	local cooldown = full or (tokens and tokens["ebs.cooldown"])
	local checked = full or (tokens and (tokens["ebs.checked"] or tokens["ebs.form"]))
	local icon = full or (tokens and tokens["ebs.icon"])
	local count = full or (tokens and tokens["ebs.count"])
	local equipped = full or (tokens and tokens["ebs.equipped"])
	local glow = full or (tokens and tokens["ebs.glow"])
	if not (full or range or usable or cooldown or checked or icon or count or equipped or glow) then
		return
	end
	if full or checked then
		-- One companion lookup per pass, not per button.
		companionCache = nil
	end
	local function PaintOne(btn, allowGlow)
		if not btn or Paint.IsParked(btn) then
			if btn then
				Paint.UpdateFlash(btn)
			end
			return
		end
		if not btn.ActionType then
			Paint.UpdateFlash(btn)
			if btn.PlaceholderTexture then
				if full then
					Paint.Update(btn)
				else
					if icon then
						Paint.UpdateIcon(btn)
					end
					if usable then
						Paint.UpdateUsable(btn)
					end
				end
			end
			return
		end
		if full then
			Paint.Update(btn)
			return
		end
		if icon then
			Paint.UpdateIcon(btn)
		end
		if count then
			Paint.UpdateCount(btn)
		end
		if cooldown then
			pcall(Paint.UpdateCooldown, btn)
		end
		if equipped then
			Paint.UpdateEquipped(btn)
		end
		if range then
			Paint.UpdateRange(btn)
		end
		if usable then
			Paint.UpdateUsable(btn)
		end
		if checked then
			Paint.UpdateChecked(btn)
		end
		if allowGlow and (glow or icon) then
			Paint.UpdateGlow(btn)
		end
	end
	local list = EBS.buttons
	for i = 1, #list do
		PaintOne(list[i], true)
	end
	-- Corner badges are not Extra-window buttons. CD/usable/icon still paint
	-- here; Bars.Effects.SyncColumn owns glow.
	local badges = EBS.badges
	if badges then
		for i = 1, #badges do
			PaintOne(badges[i], false)
		end
	end
	if full or checked then
		Paint.ArmCheckedPoll()
	end
end

--- The bag item a button's count digit reads. nil when it reads a spell's
--- reagent (an item we cannot name), which must refresh on every pulse.
local function CountItemId(btn)
	local id = btn._liveCountItemId or btn.ItemId
	if not id then
		if btn.ActionType == "item" then
			id = btn.ActionValue
		elseif IsMacroLike(btn) then
			id = MacroShownItem(btn)
		end
	end
	return tonumber(id)
end

function Paint.FlushCounts(ctx)
	local regions = ctx and ctx.regions
	local doBags = not regions or regions.bags
	local doEquip = not regions or regions.equipped
	if not doBags and not doEquip then
		return false
	end
	-- Items whose totals moved on this pulse (nil = unknown, refresh all).
	local changedIDs = doBags and ctx and ctx.changedItemIDs
	local any = false
	local function CountOne(btn)
		if not btn or not btn.ActionType then
			return
		end
		local spellFace = btn.ActionType == "spell"
		if not (spellFace or btn.ActionType == "item" or btn.ActionType == "toy" or IsMacroLike(btn)) then
			return
		end
		if doBags then
			-- A spell reagent is not in changedItemIDs. Refresh every bag pulse.
			local id = (not spellFace) and changedIDs and CountItemId(btn)
			if not (id and not changedIDs[id]) then
				local changed = Paint.UpdateCount(btn)
				-- 0-count gems must re-tint even when the digit did not change.
				if changed or ConsumableKindButton(btn) then
					Paint.UpdateUsable(btn)
					any = true
				end
			end
		end
		if doEquip then
			Paint.UpdateEquipped(btn)
			any = true
		end
	end
	local list = EBS.buttons
	for i = 1, #list do
		CountOne(list[i])
	end
	local badges = EBS.badges
	if badges then
		for i = 1, #badges do
			CountOne(badges[i])
		end
	end
	return any
end

function FluxButton:UpdateEmptyBackground()
	Paint.UpdateEmpty(self)
end

function FluxButton:UpdateUsable()
	Paint.UpdateUsable(self)
end

function FluxButton:UpdateCooldown()
	Paint.UpdateCooldown(self)
end

function FluxButton:UpdateEquipped()
	Paint.UpdateEquipped(self)
end
