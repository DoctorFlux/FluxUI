-- ExtraButtonSystem/FlyoutEngine/Attach.lua — BindHost / SetButtons / Toggle.
local addonName, ns = ...
local Flux = ns.Flux
local Flyout = Flux.EBS and Flux.EBS.Flyout
if not Flyout then
	return
end

local function Rec(widget)
	return widget and Flyout.attached[widget] or nil
end

local function MergeOpts(rec, opts)
	rec.opts = rec.opts or {}
	if type(opts) ~= "table" then
		return rec.opts
	end
	for k, v in pairs(opts) do
		rec.opts[k] = v
	end
	if rec.opts.direction then
		rec.opts.direction = Flyout.DirOk(rec.opts.direction)
	end
	return rec.opts
end

function Flyout.BindHost(widget, opts)
	if not widget then
		return nil
	end
	local rec = Flyout.attached[widget]
	if not rec then
		rec = {
			widget = widget,
			opts = {},
			buttons = {},
		}
		Flyout.attached[widget] = rec
	end
	MergeOpts(rec, opts)
	if rec.opts.matchAnchorScale == nil then
		rec.opts.matchAnchorScale = true
	end
	local dir = rec.opts.direction or Flyout.DirOk(widget.GetAttribute and widget:GetAttribute("flyoutDirection")) or "UP"
	rec.opts.direction = dir
	if widget.SetAttribute and not Flyout.InLockdown() then
		widget:SetAttribute("flyoutDirection", dir)
	end
	if rec.arrow and rec.arrow.SetAttribute and not Flyout.InLockdown() then
		rec.arrow:SetAttribute("flyoutDirection", dir)
	end
	return rec
end

local function EnsureParts(widget)
	local rec = Rec(widget)
	if not rec then
		return nil
	end
	if Flyout.InLockdown() then
		return rec
	end
	Flyout.EnsureDummy()
	local popup = Flyout.Popup and Flyout.Popup.Ensure(widget)
	-- hideArrow: never create the secure opener. It cannot SetPoint onto
	-- SecureUnitButton children (player-frame spec/transmog hosts).
	local arrow
	if not (rec.opts and rec.opts.hideArrow) and Flyout.Arrow and Flyout.Arrow.Ensure then
		arrow = Flyout.Arrow.Ensure(widget, rec.opts)
	end
	if arrow and popup and Flyout.Secure and Flyout.Secure.InstallOpener then
		Flyout.Secure.InstallOpener(arrow, popup, widget)
	end
	if arrow and not Flyout.InLockdown() then
		arrow:SetAttribute("flyoutDirection", rec.opts.direction or "UP")
	end
	return rec
end

function Flyout.SetButtons(widget, buttons, opts)
	if not widget then
		return
	end
	local rec = Flyout.BindHost(widget, opts)
	if not rec then
		return
	end
	local list = Flyout.Def and Flyout.Def.NormalizeList(buttons) or (buttons or {})
	local favCategory = rec.opts and rec.opts.favoriteCategory
	if favCategory and Flyout.Favorites and Flyout.Favorites.PromoteAvailable then
		list = Flyout.Favorites.PromoteAvailable(list, favCategory)
	end
	rec.buttons = list
	local function apply()
		EnsureParts(widget)
		if Flyout.Popup and Flyout.Popup.Layout then
			Flyout.Popup.Layout(widget, rec.buttons, rec.opts)
		end
		if #list > 0 then
			if rec.opts and rec.opts.hideArrow then
				if Flyout.Arrow and Flyout.Arrow.Hide then
					Flyout.Arrow.Hide(widget)
				end
			elseif Flyout.Arrow and Flyout.Arrow.Show then
				Flyout.Arrow.Show(widget)
			end
		else
			if rec.popup and rec.popup:IsShown() and not Flyout.InLockdown() then
				rec.popup:Hide()
			end
			if Flyout.Arrow and Flyout.Arrow.Hide then
				Flyout.Arrow.Hide(widget)
			end
		end
	end
	if Flyout.InLockdown() then
		Flyout.Defer("flyout.setbuttons." .. tostring(widget), apply)
		return
	end
	apply()
end

function Flyout.Clear(widget)
	if not widget then
		return
	end
	local rec = Rec(widget)
	if not rec then
		return
	end
	rec.buttons = {}
	local function apply()
		if rec.popup and rec.popup:IsShown() then
			rec.popup:Hide()
		end
		if Flyout.Popup and Flyout.Popup.Layout then
			Flyout.Popup.Layout(widget, rec.buttons, rec.opts)
		end
		if Flyout.Arrow and Flyout.Arrow.Hide then
			Flyout.Arrow.Hide(widget)
		end
	end
	if Flyout.InLockdown() then
		Flyout.Defer("flyout.clear." .. tostring(widget), apply)
		return
	end
	apply()
end

function Flyout.PlacePopup(widget)
	if Flyout.Popup and Flyout.Popup.Place then
		Flyout.Popup.Place(widget)
	end
end

function Flyout.Toggle(widget)
	if not widget then
		return
	end
	local rec = Rec(widget)
	if not rec then
		return
	end
	EnsureParts(widget)
	local popup = rec.popup
	if not popup then
		return
	end
	if popup:IsShown() then
		if not Flyout.InLockdown() then
			popup:Hide()
		end
		return
	end
	if Flyout.InLockdown() then
		return
	end
	for other in pairs(Flyout.attached) do
		if other ~= widget then
			Flyout.Close(other)
		end
	end
	if Flyout.Popup and Flyout.Popup.Layout then
		Flyout.Popup.Layout(widget, rec.buttons, rec.opts)
	end
	Flyout.PlacePopup(widget)
	popup:Show()
end

function Flyout.Close(widget)
	local rec = Rec(widget)
	local popup = rec and rec.popup
	if popup and popup:IsShown() and not Flyout.InLockdown() then
		popup:Hide()
	end
end

function Flyout.CloseAll()
	if Flyout.InLockdown() then
		return
	end
	for widget in pairs(Flyout.attached) do
		Flyout.Close(widget)
	end
end

function Flyout.ApplyAppearanceAccent()
	for widget, rec in pairs(Flyout.attached) do
		if rec then
			if rec.popup and Flyout.Chrome and Flyout.Chrome.ApplyAccent then
				Flyout.Chrome.ApplyAccent(rec.popup)
			end
			if rec.arrow and Flyout.Arrow and Flyout.Arrow.ApplyAccent then
				Flyout.Arrow.ApplyAccent(rec.arrow)
			end
		end
	end
end

function Flyout.RefreshArrowLayers()
	if Flyout.Arrow and Flyout.Arrow.RefreshAll then
		Flyout.Arrow.RefreshAll()
	end
end
