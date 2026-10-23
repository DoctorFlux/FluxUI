-- Era / Anniversary combined backpack.
-- Those clients have no ContainerFrameCombinedBags. This window reuses each
-- player bag's item buttons (so clicks, tooltips, and cooldowns stay Blizzard's)
-- and lays them out like the Forever gamepad combined bag. Bank frames are not taken.
local addonName, ns = ...
local Flux = ns.Flux or _G.Flux

local client = Flux and Flux.Client
if not client or not (client.isEra or client.isAnniversary) then
	return
end

local function UsesAltBag()
	if _G.FluxUI_UsesAlternativeBagUI and _G.FluxUI_UsesAlternativeBagUI() then
		return true
	end
	if _G.Bagnon or _G.Bagnonium then
		return true
	end
	local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
	if loaded then
		local ok, on = pcall(loaded, "Baganator")
		if ok and on then
			return true
		end
	end
	return _G.Baganator and _G.Baganator.API ~= nil
end

if UsesAltBag() then
	return
end

local COLUMNS = 10
local ITEM = 37
local GAP = 5
local LEFT = 10
local TOP = -106
local WIDTH = COLUMNS * ITEM + (COLUMNS - 1) * GAP + 15
local BOTTOM_PAD = 36
local HEADER = 106

-- Forever's bag is a neutral silver frame on a dark flat panel. These are that
-- look, not the FluxUI accent from options.
local FOREVER_BORDER_R, FOREVER_BORDER_G, FOREVER_BORDER_B = 1, 1, 1
local FOREVER_PANEL_R, FOREVER_PANEL_G, FOREVER_PANEL_B, FOREVER_PANEL_A = 0.14, 0.14, 0.15, 0.96
local BACKPACK_ICON = "Interface\\Icons\\INV_Misc_Bag_08"

local function SeatFluxBorder(frame, borderLevel, fillLevel)
	local border = frame.FluxBorderFrame
	if not border then
		return
	end
	local strata = frame.GetFrameStrata and frame:GetFrameStrata() or "HIGH"
	border:SetFrameStrata(strata)
	border:SetFrameLevel(borderLevel)
	local fill = border.BackgroundFrame
	if fill then
		fill:SetFrameStrata(strata)
		fill:SetFrameLevel(fillLevel)
	end
end

local EnsureEdgeStrips

local function ApplyWindowChrome(frame)
	local Border = _G.FluxBorder
	if not frame or not Border or not Border.ApplyTo then
		return
	end
	if frame.FluxBorderFrame and Border.RemoveFrom then
		Border:RemoveFrom(frame)
	end
	-- Same inset the grids use: the fill expands under the border instead of
	-- stopping on the empty inner corner of the art.
	Border:ApplyTo(frame, -4, -4, -5, -4)
	if not frame.FluxBorderFrame then
		return
	end
	Border:SetBorderColor(frame, FOREVER_BORDER_R, FOREVER_BORDER_G, FOREVER_BORDER_B, 1)
	Border:SetBackdropColor(frame, FOREVER_PANEL_R, FOREVER_PANEL_G, FOREVER_PANEL_B, FOREVER_PANEL_A)
	local level = frame.GetFrameLevel and frame:GetFrameLevel() or 1
	SeatFluxBorder(frame, level + 8, level + 1)
	local fill = frame.FluxBorderFrame and frame.FluxBorderFrame.BackgroundFrame
	if fill then
		-- Left, right, and bottom stay on the border. The top inset was
		-- 4px above the frame, past the top edge.
		fill:ClearAllPoints()
		fill:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 0)
		fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 5, -4)
	end
	EnsureEdgeStrips(frame)
end

local function PaintEdgeStrip(strip)
	local Border = _G.FluxBorder
	if not strip or not Border or not Border.ApplyTo or strip.FluxBorderFrame then
		return
	end
	Border:ApplyTo(strip, -2, -2, -3, -2)
	Border:SetBorderColor(strip, FOREVER_BORDER_R, FOREVER_BORDER_G, FOREVER_BORDER_B, 1)
	Border:SetBackdropColor(strip, FOREVER_PANEL_R, FOREVER_PANEL_G, FOREVER_PANEL_B, FOREVER_PANEL_A)
	local level = strip:GetFrameLevel() or 1
	SeatFluxBorder(strip, level + 4, level + 1)
end

function EnsureEdgeStrips(frame)
	local level = frame:GetFrameLevel()
	-- Window border outer edge, with the same -4 pad ApplyWindowChrome uses.
	-- The strip frame is inset so its own Flux border lands on that same line.
	if not frame.FluxTopStrip then
		local top = CreateFrame("Frame", nil, frame)
		top:SetHeight(26)
		frame.FluxTopStrip = top
	end
	if not frame.FluxGoldStrip then
		local gold = CreateFrame("Frame", nil, frame)
		gold:SetHeight(24)
		frame.FluxGoldStrip = gold
	end
	local top = frame.FluxTopStrip
	top:ClearAllPoints()
	top:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 0)
	top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 0)
	top:SetFrameLevel(level + 2)
	local gold = frame.FluxGoldStrip
	gold:ClearAllPoints()
	-- Same left-to-right span as the window border (pad -4 plus the corner offsets).
	gold:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -2, -2)
	gold:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
	gold:SetFrameLevel(level + 2)
	PaintEdgeStrip(top)
	PaintEdgeStrip(gold)
	if gold.FluxBorderFrame then
		gold.FluxBorderFrame:SetFrameLevel(level + 4)
		local goldFill = gold.FluxBorderFrame.BackgroundFrame
		if goldFill then
			goldFill:SetFrameLevel(level + 3)
		end
	end
	local topFill = top.FluxBorderFrame and top.FluxBorderFrame.BackgroundFrame
	if topFill then
		topFill:ClearAllPoints()
		topFill:SetPoint("TOPLEFT", top, "TOPLEFT", -3, 0)
		topFill:SetPoint("BOTTOMRIGHT", top, "BOTTOMRIGHT", 3, -2)
	end
	-- Window border stays above both bars, including the gold bar's right end.
	-- The backpack icon sits above that border so the corner does not cover it.
	local windowBorder = frame.FluxBorderFrame
	if windowBorder then
		windowBorder:SetFrameLevel(level + 30)
	end
	local portrait = frame.PortraitContainer
	if portrait and portrait.SetFrameLevel then
		portrait:SetFrameLevel(level + 40)
	end
	local title = frame.TitleContainer
	if title and top then
		title:SetParent(top)
		title:ClearAllPoints()
		title:SetAllPoints(top)
		title:SetFrameLevel(top:GetFrameLevel() + 8)
	end
end

local function PaintPortrait(frame)
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetSize(58, 58)
	holder:SetPoint("TOPLEFT", frame, "TOPLEFT", -15, 15)
	holder:SetFrameLevel(frame:GetFrameLevel() + 40)
	local portrait = holder:CreateTexture(nil, "ARTWORK")
	portrait:SetSize(54, 54)
	portrait:SetPoint("CENTER", holder, "CENTER", 0, 0)
	portrait:SetTexture(BACKPACK_ICON)
	if holder.CreateMaskTexture then
		pcall(function()
			local mask = holder:CreateMaskTexture()
			mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
			mask:SetSize(42, 42)
			mask:SetPoint("CENTER", portrait, "CENTER", 0, 0)
			portrait:AddMaskTexture(mask)
		end)
	end
	frame.PortraitContainer = holder
	frame.portrait = portrait
	function frame:SetPortraitToAsset(texture)
		if self.portrait and self.portrait.SetTexture then
			self.portrait:SetTexture(texture)
		end
	end
	local function Ring()
		local Border = _G.FluxBorder
		if not Border or not Border.ApplyCircle or frame.FluxPortraitRing then
			return
		end
		frame.FluxPortraitRing = Border:ApplyCircle(holder, 58, FOREVER_BORDER_R, FOREVER_BORDER_G, FOREVER_BORDER_B)
	end
	Ring()
	holder:SetScript("OnShow", Ring)
end

local function PaintTitle(frame)
	local title = CreateFrame("Frame", nil, frame)
	title:SetHeight(20)
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", 48, -2)
	title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -2)
	title:SetFrameLevel(frame:GetFrameLevel() + 12)
	local text = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOP", title, "TOP", 0, -2)
	text:SetPoint("LEFT", title, "LEFT", 0, 0)
	text:SetPoint("RIGHT", title, "RIGHT", 0, 0)
	text:SetJustifyH("CENTER")
	text:SetWordWrap(false)
	text:SetText(_G.BACKPACK_TOOLTIP or "Backpack")
	frame.TitleContainer = title
	frame.TitleText = text
	function frame:SetTitle(name)
		if self.TitleText and self.TitleText.SetText then
			self.TitleText:SetText(name)
		end
	end
end

local function PaintCloseButton(frame)
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 4)
	close:SetFrameLevel(frame:GetFrameLevel() + 20)
	frame.CloseButton = close
end

local combined = CreateFrame("Frame", "FluxCombinedBags", UIParent)
combined:Hide()
combined:SetSize(WIDTH, 200)
combined:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 80)
combined:SetClampedToScreen(true)
combined:EnableMouse(true)
combined:SetMovable(true)
combined:SetToplevel(true)
if combined.SetFrameStrata then
	combined:SetFrameStrata("HIGH")
end
combined:RegisterForDrag("LeftButton")
combined:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)
combined:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
end)

PaintPortrait(combined)
PaintTitle(combined)
PaintCloseButton(combined)
ApplyWindowChrome(combined)

if _G.UISpecialFrames then
	local listed = false
	for i = 1, #UISpecialFrames do
		if UISpecialFrames[i] == "FluxCombinedBags" then
			listed = true
			break
		end
	end
	if not listed then
		table.insert(UISpecialFrames, "FluxCombinedBags")
	end
end

local slotRow = CreateFrame("Frame", nil, combined)
slotRow:SetSize(4, 40)
slotRow:SetFrameLevel(600)

local hosts = {}
local ghosted = {}
local busy = false
local closing = false
local layingSlots = false
local refreshing = false
local releasing = false
local SetChatDragHold
local StopFastSort

local origToggleAllBags, origToggleBackpack, origToggleBag
local origOpenAllBags, origOpenBag, origOpenBackpack
local origCloseAllBags, origCloseBag, origCloseBackpack

local function ShouldOwn()
	if closing then
		return false
	end
	return not UsesAltBag()
end

local function BagCount()
	return _G.NUM_BAG_FRAMES or _G.NUM_BAG_SLOTS or 4
end

local CONTAINER_CLASS = (Enum and Enum.ItemClass and Enum.ItemClass.Container) or 1
local QUIVER_CLASS = (Enum and Enum.ItemClass and Enum.ItemClass.Quiver) or 11

local function IsSpecialtyBag(bagID)
	if type(bagID) ~= "number" then
		return false
	end
	local key = _G.KEYRING_CONTAINER
	if key ~= nil and bagID == key then
		return true
	end
	if bagID <= 0 or bagID > BagCount() then
		return false
	end
	if _G.IsInventoryItemProfessionBag and C_Container and C_Container.ContainerIDToInventoryID then
		local inv = C_Container.ContainerIDToInventoryID(bagID)
		local ok, prof = pcall(IsInventoryItemProfessionBag, "player", inv)
		if ok and prof then
			return true
		end
	end
	if not GetInventoryItemLink or not C_Container or not C_Container.ContainerIDToInventoryID then
		return false
	end
	local inv = C_Container.ContainerIDToInventoryID(bagID)
	local link = inv and GetInventoryItemLink("player", inv)
	if not link then
		return false
	end
	local instant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
	if not instant then
		return false
	end
	local info = { instant(link) }
	local classID, subClassID = info[6], info[7]
	if classID == QUIVER_CLASS then
		return true
	end
	if classID == CONTAINER_CLASS and type(subClassID) == "number" and subClassID > 0 then
		return true
	end
	return false
end

-- Backpack and plain bags share one window. Quivers, ammo pouches, reagent
-- bags, and the keyring keep Blizzard's own bag frame.
local function IsCombinedBagID(id)
	if id == 0 then
		return true
	end
	local n = BagCount()
	if type(id) ~= "number" or id < 1 or id > n then
		return false
	end
	return not IsSpecialtyBag(id)
end

local function KeyringActive()
	local id = _G.KEYRING_CONTAINER
	if id == nil then
		return false
	end
	if _G.IsKeyRingEnabled and not IsKeyRingEnabled() then
		return false
	end
	if C_Container and C_Container.GetContainerNumSlots then
		return (C_Container.GetContainerNumSlots(id) or 0) > 0
	end
	return _G.KeyRingButton ~= nil
end

local function OwningOpen()
	return busy or (combined:IsShown() and not closing)
end

local function RightInset()
	local close = combined.CloseButton
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

local ownedSlots

local CLASSIC_SLOTS = {
	{ kind = "backpack", w = 37, h = 37, bagID = 0 },
	{ kind = "bag", w = 37, h = 37, bagID = 1 },
	{ kind = "bag", w = 37, h = 37, bagID = 2 },
	{ kind = "bag", w = 37, h = 37, bagID = 3 },
	{ kind = "bag", w = 37, h = 37, bagID = 4 },
	{ kind = "key", w = 18, h = 39 },
}

local function InventoryIDForBag(bagID)
	if bagID == nil or bagID < 0 then
		return nil
	end
	if C_Container and C_Container.ContainerIDToInventoryID then
		return C_Container.ContainerIDToInventoryID(bagID)
	end
	if _G.ContainerIDToInventoryID then
		return ContainerIDToInventoryID(bagID)
	end
end

local function HighlightBagItems(bagID, on)
	for button, host in pairs(hosts) do
		if button and host and button.CreateTexture then
			local glow = button.FluxBagHighlight
			if not glow then
				glow = button:CreateTexture(nil, "OVERLAY")
				glow:SetAllPoints()
				glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
				glow:SetBlendMode("ADD")
				button.FluxBagHighlight = glow
			end
			glow:SetShown(on and host.GetID and host:GetID() == bagID)
		end
	end
end

local function FreeBagSlots()
	if Flux.Container and Flux.Container.GetTotalFreeBagSlots then
		return Flux.Container.GetTotalFreeBagSlots()
	end
	if C_Container and C_Container.CalculateTotalNumberOfFreeBagSlots then
		return C_Container.CalculateTotalNumberOfFreeBagSlots() or 0
	end
	local total = 0
	if not (C_Container and C_Container.GetContainerNumFreeSlots) then
		return total
	end
	total = C_Container.GetContainerNumFreeSlots(0) or 0
	for i = 1, BagCount() do
		if IsCombinedBagID(i) then
			total = total + (C_Container.GetContainerNumFreeSlots(i) or 0)
		end
	end
	return total
end

-- Classic bag buttons take this from GetInventorySlotInfo("Bag0Slot").
-- UI-Backpack-EmptySlot is a faint backpack watermark and vanishes on the panel.
local EMPTY_BAG_ICON = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag"

local function EmptyBagSlotTexture(bagID)
	local index = (bagID or 1) - 1
	if index < 0 then
		index = 0
	end
	local blizz = _G["CharacterBag" .. index .. "Slot"]
	local stored = blizz and blizz.backgroundTextureName
	if stored and stored ~= "" then
		return stored
	end
	if _G.GetInventorySlotInfo then
		local _, texture = GetInventorySlotInfo("Bag" .. index .. "Slot")
		if texture and texture ~= "" then
			return texture
		end
	end
	return EMPTY_BAG_ICON
end

local function PaintSlotIcon(icon, texture)
	if not icon then
		return
	end
	icon:SetTexture(texture)
	icon:SetTexCoord(0, 1, 0, 1)
	icon:SetVertexColor(1, 1, 1, 1)
	icon:SetAlpha(1)
	icon:SetBlendMode("BLEND")
	if icon.SetDesaturated then
		icon:SetDesaturated(false)
	end
	icon:Show()
end

local function UpdateOwnedSlot(button)
	if not button then
		return
	end
	if button.kind == "backpack" then
		PaintSlotIcon(button.icon, BACKPACK_ICON)
		if button.count then
			button.count:SetText(FreeBagSlots())
			button.count:Show()
		end
		return
	end
	if button.kind == "key" then
		if button.openMark then
			local key = _G.KEYRING_CONTAINER
			local open = key and _G.IsBagOpen and IsBagOpen(key)
			button.openMark:SetShown(open and true or false)
		end
		return
	end
	local inv = InventoryIDForBag(button.bagID)
	button.invID = inv
	local texture = inv and GetInventoryItemTexture and GetInventoryItemTexture("player", inv)
	local empty = not texture or texture == ""
	PaintSlotIcon(button.icon, empty and EmptyBagSlotTexture(button.bagID) or texture)
	if button.plate then
		button.plate:SetShown(empty)
	end
	if button.openMark then
		local open = IsSpecialtyBag(button.bagID) and _G.IsBagOpen and IsBagOpen(button.bagID)
		button.openMark:SetShown(open and true or false)
	end
end

local function ShowOwnedTooltip(button)
	if not GameTooltip or not GameTooltip.SetOwner then
		return
	end
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	if button.kind == "backpack" then
		if _G.GameTooltip_SetTitle then
			GameTooltip_SetTitle(GameTooltip, _G.BACKPACK_TOOLTIP or "Backpack")
		else
			GameTooltip:SetText(_G.BACKPACK_TOOLTIP or "Backpack", 1, 1, 1)
		end
		if _G.NUM_FREE_SLOTS then
			GameTooltip:AddLine(NUM_FREE_SLOTS:format(FreeBagSlots()), 1, 1, 1)
		end
		GameTooltip:Show()
		return
	end
	if button.kind == "key" then
		if _G.GameTooltip_SetTitle then
			GameTooltip_SetTitle(GameTooltip, _G.KEYRING or "Keyring")
		else
			GameTooltip:SetText(_G.KEYRING or "Keyring", 1, 1, 1)
		end
		GameTooltip:Show()
		return
	end
	local inv = button.invID or InventoryIDForBag(button.bagID)
	button.invID = inv
	if inv and GameTooltip.SetInventoryItem and GameTooltip:SetInventoryItem("player", inv) then
		GameTooltip:Show()
		return
	end
	local title = _G.EQUIP_CONTAINER or "Equip Container"
	if _G.GameTooltip_SetTitle then
		GameTooltip:SetOwner(button, "ANCHOR_LEFT")
		GameTooltip_SetTitle(GameTooltip, title)
	else
		GameTooltip:SetText(title, 1, 1, 1)
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
		UpdateOwnedSlot(self)
		return
	end
	local inv = self.invID or InventoryIDForBag(self.bagID)
	self.invID = inv
	if inv and _G.PutItemInBag and PutItemInBag(inv) then
		UpdateOwnedSlot(self)
		return
	end
	if IsSpecialtyBag(self.bagID) and _G.ToggleBag then
		ToggleBag(self.bagID)
		UpdateOwnedSlot(self)
	end
end

local function OnOwnedSlotDrag(self)
	if self.kind ~= "bag" then
		return
	end
	local inv = self.invID or InventoryIDForBag(self.bagID)
	self.invID = inv
	if inv and _G.PickupBagFromSlot then
		PickupBagFromSlot(inv)
	end
end

local function CreateOwnedSlot(info)
	local button = CreateFrame("Button", nil, slotRow)
	button:SetSize(info.w, info.h)
	button.kind = info.kind
	button.bagID = info.bagID
	if info.kind == "key" then
		button:SetNormalTexture("Interface\\Buttons\\UI-Button-KeyRing")
		button:SetHighlightTexture("Interface\\Buttons\\UI-Button-KeyRing-Highlight", "ADD")
		button:SetPushedTexture("Interface\\Buttons\\UI-Button-KeyRing-Down")
		for _, getter in ipairs({ "GetNormalTexture", "GetHighlightTexture", "GetPushedTexture" }) do
			local tex = button[getter] and button[getter](button)
			if tex and tex.SetTexCoord then
				tex:SetTexCoord(0, 0.5625, 0, 0.609375)
			end
		end
	else
		button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
		button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
		button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		-- Same as the classic item button: the slot frame is 64 and hangs past
		-- the button. The pushed texture is not given that size, so a click
		-- stays on the button instead of drawing a larger frame.
		local normal = button:GetNormalTexture()
		if normal then
			normal:ClearAllPoints()
			normal:SetSize(64, 64)
			normal:SetPoint("CENTER", button, "CENTER", 0, -1)
		end
		local pushed = button:GetPushedTexture()
		if pushed then
			pushed:ClearAllPoints()
			pushed:SetAllPoints(button)
		end
		-- Opaque center so an empty slot stays a solid button. The bag glyph
		-- sits on top of it, under the quickslot frame.
		local plate = button:CreateTexture(nil, "BACKGROUND", nil, 1)
		plate:SetSize(36, 36)
		plate:SetPoint("CENTER", button, "CENTER", 0, -1)
		plate:SetColorTexture(0.07, 0.07, 0.08, 1)
		plate:Hide()
		button.plate = plate
		local icon = button:CreateTexture(nil, "BORDER", nil, 1)
		icon:SetSize(36, 36)
		icon:SetPoint("CENTER", button, "CENTER", 0, -1)
		button.icon = icon
		if info.kind == "backpack" then
			local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
			count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
			button.count = count
		end
		local highlight = button:GetHighlightTexture()
		if highlight then
			highlight:ClearAllPoints()
			highlight:SetAllPoints(button)
		end
	end
	local mark = button:CreateTexture(nil, "OVERLAY")
	mark:SetAllPoints()
	mark:SetTexture("Interface\\Buttons\\CheckButtonHilight")
	mark:SetBlendMode("ADD")
	mark:Hide()
	button.openMark = mark
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnClick", OnOwnedSlotClick)
	button:SetScript("OnDragStart", OnOwnedSlotDrag)
	button:SetScript("OnReceiveDrag", OnOwnedSlotClick)
	button:SetScript("OnEnter", function(self)
		HighlightBagItems(self.bagID, true)
		ShowOwnedTooltip(self)
	end)
	button:SetScript("OnLeave", function()
		HighlightBagItems(nil, false)
		if GameTooltip and GameTooltip.Hide then
			GameTooltip:Hide()
		end
	end)
	button:SetFrameLevel(610)
	UpdateOwnedSlot(button)
	return button
end

local function UpdateOwnedSlots()
	if not ownedSlots then
		return
	end
	for i = 1, #ownedSlots do
		UpdateOwnedSlot(ownedSlots[i])
	end
end

local searchBox
local sortButton

local function ApplySearchText(box)
	if not box or not box.GetText then
		return
	end
	if _G.SearchBoxTemplate_OnTextChanged then
		pcall(SearchBoxTemplate_OnTextChanged, box)
	end
	if C_Container and C_Container.SetItemSearch then
		pcall(C_Container.SetItemSearch, box:GetText() or "")
	end
end

local function BindSearchBox(box)
	if not box or box.FluxSearchBound then
		return
	end
	box.FluxSearchBound = true
	if box.SetAutoFocus then
		box:SetAutoFocus(false)
	end
	if box.Instructions and box.Instructions.SetText and _G.SEARCH then
		box.Instructions:SetText(SEARCH)
		box.Instructions:Show()
	end
	box:HookScript("OnTextChanged", function(self)
		ApplySearchText(self)
	end)
	box:HookScript("OnEscapePressed", function(self)
		self:SetText("")
		self:ClearFocus()
	end)
end

local function CreateSearchBox()
	local templates = { "BagSearchBoxTemplate", "SearchBoxTemplate", "InputBoxTemplate" }
	for i = 1, #templates do
		local created, box = pcall(CreateFrame, "EditBox", nil, combined, templates[i])
		if created and box then
			BindSearchBox(box)
			return box
		end
	end
	local box = CreateFrame("EditBox", nil, combined)
	box:SetFontObject("ChatFontNormal")
	box:SetAutoFocus(false)
	box:SetScript("OnTextChanged", function(self)
		ApplySearchText(self)
	end)
	box:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		self:ClearFocus()
	end)
	return box
end

local CLEANUP_DESCRIPTION = "Auto-sorts your inventory to make room for new items. You can assign an item type to a specific bag by clicking the bag's top-left icon."

local sortDriver = CreateFrame("Frame")
sortDriver:Hide()
local sortPlan
local sortStill
local sortPasses = 0

local function PickupSlot(bag, slot)
	if C_Container and C_Container.PickupContainerItem then
		C_Container.PickupContainerItem(bag, slot)
	elseif _G.PickupContainerItem then
		PickupContainerItem(bag, slot)
	end
end

local function ReadSlot(bag, slot)
	if not (C_Container and C_Container.GetContainerItemInfo) then
		return nil
	end
	local info = C_Container.GetContainerItemInfo(bag, slot)
	if not info or not info.itemID or info.itemID == 0 then
		return nil
	end
	local classID, subclassID = 99, 99
	local instant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
	if instant and info.hyperlink then
		local details = { instant(info.hyperlink) }
		classID = details[6] or classID
		subclassID = details[7] or subclassID
	end
	local maxStack = info.stackCount or 1
	if C_Item and C_Item.GetItemMaxStackSize then
		local ok, n = pcall(C_Item.GetItemMaxStackSize, info.itemID)
		if ok and type(n) == "number" and n > maxStack then
			maxStack = n
		end
	end
	if _G.GetItemInfo then
		local ok, n = pcall(function()
			return select(8, GetItemInfo(info.hyperlink or info.itemID))
		end)
		if ok and type(n) == "number" and n > maxStack then
			maxStack = n
		end
	end
	return {
		id = info.itemID,
		count = info.stackCount or 1,
		name = info.itemName or "",
		quality = info.quality or 0,
		classID = classID,
		subclassID = subclassID,
		maxStack = math.max(1, maxStack),
		locked = info.isLocked and true or false,
	}
end

local function BagIgnored(bagID)
	local flag = Enum and Enum.BagSlotFlags and Enum.BagSlotFlags.DisableAutoSort
	if not flag or not (C_Container and C_Container.GetBagSlotFlag) then
		return false
	end
	local ok, isSet = pcall(C_Container.GetBagSlotFlag, bagID, flag)
	return ok and isSet and true or false
end

local function StackAndSort(items)
	local groups = {}
	local ids = {}
	for i = 1, #items do
		local item = items[i]
		local group = groups[item.id]
		if not group then
			group = { item = item, total = 0, maxStack = item.maxStack or 1 }
			groups[item.id] = group
			ids[#ids + 1] = item.id
		end
		group.total = group.total + item.count
		if item.maxStack > group.maxStack then
			group.maxStack = item.maxStack
		end
		if item.name ~= "" then
			group.item.name = item.name
		end
	end
	local stacks = {}
	for i = 1, #ids do
		local group = groups[ids[i]]
		local left = group.total
		local maxStack = math.max(1, group.maxStack)
		while left > 0 do
			local n = math.min(maxStack, left)
			stacks[#stacks + 1] = {
				id = group.item.id,
				count = n,
				name = group.item.name,
				quality = group.item.quality,
				classID = group.item.classID,
				subclassID = group.item.subclassID,
			}
			left = left - n
		end
	end
	table.sort(stacks, function(a, b)
		if a.classID ~= b.classID then return a.classID < b.classID end
		if a.subclassID ~= b.subclassID then return a.subclassID < b.subclassID end
		if a.quality ~= b.quality then return a.quality < b.quality end
		if a.name ~= b.name then return a.name < b.name end
		if a.id ~= b.id then return a.id < b.id end
		return a.count > b.count
	end)
	return stacks
end

local function SlotsFor(bagIDs)
	local slots = {}
	for i = 1, #bagIDs do
		local bag = bagIDs[i]
		local n = (C_Container and C_Container.GetContainerNumSlots(bag)) or 0
		for slot = 1, n do
			slots[#slots + 1] = { bag = bag, slot = slot }
		end
	end
	return slots
end

local function AddGroup(plan, bagIDs)
	local open = {}
	local items = {}
	local raw = SlotsFor(bagIDs)
	for i = 1, #raw do
		local item = ReadSlot(raw[i].bag, raw[i].slot)
		if item and item.locked then
			plan[#plan + 1] = {
				bag = raw[i].bag,
				slot = raw[i].slot,
				id = item.id,
				count = item.count,
			}
		else
			open[#open + 1] = raw[i]
			if item then
				items[#items + 1] = item
			end
		end
	end
	local stacks = StackAndSort(items)
	for i = 1, #open do
		local stack = stacks[i]
		plan[#plan + 1] = {
			bag = open[i].bag,
			slot = open[i].slot,
			id = stack and stack.id or nil,
			count = stack and stack.count or 0,
		}
	end
end

local function BuildFastPlan()
	local plan = {}
	local general = {}
	local n = BagCount()
	for bag = 0, n do
		local slots = (C_Container and C_Container.GetContainerNumSlots(bag)) or 0
		if slots > 0 and not BagIgnored(bag) then
			if IsCombinedBagID(bag) then
				general[#general + 1] = bag
			else
				AddGroup(plan, { bag })
			end
		end
	end
	if #general > 0 then
		AddGroup(plan, general)
	end
	return plan
end

local function CursorID()
	if not (_G.GetCursorInfo and _G.CursorHasItem and CursorHasItem()) then
		return nil
	end
	local kind, id = GetCursorInfo()
	if kind == "item" then
		return id
	end
end

local function CollectGroup(bagIDs)
	local slots = {}
	for i = 1, #bagIDs do
		local bag = bagIDs[i]
		local n = C_Container.GetContainerNumSlots(bag) or 0
		for slot = 1, n do
			slots[#slots + 1] = { bag = bag, slot = slot, item = ReadSlot(bag, slot) }
		end
	end
	return slots
end

local function SortableGroups()
	local general, special = {}, {}
	local n = BagCount()
	for bag = 0, n do
		if (C_Container.GetContainerNumSlots(bag) or 0) > 0 and not BagIgnored(bag) then
			if IsCombinedBagID(bag) then
				general[#general + 1] = bag
			else
				special[#special + 1] = bag
			end
		end
	end
	local groups = {}
	if #general > 0 then
		groups[#groups + 1] = general
	end
	for i = 1, #special do
		groups[#groups + 1] = { special[i] }
	end
	return groups
end

local function ItemBefore(a, b)
	local ia, ib = a.item, b.item
	if ia.classID ~= ib.classID then return ia.classID < ib.classID end
	if ia.subclassID ~= ib.subclassID then return ia.subclassID < ib.subclassID end
	if ia.quality ~= ib.quality then return ia.quality < ib.quality end
	if ia.name ~= ib.name then return ia.name < ib.name end
	if ia.id ~= ib.id then return ia.id < ib.id end
	if ia.count ~= ib.count then return ia.count > ib.count end
	if a.bag ~= b.bag then return a.bag < b.bag end
	return a.slot < b.slot
end

local function QueueGroup(slots, queue0, queue1)
	local items = {}
	for i = 1, #slots do
		local item = slots[i].item
		if item and not item.locked then
			items[#items + 1] = slots[i]
		end
	end
	table.sort(items, ItemBefore)
	local place = 1
	for i = 1, #items do
		while place <= #slots do
			local blocked = slots[place].item and slots[place].item.locked
			if not blocked then
				break
			end
			place = place + 1
		end
		if place > #slots then
			break
		end
		local dest = slots[place]
		local src = items[i]
		if src.bag ~= dest.bag or src.slot ~= dest.slot then
			local move = { src.bag, src.slot, dest.bag, dest.slot }
			if dest.item then
				queue1[#queue1 + 1] = move
			else
				queue0[#queue0 + 1] = move
			end
		end
		place = place + 1
	end
end

local function PlayMoves(list)
	for i = 1, #list do
		local move = list[i]
		PickupSlot(move[1], move[2])
		PickupSlot(move[3], move[4])
		if _G.ClearCursor then
			ClearCursor()
		end
	end
end

local function StackPass()
	local partials = {}
	local groups = SortableGroups()
	for g = 1, #groups do
		local slots = CollectGroup(groups[g])
		for i = 1, #slots do
			local item = slots[i].item
			if item and not item.locked and item.maxStack > 1 and item.count < item.maxStack then
				local list = partials[item.id]
				if not list then
					list = {}
					partials[item.id] = list
				end
				list[#list + 1] = slots[i]
			end
		end
	end
	local moved = false
	for _, list in pairs(partials) do
		if #list >= 2 then
			local total, full = 0, 0
			local maxStack = 1
			for i = 1, #list do
				total = total + list[i].item.count
				if list[i].item.maxStack > maxStack then
					maxStack = list[i].item.maxStack
				end
			end
			for i = 1, #list do
				if list[i].item.count >= maxStack then
					full = full + 1
				end
			end
			local targetFull = math.floor(total / maxStack)
			local targetStacks = math.ceil(total / maxStack)
			if #list > targetStacks or full ~= targetFull then
				table.sort(list, function(a, b)
					return a.item.count < b.item.count
				end)
				local source, target = list[1], list[#list]
				PickupSlot(source.bag, source.slot)
				PickupSlot(target.bag, target.slot)
				if _G.ClearCursor then
					ClearCursor()
				end
				moved = true
			end
		end
	end
	return moved
end

local function OrderPass()
	local queue0, queue1 = {}, {}
	local groups = SortableGroups()
	for i = 1, #groups do
		QueueGroup(CollectGroup(groups[i]), queue0, queue1)
	end
	if #queue0 == 0 and #queue1 == 0 then
		return false
	end
	PlayMoves(queue0)
	PlayMoves(queue1)
	return true
end

local sortPhase = "stack"

local function RunSortPass()
	if not sortPlan or not combined:IsShown() then
		StopFastSort()
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		return
	end
	sortPasses = sortPasses + 1
	if sortPasses > 24 then
		StopFastSort()
		return
	end
	if _G.CursorHasItem and CursorHasItem() and _G.ClearCursor then
		ClearCursor()
	end
	if sortPhase == "stack" then
		if StackPass() then
			return
		end
		sortPhase = "order"
	end
	if not OrderPass() then
		StopFastSort()
	end
end

StopFastSort = function()
	sortDriver:Hide()
	sortDriver:UnregisterEvent("BAG_UPDATE_DELAYED")
	sortPlan = nil
	sortStill = 0
	sortPasses = 0
	sortPhase = "stack"
	if _G.ClearCursor and _G.CursorHasItem and CursorHasItem() then
		pcall(ClearCursor)
	end
end

sortDriver:SetScript("OnEvent", function(_, event)
	if event == "BAG_UPDATE_DELAYED" then
		RunSortPass()
	end
end)

local function SortCombinedBags()
	if InCombatLockdown and InCombatLockdown() then
		return
	end
	if _G.CursorHasItem and CursorHasItem() then
		return
	end
	if not (C_Container and C_Container.GetContainerItemInfo and C_Container.PickupContainerItem) then
		return
	end
	StopFastSort()
	if _G.PlaySound and _G.SOUNDKIT and SOUNDKIT.IG_BACKPACK_OPEN then
		pcall(PlaySound, SOUNDKIT.IG_BACKPACK_OPEN)
	end
	sortPlan = true
	sortPasses = 0
	sortPhase = "stack"
	sortDriver:RegisterEvent("BAG_UPDATE_DELAYED")
	sortDriver:Show()
	RunSortPass()
end

local function ApplySortAtlas(texture, atlas)
	if not texture or not texture.SetAtlas or not atlas then
		return false
	end
	local ok = pcall(texture.SetAtlas, texture, atlas)
	return ok and true or false
end

local function ShowSortTooltip(self)
	if not GameTooltip or not GameTooltip.SetOwner then
		return
	end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	local title = _G.BAG_CLEANUP_BAGS or "Clean Up Bags"
	local desc = _G.BAG_CLEANUP_BAGS_DESCRIPTION or CLEANUP_DESCRIPTION
	if _G.GameTooltip_SetTitle then
		local color = _G.HIGHLIGHT_FONT_COLOR
		GameTooltip_SetTitle(GameTooltip, title, color)
	else
		GameTooltip:ClearLines()
		GameTooltip:AddLine(title, 1, 1, 1)
	end
	if _G.GameTooltip_AddNormalLine then
		GameTooltip_AddNormalLine(GameTooltip, desc, true)
	else
		GameTooltip:AddLine(desc, 1, 0.82, 0, true)
	end
	GameTooltip:Show()
end

local function EnsureBagChrome()
	if not searchBox then
		searchBox = CreateSearchBox()
		if searchBox then
			searchBox:SetFrameStrata("HIGH")
			searchBox:SetFrameLevel(800)
		end
	end
	if sortButton then
		return
	end
	sortButton = CreateFrame("Button", nil, combined)
	sortButton:SetSize(28, 26)
	sortButton:SetFrameStrata("HIGH")
	sortButton:SetFrameLevel(820)
	sortButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	sortButton:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
	sortButton:SetPushedTexture("Interface\\Buttons\\UI-Quickslot2")
	sortButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	ApplySortAtlas(sortButton:GetNormalTexture(), "bags-button-autosort-up")
	ApplySortAtlas(sortButton:GetPushedTexture(), "bags-button-autosort-down")
	local highlight = sortButton:GetHighlightTexture()
	if highlight then
		highlight:ClearAllPoints()
		highlight:SetSize(24, 23)
		highlight:SetPoint("CENTER")
	end
	sortButton:SetScript("OnClick", SortCombinedBags)
	sortButton:SetScript("OnMouseUp", function(_, button)
		if button == "LeftButton" then
			SortCombinedBags()
		end
	end)
	sortButton:SetScript("OnEnter", ShowSortTooltip)
	sortButton:SetScript("OnLeave", function()
		if GameTooltip and GameTooltip.Hide then
			GameTooltip:Hide()
		end
	end)
end

local function LayoutBagChrome()
	EnsureBagChrome()
	if sortButton then
		sortButton:ClearAllPoints()
		sortButton:SetPoint("TOPRIGHT", combined, "TOPRIGHT", -9, -34)
		sortButton:Show()
	end
	if searchBox then
		searchBox:ClearAllPoints()
		searchBox:SetSize(330, 20)
		searchBox:SetPoint("TOPLEFT", combined, "TOPLEFT", 62, -37)
		if sortButton then
			searchBox:SetPoint("RIGHT", sortButton, "LEFT", -8, 0)
		end
		searchBox:Show()
	end
end

local function LayoutSlots()
	if layingSlots then
		return
	end
	layingSlots = true
	LayoutBagChrome()
	local ox = RightInset()
	slotRow:ClearAllPoints()
	slotRow:SetPoint("TOPRIGHT", combined, "TOPRIGHT", ox, -64)
	slotRow:SetFrameLevel(600)
	slotRow:Show()
	if not ownedSlots then
		ownedSlots = {}
		for i = 1, #CLASSIC_SLOTS do
			local info = CLASSIC_SLOTS[i]
			if info.kind ~= "key" or KeyringActive() then
				ownedSlots[#ownedSlots + 1] = CreateOwnedSlot(info)
			end
		end
	end
	local prev
	for i = 1, #ownedSlots do
		local button = ownedSlots[i]
		button:ClearAllPoints()
		if not prev then
			button:SetPoint("RIGHT", slotRow, "RIGHT", 0, 0)
		else
			button:SetPoint("RIGHT", prev, "LEFT", 0, 0)
		end
		button:Show()
		UpdateOwnedSlot(button)
		prev = button
	end
	layingSlots = false
end

function slotRow:Layout()
end

-- Main action bar buttons. Not the bag quickslot (UI-Quickslot / UI-Quickslot2).
local ACTION_ICON_FRAME = "UI-HUD-ActionBar-IconFrame"
local ACTION_ICON_BG = "UI-HUD-ActionBar-IconFrame-Background"
local ACTION_ICON_SLOT = "ui-hud-actionbar-iconframe-slot"

local function HasAtlas(name)
	return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

local function ItemButtonIcon(button)
	if not button then
		return nil
	end
	return button.icon or button.Icon or (button.GetName and _G[button:GetName() .. "IconTexture"])
end

local function ItemSlotEmpty(button)
	local icon = ItemButtonIcon(button)
	if not icon or not icon.IsShown or not icon:IsShown() then
		return true
	end
	local texture = icon.GetTexture and icon:GetTexture()
	return texture == nil or texture == "" or texture == 0
end

local function QualityColor(quality)
	if type(quality) ~= "number" then
		return nil
	end
	local colors = _G.ITEM_QUALITY_COLORS or _G.BAG_ITEM_QUALITY_COLORS
	local color = colors and colors[quality]
	if color then
		return color.r, color.g, color.b
	end
end

local function ApplyItemQuality(button)
	if not button then
		return
	end
	local host = hosts[button]
	local hosted = host and button.GetParent and button:GetParent() == host
	local border = button.IconBorder or button.FluxQualityBorder
	if not hosted or ItemSlotEmpty(button) then
		if border then
			border:Hide()
		end
		return
	end
	local bag = host.GetID and host:GetID()
	local slot = button.GetID and button:GetID()
	local info = bag and slot and C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag, slot)
	local r, g, b = QualityColor(info and info.quality)
	if not r then
		if border then
			border:Hide()
		end
		return
	end
	if not border then
		border = button:CreateTexture(nil, "OVERLAY", nil, 2)
		if not border then
			return
		end
		border:SetTexture("Interface\\Common\\WhiteIconFrame")
		border:SetSize(37, 37)
		border:SetPoint("CENTER", button, "CENTER", 0, 0)
		button.FluxQualityBorder = border
	end
	border:SetVertexColor(r, g, b)
	border:SetAlpha(1)
	border:Show()
end

local function RestoreBagFrame(button)
	local normal = button.GetNormalTexture and button:GetNormalTexture()
	if normal then
		normal:SetTexture("Interface\\Buttons\\UI-Quickslot2")
		normal:SetTexCoord(0, 1, 0, 1)
		normal:SetAlpha(1)
		normal:ClearAllPoints()
		normal:SetSize(64, 64)
		normal:SetPoint("CENTER", button, "CENTER", 0, -1)
	end
	local pushed = button.GetPushedTexture and button:GetPushedTexture()
	if pushed then
		pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
		pushed:SetAlpha(1)
		pushed:ClearAllPoints()
		pushed:SetAllPoints(button)
	end
end

local function EnsureActionTexture(button, key, atlas, layer, sublevel)
	local tex = button[key]
	if not tex then
		tex = button:CreateTexture(nil, layer, nil, sublevel)
		if not tex then
			return nil
		end
		tex:SetAllPoints(button)
		button[key] = tex
	end
	if tex.SetAtlas and HasAtlas(atlas) then
		tex:SetAtlas(atlas)
	end
	tex:SetAlpha(1)
	tex:SetVertexColor(1, 1, 1, 1)
	return tex
end

local function ApplyEmptySlotIcon(button)
	if not button then
		return
	end
	local host = hosts[button]
	local hosted = host and button.GetParent and button:GetParent() == host
	local empty = hosted and ItemSlotEmpty(button)
	if not empty then
		if button.FluxEmptySlot then
			button.FluxEmptySlot:Hide()
		end
		if button.FluxEmptySlotArt then
			button.FluxEmptySlotArt:Hide()
		end
		if button.FluxBagSlotBg then
			button.FluxBagSlotBg:Hide()
		end
		if button.FluxActionArt then
			button.FluxActionArt = nil
			RestoreBagFrame(button)
		end
		return
	end
	local bg = EnsureActionTexture(button, "FluxEmptySlot", ACTION_ICON_BG, "BACKGROUND", 0)
	local art = EnsureActionTexture(button, "FluxEmptySlotArt", ACTION_ICON_SLOT, "BACKGROUND", 1)
	if bg then
		bg:Show()
	end
	if art then
		art:Show()
	end
	local normal = button.GetNormalTexture and button:GetNormalTexture()
	if normal and normal.SetAtlas and HasAtlas(ACTION_ICON_FRAME) then
		normal:SetAtlas(ACTION_ICON_FRAME)
		normal:SetTexCoord(0, 1, 0, 1)
		normal:SetAlpha(1)
		normal:ClearAllPoints()
		normal:SetAllPoints(button)
		button.FluxActionArt = true
	end
end

local function RefreshEmptySlotIcons()
	if not combined:IsShown() then
		return
	end
	for button in pairs(hosts) do
		ApplyEmptySlotIcon(button)
		ApplyItemQuality(button)
	end
end

local function HostFor(button, bagID)
	local host = hosts[button]
	if not host then
		host = CreateFrame("Frame", nil, combined)
		host:EnableMouse(false)
		hosts[button] = host
	end
	host:SetParent(combined)
	host:SetID(bagID)
	host:SetSize(ITEM, ITEM)
	host:SetFrameLevel(520)
	button:SetParent(host)
	button:SetSize(ITEM, ITEM)
	button:ClearAllPoints()
	button:SetAllPoints(host)
	local normal = button.GetNormalTexture and button:GetNormalTexture()
	if normal then
		if normal.SetTexture and not normal:GetTexture() then
			normal:SetTexture("Interface\\Buttons\\UI-Quickslot2")
		end
		normal:ClearAllPoints()
		normal:SetSize(64, 64)
		normal:SetPoint("CENTER", button, "CENTER", 0, -1)
	end
	local pushed = button.GetPushedTexture and button:GetPushedTexture()
	if pushed then
		pushed:ClearAllPoints()
		pushed:SetAllPoints(button)
	end
	return host
end

local function ReturnItems()
	for button, host in pairs(hosts) do
		local frame = host and host.fluxContainer
		if button and frame and button.GetParent and button:GetParent() ~= frame then
			button:SetParent(frame)
			button:ClearAllPoints()
		end
		if host and host.Hide then
			host:Hide()
		end
		if button then
			if button.FluxEmptySlot then
				button.FluxEmptySlot:Hide()
			end
			if button.FluxEmptySlotArt then
				button.FluxEmptySlotArt:Hide()
			end
			if button.FluxBagSlotBg then
				button.FluxBagSlotBg:Hide()
			end
			if button.FluxActionArt then
				button.FluxActionArt = nil
				RestoreBagFrame(button)
			end
			if button.IconBorder then
				button.IconBorder:Hide()
			end
			if button.FluxQualityBorder then
				button.FluxQualityBorder:Hide()
			end
		end
	end
	combined.FluxHostedButtons = nil
end

local function Ghost(frame)
	if not frame then
		return
	end
	ghosted[frame] = true
	frame.FluxCombinedGhost = true
	frame:SetAlpha(0)
	if frame.EnableMouse then
		frame:EnableMouse(false)
	end
	local name = frame.GetName and frame:GetName()
	local close = frame.CloseButton or (name and _G[name .. "CloseButton"])
	if close then
		if close.Hide then
			close:Hide()
		end
		if close.EnableMouse then
			close:EnableMouse(false)
		end
	end
	local portrait = frame.PortraitButton or (name and _G[name .. "PortraitButton"])
	if portrait and portrait.EnableMouse then
		portrait:EnableMouse(false)
	end
end

local function Restore(frame)
	if not frame then
		return
	end
	ghosted[frame] = nil
	frame.FluxCombinedGhost = nil
	frame:SetAlpha(1)
	if frame.EnableMouse then
		frame:EnableMouse(true)
	end
	local scale = frame.GetScale and frame:GetScale() or 1
	if type(scale) == "number" and scale < 0.05 then
		frame:SetScale(1)
	end
	local name = frame.GetName and frame:GetName()
	local close = frame.CloseButton or (name and _G[name .. "CloseButton"])
	if close and close.EnableMouse then
		close:EnableMouse(true)
	end
	local portrait = frame.PortraitButton or (name and _G[name .. "PortraitButton"])
	if portrait and portrait.EnableMouse then
		portrait:EnableMouse(true)
	end
end

local function RestoreAll()
	for frame in pairs(ghosted) do
		Restore(frame)
	end
end

local function EachContainer(call)
	local n = _G.NUM_CONTAINER_FRAMES or 13
	for i = 1, n do
		local frame = _G["ContainerFrame" .. i]
		if frame then
			call(frame)
		end
	end
end

local function FindOpenContainer(bagID)
	local found
	EachContainer(function(frame)
		if not found and frame:IsShown() and frame:GetID() == bagID then
			found = frame
		end
	end)
	return found
end

local parkedMoney

local function PlaceMoney()
	local frame = FindOpenContainer(0)
	if not frame or not frame.GetName then
		return
	end
	local money = _G[frame:GetName() .. "MoneyFrame"]
	if not money then
		return
	end
	if money:GetParent() ~= combined then
		parkedMoney = { frame = money:GetParent(), money = money }
	end
	if combined.FluxGoldPanel and combined.FluxGoldPanel.Hide then
		combined.FluxGoldPanel:Hide()
	end
	EnsureEdgeStrips(combined)
	local strip = combined.FluxGoldStrip
	money:SetParent(strip or combined)
	money:SetAlpha(1)
	money:ClearAllPoints()
	if strip then
		money:SetPoint("RIGHT", strip, "RIGHT", -10, 0)
		money:SetFrameLevel(strip:GetFrameLevel() + 6)
	else
		money:SetPoint("BOTTOMRIGHT", combined, "BOTTOMRIGHT", -10, 8)
		if money.SetFrameLevel and combined.GetFrameLevel then
			money:SetFrameLevel(combined:GetFrameLevel() + 30)
		end
	end
	money:Show()
	if _G.FluxGoldLedger and FluxGoldLedger.AttachBagMoneyTooltip then
		FluxGoldLedger:AttachBagMoneyTooltip(money)
	end
end

local function ReleaseMoney()
	local parked = parkedMoney
	parkedMoney = nil
	if not parked or not parked.money or not parked.frame then
		return
	end
	parked.money:SetParent(parked.frame)
end

local function CollectItemButtons(frame)
	local name = frame.GetName and frame:GetName()
	local size = frame.size or 0
	if not name or size < 1 then
		return nil
	end
	local list = {}
	for i = 1, size do
		local button = _G[name .. "Item" .. i]
		if button and (not button.IsShown or button:IsShown()) then
			list[#list + 1] = button
		end
	end
	table.sort(list, function(a, b)
		return (a:GetID() or 0) < (b:GetID() or 0)
	end)
	return list
end

local function BagOrder()
	local ids = { 0 }
	local n = BagCount()
	for i = 1, n do
		if IsCombinedBagID(i) then
			ids[#ids + 1] = i
		end
	end
	return ids
end

local function LayoutItems()
	local used = {}
	local entries = {}
	local hostedButtons = {}
	local ids = BagOrder()
	for i = 1, #ids do
		local frame = FindOpenContainer(ids[i])
		if frame then
			local buttons = CollectItemButtons(frame)
			if buttons then
				for b = 1, #buttons do
					local button = buttons[b]
					local host = HostFor(button, ids[i])
					host.fluxContainer = frame
					used[host] = true
					entries[#entries + 1] = host
					hostedButtons[#hostedButtons + 1] = button
					button:Show()
					host:Show()
				end
			end
			Ghost(frame)
		end
	end
	combined.FluxHostedButtons = hostedButtons
	for _, host in pairs(hosts) do
		if not used[host] then
			host:Hide()
		end
	end
	local count = #entries
	local rows = math.max(1, math.ceil(count / COLUMNS))
	for i = 1, count do
		local host = entries[i]
		local col = (i - 1) % COLUMNS
		local row = math.floor((i - 1) / COLUMNS)
		host:ClearAllPoints()
		host:SetPoint("TOPLEFT", combined, "TOPLEFT", LEFT + col * (ITEM + GAP), TOP - row * (ITEM + GAP))
	end
	local itemsH = rows * ITEM + (rows - 1) * GAP
	combined:SetSize(WIDTH, HEADER + itemsH + BOTTOM_PAD)
	PlaceMoney()
	RefreshEmptySlotIcons()
	if _G.BagHelpBox and BagHelpBox.Hide then
		BagHelpBox:Hide()
	end
end

function combined:EnumerateValidItems()
	local list = combined.FluxHostedButtons
	local i = 0
	local n = list and #list or 0
	return function()
		i = i + 1
		if i <= n then
			return i, list[i]
		end
	end
end

local function ReleaseSeparateFrames()
	if releasing then
		return
	end
	releasing = true
	EachContainer(function(frame)
		if not frame:IsShown() then
			return
		end
		local id = frame:GetID()
		if IsCombinedBagID(id) or not IsSpecialtyBag(id) then
			return
		end
		Restore(frame)
		local name = frame.GetName and frame:GetName()
		local size = frame.size or 0
		local stolen = false
		if name and size > 0 then
			for i = 1, size do
				local button = _G[name .. "Item" .. i]
				if button and button:GetParent() ~= frame then
					button:SetParent(frame)
					stolen = true
				end
			end
		end
		if stolen and _G.ContainerFrame_GenerateFrame then
			ContainerFrame_GenerateFrame(frame, size, id)
		end
	end)
	releasing = false
end

local dropCatcher
local dropLock

local function NearestSlotButton()
	if not GetCursorPosition then
		return nil
	end
	local x, y = GetCursorPosition()
	local scale = combined.GetEffectiveScale and combined:GetEffectiveScale() or 1
	if not scale or scale == 0 then
		scale = 1
	end
	x, y = x / scale, y / scale
	local best, bestDist
	for button, host in pairs(hosts) do
		if host and host.IsShown and host:IsShown() and button and button.GetLeft then
			local left, right = button:GetLeft(), button:GetRight()
			local bottom, top = button:GetBottom(), button:GetTop()
			if left and right and bottom and top then
				local dx = ((left + right) * 0.5) - x
				local dy = ((bottom + top) * 0.5) - y
				local dist = dx * dx + dy * dy
				if not bestDist or dist < bestDist then
					bestDist = dist
					best = button
				end
			end
		end
	end
	return best
end

local function DropCursorOnNearestSlot()
	if dropLock or not (_G.CursorHasItem and CursorHasItem()) then
		return
	end
	local button = NearestSlotButton()
	local host = button and hosts[button]
	if not button or not host then
		return
	end
	local bag = host.GetID and host:GetID()
	local slot = button.GetID and button:GetID()
	if bag == nil or not slot then
		return
	end
	dropLock = true
	if C_Container and C_Container.PickupContainerItem then
		C_Container.PickupContainerItem(bag, slot)
	elseif _G.PickupContainerItem then
		PickupContainerItem(bag, slot)
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			dropLock = false
		end)
	else
		dropLock = false
	end
end

local function EnsureSlotDrop()
	if dropCatcher then
		return
	end
	dropCatcher = CreateFrame("Button", nil, combined)
	dropCatcher:SetPoint("TOPLEFT", combined, "TOPLEFT", 6, TOP)
	dropCatcher:SetPoint("BOTTOMRIGHT", combined, "BOTTOMRIGHT", -6, 32)
	dropCatcher:SetFrameLevel(500)
	dropCatcher:EnableMouse(true)
	dropCatcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	dropCatcher:SetScript("OnReceiveDrag", DropCursorOnNearestSlot)
	dropCatcher:SetScript("OnMouseUp", DropCursorOnNearestSlot)
end

local bagLayoutKey
local slotCountKey

local function SlotCountSignature()
	if not (C_Container and C_Container.GetContainerNumSlots) then
		return ""
	end
	local parts = {}
	local n = BagCount()
	for bag = 0, n do
		parts[#parts + 1] = C_Container.GetContainerNumSlots(bag) or 0
	end
	return table.concat(parts, ":")
end

local function BagLayoutSignature()
	local parts = {}
	local n = BagCount()
	if not (C_Container and C_Container.GetContainerNumSlots) then
		return ""
	end
	for bag = 0, n do
		local slots = C_Container.GetContainerNumSlots(bag) or 0
		parts[#parts + 1] = bag .. ":" .. slots .. ":" .. (IsSpecialtyBag(bag) and "s" or "n")
	end
	return table.concat(parts, "|")
end

local function Refresh()
	if refreshing or closing or releasing then
		return
	end
	refreshing = true
	ReleaseSeparateFrames()
	LayoutSlots()
	LayoutItems()
	EnsureSlotDrop()
	refreshing = false
	bagLayoutKey = BagLayoutSignature()
	slotCountKey = SlotCountSignature()
end

_G.FluxRefreshInBagSlots = function()
	if not combined:IsShown() or closing then
		return
	end
	UpdateOwnedSlots()
end

local function AdoptFrame(frame)
	if not frame or not IsCombinedBagID(frame:GetID()) or not OwningOpen() then
		return
	end
	Refresh()
end

local function CloseOwnedBags()
	if closing then
		return
	end
	closing = true
	ReturnItems()
	ReleaseMoney()
	if origCloseBackpack then
		origCloseBackpack()
	end
	local n = BagCount()
	for i = 1, n do
		if IsCombinedBagID(i) and origCloseBag then
			origCloseBag(i)
		end
	end
	RestoreAll()
	closing = false
end

local function OpenPlayerBags()
	if origOpenBackpack then
		origOpenBackpack()
	elseif origToggleBag then
		origToggleBag(0)
	end
	local n = BagCount()
	for i = 1, n do
		if IsCombinedBagID(i) then
			if origOpenBag then
				origOpenBag(i)
			elseif origToggleBag then
				origToggleBag(i)
			end
		end
	end
end

local function ShowCombined()
	if busy or closing then
		return
	end
	busy = true
	OpenPlayerBags()
	busy = false
	combined:Show()
	Refresh()
end

combined:HookScript("OnShow", function()
	ApplyWindowChrome(combined)
	Refresh()
end)

combined:HookScript("OnHide", function()
	CloseOwnedBags()
	if StopFastSort then
		StopFastSort()
	end
	if SetChatDragHold then
		SetChatDragHold(false)
	end
end)

local function SafeHook(name, fn)
	if type(_G[name]) ~= "function" then
		return false
	end
	return pcall(hooksecurefunc, name, fn)
end

local function OnContainerShown(frame)
	if not ShouldOwn() or not OwningOpen() or not frame or not IsCombinedBagID(frame:GetID()) then
		return
	end
	Ghost(frame)
	AdoptFrame(frame)
end

local function OnContainerAnchors()
	if not ShouldOwn() or not OwningOpen() then
		return
	end
	EachContainer(function(frame)
		if frame:IsShown() and IsCombinedBagID(frame:GetID()) then
			Ghost(frame)
		end
	end)
end

local wrapped = false
local bankOpenedCombined = false

local function FrameName(frame)
	return frame and frame.GetName and frame:GetName()
end

local function InstallWrappers()
	if wrapped or type(_G.ToggleBag) ~= "function" then
		return
	end
	wrapped = true
	origToggleAllBags = ToggleAllBags
	origToggleBackpack = ToggleBackpack
	origToggleBag = ToggleBag
	origOpenAllBags = OpenAllBags
	origOpenBag = OpenBag
	origOpenBackpack = OpenBackpack
	origCloseAllBags = CloseAllBags
	origCloseBag = CloseBag
	origCloseBackpack = CloseBackpack

	function ToggleAllBags(...)
		if busy or not ShouldOwn() then
			return origToggleAllBags(...)
		end
		if combined:IsShown() then
			bankOpenedCombined = false
			combined:Hide()
		else
			ShowCombined()
		end
	end

	function ToggleBackpack(...)
		if busy or not ShouldOwn() then
			return origToggleBackpack(...)
		end
		if combined:IsShown() then
			bankOpenedCombined = false
			combined:Hide()
		else
			ShowCombined()
		end
	end

	function ToggleBag(id, ...)
		if not ShouldOwn() or busy or not IsCombinedBagID(id) then
			return origToggleBag(id, ...)
		end
		if combined:IsShown() then
			bankOpenedCombined = false
			combined:Hide()
		else
			ShowCombined()
		end
	end

	function OpenBag(id, force, ...)
		if busy or not ShouldOwn() or not IsCombinedBagID(id) then
			return origOpenBag(id, force, ...)
		end
		if combined:IsShown() then
			return origOpenBag(id, force, ...)
		end
		ShowCombined()
	end

	function OpenBackpack(...)
		if busy or not ShouldOwn() then
			return origOpenBackpack(...)
		end
		if not combined:IsShown() then
			ShowCombined()
		end
	end

	function OpenAllBags(frame, ...)
		if busy or not ShouldOwn() then
			return origOpenAllBags(frame, ...)
		end
		-- The banker calls this with the bank frame. Open the combined bag,
		-- and only close it again if the bank is what opened it.
		if FrameName(frame) == "BankFrame" then
			if not combined:IsShown() then
				bankOpenedCombined = true
				ShowCombined()
			end
			return
		end
		if not combined:IsShown() then
			ShowCombined()
		end
	end

	function CloseAllBags(frame, ...)
		if busy or not ShouldOwn() then
			return origCloseAllBags(frame, ...)
		end
		if FrameName(frame) == "BankFrame" then
			if not bankOpenedCombined then
				return
			end
			bankOpenedCombined = false
			if combined:IsShown() then
				combined:Hide()
			end
			return
		end
		bankOpenedCombined = false
		if combined:IsShown() then
			combined:Hide()
			return
		end
		return origCloseAllBags(frame, ...)
	end

	_G.ToggleAllBags = ToggleAllBags
	_G.ToggleBackpack = ToggleBackpack
	_G.ToggleBag = ToggleBag
	_G.OpenBag = OpenBag
	_G.OpenBackpack = OpenBackpack
	_G.OpenAllBags = OpenAllBags
	_G.CloseAllBags = CloseAllBags

	SafeHook("ContainerFrame_GenerateFrame", function(frame)
		AdoptFrame(frame)
	end)
	SafeHook("ContainerFrame_Update", function()
		RefreshEmptySlotIcons()
	end)
	SafeHook("ContainerFrame_OnShow", OnContainerShown)
	SafeHook("UpdateContainerFrameAnchors", OnContainerAnchors)

	local bar = _G.BagsBar
	if bar and not bar.FluxCombinedLayoutGuard and type(bar.Layout) == "function" then
		bar.FluxCombinedLayoutGuard = true
		local origLayout = bar.Layout
		bar.Layout = function(self, ...)
			-- Resizing this bar reanchors the hosted slots and shifts chat.
			if combined:IsShown() and not closing then
				return
			end
			return origLayout(self, ...)
		end
	end
end

local anchorsWrapped = false

local function InstallAnchorGuard()
	if anchorsWrapped or type(_G.UpdateContainerFrameAnchors) ~= "function" then
		return
	end
	local orig = _G.UpdateContainerFrameAnchors
	local function GuardedAnchors()
		local root = _G.ContainerFrame1
		local bags = root and root.bags
		if not bags or not OwningOpen() then
			return orig()
		end
		local saved = {}
		for i = 1, #bags do
			saved[i] = bags[i]
		end
		local count = 0
		for i = 1, #saved do
			local frame = _G[saved[i]]
			local id = frame and frame.GetID and frame:GetID()
			if not (frame and IsCombinedBagID(id)) then
				count = count + 1
				bags[count] = saved[i]
			end
		end
		for i = count + 1, #bags do
			bags[i] = nil
		end
		local ok, err = pcall(orig)
		for i = 1, #saved do
			bags[i] = saved[i]
		end
		for i = #saved + 1, #bags do
			bags[i] = nil
		end
		if not ok then
			error(err, 0)
		end
	end
	_G.UpdateContainerFrameAnchors = GuardedAnchors
	anchorsWrapped = true
end

local keyRingWrapped = false

local function InstallKeyRingGuard()
	if keyRingWrapped or type(_G.MainMenuBar_UpdateKeyRing) ~= "function" then
		return
	end
	local orig = MainMenuBar_UpdateKeyRing
	local function GuardedKeyRing(...)
		if (combined:IsShown() or busy) and not closing then
			return
		end
		return orig(...)
	end
	_G.MainMenuBar_UpdateKeyRing = GuardedKeyRing
	keyRingWrapped = true
end

local BLIZZARD_SLOT_NAMES = {
	"MainMenuBarBackpackButton",
	"CharacterBag0Slot",
	"CharacterBag1Slot",
	"CharacterBag2Slot",
	"CharacterBag3Slot",
	"KeyRingButton",
}

local function ReleaseBlizzardSlotFlags()
	for i = 1, #BLIZZARD_SLOT_NAMES do
		local button = _G[BLIZZARD_SLOT_NAMES[i]]
		if button then
			button.FluxBagSlotHosted = nil
		end
	end
	local hidden = _G.FluxHiddenParent
	if hidden and not hidden.Layout then
		function hidden:Layout()
		end
	end
end

local layoutOuter = false
local layoutOuterPending = false

local function InstallLayoutOuter()
	local bar = _G.BagsBar
	if layoutOuter or not bar or type(bar.Layout) ~= "function" or not bar.FluxHooked then
		return
	end
	layoutOuter = true
	local orig = bar.Layout
	bar.Layout = function(self, ...)
		if (combined:IsShown() or busy) and not closing then
			return
		end
		return orig(self, ...)
	end
end

local function ScheduleLayoutOuter()
	if layoutOuter then
		return
	end
	if not (C_Timer and C_Timer.After) then
		InstallLayoutOuter()
		return
	end
	if layoutOuterPending then
		return
	end
	layoutOuterPending = true
	C_Timer.After(0, function()
		layoutOuterPending = false
		InstallLayoutOuter()
	end)
end

-- BagsBar:OnLoad registered OnExpandChanged with the original Layout function.
-- Replacing BagsBar.Layout later does not change that callback, so an item
-- cursor still SetSizes the bar and reanchors the bag buttons.
local expandLayoutUnhooked = false

local function UnregisterBagExpandLayout()
	if expandLayoutUnhooked then
		return
	end
	local bar = _G.BagsBar
	local reg = _G.EventRegistry
	if not bar or not reg or type(reg.UnregisterCallback) ~= "function" then
		return
	end
	reg:UnregisterCallback("MainMenuBarManager.OnExpandChanged", bar)
	expandLayoutUnhooked = true
end

local function CursorHoldsItem()
	if GetCursorInfo then
		local cursorType = GetCursorInfo()
		if cursorType == "item" then
			return true
		end
	end
	if _G.CursorHasItem and CursorHasItem() then
		return true
	end
	return false
end

local chatHoldOn = false
local chatHoldGen = 0

SetChatDragHold = function(on)
	if not _G.FluxChatFrame_SetDragHold then
		return
	end
	if on then
		chatHoldGen = chatHoldGen + 1
		if not chatHoldOn then
			chatHoldOn = true
			FluxChatFrame_SetDragHold(true)
		end
		return
	end
	if not chatHoldOn then
		return
	end
	chatHoldOn = false
	FluxChatFrame_SetDragHold(false)
end

local function QueueChatHoldRelease()
	if not chatHoldOn then
		return
	end
	chatHoldGen = chatHoldGen + 1
	local gen = chatHoldGen
	local function release()
		if gen ~= chatHoldGen then
			return
		end
		if combined:IsShown() and not closing and CursorHoldsItem() then
			return
		end
		SetChatDragHold(false)
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0, release)
	else
		release()
	end
end

local function SyncChatDragHold()
	if not combined:IsShown() or closing then
		SetChatDragHold(false)
		return
	end
	if CursorHoldsItem() then
		SetChatDragHold(true)
		return
	end
	QueueChatHoldRelease()
end

InstallWrappers()
InstallAnchorGuard()
InstallKeyRingGuard()
ReleaseBlizzardSlotFlags()
ScheduleLayoutOuter()
UnregisterBagExpandLayout()

local function RepinItemsQuiet()
	for button, host in pairs(hosts) do
		if button and host and button.GetParent and button:GetParent() ~= host then
			button:SetParent(host)
			button:ClearAllPoints()
			button:SetAllPoints(host)
		end
	end
end

local function OpenMissingCombinedBags()
	if not (C_Container and C_Container.GetContainerNumSlots) then
		return
	end
	local n = BagCount()
	for bag = 0, n do
		if IsCombinedBagID(bag) and (C_Container.GetContainerNumSlots(bag) or 0) > 0 and not FindOpenContainer(bag) then
			if bag == 0 and origOpenBackpack then
				origOpenBackpack()
			elseif origOpenBag then
				origOpenBag(bag)
			end
		end
	end
end

local function RefreshIfSlotCountsChanged()
	if not combined:IsShown() or closing or refreshing or busy then
		return
	end
	local sig = SlotCountSignature()
	if sig == slotCountKey then
		return
	end
	slotCountKey = sig
	busy = true
	OpenMissingCombinedBags()
	busy = false
	Refresh()
end

local function RefreshIfBagLayoutChanged()
	if not combined:IsShown() or closing or refreshing or busy then
		return
	end
	local sig = BagLayoutSignature()
	if sig == bagLayoutKey then
		return
	end
	bagLayoutKey = sig
	busy = true
	OpenMissingCombinedBags()
	busy = false
	Refresh()
end

local layoutCheckOwed = false

local watcher = CreateFrame("Frame")
if Flux.Container and Flux.Container.WatchFreeBagSlots then
	Flux.Container.WatchFreeBagSlots("FluxClassicCombinedBag", function(total)
		if UsesAltBag() or not ownedSlots then return end
		for i = 1, #ownedSlots do
			local button = ownedSlots[i]
			if button.kind == "backpack" and button.count then button.count:SetText(total) end
		end
	end)
end
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("BAG_UPDATE")
watcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
watcher:RegisterEvent("CURSOR_CHANGED")
watcher:SetScript("OnEvent", function(_, event)
	if event == "ADDON_LOADED" or event == "PLAYER_ENTERING_WORLD" then
		InstallWrappers()
		InstallAnchorGuard()
		InstallKeyRingGuard()
		ReleaseBlizzardSlotFlags()
		ScheduleLayoutOuter()
		UnregisterBagExpandLayout()
	end
	if event == "CURSOR_CHANGED" then
		if CursorHoldsItem() then
			layoutCheckOwed = true
			if _G.FluxChatFrame_SetDragHold then
				FluxChatFrame_SetDragHold(true)
			end
			return
		end
		if _G.FluxChatFrame_SetDragHold then
			FluxChatFrame_SetDragHold(false, true)
		end
		if not layoutCheckOwed then
			return
		end
		layoutCheckOwed = false
		UpdateOwnedSlots()
		RefreshIfSlotCountsChanged()
		if combined:IsShown() and not closing and not refreshing then
			RepinItemsQuiet()
		end
		return
	end
	if event == "BAG_UPDATE" then
		if CursorHoldsItem() then
			layoutCheckOwed = true
			return
		end
		UpdateOwnedSlots()
		RefreshIfSlotCountsChanged()
		if combined:IsShown() and not closing and not refreshing then
			RepinItemsQuiet()
		end
		return
	end
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		UpdateOwnedSlots()
		RefreshIfBagLayoutChanged()
		if combined:IsShown() and not closing and not refreshing and not CursorHoldsItem() then
			RepinItemsQuiet()
		end
		return
	end
	if event == "PLAYER_ENTERING_WORLD" and not combined:IsShown() then
		if SetChatDragHold then
			SetChatDragHold(false)
		end
	end
end)

