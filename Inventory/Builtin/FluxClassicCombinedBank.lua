-- Era / Anniversary character bank. The live Blizzard BankFrame retains bank
-- events and purchase state; its own buttons are hosted in a combined window.
-- Blizzard remains the owner of item clicks, tooltips, slot purchases and bags.
local addonName, ns = ...
local Flux = ns.Flux or _G.Flux
local client = Flux and Flux.Client
if not client or not (client.isEra or client.isAnniversary) then return end

local function UsesAltBag()
	if _G.FluxUI_UsesAlternativeBagUI and _G.FluxUI_UsesAlternativeBagUI() then return true end
	if _G.Bagnon or _G.Bagnonium then return true end
	local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
	if loaded then
		local ok, on = pcall(loaded, "Baganator")
		if ok and on then return true end
	end
	return _G.Baganator and _G.Baganator.API ~= nil
end

if UsesAltBag() then return end

local COLUMNS, ITEM, GAP = 10, 37, 5
local Unpack = unpack or table.unpack
local WIDTH, TOP, BOTTOM = COLUMNS * ITEM + (COLUMNS - 1) * GAP + 15, 106, 40
local BANK_ICON = "Interface\\Icons\\INV_Misc_Coin_02"
local frame = CreateFrame("Frame", "FluxCombinedBank", UIParent)
frame:SetSize(WIDTH, 400)
frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 45, -85)
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:SetToplevel(true)
frame:SetFrameStrata("HIGH")
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

local function ApplyChrome(target)
	local border = _G.FluxBorder
	if not border or not border.ApplyTo then return end
	if target.FluxBorderFrame and border.RemoveFrom then border:RemoveFrom(target) end
	border:ApplyTo(target, -4, -4, -5, -4)
	if not target.FluxBorderFrame then return end
	border:SetBorderColor(target, 1, 1, 1, 1)
	border:SetBackdropColor(target, 0.14, 0.14, 0.15, 0.96)
	local level = target:GetFrameLevel()
	target.FluxBorderFrame:SetFrameLevel(level + (target == frame and 30 or 4))
	local fill = target.FluxBorderFrame.BackgroundFrame
	if fill then
		fill:SetFrameLevel(level + (target == frame and 1 or 3))
		fill:ClearAllPoints()
		fill:SetPoint("TOPLEFT", target, "TOPLEFT", -5, 0)
		fill:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 5, -4)
	end
end

local topStrip = CreateFrame("Frame", nil, frame)
topStrip:SetFrameLevel(frame:GetFrameLevel() + 2)
topStrip:SetHeight(26)
topStrip:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 0)
topStrip:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 0)
local goldStrip = CreateFrame("Frame", nil, frame)
goldStrip:SetFrameLevel(frame:GetFrameLevel() + 2)
goldStrip:SetHeight(34)
goldStrip:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -2, -2)
goldStrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)

local portrait = CreateFrame("Frame", nil, frame)
portrait:SetSize(58, 58)
portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", -15, 15)
portrait:SetFrameLevel(frame:GetFrameLevel() + 40)
local portraitIcon = portrait:CreateTexture(nil, "ARTWORK")
portraitIcon:SetSize(54, 54)
portraitIcon:SetPoint("CENTER")
portraitIcon:SetTexture(BANK_ICON)
if portrait.CreateMaskTexture then
	local mask = portrait:CreateMaskTexture()
	mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetSize(42, 42)
	mask:SetPoint("CENTER", portraitIcon, "CENTER")
	portraitIcon:AddMaskTexture(mask)
end
local function ApplyPortraitRing()
	local border = _G.FluxBorder
	if border and border.ApplyCircle and not frame.FluxPortraitRing then
		frame.FluxPortraitRing = border:ApplyCircle(portrait, 58, 1, 1, 1)
	end
end
portrait:SetScript("OnShow", ApplyPortraitRing)

local titleHost = CreateFrame("Frame", nil, topStrip)
titleHost:SetAllPoints(topStrip)
titleHost:SetFrameLevel(topStrip:GetFrameLevel() + 35)
local title = titleHost:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("CENTER", titleHost, "CENTER", 10, 0)
title:SetText(_G.BANK or "Bank")
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 4)
close:SetFrameLevel(frame:GetFrameLevel() + 40)
close:SetScript("OnClick", function()
	if _G.BankFrame and _G.HideUIPanel then HideUIPanel(BankFrame) end
end)

local slotRow = CreateFrame("Frame", nil, frame)
slotRow:SetID(_G.BANK_CONTAINER or -1)
slotRow:SetSize(WIDTH - 44, 40)
slotRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -64)
slotRow:SetFrameLevel(frame:GetFrameLevel() + 25)

local grid = CreateFrame("Frame", nil, frame)
grid:SetID(_G.BANK_CONTAINER or -1)
grid:SetFrameLevel(frame:GetFrameLevel() + 5)
grid:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -TOP)
grid:SetWidth(WIDTH - 15)
grid:SetHeight(1)

local active, releasing, pending = false, false, false
local bank, bankAlpha, bankMouse
local parked = {}
local hosts = {}
local ghosted = {}
local slotScripts = {}
local slotHighlightAlpha = {}
local visuals = {}

local function CaptureTexture(texture)
	if not texture then return end
	local points = {}
	for i = 1, texture:GetNumPoints() do points[i] = { texture:GetPoint(i) } end
	return { texture = texture, file = texture:GetTexture(), atlas = texture.GetAtlas and texture:GetAtlas(),
		width = texture:GetWidth(), height = texture:GetHeight(), alpha = texture:GetAlpha(), points = points }
end

local function RestoreTexture(saved)
	if not saved then return end
	local texture = saved.texture
	if saved.atlas and texture.SetAtlas then texture:SetAtlas(saved.atlas) else texture:SetTexture(saved.file) end
	texture:SetAlpha(saved.alpha)
	texture:SetSize(saved.width, saved.height)
	texture:ClearAllPoints()
	for i = 1, #saved.points do texture:SetPoint(Unpack(saved.points[i])) end
end

local function BankItemEmpty(button)
	local icon = button.icon or button.Icon or (button.GetName and _G[button:GetName() .. "IconTexture"])
	if not icon or not icon.IsShown or not icon:IsShown() then return true end
	local texture = icon.GetTexture and icon:GetTexture()
	return texture == nil or texture == "" or texture == 0
end

local function SetEmptyArt(button, key, atlas, layer, sublevel)
	local texture = button[key]
	if not texture then
		texture = button:CreateTexture(nil, layer, nil, sublevel)
		texture:SetAllPoints(button)
		button[key] = texture
	end
	if _G.C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) and texture.SetAtlas then
		texture:SetAtlas(atlas)
	end
	texture:Show()
end

local function StyleItem(button, id)
	local normal = button.GetNormalTexture and button:GetNormalTexture()
	local pushed = button.GetPushedTexture and button:GetPushedTexture()
	if not visuals[button] then visuals[button] = { normal = CaptureTexture(normal), pushed = CaptureTexture(pushed) } end
	local empty = BankItemEmpty(button)
	if normal then
		normal:SetTexture("Interface\\Buttons\\UI-Quickslot2")
		normal:ClearAllPoints()
		normal:SetSize(64, 64)
		normal:SetPoint("CENTER", button, "CENTER", 0, -1)
	end
	if pushed then pushed:ClearAllPoints(); pushed:SetAllPoints(button) end
	if empty then
		SetEmptyArt(button, "FluxBankEmptyBg", "UI-HUD-ActionBar-IconFrame-Background", "BACKGROUND", 0)
		SetEmptyArt(button, "FluxBankEmptyArt", "ui-hud-actionbar-iconframe-slot", "BACKGROUND", 1)
		if normal and normal.SetAtlas and _G.C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("UI-HUD-ActionBar-IconFrame") then
			normal:SetAtlas("UI-HUD-ActionBar-IconFrame")
			normal:ClearAllPoints()
			normal:SetAllPoints(button)
		end
	else
		if button.FluxBankEmptyBg then button.FluxBankEmptyBg:Hide() end
		if button.FluxBankEmptyArt then button.FluxBankEmptyArt:Hide() end
	end
	local qualityBorder = button.IconBorder or button.FluxBankQualityBorder
	local info = not empty and C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(id, button:GetID())
	local colors = _G.ITEM_QUALITY_COLORS or _G.BAG_ITEM_QUALITY_COLORS
	local color = info and colors and colors[info.quality]
	if color then
		if not qualityBorder then
			qualityBorder = button:CreateTexture(nil, "OVERLAY", nil, 2)
			qualityBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
			qualityBorder:SetSize(37, 37)
			qualityBorder:SetPoint("CENTER", button, "CENTER")
			button.FluxBankQualityBorder = qualityBorder
		end
		qualityBorder:SetVertexColor(color.r, color.g, color.b)
		qualityBorder:Show()
	elseif qualityBorder then
		qualityBorder:Hide()
	end
end

local function PlaceBankBag(self)
	if _G.CursorHasItem and CursorHasItem() and _G.PutItemInBag then
		PutItemInBag(self:GetInventorySlot())
	end
end

local function SaveAndMove(button, parent)
	if not button then return end
	if not parked[button] then
		local points = {}
		for i = 1, button:GetNumPoints() do
			points[i] = { button:GetPoint(i) }
		end
		parked[button] = { parent = button:GetParent(), points = points }
	end
	button:SetParent(parent)
	button:ClearAllPoints()
end

local function ReturnButtons()
	for button, saved in pairs(visuals) do
		RestoreTexture(saved.normal)
		RestoreTexture(saved.pushed)
		if button.FluxBankEmptyBg then button.FluxBankEmptyBg:Hide() end
		if button.FluxBankEmptyArt then button.FluxBankEmptyArt:Hide() end
		if button.FluxBankQualityBorder then button.FluxBankQualityBorder:Hide() end
		visuals[button] = nil
	end
	for texture, alpha in pairs(slotHighlightAlpha) do
		texture:SetAlpha(alpha)
		slotHighlightAlpha[texture] = nil
	end
	for button, scripts in pairs(slotScripts) do
		button:SetScript("OnClick", scripts.click)
		button:SetScript("OnReceiveDrag", scripts.drop)
		slotScripts[button] = nil
	end
	for button, old in pairs(parked) do
		button:SetParent(old.parent)
		button:ClearAllPoints()
		for i = 1, #old.points do
			button:SetPoint(Unpack(old.points[i]))
		end
		parked[button] = nil
	end
	for button, host in pairs(hosts) do
		host:Hide()
		hosts[button] = nil
	end
end

local function GhostContainer(container)
	if ghosted[container] then return end
	ghosted[container] = { alpha = container:GetAlpha(), mouse = container:IsMouseEnabled() }
	container:SetAlpha(0)
	container:EnableMouse(false)
end

local function RestoreContainers()
	for container, old in pairs(ghosted) do
		container:SetAlpha(old.alpha)
		container:EnableMouse(old.mouse)
		ghosted[container] = nil
	end
end

local function FindContainer(id)
	for i = 1, (_G.NUM_CONTAINER_FRAMES or 13) do
		local container = _G["ContainerFrame" .. i]
		if container and container:IsShown() and container:GetID() == id then return container end
	end
end

local function OpenBankBags()
	if not (C_Container and C_Container.GetContainerNumSlots and _G.OpenBag) then return end
	local count = (_G.GetNumBankSlots and GetNumBankSlots()) or 0
	local missing = {}
	for index = 1, count do
		local id = (_G.NUM_BAG_SLOTS or 4) + index
		if (C_Container.GetContainerNumSlots(id) or 0) > 0 and not FindContainer(id) then
			missing[#missing + 1] = id
		end
	end
	if #missing == 0 then return end
	-- ContainerFrame_GenerateFrame can reassign an existing frame to a newly
	-- opened bank bag. Its SetPoint calls require every old item to be back
	-- under that frame before OpenBag starts regeneration.
	ReturnButtons()
	RestoreContainers()
	for i = 1, #missing do OpenBag(missing[i]) end
end

local function HostButton(button, id)
	local host = hosts[button]
	if not host then
		host = CreateFrame("Frame", nil, grid)
		hosts[button] = host
	end
	host:SetParent(grid)
	host:SetID(id)
	host:SetSize(ITEM, ITEM)
	host:SetFrameLevel(grid:GetFrameLevel() + 2)
	SaveAndMove(button, host)
	button:SetSize(ITEM, ITEM)
	button:SetAllPoints(host)
	button:Show()
	host:Show()
	StyleItem(button, id)
	return host
end

local function LayoutItems()
	local entries, used = {}, {}
	local slots = _G.BankSlotsFrame
	local generic = _G.NUM_BANKGENERIC_SLOTS or 28
	for i = 1, generic do
		local button = slots and slots["Item" .. i]
		if button then
			local host = HostButton(button, _G.BANK_CONTAINER or -1)
			entries[#entries + 1] = host
			used[host] = true
		end
	end
	local purchased = (_G.GetNumBankSlots and GetNumBankSlots()) or 0
	for index = 1, purchased do
		local id = (_G.NUM_BAG_SLOTS or 4) + index
		local container = FindContainer(id)
		if container then
			local name = container:GetName()
			local count = container.size or (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(id)) or 0
			local buttons = {}
			for i = 1, count do
				local button = name and _G[name .. "Item" .. i]
				if button then buttons[#buttons + 1] = button end
			end
			table.sort(buttons, function(a, b) return a:GetID() < b:GetID() end)
			for i = 1, #buttons do
				local host = HostButton(buttons[i], id)
				entries[#entries + 1] = host
				used[host] = true
			end
			GhostContainer(container)
		end
	end
	for _, host in pairs(hosts) do
		if not used[host] then host:Hide() end
	end
	for i = 1, #entries do
		local col = (i - 1) % COLUMNS
		local row = math.floor((i - 1) / COLUMNS)
		entries[i]:ClearAllPoints()
		entries[i]:SetPoint("TOPLEFT", grid, "TOPLEFT", col * (ITEM + GAP), -row * (ITEM + GAP))
	end
	local rows = math.max(1, math.ceil(#entries / COLUMNS))
	grid:SetHeight(rows * (ITEM + GAP))
	local height = TOP + rows * (ITEM + GAP) + BOTTOM
	frame:SetHeight(height)
	local screen = UIParent:GetHeight() or 768
	frame:SetScale(math.min(1, (screen - 105) / height))
	ApplyChrome(frame)
end

local function LayoutSlots()
	local slots = _G.BankSlotsFrame
	if not slots then return end
	local previous
	for i = 1, (_G.NUM_BANKBAGSLOTS or 7) do
		local button = slots["Bag" .. i]
		if button then
			local highlight = button.HighlightFrame and button.HighlightFrame.HighlightTexture
			if highlight then
				if slotHighlightAlpha[highlight] == nil then slotHighlightAlpha[highlight] = highlight:GetAlpha() end
				highlight:SetAlpha(0)
			end
			if not slotScripts[button] then
				slotScripts[button] = { click = button:GetScript("OnClick"), drop = button:GetScript("OnReceiveDrag") }
				button:SetScript("OnClick", PlaceBankBag)
				button:SetScript("OnReceiveDrag", PlaceBankBag)
			end
			SaveAndMove(button, slotRow)
			button:SetSize(ITEM, ITEM)
			if not previous then
				button:SetPoint("RIGHT", slotRow, "RIGHT")
			else
				button:SetPoint("RIGHT", previous, "LEFT")
			end
			button:Show()
			previous = button
		end
	end
	if _G.UpdateBagSlotStatus then UpdateBagSlotStatus() end
end

local function MoveBankDetails()
	local purchase = _G.BankFramePurchaseButton
	local cost = _G.BankFrameDetailMoneyFrame
	local purchased, full = _G.GetNumBankSlots and GetNumBankSlots()
	full = full or (type(purchased) == "number" and purchased >= (_G.NUM_BANKBAGSLOTS or 7))
	if purchase then
		SaveAndMove(purchase, goldStrip)
		purchase:SetPoint("LEFT", goldStrip, "LEFT", 10, 0)
		purchase:SetFrameLevel(goldStrip:GetFrameLevel() + 5)
		purchase:SetShown(not full)
	end
	if cost then
		SaveAndMove(cost, goldStrip)
		cost:SetPoint("LEFT", goldStrip, "LEFT", 145, 0)
		cost:SetFrameLevel(goldStrip:GetFrameLevel() + 5)
		cost:SetShown(not full)
	end
	local money = _G.BankFrameMoneyFrame
	if money then
		SaveAndMove(money, goldStrip)
		money:SetPoint("RIGHT", goldStrip, "RIGHT", -12, 0)
		money:SetFrameLevel(goldStrip:GetFrameLevel() + 5)
	end
end

local function Release()
	if not active or releasing then return end
	releasing = true
	active = false
	ReturnButtons()
	RestoreContainers()
	if bank then
		bank:SetAlpha(bankAlpha or 1)
		bank:EnableMouse(bankMouse)
	end
	frame:Hide()
	bank, bankAlpha, bankMouse = nil, nil, nil
	releasing = false
end

local function Refresh()
	if not active or releasing then return end
	if UsesAltBag() or not bank or not bank:IsShown() then
		Release()
		return
	end
	OpenBankBags()
	LayoutSlots()
	MoveBankDetails()
	LayoutItems()
end

local function ScheduleRefresh()
	if pending or not active then return end
	pending = true
	local function run()
		pending = false
		Refresh()
	end
	if C_Timer and C_Timer.After then C_Timer.After(0, run) else run() end
end

local function Activate(native)
	if active or UsesAltBag() or not native or not native:IsShown() then return end
	if not (_G.BankSlotsFrame and _G.BankFramePurchaseButton and _G.BankFrameDetailMoneyFrame and _G.BankFrameMoneyFrame) then return end
	bank = native
	bankAlpha, bankMouse = bank:GetAlpha(), bank:IsMouseEnabled()
	active = true
	bank:SetAlpha(0)
	bank:EnableMouse(false)
	title:SetText((_G.UnitName and UnitName("npc")) or _G.BANK or "Bank")
	ApplyChrome(frame)
	ApplyChrome(topStrip)
	ApplyChrome(goldStrip)
	ApplyPortraitRing()
	frame:Show()
	Refresh()
end

frame:SetScript("OnHide", function()
	if active and not releasing and bank and bank:IsShown() and _G.HideUIPanel then
		HideUIPanel(bank)
	end
end)

if _G.UISpecialFrames then table.insert(UISpecialFrames, "FluxCombinedBank") end

local hooked
local function Install()
	local native = _G.BankFrame
	if hooked or not native or not native.HookScript then return end
	hooked = true
	native:HookScript("OnShow", Activate)
	native:HookScript("OnHide", Release)
	if native:IsShown() then Activate(native) end
end

Install()
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("BANKFRAME_OPENED")
watcher:RegisterEvent("BANKFRAME_CLOSED")
watcher:RegisterEvent("BAG_UPDATE")
watcher:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
watcher:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
watcher:RegisterEvent("PLAYER_MONEY")
watcher:SetScript("OnEvent", function(_, event)
	if UsesAltBag() then
		Release()
		return
	end
	if event == "ADDON_LOADED" or event == "PLAYER_ENTERING_WORLD" then Install() end
	if event == "BANKFRAME_CLOSED" then Release() else ScheduleRefresh() end
end)
