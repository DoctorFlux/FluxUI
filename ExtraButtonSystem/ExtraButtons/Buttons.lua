--[[
    ExtraButtonSystem/ExtraButtons/Buttons.lua
    Button grid layout and pooling. Widgets come from the rewrite EBS engine.
]]

local addonName, ns = ...
local Flux = ns and ns.Flux
local E = FluxExtraButtons
if not E.Buttons then E.Buttons = {} end
local B = E.Buttons

B.activeButtonPool = {}
B.activeButtons = {}

local extraSeq = 1

local function Engine()
	return Flux and Flux.EBS
end

local function NativeSize()
	return E:GetDefaultButtonSize()
end

local function ScaleMult()
	return E.BUTTON_SLOT_SIZE_MULTIPLIER or 1.3
end

local function SlotSize()
	return NativeSize() * ScaleMult()
end

local function ApplyHostStyle(btn, scope)
	local ebs = Engine()
	if not (btn and ebs and ebs.Style and ebs.Style.Apply) then
		return
	end
	ebs.Style.Apply(btn, scope or btn.categoryScope or "character")
	if ebs.Style.SizeRing then
		ebs.Style.SizeRing(btn)
	end
end

-- Native 44 widget, visual size is SetScale on a larger SlotFrame. Do not SetSize
-- the widget to the visual px (SpellFX fill is authored for 44).
local function PackInSlot(btn, parent)
	local widget = btn and btn.Widget
	local slot = btn and btn.SlotFrame
	if not (widget and slot) then
		return
	end
	local scale = ScaleMult()
	local sz = SlotSize()
	slot:SetSize(sz, sz)
	if parent then
		slot:SetParent(parent)
	end
	local level = widget.GetFrameLevel and widget:GetFrameLevel()
	if slot.SetFrameLevel and type(level) == "number" then
		slot:SetFrameLevel(math.max(1, level - 1))
	end
	widget:SetParent(slot)
	widget:ClearAllPoints()
	widget:SetPoint("CENTER", slot, "CENTER", 0, 0)
	widget:SetSize(NativeSize(), NativeSize())
	widget:SetScale(scale)
	btn.ButtonScale = scale
	if slot.SetClipsChildren then
		pcall(slot.SetClipsChildren, slot, false)
	end
end

local function SetHostAction(btn, actionType, actionValue)
	local ebs = Engine()
	if ebs and ebs.Action and ebs.Action.SetAction then
		ebs.Action.SetAction(btn, actionType, actionValue)
	elseif btn.SetAction then
		btn:SetAction(actionType, actionValue)
	end
end

local function ClearHostAction(btn)
	local ebs = Engine()
	if ebs and ebs.Action and ebs.Action.Clear then
		ebs.Action.Clear(btn)
	elseif btn.ClearAction then
		btn:ClearAction()
	end
end

-- Retail/Midnight/Forever dropped the MouseIsOver global; Classic still has it.
local function FrameMouseOver(frame)
	if not frame then
		return false
	end
	if frame.IsForbidden and frame:IsForbidden() then
		return false
	end
	if frame.IsMouseOver then
		local ok, over = pcall(frame.IsMouseOver, frame)
		if ok then
			return over and true or false
		end
	end
	if MouseIsOver then
		local ok, over = pcall(MouseIsOver, frame)
		if ok and over then
			return true
		end
	end
	return false
end

function B:Initialize()
	self.activeButtonPool = {}
	self.activeButtons = {}
	self:SetupCursorMonitoring()
end

function B:SetupCursorMonitoring()
	local cursorEventFrame = CreateFrame("Frame")
	cursorEventFrame:RegisterEvent("CURSOR_CHANGED")
	cursorEventFrame:SetScript("OnEvent", function()
		local cursorType = GetCursorInfo()
		if cursorType then
			for _, btn in ipairs(self.activeButtons) do
				if btn and btn.deleteMeBtn then
					btn.deleteMeBtn:Hide()
				end
			end
		else
			self:UpdateAllDeleteButtonVisibility()
		end
	end)
end

function B:UpdateAllDeleteButtonVisibility()
	for _, btn in ipairs(self.activeButtons) do
		if btn and btn.deleteMeBtn and btn.deleteMeBtn.btnData then
			self:UpdateDeleteButtonVisibility(btn, btn.deleteMeBtn.btnData)
		end
	end
end

function B:CreateButton(parent, btnData)
	if InCombatLockdown and InCombatLockdown() then
		return nil
	end
	local ebs = Engine()
	if not (ebs and ebs.Widget and ebs.Widget.Create) then
		return nil
	end
	local native = NativeSize()
	local scale = ScaleMult()
	local slotFrame = CreateFrame("Frame", nil, parent)
	slotFrame:SetSize(native * scale, native * scale)
	slotFrame:EnableMouse(true)
	local name = "FluxExtraButton" .. extraSeq
	extraSeq = extraSeq + 1
	local btn = ebs.Widget.Create(slotFrame, {
		name = name,
		size = native,
		showBorder = true,
		tooltip = true,
		macroText = true,
		locked = false,
	})
	if not btn or not btn.Widget then
		return nil
	end
	btn.SlotFrame = slotFrame
	btn._fluxScopeOnlyTint = true
	PackInSlot(btn, parent)
	if ebs.Flyout and ebs.Flyout.BindHost then
		ebs.Flyout.BindHost(btn.Widget, { direction = "DOWN" })
	end
	ApplyHostStyle(btn, "character")
	local G = Flux and Flux.ButtonFX and Flux.ButtonFX.Glow
	if G and G.NotifySAO then
		G.NotifySAO(btn.Widget)
	end
	if not self:ButtonHasContent(btnData) then
		self:CreateDeleteButton(btn, btnData)
	end
	return btn
end

function B:CreateDeleteButton(btn, btnData)
	if not btn or not btn.Widget then
		return
	end

	local widgetName = btn.Widget:GetName() or "FluxExtraButton"
	local deleteBtn = CreateFrame("Button", widgetName .. "DeleteMe", btn.Widget, "UIPanelCloseButton")

	local deleteButtonSize = 32
	local Client = Flux and Flux.Client
	if Client and not Client.isPostDF then
		deleteButtonSize = deleteButtonSize * 1.2
	end
	deleteBtn:SetSize(deleteButtonSize, deleteButtonSize)
	deleteBtn:SetPoint("TOPRIGHT", btn.Widget, "TOPRIGHT", 0, 0)
	deleteBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-CloseButton-Up")
	deleteBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-CloseButton-Down")
	deleteBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-CloseButton-Highlight", "ADD")
	deleteBtn:SetFrameLevel(btn.Widget:GetFrameLevel() + 2)

	if btn.ButtonScale and btn.ButtonScale ~= 1 then
		deleteBtn:SetScale(1 / btn.ButtonScale)
	end

	deleteBtn:Hide()

	deleteBtn.buttonOwner = btn
	deleteBtn.btnData = btnData
	if btn.categoryData then
		deleteBtn.categoryData = btn.categoryData
	end

	deleteBtn:SetScript("OnClick", function(s)
		if InCombatLockdown() then
			return
		end

		local ownerBtn = s.buttonOwner
		local data = s.btnData
		local categoryData = s.categoryData or (ownerBtn and ownerBtn.categoryData)

		if not ownerBtn or not data then
			return
		end

		if data.dataType or data.actionType or data.actionValue then
			return
		end

		if not categoryData then
			local buttonWidget = ownerBtn.Widget
			if not buttonWidget then
				return
			end
			local slotFrame = ownerBtn.SlotFrame
			local buttonContainer = slotFrame and slotFrame:GetParent() or buttonWidget:GetParent()
			if not buttonContainer then
				return
			end
			if E.Categories and E.Categories.activeCategoryWindows then
				for _, catWindow in ipairs(E.Categories.activeCategoryWindows) do
					if catWindow.buttonContainer == buttonContainer
						or (slotFrame and catWindow.buttonContainer == slotFrame:GetParent()) then
						categoryData = catWindow.categoryData
						break
					end
				end
			end
		end

		if not categoryData then
			return
		end

		local success = E:RemoveButtonFromEntriesTable(categoryData, data)

		if success then
			if E.Categories then
				E.Categories:RefreshCategories()
			end
			C_Timer.After(0.1, function()
				if B.UpdateAllDeleteButtonVisibility then
					B:UpdateAllDeleteButtonVisibility()
				end
			end)
		end
	end)

	deleteBtn:SetScript("OnEnter", function(sDB)
		sDB:Show()
	end)

	deleteBtn:SetScript("OnLeave", function(sDB)
		if not FrameMouseOver(btn.Widget) and not FrameMouseOver(sDB) then
			sDB:Hide()
		end
	end)

	btn.deleteMeBtn = deleteBtn
end

function B:GetButtonFromPool(parent, btnData)
	local btn = table.remove(self.activeButtonPool)
	if not btn then
		return self:CreateButton(parent, btnData)
	end
	if btn.Widget then
		if not btn.SlotFrame then
			local slotFrame = CreateFrame("Frame", nil, parent)
			slotFrame:EnableMouse(true)
			btn.SlotFrame = slotFrame
		end
		PackInSlot(btn, parent)
		if not btn.deleteMeBtn and not self:ButtonHasContent(btnData) then
			self:CreateDeleteButton(btn, btnData)
		end
	end
	return btn
end

function B:ReturnButtonToPool(btn)
	if not btn then
		return
	end

	if btn.Widget then
		btn.Widget:Hide()
		btn.Widget:ClearAllPoints()
	end

	if btn.SlotFrame then
		btn.SlotFrame:Hide()
		btn.SlotFrame:ClearAllPoints()
	end

	if btn.deleteMeBtn then
		btn.deleteMeBtn:Hide()
	end

	for i, activeBtn in ipairs(self.activeButtons) do
		if activeBtn == btn then
			table.remove(self.activeButtons, i)
			break
		end
	end

	ClearHostAction(btn)

	table.insert(self.activeButtonPool, btn)
end

function B:CalculateGridLayout(containerWidth, buttonSize, buttonSpacing, numColumns)
	numColumns = numColumns or E.NUM_BUTTON_COLUMNS_TARGET
	local effectiveWidth = containerWidth - E.BUTTONS_LEFT_INSET - E.BUTTONS_RIGHT_INSET
	local actualColumns = math.floor(effectiveWidth / (buttonSize + buttonSpacing))
	actualColumns = math.max(1, math.min(actualColumns, numColumns))
	return actualColumns
end

function B:RenderButtonsForCategory(categoryFrame, categoryData, xOffset, yOffset)
	if not categoryFrame or not categoryData then
		return 0
	end

	local buttons = E:GetButtonsForCategory(categoryData)
	if #buttons == 0 then
		return 0
	end

	local containerWidth = categoryFrame:GetWidth() or 200
	local buttonSpacing = E.BUTTON_SPACING
	local slotSize = SlotSize()
	local numColumns = self:CalculateGridLayout(containerWidth, slotSize, buttonSpacing, E.NUM_BUTTON_COLUMNS_TARGET)

	local currentRow = 0
	local currentCol = 0
	local buttonsPlaced = 0

	for _, btnData in ipairs(buttons) do
		if btnData.type == "button" or not btnData.type then
			buttonsPlaced = buttonsPlaced + 1
			local btn = self:GetButtonFromPool(categoryFrame, btnData)
			if btn and btn.Widget then
				PackInSlot(btn, categoryFrame)

				local slotX = xOffset + (currentCol * (slotSize + buttonSpacing))
				local slotY = yOffset - (currentRow * (slotSize + buttonSpacing))

				if btn.SlotFrame then
					btn.SlotFrame:ClearAllPoints()
					btn.SlotFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", slotX, slotY)
					btn.SlotFrame:Show()
				end

				btn.Widget:Show()

				if btn.deleteMeBtn then
					btn.deleteMeBtn.btnData = btnData
					btn.deleteMeBtn.categoryData = categoryData
				end
				btn.categoryData = categoryData
				btn.btnData = btnData
				btn.categoryScope = categoryData.scope

				local hasAction = (btnData.dataType and btnData.data) or (btnData.actionType and btnData.actionValue)
				if hasAction then
					local actionType = btnData.dataType or btnData.actionType
					local actionValue = btnData.data or btnData.actionValue
					SetHostAction(btn, actionType, actionValue)
					if btn.deleteMeBtn then
						btn.deleteMeBtn:Hide()
						btn.deleteMeBtn:SetParent(nil)
						btn.deleteMeBtn = nil
					end
				else
					ClearHostAction(btn)
					if not btn.deleteMeBtn then
						self:CreateDeleteButton(btn, btnData)
					end
				end
				ApplyHostStyle(btn, categoryData.scope)

				btn.OnReceiveDragCallback = function(actionType, actionValue)
					btnData.dataType = actionType
					btnData.data = actionValue
					btnData.actionType = actionType
					btnData.actionValue = actionValue
					if btn.deleteMeBtn then
						btn.deleteMeBtn:Hide()
						btn.deleteMeBtn:SetParent(nil)
						btn.deleteMeBtn = nil
					end
					ApplyHostStyle(btn, categoryData.scope)
				end

				btn.OnDelete = function()
					btnData.dataType = nil
					btnData.data = nil
					btnData.actionType = nil
					btnData.actionValue = nil
					if not btn.deleteMeBtn then
						self:CreateDeleteButton(btn, btnData)
					end
					if btn.deleteMeBtn then
						self:UpdateDeleteButtonVisibility(btn, btnData)
					end
					ApplyHostStyle(btn, categoryData.scope)
				end

				self:SetupDeleteButtonVisibility(btn, btnData)

				btnData.buttonObj = btn
				table.insert(self.activeButtons, btn)

				currentCol = currentCol + 1
				if currentCol >= numColumns then
					currentCol = 0
					currentRow = currentRow + 1
				end
			end
		end
	end

	local rowsNeeded = math.ceil(buttonsPlaced / numColumns)
	local heightUsed = rowsNeeded * (slotSize + buttonSpacing)
	if rowsNeeded > 0 then
		heightUsed = heightUsed + (slotSize * 0.05)
	end
	return heightUsed
end

function B:ButtonHasContent(btnData)
	if not btnData then
		return false
	end
	return (btnData.dataType and btnData.data) or (btnData.actionType and btnData.actionValue)
end

function B:SetupDeleteButtonVisibility(btn, btnData)
	if not btn or not btn.Widget or not btn.deleteMeBtn then
		return
	end

	if self:ButtonHasContent(btnData) then
		btn.deleteMeBtn:Hide()
		return
	end

	if btn._fluxDeleteHooks then
		return
	end
	btn._fluxDeleteHooks = true

	btn.Widget:HookScript("OnEnter", function(widget)
		local owner = widget.FluxButton or btn
		local data = owner and owner.btnData
		local cursorType = GetCursorInfo()
		if cursorType then
			if owner and owner.deleteMeBtn then
				owner.deleteMeBtn:Hide()
			end
		elseif data and not B:ButtonHasContent(data) then
			if owner and owner.deleteMeBtn then
				owner.deleteMeBtn:Show()
			end
		end
	end)

	btn.Widget:HookScript("OnLeave", function(widget)
		local owner = widget.FluxButton or btn
		C_Timer.After(0.05, function()
			if owner and owner.deleteMeBtn and owner.Widget
				and not FrameMouseOver(owner.Widget) and not FrameMouseOver(owner.deleteMeBtn) then
				owner.deleteMeBtn:Hide()
			end
		end)
	end)
end

function B:UpdateDeleteButtonVisibility(btn, btnData)
	if not btn then
		return
	end

	if self:ButtonHasContent(btnData) then
		if btn.deleteMeBtn then
			btn.deleteMeBtn:Hide()
			btn.deleteMeBtn:SetParent(nil)
			btn.deleteMeBtn = nil
		end
		return
	end

	if not btn.deleteMeBtn then
		self:CreateDeleteButton(btn, btnData)
	end

	if not btn.deleteMeBtn then
		return
	end

	local cursorType = GetCursorInfo()
	if cursorType then
		btn.deleteMeBtn:Hide()
	else
		if FrameMouseOver(btn.Widget) or FrameMouseOver(btn.deleteMeBtn) then
			btn.deleteMeBtn:Show()
		else
			btn.deleteMeBtn:Hide()
		end
	end
end

function B:AddButtonToCategory(categoryData)
	if not categoryData then
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		return
	end

	local newButton = E:AddButtonToEntriesTable(categoryData)

	if E.Categories then
		E.Categories:RefreshCategories()
	end

	return newButton
end

E.Buttons = B
