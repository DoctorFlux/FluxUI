-- ExtraButtonSystem/FlyoutEngine/HostCompat.lua — NC modules talk to FlyoutEngine.
local addonName, ns = ...
local Flux = ns.Flux
local Flyout = Flux.EBS and Flux.EBS.Flyout
if not Flyout then
	return
end

local Compat = _G.FluxFlyoutFrame or {}
_G.FluxFlyoutFrame = Compat

local function ToEngineButtons(actions)
	local list = {}
	if type(actions) ~= "table" then
		return list
	end
	for i = 1, #actions do
		local src = actions[i]
		if type(src) == "table" then
			local t = src.type
				or (src.spellId and "spell")
				or (src["$spellID"] and "spell")
				or ((src.itemId or src["$itemId"] or src["$reagentItemId"]) and "item")
				or "item"
			local item = src["$itemId"] or src.itemId or src.ItemId or src.id or src["$reagentItemId"] or src.item
			list[#list + 1] = {
				type = t,
				spell = src.spell or src.spellId or src.SpellId or src["$spellID"],
				item = item,
				macro = src.macro,
				macrotext = src.macrotext or src.macroText,
				icon = src.icon or src.texture or src["$iconTexture"],
				name = src.name or src["$name"],
				count = src.count,
				bag = src.bag,
				slot = src.slot,
				onClick = src.onClick,
				skipFavorite = src.skipFavorite or src["$isReagent"] or nil,
				skipUse = src.skipUse or src["$isReagent"] or nil,
				isReagent = src.isReagent or src["$isReagent"] or nil,
				currentCount = src.currentCount or src["$currentCount"],
				targetCount = src.targetCount or src["$targetCount"],
			}
		end
	end
	return list
end

local function HostWidget(parentButton)
	if not parentButton then
		return nil
	end
	if parentButton.GetObjectType then
		return parentButton
	end
	return parentButton.Widget
end

function Compat.ShowFlyout(parentButton, actions, config)
	local widget = HostWidget(parentButton)
	if not widget or type(actions) ~= "table" or #actions == 0 then
		return
	end
	if Flyout.InLockdown and Flyout.InLockdown() then
		return
	end
	if Flyout.IsOpen and Flyout.IsOpen(widget) then
		Flyout.Close(widget)
		return
	end
	config = config or {}
	local buttons = ToEngineButtons(actions)
	local favCategory = config.favoriteCategory
		or (widget._fluxFlyoutFavoritesCategory)
	local opts = {
		direction = config.direction or "UP",
		favoriteCategory = favCategory,
		chrome = config.chrome,
		cellSize = config.cellSize,
		padding = config.padding,
		matchAnchorScale = config.matchAnchorScale ~= false,
	}
	if config.onActionUse then
		for i = 1, #buttons do
			local src = actions[i]
			local prev = buttons[i].onClick
			buttons[i].onClick = function(kid, mouse)
				if mouse == "RightButton" then
					return
				end
				if prev then
					prev(kid, mouse)
				end
				config.onActionUse(src, kid, mouse)
			end
		end
	end
	Flyout.SetButtons(widget, buttons, opts)
	if Flyout.Toggle then
		Flyout.Toggle(widget)
	end
end

function Compat.CloseFlyoutFor(parentButton)
	local widget = HostWidget(parentButton)
	if widget and Flyout.Close then
		Flyout.Close(widget)
	end
end

function Compat.CloseFlyout()
	if Flyout.CloseAll then
		Flyout.CloseAll()
	end
end

function Compat.IsFlyoutOpenFor(parentButton)
	local widget = HostWidget(parentButton)
	return widget and Flyout.IsOpen and Flyout.IsOpen(widget) or false
end

function Compat.GetFlyoutForButton(parentButton)
	local widget = HostWidget(parentButton)
	return widget and Flyout.GetPopup and Flyout.GetPopup(widget) or nil
end

function Compat.GetActiveFlyout()
	if not Flyout.attached then
		return nil
	end
	for widget, rec in pairs(Flyout.attached) do
		if rec and rec.popup and rec.popup:IsShown() then
			return rec.popup, widget
		end
	end
	return nil
end

function Compat.ShowArrow(parentButton, direction)
	local widget = HostWidget(parentButton)
	if not widget then
		return
	end
	local rec = Flyout.BindHost(widget, { direction = direction or "UP" })
	if Flyout.Arrow and Flyout.Arrow.Ensure then
		Flyout.Arrow.Ensure(widget, rec and rec.opts)
	end
	if Flyout.Arrow and Flyout.Arrow.Show then
		Flyout.Arrow.Show(widget)
	end
end

function Compat.HideArrow(parentButton)
	local widget = HostWidget(parentButton)
	if widget and Flyout.Arrow and Flyout.Arrow.Hide then
		Flyout.Arrow.Hide(widget)
	end
end

function Compat.ShowArrowFor(parentButton, direction)
	Compat.ShowArrow(parentButton, direction)
end

function Compat.OnDependentsLayoutChanged()
	if Flyout.OnDependentsLayoutChanged then
		Flyout.OnDependentsLayoutChanged()
	end
end

return Compat
