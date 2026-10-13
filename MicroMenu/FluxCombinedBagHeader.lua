-- In-bag bag slots for Live and Forever.
-- Forever shows GamepadBagBar. Live does not reuse Blizzard's round bag
-- buttons; it draws its own square item slots. The item grid stays Blizzard's.
-- Forever's gamepad UI keeps Blizzard's bag untouched.
local addonName, ns = ...
local Flux = ns.Flux or _G.Flux

local SLOT_SCALE = 0.8
local ITEM_ANCHOR_X = 10
local ITEM_ANCHOR_Y = -65
-- Search sits at y=-37 (18px) and sort at y=-34 (26px). The slot row goes
-- under that line, and the item grid starts under the slot row.
local HEADER_BOTTOM = 60
local SLOT_GAP = 4
local SLOT_ROW_H = 36
local ITEM_GAP = 6
local ITEM_ANCHOR_Y_BELOW_SLOTS = -(HEADER_BOTTOM + SLOT_GAP + SLOT_ROW_H + ITEM_GAP)
local EXTRA_HEIGHT_FOR_SLOTS = ITEM_ANCHOR_Y - ITEM_ANCHOR_Y_BELOW_SLOTS
local ITEM_SPACING = 5
local BACKPACK_ICON = "Interface\\Buttons\\Button-Backpack-Up"
local EMPTY_SLOT = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"

-- Owned square slots. bagID nil is filled in for the reagent bag when that slot exists.
local LIVE_SLOTS = {
	{ kind = "backpack", w = 32, h = 32, bagID = 0 },
	{ kind = "bag", w = 36, h = 36, bagID = 1 },
	{ kind = "bag", w = 36, h = 36, bagID = 2 },
	{ kind = "bag", w = 36, h = 36, bagID = 3 },
	{ kind = "bag", w = 36, h = 36, bagID = 4 },
	{ kind = "bag", w = 36, h = 36, reagent = true },
	{ kind = "key", w = 14, h = 31 },
}

local function UsesAltBag()
	return _G.FluxUI_UsesAlternativeBagUI and _G.FluxUI_UsesAlternativeBagUI()
end

local function RetailHeaderClient()
	local client = Flux and Flux.Client
	if not client then
		return _G.ContainerFrameCombinedBags ~= nil or _G.GamepadBagBar ~= nil
	end
	if client.isEra or client.isAnniversary or client.isClassic then
		return false
	end
	return true
end

-- Blizzard's gamepad panels, bags and bindings end in the protected
-- SetPreferredGamepadInteractTarget(). Flux code inside them is blamed for it.
local function ForeverGamepadUI()
	local cap = Flux and Flux.Cap
	return cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() or false
end

local function Off()
	return UsesAltBag() or ForeverGamepadUI()
end

if not RetailHeaderClient() or Off() then
	return
end

local function Contains(list, value)
	for i = 1, #list do
		if list[i] == value then
			return true
		end
	end
	return false
end

-- Unequipping bag 1-4 hides the combined window even though the player left it
-- open. Blizzard lists the bag in checkReopenBags only when that window was
-- open, and CheckReopenBags skips a bag that now has no slots.
-- Post-hook only: replacing CloseBag runs Flux code inside every CloseAllBags,
-- including the ESC handler.
local reopenHooked = false
local function HookReopenAfterUnequip()
	local settings = _G.ContainerFrameSettingsManager
	if reopenHooked or not settings or type(settings.OnBagClosed) ~= "function" then
		return
	end
	reopenHooked = true
	hooksecurefunc(settings, "OnBagClosed", function(self, bagID, container)
		local backpack = (Enum and Enum.BagIndex and Enum.BagIndex.Backpack) or 0
		if Off() or bagID == nil or bagID == backpack then
			return
		end
		if not container or not container.IsCombinedBagContainer or not container:IsCombinedBagContainer() then
			return
		end
		local pending = self.checkReopenBags
		if type(pending) ~= "table" or not Contains(pending, bagID) then
			return
		end
		C_Timer.After(0, function()
			if Off() or container:IsShown() then
				return
			end
			if self.IsUsingCombinedBags and not self:IsUsingCombinedBags() then
				return
			end
			if _G.OpenBag then
				OpenBag(backpack)
			end
		end)
	end)
end
HookReopenAfterUnequip()

local function GamepadUIOn()
	return InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled()
end

local function CombinedBag()
	return _G.ContainerFrameCombinedBags
end

local header
local liveButtons
local layingOut = false

local function ReagentBagID()
	if _G.REAGENTBAG_CONTAINER then
		return REAGENTBAG_CONTAINER
	end
	if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
		return Enum.BagIndex.ReagentBag
	end
	if (_G.NUM_REAGENTBAG_SLOTS or 0) > 0 then
		return 5
	end
end

local function WantLiveSlot(info)
	if info.reagent then
		info.bagID = ReagentBagID()
		return info.bagID ~= nil and _G.CharacterReagentBag0Slot ~= nil
	end
	if info.kind == "key" then
		if not _G.KeyRingButton then
			return false
		end
		if _G.IsKeyRingEnabled and not IsKeyRingEnabled() then
			return false
		end
		return true
	end
	return true
end

local function InventoryIDForBag(bagID)
	if bagID == nil then
		return nil
	end
	if C_Container and C_Container.ContainerIDToInventoryID then
		return C_Container.ContainerIDToInventoryID(bagID)
	end
	if _G.ContainerIDToInventoryID then
		return ContainerIDToInventoryID(bagID)
	end
end

local function SetSlotIcon(button, texture)
	local icon = button.icon or button.Icon
	if icon and icon.SetTexture then
		if texture then
			icon:SetTexture(texture)
			icon:Show()
		else
			icon:SetTexture(EMPTY_SLOT)
			icon:Show()
		end
		return
	end
	if _G.SetItemButtonTexture then
		SetItemButtonTexture(button, texture)
	end
end

local function UpdateOwnedSlot(button)
	if not button then
		return
	end
	if button.kind == "backpack" then
		SetSlotIcon(button, BACKPACK_ICON)
		local count = button.Count
		if not count and button.CreateFontString then
			count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
			count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
			button.Count = count
		end
		if count and count.SetText then
			local free = 0
			if C_Container and C_Container.CalculateTotalNumberOfFreeBagSlots then
				free = C_Container.CalculateTotalNumberOfFreeBagSlots() or 0
			elseif C_Container and C_Container.GetContainerNumFreeSlots then
				free = C_Container.GetContainerNumFreeSlots(0) or 0
			end
			count:SetText(free)
			count:Show()
		end
		return
	end
	if button.kind == "key" then
		return
	end
	local inv = button.invID or InventoryIDForBag(button.bagID)
	button.invID = inv
	local texture = inv and GetInventoryItemTexture and GetInventoryItemTexture("player", inv)
	SetSlotIcon(button, texture)
	if button.togglesBag and button.openMark and button.openMark.SetShown then
		local open = _G.IsBagOpen and IsBagOpen(button.bagID)
		button.openMark:SetShown(open and true or false)
	end
end

local function HighlightCombinedBag(bagID, on)
	local bag = CombinedBag()
	if bag and bag.SetItemsMatchingBagHighlighted then
		bag:SetItemsMatchingBagHighlighted(bagID, on and true or false)
		return
	end
	if not bag or not bag.EnumerateValidItems then
		return
	end
	for _, item in bag:EnumerateValidItems() do
		if item and item.BagIndicator and item.GetBagID then
			item.BagIndicator:SetShown(on and item:GetBagID() == bagID)
		end
	end
end

local function ShowSlotTooltip(button)
	if not GameTooltip or not GameTooltip.SetOwner then
		return
	end
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	if button.kind == "backpack" then
		local title = _G.BACKPACK_TOOLTIP or "Backpack"
		GameTooltip:SetText(title, 1, 1, 1)
		local free = 0
		if C_Container and C_Container.CalculateTotalNumberOfFreeBagSlots then
			free = C_Container.CalculateTotalNumberOfFreeBagSlots() or 0
		end
		if _G.NUM_FREE_SLOTS then
			GameTooltip:AddLine(NUM_FREE_SLOTS:format(free), 1, 1, 1)
		end
	elseif button.bagID ~= nil and C_Container and C_Container.GetBagName then
		local name = C_Container.GetBagName(button.bagID)
		GameTooltip:SetText(name and name ~= "" and name or ("Bag " .. button.bagID), 1, 1, 1)
	elseif button.kind == "key" then
		GameTooltip:SetText(_G.KEYRING or "Keyring", 1, 1, 1)
	end
	GameTooltip:Show()
end

local function OnOwnedSlotClick(self)
	if self.kind == "backpack" then
		if _G.PutItemInBackpack then
			PutItemInBackpack()
		end
		return
	end
	if self.kind == "key" then
		if _G.CursorHasItem and CursorHasItem() and _G.PutKeyInKeyRing then
			PutKeyInKeyRing()
			return
		end
		local key = _G.KEYRING_CONTAINER
		if key and _G.ToggleBag then
			ToggleBag(key)
		end
		return
	end
	local inv = self.invID or InventoryIDForBag(self.bagID)
	self.invID = inv
	if not inv then
		return
	end
	if _G.PutItemInBag and PutItemInBag(inv) then
		UpdateOwnedSlot(self)
		return
	end
	if self.togglesBag and _G.ToggleBag then
		ToggleBag(self.bagID)
		UpdateOwnedSlot(self)
		return
	end
	if _G.PickupBagFromSlot then
		PickupBagFromSlot(inv)
	end
end

local function CreateSquareButton(parent)
	local ok, button = pcall(CreateFrame, "ItemButton", nil, parent)
	if ok and button then
		return button
	end
	button = CreateFrame("Button", nil, parent)
	button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", 4, -4)
	icon:SetPoint("BOTTOMRIGHT", -4, 4)
	button.icon = icon
	return button
end

local function CreateOwnedSlot(parent, info)
	local button
	if info.kind == "key" then
		button = CreateFrame("Button", nil, parent)
		button:SetNormalTexture("Interface\\Buttons\\UI-Button-KeyRing")
		button:SetHighlightTexture("Interface\\Buttons\\UI-Button-KeyRing-Highlight", "ADD")
		button:SetPushedTexture("Interface\\Buttons\\UI-Button-KeyRing-Down")
		local normal = button:GetNormalTexture()
		if normal and normal.SetTexCoord then
			normal:SetTexCoord(0, 0.5625, 0, 0.609375)
		end
		local highlight = button:GetHighlightTexture()
		if highlight and highlight.SetTexCoord then
			highlight:SetTexCoord(0, 0.5625, 0, 0.609375)
		end
		local pushed = button:GetPushedTexture()
		if pushed and pushed.SetTexCoord then
			pushed:SetTexCoord(0, 0.5625, 0, 0.609375)
		end
	else
		button = CreateSquareButton(parent)
	end
	button:SetSize(info.w, info.h)
	button.kind = info.kind
	button.bagID = info.bagID
	button.togglesBag = info.reagent and true or false
	button.invID = InventoryIDForBag(info.bagID)
	if info.reagent and not button.openMark then
		local mark = button:CreateTexture(nil, "OVERLAY")
		mark:SetAllPoints()
		mark:SetTexture("Interface\\Buttons\\CheckButtonHilight")
		mark:SetBlendMode("ADD")
		mark:Hide()
		button.openMark = mark
	end
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnClick", OnOwnedSlotClick)
	button:SetScript("OnDragStart", OnOwnedSlotClick)
	button:SetScript("OnReceiveDrag", OnOwnedSlotClick)
	button:SetScript("OnEnter", function(self)
		HighlightCombinedBag(self.bagID or 0, true)
		ShowSlotTooltip(self)
	end)
	button:SetScript("OnLeave", function(self)
		HighlightCombinedBag(self.bagID or 0, false)
		if GameTooltip and GameTooltip.Hide then
			GameTooltip:Hide()
		end
	end)
	UpdateOwnedSlot(button)
	return button
end

-- Close stays visible, so the row sits to its left instead of under it.
-- GetWidth can be a secret on Midnight; fall back rather than compare it raw.
local function HeaderOffset(bag)
	local close = bag and (bag.CloseButton or bag.Close)
	local width = 32
	if close and close.GetWidth then
		local ok, measured = pcall(function()
			local w = close:GetWidth()
			if type(w) == "number" and w > 1 then
				return w
			end
		end)
		if ok and type(measured) == "number" then
			width = measured
		end
	end
	return -(width + 6), -19
end

local function PlaceSlotRow(row, bag)
	row:ClearAllPoints()
	local sort = _G.BagItemAutoSortButton
	if sort and sort.IsShown and sort:IsShown() and not GamepadUIOn() then
		row:SetPoint("TOPRIGHT", sort, "BOTTOMRIGHT", 0, -SLOT_GAP)
		return
	end
	local ox, oy = HeaderOffset(bag)
	row:SetPoint("TOPRIGHT", bag, "TOPRIGHT", ox, oy)
end

local function LayoutLiveSlots()
	local bag = CombinedBag()
	if not bag or not header or layingOut or Off() then
		return
	end
	layingOut = true
	if header:GetParent() ~= bag then
		header:SetParent(bag)
	end
	PlaceSlotRow(header, bag)
	if bag.GetFrameLevel and header.SetFrameLevel then
		header:SetFrameLevel(bag:GetFrameLevel() + 8)
	end
	header:Show()

	if not liveButtons then
		liveButtons = {}
		for i = 1, #LIVE_SLOTS do
			local info = LIVE_SLOTS[i]
			if WantLiveSlot(info) then
				liveButtons[#liveButtons + 1] = CreateOwnedSlot(header, info)
			end
		end
	end

	local prev
	for i = 1, #liveButtons do
		local button = liveButtons[i]
		if header.GetFrameLevel and button.SetFrameLevel then
			button:SetFrameLevel(header:GetFrameLevel() + 5)
		end
		button:ClearAllPoints()
		if not prev then
			button:SetPoint("RIGHT", header, "RIGHT", 0, 0)
		else
			button:SetPoint("RIGHT", prev, "LEFT", 0, 0)
		end
		UpdateOwnedSlot(button)
		button:Show()
		prev = button
	end
	layingOut = false
end

local function EnsureLiveHeader(bag)
	if header or _G.GamepadBagBar then
		return
	end
	header = CreateFrame("Frame", "FluxCombinedBagHeader", bag)
	header:SetSize(4, 40)
	function header:Layout()
		LayoutLiveSlots()
	end
	LayoutLiveSlots()
end

local function ShowCloseButton(bag)
	local close = bag and (bag.CloseButton or bag.Close)
	if close and close.Show then
		close:Show()
		if close.SetAlpha then
			close:SetAlpha(1)
		end
	end
end

local function RaiseAboveSlots(frame, bag)
	if not frame or not frame.SetFrameLevel or not bag or not bag.GetFrameLevel then
		return
	end
	frame:SetFrameLevel(bag:GetFrameLevel() + 40)
end

local function SearchChromeShown()
	if GamepadUIOn() then
		return false
	end
	local sort = _G.BagItemAutoSortButton
	return sort and sort.IsShown and sort:IsShown()
end

-- Blizzard draws search and sort on the header line. Keep them shown and
-- clickable; the slot row is placed under that line instead of on top of it.
local function ShowSearchChrome(bag)
	if not bag or GamepadUIOn() then
		return
	end
	local search = _G.BagItemSearchBox
	if search then
		search:SetParent(bag)
		search:ClearAllPoints()
		if bag.SetSearchBoxPoint then
			bag:SetSearchBoxPoint(search)
		else
			search:SetPoint("TOPLEFT", bag, "TOPLEFT", 62, -37)
			if search.SetWidth then
				search:SetWidth(330)
			end
		end
		search.anchorBag = bag
		search:Show()
		RaiseAboveSlots(search, bag)
	end
	local sort = _G.BagItemAutoSortButton
	if sort then
		sort:SetParent(bag)
		sort:ClearAllPoints()
		sort:SetPoint("TOPRIGHT", bag, "TOPRIGHT", -9, -34)
		sort:Show()
		RaiseAboveSlots(sort, bag)
	end
end

local HIGHLIGHT_FILE = "Interface\\Buttons\\ButtonHilight-Square"

local function FitSlotHighlight(button)
	local tex = button and button.SlotHighlightTexture
	if not tex or not tex.SetAllPoints then
		return
	end
	if tex.SetTexture then
		tex:SetTexture(HIGHLIGHT_FILE)
	end
	if tex.SetBlendMode then
		tex:SetBlendMode("ADD")
	end
	if tex.SetAlpha then
		tex:SetAlpha(0.35)
	end
	tex:ClearAllPoints()
	tex:SetAllPoints(button)
end

local function HookHighlightFit(button)
	if not button or button.FluxHighlightFit or not button.UpdateTextures then
		return
	end
	button.FluxHighlightFit = true
	hooksecurefunc(button, "UpdateTextures", FitSlotHighlight)
end

local function GamepadSlotBagID(button)
	if not button then
		return nil
	end
	if button.IsBackpack and button:IsBackpack() then
		return 0
	end
	if button.GetName and button:GetName() == "GamepadBackpackButton" then
		return 0
	end
	if button.GetBagID then
		return button:GetBagID()
	end
end

local function HighlightGamepadBag(button, on)
	if Off() then
		return
	end
	local bag = CombinedBag()
	local bagID = GamepadSlotBagID(button)
	if not bag or bagID == nil or not bag.SetItemsMatchingBagHighlighted then
		return
	end
	bag:SetItemsMatchingBagHighlighted(bagID, on and true or false)
end

local function UncoverGamepadSlot(button)
	local drop = button and button.BagDropdownButton
	if not drop then
		return
	end
	-- This control is 50x40 on the top of the slot. It eats hover, so only the
	-- bottom edge of the backpack reaches the button.
	if drop.EnableMouse then
		drop:EnableMouse(false)
	end
	drop:SetSize(1, 1)
end

local function HookGamepadSlotHover(button)
	if not button or button.FluxGamepadHover or not button.HookScript then
		return
	end
	button.FluxGamepadHover = true
	button:HookScript("OnEnter", function(self)
		HighlightGamepadBag(self, true)
	end)
	button:HookScript("OnLeave", function(self)
		HighlightGamepadBag(self, false)
	end)
end

-- Gamepad backpack is 40px while the other slots are 45px, and its frame art
-- is 46px pinned to the top-left, so the icon and border sit off the row.
-- Match the neighbor slot's size and let UpdateTextures place the art.
local function ShowGamepadFreeCount(bar)
	if Off() then
		return
	end
	local backpack = bar and (bar.BackpackButton or _G.GamepadBackpackButton)
	if not backpack then
		return
	end
	-- Forever draws the free-slot total on FreeSlots, centered, and hides it
	-- unless displayFreeBagSlots is on. The centered icon covers that point.
	local count = backpack.FreeSlots or backpack.Count
	if not count then
		return
	end
	local free = 0
	if C_Container and C_Container.CalculateTotalNumberOfFreeBagSlots then
		free = C_Container.CalculateTotalNumberOfFreeBagSlots() or 0
	end
	count:SetText(string.format("(%s)", free))
	if count.SetDrawLayer then
		count:SetDrawLayer("OVERLAY", 7)
	end
	count:ClearAllPoints()
	count:SetPoint("BOTTOMRIGHT", backpack, "BOTTOMRIGHT", -2, 2)
	count:Show()
end

if hooksecurefunc and _G.GamepadBackpackButton and GamepadBackpackButton.UpdateFreeSlots then
	hooksecurefunc(GamepadBackpackButton, "UpdateFreeSlots", function(self)
		ShowGamepadFreeCount(self:GetParent())
	end)
end

local function MatchBackpackToSlots(bar)
	local backpack = bar.BackpackButton or _G.GamepadBackpackButton
	local sample = bar.Bag0SlotButton
	if not backpack or backpack.FluxSizeMatched then
		return
	end
	local width, height = 45, 45
	if sample then
		local ok, w, h = pcall(function()
			return sample:GetWidth(), sample:GetHeight()
		end)
		if ok and type(w) == "number" and w > 1 and type(h) == "number" and h > 1 then
			width, height = w, h
		end
	end
	backpack:SetSize(width, height)
	local icon = backpack.icon
	local sampleIcon = sample and sample.icon
	if icon then
		local iconW, iconH = width - 8, height - 8
		if sampleIcon then
			local measured, iw, ih = pcall(function()
				return sampleIcon:GetWidth(), sampleIcon:GetHeight()
			end)
			if measured and type(iw) == "number" and iw > 1 and type(ih) == "number" and ih > 1 then
				iconW, iconH = iw, ih
			end
		end
		icon:ClearAllPoints()
		icon:SetSize(iconW, iconH)
		icon:SetPoint("CENTER", backpack, "CENTER", 0, 0)
	end
	if backpack.UpdateTextures then
		backpack:UpdateTextures()
	end
	backpack.FluxSizeMatched = true
	FitSlotHighlight(backpack)
	ShowGamepadFreeCount(bar)
end

local function FitGamepadHighlights(bar)
	if not bar then
		return
	end
	if bar.BagButtonArray then
		for _, button in ipairs(bar.BagButtonArray) do
			FitSlotHighlight(button)
			HookHighlightFit(button)
			HookGamepadSlotHover(button)
			UncoverGamepadSlot(button)
		end
	end
	if bar.GetChildren then
		for _, child in ipairs({ bar:GetChildren() }) do
			if child and child.SlotHighlightTexture then
				FitSlotHighlight(child)
				HookHighlightFit(child)
				HookGamepadSlotHover(child)
				UncoverGamepadSlot(child)
			end
		end
	end
	MatchBackpackToSlots(bar)
end

local function GamepadBarPlaced(bar, bag)
	if not bar.FluxBarPlaced or bar:GetParent() ~= bag then
		return false
	end
	local ok, scale = pcall(bar.GetScale, bar)
	return ok and type(scale) == "number" and math.abs(scale - SLOT_SCALE) < 0.02
end

local function ApplyGamepadBar(bag)
	local bar = _G.GamepadBagBar
	if not bar then
		return false
	end
	if not GamepadBarPlaced(bar, bag) then
		if bar.SetParent and bar:GetParent() ~= bag then
			bar:SetParent(bag)
		end
		-- Scale first, then pin TOPRIGHT. Scaling after the point slides the
		-- 40px backpack off the 45px slots.
		bar:SetScale(SLOT_SCALE)
		PlaceSlotRow(bar, bag)
		bar.FluxBarPlaced = true
	end
	if bag.GetFrameLevel and bar.SetFrameLevel then
		bar:SetFrameLevel(bag:GetFrameLevel() + 8)
	end
	FitGamepadHighlights(bar)
	ShowGamepadFreeCount(bar)
	bar:Show()
	return true
end

local function ApplyHeader(bag)
	bag = bag or CombinedBag()
	if not bag or Off() then
		return
	end
	if bag.IsCombinedBagContainer and not bag:IsCombinedBagContainer() then
		return
	end
	ShowSearchChrome(bag)
	ShowCloseButton(bag)
	if ApplyGamepadBar(bag) then
		if header and header.Hide then
			header:Hide()
		end
	else
		EnsureLiveHeader(bag)
		LayoutLiveSlots()
	end
	if not bag.FluxSizingBag and bag.UpdateFrameSize and SearchChromeShown() then
		bag.FluxSizingBag = true
		pcall(bag.UpdateFrameSize, bag)
		bag.FluxSizingBag = false
	end
end

local function SlotOrder(button)
	local bagID = 0
	local slot = 0
	if button.GetBagID then
		bagID = tonumber(button:GetBagID()) or 0
	end
	if button.GetID then
		slot = tonumber(button:GetID()) or 0
	end
	return bagID, slot
end

local function CollectCombinedItems(bag)
	local items = {}
	local list = bag.Items
	local count = list and #list or 0
	local sized = bag.GetBagSize and bag:GetBagSize() or 0
	if type(sized) == "number" and sized > count then
		count = sized
	end
	-- Combined bags store the backpack at the end. GetBagSize can stop
	-- before those buttons, so they never land in the grid.
	if list and count > 0 then
		for i = 1, count do
			local button = list[i]
			if button then
				if button.Show then
					button:Show()
				end
				items[#items + 1] = button
			end
		end
	end
	if #items == 0 and bag.EnumerateValidItems then
		pcall(function()
			for _, button in bag:EnumerateValidItems() do
				if button then
					if button.Show then
						button:Show()
					end
					items[#items + 1] = button
				end
			end
		end)
	end
	table.sort(items, function(a, b)
		local bagA, slotA = SlotOrder(a)
		local bagB, slotB = SlotOrder(b)
		if bagA ~= bagB then
			return bagA < bagB
		end
		return slotA < slotB
	end)
	return items
end

local function FitGridHeight(bag, rows, itemSize, anchorY)
	local grid = rows * (itemSize + ITEM_SPACING)
	local moneyH = 28
	local money = bag.MoneyFrame
	if money and money.GetHeight then
		local ok, h = pcall(money.GetHeight, money)
		if ok and type(h) == "number" and h > 1 then
			moneyH = h
		end
	end
	local needed = -anchorY + grid + moneyH + 20
	local height = bag.GetHeight and bag:GetHeight() or 0
	if type(height) == "number" and needed > height + 1 and bag.SetHeight then
		bag.FluxAddingSlotRowHeight = true
		bag:SetHeight(needed)
		bag.FluxAddingSlotRowHeight = false
	end
end

local function ApplyItemAnchor(bag)
	if not bag or Off() then
		return
	end
	if bag.IsCombinedBagContainer and not bag:IsCombinedBagContainer() then
		return
	end
	local items = CollectCombinedItems(bag)
	if #items == 0 then
		return
	end
	local columns = 10
	if bag.GetColumns then
		columns = bag:GetColumns() or columns
	end
	local anchorY = SearchChromeShown() and ITEM_ANCHOR_Y_BELOW_SLOTS or ITEM_ANCHOR_Y
	local size = 37
	pcall(function()
		local w = items[1]:GetWidth()
		if type(w) == "number" and w > 1 then
			size = w
		end
	end)
	for i = 1, #items do
		local button = items[i]
		local col = (i - 1) % columns
		local row = math.floor((i - 1) / columns)
		button:ClearAllPoints()
		button:SetPoint(
			"TOPLEFT",
			bag,
			"TOPLEFT",
			ITEM_ANCHOR_X + col * (size + ITEM_SPACING),
			anchorY - row * (size + ITEM_SPACING)
		)
	end
	FitGridHeight(bag, math.ceil(#items / columns), size, anchorY)
	if bag.LayoutAddSlots then
		pcall(bag.LayoutAddSlots, bag)
	end
end

_G.FluxRefreshInBagSlots = function()
	if Off() then
		return
	end
	local bag = CombinedBag()
	if bag and bag.IsShown and bag:IsShown() then
		ApplyHeader(bag)
	end
end

local hooked = false

local function SafeHook(obj, method, fn)
	if not obj or type(obj[method]) ~= "function" then
		return false
	end
	return pcall(hooksecurefunc, obj, method, fn)
end

-- Methods often live on the mixin, not the frame. Hook the frame when that
-- works, otherwise the mixin, so a failed hook does not abort the file.
local function HookMethod(bag, method, fn)
	if SafeHook(bag, method, fn) then
		return
	end
	if not SafeHook(_G.ContainerFrameCombinedBagsMixin, method, fn) then
		SafeHook(_G.ContainerFrameMixin, method, fn)
	end
end

local function HookCombined(bag)
	if hooked or not bag then
		return
	end
	hooked = true
	HookMethod(bag, "OnBagSlotEnter", function(self, bagSlot)
		if Off() then
			return
		end
		local gamepadBar = _G.GamepadBagBar
		if not gamepadBar or not bagSlot or not bagSlot.GetParent or not bagSlot.GetBagID then
			return
		end
		if bagSlot:GetParent() ~= gamepadBar then
			return
		end
		if self.SetItemsMatchingBagHighlighted then
			local bagID = GamepadSlotBagID(bagSlot)
			if bagID ~= nil then
				self:SetItemsMatchingBagHighlighted(bagID, true)
			end
		end
	end)
	HookMethod(bag, "UpdateSearchBox", function(self)
		ApplyHeader(self)
	end)
	HookMethod(bag, "UpdateItemLayout", function(self)
		ApplyHeader(self)
		ApplyItemAnchor(self)
	end)
	HookMethod(bag, "UpdateFrameSize", function(self)
		if Off() or not self or not self.IsCombinedBagContainer or not self:IsCombinedBagContainer() then
			return
		end
		if not SearchChromeShown() or self.FluxAddingSlotRowHeight then
			return
		end
		self.FluxAddingSlotRowHeight = true
		pcall(function()
			local height = self:GetHeight()
			if type(height) == "number" and height > 1 then
				self:SetHeight(height + EXTRA_HEIGHT_FOR_SLOTS)
			end
		end)
		self.FluxAddingSlotRowHeight = false
	end)
	if bag.HookScript then
		bag:HookScript("OnShow", function(self)
			if Off() then
				return
			end
			ApplyHeader(self)
			ApplyItemAnchor(self)
			if _G.FluxGoldLedger and FluxGoldLedger.AttachBagMoneyTooltip then
				FluxGoldLedger:AttachBagMoneyTooltip(self.MoneyFrame)
			end
		end)
	end
	if bag.IsShown and bag:IsShown() and not Off() then
		ApplyHeader(bag)
		ApplyItemAnchor(bag)
		if _G.FluxGoldLedger and FluxGoldLedger.AttachBagMoneyTooltip then
			FluxGoldLedger:AttachBagMoneyTooltip(bag.MoneyFrame)
		end
	end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("BAG_UPDATE")
watcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
watcher:SetScript("OnEvent", function(_, event)
	if Off() then
		return
	end
	if event == "BAG_UPDATE" or event == "PLAYER_EQUIPMENT_CHANGED" then
		if liveButtons then
			for i = 1, #liveButtons do
				UpdateOwnedSlot(liveButtons[i])
			end
		end
		ShowGamepadFreeCount(_G.GamepadBagBar)
		return
	end
	HookReopenAfterUnequip()
	HookCombined(CombinedBag())
end)
HookCombined(CombinedBag())
