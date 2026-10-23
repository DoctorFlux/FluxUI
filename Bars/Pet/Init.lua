-- Bars/Pet/Init.lua — 5×2 Flux pet bar on Extra Button widgets.
local addonName, ns = ...
local Flux = ns.Flux

local Bars = Flux.Bars or {}
Flux.Bars = Bars

local Pet = Bars.Pet or {}
Bars.Pet = Pet

Pet.CONFIG = {
	buttonSize = 30,
	buttonPadding = 0,
	rows = 5,
	columns = 2,
	totalButtons = 10,
	scale = 1.133,
	showGrid = false,
}

local PETBAR_TO_STANCE_GAP = 4
local FLUX_WINDOW_GAP_X = -4
local FLUX_WINDOW_GAP_Y = -4
local STATUS_LOC2_STACK_GAP = 2
local VISIBILITY = "[pet,novehicleui]show;hide"
if Flux.Client and (Flux.Client.isCamelot or Flux.Client.isForever) then
	VISIBILITY = "[pet,nobonusbar:5]show;hide"
end

local frame
local buttons = {}
local started = false
local bindingModeOverride
local bindingModePending

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

function Pet.GetFrame()
	return frame
end

function Pet.GetButton(index)
	return buttons[index]
end

function Pet.GetAllButtons()
	return buttons
end

function Pet.ForAll(method, ...)
	local paint = Flux.EBS and Flux.EBS.Paint
	for i = 1, #buttons do
		local btn = buttons[i]
		if btn then
			if method == "Update" and paint and paint.Update then
				paint.Update(btn)
			elseif method == "UpdateUsable" and paint and paint.UpdateUsable then
				paint.UpdateUsable(btn)
			elseif method == "UpdateCooldown" and paint and paint.UpdateCooldown then
				paint.UpdateCooldown(btn)
			elseif method == "ShowGrid" then
				btn.showgrid = (btn.showgrid or 0) + 1
				if btn.Widget then
					btn.Widget:SetAlpha(1)
				end
			elseif method == "HideGrid" then
				btn.showgrid = math.max(0, (btn.showgrid or 0) - 1)
				if paint and paint.UpdateIcon then
					paint.UpdateIcon(btn)
				end
			elseif type(btn[method]) == "function" then
				btn[method](btn, ...)
			end
		end
	end
end

-- Same pet/stance spatial relationship as when Flux player is off:
-- pet sits left of stance only for Layout stance placement 2 (or no Flux player).
local function UsePetBarDetachedStanceLayout()
	local Stance = Bars.Stance
	if Stance and Stance.ShouldAnchorToPlayerBorder then
		return not Stance.ShouldAnchorToPlayerBorder()
	end
	if not (FluxUnitFrames_ShouldUseFlux and FluxUnitFrames_ShouldUseFlux("player")) then
		return true
	end
	if FluxOptions and FluxOptions.GetStanceBarPlacement and FluxOptions:GetStanceBarPlacement() == 2 then
		return true
	end
	return false
end

local function WindowFrame()
	if FluxWindowFrame and FluxWindowFrame.GetFrame then
		return FluxWindowFrame:GetFrame()
	end
	return nil
end

function Pet.UpdatePosition()
	if not frame then
		return
	end
	if InLockdown() then
		Defer("bars.pet.pos", Pet.UpdatePosition)
		return
	end
	frame:SetScale(Pet.CONFIG.scale)
	local statusStrip = _G.FluxStatusBarContainer
	local statusLoc2 = FluxOptions and FluxOptions.GetStatusBarPosition and FluxOptions:GetStatusBarPosition() == 2
	local stripShown = statusStrip and statusStrip.IsShown and statusStrip:IsShown()
	local stanceFrame = (Bars.Stance and Bars.Stance.GetFrame and Bars.Stance.GetFrame())
		or (_G.FluxStanceBar and _G.FluxStanceBar.GetFrame and _G.FluxStanceBar:GetFrame())
		or _G.FluxStanceBar
	if stanceFrame and not (stanceFrame.SetPoint and stanceFrame.GetHeight) then
		stanceFrame = nil
	end
	local stanceRow = stanceFrame and stanceFrame.IsShown and stanceFrame:IsShown()
		and stanceFrame.GetHeight and (stanceFrame:GetHeight() or 0) > 1

	if statusLoc2 and stripShown then
		frame:ClearAllPoints()
		if UsePetBarDetachedStanceLayout() and stanceRow then
			frame:SetPoint("TOPRIGHT", stanceFrame, "TOPLEFT", -PETBAR_TO_STANCE_GAP, 0)
		else
			frame:SetPoint("BOTTOMRIGHT", statusStrip, "TOPRIGHT", FLUX_WINDOW_GAP_X, STATUS_LOC2_STACK_GAP)
		end
		return
	end

	local windowFrame = WindowFrame()
	if windowFrame then
		frame:ClearAllPoints()
		if not UsePetBarDetachedStanceLayout() then
			-- Pos 1 + Flux player: pet at window top-left, not beside player-docked stance.
			frame:SetPoint("TOPRIGHT", windowFrame, "TOPLEFT", FLUX_WINDOW_GAP_X, FLUX_WINDOW_GAP_Y)
		elseif stanceRow then
			frame:SetPoint("TOPRIGHT", stanceFrame, "TOPLEFT", -PETBAR_TO_STANCE_GAP, 0)
		else
			frame:SetPoint("TOPRIGHT", windowFrame, "TOPLEFT", FLUX_WINDOW_GAP_X, FLUX_WINDOW_GAP_Y)
		end
		return
	end

	frame:ClearAllPoints()
	frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -22, -22)
end

function Pet.SetBindingModeFrameOverride(active)
	if not frame then
		return
	end
	if InLockdown() then
		bindingModePending = not not active
		return
	end
	bindingModePending = nil
	bindingModeOverride = not not active
	if UnregisterStateDriver then
		UnregisterStateDriver(frame, "visibility")
	end
	if active then
		if UnitHasVehicleUI and UnitHasVehicleUI("player") then
			frame:Hide()
		else
			frame:Show()
		end
	elseif RegisterStateDriver then
		RegisterStateDriver(frame, "visibility", VISIBILITY)
	end
end

function Pet.FlushBindingModePending()
	if bindingModePending == nil then
		return
	end
	local active = bindingModePending
	bindingModePending = nil
	Pet.SetBindingModeFrameOverride(active)
end

function Pet.ApplyVisibility()
	if not frame or InLockdown() then
		return
	end
	if bindingModeOverride then
		Pet.SetBindingModeFrameOverride(true)
		return
	end
	if RegisterStateDriver then
		RegisterStateDriver(frame, "visibility", VISIBILITY)
	end
end

local function InstallGlobal(f)
	f.GetFrame = function()
		return Pet.GetFrame()
	end
	f.GetButton = function(_, i)
		return Pet.GetButton(i)
	end
	f.GetAllButtons = function()
		return Pet.GetAllButtons()
	end
	f.ForAll = function(_, method, ...)
		return Pet.ForAll(method, ...)
	end
	f.UpdatePosition = function()
		return Pet.UpdatePosition()
	end
	f.SetupKeybindings = function()
		if Pet.SetupKeybindings then
			Pet.SetupKeybindings()
		end
	end
	f.SetBindingModeFrameOverride = function(_, active)
		return Pet.SetBindingModeFrameOverride(active)
	end
	_G.FluxPetBar = f
	Pet.shim = f
end

local function CreateButtons()
	local EBS = Flux.EBS
	if not (EBS and EBS.Widget and EBS.Widget.Create) then
		return
	end
	local native = (Flux.Bars and Flux.Bars.CONFIG and Flux.Bars.CONFIG.buttonSize) or 44
	for i = 1, Pet.CONFIG.totalButtons do
		local btn = EBS.Widget.Create(frame, {
			name = "FluxPetButton" .. i,
			size = native,
			showBorder = true,
			tooltip = true,
			macroText = false,
			autocast = true,
			locked = false,
			castUnit = "pet",
		})
		if btn then
			btn.showgrid = 0
			btn.categoryScope = "character"
			if EBS.Action and EBS.Action.SetAction then
				EBS.Action.SetAction(btn, "pet", i)
			end
			if EBS.Style and EBS.Style.Apply then
				EBS.Style.Apply(btn, "character")
			end
			local G = Flux.ButtonFX and Flux.ButtonFX.Glow
			if G and btn.Widget and G.NotifySAO then
				G.NotifySAO(btn.Widget)
			end
			buttons[i] = btn
		end
	end
end

function Pet.Start()
	if started then
		return
	end
	if InLockdown() then
		Defer("bars.pet.start", Pet.Start)
		return
	end
	started = true
	frame = CreateFrame("Frame", "FluxPetBar", UIParent)
	frame:SetFrameStrata("MEDIUM")
	frame:SetFrameLevel(5)
	frame:SetMovable(false)
	frame:EnableMouse(false)
	frame:SetSize(1, 1)
	frame:SetScale(Pet.CONFIG.scale)
	InstallGlobal(frame)
	CreateButtons()
	if Pet.LayoutButtons then
		Pet.LayoutButtons()
	end
	if FluxBorder and FluxBorder.SetClassColor then
		FluxBorder:SetClassColor(frame, 1, true)
	end
	Pet.ApplyVisibility()
	if Pet.SetupKeybindings then
		Pet.SetupKeybindings()
	end
	if Pet.Watch and Pet.Watch.Start then
		Pet.Watch.Start()
	end
	Pet.UpdatePosition()
	Pet.ForAll("Update")
	if Bars.Blizzard and Bars.Blizzard.HideUnusedBars then
		Bars.Blizzard.HideUnusedBars()
	end
end

Flux.Module.Register("PetBar", {
	clients = { era = true, anniversary = true, classic = true, midnight = true },
	OnEnable = function()
		Pet.Start()
	end,
})
