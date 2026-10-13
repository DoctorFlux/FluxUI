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
local addonName, ns = ...
local Flux = ns.Flux

local ButtonFX = Flux.ButtonFX or {}
Flux.ButtonFX = ButtonFX

local Click = {}
ButtonFX.Click = Click

local wrapFrame

-- KeyBind remaps to LeftButton per CVar. Mouse-down is swallowed. Mouse-up
-- falls through untouched so the secure handler runs the release path.
local CLICK_SNIPPET = [[
	if (button == "KeyBind") then
		local IsEmpowerSpell = self:GetAttribute("IsEmpowerSpell")
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
	elseif (down) then
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
		wrap:Execute([[
			ActionButtonUseKeyDown = owner:GetAttribute("CVar_ActionButtonUseKeyDown")
			empowerTapControls = owner:GetAttribute("CVar_empowerTapControls")
		]])
	end
end

--- Mirror type onto typerelease (ButtonForge). Hold-release reads typerelease,
--- not type. Action slots use "action" (UseAction), never "actionrelease".
function Click.MirrorTypeRelease(widget)
	if not widget or not widget.GetAttribute then
		return
	end
	local actionType = widget:GetAttribute("type")
	if type(actionType) ~= "string" or actionType == "" then
		return
	end
	pcall(widget.SetAttribute, widget, "typerelease", actionType)
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
	if not wrap or not wrap.WrapScript then
		widget:RegisterForClicks("AnyUp")
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
	pcall(wrap.WrapScript, wrap, widget, "OnClick", CLICK_SNIPPET)
	Click.SyncCVars()
end
