-- BlizzardSettings/Write.lua — the only place Flux writes Blizzard CVars and Settings.
-- CVars: C_CVar.SetCVar / SetCVarBitfield only, skipped when missing or already equal.
-- Writes wait in combat, through Edit Mode's complete enter/exit pass, or while
-- SettingsPanel is shown (its previews rebuild
-- plates and raid frames on CVAR_UPDATE) and flush on PLAYER_REGEN_ENABLED or
-- SettingsPanel OnHide. Settings.SetValue / NotifyUpdate only run on clients without
-- enforced secret values (Era / Anniversary / other Classic): on Forever and Live
-- they run Blizzard setting callbacks as Flux, which taints plates and raid frames.
local addonName, ns = ...
local Flux = ns.Flux

local BS = Flux.BlizzardSettings or {}
Flux.BlizzardSettings = BS

local Write = {}
BS.Write = Write

function Write.IsSecretClient()
	local client = Flux.Client
	if not client or client.isAnyClassic then
		return false
	end
	return (client.isRetail and client.isPostDF) and true or false
end

function Write.MayUseSettingsAPI()
	return not Write.IsSecretClient()
end

local function IsCompactFrameCVar(cvar)
	if type(cvar) ~= "string" then return false end
	local lower = string.lower(cvar)
	return lower:sub(1, 10) == "raidframes" or lower:sub(1, 9) == "pvpframes"
		or lower == "usecompactpartyframes" or lower == "raidoptiondisplaymaintankandassist"
		or lower == "raidoptiondisplaypets" or lower == "pvpoptiondisplaypets"
end

function Write.Get(cvar)
	if C_CVar and C_CVar.GetCVar then
		return C_CVar.GetCVar(cvar)
	end
	if GetCVar then
		return GetCVar(cvar)
	end
	return nil
end

function Write.Exists(cvar)
	return Write.Get(cvar) ~= nil
end

--- Missing CVars count as matching so nothing is written for them.
function Write.Matches(cvar, desired)
	local cur = Write.Get(cvar)
	if cur == nil then
		return true
	end
	local a, b = tonumber(cur), tonumber(desired)
	if a and b then
		return math.abs(a - b) < 0.001
	end
	return tostring(cur) == tostring(desired)
end

local function InCombat()
	return InCombatLockdown and InCombatLockdown() and true or false
end

local function SettingsPanelShown()
	local panel = SettingsPanel
	return panel and panel.IsShown and panel:IsShown() and true or false
end

function Write.CanWriteNow()
	return not InCombat() and not SettingsPanelShown()
		and not (FluxEditModeBusy and FluxEditModeBusy())
end

--- Returns true if the CVar was written.
function Write.CVar(cvar, value, force)
	-- A later timer does not make CUF callbacks safe: they persist native option
	-- tables written under addon execution, then Edit Mode consumes them on exit.
	-- Match the CUF policy in Flux.CVar/FluxSetCVar, including explicit resets.
	if Write.IsSecretClient() and IsCompactFrameCVar(cvar) then return false end
	if InCombat() or not Write.Exists(cvar) then
		return false
	end
	if not force and Write.Matches(cvar, value) then
		return false
	end
	local set = (C_CVar and C_CVar.SetCVar) or SetCVar
	if not set then
		return false
	end
	return pcall(set, cvar, tostring(value)) and true or false
end

--- Bitfield CVars store packed bits; never write them with a raw number.
function Write.Bit(cvar, index, enabled, force)
	if InCombat() or type(index) ~= "number" or index <= 0 or not Write.Exists(cvar) then
		return false
	end
	enabled = enabled and true or false
	local getBit = (C_CVar and C_CVar.GetCVarBitfield) or GetCVarBitfield
	if not force and getBit then
		local ok, cur = pcall(getBit, cvar, index)
		local secret = false
		if issecretvalue then
			local okSecret, res = pcall(issecretvalue, cur)
			secret = okSecret and res and true or false
		end
		if ok and not secret and (cur and true or false) == enabled then
			return false
		end
	end
	local setBit = (C_CVar and C_CVar.SetCVarBitfield) or SetCVarBitfield
	if not setBit then
		return false
	end
	return pcall(setBit, cvar, index, enabled) and true or false
end

function Write.SetSetting(variable, value)
	if not Write.MayUseSettingsAPI() or not (Settings and Settings.SetValue) then
		return false
	end
	return pcall(Settings.SetValue, variable, value) and true or false
end

--- Update a control on the open Options page (Era / Anniversary only, see header).
--- Not for nameplate, raid, or PROXY_SHOW_ACTIONBAR_* settings: their callbacks
--- re-layout raid previews and Edit Mode action bars as Flux.
function Write.SetShownValue(variable, value)
	if not Write.MayUseSettingsAPI() or not (Settings and Settings.SetValue) then
		return false
	end
	return pcall(Settings.SetValue, variable, value, true) and true or false
end

--- Retail's Sticky Targeting checkbox negates deselectOnClick. Its native
--- setting writes only that CVar; keep all other Settings callbacks behind
--- MayUseSettingsAPI so nameplate and compact-frame previews stay guarded.
function Write.SetStickyTargetingOff()
	if not Write.IsSecretClient() or InCombat() or not (Settings and Settings.GetSetting) then
		return false
	end
	if Write.Matches("deselectOnClick", "1") then
		return true
	end
	local ok, setting = pcall(Settings.GetSetting, "deselectOnClick")
	if not ok or not setting or not setting.SetValue then
		return false
	end
	local wrote = pcall(setting.SetValue, setting, false, true)
	return wrote and Write.Matches("deselectOnClick", "1") and true or false
end

function Write.RefreshShown(...)
	if not Write.MayUseSettingsAPI() or not (Settings and Settings.NotifyUpdate) then
		return
	end
	for i = 1, select("#", ...) do
		local variable = select(i, ...)
		if type(variable) == "table" then
			for _, name in ipairs(variable) do
				pcall(Settings.NotifyUpdate, name)
			end
		elseif variable ~= nil then
			pcall(Settings.NotifyUpdate, variable)
		end
	end
end

function Write.Notify(...)
	if not Write.MayUseSettingsAPI() or not (Settings and Settings.NotifyUpdate) then
		return
	end
	for i = 1, select("#", ...) do
		local variable = select(i, ...)
		if type(variable) == "table" then
			for _, name in ipairs(variable) do
				pcall(Settings.NotifyUpdate, name)
			end
		elseif variable ~= nil then
			pcall(Settings.NotifyUpdate, variable)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Deferred work
-- ---------------------------------------------------------------------------
local queue = {}
local flusher = CreateFrame("Frame")
local panelHooked = false

local function HookSettingsPanel()
	if panelHooked or not SettingsPanel then
		return
	end
	panelHooked = true
	local function FlushAfterHide()
		-- IsShown() is still true during OnHide. The Forever watcher fires
		-- once the panel is already hidden, and After(0) stays safe there too.
		C_Timer.After(0, Write.Flush)
	end
	local client = Flux.Client
	if client and (client.isCamelot or client.isForever) then
		local was = SettingsPanel:IsShown() and true or false
		local watch = CreateFrame("Frame")
		watch:SetScript("OnUpdate", function()
			if not SettingsPanel or not SettingsPanel.IsShown then
				return
			end
			local shown = SettingsPanel:IsShown() and true or false
			if shown == was then
				return
			end
			was = shown
			if not shown then
				FlushAfterHide()
			end
		end)
		return
	end
	if not SettingsPanel.HookScript then
		panelHooked = false
		return
	end
	SettingsPanel:HookScript("OnHide", FlushAfterHide)
end

local function RunNow(fn)
	local ok, result = pcall(fn)
	if not ok then
		if geterrorhandler then
			geterrorhandler()(result)
		end
		return false
	end
	return result
end

--- Run fn now if writes are allowed, else queue it under key (one entry per key).
function Write.Run(key, fn)
	if Write.CanWriteNow() then
		queue[key] = nil
		return RunNow(fn)
	end
	queue[key] = fn
	flusher:RegisterEvent("PLAYER_REGEN_ENABLED")
	local editing = FluxEditModeBusy and FluxEditModeBusy()
	if not editing or SettingsPanelShown() then HookSettingsPanel() end
	if editing and FluxAfterEditMode then
		FluxAfterEditMode(Write.Flush)
	end
	return false
end

function Write.IsQueued(key)
	return queue[key] ~= nil
end

function Write.Flush()
	if not Write.CanWriteNow() then
		if SettingsPanelShown() then HookSettingsPanel() end
		return
	end
	flusher:UnregisterEvent("PLAYER_REGEN_ENABLED")
	for key, fn in pairs(queue) do
		queue[key] = nil
		RunNow(fn)
	end
end

flusher:SetScript("OnEvent", function()
	Write.Flush()
end)
