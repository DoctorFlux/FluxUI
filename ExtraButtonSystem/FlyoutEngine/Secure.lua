-- ExtraButtonSystem/FlyoutEngine/Secure.lua — opener snippet + WrapScript helpers.
local addonName, ns = ...
local Flux = ns.Flux
local Flyout = Flux.EBS and Flux.EBS.Flyout
if not Flyout then
	return
end

local Secure = {}
Flyout.Secure = Secure

Secure.OPENER_SCRIPT = [=[
local arg1, arg2 = ...
local mouseClick = button or arg1 or "LeftButton"
local isDown = down
if isDown == nil then
	isDown = arg2
end
if isDown then
	return
end
local popup = self:GetFrameRef("popup")
local host = self:GetFrameRef("host")
local uiParent = self:GetFrameRef("uiParent")
local visibilityParent = self:GetFrameRef("visibilityParent")
if not popup then
	return
end
if visibilityParent and not visibilityParent:IsVisible() then
	return
end
if popup:IsShown() then
	popup:Hide()
	popup:ClearBindings()
	return
end
	popup:SetBindingClick(true, "ESCAPE", self, mouseClick)
	popup:ClearAllPoints()
	if visibilityParent or uiParent then
		popup:SetParent(visibilityParent or uiParent)
	end
	local dir = self:GetAttribute("flyoutDirection") or "UP"
	local place = self:GetFrameRef("place") or host
	local pp = self:GetAttribute("flyoutPlacePoint")
	local pr = self:GetAttribute("flyoutPlaceRelPoint")
	if pp and pr and place then
		popup:SetPoint(pp, place, pr, self:GetAttribute("flyoutPlaceX") or 0, self:GetAttribute("flyoutPlaceY") or 0)
	elseif host then
		if dir == "DOWN" then
			popup:SetPoint("TOP", host, "BOTTOM", 0, -2)
		elseif dir == "LEFT" then
			popup:SetPoint("RIGHT", host, "LEFT", -2, 0)
		elseif dir == "RIGHT" then
			popup:SetPoint("LEFT", host, "RIGHT", 2, 0)
		else
			popup:SetPoint("BOTTOM", host, "TOP", 0, 2)
		end
	end
	popup:Show()
]=]

Secure.CLOSE_SCRIPT = [=[
local arg1, arg2 = ...
local isDown = down
if isDown == nil then
	isDown = arg2
end
if isDown then
	return
end
if self:GetAttribute("doCloseOnClick") == false then
	return
end
local popup = self:GetFrameRef("popup")
if not popup then
	return
end
local dummy = popup:GetFrameRef("dummy")
if dummy and dummy:GetAttribute("doCloseOnClick") == false then
	return
end
if popup:IsShown() then
	popup:Hide()
	popup:ClearBindings()
end
]=]

-- Only explicitly opted-in hosts follow a shared visibility owner. Run this
-- before that owner's ordinary OnHide so an open popup loses its Escape
-- binding securely and stays closed when the owner becomes visible again.
Secure.VISIBILITY_HIDE_SCRIPT = [=[
if control:GetFrameRef("visibilityParent") == self then
	control:Hide()
	control:ClearBindings()
end
]=]

function Secure.HandlerOnLoad(frame)
	if frame and SecureHandler_OnLoad then
		pcall(SecureHandler_OnLoad, frame)
	end
end

function Secure.SetVisibilityParent(popup, parent)
	if not popup or Flyout.InLockdown() then return false end
	if not parent and not popup._fluxVisibilityParent then return true end
	Secure.HandlerOnLoad(popup)
	if not popup.SetFrameRef then return false end
	popup:SetFrameRef("visibilityParent", parent or UIParent)
	popup._fluxVisibilityParent = parent
	if not parent then return true end
	local Restricted = Flux.Restricted
	local works = not Restricted or not Restricted.Works or Restricted.Works()
	if not works and Restricted.PagingWorks then works = Restricted.PagingWorks() end
	if not works or not popup.WrapScript then return false end
	popup._fluxVisibilityWraps = popup._fluxVisibilityWraps or {}
	if popup._fluxVisibilityWraps[parent] then return true end
	local ok = pcall(popup.WrapScript, popup, parent, "OnHide", Secure.VISIBILITY_HIDE_SCRIPT)
	if ok then popup._fluxVisibilityWraps[parent] = true end
	return ok
end

function Secure.InstallOpener(arrow, popup, host)
	if not arrow or not popup or not host then
		return
	end
	if Flyout.InLockdown() then
		return
	end
	Secure.HandlerOnLoad(arrow)
	Secure.HandlerOnLoad(popup)
	if arrow.SetFrameRef then
		arrow:SetFrameRef("popup", popup)
		arrow:SetFrameRef("host", host)
		arrow:SetFrameRef("uiParent", UIParent)
		local rec = Flyout.HostOf(host)
		local opts = rec and rec.opts or {}
		if opts.visibilityParent or arrow._fluxVisibilityParent then
			arrow:SetFrameRef("visibilityParent", opts.visibilityParent or UIParent)
			arrow._fluxVisibilityParent = opts.visibilityParent
			Secure.SetVisibilityParent(popup, opts.visibilityParent)
		end
		local place = opts.anchorFrame or host
		arrow:SetFrameRef("place", place)
		if not Flyout.InLockdown() then
			if opts.placePoint and opts.placeRelPoint then
				arrow:SetAttribute("flyoutPlacePoint", opts.placePoint)
				arrow:SetAttribute("flyoutPlaceRelPoint", opts.placeRelPoint)
				arrow:SetAttribute("flyoutPlaceX", opts.placeX or 0)
				arrow:SetAttribute("flyoutPlaceY", opts.placeY or 0)
			else
				arrow:SetAttribute("flyoutPlacePoint", nil)
				arrow:SetAttribute("flyoutPlaceRelPoint", nil)
				arrow:SetAttribute("flyoutPlaceX", nil)
				arrow:SetAttribute("flyoutPlaceY", nil)
			end
		end
	end
	local dummy = Flyout.EnsureDummy()
	if popup.SetFrameRef and dummy then
		popup:SetFrameRef("dummy", dummy)
	end
	arrow:SetAttribute("type", Flyout.OPENER_TYPE)
	arrow:SetAttribute("typerelease", Flyout.OPENER_TYPE)
	arrow:SetAttribute("*type*", Flyout.OPENER_TYPE)
	local Restricted = Flux.Restricted
	if Restricted and Restricted.SetSnippet then
		Restricted.SetSnippet(arrow, Flyout.OPENER_ATTR, Secure.OPENER_SCRIPT)
		Restricted.SetSnippet(arrow, "_" .. Flyout.OPENER_TYPE, Secure.OPENER_SCRIPT)
	elseif not (Restricted and Restricted.Works and not Restricted.Works()) then
		arrow:SetAttribute(Flyout.OPENER_ATTR, Secure.OPENER_SCRIPT)
		arrow:SetAttribute("_" .. Flyout.OPENER_TYPE, Secure.OPENER_SCRIPT)
	end
end

function Secure.InstallKidClose(kid, popup)
	if not kid or not popup then
		return
	end
	if Flyout.InLockdown() then
		return
	end
	if kid._fluxFlyoutWrapped then
		if kid.SetFrameRef then
			kid:SetFrameRef("popup", popup)
		end
		return
	end
	Secure.HandlerOnLoad(kid)
	if kid.SetFrameRef then
		kid:SetFrameRef("popup", popup)
	end
	local Restricted = Flux.Restricted
	if Restricted and Restricted.Works and not Restricted.Works() then
		return
	end
	if WrapScript then
		pcall(WrapScript, kid, "PostClick", Secure.CLOSE_SCRIPT)
		kid._fluxFlyoutWrapped = true
	end
end
