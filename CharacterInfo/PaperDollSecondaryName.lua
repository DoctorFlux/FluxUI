-- Forever title-bar toggle for CVar UnitSurnameOwn ("My surname" / secondary name).
-- Fits the Character Info header, left of the name, next to the class/spec icon.
-- Does not move Blizzard's title text.
local _, ns = ...
local Flux = ns.Flux
local module = ns.CharacterStats
if not module then
	return
end

local SURNAME_OWN_CVAR = "UnitSurnameOwn"
local FALLBACK_LABEL = "Secondary name"
local CHECK_SIZE = 20
local LABEL_GAP = 3

local toggleRow
local surnameCheck
local syncingFromGame = false

local function PlayerNameAPI()
	return Flux and Flux.PlayerName
end

local function UniqueNamesEnabled()
	local PN = PlayerNameAPI()
	return PN and PN.UsesRegionalUniqueNames and PN.UsesRegionalUniqueNames() or false
end

local function GetLabel()
	local s = rawget(_G, "UNIT_SECONDARY_NAME_OWN")
	if type(s) == "string" and s ~= "" then
		return s
	end
	return FALLBACK_LABEL
end

local function GetTooltip()
	local s = rawget(_G, "OPTION_TOOLTIP_UNIT_SECONDARY_NAME_OWN")
	if type(s) == "string" and s ~= "" then
		return s
	end
	return nil
end

local function ShouldShowSurname()
	local PN = PlayerNameAPI()
	if PN and PN.ShouldDisplaySurname then
		return PN.ShouldDisplaySurname() and true or false
	end
	return false
end

local function ApplyShowSurname(enabled)
	local PN = PlayerNameAPI()
	if PN and PN.SetDisplaySurname then
		PN.SetDisplaySurname(enabled and true or false)
	end
	local UF = ns.UnitFrames
	if UF and UF.RefreshSelfDisplayNames then
		UF.RefreshSelfDisplayNames()
	end
end

local function SetCheckboxChecked(checkbox, checked)
	if not checkbox then
		return
	end
	syncingFromGame = true
	checkbox:SetChecked(checked and true or false)
	syncingFromGame = false
end

local function SyncFromGame()
	if not surnameCheck then
		return
	end
	SetCheckboxChecked(surnameCheck, ShouldShowSurname())
end

local function GetCharacterFrame()
	return _G.CharacterFrame
end

local function TitleShowsPlayerName()
	local cf = GetCharacterFrame()
	if not cf then
		return false
	end
	local active = cf.activeSubframe
	return active == nil or active == "PaperDollFrame"
end

local function SafeStringWidth(fs)
	if not fs or type(fs.GetStringWidth) ~= "function" then
		return 0
	end
	local ok, w = pcall(fs.GetStringWidth, fs)
	if ok and type(w) == "number" then
		return w
	end
	return 0
end

local function GetTitleText(cf)
	if not cf then
		return nil
	end
	if type(cf.GetTitleText) == "function" then
		local ok, fs = pcall(cf.GetTitleText, cf)
		if ok and fs then
			return fs
		end
	end
	local container = cf.TitleContainer
	return container and container.TitleText
end

local function SafeRegionWidth(region)
	if not region or type(region.GetWidth) ~= "function" then
		return 0
	end
	local ok, w = pcall(region.GetWidth, region)
	if ok and type(w) == "number" then
		return w
	end
	return 0
end

local function IsRightPaneCollapsed()
	local cf = GetCharacterFrame()
	if cf and type(cf.IsRightPaneCollapsed) == "function" then
		local ok, collapsed = pcall(cf.IsRightPaneCollapsed, cf)
		if ok and collapsed then
			return true
		end
	end
	return false
end

local function LabelWouldOverlapTitle()
	local cf = GetCharacterFrame()
	local container = cf and cf.TitleContainer
	if not container then
		return true
	end
	if IsRightPaneCollapsed() then
		return true
	end
	local containerW = SafeRegionWidth(container)
	local titleW = SafeStringWidth(GetTitleText(cf))
	local labelW = CHECK_SIZE + LABEL_GAP + SafeStringWidth(surnameCheck and surnameCheck.text) + 8
	if containerW <= 0 then
		return false
	end
	-- Blizzard title is stretched across the header and drawn centered.
	local nameLeft = (containerW * 0.5) - (titleW * 0.5)
	return labelW + 4 > nameLeft
end

local function GetPortrait(cf)
	if not cf then
		return nil
	end
	if type(cf.GetPortrait) == "function" then
		local ok, portrait = pcall(cf.GetPortrait, cf)
		if ok and portrait then
			return portrait
		end
	end
	local container = cf.PortraitContainer
	return container and container.portrait
end

local function LayoutToggleRow()
	if not toggleRow or not surnameCheck then
		return
	end
	if surnameCheck.text then
		surnameCheck.text:SetText(GetLabel())
	end
	local labelW = SafeStringWidth(surnameCheck.text)
	toggleRow:SetWidth(CHECK_SIZE + LABEL_GAP + labelW + 2)
	surnameCheck:SetHitRectInsets(-1, -(LABEL_GAP + labelW + 2), -1, -1)
end

local function AnchorToggle()
	if not toggleRow then
		return
	end
	local cf = GetCharacterFrame()
	if not cf then
		return
	end
	local container = cf.TitleContainer
	local host = container or cf
	if toggleRow:GetParent() ~= cf then
		toggleRow:SetParent(cf)
	end
	toggleRow:SetFrameStrata(host:GetFrameStrata())
	toggleRow:SetFrameLevel((host:GetFrameLevel() or 510) + 8)
	LayoutToggleRow()
	toggleRow:ClearAllPoints()
	toggleRow:SetHeight(CHECK_SIZE)

	-- Keep Blizzard's name in place. If the header is too narrow (side pane hidden),
	-- sit just under the title at the left, still next to the class icon, with the
	-- label visible so players can see what the checkmark is for.
	local belowTitle = LabelWouldOverlapTitle()
	if container then
		if belowTitle then
			toggleRow:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 2, -2)
		else
			toggleRow:SetPoint("TOPLEFT", container, "TOPLEFT", 2, 0)
			toggleRow:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 2, 0)
		end
	else
		toggleRow:SetPoint("TOPLEFT", cf, "TOPLEFT", 58, belowTitle and -22 or -1)
	end
end

local function ShouldShowToggle()
	return UniqueNamesEnabled() and TitleShowsPlayerName()
end

local function CreateSurnameCheckbox(parent)
	local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	checkbox:SetSize(CHECK_SIZE, CHECK_SIZE)
	checkbox:EnableMouse(true)
	checkbox:RegisterForClicks("LeftButtonUp")

	local labelText = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	labelText:SetPoint("LEFT", checkbox, "RIGHT", LABEL_GAP, 0)
	labelText:SetText(GetLabel())
	labelText:SetTextColor(1, 0.82, 0, 1)
	checkbox.text = labelText

	checkbox:SetScript("OnClick", function(self)
		if syncingFromGame then
			return
		end
		local newValue = not ShouldShowSurname()
		ApplyShowSurname(newValue)
		SetCheckboxChecked(self, newValue)
	end)

	checkbox:SetScript("OnEnter", function()
		if not GameTooltip then
			return
		end
		local label = GetLabel()
		local tooltip = GetTooltip()
		GameTooltip:SetOwner(checkbox, "ANCHOR_RIGHT")
		GameTooltip:SetText(label, 1, 1, 1)
		if tooltip then
			GameTooltip:AddLine(tooltip, 0.8, 0.8, 0.8, true)
		end
		GameTooltip:Show()
	end)
	checkbox:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)

	return checkbox
end

local function EnsureToggle()
	if not ShouldShowToggle() then
		if toggleRow then
			toggleRow:Hide()
		end
		return
	end

	if toggleRow then
		toggleRow:Show()
		AnchorToggle()
		SyncFromGame()
		return
	end

	local cf = GetCharacterFrame()
	if not cf then
		return
	end

	toggleRow = CreateFrame("Frame", "FluxPaperDollSecondaryNameRow", cf)
	toggleRow:SetSize(CHECK_SIZE, CHECK_SIZE)

	surnameCheck = CreateSurnameCheckbox(toggleRow)
	surnameCheck:SetPoint("LEFT", toggleRow, "LEFT", 0, 0)

	AnchorToggle()
	SyncFromGame()
	toggleRow:Show()
end

local function IsCamelotClient()
	return Flux and Flux.Client and Flux.Client.isCamelot == true
end

local function HookCharacterFrame()
	local cf = GetCharacterFrame()
	if not cf then
		return
	end
	-- OnShow calls UpdateTitle/UpdateSize before the secret health compare.
	-- Post-hooks on those methods taint the compare. Run after ToggleCharacter.
	if IsCamelotClient() then
		local info = rawget(_G, "FluxInfoFrame")
		if info and info.AfterCharacterShown and not cf._fluxSecondaryNameAfterOpen then
			cf._fluxSecondaryNameAfterOpen = true
			info.AfterCharacterShown(function()
				EnsureToggle()
				SyncFromGame()
				AnchorToggle()
			end)
		end
		if type(cf.SetRightPaneCollapsed) == "function" and not cf._fluxSecondaryNameCollapseHook and type(hooksecurefunc) == "function" then
			cf._fluxSecondaryNameCollapseHook = true
			hooksecurefunc(cf, "SetRightPaneCollapsed", function()
				AnchorToggle()
			end)
		end
		return
	end
	if cf.HookScript and not cf._fluxSecondaryNameOnShow then
		cf._fluxSecondaryNameOnShow = true
		cf:HookScript("OnShow", function()
			EnsureToggle()
			SyncFromGame()
		end)
	end
	if type(cf.UpdateTitle) == "function" and not cf._fluxSecondaryNameTitleHook then
		cf._fluxSecondaryNameTitleHook = true
		if type(hooksecurefunc) == "function" then
			hooksecurefunc(cf, "UpdateTitle", function()
				EnsureToggle()
				SyncFromGame()
			end)
		end
	end
	if type(cf.UpdateSize) == "function" and not cf._fluxSecondaryNameSizeHook then
		cf._fluxSecondaryNameSizeHook = true
		if type(hooksecurefunc) == "function" then
			hooksecurefunc(cf, "UpdateSize", function()
				AnchorToggle()
			end)
		end
	end
	if type(cf.SetRightPaneCollapsed) == "function" and not cf._fluxSecondaryNameCollapseHook then
		cf._fluxSecondaryNameCollapseHook = true
		if type(hooksecurefunc) == "function" then
			hooksecurefunc(cf, "SetRightPaneCollapsed", function()
				AnchorToggle()
			end)
		end
	end
	if cf.HookScript and not cf._fluxSecondaryNameOnSize then
		cf._fluxSecondaryNameOnSize = true
		cf:HookScript("OnSizeChanged", function()
			AnchorToggle()
		end)
	end
end

local syncFrame = CreateFrame("Frame")
syncFrame:RegisterEvent("CVAR_UPDATE")
syncFrame:RegisterEvent("UNIT_NAME_UPDATE")
syncFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "CVAR_UPDATE" then
		if type(arg1) == "string" and string.lower(arg1) == string.lower(SURNAME_OWN_CVAR) then
			EnsureToggle()
			SyncFromGame()
		end
		return
	end
	if event == "UNIT_NAME_UPDATE" and arg1 == "player" then
		EnsureToggle()
		SyncFromGame()
	end
end)

function module.InstallSecondaryName()
	if not UniqueNamesEnabled() then
		if toggleRow then
			toggleRow:Hide()
		end
		return false
	end
	HookCharacterFrame()
	EnsureToggle()
	return toggleRow ~= nil
end
