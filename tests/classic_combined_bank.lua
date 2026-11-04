-- Exercise the loaded bank window's native button ownership and late handoff.
local checks = 0
local Unpack = unpack or table.unpack
local function check(value, label)
	checks = checks + 1
	assert(value, label)
end

local objects = {}
local allObjects = {}
local function object(name, parent)
	local value = { name = name, parent = parent, shown = false, alpha = 1, mouse = true, points = {}, level = 1, id = 0 }
	allObjects[#allObjects + 1] = value
	function value:SetSize(w, h) self.width, self.height = w, h end
	function value:SetWidth(w) self.width = w end
	function value:SetHeight(h) self.height = h end
	function value:GetWidth() return self.width or 37 end
	function value:GetHeight() return self.height or 768 end
	function value:SetTexture(texture) self.texture = texture; self.atlas = nil end
	function value:GetTexture() return self.texture end
	function value:SetAtlas(atlas) self.atlas = atlas; self.texture = nil end
	function value:GetAtlas() return self.atlas end
	function value:SetVertexColor() end
	function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
	function value:ClearAllPoints() self.points = {} end
	function value:GetNumPoints() return #self.points end
	function value:GetPoint(i) return Unpack(self.points[i]) end
	function value:SetAllPoints(other) self.allPoints = other end
	function value:SetParent(p) self.parent = p end
	function value:GetParent() return self.parent end
	function value:GetName() return self.name end
	function value:SetID(id) self.id = id end
	function value:GetID() return self.id end
	function value:SetFrameLevel(level) self.level = level end
	function value:GetFrameLevel() return self.level end
	function value:SetAlpha(alpha) self.alpha = alpha end
	function value:GetAlpha() return self.alpha end
	function value:EnableMouse(on) self.mouse = on end
	function value:IsMouseEnabled() return self.mouse end
	function value:Show() self.shown = true; if self.hooks and self.hooks.OnShow then self.hooks.OnShow(self) end end
	function value:Hide() self.shown = false; if self.script and self.script.OnHide then self.script.OnHide(self) end; if self.hooks and self.hooks.OnHide then self.hooks.OnHide(self) end end
	function value:SetShown(on) if on then self:Show() else self:Hide() end end
	function value:IsShown() return self.shown end
	function value:SetScript(event, fn) self.script = self.script or {}; self.script[event] = fn end
	function value:GetScript(event) return self.script and self.script[event] end
	function value:HookScript(event, fn) self.hooks = self.hooks or {}; self.hooks[event] = fn end
	function value:RegisterEvent() end
	function value:RegisterForDrag() end
	function value:RegisterForClicks() end
	function value:SetFrameStrata() end
	function value:GetFrameStrata() return "HIGH" end
	function value:SetScale(scale) self.scale = scale end
	function value:GetSize() return self.width or 36, self.height or 36 end
	function value:SetClampedToScreen() end
	function value:SetMovable() end
	function value:SetToplevel() end
	function value:EnableMouseWheel() end
	function value:SetScrollChild(child) self.child = child end
	function value:GetVerticalScroll() return self.scroll or 0 end
	function value:SetVerticalScroll(n) self.scroll = n end
	function value:CreateTexture() local child = object(nil, self); function child:AddMaskTexture() end; return child end
	function value:CreateMaskTexture() return object(nil, self) end
	function value:CreateFontString() local child = object(nil, self); function child:SetText(s) self.text = s end; return child end
	if name then objects[name] = value; _G[name] = value end
	return value
end

UIParent = object("UIParent")
UIParent:SetHeight(768)
function CreateFrame(_, name, parent) return object(name, parent) end
local anniversary = arg and arg[1] == "anniversary"
BANK_CONTAINER, NUM_BANKGENERIC_SLOTS, NUM_BANKBAGSLOTS, NUM_BAG_SLOTS = -1, 28, anniversary and 7 or 6, 4
UISpecialFrames = {}
local loaded = arg and arg[2] == "early" or false
local cursorItem, originalSlotClicks, placedBags = false, 0, 0
CursorHasItem = function() return cursorItem end
PutItemInBag = function() placedBags = placedBags + 1; return true end
C_AddOns = { IsAddOnLoaded = function(name) return name == "Baganator" and loaded end }
local newBag, purchased = false, 1
C_Container = { GetContainerNumSlots = function(id) return id == 5 and (newBag and 0 or 16) or (newBag and id == 9 and 18 or 0) end }
GetNumBankSlots = function() return purchased, false end
UnitName = function() return "Banker" end
UpdateBagSlotStatus = function() end

BankFrame = object("BankFrame", UIParent)
BankSlotsFrame = object("BankSlotsFrame", BankFrame)
BankSlotsFrame:SetID(BANK_CONTAINER)
local item = {}
for i = 1, NUM_BANKGENERIC_SLOTS do
	item[i] = object("BankFrameItem" .. i, BankSlotsFrame)
	item[i].normal = object(nil, item[i])
	item[i].normal:SetTexture("native-bank-slot")
	item[i].GetNormalTexture = function(self) return self.normal end
	item[i].icon = object(nil, item[i])
	if i ~= 2 then item[i].icon:SetTexture("item-icon"); item[i].icon:Show() end
	item[i]:SetID(i)
	item[i]:SetPoint("TOPLEFT", BankSlotsFrame)
	BankSlotsFrame["Item" .. i] = item[i]
end
local bagSlot = {}
for i = 1, NUM_BANKBAGSLOTS do
	bagSlot[i] = object(nil, BankSlotsFrame)
	bagSlot[i]:SetID(i)
	bagSlot[i]:SetPoint("TOPLEFT", BankSlotsFrame)
	bagSlot[i]:SetScript("OnClick", function() originalSlotClicks = originalSlotClicks + 1 end)
	bagSlot[i]:SetScript("OnReceiveDrag", function() originalSlotClicks = originalSlotClicks + 1 end)
	bagSlot[i].HighlightFrame = { HighlightTexture = object(nil, bagSlot[i]) }
	bagSlot[i].GetInventorySlot = function(self) return 39 + self:GetID() end
	BankSlotsFrame["Bag" .. i] = bagSlot[i]
end
BankFramePurchaseInfo = object("BankFramePurchaseInfo", BankSlotsFrame)
BankFramePurchaseButton = object("BankFramePurchaseButton", BankFramePurchaseInfo)
BankFrameDetailMoneyFrame = object("BankFrameDetailMoneyFrame", BankFramePurchaseInfo)
BankFrameMoneyFrame = object("BankFrameMoneyFrame", BankSlotsFrame)
local bankBag = object("ContainerFrame1", UIParent)
ContainerFrame1 = bankBag
bankBag:SetID(5)
bankBag.size = 16
local bagItem
for i = 1, 16 do
	local button = object("ContainerFrame1Item" .. i, bankBag)
	_G["ContainerFrame1Item" .. i] = button
	button:SetID(i)
	if i == 1 then bagItem = button end
end
function OpenBag(id)
	if id == 9 then
		check(bagItem:GetParent() == bankBag, "hosted items return before Blizzard regenerates a reused container")
		bankBag:SetID(9)
		bankBag.size = 18
		bankBag:Show()
	elseif id == 5 then
		bankBag:SetID(5)
		bankBag.size = 16
		bankBag:Show()
	end
end
function HideUIPanel(panel) panel:Hide() end

local ns = { Flux = { Client = { isEra = not anniversary, isAnniversary = anniversary } } }
local source = assert(loadfile("Inventory/Builtin/FluxClassicCombinedBank.lua"))
source("_FluxUI", ns)
if loaded then
	check(objects.FluxCombinedBank == nil, "Baganator present at startup prevents custom bank creation")
	print("classic combined bank early Baganator: " .. checks .. " checks")
	return
end
local custom = assert(objects.FluxCombinedBank)
check(not custom:IsShown(), "bank starts hidden")
BankFrame:Show()
check(custom:IsShown() and BankFrame:GetAlpha() == 0, "combined bank replaces native appearance")
check(custom.width == 430 and custom.scale == 1, "bank uses the full ten-column bag window")
check(item[1].normal:GetTexture() == "Interface\\Buttons\\UI-Quickslot2", "filled bank items match bag slot art")
check(item[2].FluxBankEmptyArt ~= nil, "empty bank items get combined bag empty art")
check(item[10]:GetParent().points[1][4] == 9 * 42, "tenth item ends the first row")
check(item[11]:GetParent().points[1][5] == -42, "eleventh item starts the next row")
check(item[1]:GetParent():GetID() == BANK_CONTAINER, "native bank item keeps bank container ID")
check(bagItem:GetParent():GetID() == 5 and bagItem:GetParent() ~= bankBag, "native bank bag item keeps bag ID: " .. tostring(bankBag:IsShown()))
check(bagSlot[1]:GetParent():GetID() == BANK_CONTAINER, "native bag slot moved to bank row")
check(bagSlot[NUM_BANKBAGSLOTS]:GetParent():GetID() == BANK_CONTAINER, "last client bank bag slot is present")
check(BankFramePurchaseButton:GetParent() ~= BankFramePurchaseInfo, "native purchase control is visible in compact footer")
check(bagSlot[1].HighlightFrame.HighlightTexture:GetAlpha() == 0, "combined bank hides open-bag check mark")
check(bankBag:GetAlpha() == 0, "separate bank bag frame is hidden: " .. tostring(bankBag:GetAlpha()))
FluxVendorAutoMerchantUI = {
	CreateRestockStyleButton = function(parent, name) return object(name, parent) end,
	CreateRestockAutoToggle = function(parent)
		local toggle = object(nil, parent)
		function toggle:SetChecked(on) self.checked = on end
		return toggle
	end,
	SetRestockButtonEnabled = function() end,
}
FluxBankRestock = { IsAutoEnabled = function() return false end, GetCachedCanRunNow = function() return false end, IsRunning = function() return false end }
FluxRestock = { Inv = { Bank = { RegisterBankOpen = function() end, RegisterBankClose = function() end } } }
local restock = assert(loadfile("Inventory/Restock/Bank/FluxBankRestockButton.lua"))()
restock.AttachToBank()
local restockButton = assert(objects.FluxBankRestockButton)
check(restockButton:GetParent() == custom and restockButton:IsShown(), "restock button is hosted by combined bank: " .. tostring(restockButton:GetParent() == custom) .. "/" .. tostring(restockButton:IsShown()))
check(restockButton.points[1][1] == "TOPLEFT" and restockButton.points[1][4] == 65, "restock button clears bank bag row")
bagSlot[1].script.OnClick(bagSlot[1], "LeftButton")
check(originalSlotClicks == 0 and placedBags == 0, "plain bank slot click does not toggle a bag")
cursorItem = true
bagSlot[1].script.OnReceiveDrag(bagSlot[1])
check(placedBags == 1, "dropping a bag equips it in the bank slot")
cursorItem = false
local watcher
for _, value in ipairs(allObjects) do
	if value.script and value.script.OnEvent then watcher = value end
end
check(watcher ~= nil, "bank watcher exists")
newBag, purchased = true, 5
watcher.script.OnEvent(watcher, "BAG_UPDATE")
check(bankBag:GetID() == 9 and bagItem:GetParent():GetID() == 9, "newly equipped bank bag is rehosted after regeneration")
purchased = NUM_BANKBAGSLOTS
watcher.script.OnEvent(watcher, "PLAYERBANKBAGSLOTS_CHANGED")
check(not BankFramePurchaseButton:IsShown() and not BankFrameDetailMoneyFrame:IsShown(), "full bank hides purchase and next-slot cost")
check(BankFrameMoneyFrame:GetParent() ~= BankSlotsFrame, "full bank still shows current money")
loaded = true
watcher.script.OnEvent(watcher, "ADDON_LOADED")
check(not custom:IsShown() and BankFrame:GetAlpha() == 1, "late Baganator releases custom bank")
FluxUI_UsesAlternativeBagUI = function() return true end
local baganatorView = object("BaganatorBankView", UIParent)
baganatorView:Show()
FluxBaganatorCompat = { GetActiveBaganatorBankView = function() return baganatorView end }
restock.AttachToBank()
check(restockButton:GetParent() == baganatorView, "restock button returns to Baganator view")
check(item[1]:GetParent() == BankSlotsFrame and bagSlot[1]:GetParent() == BankSlotsFrame, "native bank buttons restored")
check(item[1].normal:GetTexture() == "native-bank-slot", "native bank item art restores after handoff")
check(bagItem:GetParent() == bankBag and bankBag:GetAlpha() == 1, "native bank bag restored")
check(bagSlot[1].HighlightFrame.HighlightTexture:GetAlpha() == 1, "bank bag highlight restores after handoff")
bagSlot[1].script.OnClick(bagSlot[1], "LeftButton")
check(originalSlotClicks == 1, "Baganator handoff restores native bank slot click")
loaded = false
FluxUI_UsesAlternativeBagUI = nil
newBag, purchased = false, 1
BankFrame:Hide()
BankFrame:Show()
check(custom:IsShown(), "bank reopens after Baganator unloads")
custom:Hide()
check(not BankFrame:IsShown(), "custom close closes native bank session")
check(item[1]:GetParent() == BankSlotsFrame, "custom close restores native buttons")
print("classic combined bank: " .. checks .. " checks")
