-- Action.lua — C_ActionBar vs legacy action-button queries
local addonName, ns = ...
local Flux = ns.Flux

local Action = {}
Flux.Action = Action
Flux.API = Flux.API or {}
Flux.API.Action = Action

local cab = C_ActionBar

local function Pick(modern, legacy)
	if cab and cab[modern] then
		return cab[modern]
	end
	return _G[legacy]
end

local _GetActionTexture = Pick("GetActionTexture", "GetActionTexture")
local _IsUsableAction = Pick("IsUsableAction", "IsUsableAction")
local _IsConsumableAction = Pick("IsConsumableAction", "IsConsumableAction")
local _IsStackableAction = Pick("IsStackableAction", "IsStackableAction")
local _IsItemAction = Pick("IsItemAction", "IsItemAction")
local _IsEquippedAction = Pick("IsEquippedAction", "IsEquippedAction")
local _GetActionCharges = Pick("GetActionCharges", "GetActionCharges")
local _GetActionCount = Pick("GetActionCount", "GetActionCount")
local _GetActionCooldown = Pick("GetActionCooldown", "GetActionCooldown")
local _GetActionInfo = GetActionInfo
local _HasAction = Pick("HasAction", "HasAction")
local _IsAttackAction = Pick("IsAttackAction", "IsAttackAction")
local _IsAutoRepeatAction = Pick("IsAutoRepeatAction", "IsAutoRepeatAction")
local _IsCurrentAction = Pick("IsCurrentAction", "IsCurrentAction")

local function ActionFlag(fn, slot)
	if not slot or not fn then
		return false
	end
	local ok, v = pcall(fn, slot)
	if not ok then
		return false
	end
	if Flux.Secrets and Flux.Secrets.SafeBooleanTest then
		return Flux.Secrets.SafeBooleanTest(v, false) and true or false
	end
	return v and true or false
end

function Action.GetTexture(slot)
	if not slot or not _GetActionTexture then
		return nil
	end
	return _GetActionTexture(slot)
end

function Action.IsUsable(slot)
	if not slot or not _IsUsableAction then
		return false
	end
	return _IsUsableAction(slot)
end

function Action.IsConsumable(slot)
	if not slot or not _IsConsumableAction then
		return false
	end
	return _IsConsumableAction(slot)
end

function Action.IsStackable(slot)
	if not slot or not _IsStackableAction then
		return false
	end
	return _IsStackableAction(slot)
end

function Action.IsItem(slot)
	if not slot or not _IsItemAction then
		return false
	end
	return _IsItemAction(slot)
end

function Action.IsEquipped(slot)
	if not slot or not _IsEquippedAction then
		return false
	end
	return _IsEquippedAction(slot)
end

-- Midnight C_ActionBar.GetActionCharges returns a SpellChargeInfo table.
-- Classic GetActionCharges returns current, max, start, duration, chargeModRate.
-- Pass values through (including secrets / duration objects). Do not compare here.
function Action.UnpackCharges(a, b, c, d, e, f)
	if type(a) == "table" then
		-- isActive is NeverSecret. Charge counts / start / duration may be.
		local chargeActive = a.isActive
		local ok, cur, maxC, start, duration, rate = pcall(function()
			return a.currentCharges, a.maxCharges, a.cooldownStartTime, a.cooldownDuration, a.chargeModRate
		end)
		if ok then
			return cur, maxC, start, duration, rate, chargeActive
		end
		return nil, nil, nil, nil, nil, chargeActive
	end
	return a, b, c, d, e, f
end

-- Midnight C_ActionBar.GetActionCooldown returns a CooldownInfo table with isActive.
-- Classic GetActionCooldown is start, duration, enable, modRate. isActive is nil on tuples.
function Action.UnpackCooldown(a, b, c, d, e)
	if type(a) == "table" then
		return a.startTime or a.start, a.duration, a.isEnabled or a.enable, a.isActive, a.modRate or a.timeMod
	end
	return a, b, c, nil, d or e
end

function Action.GetCharges(slot)
	if not slot or not _GetActionCharges then
		return 0, 0, 0, 0, 0
	end
	return Action.UnpackCharges(_GetActionCharges(slot))
end

function Action.GetCount(slot)
	if not slot or not _GetActionCount then
		return 0
	end
	return _GetActionCount(slot)
end

function Action.GetCooldown(slot)
	if not slot or not _GetActionCooldown then
		return 0, 0, 0
	end
	return Action.UnpackCooldown(_GetActionCooldown(slot))
end

function Action.GetChargeDuration(slot)
	if not slot or not (cab and cab.GetActionChargeDuration) then
		return nil
	end
	return cab.GetActionChargeDuration(slot)
end

function Action.GetInfo(slot)
	if not slot or not _GetActionInfo then
		return nil
	end
	return _GetActionInfo(slot)
end

--- Occupancy key is action type+id only. Shown-spell flips on a bar macro
--- (GetMacroSpell / GetMacroItem) are display, not a new occupant.
function Action.OccupancyKey(slot)
	if not slot then
		return ""
	end
	local actionType, id = Action.GetInfo(slot)
	return (actionType or "") .. ":" .. tostring(id or "")
end

-- Macro name overlay on action slots. Empty for spells/items.
function Action.GetText(slot)
	if not slot or not GetActionText then
		return nil
	end
	return GetActionText(slot)
end

function Action.HasAction(slot)
	if not slot or not _HasAction then
		return false
	end
	local ok, v = pcall(_HasAction, slot)
	if not ok then
		return false
	end
	if Flux.Secrets and Flux.Secrets.SafeBooleanTest then
		return Flux.Secrets.SafeBooleanTest(v, false) and true or false
	end
	return v and true or false
end

function Action.IsAttack(slot)
	return ActionFlag(_IsAttackAction, slot)
end

function Action.IsAutoRepeat(slot)
	return ActionFlag(_IsAutoRepeatAction, slot)
end

function Action.IsCurrent(slot)
	return ActionFlag(_IsCurrentAction, slot)
end

function Action.IsAssistedCombat(slot)
	if type(slot) ~= "number" then
		return false
	end
	if not (cab and cab.IsAssistedCombatAction) then
		return false
	end
	return cab.IsAssistedCombatAction(slot) and true or false
end

-- Next rotation spell for the one-button assistant. Argument must stay false:
-- true is highlight-mode and returns nil while the assistant button is visible.
function Action.GetAssistedNextSpell()
	if Flux.Cap and Flux.Cap.ClientSupportsSingleButtonAssistant then
		if not Flux.Cap.ClientSupportsSingleButtonAssistant() then
			return nil
		end
	end
	if not (C_AssistedCombat and C_AssistedCombat.GetNextCastSpell) then
		return nil
	end
	local ok, id = pcall(C_AssistedCombat.GetNextCastSpell, false)
	if not ok then
		return nil
	end
	id = tonumber(id)
	if not (id and id > 0) then
		return nil
	end
	if Flux.Spell and Flux.Spell.GetOverrideSpell then
		id = Flux.Spell.GetOverrideSpell(id) or id
	end
	return id
end

function Action.IsAssistedHighlightActive()
	local mgr = _G.AssistedCombatManager
	if mgr and mgr.IsAssistedHighlightActive then
		local ok, on = pcall(mgr.IsAssistedHighlightActive, mgr)
		if ok then
			return on and true or false
		end
	end
	if GetCVarBool then
		local ok, v = pcall(GetCVarBool, "assistedCombatHighlight")
		return ok and v and true or false
	end
	return false
end

-- Highlight-mode next-cast. true is required: false is the one-button assistant
-- face and returns a different spell while that button is shown.
function Action.GetAssistedHighlightSpell()
	if not Action.IsAssistedHighlightActive() then
		return nil
	end
	if not (C_AssistedCombat and C_AssistedCombat.GetNextCastSpell) then
		return nil
	end
	local ok, id = pcall(C_AssistedCombat.GetNextCastSpell, true)
	if not ok then
		return nil
	end
	if Flux.Secrets and Flux.Secrets.IsSecretValue and Flux.Secrets.IsSecretValue(id) then
		return nil
	end
	id = tonumber(id)
	if not (id and id > 0) then
		return nil
	end
	return id
end

-- Same occupancy as Blizzard AssistedCombatManager:GetActionButtonSpellForAssistedHighlight.
-- Do not write widget.action: that taints UseAction on the click path.
function Action.SpellForAssistedHighlight(slot)
	if type(slot) ~= "number" then
		return nil
	end
	local typ, id, subType = Action.GetInfo(slot)
	if typ == nil then
		return nil
	end
	if Flux.Secrets and Flux.Secrets.IsSecretValue then
		if Flux.Secrets.IsSecretValue(typ) then
			return nil
		end
	end
	if typ == "macro" then
		if subType == "spell" then
			return id
		end
		return 0
	end
	if typ == "spell" and subType ~= "assistedcombat" then
		local mgr = _G.AssistedCombatManager
		if mgr and mgr.IsRotationSpell then
			local ok, rot = pcall(mgr.IsRotationSpell, mgr, id)
			if ok and rot then
				return id
			end
			return nil
		end
		return id
	end
	return nil
end

function Action.GetDisplayCount(slot)
	if not slot then
		return nil
	end
	if cab and cab.GetActionDisplayCount then
		return cab.GetActionDisplayCount(slot)
	end
	return Action.GetCount(slot)
end

function Action.GetCooldownDuration(slot)
	if not slot or not (cab and cab.GetActionCooldownDuration) then
		return nil
	end
	return cab.GetActionCooldownDuration(slot)
end

function Action.EnableRangeCheck(slot, enable)
	if not slot or not (cab and cab.EnableActionRangeCheck) then
		return false
	end
	return pcall(cab.EnableActionRangeCheck, slot, enable and true or false)
end

-- ActionBarButtonEventsFrame has RegisterFrame but no UnregisterFrame on
-- mainline, and its OnEvent walks pairs(self.frames) calling frame:OnEvent.
-- Any Flux function reachable from that loop taints every later frame in it,
-- including OverrideActionBarButtonN → Update → UpdatePressAndHoldAction →
-- SetAttribute (ADDON_ACTION_BLOCKED in combat). Drop the entry instead.
local COLLECTORS = {
	"ActionBarButtonEventsFrame",
	"ActionBarActionEventsFrame",
	"ActionBarButtonUpdateFrame",
}

--- Forever gamepad buttons share these collectors. Addon tinsert/nil taints
--- frames, then UpdatePressAndHoldAction taints UseAction on every click.
local function LeaveBlizzardCollector()
	local C = Flux.Client
	return C and (C.isCamelot or C.isForever) and true or false
end

function Action.LeaveBlizzardCollector()
	return LeaveBlizzardCollector()
end

--- OnLoad of ActionBarButtonTemplate calls RegisterFrame. Suppress that for
--- one CreateFrame, then restore the Blizzard methods.
function Action.WithRegistrationSuppressed(fn)
	if not LeaveBlizzardCollector() then
		return fn()
	end
	local saved = {}
	for i = 1, #COLLECTORS do
		local collector = _G[COLLECTORS[i]]
		if collector and type(collector.RegisterFrame) == "function" then
			saved[#saved + 1] = { collector = collector, orig = collector.RegisterFrame }
			collector.RegisterFrame = function() end
		end
	end
	local results = { pcall(fn) }
	for i = 1, #saved do
		saved[i].collector.RegisterFrame = saved[i].orig
	end
	if not results[1] then
		error(results[2])
	end
	return unpack(results, 2)
end

--- Remove one widget from a Blizzard button collector.
--- Nils in place; never table.remove — shifting rewrites the later
--- Blizzard-owned entries as tainted values.
function Action.NilFromCollector(collector, widget)
	if LeaveBlizzardCollector() then
		return
	end
	if not collector or not widget then
		return
	end
	if collector.UnregisterFrame then
		pcall(collector.UnregisterFrame, collector, widget)
	end
	local frames = collector.frames
	if type(frames) ~= "table" then
		return
	end
	frames[widget] = nil
	local tail = #frames
	if frames[tail] == widget then
		frames[tail] = nil
		return
	end
	for k, f in pairs(frames) do
		if f == widget then
			frames[k] = nil
		end
	end
end

local function IsFluxActionWidget(widget)
	if type(widget) ~= "table" then
		return false
	end
	if widget._fluxHost or widget._fluxExtraButton or widget._fluxOverlayAttached
		or widget._fluxIsPresetGrid or widget._fluxOccupancy or widget.FluxButton then
		return true
	end
	local name = widget.GetName and widget:GetName()
	if type(name) ~= "string" then
		return false
	end
	-- Pattern (not plain): a fourth-arg true made "^FluxAction" look for a
	-- literal caret, so FluxCombat / FluxTrinket / FluxEBS never matched.
	return name:find("^Flux") ~= nil
end

--- Drop every Flux action widget still sitting in a Blizzard collector.
--- ActionBarButtonEventsFrame:OnEvent walks pairs(self.frames) and any Flux
--- script reached there (OnAttributeChanged, UpdateFlyout, SetChecked) taints
--- the rest of the loop — OverrideActionBarButtonN:SetAttribute in combat.
function Action.SweepFluxFromCollectors()
	if LeaveBlizzardCollector() then
		return
	end
	for i = 1, #COLLECTORS do
		local collector = _G[COLLECTORS[i]]
		local frames = collector and collector.frames
		if type(frames) == "table" then
			local drop = {}
			for _, f in pairs(frames) do
				if IsFluxActionWidget(f) then
					drop[#drop + 1] = f
				end
			end
			for j = 1, #drop do
				Action.NilFromCollector(collector, drop[j])
			end
		end
	end
end

--- Drop a widget from every action-button collector plus the C_ActionBar registry.
function Action.DetachFromCollectors(widget, slot)
	if not widget then
		return
	end
	for i = 1, #COLLECTORS do
		Action.NilFromCollector(_G[COLLECTORS[i]], widget)
	end
	if cab and cab.UnregisterActionUIButton then
		pcall(cab.UnregisterActionUIButton, widget)
	end
	if widget.UnregisterActionBarButtonCheckFrames then
		pcall(widget.UnregisterActionBarButtonCheckFrames, widget, slot or widget.action)
	end
	Action.SweepFluxFromCollectors()
end
