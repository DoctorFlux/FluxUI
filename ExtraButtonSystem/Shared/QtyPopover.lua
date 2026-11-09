-- ExtraButtonSystem/Shared/QtyPopover.lua — restock target qty (writes ConsumableBest persist).
local addonName, ns = ...
local Flux = ns.Flux
local EBS = Flux.EBS

local Qty = {}
EBS.QtyPopover = Qty

local frame

local function Ensure()
	if frame then
		return frame
	end
	frame = CreateFrame("Frame", "FluxEBSQtyPopover", UIParent, "BackdropTemplate")
	frame:SetSize(180, 72)
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:Hide()
	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
	end
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", 0, -10)
	title:SetText("Restock amount")
	frame.title = title
	local edit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	edit:SetSize(60, 20)
	edit:SetPoint("LEFT", 20, -6)
	edit:SetAutoFocus(true)
	edit:SetNumeric(true)
	edit:SetMaxLetters(5)
	frame.edit = edit
	local ok = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	ok:SetSize(50, 22)
	ok:SetPoint("LEFT", edit, "RIGHT", 8, 0)
	ok:SetText("OK")
	ok:SetScript("OnClick", function()
		local n = tonumber(edit:GetText())
		if frame.kind and FluxConsumableBest and FluxConsumableBest.Persist then
			FluxConsumableBest.Persist.SetRestockTarget(frame.kind, n)
		end
		frame:Hide()
	end)
	edit:SetScript("OnEnterPressed", function()
		ok:Click()
	end)
	edit:SetScript("OnEscapePressed", function()
		frame:Hide()
	end)
	return frame
end

function Qty.Show(kind, anchor)
	local f = Ensure()
	f.kind = kind
	local cur = FluxConsumableBest and FluxConsumableBest.Persist and FluxConsumableBest.Persist.GetRestockTarget(kind)
	f.edit:SetText(cur and tostring(cur) or "20")
	f:ClearAllPoints()
	if anchor then
		f:SetPoint("BOTTOM", anchor, "TOP", 0, 8)
	else
		f:SetPoint("CENTER")
	end
	f:Show()
	f.edit:SetFocus()
end
