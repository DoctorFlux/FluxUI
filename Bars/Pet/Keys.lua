-- Bars/Pet/Keys.lua — BONUSACTIONBUTTON1-10 click-route onto Flux pet widgets.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars
local Pet = Bars.Pet

local function InLockdown()
	return Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown()
end

function Pet.SetupKeybindings()
	local frame = Pet.GetFrame and Pet.GetFrame()
	if not frame or InLockdown() or not SetOverrideBindingClick then
		if InLockdown() and Flux.Combat and Flux.Combat.Defer then
			Flux.Combat.Defer("bars.pet.keys", Pet.SetupKeybindings)
		end
		return
	end
	if ClearOverrideBindings then
		ClearOverrideBindings(frame)
	end
	if not GetBindingKey then
		return
	end
	local buttons = Pet.GetAllButtons and Pet.GetAllButtons() or {}
	for i = 1, Pet.CONFIG.totalButtons do
		local btn = buttons[i]
		local widget = btn and btn.Widget
		local name = widget and widget.GetName and widget:GetName()
		if name then
			local command = ("BONUSACTIONBUTTON%d"):format(i)
			local keys = { GetBindingKey(command) }
			for k = 1, #keys do
				local key = keys[k]
				if key and key ~= "" then
					pcall(SetOverrideBindingClick, frame, false, key, name, "KeyBind")
				end
			end
		end
	end
end
