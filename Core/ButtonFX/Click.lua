-- ButtonFX/Click.lua — ButtonForge secure click contract, verbatim.
--
-- Addon buttons reach SecureActionButton_OnClick with isSecureAction nil, so
-- isSecureMousePress is false and pressAndHoldAction keeps useOnKeyDown true.
-- Mouse-down is swallowed by the wrap; mouse-up falls through and resolves as
-- the hold-release path, which reads `typerelease` (mirrored onto `type`).
--
-- The wrap must not write useOnKeyDown or pressAndHoldAction. A pre-body that
-- returns no message also suppresses the post-body (SecureHandlers.lua
-- Wrapped_Click gates it on `message ~= nil`), so any attribute cleared here
-- would never be restored.
--
-- Forever has no WrapScript. Stock OnClick cannot pass isSecureAction, so
-- mouse and keys share one useOnKeyDown gate. Do not SetScript OnClick —
-- calling SecureActionButton_OnClick from addon Lua taints UseAction.
-- Visible hosts register AnyUp with useOnKeyDown false (mouse on release).
-- Strip keys click a hidden AnyDown proxy that inherits the host attributes.
local addonName, ns = ...
local Flux = ns.Flux

local ButtonFX = Flux.ButtonFX or {}
Flux.ButtonFX = ButtonFX

local Click = {}
ButtonFX.Click = Click

local wrapFrame

-- KeyBind remaps to LeftButton per CVar. ConjureBind remaps to RightButton.
-- Extra window: mouse-down is swallowed. Mouse-up falls through so the secure
-- handler runs the release path (typerelease / typerelease2 / typerelease3).
-- HUD grids / trinkets (opts.onDown): invert that — fire on press, swallow up
-- so AnyDown+AnyUp does not use twice. HUD conjure keys must follow that press
-- path: CVar-gating would swallow down, and this wrap also swallows up.
-- The empower gate follows the same modifier paging the click does: Bars.State
-- stamps shift-IsEmpowerSpell* / ctrl-IsEmpowerSpell* next to shift-action* /
-- ctrl-action*, and IsShiftKeyDown / IsControlKeyDown are both in the
-- restricted environment. Reading only the bare attribute gated an empowered
-- spell on a mini row against whatever sat on the main row. Widgets without the
-- prefixed twins (Extra window, grids) fall back to the bare attribute.
local CLICK_SNIPPET = [[
	if (button == "KeyBind") then
		local IsEmpowerSpell
		if (IsShiftKeyDown()) then
			IsEmpowerSpell = self:GetAttribute("shift-IsEmpowerSpell*")
		elseif (IsControlKeyDown()) then
			IsEmpowerSpell = self:GetAttribute("ctrl-IsEmpowerSpell*")
		else
			IsEmpowerSpell = self:GetAttribute("IsEmpowerSpell*")
		end
		if (IsEmpowerSpell == nil) then
			IsEmpowerSpell = self:GetAttribute("IsEmpowerSpell")
		end
		if (down) then
			if (ActionButtonUseKeyDown or IsEmpowerSpell) then
				return "LeftButton"
			else
				return false
			end
		else
			if ((not ActionButtonUseKeyDown and not IsEmpowerSpell) or (IsEmpowerSpell and not empowerTapControls)) then
				return "LeftButton"
			else
				return false
			end
		end
	elseif (button == "ConjureBind") then
		local IsEmpowerSpell = self:GetAttribute("IsEmpowerSpell")
		if (down) then
			if (ActionButtonUseKeyDown or IsEmpowerSpell) then
				return "RightButton"
			else
				return false
			end
		else
			if ((not ActionButtonUseKeyDown and not IsEmpowerSpell) or (IsEmpowerSpell and not empowerTapControls)) then
				return "RightButton"
			else
				return false
			end
		end
	elseif (down) then
		return false
	end
]]

local CLICK_SNIPPET_ON_DOWN = [[
	if (button == "KeyBind") then
		local IsEmpowerSpell
		if (IsShiftKeyDown()) then
			IsEmpowerSpell = self:GetAttribute("shift-IsEmpowerSpell*")
		elseif (IsControlKeyDown()) then
			IsEmpowerSpell = self:GetAttribute("ctrl-IsEmpowerSpell*")
		else
			IsEmpowerSpell = self:GetAttribute("IsEmpowerSpell*")
		end
		if (IsEmpowerSpell == nil) then
			IsEmpowerSpell = self:GetAttribute("IsEmpowerSpell")
		end
		if (down) then
			if (ActionButtonUseKeyDown or IsEmpowerSpell) then
				return "LeftButton"
			else
				return false
			end
		else
			if ((not ActionButtonUseKeyDown and not IsEmpowerSpell) or (IsEmpowerSpell and not empowerTapControls)) then
				return "LeftButton"
			else
				return false
			end
		end
	elseif (button == "ConjureBind") then
		if (down == false) then
			return false
		else
			return "RightButton"
		end
	elseif (not down) then
		return false
	end
]]

local function InLockdown()
	return InCombatLockdown and InCombatLockdown()
end

local function EnsureWrap()
	if wrapFrame then
		return wrapFrame
	end
	local ok, frame = pcall(CreateFrame, "Frame", "FluxButtonFXClickWrap", UIParent, "SecureHandlerBaseTemplate")
	if ok and frame then
		wrapFrame = frame
		wrapFrame:Hide()
		Click.SyncCVars()
	end
	return wrapFrame
end

function Click.SyncCVars()
	local wrap = EnsureWrap()
	if not wrap or InLockdown() then
		return
	end
	local keyDown = false
	if Flux.CVar and Flux.CVar.GetBool then
		keyDown = Flux.CVar.GetBool("ActionButtonUseKeyDown") and true or false
	elseif GetCVarBool then
		keyDown = GetCVarBool("ActionButtonUseKeyDown") and true or false
	end
	local empower = false
	if GetCVarBool then
		empower = GetCVarBool("empowerTapControls") and true or false
	end
	wrap:SetAttribute("CVar_ActionButtonUseKeyDown", keyDown)
	wrap:SetAttribute("CVar_empowerTapControls", empower)
	if wrap.Execute then
		local Restricted = Flux.Restricted
		if Restricted and Restricted.Execute then
			Restricted.Execute(wrap, [[
			ActionButtonUseKeyDown = owner:GetAttribute("CVar_ActionButtonUseKeyDown")
			empowerTapControls = owner:GetAttribute("CVar_empowerTapControls")
		]])
		else
			wrap:Execute([[
			ActionButtonUseKeyDown = owner:GetAttribute("CVar_ActionButtonUseKeyDown")
			empowerTapControls = owner:GetAttribute("CVar_empowerTapControls")
		]])
		end
	end
end

--- Mirror type* onto typerelease* (ButtonForge). Hold-release reads typerelease,
--- typerelease2, typerelease3 — not type / type2 / type3. Action slots use
--- "action" (UseAction), never "actionrelease".
local RELEASE_TYPE_KEYS = {
	"type",
	"type1",
	"type2",
	"type3",
	-- Strip modifier paging: Bars.State writes these wildcard sets so
	-- CalculateAction resolves nomod / SHIFT / CTRL from the live modifier state
	-- at press time. Without the release mirror a held SHIFT would cast on down
	-- and never resolve the hold-release path.
	"type*",
	"shift-type*",
	"ctrl-type*",
	"shift-type1",
	"ctrl-type1",
	"alt-type1",
	"alt-ctrl-type1",
	"alt-shift-type1",
	"ctrl-shift-type1",
	"alt-ctrl-shift-type1",
	"shift-type2",
	"ctrl-type2",
	"alt-type2",
	"shift-type3",
	"ctrl-type3",
	"alt-type3",
}

function Click.MirrorTypeRelease(widget)
	if not widget or not widget.GetAttribute then
		return
	end
	for i = 1, #RELEASE_TYPE_KEYS do
		local key = RELEASE_TYPE_KEYS[i]
		local actionType = widget:GetAttribute(key)
		if type(actionType) == "string" and actionType ~= "" then
			local releaseKey = key:gsub("type", "typerelease", 1)
			pcall(widget.SetAttribute, widget, releaseKey, actionType)
		end
	end
end

--- Wrap clients can WrapScript OnClick. Forever/camelot cannot (Restricted.Works
--- is false); Click.Apply then uses mouse-up on the widget and leaves key-down
--- to a hidden proxy (Bars.Clicks).
function Click.UsesWrap()
	local Restricted = Flux.Restricted
	if Restricted and Restricted.Works then
		return Restricted.Works() and true or false
	end
	return true
end

function Click.Apply(widget, opts)
	if not widget or InLockdown() then
		return
	end
	opts = opts or {}
	local wrap = EnsureWrap()
	if widget.EnableMouse then
		pcall(widget.EnableMouse, widget, true)
	end
	local Restricted = Flux.Restricted
	if not wrap or not wrap.WrapScript or not Click.UsesWrap() then
		-- Keep the template OnClick (secure). Addon OnClick taints UseAction.
		widget:RegisterForClicks("AnyUp")
		pcall(widget.SetAttribute, widget, "useOnKeyDown", false)
		pcall(widget.SetAttribute, widget, "pressAndHoldAction", false)
		return
	end
	pcall(wrap.UnwrapScript, wrap, widget, "OnClick")
	pcall(widget.SetAttribute, widget, "pressAndHoldAction", true)
	-- ButtonForge never sets useOnKeyDown; nil defers to the CVar.
	pcall(widget.SetAttribute, widget, "useOnKeyDown", nil)
	Click.MirrorTypeRelease(widget)
	if opts.empower then
		pcall(widget.SetAttribute, widget, "IsEmpowerSpell", true)
	end
	widget:RegisterForClicks("AnyUp", "AnyDown")
	local snippet = (opts.onDown and CLICK_SNIPPET_ON_DOWN) or CLICK_SNIPPET
	if Restricted and Restricted.WrapScript then
		Restricted.WrapScript(wrap, widget, "OnClick", snippet)
	else
		pcall(wrap.WrapScript, wrap, widget, "OnClick", snippet)
	end
	Click.SyncCVars()
end
