-- NamePlates/Core.lua — shared state and driver for Flux nameplate overlays.
-- Flux keeps Blizzard's nameplate and cast lifecycle. Some modules style
-- native regions, so keep those writes scoped and verify 12.x SetUnit taint.
local addonName, ns = ...
local Flux = ns.Flux

local NP = {}
Flux.NamePlates = NP

NP.PREVIEW_UNIT = (NamePlateConstants and NamePlateConstants.PREVIEW_UNIT_TOKEN) or "preview"
NP.FONT = "Fonts\\FRIZQT__.TTF"
NP.FRAME_LEVEL_OFFSET = 5

-- ---------------------------------------------------------------------------
-- Client gates
-- ---------------------------------------------------------------------------
local function ClientFlag(name)
	local client = Flux.Client
	if client and client[name] then
		return true
	end
	return FLUX_API and FLUX_API[name] and true or false
end

--- Era, Anniversary, and the other Classic projects (no enforced secret values).
function NP.IsClassicFamily()
	if ClientFlag("isAnyClassic") then
		return true
	end
	local id = WOW_PROJECT_ID
	if not id then
		return false
	end
	return (WOW_PROJECT_CLASSIC and id == WOW_PROJECT_CLASSIC)
		or (WOW_PROJECT_BURNING_CRUSADE_CLASSIC and id == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
		or (WOW_PROJECT_WRATH_CLASSIC and id == WOW_PROJECT_WRATH_CLASSIC)
		or (WOW_PROJECT_CATACLYSM_CLASSIC and id == WOW_PROJECT_CATACLYSM_CLASSIC)
		or (WOW_PROJECT_MISTS_CLASSIC and id == WOW_PROJECT_MISTS_CLASSIC)
		or false
end

--- Forever (camelot) and Live Midnight: secret values are enforced.
function NP.IsSecretClient()
	if NP.IsClassicFamily() then
		return false
	end
	return ClientFlag("isForever") or ClientFlag("isCamelot") or ClientFlag("isRetail")
		or (WOW_PROJECT_MAINLINE ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
end

--- 12.x mainline is Live even if the Forever/camelot flag was also set.
function NP.IsLiveClient()
	local client = Flux.Client
	local major = client and client.majorVersion or 0
	if WOW_PROJECT_MAINLINE ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and major >= 12 then
		return true
	end
	return ClientFlag("isLiveMidnight") or (ClientFlag("isRetail") and not ClientFlag("isForever") and not ClientFlag("isCamelot"))
end

function NP.PlateTextOffsetY()
	-- Forever and Era plate art sits low around the glyphs. Anniversary stays at -1.
	if not NP.IsLiveClient() and (ClientFlag("isForever") or ClientFlag("isCamelot")) then
		return 3
	end
	if ClientFlag("isClassicEra") or ClientFlag("isEra") then
		return 1
	end
	return -1
end

function NP.IsThreatSupported()
	return C_NamePlate ~= nil
end

function NP.IsLevelSupported()
	-- Live has no level. Forever, Era, and Anniversary keep it.
	if NP.IsLiveClient() then
		return false
	end
	return C_NamePlate ~= nil
end

-- ---------------------------------------------------------------------------
-- Settings (FluxUI_DB.nameplateThreat)
-- ---------------------------------------------------------------------------
local DEFAULTS = {
	npcThreatBorder = true,
	enemyPlayerTarget = true,
	visibilityMode = "group",
	levelOverlayEnabled = true,
	questOverlayEnabled = true,
}

function NP.GetDB()
	if type(FluxUI_DB) ~= "table" then
		return DEFAULTS
	end
	local db = FluxUI_DB.nameplateThreat
	if type(db) ~= "table" then
		db = {}
		FluxUI_DB.nameplateThreat = db
	end
	if db.npcThreatBorder == nil then
		db.npcThreatBorder = true
	end
	if db.enemyPlayerTarget == nil then
		db.enemyPlayerTarget = true
	end
	if db.visibilityMode ~= "always" and db.visibilityMode ~= "never" and db.visibilityMode ~= "group" then
		db.visibilityMode = "group"
	end
	if db.levelOverlayEnabled == nil then
		db.levelOverlayEnabled = true
	end
	if db.questOverlayEnabled == nil then
		db.questOverlayEnabled = true
	end
	return db
end

-- ---------------------------------------------------------------------------
-- Secret-value helpers
-- ---------------------------------------------------------------------------
function NP.IsSecret(value)
	if value == nil then
		return false
	end
	local S = Flux.Secrets
	if S and S.IsSecretValue then
		return S.IsSecretValue(value) and true or false
	end
	local fn = issecretvalue
	if fn then
		local ok, res = pcall(fn, value)
		return ok and res and true or false
	end
	return false
end

--- True only for a readable, non-nil value.
function NP.IsUsable(value)
	if value == nil or NP.IsSecret(value) then
		return false
	end
	local S = Flux.Secrets
	if S and S.CanAccessValue then
		return S.CanAccessValue(value) and true or false
	end
	return true
end

--- Boolean test that treats a secret as `default`.
function NP.BoolTest(value, default)
	local S = Flux.Secrets
	if S and S.SafeBooleanTest then
		return S.SafeBooleanTest(value, default)
	end
	if NP.IsSecret(value) then
		return default
	end
	return value and true or false
end

-- ---------------------------------------------------------------------------
-- Plate lookup (read-only)
-- ---------------------------------------------------------------------------
-- Native nameplate tokens are rebound by the existing add/remove lifecycle.
-- Cache only the plate identity; child fields remain live reads on every call.
local activePlates = {}
function NP.GetPlate(unit)
	if type(unit) ~= "string" or unit == NP.PREVIEW_UNIT then
		return nil
	end
	local cached = activePlates[unit]
	if cached then return cached end
	if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return nil end
	local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
	if ok then
		-- A missing plate is retried; NAME_PLATE_UNIT_ADDED can precede setup.
		if plate and NP.activeUnits and NP.activeUnits[unit] then activePlates[unit] = plate end
		return plate
	end
	return nil
end

--- uf, plate, container, healthBar for a world nameplate unit.
function NP.GetParts(unit)
	local plate = NP.GetPlate(unit)
	local uf = plate and plate.UnitFrame
	local container = uf and uf.HealthBarsContainer
	local healthBar = container and container.healthBar
	return uf, plate, container, healthBar
end

local function PlateUnitToken(plate)
	if not plate then
		return nil
	end
	local unit = plate.unitToken or plate.namePlateUnitToken
	if unit == nil and plate.UnitFrame then
		unit = plate.UnitFrame.unit
	end
	if type(unit) ~= "string" or NP.IsSecret(unit) or unit == NP.PREVIEW_UNIT then
		return nil
	end
	return unit
end

-- ---------------------------------------------------------------------------
-- Flux-owned host frames
-- ---------------------------------------------------------------------------
function NP.CreateHost(width, height)
	local host = CreateFrame("Frame", nil, UIParent)
	host:SetSize(width or 20, height or 14)
	host:EnableMouse(false)
	host:Hide()
	return host
end

--- Parent a Flux host to the nameplate and lift it above the unit frame.
--- Never parent under UnitFrame or its children, and never SetFrameStrata.
function NP.AttachHost(host, plate, extraLevel)
	if not host or not plate then
		return false
	end
	if host:GetParent() ~= plate then
		if not pcall(host.SetParent, host, plate) then
			return false
		end
	end
	local ok, level = pcall(plate.GetFrameLevel, plate)
	if ok and type(level) == "number" and not NP.IsSecret(level) then
		pcall(host.SetFrameLevel, host, level + NP.FRAME_LEVEL_OFFSET + (extraLevel or 0))
	end
	return true
end

function NP.ReleaseHost(host)
	if not host then
		return
	end
	host:Hide()
	host:ClearAllPoints()
	host:SetParent(UIParent)
end

function NP.UsesClassicHealthBar()
	local options = NamePlateSetupOptions
	return options and options.useClassicHealthBar == true or false
end

-- One game texture for the level and threat tags.
-- Classic: Interface\Tooltips\Nameplate-Border.
-- Other styles: UI-HUD-CoolDownManager-Bar-BG. No selection-ring atlas.
local CLASSIC_BORDER = "Interface\\Tooltips\\Nameplate-Border"
local MODERN_BACKDROP = "UI-HUD-CoolDownManager-Bar-BG"
local threatTint = {}

local function ApplyClientPlate(host)
	local classic = NP.UsesClassicHealthBar()
	host._fluxClassic = classic
	local art = host.art
	art:ClearAllPoints()
	art:SetPoint("TOPLEFT", host, "TOPLEFT", -2, 2)
	art:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 2, -2)
	if classic then
		art:SetTexture(CLASSIC_BORDER)
		art:SetTexCoord(0, 1, 0.5, 1)
		if art.SetTextureSliceMargins then
			art:SetTextureSliceMargins(0, 0, 0, 0)
		end
	elseif art.SetAtlas then
		art:SetAtlas(MODERN_BACKDROP, false)
	end
	art:Show()
end

function NP.CreateClientPlate(role)
	local host = NP.CreateHost(role == "level" and 36 or 48, 14)
	host._fluxRole = role
	local art = host:CreateTexture(nil, "BACKGROUND")
	host.art = art
	host.backdrop = art
	host.rim = art
	host.plate = art
	host.border = art
	ApplyClientPlate(host)
	return host
end

local PLATE_HEIGHT = 14

function NP.FitPlate(host, widget)
	if not host then
		return
	end
	local threat = host._fluxRole == "threat"
	local w = host._fluxRole == "level" and 52 or 54
	local measured = false
	local method = widget and (widget.GetStringWidth or widget.GetWidth)
	if method then
		local okW, sw = pcall(method, widget)
		if okW and not NP.IsSecret(sw) and type(sw) == "number" and sw > 4 then
			w = sw + (threat and 4 or 10)
			measured = true
		end
	end
	host:SetSize(w, PLATE_HEIGHT)
	return w, measured
end

function NP.IsUnitTarget(unit)
	if not unit or not UnitIsUnit then
		return false
	end
	local ok, value = pcall(UnitIsUnit, unit, "target")
	return ok and NP.BoolTest(value, false)
end

function NP.ShowPlate(host, unit)
	if not host or not host.art then
		return
	end
	if host._fluxClassic ~= NP.UsesClassicHealthBar() then
		ApplyClientPlate(host)
	end
	local threat = NP.ThreatTint(unit)
	local selected = NP.IsUnitTarget(unit)
	local r, g, b, a = 1, 1, 1, 1
	if threat then
		r, g, b = threat[1], threat[2], threat[3]
		a = selected and 1 or 0.8
	elseif selected then
		local c = NAMEPLATE_BORDER_TARGET_COLOR
		if c then
			r, g, b, a = c.r, c.g, c.b, c.a or 1
		else
			r, g, b = 1, 0.9, 0.4
		end
	end
	host.art:SetVertexColor(r, g, b, a)
end

function NP.SetThreatTint(unit, r, g, b)
	if not unit then
		return
	end
	if r then
		local tint = threatTint[unit]
		if tint then tint[1], tint[2], tint[3] = r, g, b
		else threatTint[unit] = { r, g, b } end
	else
		threatTint[unit] = nil
	end
end

function NP.ThreatTint(unit)
	return unit and threatTint[unit]
end

local function TintRegion(region, r, g, b, a)
	if region and region.SetVertexColor then
		pcall(region.SetVertexColor, region, r, g, b, a or 1)
	end
end

local function UnitFrameOf(healthBar)
	local container = healthBar and healthBar.GetParent and healthBar:GetParent()
	return container and container.GetParent and container:GetParent()
end

local function SelectionShown(frame)
	if not frame then
		return false
	end
	local function On(method)
		if not frame[method] then
			return false
		end
		local ok, value = pcall(frame[method], frame)
		return ok and NP.BoolTest(value, false)
	end
	return On("IsTarget") or On("IsFocus")
end

local function ShowTinted(region, r, g, b)
	TintRegion(region, r, g, b, 1)
	if region and region.Show then
		region:Show()
	end
end

local function RestoreSelectionBorder(region, frame)
	if not region then
		return
	end
	if SelectionShown(frame) then
		local c = NAMEPLATE_BORDER_TARGET_COLOR
		if c then
			pcall(region.SetVertexColor, region, c.r, c.g, c.b, c.a or 1)
		else
			TintRegion(region, 1, 1, 1, 1)
		end
		if region.Show then
			region:Show()
		end
	else
		TintRegion(region, 1, 1, 1, 1)
		if region.Hide then
			region:Hide()
		end
	end
end

--- Recolor the Blizzard nameplate border and the level-indicator border.
--- The 0.25s threat poll reapplies this after Blizzard repaints them.
function NP.TintPlateChrome(healthBar, r, g, b)
	if not healthBar then
		return
	end
	TintRegion(healthBar.bgTexture, r, g, b, 1)
	local container = healthBar.GetParent and healthBar:GetParent()
	TintRegion(container and container.border, r, g, b, 1)
	ShowTinted(healthBar.selectedBorder, r, g, b)

	local uf = UnitFrameOf(healthBar)
	local diff = uf and uf.PlayerLevelDiffFrame
	if diff then
		TintRegion(diff.playerLevelDiffIcon, r, g, b, 1)
		ShowTinted(diff.selectedBorder, r, g, b)
	end
	if uf and uf.selectionHighlight and SelectionShown(healthBar) then
		ShowTinted(uf.selectionHighlight, r, g, b)
	end
end

function NP.ResetPlateChrome(healthBar)
	if not healthBar then
		return
	end
	TintRegion(healthBar.bgTexture, 1, 1, 1, 1)
	local container = healthBar.GetParent and healthBar:GetParent()
	local border = container and container.border
	if border and border.SetVertexColor then
		local opt = NamePlateEnemyFrameOptions
		local c = opt and opt.defaultBorderColor
		if c then
			pcall(border.SetVertexColor, border, c.r, c.g, c.b, c.a or 1)
		else
			pcall(border.SetVertexColor, border, 0, 0, 0, 1)
		end
	end
	RestoreSelectionBorder(healthBar.selectedBorder, healthBar)

	local uf = UnitFrameOf(healthBar)
	local diff = uf and uf.PlayerLevelDiffFrame
	if diff then
		TintRegion(diff.playerLevelDiffIcon, 1, 1, 1, 1)
		RestoreSelectionBorder(diff.selectedBorder, diff)
	end
	if uf and uf.selectionHighlight then
		TintRegion(uf.selectionHighlight, 1, 1, 1, 1)
	end
end

-- ---------------------------------------------------------------------------
-- Modules and driver
-- ---------------------------------------------------------------------------
-- A module may define:
--   Added(unit), Removed(unit), Refresh(unit), RefreshAll(),
--   interval (seconds) + Poll() for periodic work.
local modules = {}
local activeUnits = {}
NP.activeUnits = activeUnits

function NP.RegisterModule(name, module)
	module.name = name
	module._elapsed = 0
	modules[#modules + 1] = module
	return module
end

local function EachModule(method, ...)
	for i = 1, #modules do
		local module = modules[i]
		local fn = module[method]
		if fn then
			local ok, err = pcall(fn, ...)
			if not ok and geterrorhandler then
				geterrorhandler()(err)
			end
		end
	end
end

local driver = CreateFrame("Frame")
driver:Hide()

local function HasActiveUnits()
	return next(activeUnits) ~= nil
end

local function AddUnit(unit)
	if not unit then return end
	activePlates[unit] = nil
	if activeUnits[unit] then return end
	activeUnits[unit] = true
	EachModule("Added", unit)
	driver:Show()
end

local function RemoveUnit(unit)
	if not unit or not activeUnits[unit] then
		return
	end
	activeUnits[unit] = nil
	activePlates[unit] = nil
	EachModule("Removed", unit)
	if not HasActiveUnits() then
		driver:Hide()
	end
end

local function ScanPlates()
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then
		return
	end
	local ok, list = pcall(C_NamePlate.GetNamePlates)
	if not ok or type(list) ~= "table" then
		return
	end
	local seen = {}
	for _, plate in pairs(list) do
		local unit = PlateUnitToken(plate)
		if unit then
			seen[unit] = true
			AddUnit(unit)
			activePlates[unit] = plate
		end
	end
	for unit in pairs(activeUnits) do
		if not seen[unit] then
			RemoveUnit(unit)
		end
	end
end

function NP.RefreshUnit(unit)
	if activeUnits[unit] then
		EachModule("Refresh", unit)
	end
end

function NP.RefreshAll()
	-- Explicit refreshes also reconcile native replacement/style rebuilds.
	for unit in pairs(activePlates) do activePlates[unit] = nil end
	NP.GetDB()
	EachModule("RefreshAll")
	for unit in pairs(activeUnits) do
		EachModule("Refresh", unit)
	end
end

driver:SetScript("OnUpdate", function(self, elapsed)
	for i = 1, #modules do
		local module = modules[i]
		if module.interval and module.Poll then
			module._elapsed = module._elapsed + elapsed
			if module._elapsed >= module.interval then
				module._elapsed = 0
				local ok, err = pcall(module.Poll)
				if not ok and geterrorhandler then
					geterrorhandler()(err)
				end
			end
		end
	end
end)

local events = CreateFrame("Frame")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent", function(_, event, unit)
	if event == "NAME_PLATE_UNIT_ADDED" then
		if type(unit) == "string" and not NP.IsSecret(unit) then
			AddUnit(unit)
		end
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		if type(unit) == "string" and not NP.IsSecret(unit) then
			RemoveUnit(unit)
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		ScanPlates()
		NP.RefreshAll()
	else
		NP.RefreshAll()
	end
end)

-- Options call these after changing FluxUI_DB.nameplateThreat.
_G.FluxNamePlates_RefreshFromDB = NP.RefreshAll
_G.FluxNamePlateThreat_RefreshFromDB = NP.RefreshAll

-- Small quest progress tags: Questie's associations when loaded, otherwise
-- Blizzard's unit tooltip + active quest log. No bundled database or saved
-- quest cache. Flux replaces Questie's nameplate marker while this is enabled.
do
	local Quest = NP.RegisterModule("quest", { interval = 0.25 })
	local states, unused = {}, {}
	local visibleUnits = {}
	local dirty, subscribed, retries = true, false, 0
	local callbackOwner, readyOwner
	local questiePlates, questieLoader, suppressedProfile
	local questEvents = { "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "ADDON_LOADED" }
	-- Exact artwork from the supplied Questie installation; included here so
	-- disabling/uninstalling Questie does not change the badge. See docs/19-nameplates.md.
	local icons = { monster = "Interface\\AddOns\\_FluxUI\\Texture\\QuestSlay.blp",
		item = "Interface\\AddOns\\_FluxUI\\Texture\\QuestLoot.blp" }
	local scanner

	local function Enabled()
		return NP.GetDB().questOverlayEnabled ~= false
	end

	local function Invalidate()
		if Enabled() then dirty, retries = true, 3 end
	end

	local function SuppressQuestieNameplates()
		if not Enabled() then return end
		local profile = Questie and Questie.db and Questie.db.profile
		if not profile then return end
		local changed = profile.nameplateEnabled ~= false
		if changed then profile.nameplateEnabled = false end
		if QuestieLoader and type(QuestieLoader.ImportModule) == "function" then
			if questieLoader ~= QuestieLoader then
				questieLoader = QuestieLoader
				questiePlates = QuestieLoader:ImportModule("QuestieNameplate")
				suppressedProfile = nil
			end
			-- Match Questie's own option setter, including already-visible markers.
			-- Its target-frame marker and every other Questie setting stay independent.
			if questiePlates and type(questiePlates.HideCurrentFrames) == "function"
				and (changed or suppressedProfile ~= profile) then
				questiePlates:HideCurrentFrames()
				suppressedProfile = profile
			end
		end
	end

	local function Subscribe()
		SuppressQuestieNameplates()
		if not Flux.Events then return end
		local enabled = Enabled()
		if enabled ~= subscribed then
			subscribed = enabled
			for _, event in ipairs(questEvents) do
				if enabled then Flux.Events.Register(event, Invalidate)
				else Flux.Events.Unregister(event, Invalidate) end
			end
		end
		local api = Questie and Questie.API
		if enabled and api and type(api.RegisterOnReady) == "function" and readyOwner ~= api then
			readyOwner = api
			api.RegisterOnReady(Invalidate)
		end
		if enabled and api and type(api.RegisterForQuestUpdates) == "function" and callbackOwner ~= api then
			api.RegisterForQuestUpdates(Invalidate)
			-- The public API has no unregister. This one callback is inert when off.
			callbackOwner = api
		end
	end

	local function Number(value)
		if NP.IsSecret(value) or type(value) ~= "number" or value ~= value
			or value == math.huge or value == -math.huge or value < 0 or value % 1 ~= 0 then return end
		return value
	end

	local function PublicTable(value)
		return not NP.IsSecret(value) and type(value) == "table"
			and not (issecrettable and issecrettable(value))
	end

	local function Text(value)
		if not NP.IsSecret(value) and type(value) == "string" then
			return (value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*(.-)%s*$"))
		end
	end

	local function NativeObjectives(id, cache)
		if not id or id == 0 then return end
		if cache[id] == nil then
			cache[id] = false
			local log = C_QuestLog
			if log and log.GetQuestObjectives and (not log.IsOnQuest or NP.BoolTest(log.IsOnQuest(id), false)) then
				local ok, objectives = pcall(log.GetQuestObjectives, id)
				if ok and PublicTable(objectives) then cache[id] = objectives end
			end
		end
		return cache[id] or nil
	end

	local function MatchNative(rows, seen, id, text, cache)
		text = Text(text)
		if not text then return end
		for index, objective in ipairs(NativeObjectives(id, cache) or {}) do
			if PublicTable(objective) then
				local kind, finished = Text(objective.type), objective.finished
				local current, required = Number(objective.numFulfilled), Number(objective.numRequired)
				if (kind == "monster" or kind == "item") and not NP.IsSecret(finished) and not finished
					and current and required and required > 0 and current < required
					and text == Text(objective.text) and not seen[objective] then
					seen[objective] = true
					rows[#rows + 1] = { questID = id, index = index, kind = kind, current = current, required = required }
				end
			end
		end
	end

	local function NativeRows(unit, rows, batch)
		local cache, seen = batch.nativeObjectives or {}, {}
		batch.nativeObjectives = cache
		if C_TooltipInfo and C_TooltipInfo.GetUnit then
			local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
			local kinds = Enum and Enum.TooltipDataLineType
			if not ok or not PublicTable(data) or not PublicTable(data.lines) or not kinds then return end
			local id, own = nil, false
			local playerGUID = UnitGUID("player")
			for _, line in ipairs(data.lines) do
				if PublicTable(line) and not NP.IsSecret(line.type) then
					if line.type == kinds.QuestTitle then id, own = Number(line.id), true
					elseif line.type == kinds.QuestPlayer then
						own = not NP.IsSecret(line.guid) and not NP.IsSecret(playerGUID)
							and type(line.guid) == "string" and line.guid == playerGUID
					elseif line.type == kinds.QuestObjective and own and id then
						MatchNative(rows, seen, id, line.leftText, cache)
					end
				else id, own = nil, false end
			end
		elseif GetNumQuestLogEntries and GetQuestLogTitle then
			-- Legacy clients: a single private native tooltip, never GameTooltip.
			-- Match its quest block to active log text; never guess drop sources.
			if not scanner then scanner = CreateFrame("GameTooltip", "FluxNamePlateQuestScanner", UIParent, "GameTooltipTemplate") end
			scanner:SetOwner(UIParent, "ANCHOR_NONE")
			scanner:ClearLines()
			local ok = pcall(scanner.SetUnit, scanner, unit)
			if ok then
				local titles = batch.nativeTitles
				if not titles then
					titles = {}
					batch.nativeTitles = titles
					for index = 1, math.min(Number(GetNumQuestLogEntries()) or 0, 500) do
						local title, _, _, header, _, _, _, id = GetQuestLogTitle(index)
						title, id = Text(title), Number(id)
						if title and id and not NP.IsSecret(header) and not header then
							if titles[title] == nil then titles[title] = id else titles[title] = false end
						end
					end
				end
				local id
				for _, region in ipairs({ scanner:GetRegions() }) do
					local text = region.IsObjectType and region:IsObjectType("FontString") and Text(region:GetText())
					if text then
						if titles[text] ~= nil then id = titles[text] or nil
						elseif id then MatchNative(rows, seen, id, text, cache) end
					end
				end
			end
			scanner:Hide()
			scanner:ClearLines()
		end
	end

	local function Rows(unit, cache)
		-- Modern instance tooltips/GUIDs can be restricted even when a token is
		-- public. Do not invoke Questie's Lua lookup or a native tooltip rebuild
		-- in that context; old public counts must disappear on world transitions.
		if NP.IsSecretClient() and IsInInstance and NP.BoolTest(IsInInstance(), true) then return end
		local guid = UnitGUID and UnitGUID(unit)
		if NP.IsSecret(guid) or type(guid) ~= "string" then return end
		local npc = guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
			or guid:match("^Vehicle%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
		if not npc then return end
		local loaded = Questie and Questie.db and QuestieLoader and type(QuestieLoader.ImportModule) == "function"
			and not (Questie.API and Questie.API.isReady == false)
		local key = loaded and npc or unit
		if cache[key] then return cache[key] end
		local rows = {}
		cache[key] = rows
		local tooltips = loaded and QuestieLoader:ImportModule("QuestieTooltips")
		local entries = tooltips and tooltips.lookupByKey and tooltips.lookupByKey["m_" .. npc]
		if not tooltips then NativeRows(unit, rows, cache) end
		local seen = {}
		for _, entry in pairs(entries or {}) do
			local objective = entry.objective
			local id = Number(entry.questId)
			local active = true
			if id and C_QuestLog and C_QuestLog.IsOnQuest then
				active = NP.BoolTest(C_QuestLog.IsOnQuest(id), false)
			end
			if objective and id and active and not seen[objective] then
				seen[objective] = true
				-- The same refresh contract Questie uses before drawing its icon.
				if type(objective.Update) == "function" then objective:Update() end
				local current, required = Number(objective.Collected), Number(objective.Needed)
				local kind, completed = objective.Type, objective.Completed
				if not NP.IsSecret(kind) and (kind == "monster" or kind == "item")
					and not NP.IsSecret(completed) and not completed
					and current and required and required > 0 and current < required then
					rows[#rows + 1] = { questID = id, index = Number(objective.Index) or 0,
						kind = kind, current = current, required = required }
				end
			end
		end
		table.sort(rows, function(a, b)
			if a.questID == b.questID then return a.index < b.index end
			return a.questID < b.questID
		end)
		return rows
	end

	local function ReleaseRow(host)
		NP.ReleaseHost(host)
		host.text:SetText("")
		host.icon:SetTexture(nil)
		host.kind, host.current, host.required = nil, nil, nil
		unused[#unused + 1] = host
	end

	local function Release(unit)
		local state = states[unit]
		if not state then return end
		for _, host in ipairs(state) do ReleaseRow(host) end
		states[unit] = nil
	end

	local function NewRow()
		local host = table.remove(unused)
		if host then return host end
		host = NP.CreateClientPlate("quest")
		host.icon = host:CreateTexture(nil, "OVERLAY")
		host.icon:SetSize(10, 10)
		host.icon:SetPoint("LEFT", host, "LEFT", 2, 0)
		host.text = host:CreateFontString(nil, "OVERLAY")
		host.text:SetFont(NP.FONT, 10, "OUTLINE")
		host.text:SetShadowColor(0, 0, 0, 1)
		host.text:SetShadowOffset(1, -1)
		host.text:SetJustifyH("LEFT")
		host.text:SetWordWrap(false)
		host.text:SetPoint("LEFT", host.icon, "RIGHT", 2, NP.IsLiveClient() and 1 or NP.PlateTextOffsetY())
		host.text:SetTextColor(1, 0.82, 0, 1)
		return host
	end

	local function IsVisible(uf, healthBar)
		if not uf or not healthBar then return false end
		local visible, shown = true, true
		if uf.IsShown then visible, shown = pcall(uf.IsShown, uf) end
		if not visible or not NP.BoolTest(shown, false) then return false end
		if healthBar.IsShown then visible, shown = pcall(healthBar.IsShown, healthBar) end
		return visible and NP.BoolTest(shown, false)
	end

	local function Layout(unit, state, container)
		if not state then return end
		local width = 0
		if container.GetWidth then
			local ok, value = pcall(container.GetWidth, container)
			if ok and not NP.IsSecret(value) and type(value) == "number"
				and value > 0 and value < math.huge then width = value end
		end
		local threatWidth = NP.GetThreatPlateWidth and NP.GetThreatPlateWidth(unit) or 0
		-- Keep every objective on the first badge baseline. Grow outward to the
		-- left when the plate's left half cannot fit it beside centered threat.
		-- Six units leave two visible units between the two expanding backdrops.
		-- Unknown native width uses the exterior left lane without secret arithmetic.
		local x = math.min(0, width / 2 - threatWidth / 2 - 6 - state.width)
		if not state.layoutDirty and state.container == container and state.x == x then return end
		state.layoutDirty, state.container, state.x = false, container, x
		for _, host in ipairs(state) do
			host:ClearAllPoints()
			if host.attached and pcall(host.SetPoint, host, "TOPLEFT", container, "BOTTOMLEFT", x, 3) then host:Show()
			else host:Hide() end
			x = x + host.questWidth + 4
		end
	end

	local function Update(unit, cache)
		local uf, plate, container, healthBar = NP.GetParts(unit)
		local visible = IsVisible(uf, healthBar)
		visibleUnits[unit] = visible
		if not Enabled() or unit == NP.PREVIEW_UNIT or not container or not visible
			then Release(unit); return end
		local rows = Rows(unit, cache)
		if not rows or #rows == 0 then Release(unit); return end
		local state = states[unit] or {}
		states[unit] = state
		state.width, state.layoutDirty = 0, true
		for index, row in ipairs(rows) do
			local host = state[index] or NewRow()
			state[index] = host
			if host.kind ~= row.kind then host.icon:SetTexture(icons[row.kind]); host.kind = row.kind end
			if host.current ~= row.current or host.required ~= row.required then
				host.text:SetFormattedText("%d/%d", row.current, row.required)
				host.current, host.required = row.current, row.required
				local width = NP.FitPlate(host, host.text)
				-- FitPlate includes 10 text-padding units; total extra space is
				-- 2 left + 10 icon + 2 gap + 2 right = 16, keeping the tag short.
				host.questWidth = width + 6
				host:SetSize(host.questWidth, 12)
			end
			NP.ShowPlate(host, unit)
			host.attached = NP.AttachHost(host, plate, 1)
			state.width = state.width + host.questWidth + (index > 1 and 4 or 0)
		end
		for index = #state, #rows + 1, -1 do ReleaseRow(table.remove(state)) end
		Layout(unit, state, container)
	end

	function Quest.Added(unit)
		if Enabled() then SuppressQuestieNameplates(); Update(unit, {}); retries = 3 end
	end
	function Quest.Removed(unit)
		Release(unit)
		visibleUnits[unit] = nil
	end
	function Quest.Refresh(unit) Update(unit, {}) end
	function Quest.RefreshAll()
		Subscribe()
		dirty = true
		if not Enabled() then
			for unit in pairs(states) do Release(unit) end
			wipe(visibleUnits)
			retries, dirty = 0, false
		end
	end
	function Quest.Poll()
		if not Enabled() then return end
		SuppressQuestieNameplates()
		if not (dirty or retries > 0) then
			-- Native name-only/style changes can hide a bar without a quest event.
			-- Detect that transition without rescanning settled objective data.
			local cache = {}
			for unit in pairs(activeUnits) do
				local uf, _, container, bar = NP.GetParts(unit)
				if visibleUnits[unit] ~= IsVisible(uf, bar) then Update(unit, cache)
				elseif container then Layout(unit, states[unit], container) end
			end
			return
		end
		Subscribe()
		dirty = false
		if retries > 0 then retries = retries - 1 end
		local cache = {}
		for unit in pairs(activeUnits) do Update(unit, cache) end
	end
	Subscribe()
end

-- ---------------------------------------------------------------------------
-- Forever world plates: fade Blizzard's level number (not the frame — options
-- measure that frame with GetPoint) and let the health bar use the badge's
-- space. Shared CC and loss of control sit to the right of that badge; pull
-- them back to the health bar once the badge is gone. Nothing here runs while
-- the settings panel is open, and the options preview plate is never touched.
-- NamePlateConstants and plate size stay Blizzard's.
-- ---------------------------------------------------------------------------
local function IsForeverClient()
	if NP.IsLiveClient() then
		return false
	end
	return ClientFlag("isForever") or ClientFlag("isCamelot")
end

local function OptionsOpen()
	return SettingsPanel and SettingsPanel.IsShown and SettingsPanel:IsShown()
end

-- Reassert native layout only when it differs. These objects can have secret
-- alpha/anchors: an unknown result never enters a Lua comparison and retains
-- the original write path instead of claiming that cached artwork stayed put.
local function HasPublicPoint(region, point, relative, relativePoint, x, y)
	if not (region.GetNumPoints and region.GetPoint) then return false end
	local ok, count = pcall(region.GetNumPoints, region)
	if not ok or not NP.IsUsable(count) or type(count) ~= "number" or count < 0 or count > 8 then return false end
	for i = 1, count do
		local got, p, r, rp, px, py = pcall(region.GetPoint, region, i)
		if not got or not NP.IsUsable(p) or not NP.IsUsable(r) or not NP.IsUsable(rp)
			or not NP.IsUsable(px) or not NP.IsUsable(py) then return false end
		if p == point then return r == relative and rp == relativePoint and px == x and py == y end
	end
	return false
end

local function EnsurePublicPoint(region, point, relative, relativePoint, x, y)
	if region and region.SetPoint and not HasPublicPoint(region, point, relative, relativePoint, x, y) then
		pcall(region.SetPoint, region, point, relative, relativePoint, x, y)
	end
end

local function FadeArtwork(region)
	if not region then
		return
	end
	if region.SetAlpha then
		if region.GetAlpha then
			local ok, alpha = pcall(region.GetAlpha, region)
			if ok and NP.IsUsable(alpha) and type(alpha) == "number" and alpha == 0 then return end
		end
		region:SetAlpha(0)
	end
end

local function FadeBlizzardLevel(uf)
	local diff = uf.PlayerLevelDiffFrame
	if diff then
		FadeArtwork(diff.playerLevelDiffText)
		FadeArtwork(diff.playerLevelDiffIcon)
		FadeArtwork(diff.highLevelTexture)
		FadeArtwork(diff.selectedBorder)
	end
	local level = uf.LevelFrame
	if level then
		FadeArtwork(level.LevelText)
		FadeArtwork(level.HighLevelTexture)
	end
end

-- Blizzard uses 5px, plus the level width while the badge is showing.
local RIGHT_AURA_GAP = 5

local function PullRightAuras(uf, health)
	local auras = uf.AurasFrame
	if not auras then
		return
	end
	local cc = auras.CrowdControlListFrame
	local loc = auras.LossOfControlFrame
	if cc and cc.SetPoint then
		EnsurePublicPoint(cc, "LEFT", health, "RIGHT", RIGHT_AURA_GAP, 0)
	end
	if loc and loc.SetPoint then
		EnsurePublicPoint(loc, "LEFT", health, "RIGHT", RIGHT_AURA_GAP, 0)
	end
end

local function StretchHealthBar(uf)
	local setup = NamePlateSetupOptions
	local cast = uf.CastBarsContainer
	local health = uf.HealthBarsContainer
	if not (cast and health and health.SetPoint) then
		return
	end
	local spacing = (setup and setup.castBarToHealthBarSpacing) or 2
	EnsurePublicPoint(health, "BOTTOMRIGHT", cast, "TOPRIGHT", 0, spacing)
	local bar = health.healthBar
	if bar and setup and setup.useClassicHealthBar then
		local scale = setup.horizontalScale or 1
		local y = 0.5 * (setup.verticalScale or 1)
		EnsurePublicPoint(bar, "BOTTOMRIGHT", health, "BOTTOMRIGHT", -4 * scale, y)
	end
	PullRightAuras(uf, health)
end

local function ApplyForeverPlate(uf)
	-- The single caller checks Settings once before walking the active batch.
	if not uf then
		return
	end
	local unit = uf.unit
	if unit == NP.PREVIEW_UNIT or unit == "preview" then
		return
	end
	FadeBlizzardLevel(uf)
	StretchHealthBar(uf)
end

--- Health amount and percent stay inside the bar on Forever and Live.
--- Forever Default (Modern) and Cast Focus center them. Forever's other styles
--- keep them on the right inside the bar so the name does not cover them.
local function ShowOnlyName(uf)
	if not uf.IsShowOnlyName then
		return false
	end
	local ok, value = pcall(uf.IsShowOnlyName, uf)
	return ok and NP.BoolTest(value, false)
end

local function PlaceHealthReadout(uf)
	if not uf then
		return
	end
	local unit = uf.unit
	if unit == NP.PREVIEW_UNIT or unit == "preview" then
		return
	end
	local health = uf.HealthBarsContainer
	local bar = health and health.healthBar
	local setup = NamePlateSetupOptions
	local anchors = NamePlateConstants and NamePlateConstants.NAME_ANCHOR_STYLES
	if not (bar and bar.LeftText and bar.RightText and setup and anchors) then
		return
	end
	local left, right, mid = bar.LeftText, bar.RightText, bar.Text
	local y = setup.useClassicHealthBar and -0.5 or 0
	local plateStyle = 0
	if C_CVar and C_CVar.GetCVar then
		plateStyle = tonumber(C_CVar.GetCVar("nameplateStyle")) or 0
	end
	local styles = Enum and Enum.NamePlateStyle
	local centerReadout = setup.unitNameAnchorStyle == anchors.InsideHealthBar
	if IsForeverClient() and styles then
		centerReadout = plateStyle == styles.Modern or plateStyle == styles.CastFocus
	end
	if centerReadout then
		pcall(function()
			right:ClearAllPoints()
			right:SetPoint("RIGHT", bar, "CENTER", -2, y)
			left:ClearAllPoints()
			left:SetPoint("LEFT", bar, "CENTER", 2, y)
			if mid then
				mid:ClearAllPoints()
				mid:SetPoint("CENTER", bar, "CENTER", 0, y)
			end
		end)
		if uf.name and not ShowOnlyName(uf) then
			if setup.unitNameAnchorStyle == anchors.InsideHealthBar then
				pcall(function()
					uf.name:ClearAllPoints()
					uf.name:SetJustifyH("LEFT")
					uf.name:SetPoint("LEFT", health, "LEFT", 4, 0)
					uf.name:SetPoint("RIGHT", right, "LEFT", -4, 0)
				end)
			else
				local gap = setup.healthBarToNameAboveSpacing or 2
				pcall(function()
					uf.name:ClearAllPoints()
					uf.name:SetPoint("BOTTOMLEFT", health, "TOPLEFT", 0, gap)
					uf.name:SetPoint("BOTTOMRIGHT", health, "TOPRIGHT", 0, gap)
				end)
			end
		end
		return
	end
	pcall(function()
		left:ClearAllPoints()
		left:SetPoint("RIGHT", bar, "RIGHT", -4, y)
		right:ClearAllPoints()
		right:SetPoint("RIGHT", left, "LEFT", -2, 0)
		if mid then
			mid:ClearAllPoints()
			mid:SetPoint("RIGHT", right, "LEFT", 2, 0)
		end
		if IsForeverClient() then
			local base = setup.healthBarFontHeight or 12
			local size = math.max(8, base - 2)
			left:SetTextHeight(size)
			right:SetTextHeight(size)
			if mid then
				mid:SetTextHeight(size)
			end
			if uf.name and uf.name.SetTextHeight then
				uf.name:SetTextHeight(math.max(6, math.floor(base * 0.7 + 0.5)))
			end
		end
	end)
	if setup.unitNameAnchorStyle == anchors.AboveHealthBar and uf.name and not ShowOnlyName(uf) then
		local gap = setup.healthBarToNameAboveSpacing or 2
		pcall(function()
			uf.name:ClearAllPoints()
			uf.name:SetPoint("BOTTOMLEFT", health, "TOPLEFT", 0, gap)
			uf.name:SetPoint("BOTTOMRIGHT", health, "TOPRIGHT", 0, gap)
		end)
	end
end

if IsForeverClient() then
	local foreverElapsed = 0
	driver:HookScript("OnUpdate", function(_, elapsed)
		if OptionsOpen() then
			return
		end
		foreverElapsed = foreverElapsed + elapsed
		local placeText = foreverElapsed >= 0.25
		if placeText then
			foreverElapsed = 0
		end
		for unit in pairs(activeUnits) do
			local uf = NP.GetParts(unit)
			-- Combat shows the level badge and Blizzard shortens the bar by that width.
			ApplyForeverPlate(uf)
			if placeText then PlaceHealthReadout(uf) end
		end
	end)
end

-- Live has no level. Hide Blizzard's level frames. Do not stretch the bar.
local function IsLiveClient()
	return NP.IsLiveClient()
end

local function HideLiveLevelRegion(frame)
	if not (frame and frame.Hide) then return end
	if frame.IsShown then
		local ok, shown = pcall(frame.IsShown, frame)
		if ok and NP.IsUsable(shown) and shown == false then return end
	end
	frame:Hide()
end

local function HideLiveLevel(uf)
	if not uf or uf.unit == NP.PREVIEW_UNIT or uf.unit == "preview" then
		return
	end
	if uf.LevelFrame and uf.LevelFrame.Hide then
		HideLiveLevelRegion(uf.LevelFrame)
	end
	if uf.PlayerLevelDiffFrame and uf.PlayerLevelDiffFrame.Hide then
		HideLiveLevelRegion(uf.PlayerLevelDiffFrame)
	end
end

if IsLiveClient() then
	driver:HookScript("OnUpdate", function()
		if OptionsOpen() then
			return
		end
		for unit in pairs(activeUnits) do
			HideLiveLevel(NP.GetParts(unit))
		end
	end)
end
