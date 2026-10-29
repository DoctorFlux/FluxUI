-- NamePlates/Countdown.lua — nameplate aura countdown digits at a pinned size.
-- Size: FLUX_NAMEPLATE_AURA_COUNTDOWN_SCALE of a 16px base (0.75 = 12px on every client).
-- A Flux text host sits over each aura cooldown. Blizzard digits are faded with
-- SetTextColor alpha only after Flux has a label; never SetFont / SetScale /
-- SetCountdownFont on Blizzard aura text, and never hook the aura mixins.
-- The Settings preview plate is skipped (it is not a world plate).
local addonName, ns = ...
local Flux = ns.Flux
local NP = Flux.NamePlates

local Countdown = NP.RegisterModule("countdown", { interval = 0.1 })

local FLUX_NAMEPLATE_AURA_COUNTDOWN_SCALE = 0.75
local FLUX_NAMEPLATE_AURA_COUNTDOWN_BASE_PX = 16
local MAX_DURATION_SEC = 60

local hosts = setmetatable({}, { __mode = "k" })

local function GetSize()
	local scale = FLUX_NAMEPLATE_AURA_COUNTDOWN_SCALE
	if scale < 0.35 then
		scale = 0.35
	elseif scale > 1.5 then
		scale = 1.5
	end
	local size = math.floor(FLUX_NAMEPLATE_AURA_COUNTDOWN_BASE_PX * scale + 0.5)
	return math.max(4, math.min(24, size))
end

local function CanUseObject(obj)
	if not obj then
		return false
	end
	if obj.CanBeAccessedInContext then
		local ok, allowed = pcall(obj.CanBeAccessedInContext, obj)
		if not ok or not NP.BoolTest(allowed, false) then
			return false
		end
	end
	return true
end

local function IsShownSafe(frame)
	if not frame or not frame.IsShown then
		return false
	end
	local ok, shown = pcall(frame.IsShown, frame)
	return ok and NP.BoolTest(shown, false) or false
end

local function GetBlizzardDigits(cooldown)
	if cooldown.GetCountdownFontString then
		local ok, fs = pcall(cooldown.GetCountdownFontString, cooldown)
		if ok and fs then
			return fs
		end
	end
	if cooldown.GetRegions then
		local regions = { pcall(cooldown.GetRegions, cooldown) }
		for i = 2, #regions do
			local r = regions[i]
			if r and r.GetObjectType and r:GetObjectType() == "FontString" then
				return r
			end
		end
	end
	return nil
end

local function SetBlizzardDigitsAlpha(cooldown, alpha, fs)
	fs = fs or (cooldown and GetBlizzardDigits(cooldown))
	if fs and fs.SetTextColor then
		pcall(fs.SetTextColor, fs, 1, 1, 1, alpha)
	end
end

local function FormatRemaining(remain)
	if remain >= 10 then
		return string.format("%d", math.floor(remain))
	end
	return string.format("%.1f", remain)
end

--- Blizzard's own countdown text (may be a secret string; SetText accepts it),
--- else a label from GetCooldownTimes when those numbers are readable.
local function ReadLabel(cooldown, fs)
	if fs and fs.GetText then
		local ok, txt = pcall(fs.GetText, fs)
		if ok then
			if NP.IsSecret(txt) then
				return txt
			end
			if type(txt) == "string" and txt ~= "" then
				return txt
			end
		end
	end
	if not cooldown.GetCooldownTimes then
		return nil
	end
	local ok, start, duration = pcall(cooldown.GetCooldownTimes, cooldown)
	if not ok or not NP.IsUsable(start) or not NP.IsUsable(duration) then
		return nil
	end
	start, duration = tonumber(start), tonumber(duration)
	if not start or not duration or duration <= 0 then
		return nil
	end
	if duration > 1000 or start > 100000 then
		start, duration = start / 1000, duration / 1000
	end
	if duration > MAX_DURATION_SEC then
		return nil
	end
	local remain = start + duration - GetTime()
	if remain <= 0 then
		return nil
	end
	return FormatRemaining(remain)
end

local function EnsureHost(auraItem)
	local host = hosts[auraItem]
	if host then
		return host
	end
	host = NP.CreateHost(28, 18)
	local text = host:CreateFontString(nil, "OVERLAY")
	local size = GetSize()
	text:SetFont(NP.FONT, size, "OUTLINE")
	text:SetPoint("CENTER", host, "CENTER", 0, 0)
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")
	text:SetTextColor(1, 1, 1, 1)
	host.text = text
	hosts[auraItem] = host
	return host
end

local function HideHost(auraItem, cooldown, digits)
	local host = hosts[auraItem]
	if host then
		host:Hide()
	end
	SetBlizzardDigitsAlpha(cooldown, 1, digits)
end

local function HostLevel(plate, auraItem, cooldown)
	local level = 0
	local ok, n = pcall(plate.GetFrameLevel, plate)
	if ok and type(n) == "number" and not NP.IsSecret(n) and n > level then
		level = n
	end
	ok, n = pcall(auraItem.GetFrameLevel, auraItem)
	if ok and type(n) == "number" and not NP.IsSecret(n) and n > level then
		level = n
	end
	ok, n = pcall(cooldown.GetFrameLevel, cooldown)
	if ok and type(n) == "number" and not NP.IsSecret(n) and n > level then
		level = n
	end
	return level + NP.FRAME_LEVEL_OFFSET
end

local function UpdateAuraItem(auraItem, plate)
	if not auraItem then
		return
	end
	local cooldown = auraItem.Cooldown
	if not cooldown or not CanUseObject(auraItem) or not CanUseObject(cooldown) or not IsShownSafe(auraItem) then
		HideHost(auraItem, cooldown)
		return
	end
	-- Reuse this poll's text region for alpha; never retain it across aura reuse.
	local digits = GetBlizzardDigits(cooldown)
	local label = ReadLabel(cooldown, digits)
	if label == nil then
		HideHost(auraItem, cooldown, digits)
		return
	end

	local host = EnsureHost(auraItem)
	pcall(host.text.SetText, host.text, label)
	if host:GetParent() ~= plate and not pcall(host.SetParent, host, plate) then
		HideHost(auraItem, cooldown, digits)
		return
	end
	host:ClearAllPoints()
	if not pcall(host.SetPoint, host, "CENTER", cooldown, "CENTER", 0, 0) then
		HideHost(auraItem, cooldown, digits)
		return
	end
	pcall(host.SetFrameLevel, host, HostLevel(plate, auraItem, cooldown))
	host:Show()
	SetBlizzardDigitsAlpha(cooldown, 0, digits)
end

local function UpdateList(listFrame, plate)
	if not listFrame or not listFrame.GetChildren then
		return
	end
	local children = { pcall(listFrame.GetChildren, listFrame) }
	for i = 2, #children do
		local child = children[i]
		if child and child.Cooldown then
			UpdateAuraItem(child, plate)
		end
	end
end

local function UpdatePool(pool, plate)
	if not pool or not pool.EnumerateActive then
		return
	end
	for a, b in pool:EnumerateActive() do
		local frame = (type(a) == "table" and a.Cooldown) and a or b
		if frame then
			UpdateAuraItem(frame, plate)
		end
	end
end

local function UpdatePlate(unit)
	local uf, plate = NP.GetParts(unit)
	local auras = uf and uf.AurasFrame
	if not auras then
		return
	end
	UpdatePool(auras.auraItemFramePool, plate)
	UpdateList(auras.DebuffListFrame, plate)
	UpdateList(auras.BuffListFrame, plate)
	UpdateList(auras.CrowdControlListFrame, plate)
	local loc = auras.LossOfControlFrame and auras.LossOfControlFrame.AuraItemFrame
	UpdateAuraItem(loc, plate)
end

local function HideStale()
	for auraItem, host in pairs(hosts) do
		if host:IsShown() and not IsShownSafe(auraItem) then
			host:Hide()
		end
	end
end

function Countdown.Added(unit)
	UpdatePlate(unit)
end

function Countdown.Removed()
	HideStale()
end

function Countdown.Refresh(unit)
	UpdatePlate(unit)
end

function Countdown.Poll()
	for unit in pairs(NP.activeUnits) do
		pcall(UpdatePlate, unit)
	end
	HideStale()
end
