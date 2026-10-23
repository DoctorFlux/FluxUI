-- ExtraButtonSystem/Engine/Action.lua — SetAction env vs attributes; pickup / drag OOC
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS
local FluxButton = _G.FluxButton

local Action = {}
EBS.Action = Action

local ATTR_KEYS = {
	"type", "typerelease", "spell", "item", "macro", "macrotext",
	"action", "flyout", "toy", "unit", "IsEmpowerSpell", "clickbutton",
}

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

local function Defer(key, fn)
	if Flux.Combat and Flux.Combat.Defer then
		Flux.Combat.Defer(key, fn)
	elseif not InLockdown() then
		fn()
	end
end

local function ItemID(value)
	if type(value) == "number" then
		return value
	end
	if type(value) ~= "string" then
		return nil
	end
	local id = value:match("item:(%d+)") or value:match("^(%d+)$")
	return tonumber(id)
end

local function SpellID(value)
	if type(value) == "number" then
		return value
	end
	if type(value) == "string" then
		return tonumber(value)
	end
	return nil
end

local function StripHashLines(body)
	if type(body) ~= "string" then
		return body
	end
	local out = {}
	for line in string.gmatch(body, "[^\r\n]+") do
		if not string.match(line, "^%s*#") then
			out[#out + 1] = line
		end
	end
	return table.concat(out, "\n")
end

local function TrimMacroBody(body)
	if type(body) ~= "string" then
		return ""
	end
	return (string.gsub(string.gsub(body, "^%s+", ""), "%s+$", ""))
end

local function BodyHasMouseover(body)
	return type(body) == "string" and string.upper(body):find("MOUSEOVER", 1, true) ~= nil
end

local function ExtraClickerName(widget)
	local name = widget and widget.GetName and widget:GetName()
	if type(name) ~= "string" or name == "" then
		return nil
	end
	return name .. "_MoClick"
end

local function ParkExtraClicker(widget)
	if not widget then
		return
	end
	local clickName = ExtraClickerName(widget)
	if clickName then
		local Pool = ns.FluxSecureButtonPool or _G.FluxSecureButtonPool
		local btn = _G[clickName]
		if btn and btn.SetAttribute then
			btn:SetAttribute("macrotext", "")
		end
		if Pool and Pool.Retire then
			Pool.Retire(clickName)
		end
	end
	if widget.SetAttribute then
		widget:SetAttribute("clickbutton", nil)
	end
end

--- Shown Extra widgets must not carry live [@mouseover] macrotext. The full
--- body sits on a hidden sibling; the widget is type=click.
local function RouteExtraMacro(widget, body)
	if not widget or not widget.SetAttribute then
		return
	end
	if not BodyHasMouseover(body) then
		ParkExtraClicker(widget)
		widget:SetAttribute("type", "macro")
		widget:SetAttribute("typerelease", "macro")
		widget:SetAttribute("macrotext", body)
		widget:SetAttribute("macro", nil)
		widget:SetAttribute("unit", nil)
		return
	end
	local Pool = ns.FluxSecureButtonPool or _G.FluxSecureButtonPool
	local clickName = ExtraClickerName(widget)
	local clicker = Pool and Pool.Acquire and clickName and Pool.Acquire(clickName)
	if not clicker or (Pool.ArmMacroDelegate and not Pool.ArmMacroDelegate(clicker)) then
		widget:SetAttribute("type", "macro")
		widget:SetAttribute("typerelease", "macro")
		widget:SetAttribute("macrotext", body)
		widget:SetAttribute("macro", nil)
		widget:SetAttribute("clickbutton", nil)
		widget:SetAttribute("unit", nil)
		return
	end
	clicker:Hide()
	clicker:SetAttribute("type", "macro")
	clicker:SetAttribute("macro", nil)
	clicker:SetAttribute("macrotext", body)
	clicker:SetAttribute("checkmouseovercast", false)
	clicker:SetAttribute("unit", nil)
	widget:SetAttribute("type", "click")
	widget:SetAttribute("typerelease", "click")
	widget:SetAttribute("clickbutton", clicker)
	widget:SetAttribute("macrotext", nil)
	widget:SetAttribute("macro", nil)
	widget:SetAttribute("unit", nil)
end

Action.RouteMouseoverMacro = RouteExtraMacro

local function HasShowTooltip(body)
	-- #showtooltip contains #show. Both follow the shown spell like a bar slot.
	return type(body) == "string" and string.find(body, "#show") ~= nil
end

local function MacroBands()
	local accMax = MAX_ACCOUNT_MACROS or 120
	local charMax = MAX_CHARACTER_MACROS or 18
	local numAcc, numChar = 0, 0
	if GetNumMacros then
		numAcc, numChar = GetNumMacros()
		numAcc = tonumber(numAcc) or 0
		numChar = tonumber(numChar) or 0
	end
	return accMax, charMax, numAcc, numChar
end

local function MacroInfoAt(index)
	if not index or not GetMacroInfo then
		return nil, nil, nil
	end
	local name, icon, body = GetMacroInfo(index)
	if not name then
		return nil, nil, nil
	end
	return name, icon, body
end

local function ScanMacros(pred)
	local accMax, _, numAcc, numChar = MacroBands()
	for i = 1, numAcc do
		local n, icon, b = MacroInfoAt(i)
		if n and pred(i, n, b, icon) then
			return i, n, b, icon
		end
	end
	for i = accMax + 1, accMax + numChar do
		local n, icon, b = MacroInfoAt(i)
		if n and pred(i, n, b, icon) then
			return i, n, b, icon
		end
	end
	return nil
end

local function ResolveMacroIndex(value)
	local hintIndex, hintName, hintBody
	if type(value) == "table" then
		hintIndex = tonumber(value.index or value.data or value.actionValue)
		hintName = value.name or value.macroName
		hintBody = value.body or value.macroBody
		if hintIndex then
			local n, _, b = MacroInfoAt(hintIndex)
			if n then
				local bodyOk = (not hintBody) or TrimMacroBody(b) == TrimMacroBody(hintBody)
				local nameOk = (not hintName) or n == hintName
				if bodyOk and nameOk then
					return hintIndex
				end
			end
		end
		if hintName and hintBody then
			local idx = ScanMacros(function(_, n, b)
				return n == hintName and TrimMacroBody(b) == TrimMacroBody(hintBody)
			end)
			if idx then
				return idx
			end
		end
		if hintBody and hintBody ~= "" then
			local idx = ScanMacros(function(_, _, b)
				return TrimMacroBody(b) == TrimMacroBody(hintBody)
			end)
			if idx then
				return idx
			end
		end
		if hintName and GetMacroIndexByName then
			local idx = GetMacroIndexByName(hintName)
			if idx and idx > 0 then
				return idx
			end
		end
		if hintIndex and MacroInfoAt(hintIndex) then
			return hintIndex
		end
		return nil
	end
	if type(value) == "number" then
		if MacroInfoAt(value) then
			return value
		end
		return nil
	end
	if type(value) == "string" then
		if GetMacroIndexByName then
			local idx = GetMacroIndexByName(value)
			if idx and idx > 0 then
				return idx
			end
		end
		local asNum = tonumber(value)
		if asNum and MacroInfoAt(asNum) then
			return asNum
		end
	end
	return nil
end

local function ClearAttributes(widget)
	if not widget or not widget.SetAttribute then
		return
	end
	ParkExtraClicker(widget)
	for i = 1, #ATTR_KEYS do
		widget:SetAttribute(ATTR_KEYS[i], nil)
	end
end

local function ItemAttribute(itemId)
	if not itemId then
		return nil
	end
	local name
	if Flux.Item and Flux.Item.GetInfo then
		name = Flux.Item.GetInfo(itemId)
	elseif GetItemInfo then
		name = GetItemInfo(itemId)
	end
	if type(name) == "string" and name ~= "" then
		return name
	end
	return "item:" .. tostring(itemId)
end

local function SpellCastAttribute(spellId)
	if Flux.Spell and Flux.Spell.FormatCastAttribute then
		return Flux.Spell.FormatCastAttribute(spellId)
	end
	return spellId
end

local function FlyoutId(value)
	if type(value) == "number" then
		return value
	end
	if type(value) == "string" then
		return tonumber(value:match("FLYOUT(%d+)") or value)
	end
	return nil
end

local function ProfessionOpenMacro(spellId)
	if not GetProfessions or not GetProfessionInfo then
		return nil
	end
	if not C_TradeSkillUI or not C_TradeSkillUI.OpenTradeSkill then
		return nil
	end
	local name = Flux.Spell and Flux.Spell.GetName and Flux.Spell.GetName(spellId)
	if not name then
		return nil
	end
	local p1, p2 = GetProfessions()
	local function match(idx)
		if not idx then
			return nil
		end
		local pname, _, _, _, _, _, skillLine = GetProfessionInfo(idx)
		if pname == name and skillLine then
			return "/run C_TradeSkillUI.OpenTradeSkill(" .. tostring(skillLine) .. ")"
		end
		return nil
	end
	return match(p1) or match(p2)
end

local function NoteSpellName(btn, spellId, hint)
	if not btn then
		return
	end
	if type(hint) == "string" and hint ~= "" then
		btn.SpellNameRank = hint
		btn.SpellName = hint:match("^([^%(]+)") or hint
		return
	end
	if spellId and Flux.Spell then
		if Flux.Spell.FormatCastAttribute then
			btn.SpellNameRank = Flux.Spell.FormatCastAttribute(spellId)
		end
		if Flux.Spell.GetName then
			btn.SpellName = Flux.Spell.GetName(spellId) or btn.SpellNameRank
		end
	end
end

local RANDOM_MOUNT_ID = 268435455
local RANDOM_MOUNT_SPELL = 150544

local function CapHas(key)
	return Flux.Cap and Flux.Cap[key] and true or false
end

-- Classic companions: GetCompanionInfo(type, index) → creatureSpellID as 3rd return.
local function CompanionSpellID(kind, index)
	if not GetCompanionInfo or index == nil then
		return nil
	end
	local ok, _, _, spellID = pcall(GetCompanionInfo, kind, index)
	spellID = ok and tonumber(spellID) or nil
	if spellID and spellID > 0 then
		return spellID
	end
	return nil
end

local function CleanMountName(name)
	if type(name) == "string" and name ~= "" then
		return name
	end
	return nil
end

local function CleanMountSpell(spellID)
	spellID = tonumber(spellID)
	if spellID and spellID > 0 then
		return spellID
	end
	return nil
end

local function CleanMountIcon(icon)
	if type(icon) == "number" and icon > 0 then
		return icon
	end
	if type(icon) == "string" and icon ~= "" and not string.find(icon, "QuestionMark") then
		return icon
	end
	return nil
end

-- Journal is often empty at login; nil fields mean "not loaded yet", not "unknown mount".
local function ReadMountInfo(mountId)
	if not mountId then
		return nil, nil, nil
	end
	if mountId == RANDOM_MOUNT_ID or mountId == 0 then
		local spellName = Flux.Spell and Flux.Spell.GetName and Flux.Spell.GetName(RANDOM_MOUNT_SPELL)
		return spellName, RANDOM_MOUNT_SPELL, nil
	end
	if not C_MountJournal or not C_MountJournal.GetMountInfoByID then
		return nil, nil, nil
	end
	local ok, name, spellID, icon = pcall(C_MountJournal.GetMountInfoByID, mountId)
	if not ok then
		return nil, nil, nil
	end
	return CleanMountName(name), CleanMountSpell(spellID), CleanMountIcon(icon)
end

function Action.GetMountInfo(mountId)
	return ReadMountInfo(mountId)
end

local function ApplyMountEnv(btn, mountId, name, spellID)
	btn.ActionType = "mount"
	btn.ActionValue = mountId
	btn.MountId = mountId
	if mountId == RANDOM_MOUNT_ID then
		btn.MountSpellId = RANDOM_MOUNT_SPELL
	end
	if name then
		btn.MountName = name
	end
	if spellID then
		btn.MountSpellId = spellID
		if Flux.Spell and Flux.Spell.GetName then
			btn.MountSpellName = Flux.Spell.GetName(spellID) or name
		else
			btn.MountSpellName = name
		end
	elseif name then
		btn.MountSpellName = name
	end
end

local ASSISTANT_FALLBACK_ID = 1229376
local ASSISTANT_OVERLAY_SCALE = 1.4
local ASSISTANT_OVERLAY_X = -2
local ASSISTANT_OVERLAY_Y = 1
local ASSISTANT_BIND_CMD = "FLUX_ASSISTED_COMBAT"
local assistantBindOwner
local rotationTemplateOk

function Action.SupportsAssistant()
	local Cap = Flux.Cap
	if Cap and Cap.ClientSupportsSingleButtonAssistant then
		return Cap.ClientSupportsSingleButtonAssistant() and true or false
	end
	return false
end

function Action.GetAssistantActionSpell()
	if not Action.SupportsAssistant() then
		return nil
	end
	if C_AssistedCombat and C_AssistedCombat.GetActionSpell then
		local ok, id = pcall(C_AssistedCombat.GetActionSpell)
		if ok then
			id = tonumber(id)
			if id and id > 0 then
				return id
			end
		end
	end
	return ASSISTANT_FALLBACK_ID
end

-- GetNextCastSpell argument must stay false. true is highlight-mode and
-- returns nil while the one-button assistant is visible (ButtonForge).
function Action.GetAssistantNextSpell()
	if not Action.SupportsAssistant() then
		return nil
	end
	if Flux.Action and Flux.Action.GetAssistedNextSpell then
		local id = Flux.Action.GetAssistedNextSpell()
		if id then
			return id
		end
	elseif C_AssistedCombat and C_AssistedCombat.GetNextCastSpell then
		local ok, id = pcall(C_AssistedCombat.GetNextCastSpell, false)
		if ok then
			id = tonumber(id)
			if id and id > 0 then
				return id
			end
		end
	end
	return Action.GetAssistantActionSpell()
end

function Action.IsAssistantSpell(spellId)
	spellId = tonumber(spellId)
	if not spellId then
		return false
	end
	local actionId = Action.GetAssistantActionSpell()
	if not actionId then
		return false
	end
	if spellId == actionId then
		return true
	end
	local Spell = Flux.Spell
	if Spell then
		local ov = Spell.GetOverrideSpell
		local base = Spell.GetBaseSpell
		local a = ov and ov(spellId) or spellId
		local b = ov and ov(actionId) or actionId
		if a and b and a == b then
			return true
		end
		a = base and base(spellId) or spellId
		b = base and base(actionId) or actionId
		if a and b and a == b then
			return true
		end
	end
	return false
end

function Action.GetAssistantButton()
	local list = EBS.buttons
	if not list then
		return nil
	end
	for i = 1, #list do
		local btn = list[i]
		if btn and btn.IsAssistedCombat and btn.Widget then
			return btn
		end
	end
	return nil
end

local function CanUseRotationTemplate()
	if rotationTemplateOk ~= nil then
		return rotationTemplateOk
	end
	if not _G.ActionBarButtonAssistedCombatRotationFrameMixin then
		rotationTemplateOk = false
		return false
	end
	rotationTemplateOk = true
	return true
end

local function LayoutAssistantOverlay(widget)
	if not widget then
		return
	end
	local w = widget.GetWidth and widget:GetWidth() or 0
	local h = widget.GetHeight and widget:GetHeight() or 0
	if not w or not h or w <= 0 or h <= 0 then
		return
	end
	local ow, oh = w * ASSISTANT_OVERLAY_SCALE, h * ASSISTANT_OVERLAY_SCALE
	local rot = widget.AssistedCombatRotationFrame
	if rot then
		rot:SetSize(ow, oh)
		rot:ClearAllPoints()
		rot:SetPoint("CENTER", widget, "CENTER", ASSISTANT_OVERLAY_X, ASSISTANT_OVERLAY_Y)
		if widget.GetFrameStrata then
			pcall(rot.SetFrameStrata, rot, widget:GetFrameStrata())
		end
		if rot.SetFrameLevel and widget.GetFrameLevel then
			pcall(rot.SetFrameLevel, rot, (widget:GetFrameLevel() or 0) + 1)
		end
		if rot.EnableMouse then
			pcall(rot.EnableMouse, rot, false)
		end
	end
	local atlas = widget._fluxAssistantAtlas
	if atlas then
		atlas:SetSize(ow, oh)
		atlas:ClearAllPoints()
		atlas:SetPoint("CENTER", widget, "CENTER", ASSISTANT_OVERLAY_X, ASSISTANT_OVERLAY_Y)
		if widget.GetFrameStrata then
			pcall(atlas.SetFrameStrata, atlas, widget:GetFrameStrata())
		end
		if atlas.SetFrameLevel and widget.GetFrameLevel then
			pcall(atlas.SetFrameLevel, atlas, (widget:GetFrameLevel() or 0) + 10)
		end
		local tex = atlas.Texture
		if tex then
			pcall(tex.SetAtlas, tex, "UI-HUD-RotationHelper-Inactive", false)
			tex:SetAllPoints(atlas)
		end
	end
end

function Action.LayoutAssistant(btn)
	LayoutAssistantOverlay(btn and btn.Widget)
end

function Action.UpdateAssistantChrome(btn)
	local widget = btn and btn.Widget
	if not widget then
		return
	end
	local rot = widget.AssistedCombatRotationFrame
	if rot and rot.UpdateGlow then
		pcall(rot.UpdateGlow, rot)
	end
end

local function HideAssistantOverlay(widget)
	if not widget then
		return
	end
	local rot = widget.AssistedCombatRotationFrame
	if rot then
		pcall(rot.Hide, rot)
		local alert = rot.SpellActivationAlert
		if alert and alert.Hide then
			pcall(alert.Hide, alert)
		end
	end
	local atlas = widget._fluxAssistantAtlas
	if atlas then
		pcall(atlas.Hide, atlas)
	end
end

local function AttachRotationTemplate(widget)
	local existing = widget.AssistedCombatRotationFrame
	if existing then
		existing:SetScript("OnUpdate", nil)
		existing.OnUpdate = function() end
		LayoutAssistantOverlay(widget)
		pcall(existing.Show, existing)
		return existing
	end
	if not CanUseRotationTemplate() then
		return nil
	end
	local ok, frame = pcall(CreateFrame, "Frame", nil, widget, "ActionBarButtonAssistedCombatRotationTemplate")
	if not ok or not frame then
		rotationTemplateOk = false
		return nil
	end
	-- Mixin OnUpdate ForceUpdateAction's parent.action; EBS has no real slot.
	frame:SetScript("OnUpdate", nil)
	frame.OnUpdate = function() end
	if frame.EnableMouse then
		pcall(frame.EnableMouse, frame, false)
	end
	widget.AssistedCombatRotationFrame = frame
	LayoutAssistantOverlay(widget)
	pcall(frame.Show, frame)
	return frame
end

local function AttachAtlasOverlay(widget)
	local overlay = widget._fluxAssistantAtlas
	if not overlay then
		overlay = CreateFrame("Frame", nil, widget)
		overlay:EnableMouse(false)
		local tex = overlay:CreateTexture(nil, "OVERLAY")
		tex:SetAtlas("UI-HUD-RotationHelper-Inactive", false)
		tex:SetAllPoints(overlay)
		overlay.Texture = tex
		widget._fluxAssistantAtlas = overlay
	end
	LayoutAssistantOverlay(widget)
	overlay:Show()
	return overlay
end

local function EnsureSizeHook(btn)
	local widget = btn and btn.Widget
	if not widget or widget._fluxAssistantSizeHook then
		return
	end
	widget._fluxAssistantSizeHook = true
	widget:HookScript("OnSizeChanged", function(w)
		if w._fluxAssistedCombat then
			LayoutAssistantOverlay(w)
		end
	end)
end

function Action.AttachAssistant(btn)
	if not btn or not btn.Widget then
		return
	end
	local widget = btn.Widget
	if not btn.IsAssistedCombat then
		local G = Flux.ButtonFX and Flux.ButtonFX.Glow
		if G and G.Set then
			G.Set(widget, false)
		end
	end
	btn.IsAssistedCombat = true
	widget._fluxAssistedCombat = true
	EnsureSizeHook(btn)
	local rot = AttachRotationTemplate(widget)
	if not rot then
		AttachAtlasOverlay(widget)
	elseif widget._fluxAssistantAtlas then
		widget._fluxAssistantAtlas:Hide()
	end
	Action.UpdateAssistantChrome(btn)
end

function Action.ClearAssistant(btn)
	if not btn then
		return
	end
	local widget = btn.Widget
	local was = btn.IsAssistedCombat or (widget and widget._fluxAssistedCombat)
	btn.IsAssistedCombat = nil
	btn.AssistedNextSpellId = nil
	if widget then
		widget._fluxAssistedCombat = nil
		HideAssistantOverlay(widget)
	end
	if was then
		if EBS.Watch and EBS.Watch.SyncAssistantTicker then
			EBS.Watch.SyncAssistantTicker()
		end
		Action.RebindAssistant()
	end
end

function Action.SyncAssistant(btn)
	if not btn or not btn.Widget then
		return
	end
	local on = Action.SupportsAssistant()
		and btn.ActionType == "spell"
		and Action.IsAssistantSpell(btn.SpellId)
	local was = btn.IsAssistedCombat and true or false
	if on then
		if not was then
			Action.AttachAssistant(btn)
		else
			Action.LayoutAssistant(btn)
			Action.UpdateAssistantChrome(btn)
		end
	elseif was then
		Action.ClearAssistant(btn)
	end
	if EBS.Watch and EBS.Watch.SyncAssistantTicker then
		EBS.Watch.SyncAssistantTicker()
	end
	Action.RebindAssistant()
end

function Action.RefreshAssistantIdentity()
	if not Action.SupportsAssistant() then
		return
	end
	local list = EBS.buttons
	if not list then
		return
	end
	for i = 1, #list do
		local btn = list[i]
		if btn and btn.Widget and btn.ActionType == "spell" then
			Action.SyncAssistant(btn)
		elseif btn and btn.IsAssistedCombat then
			Action.ClearAssistant(btn)
		end
	end
end

function Action.RefreshAssistantChrome()
	local list = EBS.buttons
	if not list then
		return
	end
	for i = 1, #list do
		local btn = list[i]
		if btn and btn.IsAssistedCombat then
			Action.LayoutAssistant(btn)
			Action.UpdateAssistantChrome(btn)
		end
	end
end

function Action.PaintAssistantButtons()
	local list = EBS.buttons
	if not list then
		return
	end
	local Paint = EBS.Paint
	if not Paint or not Paint.Update then
		return
	end
	for i = 1, #list do
		local btn = list[i]
		if btn and btn.IsAssistedCombat then
			Paint.Update(btn)
		end
	end
end

function Action.RebindAssistant()
	if InLockdown() then
		Defer("ebs.assistant.bind", Action.RebindAssistant)
		return
	end
	if not SetOverrideBindingClick then
		return
	end
	if not assistantBindOwner then
		assistantBindOwner = CreateFrame("Frame", "FluxEBSAssistedCombatBind", UIParent)
	end
	if ClearOverrideBindings then
		ClearOverrideBindings(assistantBindOwner)
	end
	if not Action.SupportsAssistant() then
		return
	end
	local btn = Action.GetAssistantButton()
	local widget = btn and btn.Widget
	local name = widget and widget.GetName and widget:GetName()
	if not name or not GetBindingKey then
		return
	end
	local keys = { GetBindingKey(ASSISTANT_BIND_CMD) }
	for i = 1, #keys do
		local key = keys[i]
		if key and key ~= "" then
			pcall(SetOverrideBindingClick, assistantBindOwner, false, key, name, "KeyBind")
		end
	end
end

function Action.ClearEnv(btn)
	if not btn then
		return
	end
	Action.ClearAssistant(btn)
	btn.ActionType = nil
	btn.ActionValue = nil
	btn.SpellId = nil
	btn.ItemId = nil
	btn.MacroIndex = nil
	btn.MacroName = nil
	btn.MacroBody = nil
	btn.MacroMode = nil
	btn.MacroTarget = nil
	btn.MacroTexture = nil
	btn.MacroAction = nil
	btn.MacroTargetName = nil
	btn.MacroTargetDead = nil
	btn.ShowTooltip = nil
	btn.MountId = nil
	btn.MountSpellId = nil
	btn.MountName = nil
	btn.MountSpellName = nil
	btn.ToyId = nil
	btn.SpellName = nil
	btn.SpellNameRank = nil
	btn.FlyoutId = nil
	btn.BattlePetId = nil
	btn.BattlePetName = nil
	btn.OutfitId = nil
	btn.OutfitInfo = nil
	btn.IsEmpowerSpell = nil
	btn.PetSlot = nil
	btn.ShapeshiftIndex = nil
	btn.needsRange = nil
	btn._outOfRange = nil
	btn._lastUsable = nil
	btn._lastNoMana = nil
	if EBS.Paint and EBS.Paint.ClearCache then
		EBS.Paint.ClearCache(btn)
	end
end

local function WriteAttributes(btn)
	local widget = btn and btn.Widget
	if not widget then
		return
	end
	if InLockdown() then
		local key = "ebs.attr." .. (widget.GetName and widget:GetName() or tostring(widget))
		Defer(key, function()
			WriteAttributes(btn)
		end)
		return
	end

	ClearAttributes(widget)
	local actionType = btn.ActionType
	local actionValue = btn.ActionValue
	if not actionType or actionValue == nil then
		if widget.UpdateFlyout then
			pcall(widget.UpdateFlyout, widget)
		end
		return
	end

	if actionType == "spell" then
		local profMacro = ProfessionOpenMacro(btn.SpellId)
		if profMacro then
			widget:SetAttribute("type", "macro")
			widget:SetAttribute("typerelease", "macro")
			widget:SetAttribute("macrotext", profMacro)
		else
			local attr = SpellCastAttribute(btn.SpellId or actionValue)
			widget:SetAttribute("type", "spell")
			widget:SetAttribute("typerelease", "spell")
			widget:SetAttribute("spell", attr)
			if btn.IsEmpowerSpell then
				widget:SetAttribute("IsEmpowerSpell", true)
			end
		end
	elseif actionType == "item" then
		widget:SetAttribute("type", "item")
		widget:SetAttribute("typerelease", "item")
		widget:SetAttribute("item", ItemAttribute(btn.ItemId or actionValue))
	elseif actionType == "macro" then
		if btn.MacroIndex then
			local body = btn.MacroBody
			if (not body or body == "") and GetMacroInfo then
				body = select(3, GetMacroInfo(btn.MacroIndex))
			end
			if BodyHasMouseover(body) then
				RouteExtraMacro(widget, StripHashLines(body) or body)
			else
				ParkExtraClicker(widget)
				widget:SetAttribute("type", "macro")
				widget:SetAttribute("typerelease", "macro")
				widget:SetAttribute("macro", btn.MacroIndex)
			end
		end
	elseif actionType == "macrotext" then
		RouteExtraMacro(widget, StripHashLines(actionValue))
	elseif actionType == "outfit" then
		local info = btn.OutfitInfo
		if info and not info.isDisabled then
			widget:SetAttribute("type", "macro")
			widget:SetAttribute("typerelease", "macro")
			widget:SetAttribute("macrotext", info.macrotext)
		end
	elseif actionType == "mount" then
		local mountId = btn.MountId or actionValue
		if C_MountJournal and C_MountJournal.SummonByID and mountId then
			widget:SetAttribute("type", "macro")
			widget:SetAttribute("typerelease", "macro")
			widget:SetAttribute("macrotext", "/run C_MountJournal.SummonByID(" .. tostring(mountId) .. ")")
		else
			local castName = btn.MountSpellName or btn.MountName
			if castName then
				widget:SetAttribute("type", "macro")
				widget:SetAttribute("typerelease", "macro")
				widget:SetAttribute("macrotext", "/cast " .. castName)
			end
		end
	elseif actionType == "toy" then
		if CapHas("hasToyBox") then
			widget:SetAttribute("type", "toy")
			widget:SetAttribute("typerelease", "toy")
			widget:SetAttribute("toy", btn.ToyId or actionValue)
		end
	elseif actionType == "flyout" then
		local fid = btn.FlyoutId or FlyoutId(actionValue)
		widget:SetAttribute("type", "flyout")
		widget:SetAttribute("typerelease", "flyout")
		widget:SetAttribute("spell", fid)
		if widget:GetAttribute("flyoutDirection") == nil then
			widget:SetAttribute("flyoutDirection", "DOWN")
		end
		local dir = widget:GetAttribute("flyoutDirection") or "DOWN"
		if widget.SetPopupDirection then
			pcall(widget.SetPopupDirection, widget, dir)
		else
			widget.popupDirection = dir
		end
		if SpellFlyout and widget.SetPopup then
			pcall(widget.SetPopup, widget, SpellFlyout)
		elseif SpellFlyout then
			widget.popup = SpellFlyout
		end
		if widget.UpdateFlyout then
			pcall(widget.UpdateFlyout, widget)
		end
	elseif actionType == "battlepet" then
		widget:SetAttribute("type", "macro")
		widget:SetAttribute("typerelease", "macro")
		widget:SetAttribute("macrotext", "/summonpet " .. tostring(btn.BattlePetId or actionValue))
	elseif actionType == "pet" then
		local slot = tonumber(btn.PetSlot or actionValue)
		widget:SetAttribute("type", "pet")
		widget:SetAttribute("typerelease", "pet")
		widget:SetAttribute("action", slot)
	elseif actionType == "shapeshift" then
		local donor = btn.ShapeshiftDonor
		local sid = btn.SpellId
		if donor then
			widget:SetAttribute("type", "click")
			widget:SetAttribute("typerelease", "click")
			widget:SetAttribute("clickbutton", donor)
		elseif sid then
			local attr = SpellCastAttribute(sid)
			widget:SetAttribute("type", "spell")
			widget:SetAttribute("typerelease", "spell")
			widget:SetAttribute("spell", attr)
		end
	end
	local GClick = Flux.ButtonFX and Flux.ButtonFX.Click
	if not GClick or not GClick.UsesWrap or GClick.UsesWrap() then
		widget:SetAttribute("pressAndHoldAction", true)
	end
	if GClick and GClick.MirrorTypeRelease then
		GClick.MirrorTypeRelease(widget)
	end
	local MC = Flux.MouseoverCast
	if MC and MC.ApplyNativeCheck then
		MC.ApplyNativeCheck(widget)
	end
end

local function FillEnv(btn, actionType, actionValue)
	Action.ClearEnv(btn)
	if not actionType or actionValue == nil then
		return false
	end

	if actionType == "item" then
		local asItem = ItemID(actionValue)
		if asItem and CapHas("hasToyBox") and PlayerHasToy and PlayerHasToy(asItem) then
			actionType = "toy"
			actionValue = asItem
		end
	end

	if actionType == "spell" then
		local sid = SpellID(actionValue) or actionValue
		local api = ns.API
		local isOutfitSpell = api and api.GetPlayerTransmogOutfitIDForSpell
			and api.GetPlayerTransmogOutfitIDForSpell(sid) ~= nil
		-- Keep Blizzard's assistant action spell id; GetBaseSpell would break identity.
		-- Clear outfit is a synthetic spell face, not a rank to normalize.
		-- Stance custom slots keep the placed rank. GetBaseSpell would swap the icon.
		if type(sid) == "number" and not btn._fluxExactSpell and Flux.Spell and Flux.Spell.GetBaseSpell
			and not isOutfitSpell and not Action.IsAssistantSpell(sid) then
			sid = Flux.Spell.GetBaseSpell(sid) or sid
		end
		btn.ActionType = "spell"
		btn.ActionValue = sid
		btn.SpellId = SpellID(sid)
		NoteSpellName(btn, btn.SpellId)
		btn.needsRange = true
		if btn.SpellId and C_Spell and C_Spell.IsPressHoldReleaseSpell then
			local ok, v = pcall(C_Spell.IsPressHoldReleaseSpell, btn.SpellId)
			btn.IsEmpowerSpell = ok and v and true or nil
		end
		return true
	elseif actionType == "item" then
		local iid = ItemID(actionValue) or actionValue
		btn.ActionType = "item"
		btn.ActionValue = iid
		btn.ItemId = ItemID(iid)
		btn.needsRange = true
		return true
	elseif actionType == "macro" then
		local hintName, hintBody
		if type(actionValue) == "table" then
			hintName = actionValue.name or actionValue.macroName
			hintBody = actionValue.body or actionValue.macroBody
		end
		local idx = ResolveMacroIndex(actionValue)
		if idx then
			local name, _, body = MacroInfoAt(idx)
			btn.ActionType = "macro"
			btn.ActionValue = idx
			btn.MacroIndex = idx
			btn.MacroName = name or hintName
			btn.MacroBody = body or hintBody
			btn.ShowTooltip = HasShowTooltip(btn.MacroBody)
			btn.needsRange = true
			return true
		end
		-- Keep saved identity until UPDATE_MACROS can rebind (login / reorder).
		if hintName or hintBody then
			btn.ActionType = "macro"
			btn.ActionValue = hintName or hintBody
			btn.MacroIndex = nil
			btn.MacroName = hintName
			btn.MacroBody = hintBody
			btn.ShowTooltip = HasShowTooltip(hintBody)
			btn.needsRange = true
			return true
		end
		return false
	elseif actionType == "macrotext" then
		btn.ActionType = "macrotext"
		btn.ActionValue = actionValue
		btn.MacroBody = actionValue
		btn.ShowTooltip = HasShowTooltip(actionValue)
		btn.needsRange = true
		return true
	elseif actionType == "outfit" then
		local api = ns.API
		local id = tonumber(actionValue)
		if not id or id < 0 or id ~= math.floor(id) or not api
			or not api.HasPlayerTransmogOutfitAPI or not api.HasPlayerTransmogOutfitAPI() then return false end
		btn.ActionType, btn.ActionValue, btn.OutfitId = "outfit", id, id
		-- Preserve a saved ID while outfit data is still arriving at login.
		btn.OutfitInfo = api.GetPlayerTransmogOutfitAction and api.GetPlayerTransmogOutfitAction(id)
		btn.SpellId = btn.OutfitInfo and btn.OutfitInfo.spell
		btn.needsRange = false
		return true
	elseif actionType == "mount" then
		if not CapHas("hasC_MountJournal") then
			return false
		end
		local mountId = tonumber(actionValue) or actionValue
		if type(mountId) ~= "number" then
			return false
		end
		if mountId == 0 then
			mountId = RANDOM_MOUNT_ID
		end
		-- Keep the saved id even if the journal is still empty (login).
		local name, spellID = ReadMountInfo(mountId)
		ApplyMountEnv(btn, mountId, name, spellID)
		return true
	elseif actionType == "toy" then
		if not CapHas("hasToyBox") then
			return false
		end
		local toyId = ItemID(actionValue) or tonumber(actionValue)
		if not toyId then
			return false
		end
		btn.ActionType = "toy"
		btn.ActionValue = toyId
		btn.ToyId = toyId
		btn.ItemId = toyId
		btn.needsRange = true
		return true
	elseif actionType == "flyout" then
		local fid = FlyoutId(actionValue)
		if not fid then
			return false
		end
		btn.ActionType = "flyout"
		btn.ActionValue = fid
		btn.FlyoutId = fid
		return true
	elseif actionType == "battlepet" then
		if CapHas("hasC_PetJournal") then
			btn.ActionType = "battlepet"
			btn.ActionValue = actionValue
			btn.BattlePetId = actionValue
			if C_PetJournal and C_PetJournal.GetPetInfoByPetID then
				local ok, _, _, _, _, _, _, _, name = pcall(C_PetJournal.GetPetInfoByPetID, actionValue)
				if ok then
					btn.BattlePetName = name
				end
			end
			return true
		end
		-- Classic companions: critter index is not a journal GUID. Cast the summon spell.
		local spellID = CompanionSpellID("CRITTER", actionValue)
		if spellID then
			return FillEnv(btn, "spell", spellID)
		end
		return false
	elseif actionType == "pet" then
		local slot = tonumber(actionValue)
		if not slot or slot < 1 then
			return false
		end
		btn.ActionType = "pet"
		btn.ActionValue = slot
		btn.PetSlot = slot
		btn.needsRange = false
		return true
	elseif actionType == "shapeshift" then
		local index = tonumber(actionValue)
		if not index or index < 1 then
			return false
		end
		btn.ActionType = "shapeshift"
		btn.ActionValue = index
		btn.ShapeshiftIndex = index
		btn.needsRange = false
		local S = Flux.Shapeshift
		if S and S.GetFormInfo then
			local _, _, _, spellID = S.GetFormInfo(index)
			btn.SpellId = tonumber(spellID)
			if btn.SpellId then
				NoteSpellName(btn, btn.SpellId)
			end
		end
		return true
	end
	return false
end

local function AlwaysTranslateMacro(btn)
	-- Reverse badges must reparse on every hop. Unchanged skip hid them
	-- against a stale Identity face (hiddenSwap).
	return btn and (btn.badgeMode or btn.kind == "badge") and true or false
end

local function ShownMacroSpellId(index)
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
	if type(a) == "string" and a ~= "" then
		if Flux.Spell and Flux.Spell.GetID then
			return Flux.Spell.GetID(a) or a
		end
		return a
	end
	return nil
end

local function ShownMacroItemId(index)
	if not index or not GetMacroItem then
		return nil
	end
	local name, link = GetMacroItem(index)
	local iid = ItemID(link)
	if iid then
		return iid
	end
	if type(name) ~= "string" or name == "" then
		return nil
	end
	iid = ItemID(name)
	if iid then
		return iid
	end
	if C_Item and C_Item.GetItemInfoInstant then
		local ok, id = pcall(C_Item.GetItemInfoInstant, name)
		if ok then
			iid = tonumber(id)
		end
	end
	if not iid and GetItemInfoInstant then
		local ok, id = pcall(GetItemInfoInstant, name)
		if ok then
			iid = tonumber(id)
		end
	end
	return iid
end

local function StripSlashRemainder(action)
	if type(action) ~= "string" then
		return action
	end
	local rest = action:match("^%s*/%S+%s+(.*)$")
	if rest and rest ~= "" then
		return rest
	end
	return action
end

local function AcceptParsedRemainder(a)
	if type(a) == "number" then
		a = tostring(a)
	end
	if type(a) ~= "string" then
		return nil
	end
	a = TrimMacroBody(a)
	if a == "" or a == "?" then
		return nil
	end
	return a
end

local function FirstSequenceToken(chosen)
	if type(chosen) ~= "string" then
		return chosen
	end
	if not string.find(chosen, ",", 1, true) then
		return chosen
	end
	local cleaned = string.gsub(chosen, "^reset=[^%s]*%s*", "")
	local first = string.match(cleaned, "([^,]+)")
	return AcceptParsedRemainder(first) or chosen
end

--- Options tail after /cast /use /castsequence or a non-empty #showtooltip.
--- SecureCmdOptionParse on a full "/cast [mod] A; B" line (or bare #showtooltip)
--- returns "?" / empty — that paints INV_Misc_QuestionMark and never swaps.
local function CommandOptions(line)
	if type(line) ~= "string" then
		return nil, nil
	end
	local stt = string.match(line, "^%s*#%s*showtooltip%s*(.*)$")
	if stt then
		stt = TrimMacroBody(stt)
		if stt ~= "" then
			return stt, "showtooltip"
		end
		return nil, "showtooltip"
	end
	if string.match(line, "^%s*#") then
		return nil, "hash"
	end
	-- LAB ParseMacrotextForDisplay: /cast /use /spell tails, not the slash word.
	local cmd, rest = string.match(line, "^%s*(/%a+)%s*(.-)%s*$")
	if cmd then
		cmd = string.lower(cmd)
		if cmd == "/castsequence" then
			return rest, "castsequence"
		end
		if (cmd == "/cast" or cmd == "/use" or cmd == "/spell"
			or cmd == "/castrandom" or cmd == "/userandom")
			and rest and rest ~= "" then
			return rest, "cast"
		end
	end
	return nil, nil
end

local function ParseOptions(options)
	if type(options) ~= "string" or options == "" or not SecureCmdOptionParse then
		return nil, nil
	end
	local ok, a, t = pcall(SecureCmdOptionParse, options)
	if not ok then
		return nil, nil
	end
	a = AcceptParsedRemainder(a)
	if not a then
		return nil, nil
	end
	return a, t
end

local parseCacheFrame
local parseCacheSig
local parseCacheAction = {}
local parseCacheTarget = {}

--- Cheap live-condition key so a same-frame SHIFT/form/target flip cannot
--- reuse a remainder parsed before the condition actually changed.
local function ConditionSig()
	local n = 0
	if IsShiftKeyDown and IsShiftKeyDown() then
		n = n + 1
	end
	if IsControlKeyDown and IsControlKeyDown() then
		n = n + 2
	end
	if IsAltKeyDown and IsAltKeyDown() then
		n = n + 4
	end
	if IsStealthed and IsStealthed() then
		n = n + 8
	end
	if UnitAffectingCombat and UnitAffectingCombat("player") then
		n = n + 16
	end
	local form = (GetShapeshiftForm and GetShapeshiftForm()) or 0
	n = n + form * 32
	if UnitExists and UnitExists("target") then
		n = n + 2048
		if UnitCanAttack and UnitCanAttack("player", "target") then
			n = n + 4096
		end
		if UnitCanAssist and UnitCanAssist("player", "target") then
			n = n + 8192
		end
	end
	if UnitExists and UnitExists("mouseover") then
		n = n + 16384
	end
	if IsMounted and IsMounted() then
		n = n + 32768
	end
	if IsFlying and IsFlying() then
		n = n + 65536
	end
	if IsIndoors and IsIndoors() then
		n = n + 131072
	end
	return n
end

function Action.InvalidateMacroParseCache()
	parseCacheFrame = nil
	parseCacheSig = nil
end

--- Live remainder after SecureCmdOptionParse. Extra TranslateMacro (EvaluateMacroActiveCast):
--- parse #showtooltip args and /cast tails, never the slash command itself.
--- skipCache: reverse badges must not reuse a lagged remainder from this frame.
local function ParseMacroBody(body, skipCache)
	if type(body) ~= "string" or body == "" then
		return nil, nil
	end
	if not SecureCmdOptionParse then
		return nil, nil
	end
	-- Same body, same frame, same condition state. Strip overlay + ShouldShow
	-- used to parse the same text three times on SHIFT. Reverse badges skip
	-- so leave-condition cannot keep the in-condition remainder.
	if not skipCache then
		local now = GetTime and GetTime() or 0
		local sig = ConditionSig()
		if now ~= parseCacheFrame or sig ~= parseCacheSig then
			parseCacheFrame = now
			parseCacheSig = sig
			for k in pairs(parseCacheAction) do
				parseCacheAction[k] = nil
				parseCacheTarget[k] = nil
			end
		end
		local cached = parseCacheAction[body]
		if cached ~= nil then
			if cached == false then
				return nil, nil
			end
			return cached, parseCacheTarget[body]
		end
	end
	-- `#showtooltip Native` pins the face (multi-cast extras). Bare `#showtooltip`
	-- has no args — skip it or SecureCmdOptionParse returns "?" and the icon dies.
	local parsed, target
	for line in string.gmatch(body, "[^\r\n]+") do
		local options, kind = CommandOptions(line)
		if kind == "showtooltip" and options then
			local a, t = ParseOptions(options)
			if a then
				parsed, target = FirstSequenceToken(a), t
				break
			end
		end
	end
	if not parsed then
		for line in string.gmatch(body, "[^\r\n]+") do
			local options, kind = CommandOptions(line)
			if (kind == "cast" or kind == "castsequence") and options then
				local a, t = ParseOptions(options)
				if a then
					if kind == "castsequence" then
						a = FirstSequenceToken(a)
					end
					parsed, target = a, t
					break
				end
			end
		end
	end
	if not skipCache then
		parseCacheAction[body] = parsed or false
		parseCacheTarget[body] = target
	end
	return parsed, target
end

-- LAB ResolveDisplaySpellId: Retail names need GetSpellIDForSpellIdentifier.
-- GetSpellInfo's 7th return is gone on Midnight (table API).
local function ResolveDisplaySpellId(value)
	if type(value) == "number" then
		if value > 0 then
			return value
		end
		return nil
	end
	if type(value) ~= "string" or value == "" then
		return nil
	end
	if C_Spell and C_Spell.GetSpellIDForSpellIdentifier then
		local ok, id = pcall(C_Spell.GetSpellIDForSpellIdentifier, value)
		id = ok and tonumber(id) or nil
		if id and id > 0 then
			return id
		end
	end
	if Flux.Spell and Flux.Spell.GetInfo then
		local ok, _, _, _, _, _, _, sid = pcall(Flux.Spell.GetInfo, value)
		sid = ok and tonumber(sid) or nil
		if sid and sid > 0 then
			return sid
		end
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local ok, info = pcall(C_Spell.GetSpellInfo, value)
		if ok and type(info) == "table" then
			local id = tonumber(info.spellID)
			if id and id > 0 then
				return id
			end
		end
	end
	if GetSpellInfo then
		local ok, a, _, _, _, _, _, g = pcall(GetSpellInfo, value)
		if ok then
			if type(a) == "table" then
				local id = tonumber(a.spellID)
				if id and id > 0 then
					return id
				end
			end
			local id = tonumber(g)
			if id and id > 0 then
				return id
			end
		end
	end
	return nil
end

local function ResolveShownFromRemainder(parsed)
	parsed = StripSlashRemainder(parsed)
	if type(parsed) == "number" then
		parsed = tostring(parsed)
	end
	if type(parsed) == "string" then
		parsed = string.gsub(parsed, "^%s*!", "")
		parsed = string.gsub(parsed, "@[%w_]+", "")
		parsed = TrimMacroBody(parsed)
	end
	if type(parsed) ~= "string" or parsed == "" or parsed == "?" then
		return nil
	end
	-- LAB ResolveMacroDisplayValue: item:ID, inventory 1-19, spell name, then item.
	local itemId = string.match(parsed, "^item:(%d+)")
	if itemId then
		return "item", tonumber(itemId)
	end
	local slotNum = tonumber(parsed)
	if slotNum and slotNum >= 1 and slotNum <= 19 and slotNum == math.floor(slotNum) then
		if GetInventoryItemID then
			local ok, invItem = pcall(GetInventoryItemID, "player", slotNum)
			if ok and invItem then
				return "item", tonumber(invItem) or invItem
			end
		end
		return nil
	end
	local sid = ResolveDisplaySpellId(parsed)
	if sid then
		return "spell", sid
	end
	if C_Item and C_Item.GetItemInfoInstant then
		local ok, id = pcall(C_Item.GetItemInfoInstant, parsed)
		id = ok and tonumber(id) or nil
		if id then
			return "item", id
		end
	end
	if GetItemInfoInstant then
		local ok, id = pcall(GetItemInfoInstant, parsed)
		id = ok and tonumber(id) or nil
		if id then
			return "item", id
		end
	end
	-- Name with no id yet: Extra Paint still GetSpellTexture(name) like LAB remainder.
	return "spell", parsed
end

--- Currently shown spell/item for a compiled macro body (same rules as Extra TranslateMacro).
function Action.ShownFromBody(body)
	local parsed = ParseMacroBody(body)
	if not parsed then
		return nil
	end
	return ResolveShownFromRemainder(parsed)
end

local function ApplyParsedRemainder(btn, action)
	btn.SpellId = nil
	btn.ItemId = nil
	btn.MacroMode = ""
	if type(action) ~= "string" or action == "" or action == "?" then
		return
	end
	local kind, id = ResolveShownFromRemainder(action)
	if kind == "item" then
		btn.MacroMode = "item"
		btn.ItemId = id
		return
	end
	if kind == "spell" then
		btn.MacroMode = "spell"
		btn.SpellId = id
		NoteSpellName(btn, id, type(action) == "string" and action or nil)
	end
end

local function UnitNameSafe(unit)
	if not unit or not UnitName then
		return nil
	end
	local ok, name = pcall(UnitName, unit)
	if not ok or name == nil then
		return nil
	end
	local S = Flux and Flux.Secrets
	if S and S.SafeAccessibleString then
		return S.SafeAccessibleString(name)
	end
	return name
end

local function UnitDeadSafe(unit)
	if not unit or not UnitIsDead then
		return false
	end
	local ok, dead = pcall(UnitIsDead, unit)
	if not ok then
		return false
	end
	local S = Flux and Flux.Secrets
	if S and S.SafeBooleanTest then
		return S.SafeBooleanTest(dead, false) and true or false
	end
	return dead and true or false
end

local function CacheValuesEqual(a, b)
	local S = Flux and Flux.Secrets
	if S and S.SafeEqualForCache then
		return S.SafeEqualForCache(a, b) == true
	end
	local ok, same = pcall(function()
		return a == b
	end)
	return ok and same or false
end

local function PaintMacroButton(btn)
	if not btn or not EBS.Paint then
		return
	end
	if EBS.Paint.UpdateIcon then
		EBS.Paint.UpdateIcon(btn)
	end
	if EBS.Paint.UpdateCount then
		EBS.Paint.UpdateCount(btn)
	end
	if EBS.Paint.UpdateCooldown then
		EBS.Paint.UpdateCooldown(btn)
	end
	if EBS.Paint.UpdateEquipped then
		EBS.Paint.UpdateEquipped(btn)
	end
	if EBS.Paint.UpdateRange then
		EBS.Paint.UpdateRange(btn)
	end
	if EBS.Paint.UpdateUsable then
		EBS.Paint.UpdateUsable(btn)
	end
	if EBS.Paint.UpdateChecked then
		EBS.Paint.UpdateChecked(btn)
	end
	if EBS.Paint.UpdateGlow then
		EBS.Paint.UpdateGlow(btn)
	end
	if btn.tooltipHovering and Action.UpdateTooltip then
		Action.UpdateTooltip(btn)
	end
end

function Action.TranslateMacro(btn)
	if not btn or (btn.ActionType ~= "macro" and btn.ActionType ~= "macrotext") then
		return
	end
	local swapKey
	if btn._fluxCombatSwapBody then
		swapKey = tostring(btn.MacroMode) .. "\0" .. tostring(btn.ItemId) .. "\0" .. tostring(btn.SpellId)
	end
	local body = btn.MacroBody
	local texture
	local hasIndex = btn.ActionType == "macro" and btn.MacroIndex
	if hasIndex then
		local name, icon, liveBody = MacroInfoAt(btn.MacroIndex)
		if name then
			btn.MacroName = name
			btn.MacroBody = liveBody or body
			body = btn.MacroBody
			texture = icon
		end
	end
	btn.ShowTooltip = HasShowTooltip(body)

	local always = AlwaysTranslateMacro(btn)
	local parsed, target = ParseMacroBody(body, always)
	target = target or "target"
	local tName = UnitNameSafe(target)
	local tDead = UnitDeadSafe(target)
	local shownSpell, shownItem
	if hasIndex then
		shownSpell = ShownMacroSpellId(btn.MacroIndex)
		if not shownSpell then
			shownItem = ShownMacroItemId(btn.MacroIndex)
		end
	end
	local faceUnchanged = texture == btn.MacroTexture
		and parsed == btn.MacroAction
		and shownSpell == btn.MacroShownSpell
		and shownItem == btn.MacroShownItem
	local unchanged = faceUnchanged
		and CacheValuesEqual(tName, btn.MacroTargetName)
		and tDead == btn.MacroTargetDead
		and target == btn.MacroTarget
	if unchanged and not always then
		if btn._fluxManagedFaceSpellId then
			btn.MacroMode = "spell"
			btn.SpellId = btn._fluxManagedFaceSpellId
			btn.ItemId = nil
		end
		return
	end
	btn.MacroTexture = texture
	btn.MacroAction = parsed
	btn.MacroTarget = target
	btn.MacroTargetName = tName
	btn.MacroTargetDead = tDead
	btn.MacroShownSpell = shownSpell
	btn.MacroShownItem = shownItem

	if hasIndex then
		local sid = shownSpell
		if sid then
			btn.MacroMode = "spell"
			btn.SpellId = type(sid) == "number" and sid or SpellID(sid) or sid
			NoteSpellName(btn, btn.SpellId)
			btn.ItemId = nil
		else
			local iid = shownItem
			if iid then
				btn.MacroMode = "item"
				btn.ItemId = iid
				btn.SpellId = nil
			else
				btn.MacroMode = ""
				btn.SpellId = nil
				btn.ItemId = nil
			end
		end
	else
		ApplyParsedRemainder(btn, parsed)
		if not btn.MacroTexture then
			if btn.MacroMode == "spell" and btn.SpellId and Flux.Spell then
				if Flux.Spell.GetTexture then
					btn.MacroTexture = Flux.Spell.GetTexture(btn.SpellId)
				elseif Flux.Spell.GetIcon then
					btn.MacroTexture = Flux.Spell.GetIcon(btn.SpellId)
				end
			elseif btn.MacroMode == "item" and btn.ItemId and Flux.Item and Flux.Item.GetIcon then
				btn.MacroTexture = Flux.Item.GetIcon(btn.ItemId)
			end
		end
	end

	-- NC class teleport owns the Extra face (teleport vs portal). Macro parse
	-- of "Portal: City" can keep the previous teleport id; restore the pin.
	if btn._fluxManagedFaceSpellId then
		btn.MacroMode = "spell"
		btn.SpellId = btn._fluxManagedFaceSpellId
		btn.ItemId = nil
		if btn.IconOverrideTexture then
			btn.MacroTexture = btn.IconOverrideTexture
		end
	end

	-- Strip occupancy / overlay env: identity only. Extra Paint/Range need a real Extra widget.
	if btn._fluxStripFace or btn.kind == "strip" then
		return
	end
	-- Same shown spell/item: hopping units is range/tooltip, not Extra paint.
	-- Reverse badges still paint so an empty remainder can restore the default.
	if faceUnchanged and not always then
		return
	end

	local wantRange = (btn.MacroMode == "spell" or btn.MacroMode == "item") and true or false
	local rangeChanged = btn.needsRange ~= wantRange
	btn.needsRange = wantRange
	if EBS.Range and EBS.Range.RefreshButton then
		EBS.Range.RefreshButton(btn)
	end
	-- Sync walks every button, so only when this one joined or left range duty.
	if rangeChanged and EBS.Range and EBS.Range.Sync then
		EBS.Range.Sync()
	end
	PaintMacroButton(btn)
	if swapKey then
		local now = tostring(btn.MacroMode) .. "\0" .. tostring(btn.ItemId) .. "\0" .. tostring(btn.SpellId)
		return now ~= swapKey
	end
end

--- One translate path for Extra, strip overlay, and corner badges.
Action.TranslateFace = Action.TranslateMacro

function Action.TranslateMatching(kinds)
	local PF = Flux.Bars and Flux.Bars.ProgramFace
	if PF and PF.EachExtraMatching then
		PF.EachExtraMatching(kinds, Action.TranslateMacro)
		return
	end
	local list = EBS.buttons
	if not list then
		return
	end
	if not (PF and PF.ClassifyBody and PF.KindWanted) then
		Action.RefreshMacroDisplay()
		return
	end
	for i = 1, #list do
		local btn = list[i]
		if btn and (btn.ActionType == "macro" or btn.ActionType == "macrotext") then
			local need = PF.ClassifyBody(btn.MacroBody)
			if PF.KindWanted(need, kinds) then
				Action.TranslateMacro(btn)
			end
		end
	end
end

function Action.RefreshMacroDisplay()
	local list = EBS.buttons
	if list then
		for i = 1, #list do
			local btn = list[i]
			if btn and (btn.ActionType == "macro" or btn.ActionType == "macrotext") then
				Action.TranslateMacro(btn)
			end
		end
	end
	-- Badges live on their own Extra list. SecureCmdOptionParse lag after a
	-- key-up must retranlate reverse faces, not only window macros.
	local BH = Flux.Bars and Flux.Bars.BadgeHost
	if BH and BH.RefreshDisplays then
		BH.RefreshDisplays()
	end
	if BH and BH.SyncShownFaces then
		BH.SyncShownFaces()
	end
end

-- ButtonForge never TranslateMacro inside the event handler: it sets RefConditional
-- and runs on the following OnUpdate, after GetMacroInfo/GetMacroSpell catch up.
-- A second tick covers APIs that lag an extra frame.
local DISPLAY_KEY = "ebs.macro.display"
local DISPLAY_PROBE_INTERVAL = 0.15
local displayArmed = false
local displayDirty = 0
local displayProbeAccum = 0
local needFlying, needMounted, needFlyable, needSwimming, needIndoors
local lastFlying, lastMounted, lastFlyable, lastSwimming, lastIndoors

local function BodyNeeds(body, token)
	if type(body) ~= "string" then
		return false
	end
	return string.find(string.upper(body), token, 1, true) ~= nil
end

local function ScanProbeNeed()
	needFlying, needMounted, needFlyable, needSwimming, needIndoors = false, false, false, false, false
	local list = EBS.buttons
	local function Consider(body)
		if BodyNeeds(body, "FLYING") then
			needFlying = true
		end
		if BodyNeeds(body, "MOUNTED") then
			needMounted = true
		end
		if BodyNeeds(body, "FLYABLE") then
			needFlyable = true
		end
		if BodyNeeds(body, "SWIMMING") then
			needSwimming = true
		end
		if BodyNeeds(body, "INDOORS") or BodyNeeds(body, "OUTDOORS") then
			needIndoors = true
		end
	end
	if list then
		for i = 1, #list do
			local btn = list[i]
			if btn and (btn.ActionType == "macro" or btn.ActionType == "macrotext") then
				Consider(btn.MacroBody)
			end
		end
	end
	local PF = Flux.Bars and Flux.Bars.ProgramFace
	if PF and PF.EachBody then
		PF.EachBody(Consider)
	end
end

local function PullProbeFlags()
	local PF = Flux.Bars and Flux.Bars.ProgramFace
	if PF and PF.ProbeFlags then
		local f = PF.ProbeFlags()
		needFlying = f.flying and true or false
		needMounted = f.mounted and true or false
		needFlyable = f.flyable and true or false
		needSwimming = f.swimming and true or false
		needIndoors = f.indoors and true or false
		return
	end
	ScanProbeNeed()
end

local function NeedDisplayTicker()
	-- Event-driven for flyable/indoors. Keep a probe only while a state that
	-- can still change is active (mounted/flying/swimming) or a display flush is queued.
	return displayDirty > 0
		or lastFlying
		or lastMounted
		or lastSwimming
end

local function OnMacroDisplayTick(elapsed)
	-- Combat probes are not every frame: IsFlying/IsMounted/IsFlyableArea
	-- are throttled. Mouseover polling lives on ProgramFace, not this ticker.
	displayProbeAccum = displayProbeAccum + (elapsed or 0)
	local probe = displayProbeAccum >= DISPLAY_PROBE_INTERVAL
	if probe then
		displayProbeAccum = 0
	end
	if probe and needFlying then
		local v = IsFlying and IsFlying() or false
		if v ~= lastFlying then
			lastFlying = v
			displayDirty = math.max(displayDirty, 1)
			local PF = Flux.Bars and Flux.Bars.ProgramFace
			if PF and PF.Request then
				PF.Request("combat")
			end
		end
	end
	if probe and needMounted then
		local v = IsMounted and IsMounted() or false
		if v ~= lastMounted then
			lastMounted = v
			displayDirty = math.max(displayDirty, 1)
			local PF = Flux.Bars and Flux.Bars.ProgramFace
			if PF and PF.Request then
				PF.Request("combat")
			end
		end
	end
	if probe and needSwimming then
		local v = IsSwimming and IsSwimming() or false
		if v ~= lastSwimming then
			lastSwimming = v
			displayDirty = math.max(displayDirty, 1)
			local PF = Flux.Bars and Flux.Bars.ProgramFace
			if PF and PF.Request then
				PF.Request("combat")
			end
		end
	end
	if probe and needIndoors then
		local v = IsIndoors and IsIndoors() or false
		if v ~= lastIndoors then
			lastIndoors = v
			displayDirty = math.max(displayDirty, 1)
			local PF = Flux.Bars and Flux.Bars.ProgramFace
			if PF and PF.Request then
				PF.Request("combat")
			end
		end
	end
	if displayDirty > 0 then
		Action.RefreshMacroDisplay()
		displayDirty = displayDirty - 1
	end
	if probe and needFlyable then
		local v = IsFlyableArea and IsFlyableArea() or false
		if v ~= lastFlyable then
			lastFlyable = v
			displayDirty = math.max(displayDirty, 1)
			local PF = Flux.Bars and Flux.Bars.ProgramFace
			if PF and PF.Request then
				PF.Request("combat")
			end
		end
	end
	if not NeedDisplayTicker() then
		displayArmed = false
		displayProbeAccum = 0
		if Flux.Ticker and Flux.Ticker.Remove then
			Flux.Ticker.Remove(DISPLAY_KEY)
		end
	end
end

function Action.SyncMacroProbes()
	PullProbeFlags()
	if lastFlying == nil then
		lastFlying = (needFlying and IsFlying and IsFlying()) or false
	end
	if lastMounted == nil then
		lastMounted = (needMounted and IsMounted and IsMounted()) or false
	end
	if lastSwimming == nil then
		lastSwimming = (needSwimming and IsSwimming and IsSwimming()) or false
	end
	if lastFlyable == nil then
		lastFlyable = (needFlyable and IsFlyableArea and IsFlyableArea()) or false
	end
	if lastIndoors == nil then
		lastIndoors = (needIndoors and IsIndoors and IsIndoors()) or false
	end
	local PF = Flux.Bars and Flux.Bars.ProgramFace
	if PF and PF.ArmMouseoverPoll then
		PF.ArmMouseoverPoll()
	end
	local need = NeedDisplayTicker()
	if need and not displayArmed then
		displayArmed = true
		if Flux.Ticker and Flux.Ticker.Add then
			Flux.Ticker.Add(DISPLAY_KEY, OnMacroDisplayTick)
		end
	elseif (not need) and displayArmed then
		displayArmed = false
		if Flux.Ticker and Flux.Ticker.Remove then
			Flux.Ticker.Remove(DISPLAY_KEY)
		end
	end
end

function Action.RequestMacroDisplay()
	displayDirty = math.max(displayDirty, 2)
	Action.SyncMacroProbes()
end

local macroUpdateCount = 0
local macrosLoaded = false
local macroPruneReady = false
local lastMacroTotal = nil
local delayedBind = false

local function FindReboundIndex(btn, deleted)
	local storedName = btn.MacroName
	local storedBody = TrimMacroBody(btn.MacroBody)
	local index = btn.MacroIndex
	local accMax, _, numAcc, numChar = MacroBands()

	local function matchAt(i)
		local n, _, b = MacroInfoAt(i)
		if not n then
			return false
		end
		return n == storedName and TrimMacroBody(b) == storedBody
	end

	if index and matchAt(index) then
		return index
	end

	local function inAccount(i)
		return i >= 1 and i <= numAcc
	end
	local function inChar(i)
		return i >= accMax + 1 and i <= accMax + numChar
	end
	if index then
		if inAccount(index) or (numChar > 0 and inChar(index)) then
			if matchAt(index - 1) then
				return index - 1
			end
			if matchAt(index + 1) then
				return index + 1
			end
		end
	end

	local found = ScanMacros(function(_, n, b)
		return storedName and n == storedName and TrimMacroBody(b) == storedBody
	end)
	if found then
		return found
	end
	if not deleted then
		if storedBody ~= "" then
			found = ScanMacros(function(_, _, b)
				return TrimMacroBody(b) == storedBody
			end)
			if found then
				return found
			end
		end
		if index and MacroInfoAt(index) then
			local n = MacroInfoAt(index)
			if storedName and n == storedName then
				return index
			end
		end
		if storedName and GetMacroIndexByName then
			local idx = GetMacroIndexByName(storedName)
			if idx and idx > 0 then
				return idx
			end
		end
	end
	return nil
end

function Action.RefreshMacroBindings()
	if InLockdown() then
		if not delayedBind then
			delayedBind = true
			Defer("ebs.macros.bind", function()
				delayedBind = false
				Action.RefreshMacroBindings()
			end)
		end
		return
	end
	if not macrosLoaded then
		return
	end
	local _, _, numAcc, numChar = MacroBands()
	local total = numAcc + numChar
	local deleted = lastMacroTotal ~= nil and total < lastMacroTotal
	lastMacroTotal = total

	local list = EBS.buttons
	if not list then
		return
	end
	local rebound = false
	for i = 1, #list do
		local btn = list[i]
		if btn and btn.ActionType == "macro" then
			local idx = FindReboundIndex(btn, deleted)
			if idx then
				local oldIndex = btn.MacroIndex
				local oldName = btn.MacroName
				local oldBody = btn.MacroBody
				if idx ~= btn.MacroIndex then
					btn.MacroIndex = idx
					btn.ActionValue = idx
					rebound = true
				end
				local name, _, body = MacroInfoAt(idx)
				btn.MacroName = name or btn.MacroName
				btn.MacroBody = body or btn.MacroBody
				btn.ShowTooltip = HasShowTooltip(btn.MacroBody)
				if idx ~= oldIndex then
					WriteAttributes(btn)
				end
				if btn.OnMacroRebound and (idx ~= oldIndex or btn.MacroName ~= oldName or btn.MacroBody ~= oldBody) then
					Flux.Safecall(btn.OnMacroRebound, btn.MacroIndex, btn.MacroName, btn.MacroBody)
				end
			elseif macroPruneReady then
				Action.Clear(btn)
				if btn.OnDelete then
					Flux.Safecall(btn.OnDelete)
				end
			end
		end
	end
	if rebound and EBS.Range and EBS.Range.Sync then
		EBS.Range.Sync()
	end
	Action.RefreshMacroDisplay()
	Action.RequestMacroDisplay()
end

function Action.OnMacrosUpdated()
	macroUpdateCount = macroUpdateCount + 1
	if macroUpdateCount < 2 then
		return
	end
	macrosLoaded = true
	Action.RefreshMacroBindings()
end

function Action.EnableMacroPrune()
	macroPruneReady = true
	if macrosLoaded then
		Action.RefreshMacroBindings()
	end
end

function Action.ForceMacrosLoaded()
	if macrosLoaded then
		return
	end
	local _, _, numAcc, numChar = MacroBands()
	if macroUpdateCount < 2 and (numAcc + numChar) == 0 then
		return
	end
	macrosLoaded = true
	if macroUpdateCount < 2 then
		macroUpdateCount = 2
	end
	Action.RefreshMacroBindings()
end

local KNOWN = {
	outfit = true,
	spell = true,
	item = true,
	macro = true,
	macrotext = true,
	mount = true,
	toy = true,
	flyout = true,
	battlepet = true,
	pet = true,
	shapeshift = true,
}

function Action.RefreshOutfits()
	local list = EBS.buttons or {}
	for i = 1, #list do
		local btn = list[i]
		if btn and btn.ActionType == "outfit" then
			local function refresh()
				if btn.ActionType == "outfit" then Action.SetAction(btn, "outfit", btn.ActionValue) end
			end
			if InLockdown() then
				Defer("ebs.outfit." .. tostring(btn), refresh)
			else
				refresh()
			end
		end
	end
end

function Action.SetAction(btn, actionType, actionValue)
	if not btn or not btn.Widget then
		return
	end
	if actionType == nil or actionValue == nil then
		Action.Clear(btn)
		return
	end
	if not KNOWN[actionType] then
		return
	end
	-- Extra Paint keeps empty-slot gray while PlaceholderTexture is set.
	-- Food/water clear this before bind; hearth/teleport must too or the
	-- rune stays desaturated after the item returns to bags.
	if btn.PlaceholderTexture or btn.PlaceholderLabel then
		btn.PlaceholderTexture = nil
		btn.PlaceholderLabel = nil
		btn.PlaceholderHideCount = nil
		if EBS.Paint and EBS.Paint.ClearCache then
			EBS.Paint.ClearCache(btn)
		end
		if btn.WIcon then
			if btn.WIcon.SetDesaturated then
				btn.WIcon:SetDesaturated(false)
			end
			btn.WIcon:SetVertexColor(1, 1, 1, 1)
		end
	end
	if not FillEnv(btn, actionType, actionValue) then
		Action.Clear(btn)
		return
	end
	WriteAttributes(btn)
	Action.SyncAssistant(btn)
	if EBS.Style and EBS.Style.Apply then
		EBS.Style.Apply(btn, btn.categoryScope)
	end
	if btn.ActionType == "macro" or btn.ActionType == "macrotext" then
		Action.TranslateMacro(btn)
		Action.RequestMacroDisplay()
		local PF = Flux.Bars and Flux.Bars.ProgramFace
		if PF and PF.InvalidateIndex then
			PF.InvalidateIndex()
		end
	else
		if EBS.Range and EBS.Range.RefreshButton then
			EBS.Range.RefreshButton(btn)
		end
		if EBS.Paint and EBS.Paint.Update then
			EBS.Paint.Update(btn)
		end
	end
	if EBS.Range and EBS.Range.Sync then
		EBS.Range.Sync()
	end
	-- Extra buttons have no state header to resolve a slot, so the mouseover
	-- cast classification is stamped on the widget from the live spell/item.
	local MC = Flux.MouseoverCast
	if MC and not btn.badgeMode then
		if btn.ActionType == "spell" and MC.SetButtonSpell then
			MC.SetButtonSpell(btn.Widget, Action.MouseoverCastSpell(btn))
		elseif (btn.ActionType == "item" or btn.ActionType == "toy") and MC.SetButtonItem then
			MC.SetButtonItem(btn.Widget, tonumber(btn.ItemId or btn.ToyId or btn.ActionValue))
		elseif MC.SetButtonSpell then
			MC.SetButtonSpell(btn.Widget, nil)
		end
	end
end

--- Spell the mouseover-cast engine should classify this button by. Macros are
--- excluded: their body already decides its own target.
function Action.MouseoverCastSpell(btn)
	if not btn then
		return nil
	end
	local t = btn.ActionType
	if t ~= "spell" then
		return nil
	end
	return tonumber(btn.SpellId)
end

function Action.RefreshMounts()
	local list = EBS.buttons
	if not list then
		return
	end
	for i = 1, #list do
		local btn = list[i]
		if btn and btn.ActionType == "mount" and btn.MountId then
			local name, spellID = ReadMountInfo(btn.MountId)
			local needAttr = false
			if name and name ~= btn.MountName then
				btn.MountName = name
				needAttr = true
			end
			if spellID and spellID ~= btn.MountSpellId then
				btn.MountSpellId = spellID
				if Flux.Spell and Flux.Spell.GetName then
					btn.MountSpellName = Flux.Spell.GetName(spellID) or name
				else
					btn.MountSpellName = name
				end
				needAttr = true
			elseif name and not btn.MountSpellName then
				btn.MountSpellName = name
				needAttr = true
			end
			if needAttr then
				WriteAttributes(btn)
			end
		end
	end
end

function Action.Clear(btn)
	if not btn or not btn.Widget then
		return
	end
	if btn.tooltipHovering then
		Action.OnLeave(btn)
	end
	Action.ClearEnv(btn)
	WriteAttributes(btn)
	if EBS.Style and EBS.Style.Apply then
		EBS.Style.Apply(btn, btn.categoryScope)
	end
	if EBS.Paint and EBS.Paint.Update then
		EBS.Paint.Update(btn)
	end
	if EBS.Range and EBS.Range.Sync then
		EBS.Range.Sync()
	end
	Action.SyncMacroProbes()
end

local function PickupSpell(spellId)
	if not spellId then
		return
	end
	if C_Spell and C_Spell.PickupSpell then
		pcall(C_Spell.PickupSpell, spellId)
		return
	end
	if _G.PickupSpell then
		pcall(_G.PickupSpell, spellId)
	end
end

local function PickupItem(itemId)
	if not itemId then
		return
	end
	if C_Item and C_Item.PickupItem then
		pcall(C_Item.PickupItem, itemId)
		return
	end
	if _G.PickupItem then
		pcall(_G.PickupItem, itemId)
	end
end

local function CursorHasPickup()
	return GetCursorInfo and GetCursorInfo() ~= nil
end

local function LookupFlyoutIndex(flyoutID)
	if not flyoutID then
		return nil, nil
	end
	local SB = C_SpellBook
	if SB and SB.GetNumSpellBookSkillLines and SB.GetSpellBookSkillLineInfo and SB.GetSpellBookItemInfo then
		local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
		local flyoutType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout
		local okLines, n = pcall(SB.GetNumSpellBookSkillLines)
		if okLines and type(n) == "number" then
			for i = 1, n do
				local okLine, line = pcall(SB.GetSpellBookSkillLineInfo, i)
				if okLine and line then
					for j = 1, (line.numSpellBookItems or 0) do
						local slotIndex = (line.itemIndexOffset or 0) + j
						local okInfo, info = pcall(SB.GetSpellBookItemInfo, slotIndex, bank)
						if okInfo and info then
							local isFlyout = (flyoutType and info.itemType == flyoutType)
								or info.actionID == flyoutID
							if isFlyout and (info.actionID == flyoutID or info.itemID == flyoutID) then
								return slotIndex, bank
							end
						end
					end
				end
			end
		end
	end
	if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo then
		local book = BOOKTYPE_SPELL or "spell"
		local okTabs, tabs = pcall(GetNumSpellTabs)
		if okTabs and type(tabs) == "number" then
			for tab = 1, tabs do
				local okTab, _, _, offset, numSlots = pcall(GetSpellTabInfo, tab)
				if okTab then
					for i = (offset or 0) + 1, (offset or 0) + (numSlots or 0) do
						local okInfo, skillType, id = pcall(GetSpellBookItemInfo, i, book)
						if okInfo and skillType == "FLYOUT" and id == flyoutID then
							return i, book
						end
					end
				end
			end
		end
	end
	return nil, nil
end

local function PickupFlyout(flyoutID)
	local index, bank = LookupFlyoutIndex(flyoutID)
	if not index then
		return
	end
	if C_SpellBook and C_SpellBook.PickupSpellBookItem then
		pcall(C_SpellBook.PickupSpellBookItem, index, bank)
		if CursorHasPickup() then
			return
		end
	end
	if PickupSpellBookItem then
		pcall(PickupSpellBookItem, index, bank)
	end
end

local function GetMountIndexFromMountID(mountID)
	if not C_MountJournal or mountID == nil then
		return nil
	end
	if mountID == RANDOM_MOUNT_ID or mountID == 0 then
		return 0
	end
	local num = 0
	if C_MountJournal.GetNumDisplayedMounts then
		num = C_MountJournal.GetNumDisplayedMounts() or 0
	elseif C_MountJournal.GetNumMounts then
		num = C_MountJournal.GetNumMounts() or 0
	end
	for i = 1, num do
		local displayedId
		if C_MountJournal.GetDisplayedMountID then
			displayedId = C_MountJournal.GetDisplayedMountID(i)
		end
		if not displayedId and C_MountJournal.GetDisplayedMountInfo then
			displayedId = select(12, C_MountJournal.GetDisplayedMountInfo(i))
		end
		if displayedId == mountID then
			return i
		end
	end
	return nil
end

local function PickupMount(mountID)
	if not C_MountJournal or mountID == nil then
		return
	end
	local index = GetMountIndexFromMountID(mountID)
	if index ~= nil and C_MountJournal.Pickup then
		pcall(C_MountJournal.Pickup, index)
		if CursorHasPickup() then
			return
		end
	end
	if C_MountJournal.PickupByID then
		pcall(C_MountJournal.PickupByID, mountID)
	end
end

local function ResolveCursorMountId(cursorData)
	local n = tonumber(cursorData) or cursorData
	if n == 0 or n == RANDOM_MOUNT_ID then
		return RANDOM_MOUNT_ID
	end
	if C_MountJournal and C_MountJournal.GetMountInfoByID then
		local name, spellID = C_MountJournal.GetMountInfoByID(n)
		if name or spellID then
			return n
		end
	end
	if C_MountJournal then
		if C_MountJournal.GetDisplayedMountID then
			local id = C_MountJournal.GetDisplayedMountID(n)
			if id then
				return id
			end
		end
		if C_MountJournal.GetDisplayedMountInfo then
			local id = select(12, C_MountJournal.GetDisplayedMountInfo(n))
			if id then
				return id
			end
		end
	end
	return n
end

function Action.Pickup(btn)
	if not btn or InLockdown() then
		return false
	end
	local t = btn.ActionType
	local api = ns.API
	local outfitID = t == "outfit" and (btn.OutfitId or btn.ActionValue) or nil
	if t == "spell" and api and api.GetPlayerTransmogOutfitIDForSpell then
		outfitID = api.GetPlayerTransmogOutfitIDForSpell(btn.SpellId or btn.ActionValue)
	end
	if t == "outfit" or outfitID ~= nil then
		return ns.API and ns.API.TryPickupPlayerTransmogOutfit
			and ns.API.TryPickupPlayerTransmogOutfit(outfitID) or false
	elseif t == "spell" then
		PickupSpell(btn.SpellId or btn.ActionValue)
	elseif t == "item" then
		PickupItem(btn.ItemId or btn.ActionValue)
	elseif t == "macro" then
		if PickupMacro and btn.MacroIndex then
			pcall(PickupMacro, btn.MacroIndex)
		end
	elseif t == "mount" then
		PickupMount(btn.MountId or btn.ActionValue)
	elseif t == "toy" then
		if C_ToyBox and C_ToyBox.PickupToyBoxItem and btn.ToyId then
			pcall(C_ToyBox.PickupToyBoxItem, btn.ToyId)
		else
			PickupItem(btn.ToyId)
		end
	elseif t == "flyout" then
		PickupFlyout(btn.FlyoutId or btn.ActionValue)
	elseif t == "battlepet" then
		if C_PetJournal and C_PetJournal.PickupPet and btn.BattlePetId then
			pcall(C_PetJournal.PickupPet, btn.BattlePetId)
		end
	elseif t == "pet" and PickupPetAction then
		pcall(PickupPetAction, btn.PetSlot or btn.ActionValue)
	end
	return CursorHasPickup()
end

local lastPopupId
local lastPopupKind
local lastPopupAt

local function ClearFlyoutPopupStash()
	lastPopupId = nil
	lastPopupKind = nil
	lastPopupAt = nil
end

local function PeekFlyoutPopupStash()
	if not lastPopupId then
		return nil
	end
	local now = (GetTime and GetTime()) or 0
	if lastPopupAt and (now - lastPopupAt) > 60 then
		ClearFlyoutPopupStash()
		return nil
	end
	return lastPopupId, lastPopupKind
end

function Action.NoteFlyoutPopupSpell(spellId)
	spellId = SpellID(spellId)
	if spellId and spellId > 0 then
		lastPopupId = spellId
		lastPopupKind = "spell"
		lastPopupAt = (GetTime and GetTime()) or 0
	end
end

function Action.NoteFlyoutPopupItem(itemId)
	itemId = ItemID(itemId) or tonumber(itemId)
	if itemId and itemId > 0 then
		lastPopupId = itemId
		lastPopupKind = "item"
		lastPopupAt = (GetTime and GetTime()) or 0
	end
end

local function PositiveSpell(value)
	value = tonumber(value)
	if value and value > 0 then
		return value
	end
	return nil
end

local function ResolveFlyoutPopupSpell(btn)
	if not btn then
		return nil
	end
	local ov = PositiveSpell(btn.overrideSpellID)
	if ov then
		return ov
	end
	local base = PositiveSpell(btn.spellID)
	local name = btn.spellName
	local S = Flux.Spell
	if S and S.FindFlyoutSlotCastID then
		local fromFlyout = S.FindFlyoutSlotCastID(base, name)
		if fromFlyout then
			return fromFlyout
		end
	end
	local parent = btn.GetParent and btn:GetParent()
	local flyoutId = (parent and (parent.flyoutID or parent.flyoutId))
		or (_G.SpellFlyout and (_G.SpellFlyout.flyoutID or _G.SpellFlyout.flyoutId))
	if S and S.GetFlyoutInfo and S.FlyoutSlotCastID and flyoutId then
		local _, _, numSlots = S.GetFlyoutInfo(flyoutId)
		for i = 1, (numSlots or 0) do
			local sid, override, _, slotName = S.GetFlyoutSlotInfo(flyoutId, i)
			if (base and sid == base) or (name and slotName == name) then
				return S.FlyoutSlotCastID(flyoutId, i) or override or sid
			end
		end
	end
	if base and S and S.GetOverrideSpell then
		local resolved = S.GetOverrideSpell(base)
		if PositiveSpell(resolved) then
			return resolved
		end
	end
	return base
end

local function PickupResolvedSpell(spellId)
	if not spellId or InLockdown() then
		return
	end
	if C_Spell and C_Spell.PickupSpell then
		pcall(C_Spell.PickupSpell, spellId)
		return
	end
	if PickupSpell then
		pcall(PickupSpell, spellId)
	end
end

local function WireSpellFlyoutPopupButton(btn)
	if not btn or btn._fluxFlyoutPopupDragWired then
		return
	end
	btn._fluxFlyoutPopupDragWired = true
	btn:HookScript("OnDragStart", function(self)
		if InLockdown() then
			return
		end
		local sid = ResolveFlyoutPopupSpell(self)
		if sid then
			Action.NoteFlyoutPopupSpell(sid)
			PickupResolvedSpell(sid)
		end
	end)
end

local function WireSpellFlyoutPopupButtons()
	for i = 1, 32 do
		local btn = _G["SpellFlyoutPopupButton" .. i]
		if not btn then
			break
		end
		WireSpellFlyoutPopupButton(btn)
	end
end

local function WireSpellFlyout()
	local sf = _G.SpellFlyout
	if sf and not sf._fluxFlyoutPopupWired then
		sf._fluxFlyoutPopupWired = true
		sf:HookScript("OnShow", function()
			WireSpellFlyoutPopupButtons()
		end)
		sf:HookScript("OnHide", function()
			if not CursorHasPickup() then
				ClearFlyoutPopupStash()
			end
		end)
	end
	WireSpellFlyoutPopupButtons()
end

local function OnCursorChanged()
	if not CursorHasPickup() then
		ClearFlyoutPopupStash()
	end
end

local function SpellCursorAction(spellID)
	local api = ns.API
	local outfitID
	if api and api.GetPlayerTransmogOutfitIDForSpell then
		outfitID = api.GetPlayerTransmogOutfitIDForSpell(spellID)
	end
	if outfitID ~= nil then return "outfit", outfitID end
	return "spell", spellID
end

local function CursorToAction()
	if not GetCursorInfo then
		return nil
	end
	local cursorType, cursorData, cursorSubType, cursorSubData = GetCursorInfo()
	if not cursorType then
		return nil
	end
	local stashed, stashKind = PeekFlyoutPopupStash()
	if cursorType == "outfit" then
		local info = ns.API and ns.API.GetPlayerTransmogOutfitAction
			and ns.API.GetPlayerTransmogOutfitAction(cursorData)
		if info and not info.isDisabled then return "outfit", info.id end
		return nil
	elseif cursorType == "spell" then
		if stashed and stashKind == "spell" then
			return SpellCursorAction(stashed)
		end
		-- Popup slot pickup (not the parent flyout from the spellbook).
		if cursorSubType == "flyout" then
			local sid = PositiveSpell(cursorData) or PositiveSpell(cursorSubData)
			if sid and Flux.Spell and Flux.Spell.GetOverrideSpell then
				local ov = Flux.Spell.GetOverrideSpell(sid)
				if PositiveSpell(ov) then
					sid = ov
				end
			end
			return SpellCursorAction(sid or cursorData)
		end
		if C_SpellBook and C_SpellBook.GetSpellBookItemInfo and cursorData and cursorSubType then
			local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, cursorData, cursorSubType)
			local flyoutType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Flyout
			if ok and info and flyoutType and info.itemType == flyoutType then
				return "flyout", info.actionID or info.itemID or cursorSubData
			end
		end
		return SpellCursorAction(cursorSubData or cursorData)
	elseif cursorType == "flyout" then
		if stashed and stashKind == "spell" then
			return "spell", stashed
		end
		return "flyout", cursorData
	elseif cursorType == "item" then
		if stashed and stashKind == "item" then
			return "item", stashed
		end
		local iid = ItemID(cursorData) or cursorData
		if type(iid) == "number" and CapHas("hasToyBox") and PlayerHasToy and PlayerHasToy(iid) then
			return "toy", iid
		end
		return "item", iid
	elseif cursorType == "macro" then
		return "macro", cursorData
	elseif cursorType == "mount" then
		return "mount", ResolveCursorMountId(cursorData)
	elseif cursorType == "toy" then
		return "toy", cursorData
	elseif cursorType == "battlepet" then
		return "battlepet", cursorData
	elseif cursorType == "companion" then
		if cursorSubType == "MOUNT" then
			return "mount", ResolveCursorMountId(cursorData)
		elseif cursorSubType == "CRITTER" then
			local spellID = CompanionSpellID("CRITTER", cursorData)
			if spellID then
				return "spell", spellID
			end
			if CapHas("hasC_PetJournal") then
				return "battlepet", cursorData
			end
		end
		return nil
	end
	return nil
end

function Action.OnReceiveDrag(btn)
	if not btn or btn.badgeMode or InLockdown() then
		return
	end
	if btn.ActionType == "pet" and GetCursorInfo and GetCursorInfo() == "petaction" then
		if PickupPetAction then
			pcall(PickupPetAction, btn.PetSlot or btn.ActionValue)
		end
		if EBS.Paint and EBS.Paint.Update then
			EBS.Paint.Update(btn)
		end
		return
	end
	if btn.locked then
		return
	end
	WireSpellFlyout()
	local actionType, actionValue = CursorToAction()
	if not actionType or actionValue == nil then
		return
	end
	local prevType = btn.ActionType
	local prevValue = btn.ActionValue
	local prevSpell = btn.SpellId
	local prevItem = btn.ItemId
	local prevMacro = btn.MacroIndex
	local prevMount = btn.MountId
	local prevToy = btn.ToyId
	local prevFlyout = btn.FlyoutId
	local prevPet = btn.BattlePetId
	local prevOutfit = btn.OutfitId

	Action.SetAction(btn, actionType, actionValue)
	ClearFlyoutPopupStash()
	if ClearCursor then
		ClearCursor()
	end
	if btn.OnReceiveDragCallback then
		Flux.Safecall(btn.OnReceiveDragCallback, actionType, btn.ActionValue or actionValue, btn)
	end

	if prevType and prevValue ~= nil then
		local ghost = {
			ActionType = prevType,
			ActionValue = prevValue,
			SpellId = prevSpell,
			ItemId = prevItem,
			MacroIndex = prevMacro,
			MountId = prevMount,
			ToyId = prevToy,
			FlyoutId = prevFlyout,
			BattlePetId = prevPet,
			OutfitId = prevOutfit,
		}
		Action.Pickup(ghost)
	end
end

function Action.OnDragStart(btn)
	if not btn or btn.badgeMode or InLockdown() then
		return
	end
	if btn.ActionType == "pet" then
		if IsModifiedClick and not IsModifiedClick("PICKUPACTION") then
			return
		end
		if PickupPetAction then
			pcall(PickupPetAction, btn.PetSlot or btn.ActionValue)
		end
		if EBS.Paint and EBS.Paint.Update then
			EBS.Paint.Update(btn)
		end
		return
	end
	if btn.locked then
		return
	end
	if not btn.ActionType then
		return
	end
	if not Action.Pickup(btn) then
		return
	end
	Action.Clear(btn)
	if btn.OnDelete then
		Flux.Safecall(btn.OnDelete)
	end
end

local function HideCompareTooltips()
	if ShoppingTooltip1 then
		ShoppingTooltip1:Hide()
	end
	if ShoppingTooltip2 then
		ShoppingTooltip2:Hide()
	end
	if ShoppingTooltip3 then
		ShoppingTooltip3:Hide()
	end
	if ItemRefShoppingTooltip1 then
		ItemRefShoppingTooltip1:Hide()
	end
	if ItemRefShoppingTooltip2 then
		ItemRefShoppingTooltip2:Hide()
	end
end

local function ActiveTip(btn)
	local Guard = _G.FluxTooltipGuard
	if btn and btn._fluxIsolatedTooltip and Guard and Guard.GetTipForButton then
		return Guard.GetTipForButton(btn)
	end
	return GameTooltip
end

local function IsolatedItemId(btn)
	if not btn then
		return nil
	end
	local t = btn.ActionType
	local itemId = btn.ItemId
	if t == "item" then
		itemId = btn.ItemId or btn.ActionValue
	elseif (t == "macro" or t == "macrotext") and btn.ItemId then
		itemId = btn.ItemId
	end
	if type(itemId) == "string" then
		itemId = tonumber(itemId) or tonumber(tostring(itemId):match("(%d+)"))
	else
		itemId = tonumber(itemId)
	end
	return itemId
end

local function UpdateIsolatedTooltip(btn, tip)
	local Guard = _G.FluxTooltipGuard
	if not tip then
		return
	end
	local t = btn.ActionType
	local swapItemFace = btn._fluxCombatSwapBody and btn.MacroMode == "item" and btn.ItemId
	if not swapItemFace and (t == "spell" or btn.IsRecuperateMode) and Guard and Guard.FillBlizzardSpell then
		local sid = btn.SpellId or btn.ActionValue
		if btn.IsAssistedCombat then
			sid = btn.AssistedNextSpellId or sid
		end
		if sid and Flux.Spell and Flux.Spell.GetOverrideSpell then
			sid = Flux.Spell.GetOverrideSpell(sid) or sid
		end
		if not Guard.FillBlizzardSpell(tip, sid) then
			tip:SetText(btn.SpellName or btn.PlaceholderLabel or "Spell", 1, 1, 1)
		end
		tip:Show()
		return
	end
	local itemId = IsolatedItemId(btn)
	if itemId and Guard and Guard.FillBlizzardItem then
		if not Guard.FillBlizzardItem(tip, itemId) then
			tip:SetText(btn.PlaceholderLabel or "Item", 1, 1, 1)
		end
		tip:Show()
		return
	end
	if btn.PlaceholderLabel or btn.PlaceholderTexture then
		tip:SetText(btn.PlaceholderLabel or "Empty Slot", 1, 1, 1)
		tip:Show()
		return
	end
	tip:SetText("Empty Slot", 0.5, 0.5, 0.5)
	tip:Show()
end

-- Tooltip only. C++ CheckButton owns HighlightTexture (ButtonForge).
function Action.OnEnter(btn)
	if not btn then
		return
	end
	if btn.tooltipEnabled == false or btn.TooltipEnabled == false then
		return
	end
	local tip = ActiveTip(btn)
	if not tip then
		return
	end
	if btn._fluxIsolatedTooltip then
		if GameTooltip then
			GameTooltip:Hide()
		end
		HideCompareTooltips()
	end
	tip:SetOwner(btn.Widget, "ANCHOR_RIGHT")
	btn._fluxActiveTooltip = tip
	btn.tooltipHovering = true
	local updater = function()
		Action.UpdateTooltip(btn)
		Action.AppendTooltipExtras(btn)
	end
	btn.UpdateTooltip = updater
	if btn.Widget then
		btn.Widget.UpdateTooltip = updater
	end
	Action.UpdateTooltip(btn)
	Action.AppendTooltipExtras(btn)
end

function Action.AppendTooltipExtras(btn)
	if not btn then
		return
	end
	local tip = btn._fluxActiveTooltip or ActiveTip(btn)
	if not tip then
		return
	end
	if type(btn._fluxTooltipExtras) ~= "function" then
		if tip.Show then
			tip:Show()
		end
		return
	end
	local Bridge = _G.FluxEBSConsumableBridge
	if Bridge and Bridge.ResetFluxTooltipGap then
		Bridge.ResetFluxTooltipGap(tip)
	end
	pcall(btn._fluxTooltipExtras, btn, tip)
	if FluxSafeGameTooltipShow then
		FluxSafeGameTooltipShow(tip)
	else
		tip:Show()
	end
end

function Action.OnLeave(btn)
	if not btn then
		return
	end
	btn.tooltipHovering = nil
	btn.UpdateTooltip = nil
	if btn.Widget then
		btn.Widget.UpdateTooltip = nil
	end
	local Guard = _G.FluxTooltipGuard
	if Guard and Guard.HideForButton then
		Guard.HideForButton(btn)
	elseif GameTooltip then
		GameTooltip:Hide()
	end
	HideCompareTooltips()
end

local function OverrideSpell(spellId)
	if spellId and Flux.Spell and Flux.Spell.GetOverrideSpell then
		return Flux.Spell.GetOverrideSpell(spellId) or spellId
	end
	return spellId
end

local function TooltipSetSpell(spellId)
	if not GameTooltip or spellId == nil then
		return false
	end
	local id = SpellID(spellId)
	if not id and Flux.Spell and Flux.Spell.GetID then
		id = Flux.Spell.GetID(spellId)
	end
	id = OverrideSpell(id or spellId)
	if type(id) == "number" and GameTooltip.SetSpellByID then
		local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, id)
		return ok
	end
	if type(spellId) == "string" and GameTooltip.SetSpellByName then
		local ok = pcall(GameTooltip.SetSpellByName, GameTooltip, spellId)
		return ok
	end
	return false
end

local function TooltipSetItem(itemId)
	if not GameTooltip or not itemId then
		return false
	end
	if Flux.Inventory and Flux.Inventory.Find then
		local locs = Flux.Inventory.Find(itemId, {
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
		local ok = pcall(GameTooltip.SetItemByID, GameTooltip, itemId)
		if ok then
			return true
		end
	end
	if GameTooltip.SetHyperlink then
		local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. tostring(itemId))
		return ok
	end
	return false
end

function Action.UpdateTooltip(btn)
	if not btn then
		return
	end
	if btn.tooltipEnabled == false or btn.TooltipEnabled == false then
		return
	end
	if btn._fluxIsolatedTooltip then
		local tip = btn._fluxActiveTooltip or ActiveTip(btn)
		if not tip then
			return
		end
		if not tip:GetOwner() and btn.Widget then
			tip:SetOwner(btn.Widget, "ANCHOR_RIGHT")
		end
		UpdateIsolatedTooltip(btn, tip)
		return
	end
	if not GameTooltip then
		return
	end
	if not GameTooltip:GetOwner() and btn.Widget then
		GameTooltip:SetOwner(btn.Widget, "ANCHOR_RIGHT")
	end
	local t = btn.ActionType
	if t == "outfit" or btn._fluxUtilityOutfitID ~= nil then
		local info = btn._fluxUtilityOutfitInfo or btn.OutfitInfo
		local id = btn._fluxUtilityOutfitID or btn.OutfitId
		if id ~= 0 and GameTooltip.SetOutfit and info then
			GameTooltip:SetOutfit(id)
		elseif info and info.spell and GameTooltip.SetSpellByID then
			GameTooltip:SetSpellByID(info.tooltipSpell or info.spell)
		else
			GameTooltip:SetText(info and info.name or "Transmog Outfit")
		end
		GameTooltip:Show()
		return
	end
	if t == "macro" or t == "macrotext" then
		local shown = false
		if btn.ShowTooltip then
			if btn.MacroMode == "spell" and btn.SpellId then
				shown = TooltipSetSpell(btn.SpellId)
			elseif btn.MacroMode == "item" and btn.ItemId then
				shown = TooltipSetItem(btn.ItemId)
			end
		end
		if not shown then
			GameTooltip:SetText(btn.MacroName or "Macro")
		end
		GameTooltip:Show()
		return
	end
	if t == "spell" then
		local sid = btn.SpellId
		if btn.IsAssistedCombat then
			sid = btn.AssistedNextSpellId or sid
		end
		sid = OverrideSpell(sid)
		if sid then
			TooltipSetSpell(sid)
		end
	elseif t == "toy" and (btn.ToyId or btn.ItemId) then
		local id = btn.ToyId or btn.ItemId
		local shown
		if GameTooltip.SetToyByItemID then
			shown = pcall(GameTooltip.SetToyByItemID, GameTooltip, id)
		end
		if not shown then
			if GameTooltip.SetItemByID then
				GameTooltip:SetItemByID(id)
			else
				GameTooltip:SetHyperlink("item:" .. tostring(id))
			end
		end
	elseif t == "item" and btn.ItemId then
		if GameTooltip.SetItemByID then
			GameTooltip:SetItemByID(btn.ItemId)
		else
			GameTooltip:SetHyperlink("item:" .. tostring(btn.ItemId))
		end
	elseif t == "mount" then
		local mountId = btn.MountId or btn.ActionValue
		local name, spellID = ReadMountInfo(mountId)
		if name then
			btn.MountName = name
		else
			name = btn.MountName
		end
		if spellID then
			btn.MountSpellId = spellID
		else
			spellID = btn.MountSpellId
		end
		local shown = false
		if spellID then
			if GameTooltip.SetMountBySpellID then
				shown = pcall(GameTooltip.SetMountBySpellID, GameTooltip, spellID)
			end
			if not shown and GameTooltip.SetSpellByID then
				shown = pcall(GameTooltip.SetSpellByID, GameTooltip, spellID)
			end
			if shown and GameTooltip.NumLines and GameTooltip:NumLines() == 0 then
				shown = false
			end
		end
		if not shown then
			GameTooltip:SetText(name or "Mount", 1, 1, 1)
		end
	elseif t == "flyout" then
		local name
		if GetFlyoutInfo and btn.FlyoutId then
			name = GetFlyoutInfo(btn.FlyoutId)
		end
		GameTooltip:SetText(name or "Flyout")
	elseif t == "battlepet" then
		local id = btn.BattlePetId or btn.ActionValue
		if GameTooltip.SetCompanionPet and id then
			pcall(GameTooltip.SetCompanionPet, GameTooltip, id)
		else
			GameTooltip:SetText(btn.BattlePetName or "Battle Pet")
		end
	elseif t == "pet" then
		local slot = btn.PetSlot or btn.ActionValue
		if slot and GameTooltip.SetPetAction then
			pcall(GameTooltip.SetPetAction, GameTooltip, slot)
		else
			local name = btn.PetTooltipName
			if name then
				GameTooltip:SetText(name, 1, 1, 1)
			else
				GameTooltip:Hide()
				return
			end
		end
	elseif t == "shapeshift" then
		local sid = btn.SpellId
		if sid and GameTooltip.SetSpellByID then
			pcall(GameTooltip.SetSpellByID, GameTooltip, sid)
		else
			GameTooltip:Hide()
			return
		end
	elseif btn.PlaceholderLabel or btn.PlaceholderTexture then
		-- Empty food/water/hearth extras: title so AppendTooltipExtras ("No food") can attach.
		GameTooltip:SetText(btn.PlaceholderLabel or "Empty Slot", 1, 1, 1)
	else
		GameTooltip:Hide()
		return
	end
	GameTooltip:Show()
end

function FluxButton:SetAction(actionType, actionValue)
	Action.SetAction(self, actionType, actionValue)
end

function FluxButton:OnEnter()
	if self.TooltipEnabled == false or self.tooltipEnabled == false then
		return
	end
	Action.OnEnter(self)
end

function FluxButton:OnLeave()
	Action.OnLeave(self)
end

function FluxButton:FullRefresh()
	if EBS.Paint and EBS.Paint.Update then
		EBS.Paint.Update(self)
	end
end

function FluxButton:TranslateFace()
	Action.TranslateMacro(self)
end

function FluxButton:TranslateMacro()
	Action.TranslateMacro(self)
end

function FluxButton:ClearAction()
	Action.Clear(self)
end

function FluxButton:Pickup()
	Action.Pickup(self)
end

Action.ItemID = ItemID
Action.SpellID = SpellID
Action.ResolveMacroIndex = ResolveMacroIndex
Action.WriteAttributes = WriteAttributes

if Flux.AfterLoad then
	Flux.AfterLoad(function()
		WireSpellFlyout()
		if Flux.Events and Flux.Events.Register then
			Flux.Events.Register("CURSOR_CHANGED", OnCursorChanged)
			Flux.Events.Register("PLAYER_LOGIN", WireSpellFlyout)
			local function OnMacroProbeEvent()
				displayProbeAccum = DISPLAY_PROBE_INTERVAL
				OnMacroDisplayTick(0)
				Action.SyncMacroProbes()
			end
			Flux.Events.Register("PLAYER_ENTERING_WORLD", OnMacroProbeEvent)
			Flux.Events.Register("UPDATE_SHAPESHIFT_FORM", OnMacroProbeEvent)
			Flux.Events.Register("ZONE_CHANGED", OnMacroProbeEvent)
			Flux.Events.Register("ZONE_CHANGED_INDOORS", OnMacroProbeEvent)
			Flux.Events.Register("ZONE_CHANGED_NEW_AREA", OnMacroProbeEvent)
			pcall(Flux.Events.Register, "PLAYER_MOUNT_DISPLAY_CHANGED", OnMacroProbeEvent)
			pcall(Flux.Events.Register, "MOUNT_JOURNAL_USABILITY_CHANGED", OnMacroProbeEvent)
			pcall(Flux.Events.Register, "MIRROR_TIMER_START", OnMacroProbeEvent)
			pcall(Flux.Events.Register, "MIRROR_TIMER_STOP", OnMacroProbeEvent)
		end
	end)
end
