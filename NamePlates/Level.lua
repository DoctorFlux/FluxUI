-- NamePlates/Level.lua — "Lvl. N" on every client, framed by a nameplate border.
-- Anchor stays RIGHT of the health container BOTTOMRIGHT, offset -2, 0.
-- Blizzard's LevelFrame is faded with SetAlpha only. The classic health-bar
-- style keeps Blizzard's own level. Threat recolors this border while active.
local addonName, ns = ...
local Flux = ns.Flux
local NP = Flux.NamePlates

local Level = NP.RegisterModule("level", { interval = 0.25 })

local FONT_SIZE_MULT = 0.95
local FONT_SIZE_MIN = 9
local FONT_SIZE_MAX = 11
local SKULL_TEXTURE = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"

local overlays = {}

local function IsEnabled()
	return NP.IsLevelSupported() and NP.GetDB().levelOverlayEnabled ~= false
end

local function UsesClassicHealthBar()
	return NP.UsesClassicHealthBar()
end

local function Flag(fn, ...)
	if not fn then
		return false
	end
	local ok, value = pcall(fn, ...)
	return ok and NP.BoolTest(value, false)
end

local function ShouldOmit(uf, unit)
	if Flag(uf.IsSimplified, uf) or Flag(uf.IsMinion, uf) or Flag(uf.IsMinusMob, uf) or Flag(uf.IsShowOnlyName, uf) then
		return true
	end
	if Flag(UnitIsMinion, unit) then
		return true
	end
	if not UnitClassification then
		return false
	end
	local ok, classif = pcall(UnitClassification, unit)
	return ok and not NP.IsSecret(classif) and classif == "minus"
end

local function SetBlizzardLevelShown(uf, shown)
	local frame = uf and uf.LevelFrame
	if frame and frame.SetAlpha then
		frame:SetAlpha(shown and 1 or 0)
	end
end

local function EnsureOverlay(unit)
	local overlay = overlays[unit]
	if overlay then
		return overlay
	end
	local host = NP.CreateClientPlate("level")
	local text = host:CreateFontString(nil, "OVERLAY")
	text:SetFont(NP.FONT, FONT_SIZE_MIN, "OUTLINE")
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")
	text:SetWordWrap(false)
	text:SetPoint("CENTER", host, "CENTER", 0, NP.PlateTextOffsetY())
	local skull = host:CreateTexture(nil, "OVERLAY")
	skull:SetTexture(SKULL_TEXTURE)
	skull:SetPoint("CENTER", host, "CENTER", 0, NP.PlateTextOffsetY())
	skull:Hide()
	overlay = { host = host, text = text, skull = skull }
	overlays[unit] = overlay
	return overlay
end

local function UnpackColor(color)
	if not color or NP.IsSecret(color) then
		return nil
	end
	local r, g, b = color.r, color.g, color.b
	if NP.IsSecret(r) or type(r) == "number" then
		return r, g, b
	end
	return nil
end

--- Gray, green, yellow, orange, red. Forever cannot compare a secret level, so the
--- content-difficulty enum is resolved in C and mapped here.
local function LevelColor(unit, level)
	local canAttack = Flag(UnitCanAttack, "player", unit)
	if canAttack and C_PlayerInfo and C_PlayerInfo.GetContentDifficultyCreatureForPlayer and DifficultyUtil and DifficultyUtil.GetDifficultyColor then
		local ok, diff = pcall(C_PlayerInfo.GetContentDifficultyCreatureForPlayer, unit)
		if ok and not NP.IsSecret(diff) then
			local color = DifficultyUtil.GetDifficultyColor(diff)
			local r, g, b = UnpackColor(color)
			if r then
				return r, g, b
			end
		end
	end
	local playerLevel = UnitLevel and UnitLevel("player")
	if canAttack and GetRelativeDifficultyColor and not NP.IsSecret(playerLevel) and playerLevel ~= nil and not NP.IsSecret(level) then
		local color = GetRelativeDifficultyColor(playerLevel, level)
		local r, g, b = UnpackColor(color)
		if r then
			return r, g, b
		end
	end
	local c = UNIT_LEVEL_NON_ATTACKABLE
	if c then
		return c.r, c.g, c.b
	end
	return 1, 1, 1
end

--- Blizzard already resolved the difficulty color. Pass it through, including secrets.
local function BlizzardLevelColor(uf)
	local text = uf.LevelFrame and uf.LevelFrame.LevelText
	if not text or not text.GetTextColor then
		return nil
	end
	local ok, r, g, b = pcall(text.GetTextColor, text)
	if not ok or not (NP.IsSecret(r) or r ~= nil) then
		return nil
	end
	return r, g, b
end

local function Hide(unit, uf)
	local overlay = overlays[unit]
	if overlay then
		overlay.host:Hide()
	end
	if uf then
		SetBlizzardLevelShown(uf, true)
	end
end

local function UpdateUnit(unit)
	local uf, plate, container = NP.GetParts(unit)
	if not uf or not container or not IsEnabled() or UsesClassicHealthBar() or not Flag(UnitExists, unit) then
		Hide(unit, uf)
		return
	end
	if ShouldOmit(uf, unit) then
		Hide(unit, nil)
		SetBlizzardLevelShown(uf, false)
		return
	end
	local level = UnitLevel(unit)
	local secretLevel = NP.IsSecret(level)
	if not secretLevel and level == nil then
		Hide(unit, uf)
		return
	end

	local overlay = EnsureOverlay(unit)
	local base = (NamePlateSetupOptions and NamePlateSetupOptions.levelFontHeight) or 10
	local size = math.max(FONT_SIZE_MIN, math.min(FONT_SIZE_MAX, math.floor(base * FONT_SIZE_MULT + 0.5)))
	overlay.text:SetFont(NP.FONT, size, "OUTLINE")
	overlay.skull:SetSize(size + 2, size + 2)

	local showSkull = false
	if secretLevel then
		local high = uf.LevelFrame and uf.LevelFrame.HighLevelTexture
		showSkull = high and Flag(high.IsShown, high)
	elseif level <= 0 then
		showSkull = true
	end

	local r, g, b = LevelColor(unit, level)
	if not (NP.IsSecret(r) or r ~= nil) then
		r, g, b = BlizzardLevelColor(uf)
	end
	if showSkull then
		overlay.text:Hide()
		overlay.skull:Show()
	else
		overlay.skull:Hide()
		if secretLevel then
			if not pcall(overlay.text.SetFormattedText, overlay.text, "Lvl. %s", level) then
				overlay.text:SetText("Lvl.")
			end
		else
			overlay.text:SetText("Lvl. " .. tostring(level))
		end
		overlay.text:SetTextColor(r, g, b, 1)
		overlay.text:Show()
	end

	NP.FitPlate(overlay.host, showSkull and overlay.skull or overlay.text)
	NP.ShowPlate(overlay.host, unit)

	NP.AttachHost(overlay.host, plate, 1)
	overlay.host:ClearAllPoints()
	if not pcall(overlay.host.SetPoint, overlay.host, "RIGHT", container, "BOTTOMRIGHT", -2, -3) then
		Hide(unit, uf)
		return
	end
	SetBlizzardLevelShown(uf, false)
	overlay.host:Show()
end

function Level.Added(unit)
	if NP.IsLevelSupported() then
		UpdateUnit(unit)
	end
end

function Level.Removed(unit)
	local overlay = overlays[unit]
	if overlay then
		NP.ReleaseHost(overlay.host)
		overlays[unit] = nil
	end
end

function Level.Refresh(unit)
	if NP.IsLevelSupported() then
		UpdateUnit(unit)
	end
end

function Level.Poll()
	if not NP.IsLevelSupported() then
		return
	end
	for unit in pairs(NP.activeUnits) do
		UpdateUnit(unit)
	end
end
