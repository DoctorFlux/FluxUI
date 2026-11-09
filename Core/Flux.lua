-- Flux.lua — kernel + namespace. Loads first among Core files.
local addonName, ns = ...

local Flux = ns.Flux or {}
ns.Flux = Flux
_G.Flux = Flux

Flux.addonName = addonName
Flux.ns = ns
-- Two samples only; detailed recording is enabled after SavedVariables load.
Flux.startupBegan = ns.startupBegan or (debugprofilestop and debugprofilestop())
Flux.startupMemory = ns.startupMemory or (collectgarbage and collectgarbage("count"))

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
local securePhaseReady = false
local gamepadReleaseQueued = false
local loginRequested = false
local gamepadBarrierReleased = false

local function Safecall(fn, ...)
	if _type(fn) ~= "function" then
		return false, "callback is not a function"
	end
	local ok, err = _pcall(fn, ...)
	if not ok then
		local geh = _geterrorhandler
		if geh then
			geh()(_tostring(err))
		end
	end
	return ok, err
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
	-- Bind HUD input from current carried items before world entry can enable
	-- lockdown. The full inventory service still starts in the deferred phase.
	if Flux.Inventory and Flux.Inventory.PrepareHUD then
		Safecall(Flux.Inventory.PrepareHUD)
	end
	RunQueue(loginQueue)
	if Flux.Module and Flux.Module.EnableEligible then
		Flux.Module.EnableEligible("hud")
		-- One frame boundary lets immediate HUD work complete before caches and
		-- other nonessential modules. No fixed-duration startup delay.
		local function Deferred()
			Flux.deferredPhaseReady = true
			Flux.Module.EnableEligible("deferred")
			if Flux.Startup then Flux.Startup.Mark("initialization_complete") end
		end
		if Flux.Timer then Flux.Timer.After(0, Deferred) else Deferred() end
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

local function RunReadyPhases()
	if not Flux.loaded then return end
	if _G.FluxOptions and not Flux.optionsBootstrapComplete then return end
	if DeferModuleEnableForGamepadSetup() and not gamepadBarrierReleased then return end
	if not securePhaseReady then
		securePhaseReady = true
		Flux.securePhaseReady = true
		if Flux.Module then Flux.Module.EnableEligible("secure") end
	end
	if loginRequested then EnableModules() end
end

local function FireDeferredModuleEnable()
	if gamepadReleaseQueued or securePhaseReady then return end
	gamepadReleaseQueued = true
	local function Release()
		gamepadReleaseQueued = false
		gamepadBarrierReleased = true
		RunReadyPhases()
	end
	if Flux.Timer then Flux.Timer.After(0, Release)
	elseif C_Timer and C_Timer.After then C_Timer.After(0, Release)
	else
		-- Without a next-frame primitive wait for PLAYER_LOGIN/ENTERING_WORLD;
		-- never run inside Blizzard's VARIABLES_LOADED gamepad callbacks.
		gamepadReleaseQueued = false
	end
end

local function RequestModuleEnable()
	loginRequested = true
	if moduleEnableQueued then return end
	moduleEnableQueued = true
	if securePhaseReady or gamepadBarrierReleased or not DeferModuleEnableForGamepadSetup() then
		RunReadyPhases()
		return
	end
	if variablesLoaded then
		FireDeferredModuleEnable()
		return
	end
end

-- File-scope frame so CPU for lifecycle events bills this addon.
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("VARIABLES_LOADED")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
local function RetryConfiguration()
	local options = _G.FluxOptions
	if options and not Flux.optionsBootstrapComplete and options.EnsureSavedConfiguration then
		Safecall(options.EnsureSavedConfiguration)
	end
	if not options or Flux.optionsBootstrapComplete then
		boot:UnregisterEvent("PLAYER_REGEN_ENABLED")
		if Flux.Startup then Flux.Startup.Mark("saved_configuration_ready") end
	end
end
boot:SetScript("OnEvent", function(_, event, name)
	if event == "VARIABLES_LOADED" then
		variablesLoaded = true
		boot:UnregisterEvent("VARIABLES_LOADED")
		if Flux.loaded and DeferModuleEnableForGamepadSetup() then
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
		if _G.FluxOptions and not Flux.optionsBootstrapComplete then boot:RegisterEvent("PLAYER_REGEN_ENABLED") end
		if Flux.Startup then Flux.Startup.Configure() end
		if DeferModuleEnableForGamepadSetup() then
			-- EventUtil handles late LoadAddOn as well as a fresh VARIABLES_LOADED.
			-- Always leave its secure callback stack before touching action frames.
			if EventUtil and EventUtil.ContinueOnVariablesLoaded then
				EventUtil.ContinueOnVariablesLoaded(function()
					variablesLoaded = true
					FireDeferredModuleEnable()
				end)
			elseif variablesLoaded then FireDeferredModuleEnable() end
		else
			RunReadyPhases()
		end
		-- /reload and mid-session LoadAddOn: PLAYER_LOGIN may not follow.
		if IsLoggedIn and IsLoggedIn() and not Flux.loggedIn then
			boot:UnregisterEvent("PLAYER_LOGIN")
			RequestModuleEnable()
		end
	elseif event == "PLAYER_LOGIN" then
		boot:UnregisterEvent("PLAYER_LOGIN")
		-- VARIABLES_LOADED callbacks have finished by PLAYER_LOGIN. Release
		-- Forever here rather than waiting for a timer after combat world entry.
		if variablesLoaded and DeferModuleEnableForGamepadSetup() then
			gamepadBarrierReleased = true
		end
		if Flux.loggedIn or moduleEnableQueued then
			RunReadyPhases()
			return
		end
		RequestModuleEnable()
	elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" then
		RetryConfiguration()
		-- Also reconciles failed/dependency-blocked modules on reconnect and
		-- world transitions. Completed modules never rebuild their frames.
		if not Flux.loggedIn then RequestModuleEnable() end
		if DeferModuleEnableForGamepadSetup() and variablesLoaded and not securePhaseReady then
			if not (Flux.Timer or (C_Timer and C_Timer.After)) then gamepadBarrierReleased = true end
		end
		RunReadyPhases()
		if Flux.Module then Flux.Module.EnableEligible() end
	end
end)
