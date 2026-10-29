-- Bars/Paint.lua — ForceButtonRefresh-style paint via Flux.Action / Flux.Secrets.
-- Never RegisterActionUIButton. Restricted Midnight values pass through
-- without Lua compares.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Paint = {}
Bars.Paint = Paint

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

local function Secrets()
	return Flux.Secrets
end

local function ActionAPI()
	return Flux.Action
end

local function IsSecret(value)
	local S = Secrets()
	return S and S.IsSecretValue and S.IsSecretValue(value) or false
end

local function SafeNum(value, default)
	local S = Secrets()
	if S and S.SafeGetNumber then
		return S.SafeGetNumber(value, default or 0)
	end
	return tonumber(value) or default or 0
end

local function SafeBool(value, default)
	local S = Secrets()
	if S and S.SafeBooleanTest then
		return S.SafeBooleanTest(value, default)
	end
	if value == nil then
		return default
	end
	return value and true or false
end

local function HasSlot(slot)
	local A = ActionAPI()
	if A and A.HasAction then
		return A.HasAction(slot)
	end
	return slot and HasAction and HasAction(slot) and true or false
end

-- Indexed slot is the page/form occupant. The action attribute can lag
-- CHILDUPDATE; using it then paints the previous page (ghost noform icons).
local function LiveSlot(host)
	if Bars.Hosts and Bars.Hosts.LiveSlot then
		return Bars.Hosts.LiveSlot(host)
	end
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

-- Slot-program overlay: paint the currently shown spell/item, not only the
-- underlying action-slot texture.
local function ProgramBody(slot)
	local PF = Bars.ProgramFace
	if PF and PF.BodyForSlot then
		return PF.BodyForSlot(slot)
	end
	local SP = Bars.SlotProgram
	if not (slot and SP and SP.Get) then
		return nil
	end
	local text = SP.Get(slot)
	if type(text) == "string" and text ~= "" then
		return text
	end
	return nil
end

local function CoerceShown(kind, id)
	if kind == "item" then
		id = tonumber(id)
		if id then
			return "item", id
		end
		return nil
	end
	if kind == "spell" then
		local n = tonumber(id)
		if n then
			return "spell", n
		end
		if type(id) == "string" and id ~= "" and id ~= "?" then
			return "spell", id
		end
	end
	return nil
end

local function FaceBoundToSlot(host, slot)
	return host and slot and host._fluxFaceSlot == slot
end

local function ProgramShown(host, slot)
	local Identity = Flux.Identity
	if slot and Identity and Identity.Get and Identity.SlotKey then
		local kind, id = CoerceShown(Identity.Get(Identity.SlotKey(slot)))
		if kind then
			return kind, id
		end
	end
	local face = FaceBoundToSlot(host, slot) and host._fluxFace
	if face then
		if face.MacroMode == "spell" and face.SpellId then
			return "spell", face.SpellId
		elseif face.MacroMode == "item" and face.ItemId then
			return "item", face.ItemId
		end
	end
	-- Combat ApplyLiveType cannot rewrite type/macrotext. Leftover type=macro
	-- on a bonus slot would keep painting the noform overlay; only the live
	-- slot's program body is the overlay face.
	local widget = host and host.widget
	if widget and widget.GetAttribute and widget:GetAttribute("type") == "macro" then
		local body = ProgramBody(slot)
		if type(body) == "string" and body ~= "" then
			local Shown = Flux.EBS and Flux.EBS.Action and Flux.EBS.Action.ShownFromBody
			if Shown then
				local kind, id = CoerceShown(Shown(body))
				if kind then
					return kind, id
				end
			end
		end
	end
	local PF = Bars.ProgramFace
	if PF and PF.Shown then
		local kind, id = CoerceShown(PF.Shown(host))
		if kind then
			return kind, id
		end
	end
	local body = ProgramBody(slot)
	if not body then
		return nil
	end
	local Shown = Flux.EBS and Flux.EBS.Action and Flux.EBS.Action.ShownFromBody
	if not Shown then
		return nil
	end
	return CoerceShown(Shown(body))
end

--- Spell currently painted on this host (overlay / Identity / slot).
function Paint.ShownSpellId(host)
	if not host then
		return nil
	end
	local nextId = tonumber(host.AssistedNextSpellId)
	if nextId and nextId > 0 then
		return nextId
	end
	local slot = LiveSlot(host)
	local kind, shown = ProgramShown(host, slot)
	if kind == "spell" then
		return tonumber(shown)
	end
	if slot and GetActionInfo then
		local actionType, id, subType = GetActionInfo(slot)
		if actionType == "spell" then
			return tonumber(id)
		end
		if actionType == "macro" then
			if subType == "spell" and type(id) == "number" then
				return id
			end
			if GetMacroSpell then
				local a, b, c = GetMacroSpell(id)
				if type(c) == "number" and c > 0 then
					return c
				end
				if type(a) == "number" and a > 0 then
					return a
				end
				if type(b) == "number" and b > 0 then
					return b
				end
			end
		end
	end
	return nil
end

local function ApplyRankDesat(host, spellId)
	local SRM = _G.FluxSpellRankManager
	if SRM and SRM.ApplyRankDesaturation then
		SRM:ApplyRankDesaturation(host, spellId)
		return
	end
	if host.WIcon and host.WIcon.SetDesaturated then
		host.WIcon:SetDesaturated(host._fluxRankDesaturated and true or false)
	end
end

local function SlotIsAssisted(slot)
	local A = ActionAPI()
	return slot and A and A.IsAssistedCombat and A.IsAssistedCombat(slot) and true or false
end

-- Morph the face from GetNextCastSpell(false). Do not ForceUpdateAction:
-- that notifies leftover stock ActionButtons from tainted OnUpdate.
local function SyncAssistedNext(host)
	if not host then
		return nil
	end
	local widget = host.widget
	local slot = LiveSlot(host)
	if not SlotIsAssisted(slot) then
		if host.AssistedNextSpellId ~= nil then
			host._icon = nil
			host._count = nil
			host._name = nil
			host._r, host._g, host._b = nil, nil, nil
		end
		host.AssistedNextSpellId = nil
		if widget then
			widget._fluxAssistedCombat = nil
			widget.AssistedNextSpellId = nil
		end
		return nil
	end
	if widget then
		widget._fluxAssistedCombat = true
	end
	local A = ActionAPI()
	local nextId = A and A.GetAssistedNextSpell and A.GetAssistedNextSpell()
	if nextId ~= host.AssistedNextSpellId then
		host._icon = nil
		host._count = nil
		host._name = nil
		host._r, host._g, host._b = nil, nil, nil
		if widget and Flux.ButtonFX and Flux.ButtonFX.Charges and Flux.ButtonFX.Charges.ClearCache then
			Flux.ButtonFX.Charges.ClearCache(widget)
		end
	end
	host.AssistedNextSpellId = nextId
	if widget then
		widget.AssistedNextSpellId = nextId
	end
	return nextId
end

local function AssistedSpellIcon(spellId)
	if not spellId then
		return nil
	end
	if Flux.Spell and Flux.Spell.GetTexture then
		return Flux.Spell.GetTexture(spellId)
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
	if Flux.Spell and Flux.Spell.GetIcon then
		return Flux.Spell.GetIcon(spellId)
	end
	return nil
end

local function ShownSpellIcon(spell)
	local tex
	if type(spell) == "number" then
		tex = AssistedSpellIcon(spell)
	elseif type(spell) == "string" and Flux.Spell and Flux.Spell.GetTexture then
		tex = Flux.Spell.GetTexture(spell)
	end
	if IsQuestionTex(tex) then
		return nil
	end
	return tex
end

local function MacroSpellId(index)
	if not index or not GetMacroSpell then
		return nil
	end
	local a, b, c = GetMacroSpell(index)
	if type(c) == "number" and c > 0 then
		return c
	end
	if type(a) == "number" and a > 0 then
		return a
	end
	if type(b) == "number" and b > 0 then
		return b
	end
	return nil
end

-- Fallback only. Form/stealth attack-icon swaps keep the same GetActionInfo
-- spell id; Spell.GetTexture(base) stays on the original face. Blizzard paints
-- C_ActionBar.GetActionTexture on UPDATE_SHAPESHIFT_FORM.
local function SlotSpellTexture(slot)
	if not slot or not GetActionInfo then
		return nil
	end
	local S = Flux.Spell
	if not (S and S.GetTexture) then
		return nil
	end
	local actionType, id, subType = GetActionInfo(slot)
	if actionType == "spell" then
		return S.GetTexture(id)
	end
	if actionType == "macro" then
		local sid = MacroSpellId(id)
		if not sid and subType == "spell" then
			sid = id
		end
		if sid then
			return S.GetTexture(sid)
		end
	end
	return nil
end

-- TextOverlayContainer.Count ignores SetText while hidden. Never Hide it:
-- a blank string draws nothing, and the first digit has to land on a shown
-- region or the cache treats that blank paint as done.
local function CountRegionHidden(fs)
	return not (fs.IsShown and fs:IsShown())
end

local function CountRegionBlank(fs)
	if not fs.GetText then
		return false
	end
	local current = fs:GetText()
	if IsSecret(current) then
		return false
	end
	return current == nil or current == ""
end

local function ApplyCountText(host, fs, value)
	-- Midnight: SetText accepts secrets. Skipping them blanks the digit.
	-- Do not cache or ==-compare a secret (Ellesmere lastCountText = nil).
	if value == nil then
		value = ""
	end
	local S = Secrets()
	local secret = false
	if S and S.IsSecretValue then
		local ok, v = pcall(S.IsSecretValue, value)
		secret = ok and v and true or false
	end
	if secret then
		fs:Show()
		fs:SetText(value)
		-- Keep last readable digit. Wiping _count here lost the 0 that
		-- UpdateUsable needs when Midnight hides the new count in combat.
		return
	end
	local text
	if value == "" then
		text = ""
	else
		text = tostring(value)
	end
	local cached = host._count == text
	if not cached then
		host._count = text
		if text == "0" then
			host._fxCountZero = true
		elseif text == "" then
			host._fxCountZero = false
		else
			local n = tonumber(text)
			if n and n > 0 then
				host._fxCountZero = false
			end
		end
	elseif text == "" then
		if not CountRegionHidden(fs) and CountRegionBlank(fs) then
			return
		end
	elseif not CountRegionHidden(fs) and not CountRegionBlank(fs) then
		return
	end
	fs:Show()
	fs:SetText(text)
end

-- ---------------------------------------------------------------------------
-- Macro name (main row only)
-- ---------------------------------------------------------------------------

-- GetActionText is the slot label (macros). GetMacroInfo is the fallback when
-- the action API has the index but not the string yet. nil = secret, skip write.
local function MacroNameForSlot(slot)
	if not slot then
		return ""
	end
	local A = ActionAPI()
	local actionType, id
	if A and A.GetInfo then
		actionType, id = A.GetInfo(slot)
	elseif GetActionInfo then
		actionType, id = GetActionInfo(slot)
	end
	if actionType ~= "macro" then
		return ""
	end
	local name
	if A and A.GetText then
		name = A.GetText(slot)
	elseif GetActionText then
		name = GetActionText(slot)
	end
	if (name == nil or (not IsSecret(name) and name == "")) and id and GetMacroInfo then
		name = GetMacroInfo(id)
	end
	if name == nil then
		return ""
	end
	if IsSecret(name) then
		return name
	end
	if name == "" then
		return ""
	end
	local S = Secrets()
	if S and S.SafeCountKey then
		return S.SafeCountKey(name)
	end
	if type(name) ~= "string" then
		return tostring(name)
	end
	return name
end

function Paint.UpdateName(host)
	local fs = host.WName
	if not fs then
		return
	end
	if host.row ~= "main" then
		if host._name ~= "" then
			host._name = ""
			fs:SetText("")
			fs:Hide()
		end
		return
	end
	local text = ""
	if host._count == nil or host._count == "" then
		text = MacroNameForSlot(LiveSlot(host))
		if text == nil then
			return
		end
	end
	if host._name == text then
		if text ~= "" then
			fs:Show()
		end
		return
	end
	host._name = text
	if text == "" then
		fs:SetText("")
		fs:Hide()
	else
		fs:SetText(text)
		fs:Show()
	end
end

-- ---------------------------------------------------------------------------
-- Icon
-- ---------------------------------------------------------------------------

function Paint.UpdateIcon(host)
	local icon = host.WIcon
	if not icon then
		return
	end
	local slot = LiveSlot(host)
	local filled = HasSlot(slot)
	local A = ActionAPI()
	local occ = ""
	if slot and A and A.OccupancyKey then
		occ = A.OccupancyKey(slot) or ""
	end
	local occChanged = host._fluxOccKey ~= occ
	if occChanged then
		host._fluxOccKey = occ
		host._icon = nil
	end
	local face = host._fluxFace
	if filled and FaceBoundToSlot(host, slot) and face and face.MacroBody
		and Flux.EBS and Flux.EBS.Action and Flux.EBS.Action.TranslateMacro
	then
		pcall(Flux.EBS.Action.TranslateMacro, face)
	end
	local nextId = SyncAssistedNext(host)
	local tex
	if nextId then
		tex = AssistedSpellIcon(nextId)
		if IsQuestionTex(tex) then
			tex = nil
		end
	end
	-- Empty bonus/override slots must not keep a noform overlay identity.
	if not tex and slot and filled then
		local kind, shown = ProgramShown(host, slot)
		if kind == "spell" then
			tex = ShownSpellIcon(shown)
		elseif kind == "item" and Flux.Item and Flux.Item.GetIcon then
			tex = Flux.Item.GetIcon(shown)
		end
		if IsQuestionTex(tex) then
			tex = nil
		end
		if not tex then
			local bound = FaceBoundToSlot(host, slot) and host._fluxFace
			if bound and bound.MacroTexture and not IsQuestionTex(bound.MacroTexture) then
				tex = bound.MacroTexture
			end
		end
	end
	if not tex and slot then
		if A and A.GetTexture then
			tex = A.GetTexture(slot)
		elseif GetActionTexture then
			tex = GetActionTexture(slot)
		end
		if IsQuestionTex(tex) or not tex then
			local fallback = SlotSpellTexture(slot)
			if fallback and not IsQuestionTex(fallback) then
				tex = fallback
			elseif IsQuestionTex(tex) then
				tex = nil
			end
		end
	end
	if IsSecret(tex) then
		host._icon = nil
		pcall(icon.SetTexture, icon, tex)
		icon:SetShown(filled)
		ApplyRankDesat(host, Paint.ShownSpellId(host))
		return
	end
	if tex then
		if host._icon ~= tex or host._iconShown ~= filled then
			host._icon = tex
			host._iconShown = filled
			icon:SetTexture(tex)
			icon:SetTexCoord(0, 1, 0, 1)
		end
		icon:SetShown(filled)
		ApplyRankDesat(host, Paint.ShownSpellId(host))
		return
	end
	-- Same occupant, texture API lag: keeps the last good face. A new occupant
	-- (form/bonus page) must not keep the previous page's pixels.
	if filled and not occChanged and host._icon and not IsQuestionTex(host._icon) then
		icon:SetTexture(host._icon)
		icon:SetTexCoord(0, 1, 0, 1)
		icon:Show()
		host._iconShown = true
		ApplyRankDesat(host, Paint.ShownSpellId(host))
		return
	end
	if host._icon == nil and host._iconShown == false then
		return
	end
	host._icon = nil
	host._iconShown = false
	host._fluxRankDesaturated = false
	icon:SetTexture(nil)
	icon:Hide()
end

-- No icon settle driver. Mixin Update() is detached, but the scheduler now
-- defers eval past a layout instead of dropping it, so "bars.icon" always
-- lands. UpdateIcon re-reads GetActionTexture every pass and only writes when
-- the texture actually changed, so a repaint of an unchanged bar is nearly free.

-- ---------------------------------------------------------------------------
-- Count
-- ---------------------------------------------------------------------------

-- Overlay identity owns the count. Falling through to GetActionDisplayCount
-- keeps the other face's item/spell digits after a reverse badge swap.
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

local function OverlaySpellCount(shown)
	if not shown then
		return ""
	end
	if Flux.Spell and Flux.Spell.GetDisplayCount then
		local display = Flux.Spell.GetDisplayCount(shown)
		if display ~= nil then
			return display
		end
	end
	if Flux.Spell and Flux.Spell.GetCount then
		local n = Flux.Spell.GetCount(shown)
		if IsSecret(n) then
			return n
		end
		n = SafeNum(n, 0)
		-- Consumable spells keep the 0 digit; reagents with none stay blank.
		if n > 0 or IsConsumableSpellId(shown) then
			return tostring(n)
		end
	end
	if Flux.Spell and Flux.Spell.GetCharges then
		local charges, maxCharges = Flux.Spell.GetCharges(shown)
		if IsSecret(charges) then
			return charges
		end
		local cur = SafeNum(charges, 0)
		local max = SafeNum(maxCharges, 0)
		if max > 1 then
			return tostring(cur)
		end
	end
	return ""
end

local function OverlayItemCount(shown)
	if not shown or not (Flux.Item and Flux.Item.GetCount) then
		return ""
	end
	local charges = Flux.Item.GetCount(shown, false, true)
	if IsSecret(charges) then
		return charges
	end
	local stacks = Flux.Item.GetCount(shown, false, false)
	if IsSecret(stacks) then
		return stacks
	end
	charges = SafeNum(charges, 0)
	stacks = SafeNum(stacks, 0)
	local n = charges
	if stacks > n then
		n = stacks
	end
	-- Mana gem / emerald / potion: always show the digit, including 0.
	if Flux.Item.IsConsumable and Flux.Item.IsConsumable(shown) then
		return tostring(n)
	end
	if n > 1 then
		return tostring(n)
	end
	return ""
end

local function CountLooksEmpty(display)
	local S = Secrets()
	if S and S.SafeLooksEmpty then
		return S.SafeLooksEmpty(display)
	end
	if display == nil then
		return true
	end
	if IsSecret(display) then
		return false
	end
	return display == ""
end

local function DisplayedZero(host)
	if not host then
		return false
	end
	if host._fxCountZero then
		return true
	end
	return host._count == "0"
end

-- 0-count consumable / charged action: darken even when IsUsable stays true.
-- Unique gems can still sit in the stack snapshot at 1 with 0 charges left.
local function OverlayItemEmptyUnusable(host, itemId)
	if not itemId or not Flux.Item or not Flux.Item.GetCount then
		return DisplayedZero(host)
	end
	if Flux.Item.IsEquipped and Flux.Item.IsEquipped(itemId) then
		if host then
			host._fxItemEmpty = false
		end
		return false
	end
	if not (Flux.Item.IsConsumable and Flux.Item.IsConsumable(itemId)) then
		return DisplayedZero(host)
	end
	local n = Flux.Item.GetCount(itemId, false, true)
	if IsSecret(n) then
		if host and host._fxItemEmpty ~= nil then
			return host._fxItemEmpty
		end
		return DisplayedZero(host)
	end
	local empty = SafeNum(n, 0) <= 0
	if host then
		host._fxItemEmpty = empty
	end
	return empty
end

local function SlotCountUnusable(slot)
	local A = ActionAPI()
	if not slot or not A then
		return false
	end
	if A.IsConsumable and A.GetCount then
		local consumable = SafeBool(A.IsConsumable(slot), false)
		local n = A.GetCount(slot)
		if consumable and not IsSecret(n) and SafeNum(n, 0) == 0 then
			return true
		end
	end
	if A.GetCharges then
		local cur, maxC = A.GetCharges(slot)
		if not IsSecret(cur) and not IsSecret(maxC) then
			if SafeNum(maxC, 0) > 1 and SafeNum(cur, 0) == 0 then
				return true
			end
		end
	end
	return false
end

-- "empty" = charged spell at 0 (darken). "ready" = >=1 charge. "none" = not
-- a charge spell. nil = secret / unknown with no last-known value.
local function ChargeState(host, slot)
	local cur, maxC
	local kind, shown = ProgramShown(host, slot)
	if kind == "spell" and shown and Flux.Spell and Flux.Spell.GetCharges then
		cur, maxC = Flux.Spell.GetCharges(shown)
	end
	if cur == nil and slot then
		local A = ActionAPI()
		if A and A.GetCharges then
			cur, maxC = A.GetCharges(slot)
		end
	end
	if IsSecret(cur) or IsSecret(maxC) then
		cur = host and host._fxChargeCur
		maxC = host and host._fxChargeMax
		if cur == nil or maxC == nil then
			return nil
		end
	else
		maxC = SafeNum(maxC, 0)
		cur = SafeNum(cur, 0)
		if host then
			host._fxChargeCur = cur
			host._fxChargeMax = maxC
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

local function CooldownOptsActive(o)
	if not o then
		return false
	end
	if o.isActive == false or o.enable == false or o.enable == 0 then
		return false
	end
	if o.isActive then
		return true
	end
	if IsSecret(o.start) or IsSecret(o.duration) then
		return nil
	end
	return SafeNum(o.start, 0) > 0 and SafeNum(o.duration, 0) > 0
end

-- IsUsable lags a frame behind SPELL_UPDATE_CHARGES / cooldown end.
-- ChargeState "ready" must not stay gray when the swipe is already off.

function Paint.UpdateCount(host)
	local fs = host.WCount
	if not fs then
		return
	end
	local nextId = SyncAssistedNext(host)
	if nextId then
		ApplyCountText(host, fs, OverlaySpellCount(nextId))
		return
	end
	local slot = LiveSlot(host)
	if not HasSlot(slot) then
		-- Pickup / drop off the bar must not keep bag/equip stack digits.
		-- ProgramShown/Identity can still name the old item while HasAction is
		-- already false, and empty hosts are skipped by the live-lane flush.
		ApplyCountText(host, fs, "")
		return
	end
	local kind, shown = ProgramShown(host, slot)
	-- Overlay identity owns the count. Native display count is the other
	-- face after a reverse badge swap.
	if kind == "spell" then
		ApplyCountText(host, fs, OverlaySpellCount(shown))
		return
	end
	if kind == "item" then
		ApplyCountText(host, fs, OverlayItemCount(shown))
		return
	end
	local cab = C_ActionBar
	if slot and cab and cab.GetActionDisplayCount then
		local display = cab.GetActionDisplayCount(slot)
		if not CountLooksEmpty(display) then
			ApplyCountText(host, fs, display)
			return
		end
		-- Consumable 0: native display count is often blank. Keep the digit.
	end
	local A = ActionAPI()
	if slot and A and A.GetDisplayCount then
		local display = A.GetDisplayCount(slot)
		if not CountLooksEmpty(display) then
			ApplyCountText(host, fs, display)
			return
		end
	end

	local text = ""
	if slot then
		local A = ActionAPI()
		local consumable = A and A.IsConsumable and A.IsConsumable(slot)
		local stackable = A and A.IsStackable and A.IsStackable(slot)
		if consumable then
			local raw = A and A.GetCount and A.GetCount(slot)
			if IsSecret(raw) then
				text = raw
			else
				text = tostring(SafeNum(raw, 0))
			end
		elseif stackable then
			local n = SafeNum(A and A.GetCount and A.GetCount(slot), 0)
			if n > 1 then
				text = tostring(n)
			end
		elseif A and A.GetCharges then
			local charges, maxCharges = A.GetCharges(slot)
			if IsSecret(charges) then
				text = charges
			else
				local cur = SafeNum(charges, 0)
				local max = SafeNum(maxCharges, 0)
				if max > 1 then
					text = tostring(cur)
				end
			end
		end
	end
	ApplyCountText(host, fs, text)
end

-- Interrupt chrome sits above the cooldown. Do not skip swipe paint.
local function HideFillCooldown(widget)
	local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
	if not ov or not ov.ShouldHideCooldown or not ov.ShouldHideCooldown(widget) then
		return false
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Cooldown
-- ---------------------------------------------------------------------------

-- Charges.Apply reads its options synchronously and keeps no reference, so one
-- reusable table replaces a fresh table per host per paint. Wiped on hand-out
-- because Apply also reads optional keys a later caller may not set.
local cooldownOpts = {}

local function CooldownOpts(cd)
	for key in pairs(cooldownOpts) do
		cooldownOpts[key] = nil
	end
	cooldownOpts.cooldown = cd
	return cooldownOpts
end

-- isActive (NeverSecret) gates duration objects. Fetching Get*Duration on a
-- ready slot was the 1-frame GCD swipe on every button.
local function FillSpellCooldownOpts(o, spellId)
	o.spellId = spellId
	local start, duration, enable, modRate, isActive
	if Flux.Spell and Flux.Spell.GetCooldown then
		start, duration, enable, modRate, isActive = Flux.Spell.GetCooldown(spellId)
	end
	o.start = start
	o.duration = duration
	o.enable = enable
	o.modRate = modRate
	o.isActive = isActive
	if isActive then
		if Flux.Spell and Flux.Spell.GetCooldownDuration then
			o.durationObject = Flux.Spell.GetCooldownDuration(spellId)
		end
	elseif isActive == false then
		o.start, o.duration, o.enable = 0, 0, 0
		o.durationObject = nil
		o.skipDurationObject = true
	end
	local cur, maxCharges, chargeStart, chargeDuration, chargeModRate, chargeActive
	if Flux.Spell and Flux.Spell.GetCharges then
		cur, maxCharges, chargeStart, chargeDuration, chargeModRate, chargeActive = Flux.Spell.GetCharges(spellId)
	end
	o.current = cur
	o.maxCharges = maxCharges
	o.chargeStart = chargeStart
	o.chargeDuration = chargeDuration
	o.chargeModRate = chargeModRate
	o.chargeIsActive = chargeActive
	-- isActive is NeverSecret. Secret counts still need the duration object
	-- or the recharge edge blanks mid-combat.
	local chargeOn = SafeBool(chargeActive, nil)
	if chargeOn ~= false then
		if chargeOn or IsSecret(chargeStart) or IsSecret(chargeDuration)
			or IsSecret(cur) or IsSecret(maxCharges) then
			if Flux.Spell and Flux.Spell.GetChargeDuration then
				o.chargeDurationObject = Flux.Spell.GetChargeDuration(spellId)
			end
		end
	end
end

local function FillActionCooldownOpts(o, slot)
	local A = ActionAPI()
	local start, duration, enable, isActive, modRate
	if A and A.GetCooldown then
		start, duration, enable, isActive, modRate = A.GetCooldown(slot)
	elseif GetActionCooldown then
		local ok, s, d, e, m = pcall(GetActionCooldown, slot)
		if ok then
			start, duration, enable, modRate = s, d, e, m
		end
	end
	o.start = start
	o.duration = duration
	o.enable = enable
	o.modRate = modRate
	o.isActive = isActive
	if isActive then
		if A and A.GetCooldownDuration then
			o.durationObject = A.GetCooldownDuration(slot)
		elseif C_ActionBar and C_ActionBar.GetActionCooldownDuration then
			local ok, dur = pcall(C_ActionBar.GetActionCooldownDuration, slot)
			if ok then
				o.durationObject = dur
			end
		end
	elseif isActive == false then
		o.start, o.duration, o.enable = 0, 0, 0
		o.durationObject = nil
		o.skipDurationObject = true
	end
	local cur, maxCharges, chargeStart, chargeDuration, chargeModRate, chargeActive
	if A and A.GetCharges then
		cur, maxCharges, chargeStart, chargeDuration, chargeModRate, chargeActive = A.GetCharges(slot)
	end
	o.current = cur
	o.maxCharges = maxCharges
	o.chargeStart = chargeStart
	o.chargeDuration = chargeDuration
	o.chargeModRate = chargeModRate
	o.chargeIsActive = chargeActive
	if not o.spellId and A and A.GetInfo then
		local actionType, id = A.GetInfo(slot)
		if actionType == "spell" then
			o.spellId = id
		end
	elseif not o.spellId and GetActionInfo then
		local actionType, id = GetActionInfo(slot)
		if actionType == "spell" then
			o.spellId = id
		end
	end
	local chargeOn = SafeBool(chargeActive, nil)
	if chargeOn ~= false then
		if chargeOn or IsSecret(chargeStart) or IsSecret(chargeDuration)
			or IsSecret(cur) or IsSecret(maxCharges) then
			if A and A.GetChargeDuration then
				o.chargeDurationObject = A.GetChargeDuration(slot)
			elseif C_ActionBar and C_ActionBar.GetActionChargeDuration then
				local ok, dur = pcall(C_ActionBar.GetActionChargeDuration, slot)
				if ok then
					o.chargeDurationObject = dur
				end
			end
		end
	end
end

local function ApplyCooldownOpts(widget, cd, o)
	local FX = Flux.ButtonFX and Flux.ButtonFX.Charges
	if FX and FX.Apply then
		FX.Apply(widget, o)
		return
	end
	if HideFillCooldown(widget) then
		return
	end
	if o.durationObject and cd.SetCooldownFromDurationObject then
		pcall(cd.SetCooldownFromDurationObject, cd, o.durationObject)
		return
	end
	if IsSecret(o.start) or IsSecret(o.duration) then
		if cd.Clear then
			pcall(cd.Clear, cd)
		end
		return
	end
	local s = SafeNum(o.start, 0)
	local d = SafeNum(o.duration, 0)
	local e = SafeBool(o.enable, true)
	if e and d > 0 and s > 0 then
		if cd.SetDrawBling then
			pcall(cd.SetDrawBling, cd, true)
		end
		cd:SetCooldown(s, d)
		if cd.Show then
			cd:Show()
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
	end
end

local function ClearEmptyCooldown(host)
	local cd = host.WCooldown
	local widget = host.widget
	if not cd or not widget then
		return
	end
	local FX = Flux.ButtonFX and Flux.ButtonFX.Charges
	if FX and FX.Apply then
		local o = CooldownOpts(cd)
		o.start = 0
		o.duration = 0
		o.enable = 0
		o.skipDurationObject = true
		FX.Apply(widget, o)
	else
		if cd.SetDrawBling then
			pcall(cd.SetDrawBling, cd, false)
		end
		if CooldownFrame_Clear then
			pcall(CooldownFrame_Clear, cd)
		elseif cd.Clear then
			pcall(cd.Clear, cd)
		end
	end
	host._fxCdActive = false
	host._fxChargeState = nil
	host._fxChargeCur = nil
	host._fxChargeMax = nil
end

local function ClearEmptyUsable(host)
	host._fluxRankDesaturated = false
	if host.widget then
		host.widget._fluxRankDesaturated = false
	end
	host._r, host._g, host._b = 1, 1, 1
	local icon = host.WIcon
	if icon then
		icon:SetVertexColor(1, 1, 1)
		if icon.SetDesaturated then
			icon:SetDesaturated(false)
		end
	end
end

local function RefreshUsableIfChargeOrIdleChanged(host, charge, active)
	local prevCharge = host._fxChargeState
	local prevActive = host._fxCdActive
	-- Secret timers are unknown, not idle. Treating nil as false blanked the
	-- recharge edge and bumped last-known charges on every combat GCD paint.
	if active ~= nil then
		host._fxCdActive = active and true or false
	end
	-- Recharge swipe ended while Midnight hid GetCharges: bump last-known.
	if prevActive and host._fxCdActive == false then
		local maxC = host._fxChargeMax
		if (charge == "empty" or charge == nil) and maxC and maxC > 1 then
			local cur = host._fxChargeCur or 0
			if cur < maxC then
				host._fxChargeCur = cur + 1
				charge = ChargeState(host, LiveSlot(host))
			end
		end
	end
	host._fxChargeState = charge
	if prevCharge == charge and prevActive == host._fxCdActive then
		return
	end
	-- 0→1 charges, or the recharge swipe just ended: IsUsable is often still
	-- false for one event. Paint.UpdateUsable is fingerprint-skipped if tint
	-- did not change, so this is free on a normal GCD tick.
	if charge == "ready" or (prevActive and host._fxCdActive == false) or charge == "empty" then
		Paint.UpdateUsable(host)
	end
end

function Paint.UpdateCooldown(host)
	local cd = host.WCooldown
	local widget = host.widget
	local slot = LiveSlot(host)
	if not cd or not widget then
		return
	end
	if not slot then
		ClearEmptyCooldown(host)
		ClearEmptyUsable(host)
		return
	end
	local nextId = SyncAssistedNext(host)
	if not nextId and not HasSlot(slot) then
		ClearEmptyCooldown(host)
		ClearEmptyUsable(host)
		return
	end
	local o
	if nextId and Flux.Spell then
		o = CooldownOpts(cd)
		FillSpellCooldownOpts(o, nextId)
		ApplyCooldownOpts(widget, cd, o)
	else
		local kind, shown = ProgramShown(host, slot)
		if kind == "spell" and shown and Flux.Spell then
			o = CooldownOpts(cd)
			FillSpellCooldownOpts(o, shown)
			ApplyCooldownOpts(widget, cd, o)
		elseif kind == "item" and Flux.Item and Flux.Item.GetCooldown then
			local start, duration, enable = Flux.Item.GetCooldown(shown)
			o = CooldownOpts(cd)
			o.start = start
			o.duration = duration
			o.enable = enable
			o.itemCooldown = true
			o.skipDurationObject = true
			ApplyCooldownOpts(widget, cd, o)
		else
			o = CooldownOpts(cd)
			FillActionCooldownOpts(o, slot)
			ApplyCooldownOpts(widget, cd, o)
		end
	end
	RefreshUsableIfChargeOrIdleChanged(host, ChargeState(host, slot), CooldownOptsActive(o))
end

-- ---------------------------------------------------------------------------
-- Usable / range
-- ---------------------------------------------------------------------------

local function ApplyIconColor(host, r, g, b)
	if host._r ~= r or host._g ~= g or host._b ~= b then
		host._r, host._g, host._b = r, g, b
		if host.WIcon then
			host.WIcon:SetVertexColor(r, g, b)
		end
	end
	if host.WIcon and host.WIcon.SetDesaturated then
		host.WIcon:SetDesaturated(host._fluxRankDesaturated and true or false)
	end
end

function Paint.UpdateUsable(host)
	local slot = LiveSlot(host)
	local C = Bars.COLOR
	if not HasSlot(slot) then
		ClearEmptyUsable(host)
		return
	end
	local charge = ChargeState(host, slot)
	local nextId = SyncAssistedNext(host)
	ApplyRankDesat(host, Paint.ShownSpellId(host))
	if host._outOfRange then
		ApplyIconColor(host, C.outOfRange[1], C.outOfRange[2], C.outOfRange[3])
		return
	end

	-- IsUsable lags behind SPELL_UPDATE_CHARGES and cooldown end. A charged
	-- spell that just went 0→1 must not stay gray (OOR / OOM still win).
	-- 0 charges / 0 items always dim, including mid-combat when the API is
	-- secret: last-known empty and the painted 0 digit still win.
	local function paint(usable, noMana, countDark, itemEmpty)
		if noMana == true then
			ApplyIconColor(host, C.mana[1], C.mana[2], C.mana[3])
			return
		end
		if charge == "empty" or itemEmpty then
			ApplyIconColor(host, C.unusable[1], C.unusable[2], C.unusable[3])
			return
		end
		if countDark and charge ~= "ready" then
			ApplyIconColor(host, C.unusable[1], C.unusable[2], C.unusable[3])
			return
		end
		if usable == false and charge ~= "ready" then
			ApplyIconColor(host, C.unusable[1], C.unusable[2], C.unusable[3])
			return
		end
		if usable == true or charge == "ready" then
			ApplyIconColor(host, C.usable[1], C.usable[2], C.usable[3])
			return
		end
		-- Unknown/secret: keep last tint. Do not fail-open to bright.
		if host._r == nil then
			ApplyIconColor(host, C.usable[1], C.usable[2], C.usable[3])
		end
	end

	if nextId and Flux.Spell and Flux.Spell.IsUsable then
		local usable, noMana = Flux.Spell.IsUsable(nextId)
		if usable ~= nil then
			paint(usable, noMana, false, false)
			return
		end
	end
	local kind, shown = ProgramShown(host, slot)
	if kind == "spell" and shown and Flux.Spell and Flux.Spell.IsUsable then
		local usable, noMana = Flux.Spell.IsUsable(shown)
		if usable ~= nil then
			paint(usable, noMana, SlotCountUnusable(slot) or DisplayedZero(host), false)
			return
		end
		-- nil = unknown (Extra SpellUsable): do not gray; use the slot.
	elseif kind == "item" and Flux.Item and Flux.Item.IsUsable then
		local itemEmpty = OverlayItemEmptyUnusable(host, shown)
		if itemEmpty then
			ApplyIconColor(host, C.unusable[1], C.unusable[2], C.unusable[3])
			return
		end
		if Flux.Item.IsUsable(shown) == false and charge ~= "ready" then
			ApplyIconColor(host, C.unusable[1], C.unusable[2], C.unusable[3])
			return
		end
	end
	local usable, noMana
	local A = ActionAPI()
	if A and A.IsUsable then
		local ok, u, m = pcall(A.IsUsable, slot)
		if ok then
			usable = SafeBool(u, nil)
			noMana = SafeBool(m, false)
		end
	elseif IsUsableAction then
		local ok, u, m = pcall(IsUsableAction, slot)
		if ok then
			usable = SafeBool(u, nil)
			noMana = SafeBool(m, false)
		end
	end
	-- Mana gem / potion at 0: IsUsableAction can stay true. Darken from count.
	local itemEmpty = kind == "item" and OverlayItemEmptyUnusable(host, shown)
	local countDark = SlotCountUnusable(slot) or itemEmpty or DisplayedZero(host)
	paint(usable, noMana, countDark, itemEmpty)
end

local function ItemUseSpellId(itemId)
	if not itemId or not (Flux.Item and Flux.Item.GetSpell) then
		return nil
	end
	local ok, a, b = pcall(Flux.Item.GetSpell, itemId)
	if not ok then
		return nil
	end
	return tonumber(b) or tonumber(a)
end

local function HostShowsSpell(host, spellId)
	if not host or not spellId then
		return false
	end
	local shown = Paint.ShownSpellId(host)
	if shown and shown == spellId then
		return true
	end
	local slot = LiveSlot(host)
	local kind, id = ProgramShown(host, slot)
	if kind == "spell" and tonumber(id) == spellId then
		return true
	end
	if kind == "item" then
		return ItemUseSpellId(id) == spellId
	end
	return false
end

-- Combat-safe 0-charge / last-stack dim: live APIs are often secret or a
-- frame behind. Decrement last-known when this host just consumed.
function Paint.NotePlayerCast(spellId)
	spellId = tonumber(spellId)
	if not spellId or spellId <= 0 then
		return
	end
	Bars.ForEachHost(function(host)
		if not HostShowsSpell(host, spellId) then
			return
		end
		local slot = LiveSlot(host)
		local kind = ProgramShown(host, slot)
		local cur, maxC
		if Flux.Spell and Flux.Spell.GetCharges then
			cur, maxC = Flux.Spell.GetCharges(spellId)
		end
		local chargeSecret = IsSecret(cur) or IsSecret(maxC)
		local prevCount = host._count
		Paint.UpdateCount(host)
		if chargeSecret and host._fxChargeCur and host._fxChargeCur > 0 then
			host._fxChargeCur = host._fxChargeCur - 1
		end
		if kind == "item" and host._count == prevCount then
			local n = tonumber(prevCount)
			if n and n > 0 then
				ApplyCountText(host, host.WCount, tostring(n - 1))
			end
		end
		Paint.UpdateUsable(host)
	end)
end

-- Range unit for this host. A compiled overlay carries the macro's own @unit
-- (MacroTarget, filled by TranslateMacro before the _fluxStripFace return).
-- Overlay clicks follow that body, so they must not inherit the mouseover-cast
-- hub sitting on the action button underneath. Plain slots use the hub, gated
-- so leftover unit=mouseover is ignored while the toggle is off.
local function RangeUnit(host)
	local slot = LiveSlot(host)
	local face = FaceBoundToSlot(host, slot) and host._fluxFace
	local macroUnit = face and face.MacroTarget
	local overlay = face and face._fluxStripFace
	local widget = overlay and nil or (host and host.widget)
	local R = Flux.Range
	if R and R.ResolveUnit then
		return R.ResolveUnit(widget, macroUnit)
	end
	if type(macroUnit) == "string" and macroUnit ~= "" and macroUnit ~= "player" and macroUnit ~= "cursor" then
		return macroUnit
	end
	return "target"
end

function Paint.NeedsRange(host)
	if host and host._fluxParked then
		return false
	end
	local R = Flux.Range
	if R and R.IsHopBurst and R.IsHopBurst() then
		return false
	end
	local slot = LiveSlot(host)
	if not HasSlot(slot) then
		return false
	end
	if not UnitExists then
		return false
	end
	local ok, exists = pcall(UnitExists, RangeUnit(host))
	return ok and exists and true or false
end

--- Overlay first: a flux-p-<slot> macrotext paints its icon from the parsed
--- spell, so it has to range that spell too, not the slot underneath it.
local function ProbeRange(host, slot)
	local R = Flux.Range
	if not R then
		return nil
	end
	local unit = RangeUnit(host)
	local face = FaceBoundToSlot(host, slot) and host._fluxFace
	if face then
		if face.MacroMode == "spell" and face.SpellId then
			return R.CheckSpell(face.SpellId, unit)
		end
		if face.MacroMode == "item" and face.ItemId then
			return R.CheckItem(face.ItemId, unit)
		end
	end
	-- Plain spell/item: probe the shown identity against the mouseover-cast
	-- unit. IsActionInRange(slot, unit) is missing or target-only on some
	-- Classic clients, which is how a default bar spell never red-tinted.
	local actionType, id = host._fluxAType, host._fluxAId
	if not actionType and GetActionInfo then
		local ok, at, aid = pcall(GetActionInfo, slot)
		if ok then
			actionType, id = at, aid
			host._fluxAType, host._fluxAId = at, aid
		end
	end
	if id then
		if actionType == "spell" then
			return R.CheckSpell(id, unit)
		end
		if actionType == "item" then
			return R.CheckItem(id, unit)
		end
	end
	return R.CheckAction(slot, unit)
end

function Paint.UpdateRange(host)
	local oor = false
	if Paint.NeedsRange(host) then
		local inRange, keepLast = ProbeRange(host, LiveSlot(host))
		if keepLast then
			return
		end
		oor = (inRange == false)
	end
	if host._outOfRange == oor then
		return
	end
	host._outOfRange = oor
	Paint.UpdateUsable(host)
end

--- Blizzard ACTION_RANGE_CHECK_UPDATE is per slot. Apply that payload to the
--- hosts that show the slot; do not GetActionInfo or walk the other 56.
--- Overlay faces range a parsed spell against @unit, so they ignore this.
function Paint.ApplySlotRange(slot, isInRange, checksRange)
	slot = tonumber(slot)
	if not slot then
		return
	end
	local list = Bars.Hosts and Bars.Hosts.ForSlot and Bars.Hosts.ForSlot(slot)
	if not list or #list == 0 then
		return
	end
	local oor = checksRange and (isInRange == false) and true or false
	for i = 1, #list do
		local host = list[i]
		if host then
			local face = FaceBoundToSlot(host, slot) and host._fluxFace
			if not (face and face._fluxStripFace) then
				if host._outOfRange ~= oor then
					host._outOfRange = oor
					Paint.UpdateUsable(host)
				end
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- Checked / equipped
-- ---------------------------------------------------------------------------

local function SpellIsCurrent(spellId)
	if not spellId then
		return false
	end
	local S = Flux.Spell
	if S and S.IsCurrent then
		local nameRank = S.FormatCastAttribute and S.FormatCastAttribute(spellId) or nil
		if S.IsCurrent(spellId, nameRank) then
			return true
		end
		if S.IsAutoRepeat and S.IsAutoRepeat(spellId, nameRank) then
			return true
		end
		return false
	end
	if S and S.GetOverrideSpell then
		spellId = S.GetOverrideSpell(spellId) or spellId
	end
	local function test(fn)
		if type(fn) ~= "function" then
			return false
		end
		local ok, v = pcall(fn, spellId)
		return ok and SafeBool(v, false) or false
	end
	if C_Spell then
		if test(C_Spell.IsCurrentSpell) or test(C_Spell.IsAutoRepeatSpell) then
			return true
		end
	end
	return test(IsCurrentSpell) or test(IsAutoRepeatSpell)
end

local function SlotIsCurrent(slot)
	if not slot then
		return false
	end
	if C_ActionBar and C_ActionBar.IsCurrentAction then
		local ok, v = pcall(C_ActionBar.IsCurrentAction, slot)
		if ok then
			return SafeBool(v, false) or false
		end
	end
	if IsCurrentAction then
		return SafeBool(IsCurrentAction(slot), false) or false
	end
	return false
end

local function TargetingNow()
	if type(SpellIsTargeting) ~= "function" then
		return false
	end
	local ok, targeting = pcall(SpellIsTargeting)
	return ok and targeting and true or false
end

-- Mount spells keep IsCurrentSpell after dismiss. Gold follows mounted.
local function MountSpellStillActive(spellId)
	if not spellId or not C_MountJournal or not C_MountJournal.GetMountFromSpell then
		return true
	end
	local ok, mountId = pcall(C_MountJournal.GetMountFromSpell, spellId)
	if not ok or not mountId then
		return true
	end
	if type(IsMounted) ~= "function" then
		return true
	end
	local okM, mounted = pcall(IsMounted)
	return okM and mounted and true or false
end

local CHECKED_POLL = 0.5
local checkedPollArmed = false
local litChecked = {}

local function AfterChecked(delay, fn)
	local T = Flux.Timer
	if T and T.After then
		T.After(delay, fn)
		return
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(delay, fn)
	end
end

local function CheckedVisualOn(widget)
	local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
	return ov and ov.CheckedVisualOn and ov.CheckedVisualOn(widget) and true or false
end

local function InCheckedHopBurst()
	local R = Flux.Range
	return R and R.IsHopBurst and R.IsHopBurst() and true or false
end

--- Only hosts that are gold (or still showing leftover hilight). Never 57
--- Spell.IsCurrent probes; the hop storm stays on the held event path.
function Paint.SweepLitChecked()
	local any = false
	for host in pairs(litChecked) do
		Paint.UpdateChecked(host)
		if host._checked or CheckedVisualOn(host.widget) then
			any = true
		else
			litChecked[host] = nil
		end
	end
	return any
end

local function CheckedPollTick()
	checkedPollArmed = false
	if InCheckedHopBurst() then
		Paint.ArmCheckedPoll()
		return
	end
	if Paint.SweepLitChecked() then
		Paint.ArmCheckedPoll()
	end
end

function Paint.ArmCheckedPoll()
	if checkedPollArmed then
		return
	end
	local any = false
	for _ in pairs(litChecked) do
		any = true
		break
	end
	if not any then
		return
	end
	checkedPollArmed = true
	AfterChecked(CHECKED_POLL, CheckedPollTick)
end

function Paint.UpdateFlash(host)
	local F = Flux.ButtonFX and Flux.ButtonFX.Flash
	if not (F and F.Set) then
		return
	end
	local widget = host and host.widget
	if not widget then
		return
	end
	if host._fluxParked or widget._fluxParked then
		F.Set(widget, false)
		return
	end
	local want = false
	local slot = LiveSlot(host)
	local kind, shown = ProgramShown(host, slot)
	if kind == "spell" and shown then
		want = F.WantSpell and F.WantSpell(shown) or false
	elseif kind == "item" and shown then
		want = F.WantItem and F.WantItem(shown) or false
	elseif slot then
		want = F.WantSlot and F.WantSlot(slot) or false
	end
	F.Set(widget, want and true or false)
end

function Paint.UpdateChecked(host)
	local widget = host.widget
	Paint.UpdateFlash(host)
	if not widget or not widget.SetChecked then
		return
	end
	local ov = Flux.ButtonFX and Flux.ButtonFX.Overlay
	local slot = LiveSlot(host)
	local spellId
	local FX = Flux.ButtonFX
	if slot and FX and FX.SpellIdFromAction then
		spellId = FX.SpellIdFromAction(slot)
	end
	local kind, shown = ProgramShown(host, slot)
	if kind == "spell" and shown then
		spellId = shown
	end
	local auto = slot and IsAutoRepeatAction and SafeBool(IsAutoRepeatAction(slot), false) or false
	local spellCurrent = SpellIsCurrent(spellId)
	local slotCurrent = SlotIsCurrent(slot)
	if spellCurrent and not slotCurrent and not auto and FX and FX.Cast and FX.Cast.SpellBlockedAsCurrent then
		if FX.Cast.SpellBlockedAsCurrent(spellId) then
			spellCurrent = false
		end
	end
	if spellCurrent and not MountSpellStillActive(spellId) then
		spellCurrent = false
	end
	local targeting = TargetingNow()
	-- Overlay Extra face: gold follows the live shown spell, never the native slot.
	-- SlotIsCurrent would gold the bar while the reverse badge also golds the other face.
	local checked
	if kind == "spell" and shown then
		checked = auto or spellCurrent
	else
		checked = auto or spellCurrent or slotCurrent
	end
	if ov and ov.IsLiveReticle and ov.IsLiveReticle(widget) then
		checked = false
	end
	if targeting then
		widget._fluxHadReticle = true
	elseif widget._fluxHadReticle then
		widget._fluxHadReticle = nil
	end
	checked = checked and true or false
	-- Nothing moved: skip the widget writes entirely. Paint.ClearCache drops
	-- host._checked, and every Flux writer stamps _fluxCheckedApplied through
	-- Overlay.ApplyChecked, so a repaint still lands whenever it has to.
	-- Visual must match too: leftover CheckButtonHilight is the stuck gold.
	if host._checked == checked and widget._fluxCheckedApplied == checked
		and CheckedVisualOn(widget) == checked
	then
		if checked then
			litChecked[host] = true
			Paint.ArmCheckedPoll()
		else
			litChecked[host] = nil
		end
		return
	end
	if ov and ov.ApplyChecked then
		ov.ApplyChecked(widget, checked)
	else
		widget._fluxCheckedApplied = checked
		widget:SetChecked(checked)
	end
	widget._fluxPaintChecked = checked
	host._checked = checked
	if checked or CheckedVisualOn(widget) then
		litChecked[host] = true
		Paint.ArmCheckedPoll()
	else
		litChecked[host] = nil
	end
end

function Paint.UpdateEquipped(host)
	local border = host.WBorder
	if not border then
		return
	end
	local slot = LiveSlot(host)
	local equipped = false
	local A = ActionAPI()
	if slot and A and A.IsEquipped then
		equipped = SafeBool(A.IsEquipped(slot), false) or false
	elseif slot and IsEquippedAction then
		equipped = SafeBool(IsEquippedAction(slot), false) or false
	end
	local shown = border.IsShown and border:IsShown() and true or false
	-- Cache skip must match the widget: leftover green on an empty bonus/form
	-- slot stays visible when the cache compares only host._equipped.
	if host._equipped == equipped and shown == equipped then
		return
	end
	host._equipped = equipped
	if equipped then
		border:SetVertexColor(0, 1, 0, 0.5)
		if border.SetBlendMode then
			pcall(border.SetBlendMode, border, "ADD")
		end
		border:Show()
	else
		border:Hide()
	end
end

-- ---------------------------------------------------------------------------
-- Hotkey (backup Texture\ mouse / scroll / space glyphs + S-/C- paging prefix)
-- ---------------------------------------------------------------------------

local KEY_ICON_SIZE = 14

local function HotkeyFontSize()
	if Flux.Client and Flux.Client.isPostDF then
		return 14
	end
	return 13
end

local function WidgetHotkeyXFactor(widget)
	if FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetWidgetHorizontalSqueezeFactor then
		local native = (Bars.CONFIG and Bars.CONFIG.buttonSize) or 44
		return FluxUILayoutSqueeze.GetWidgetHorizontalSqueezeFactor(widget, native)
	end
	if not widget or not widget.GetWidth or not widget.GetHeight then
		return 1
	end
	local w, h = widget:GetWidth(), widget:GetHeight()
	if type(w) ~= "number" or type(h) ~= "number" or h <= 0 then
		return 1
	end
	local f = w / h
	if f ~= f or f <= 0 then
		return 1
	end
	return math.max(0.4, math.min(1, f))
end

local function PrepareHotKey(fs, widget)
	if not fs then
		return
	end
	local fontSize = HotkeyFontSize()
	local frameHeight = math.max(fontSize, KEY_ICON_SIZE) + 4
	if widget then
		fs:ClearAllPoints()
		fs:SetPoint("TOPRIGHT", widget, "TOPRIGHT", -2, -4)
	end
	if fs.SetHeight then
		pcall(fs.SetHeight, fs, frameHeight)
	end
	fs:SetFontObject("NumberFontNormalSmallGray")
	local font = fs.GetFont and fs:GetFont()
	if font then
		pcall(fs.SetFont, fs, font, fontSize, "OUTLINE")
	end
	fs:SetTextColor(0.75, 0.75, 0.75)
	fs:SetJustifyH("RIGHT")
	if fs.SetJustifyV then
		pcall(fs.SetJustifyV, fs, "TOP")
	end
	if fs.SetWordWrap then
		pcall(fs.SetWordWrap, fs, false)
	end
end

local function ModifierOverlay(widget, hotKey)
	if not widget then
		return nil
	end
	local overlay = widget._fluxHotkeyMod
	if overlay then
		return overlay
	end
	overlay = widget:CreateFontString(nil, "OVERLAY")
	overlay:SetFontObject("NumberFontNormalSmallGray")
	local font = hotKey and hotKey.GetFont and hotKey:GetFont()
	if font then
		pcall(overlay.SetFont, overlay, font, HotkeyFontSize(), "OUTLINE")
	end
	overlay:SetTextColor(0.75, 0.75, 0.75)
	overlay:SetPoint("RIGHT", hotKey, "RIGHT", -KEY_ICON_SIZE, 0)
	widget._fluxHotkeyMod = overlay
	return overlay
end

function Paint.AbbreviateKey(key, iconSize, iconWidth)
	local H = Flux.Hotkey
	local live = (H and H.LivePrefix and H.LivePrefix()) or ""
	if H and H.Format then
		local display, isIcon = H.Format(key, iconSize, iconWidth)
		-- Backup paging overlay: live Shift else Ctrl only, never the bind's own mods.
		if isIcon then
			return display, true, live
		end
		return live .. display, false, ""
	end
	return live .. (key or ""), false, ""
end

function Paint.UpdateHotkey(host)
	local fs = host.WHotKey
	if not fs then
		return
	end
	local widget = host.widget
	if host.row and host.row ~= "main" then
		if host._hotkey ~= "" then
			host._hotkey = ""
			fs:SetText("")
			fs:Hide()
		end
		if widget and widget._fluxHotkeyMod then
			widget._fluxHotkeyMod:Hide()
		end
		return
	end
	local key = ""
	if host.bindingCommand and GetBindingKey then
		key = GetBindingKey(host.bindingCommand) or ""
	end
	-- _hotkeyRaw is the bind chord (ACTIONBUTTON1 / borrowed 13-19). It does
	-- not change on SHIFT/CTRL press. LivePrefix must be in the skip or S-/C-
	-- never appears or drops.
	local H = Flux.Hotkey
	local live = (H and H.LivePrefix and H.LivePrefix()) or ""
	local xF = WidgetHotkeyXFactor(widget)
	local iconH = KEY_ICON_SIZE
	local iconW = math.max(1, KEY_ICON_SIZE * xF)
	if host._hotkeyRaw == key and host._hotkeyLive == live and host._hotkeyXF == xF then
		if host._hotkeyShown then
			fs:Show()
		end
		return
	end
	host._hotkeyRaw = key
	host._hotkeyLive = live
	host._hotkeyXF = xF
	local text, isIcon, prefix = "", false, ""
	if key ~= "" then
		text, isIcon, prefix = Paint.AbbreviateKey(key, iconH, iconW)
	end
	host._hotkeyShown = text ~= ""
	local sig = text .. "\0" .. (isIcon and prefix or "")
	if host._hotkey == sig then
		if text ~= "" then
			fs:Show()
		end
		return
	end
	host._hotkey = sig
	PrepareHotKey(fs, widget)
	if text == "" then
		fs:SetText("")
		fs:Hide()
		if widget and widget._fluxHotkeyMod then
			widget._fluxHotkeyMod:Hide()
		end
		return
	end
	if isIcon and prefix ~= "" and widget then
		fs:SetText(text)
		local overlay = ModifierOverlay(widget, fs)
		overlay:ClearAllPoints()
		overlay:SetPoint("RIGHT", fs, "RIGHT", -iconW, 0)
		overlay:SetText(prefix)
		overlay:Show()
	else
		fs:SetText(text)
		if widget and widget._fluxHotkeyMod then
			widget._fluxHotkeyMod:Hide()
		end
	end
	fs:Show()
end

-- ---------------------------------------------------------------------------
-- Single-button assistant (rotation helper chrome + next-cast morph)
-- Mixin Update() is detached; without this the ring/count/icon vanish after
-- paging. Paint from GetNextCastSpell — do not call mixin Update.
-- ---------------------------------------------------------------------------

local function AssistedUpdateRate()
	local rate = 0.1
	local mgr = _G.AssistedCombatManager
	if mgr and mgr.GetUpdateRate then
		local ok, r = pcall(mgr.GetUpdateRate, mgr)
		if ok and type(r) == "number" then
			rate = r
		end
	end
	if type(rate) ~= "number" or rate ~= rate or rate < 0 then
		rate = 0.1
	end
	-- CVar 0 = every frame. Floor like LAB so the face still morphs.
	if rate < 0.05 then
		rate = 0.05
	end
	return rate
end

local function AssistantRotationOnUpdate(frame, elapsed)
	if not frame or (frame.IsShown and not frame:IsShown()) then
		return
	end
	frame._fluxAssistTimeLeft = (frame._fluxAssistTimeLeft or 0) - (elapsed or 0)
	if frame._fluxAssistTimeLeft > 0 then
		return
	end
	frame._fluxAssistTimeLeft = AssistedUpdateRate()
	local widget = frame.GetParent and frame:GetParent()
	local host = widget and widget._fluxHost
	if host then
		Paint.UpdateIcon(host)
		Paint.UpdateCount(host)
		Paint.UpdateName(host)
		Paint.UpdateCooldown(host)
		Paint.UpdateUsable(host)
		Paint.UpdateChecked(host)
		if Bars.Effects and Bars.Effects.Refresh then
			Bars.Effects.Refresh(host)
		end
	end
end

function Paint.UpdateAssistedCombat(host)
	local widget = host and host.widget
	if not widget then
		return
	end
	local Cap = Flux.Cap
	if not (Cap and Cap.ClientSupportsSingleButtonAssistant and Cap.ClientSupportsSingleButtonAssistant()) then
		return
	end
	if not (C_ActionBar and C_ActionBar.IsAssistedCombatAction) then
		return
	end
	local slot = host.slot or widget.action
	local show = slot and C_ActionBar.IsAssistedCombatAction(slot) and true or false
	local rot = widget.AssistedCombatRotationFrame
	if show and not rot then
		local ok, frame = pcall(CreateFrame, "Frame", nil, widget, "ActionBarButtonAssistedCombatRotationTemplate")
		if ok and frame then
			rot = frame
			widget.AssistedCombatRotationFrame = rot
		end
	end
	if not rot then
		if show and Bars.Watch and Bars.Watch.SyncAssistantTicker then
			Bars.Watch.SyncAssistantTicker()
		end
		return
	end
	-- Mixin OnUpdate would notify leftover stock buttons. Flux paints the face
	-- from the bars.assistant ticker; keep this frame for the glow visual only.
	local was = rot._fluxAssistWanted and true or false
	rot._fluxAssistWanted = show or nil
	rot:SetScript("OnUpdate", nil)
	rot.OnUpdate = function() end
	if show then
		local w = (widget.GetWidth and widget:GetWidth()) or 0
		local h = (widget.GetHeight and widget:GetHeight()) or 0
		if w > 0 and h > 0 then
			rot:SetSize(w * 1.4, h * 1.4)
			rot:ClearAllPoints()
			rot:SetPoint("CENTER", widget, "CENTER", -2, 1)
		end
		if widget.GetFrameStrata then
			pcall(rot.SetFrameStrata, rot, widget:GetFrameStrata())
		end
		if rot.SetFrameLevel and widget.GetFrameLevel then
			pcall(rot.SetFrameLevel, rot, (widget:GetFrameLevel() or 0) + 6)
		end
		if rot.EnableMouse then
			pcall(rot.EnableMouse, rot, false)
		end
		if not rot._fluxAssistArmed then
			rot._fluxAssistArmed = true
			rot._fluxAssistTimeLeft = 0
		end
		pcall(rot.Show, rot)
		if rot.UpdateGlow then
			pcall(rot.UpdateGlow, rot)
		end
		SyncAssistedNext(host)
	else
		rot._fluxAssistArmed = nil
		pcall(rot.Hide, rot)
	end
	if was ~= show and Bars.Watch and Bars.Watch.SyncAssistantTicker then
		Bars.Watch.SyncAssistantTicker()
	end
end

local function AssistHighlightIdsEqual(a, b)
	if a == nil or b == nil then
		return false
	end
	if IsSecret(a) or IsSecret(b) then
		return false
	end
	a = tonumber(a)
	b = tonumber(b)
	return a and b and a > 0 and a == b
end

local function AssistHighlightInCombat()
	local mgr = _G.AssistedCombatManager
	if mgr and mgr.affectingCombat ~= nil then
		return mgr.affectingCombat and true or false
	end
	if UnitAffectingCombat then
		local ok, v = pcall(UnitAffectingCombat, "player")
		return ok and v and true or false
	end
	return false
end

local function HideAssistedHighlight(widget)
	local hl = widget and widget.AssistedCombatHighlightFrame
	if not hl then
		return
	end
	local anim = hl.Flipbook and hl.Flipbook.Anim
	if anim and anim.Stop then
		pcall(anim.Stop, anim)
	end
	pcall(hl.Hide, hl)
end

-- Flux hosts are not on ActionBarButtonEventsFrame, so Blizzard's
-- AssistedCombatManager candidate list never includes them. Paint the
-- ActionBarButtonAssistedCombatHighlightTemplate ants here.
function Paint.UpdateAssistedHighlight(host, nextSpellId, spellQueried, highlightActive)
	local widget = host and host.widget
	if not widget then
		return
	end
	local A = ActionAPI()
	-- Batch callers share one activation sample; standalone updates stay fresh.
	if highlightActive == nil then
		highlightActive = A and A.IsAssistedHighlightActive and A.IsAssistedHighlightActive()
	end
	if not highlightActive then
		HideAssistedHighlight(widget)
		return
	end
	if host._fluxParked then
		HideAssistedHighlight(widget)
		return
	end
	if not spellQueried then
		nextSpellId = A.GetAssistedHighlightSpell and A.GetAssistedHighlightSpell()
	end
	local cand = A.SpellForAssistedHighlight and A.SpellForAssistedHighlight(LiveSlot(host))
	local show = nextSpellId and cand and cand ~= 0 and AssistHighlightIdsEqual(cand, nextSpellId)
	if not show then
		HideAssistedHighlight(widget)
		return
	end
	local hl = widget.AssistedCombatHighlightFrame
	if not hl and not widget._fluxAssistHighlightMissing then
		local ok, frame = pcall(CreateFrame, "Frame", nil, widget, "ActionBarButtonAssistedCombatHighlightTemplate")
		if ok and frame then
			hl = frame
			widget.AssistedCombatHighlightFrame = hl
			hl:ClearAllPoints()
			hl:SetPoint("CENTER")
			if hl.EnableMouse then
				pcall(hl.EnableMouse, hl, false)
			end
			if hl.EnableMouseClicks then
				pcall(hl.EnableMouseClicks, hl, false)
			end
			local flip = hl.Flipbook
			if flip and flip.Anim then
				pcall(flip.Anim.Play, flip.Anim)
				pcall(flip.Anim.Stop, flip.Anim)
			end
		else
			widget._fluxAssistHighlightMissing = true
			return
		end
	end
	if not hl then
		return
	end
	local w = (widget.GetWidth and widget:GetWidth()) or 0
	local h = (widget.GetHeight and widget:GetHeight()) or 0
	if w > 0 and h > 0 then
		hl:SetSize(w, h)
		if hl.Flipbook then
			hl.Flipbook:SetSize(w * (66 / 45), h * (66 / 45))
		end
	end
	if widget.GetFrameStrata then
		pcall(hl.SetFrameStrata, hl, widget:GetFrameStrata())
	end
	if hl.SetFrameLevel and widget.GetFrameLevel then
		pcall(hl.SetFrameLevel, hl, (widget:GetFrameLevel() or 0) + 10)
	end
	pcall(hl.Show, hl)
	local anim = hl.Flipbook and hl.Flipbook.Anim
	if anim then
		if AssistHighlightInCombat() then
			if anim.Play then
				pcall(anim.Play, anim)
			end
		elseif anim.Stop then
			pcall(anim.Stop, anim)
		end
	end
end

function Paint.PaintAssistedHighlights()
	local A = ActionAPI()
	local highlightActive = (A and A.IsAssistedHighlightActive and A.IsAssistedHighlightActive()) and true or false
	local nextId
	if highlightActive then
		nextId = A.GetAssistedHighlightSpell and A.GetAssistedHighlightSpell()
	end
	Bars.ForEachHost(function(host)
		Paint.UpdateAssistedHighlight(host, nextId, true, highlightActive)
	end)
end

function Paint.PaintAssistedHosts()
	Bars.ForEachHost(function(host)
		local slot = host.slot
		if not SlotIsAssisted(slot) then
			return
		end
		Paint.UpdateIcon(host)
		Paint.UpdateCount(host)
		Paint.UpdateName(host)
		Paint.UpdateCooldown(host)
		Paint.UpdateUsable(host)
		Paint.UpdateChecked(host)
		if Bars.Effects and Bars.Effects.Refresh then
			Bars.Effects.Refresh(host)
		end
	end)
end

-- ---------------------------------------------------------------------------
-- Flush
-- ---------------------------------------------------------------------------

function Paint.UpdateDisplay(host)
	Paint.UpdateAssistedCombat(host)
	Paint.UpdateAssistedHighlight(host)
	Paint.UpdateIcon(host)
	Paint.UpdateCount(host)
	Paint.UpdateName(host)
	Paint.UpdateCooldown(host)
	Paint.UpdateEquipped(host)
	Paint.UpdateRange(host)
	Paint.UpdateUsable(host)
	Paint.UpdateChecked(host)
	Paint.UpdateHotkey(host)
	if Bars.Flyout and Bars.Flyout.Update then
		Bars.Flyout.Update(host)
	end
end

function Paint.UpdateAll(host)
	Paint.UpdateDisplay(host)
	if Bars.Effects and Bars.Effects.Refresh then
		Bars.Effects.Refresh(host)
	end
end

local dirtyHosts = {}

--- A surface worth running the value lanes on: something is actually on it.
function Paint.HostIsLive(host)
	if not host or host._fluxParked then
		return false
	end
	local slot = LiveSlot(host)
	local face = FaceBoundToSlot(host, slot) and host._fluxFace
	if face and (face.SpellId or face.ItemId or (face.MacroMode and face.MacroMode ~= "")) then
		return true
	end
	local widget = host.widget
	if widget and widget._fluxAssistedCombat then
		return true
	end
	return HasSlot(LiveSlot(host)) and true or false
end

function Paint.MarkDirty(host)
	if not host then
		return
	end
	Paint.ClearCache(host)
	dirtyHosts[host] = true
end

function Paint.Dirty(host)
	Paint.MarkDirty(host)
	Bars.RequestPaint("bars.dirty")
end

function Paint.EachDirty(fn)
	if type(fn) ~= "function" then
		return
	end
	for host in pairs(dirtyHosts) do
		fn(host)
	end
end

function Paint.Flush(tokens)
	local full = (tokens == nil) or tokens["bars"] == true
	local hasDirty = tokens and tokens["bars.dirty"] and true or false
	local icon = full or (tokens and tokens["bars.icon"])
	local count = full or (tokens and tokens["bars.count"])
	local cooldown = full or (tokens and tokens["bars.cooldown"])
	local usable = full or (tokens and tokens["bars.usable"])
	local checked = full or (tokens and tokens["bars.checked"])
	local equipped = full or (tokens and tokens["bars.equipped"])
	local range = full or (tokens and tokens["bars.range"])
	local hotkey = full or (tokens and tokens["bars.hotkey"])
	local glow = full or (tokens and tokens["bars.glow"])
	local valueLane = icon or count or cooldown or usable or checked or equipped or range or glow
	local anyLane = valueLane or hotkey
	local painted

	-- Swapped hosts (SHIFT/CTRL, form page) MarkDirty then coalesce bars.dirty
	-- with count/cd/hotkey. UpdateAll those hosts so icon/usable/checked land
	-- even when the event never asked for bars.icon. A dirty-only pass stops
	-- there. Independently requested lanes still reach the other hosts: a slot
	-- move must not swallow a coalesced cooldown/charge/icon event.
	if full then
		for host in pairs(dirtyHosts) do
			dirtyHosts[host] = nil
		end
	elseif hasDirty then
		if anyLane then
			painted = {}
		end
		local Perf = Flux.Perf
		if Perf then
			Perf.Begin("bars.paint.dirty")
		end
		local FX = Flux.ButtonFX
		if FX and FX.BeginSlotPass then
			FX.BeginSlotPass()
		end
		for host in pairs(dirtyHosts) do
			if painted then
				painted[host] = true
			end
			Paint.UpdateAll(host)
			dirtyHosts[host] = nil
		end
		if FX and FX.EndSlotPass then
			FX.EndSlotPass()
		end
		if Perf then
			Perf.Stop("bars.paint.dirty")
		end
	end

	if not anyLane then
		return
	end

	local Perf = Flux.Perf
	local passKey = full and "bars.paint.full" or "bars.paint.lane"
	if Perf then
		Perf.Begin(passKey)
	end
	local FX = Flux.ButtonFX
	if FX and FX.BeginSlotPass then
		FX.BeginSlotPass()
	end

	local A = ActionAPI()
	local highlightActive = (A and A.IsAssistedHighlightActive and A.IsAssistedHighlightActive()) and true or false
	local flushHighlightId
	if highlightActive then
		flushHighlightId = A.GetAssistedHighlightSpell and A.GetAssistedHighlightSpell()
	end

	local function PaintOne(host, applyHotkey)
		-- An empty surface has nothing to repaint. A slot that empties out is
		-- in dirtyHosts so leftover noform CD / dim still drop. Most of the 38
		-- minis sit empty on a normal layout.
		local live = Paint.HostIsLive(host)
		if live then
			if full or icon or count then
				Paint.UpdateAssistedCombat(host)
				Paint.UpdateAssistedHighlight(host, flushHighlightId, true, highlightActive)
			end
			if icon then
				Paint.UpdateIcon(host)
			end
			if count then
				Paint.UpdateCount(host)
			end
			if icon or count then
				Paint.UpdateName(host)
			end
			if cooldown then
				Paint.UpdateCooldown(host)
			end
			if equipped then
				Paint.UpdateEquipped(host)
			end
			if range then
				Paint.UpdateRange(host)
			end
			if usable then
				Paint.UpdateUsable(host)
			end
			if checked then
				Paint.UpdateChecked(host)
			end
			if icon or glow then
				if Bars.Flyout and Bars.Flyout.Update then
					Bars.Flyout.Update(host)
				end
			end
		elseif icon or count or checked or equipped or cooldown or usable then
			-- Parked / empty surfaces skip the value lanes, but leftover gold,
			-- leftover item-count digits, leftover noform icons, leftover equipped borders,
			-- leftover form-page cooldown swipes, leftover dim, and leftover assist ants still drop.
			Paint.UpdateAssistedHighlight(host, flushHighlightId, true, highlightActive)
			if cooldown or icon then
				ClearEmptyCooldown(host)
			end
			if usable or icon then
				ClearEmptyUsable(host)
			end
			if icon then
				local ic = host.WIcon
				local leftover = host._icon ~= nil or host._iconShown
				if not leftover and ic and ic.IsShown and ic:IsShown() then
					leftover = true
				end
				if leftover then
					Paint.UpdateIcon(host)
				end
			end
			if count then
				local fs = host.WCount
				local leftover = host._count and not CountLooksEmpty(host._count)
				if not leftover and fs and fs.GetText then
					-- GetText can return a secret string; never ~= "" it.
					leftover = not CountLooksEmpty(fs:GetText())
				end
				if leftover then
					Paint.UpdateCount(host)
				end
			end
			if checked then
				Paint.UpdateFlash(host)
				local w = host.widget
				if host._checked or (w and w._fluxCheckedApplied) or CheckedVisualOn(w) then
					Paint.UpdateChecked(host)
				end
			end
			if equipped then
				local border = host.WBorder
				if host._equipped or (border and border.IsShown and border:IsShown()) then
					Paint.UpdateEquipped(host)
				end
			end
			if icon and Bars.Flyout and Bars.Flyout.Update then
				Bars.Flyout.Update(host)
			end
		end
		-- An empty main row still shows its key, and glow transfer has to be
		-- able to clear a face that just emptied.
		if applyHotkey and hotkey then
			Paint.UpdateHotkey(host)
		end
		if glow and Bars.Effects and Bars.Effects.Refresh then
			Bars.Effects.Refresh(host)
		end
	end

	Bars.ForEachHost(function(host)
		if not (painted and painted[host]) then
			PaintOne(host, true)
		end
	end)

	if FX and FX.EndSlotPass then
		FX.EndSlotPass()
	end
	if Perf then
		Perf.Stop(passKey)
	end
end

function Paint.ClearCache(host)
	if not host then
		return
	end
	host._icon = nil
	host._iconShown = nil
	host._fluxOccKey = nil
	host._count = nil
	host._fxCountZero = nil
	host._fxItemEmpty = nil
	host._name = nil
	host.AssistedNextSpellId = nil
	host._cdStart, host._cdDur, host._cdEnable = nil, nil, nil
	host._fxCdActive = nil
	host._fxChargeState = nil
	host._fxChargeCur = nil
	host._fxChargeMax = nil
	if host.widget and Flux.ButtonFX and Flux.ButtonFX.Charges and Flux.ButtonFX.Charges.ClearCache then
		Flux.ButtonFX.Charges.ClearCache(host.widget)
	end
	host._r, host._g, host._b = nil, nil, nil
	host._checked = nil
	host._equipped = nil
	host._outOfRange = nil
	host._hotkey = nil
	host._hotkeyRaw = nil
	host._hotkeyLive = nil
	host._hotkeyShown = nil
	host._fluxAType, host._fluxAId = nil
end

Paint.QUESTION = QUESTION
