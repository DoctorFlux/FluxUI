-- Restricted.lua — SecureHandler snippet helpers.
-- Forever/camelot: RestrictedExecution captured a nil loadstring_untainted, so
-- Execute / WrapScript / _onstate snippets failed on early builds. Keep the
-- legacy policy for existing callers; PagingWorks probes the repaired engine
-- separately for bars so their established input behavior does not change.
-- Existing callers retain their state/unit-driver shims; bars register through
-- the captured native attribute-driver functions after a successful probe.
local addonName, ns = ...
local Flux = ns.Flux

local Restricted = {}
-- Retain Blizzard's entry points before the legacy Forever shims below.
local nativeAttributeDriver = RegisterAttributeDriver
local nativeUnregisterAttributeDriver = UnregisterAttributeDriver
Flux.Restricted = Restricted
Flux.Engine = Flux.Engine or {}
Flux.Engine.Restricted = Restricted

local function Works()
	local Cap = Flux.Cap
	if Cap and Cap.hasRestrictedClosures == false then
		return false
	end
	return true
end

function Restricted.Works()
	return Works()
end

-- Bars can use repaired Forever secure handlers without changing v8's mouse
-- registration, key proxies, or the compatibility policy of other modules.
-- The public loadstring_untainted global is intentionally removed after load;
-- only executing a snippet proves whether the restricted environment works.
local pagingSupported
function Restricted.PagingWorks()
	if Works() then return true end
	if pagingSupported ~= nil then return pagingSupported end
	local C = Flux.Client
	if not (C and (C.isCamelot or C.isForever)) then return false end
	if InCombatLockdown and InCombatLockdown() then return false end
	local ok, probe = pcall(CreateFrame, "Frame", "FluxBarsSecureProbe", nil, "SecureHandlerBaseTemplate")
	if ok and probe and probe.Execute then
		ok = pcall(probe.Execute, probe, [[ self:SetAttribute("flux-paging-probe", 1) ]])
		pagingSupported = ok and probe:GetAttribute("flux-paging-probe") == 1
		probe:Hide()
	else
		pagingSupported = false
	end
	if Flux.Cap then Flux.Cap.hasSecureBarPaging = pagingSupported end
	return pagingSupported
end

function Restricted.SetPagingSnippet(frame, name, body)
	if InCombatLockdown and InCombatLockdown() then return false end
	if not Restricted.PagingWorks() then return false end
	return pcall(frame.SetAttribute, frame, name, body)
end

function Restricted.ExecutePaging(frame, body)
	if InCombatLockdown and InCombatLockdown() then return false end
	if not Restricted.PagingWorks() then return false end
	return pcall(frame.Execute, frame, body)
end

function Restricted.RegisterPagingDriver(frame, state, values)
	if InCombatLockdown and InCombatLockdown() then return false end
	if Restricted.PagingWorks() and nativeAttributeDriver then
		return pcall(nativeAttributeDriver, frame, "state-" .. state, values)
	end
	return Restricted.RegisterStateDriver(frame, state, values)
end

function Restricted.UnregisterPagingDriver(frame, state)
	if InCombatLockdown and InCombatLockdown() then return false end
	if Restricted.PagingWorks() and nativeUnregisterAttributeDriver then
		return pcall(nativeUnregisterAttributeDriver, frame, "state-" .. state)
	end
	return Restricted.UnregisterStateDriver(frame, state)
end

function Restricted.Execute(frame, body)
	if not Works() then
		return false
	end
	if not frame or type(frame.Execute) ~= "function" or type(body) ~= "string" then
		return false
	end
	return pcall(frame.Execute, frame, body)
end

function Restricted.WrapScript(header, frame, script, preBody, postBody)
	if not Works() then
		return false
	end
	if not header or type(header.WrapScript) ~= "function" then
		return false
	end
	if postBody == nil then
		return pcall(header.WrapScript, header, frame, script, preBody)
	end
	return pcall(header.WrapScript, header, frame, script, preBody, postBody)
end

function Restricted.UnwrapScript(header, frame, script)
	if not Works() then
		return false
	end
	if not header or type(header.UnwrapScript) ~= "function" then
		return false
	end
	return pcall(header.UnwrapScript, header, frame, script)
end

function Restricted.SetSnippet(frame, name, body)
	if not Works() then
		return false
	end
	if not frame or type(frame.SetAttribute) ~= "function" or type(name) ~= "string" then
		return false
	end
	return pcall(frame.SetAttribute, frame, name, body)
end

-- ---------------------------------------------------------------------------
-- Forever: insecure stand-in for RegisterStateDriver / RegisterUnitWatch.
-- Never call the Blizzard manager — SetAttribute on it taints OnUpdate, then
-- MainActionBar:Hide and FluxUnitFrame_*:Show are ADDON_ACTION_BLOCKED.
-- ---------------------------------------------------------------------------

local attributeDrivers = {}
local unitWatchers = {}
local fallbackFrame
local fallbackTimer = 0
local FALLBACK_THROTTLE = 0.2

local function IsFluxOwned(frame)
	if not frame then
		return false
	end
	local name = frame.GetName and frame:GetName()
	return type(name) == "string" and name:sub(1, 4) == "Flux"
end

local function InLockdown()
	return InCombatLockdown and InCombatLockdown() or false
end

local function FrameUnit(frame)
	if not frame then
		return nil
	end
	if SecureButton_GetUnit then
		local ok, unit = pcall(SecureButton_GetUnit, frame)
		if ok and unit and unit ~= "" then
			return unit
		end
	end
	if frame.GetAttribute then
		local unit = frame:GetAttribute("unit")
		if unit and unit ~= "" then
			return unit
		end
	end
	return frame.unit
end

local function SetShownSafe(frame, shown)
	if not frame then
		return
	end
	if shown then
		if frame.IsShown and frame:IsShown() then
			return
		end
		if frame.Show then
			pcall(frame.Show, frame)
		end
	else
		if frame.IsShown and not frame:IsShown() then
			return
		end
		if frame.Hide then
			pcall(frame.Hide, frame)
		end
	end
end

local function ApplyUnitWatch(frame, asState)
	if not IsFluxOwned(frame) then
		return
	end
	local unit = FrameUnit(frame)
	local exists = unit and UnitExists(unit)
	if asState then
		if InLockdown() then
			return
		end
		if frame.SetAttribute then
			pcall(frame.SetAttribute, frame, "state-unitexists", exists and true or false)
		end
		return
	end
	-- Keep the button shown so combat can still alpha-toggle visibility.
	-- UnitFrames.SyncWatchedUnitFrameVisibility owns hide via alpha.
	-- Do not Hide here — a hidden secure frame cannot be Shown in combat.
	if not InLockdown() then
		SetShownSafe(frame, true)
	end
end

local function ApplyAttributeDriver(frame, attribute, values)
	if not IsFluxOwned(frame) or InLockdown() then
		return
	end
	if type(values) ~= "string" or values == "" or not SecureCmdOptionParse then
		return
	end
	local newValue = SecureCmdOptionParse(values)
	if attribute == "state-visibility" then
		local name = frame.GetName and frame:GetName()
		local petExistence = name == "FluxUnitFrame_pet" or name == "FluxUnitFrame_pettarget"
		if newValue == "show" then
			SetShownSafe(frame, true)
		elseif newValue == "hide" then
			SetShownSafe(frame, false)
		end
		-- Combat fade sets alpha 0 while the button stays shown. A real
		-- Show/Hide on regen must come back opaque or the next summon is invisible.
		if petExistence and frame.SetAlpha and not InLockdown() then
			pcall(frame.SetAlpha, frame, 1)
		end
		return
	end
	if not newValue or not frame.SetAttribute then
		return
	end
	if newValue == "nil" then
		newValue = nil
	else
		newValue = tonumber(newValue) or newValue
	end
	local oldValue = frame.GetAttribute and frame:GetAttribute(attribute)
	if newValue ~= oldValue then
		pcall(frame.SetAttribute, frame, attribute, newValue)
		if attribute == "state-mod" then
			local Bars = Flux.Bars
			local State = Bars and Bars.State
			if State and State.OnModFallback then
				State.OnModFallback(newValue)
			end
		end
	end
end

local function ApplyAll()
	-- Show/Hide during lockdown is ADDON_ACTION_BLOCKED. Pet frames fade in
	-- SyncWatchedUnitFrameVisibility until PLAYER_REGEN_ENABLED runs this again.
	if InLockdown() then
		return
	end
	for frame, drivers in pairs(attributeDrivers) do
		for attribute, values in pairs(drivers) do
			ApplyAttributeDriver(frame, attribute, values)
		end
	end
	for frame, asState in pairs(unitWatchers) do
		ApplyUnitWatch(frame, asState)
	end
end

local function EnsureFallbackFrame()
	if fallbackFrame then
		return fallbackFrame
	end
	fallbackFrame = CreateFrame("Frame", "FluxInsecureStateDriver")
	fallbackFrame:Hide()
	fallbackFrame:SetScript("OnUpdate", function(_, elapsed)
		fallbackTimer = fallbackTimer - elapsed
		if fallbackTimer > 0 then
			return
		end
		fallbackTimer = FALLBACK_THROTTLE
		ApplyAll()
	end)
	fallbackFrame:SetScript("OnEvent", function()
		fallbackTimer = 0
		ApplyAll()
	end)
	fallbackFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	fallbackFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
	fallbackFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	fallbackFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	fallbackFrame:RegisterEvent("UNIT_PET")
	fallbackFrame:RegisterEvent("UNIT_TARGET")
	fallbackFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	fallbackFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	fallbackFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
	fallbackFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
	fallbackFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
	fallbackFrame:RegisterEvent("UPDATE_STEALTH")
	return fallbackFrame
end

local function FallbackActive()
	return next(attributeDrivers) ~= nil or next(unitWatchers) ~= nil
end

local function SyncFallbackFrame()
	local f = EnsureFallbackFrame()
	if FallbackActive() then
		f:Show()
		fallbackTimer = 0
		ApplyAll()
	else
		f:Hide()
	end
end

function Restricted.RegisterAttributeDriver(frame, attribute, values)
	if Works() then
		if RegisterAttributeDriver then
			return pcall(RegisterAttributeDriver, frame, attribute, values)
		end
		return false
	end
	if not frame or type(attribute) ~= "string" or attribute:sub(1, 1) == "_" then
		return false
	end
	if not IsFluxOwned(frame) then
		return false
	end
	local drivers = attributeDrivers[frame]
	if not drivers then
		drivers = {}
		attributeDrivers[frame] = drivers
	end
	drivers[attribute] = values
	SyncFallbackFrame()
	return true
end

function Restricted.UnregisterAttributeDriver(frame, attribute)
	if Works() then
		if UnregisterAttributeDriver then
			return pcall(UnregisterAttributeDriver, frame, attribute)
		end
		return false
	end
	if not frame then
		return false
	end
	if attribute then
		local drivers = attributeDrivers[frame]
		if drivers then
			drivers[attribute] = nil
			if not next(drivers) then
				attributeDrivers[frame] = nil
			end
		end
	else
		attributeDrivers[frame] = nil
	end
	SyncFallbackFrame()
	return true
end

function Restricted.RegisterStateDriver(frame, state, values)
	return Restricted.RegisterAttributeDriver(frame, "state-" .. tostring(state), values)
end

function Restricted.UnregisterStateDriver(frame, state)
	if state then
		return Restricted.UnregisterAttributeDriver(frame, "state-" .. tostring(state))
	end
	return Restricted.UnregisterAttributeDriver(frame)
end

function Restricted.RegisterUnitWatch(frame, asState)
	if Works() then
		if RegisterUnitWatch then
			return pcall(RegisterUnitWatch, frame, asState)
		end
		return false
	end
	if not IsFluxOwned(frame) then
		return false
	end
	unitWatchers[frame] = asState and true or false
	SyncFallbackFrame()
	return true
end

function Restricted.UnregisterUnitWatch(frame)
	if Works() then
		if UnregisterUnitWatch then
			return pcall(UnregisterUnitWatch, frame)
		end
		return false
	end
	if not frame then
		return false
	end
	unitWatchers[frame] = nil
	SyncFallbackFrame()
	return true
end

function Restricted.UnitWatchRegistered(frame)
	if Works() then
		return UnitWatchRegistered and UnitWatchRegistered(frame) or false
	end
	return unitWatchers[frame] ~= nil
end

if not Works() then
	RegisterAttributeDriver = function(frame, attribute, values)
		return Restricted.RegisterAttributeDriver(frame, attribute, values)
	end
	UnregisterAttributeDriver = function(frame, attribute)
		return Restricted.UnregisterAttributeDriver(frame, attribute)
	end
	RegisterStateDriver = function(frame, state, values)
		return Restricted.RegisterStateDriver(frame, state, values)
	end
	UnregisterStateDriver = function(frame, state)
		return Restricted.UnregisterStateDriver(frame, state)
	end
	RegisterUnitWatch = function(frame, asState)
		return Restricted.RegisterUnitWatch(frame, asState)
	end
	UnregisterUnitWatch = function(frame)
		return Restricted.UnregisterUnitWatch(frame)
	end
	UnitWatchRegistered = function(frame)
		return Restricted.UnitWatchRegistered(frame)
	end
end
