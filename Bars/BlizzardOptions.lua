-- Bars/BlizzardOptions.lua — Blizzard Key Bindings + Action Bars options for the 19-col strip.
-- Columns 13–19 keep Hosts.BorrowedBindingOrder commands; this only reshapes the Options UI.
-- Live / Forever (post-DF retail): labels + extra bars off. Never replace GetBinding /
-- KeybindingsOverrides / ActionBarsOverrides: a Flux function inside Settings
-- registration taints the pooled Settings rows, and the nameplate options preview
-- then lays out auras tainted (secret frame rect).
local addonName, ns = ...
local Flux = ns.Flux
local Client = Flux.Client
local Cap = Flux.Cap

local Bars = Flux.Bars
local Options = {}
Bars.BlizzardOptions = Options

local SUPPRESSED_CATEGORY = "BINDING_HEADER_FLUXUI_SUPPRESSED"

local SUPPRESSED_PRIMARY_ACTIONBAR_ACTIONS = {
	ACTIONPAGE1 = true,
	ACTIONPAGE2 = true,
	ACTIONPAGE3 = true,
	ACTIONPAGE4 = true,
	ACTIONPAGE5 = true,
	ACTIONPAGE6 = true,
	PREVIOUSACTIONPAGE = true,
	NEXTACTIONPAGE = true,
}

local hookedKeybinds = false
local hookedVisibility = false
local hookedAdjustActionBarSettings = false
local bindingUiHooksInstalled = false
local origAddBindingCategories
local origCreateActionBarVisibilitySettings
local origAdjustActionBarSettings
local origGetBinding
local origCreateKeybindingSectionInitializer

local function Hosts()
	return Bars.Hosts
end

local function BorrowedOrder()
	local h = Hosts()
	return (h and h.BorrowedBindingOrder) or {}
end

local function BorrowedSet()
	local h = Hosts()
	return (h and h.BorrowedBindingSet) or {}
end

local function IsPlunderstorm()
	if C_GameRules and C_GameRules.IsPlunderstorm then
		local ok, r = pcall(C_GameRules.IsPlunderstorm)
		return ok and r
	end
	return false
end

local function Mode()
	if Cap and Cap.GetFluxBlizzardActionBarUIMode then
		return Cap.GetFluxBlizzardActionBarUIMode()
	end
	return "unsupported"
end

local function SkipSettingsReplace()
	return Client and Client.isRetail and Client.isPostDF
end

local function After0(fn)
	if C_Timer and C_Timer.After then
		C_Timer.After(0, fn)
	else
		fn()
	end
end

function Options.SetupBindingDisplayNames()
	local order = BorrowedOrder()
	local fmt = string.format or format
	for i = 1, #order do
		_G["BINDING_NAME_" .. order[i]] = fmt("Action Button %d", 12 + i)
	end
end

local function ShouldSuppressMultibarCategory(cat)
	if not cat then
		return false
	end
	if cat == "BINDING_HEADER_MULTIACTIONBAR" then
		return true
	end
	local n = cat:match("^BINDING_HEADER_ACTIONBAR(%d+)$")
	if n then
		local i = tonumber(n)
		return i and i >= 2 and i <= 8
	end
	return false
end

local function ReorderPrimaryActionBarBindings(bindingsCategories)
	if type(bindingsCategories) ~= "table" then
		return bindingsCategories
	end
	local order = BorrowedOrder()
	local orderIndex = {}
	for i = 1, #order do
		orderIndex[order[i]] = i
	end
	local extracted = {}
	local rest = {}
	for _, entry in ipairs(bindingsCategories) do
		local take = false
		if type(entry) == "table" and entry[2] and orderIndex[entry[2]] then
			extracted[orderIndex[entry[2]]] = entry
			take = true
		end
		if not take then
			rest[#rest + 1] = entry
		end
	end
	local insertAfter
	for i, entry in ipairs(rest) do
		if type(entry) == "table" and entry[2] == "ACTIONBUTTON12" then
			insertAfter = i
			break
		end
	end
	if not insertAfter then
		for i, entry in ipairs(rest) do
			if type(entry) == "table" and entry[2] and type(entry[2]) == "string" then
				if entry[2]:match("^ACTIONBUTTON(%d+)$") then
					insertAfter = i
				end
			end
		end
	end
	if not insertAfter then
		insertAfter = 0
	end
	local out = {}
	for i = 1, insertAfter do
		out[#out + 1] = rest[i]
	end
	for i = 1, #order do
		if extracted[i] then
			out[#out + 1] = extracted[i]
		end
	end
	for i = insertAfter + 1, #rest do
		out[#out + 1] = rest[i]
	end
	return out
end

local function FluxGetBinding(bindingIndex)
	local action, cat, binding1, binding2 = origGetBinding(bindingIndex)
	if Mode() ~= "classic_style" or IsPlunderstorm() then
		return action, cat, binding1, binding2
	end
	if not action then
		return action, cat, binding1, binding2
	end
	if BorrowedSet()[action] then
		return action, "BINDING_HEADER_ACTIONBAR", binding1, binding2
	end
	if cat == "BINDING_HEADER_ACTIONBAR" and SUPPRESSED_PRIMARY_ACTIONBAR_ACTIONS[action] then
		return action, SUPPRESSED_CATEGORY, binding1, binding2
	end
	if ShouldSuppressMultibarCategory(cat) then
		return action, SUPPRESSED_CATEGORY, binding1, binding2
	end
	return action, cat, binding1, binding2
end

local function FluxCreateKeybindingSectionInitializer(name, bindingsCategories, requiredSettingName, expanded)
	if Mode() == "classic_style" and not IsPlunderstorm() then
		if name == SUPPRESSED_CATEGORY then
			local init = origCreateKeybindingSectionInitializer(name, bindingsCategories, requiredSettingName, expanded)
			init:AddShownPredicate(function()
				return false
			end)
			return init
		end
		local ab = _G.BINDING_HEADER_ACTIONBAR
		if ab and name == ab and type(bindingsCategories) == "table" then
			bindingsCategories = ReorderPrimaryActionBarBindings(bindingsCategories)
		end
	end
	return origCreateKeybindingSectionInitializer(name, bindingsCategories, requiredSettingName, expanded)
end

local function InstallBindingUiHooks()
	if bindingUiHooksInstalled or Mode() ~= "classic_style" then
		return
	end
	if type(GetBinding) ~= "function" or type(CreateKeybindingSectionInitializer) ~= "function" then
		return
	end
	if not origGetBinding then
		origGetBinding = GetBinding
		GetBinding = FluxGetBinding
	end
	if not origCreateKeybindingSectionInitializer then
		origCreateKeybindingSectionInitializer = CreateKeybindingSectionInitializer
		CreateKeybindingSectionInitializer = FluxCreateKeybindingSectionInitializer
	end
	bindingUiHooksInstalled = true
end

local function AddBindingCategoriesClassicStyleFlux(AddBindingCategory)
	AddBindingCategory(BINDING_HEADER_MOVEMENT)
	AddBindingCategory(BINDING_HEADER_INTERFACE)
	AddBindingCategory(BINDING_HEADER_ACTIONBAR)
	AddBindingCategory(BINDING_HEADER_CHAT)
	AddBindingCategory(BINDING_HEADER_TARGETING)
	AddBindingCategory(BINDING_HEADER_RAID_TARGET)
	AddBindingCategory(BINDING_HEADER_VEHICLE)
	AddBindingCategory(BINDING_HEADER_CAMERA)
	AddBindingCategory(BINDING_HEADER_MISC)
	AddBindingCategory(BINDING_HEADER_OTHER)
end

local function InstallKeybindingsHook()
	if hookedKeybinds then
		return
	end
	if not (Cap and Cap.HasBlizzardSettingsKeybindings and Cap.HasBlizzardSettingsKeybindings()) then
		return
	end
	if Mode() ~= "classic_style" then
		return
	end
	origAddBindingCategories = KeybindingsOverrides.AddBindingCategories
	KeybindingsOverrides.AddBindingCategories = function(AddBindingCategory)
		if IsPlunderstorm() then
			return origAddBindingCategories(AddBindingCategory)
		end
		AddBindingCategoriesClassicStyleFlux(AddBindingCategory)
	end
	hookedKeybinds = true
end

local function InstallActionBarVisibilityHook()
	if hookedVisibility then
		return
	end
	if not (Cap and Cap.HasBlizzardActionBarsOverrides and Cap.HasBlizzardActionBarsOverrides()) then
		return
	end
	if Mode() ~= "classic_style" then
		return
	end
	origCreateActionBarVisibilitySettings = ActionBarsOverrides.CreateActionBarVisibilitySettings
	ActionBarsOverrides.CreateActionBarVisibilitySettings = function(...)
		-- Intentionally empty: hide PROXY_SHOW_ACTIONBAR_2+ checkboxes.
	end
	hookedVisibility = true
end

local function FluxDiscordIsUserOAuthed()
	return false
end

local function FluxDiscordGetGuildLinkStatus()
	return false, nil, nil
end

local function FluxDiscordNoop()
end

local DISCORD_PROTECTED_STUBS = {
	IsUserOAuthed = FluxDiscordIsUserOAuthed,
	GetGuildLinkStatus = FluxDiscordGetGuildLinkStatus,
	UpdateDiscordServers = FluxDiscordNoop,
	UpdateGuildLobby = FluxDiscordNoop,
}

local function InstallDiscordAuthStub()
	local discord = rawget(_G, "C_Discord")
	if type(discord) ~= "table" then
		return
	end
	-- Protected while Settings or Guild Control setup is tainted.
	for name, stub in pairs(DISCORD_PROTECTED_STUBS) do
		if type(discord[name]) == "function" and discord[name] ~= stub then
			pcall(rawset, discord, name, stub)
		end
	end
end

-- Do not write into Blizzard Settings initializers (data.tooltip,
-- modifyPredicates). A tainted row field makes its dropdown build the menu
-- generator tainted, and opening it runs the nameplate preview aura Layout tainted.
local function SanitizeDiscordAuthButtons()
	InstallDiscordAuthStub()
end

local function InstallAdjustActionBarSettingsHook()
	if hookedAdjustActionBarSettings then
		return
	end
	if not (Cap and Cap.HasBlizzardActionBarsOverrides and Cap.HasBlizzardActionBarsOverrides()) then
		return
	end
	if Mode() ~= "classic_style" then
		return
	end
	if type(ActionBarsOverrides.AdjustActionBarSettings) ~= "function" then
		return
	end
	origAdjustActionBarSettings = ActionBarsOverrides.AdjustActionBarSettings
	ActionBarsOverrides.AdjustActionBarSettings = function(category, layout)
		if IsPlunderstorm() then
			return origAdjustActionBarSettings(category, layout)
		end
		return
	end
	hookedAdjustActionBarSettings = true
end

local function InstallHooks()
	Options.SetupBindingDisplayNames()
	SanitizeDiscordAuthButtons()
	if SkipSettingsReplace() then
		return
	end
	if Mode() ~= "classic_style" then
		return
	end
	InstallBindingUiHooks()
	InstallKeybindingsHook()
	InstallActionBarVisibilityHook()
	InstallAdjustActionBarSettingsHook()
end

local function ForceExtraActionBarsOff()
	if IsPlunderstorm() then
		return
	end
	if Flux.Combat and Flux.Combat.InLockdown and Flux.Combat.InLockdown() then
		Flux.Combat.Defer("bars.blizzardoptions.toggles", ForceExtraActionBarsOff)
		return
	end
	if type(GetActionBarToggles) ~= "function" or type(SetActionBarToggles) ~= "function" then
		return
	end
	-- Toggles only. MultiActionBar_Update from here SetShowns every multi-bar as
	-- Flux, and Edit Mode's SetupActionBar reads that bar state before TargetUnit.
	-- Blizzard applies the toggles itself; Bars/Blizzard.lua alpha-hides leftovers.
	local t = { GetActionBarToggles() }
	for i = 1, #t do
		t[i] = false
	end
	if #t > 0 then
		SetActionBarToggles(unpack(t))
	end
end

Options.ForceExtraActionBarsOff = ForceExtraActionBarsOff
Options.InstallHooks = InstallHooks

local Ev = Flux.Events
if Ev and Ev.Register then
	if not SkipSettingsReplace() then
		Ev.Register("ADDON_LOADED", function(_, loaded)
			if loaded ~= "Blizzard_SettingsDefinitions_Frame" and loaded ~= addonName then
				return
			end
			InstallHooks()
		end)
	end
	Ev.Register("PLAYER_LOGIN", function()
		SanitizeDiscordAuthButtons()
	end)
	Ev.Register("PLAYER_ENTERING_WORLD", function()
		ForceExtraActionBarsOff()
	end)
end

Flux.AfterLogin(function()
	InstallHooks()
	After0(InstallHooks)
	After0(ForceExtraActionBarsOff)
end)

InstallHooks()
