-- Flux.lua — kernel + namespace. Loads first among Core files.
local addonName, ns = ...

local Flux = ns.Flux or {}
ns.Flux = Flux
_G.Flux = Flux

Flux.addonName = addonName
Flux.ns = ns

local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local addonVer = getMeta and getMeta(addonName, "Version")
Flux.version = (addonVer and addonVer ~= "") and addonVer or "0.0.1"

local _tostring = tostring
local _select = select
local _pcall = pcall
local _type = type
local _geterrorhandler = geterrorhandler

local loadQueue = {}
local loginQueue = {}
Flux.loaded = false
Flux.loggedIn = false
local variablesLoaded = false
local moduleEnableQueued = false

local function Safecall(fn, ...)
	if _type(fn) ~= "function" then
		return
	end
	local ok, err = _pcall(fn, ...)
	if not ok then
		local geh = _geterrorhandler
		if geh then
			geh()(_tostring(err))
		end
	end
end

local function RunQueue(queue)
	for i = 1, #queue do
		Safecall(queue[i])
		queue[i] = nil
	end
end

--- Run after this addon's ADDON_LOADED (all TOC files have executed).
function Flux.AfterLoad(fn)
	if Flux.loaded then
		Safecall(fn)
		return
	end
	loadQueue[#loadQueue + 1] = fn
end

--- Run at PLAYER_LOGIN (or immediately if already logged in).
function Flux.AfterLogin(fn)
	if Flux.loggedIn then
		Safecall(fn)
		return
	end
	loginQueue[#loginQueue + 1] = fn
end

function Flux.Print(...)
	local n = _select("#", ...)
	if n == 0 then
		print("|cff00ffff[FluxUI]|r")
		return
	end
	local parts = { "|cff00ffff[FluxUI]|r" }
	for i = 1, n do
		parts[i + 1] = _tostring(_select(i, ...))
	end
	print(table.concat(parts, " "))
end

function Flux.Safecall(fn, ...)
	return Safecall(fn, ...)
end

local function EnableModules()
	if Flux.loggedIn then
		return
	end
	Flux.loggedIn = true
	RunQueue(loginQueue)
	if Flux.Module and Flux.Module.EnableEligible then
		Flux.Module.EnableEligible()
	end
end

-- GamepadMainActionBarFrame:PostVariableSetUp runs from
-- EventUtil.TriggerOnVariablesLoaded and calls the protected
-- SetPreferredGamepadInteractTarget. On /reload, ADDON_LOADED is before that
-- event, so enabling modules there creates action buttons and rewrites
-- collector methods first. The protected call is then tainted. Forever waits
-- until the event has finished, then starts on the next frame. The style API
-- is not reliable yet at ADDON_LOADED, so this is every Forever client, not
-- only the gamepad HUD.
local function DeferModuleEnableForGamepadSetup()
	local client = Flux.Client
	return client and client.isCamelot and true or false
end

local function FireDeferredModuleEnable()
	if C_Timer and C_Timer.After then
		C_Timer.After(0, EnableModules)
	else
		EnableModules()
	end
end

local function RequestModuleEnable()
	if moduleEnableQueued then
		return
	end
	moduleEnableQueued = true
	if not DeferModuleEnableForGamepadSetup() then
		EnableModules()
		return
	end
	if variablesLoaded then
		FireDeferredModuleEnable()
		return
	end
	-- Mid-session LoadAddOn never sees VARIABLES_LOADED again. /reload does,
	-- and that handler enables first; this is only the fallback.
	if C_Timer and C_Timer.After then
		C_Timer.After(1, EnableModules)
	end
end

-- File-scope frame so CPU for lifecycle events bills this addon.
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("VARIABLES_LOADED")
boot:SetScript("OnEvent", function(_, event, name)
	if event == "VARIABLES_LOADED" then
		variablesLoaded = true
		boot:UnregisterEvent("VARIABLES_LOADED")
		if moduleEnableQueued and not Flux.loggedIn then
			FireDeferredModuleEnable()
		end
		return
	end
	if event == "ADDON_LOADED" then
		if name ~= addonName then
			return
		end
		boot:UnregisterEvent("ADDON_LOADED")
		Flux.loaded = true
		RunQueue(loadQueue)
		-- /reload and mid-session LoadAddOn: PLAYER_LOGIN may not follow.
		if IsLoggedIn and IsLoggedIn() and not Flux.loggedIn then
			boot:UnregisterEvent("PLAYER_LOGIN")
			RequestModuleEnable()
		end
	elseif event == "PLAYER_LOGIN" then
		boot:UnregisterEvent("PLAYER_LOGIN")
		if Flux.loggedIn or moduleEnableQueued then
			return
		end
		RequestModuleEnable()
	end
end)
