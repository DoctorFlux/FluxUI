-- MicroMenu/_tmp_micromenusmoke.lua — pos2 stays on UIParent, never follows ChatFrame1 off-screen.
-- lua MicroMenu/_tmp_micromenusmoke.lua   (from the _FluxUI addon root)
local here = arg and arg[0]
local dir = "."
if type(here) == "string" then
	dir = here:gsub("[/\\][^/\\]+$", "")
	if dir == here then
		dir = "."
	end
end

local function read(rel)
	local f = io.open(dir .. "/" .. rel, "r")
	if not f then
		return ""
	end
	local s = f:read("*a")
	f:close()
	return s
end

local failures = {}
local function has(hay, needle, label)
	if not hay:find(needle, 1, true) then
		failures[#failures + 1] = label
	end
end
local function hasNot(hay, needle, label)
	if hay:find(needle, 1, true) then
		failures[#failures + 1] = label
	end
end

local micro = read("FluxMicroMenu.lua")
if micro == "" then
	io.stderr:write("read FluxMicroMenu.lua failed\n")
	os.exit(1)
end
local chat = read("../Other/FluxChatFrame.lua")
if chat == "" then
	io.stderr:write("read FluxChatFrame.lua failed\n")
	os.exit(1)
end

has(micro, "local function ClampBesideChatColumn", "ClampBesideChatColumn exists")
has(micro, "local function FrameEdgeInUIParent", "scale-correct edge helper")
has(micro, "local function ScheduleBesideChatStayOnScreen", "pos2 stay scheduler")
has(micro, "FluxMicroMenuPos2SizeHooked", "pos2 reclamps on UIParent size")
has(micro, 'SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT"', "pos2 pins to UIParent")
has(micro, "FluxOptions:GetMicroMenuLayoutPosition() ~= 2", "stay scheduler is pos2-only")
has(micro, "function _G.FluxMicroMenu_GetBesideChatColumnRightX", "column-right export for chat/status")
has(micro, "_besideChatColumnRightX", "pos2 stores column right edge")

local besideStart = micro:find("local function UpdateLayoutBesideChat", 1, true)
local besideEnd = micro:find("\nlocal function UpdateLayoutMinimapStrip", 1, true)
if not besideStart or not besideEnd or besideEnd <= besideStart then
	failures[#failures + 1] = "UpdateLayoutBesideChat block"
else
	local beside = micro:sub(besideStart, besideEnd)
	has(beside, 'SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT"', "beside-chat UIParent BOTTOMLEFT")
	hasNot(beside, 'SetPoint("TOPRIGHT", chatFrame', "pos2 must not SetPoint to ChatFrame1")
	hasNot(beside, "tab:GetTop() or 0) - (chatFrame:GetTop()", "pos2 must not use mixed GetTop dy")
	has(beside, "ClampBesideChatColumn", "beside-chat clamps to screen")
	has(beside, "FluxChatFrame_GetPrimaryColumnTopY", "pos2 uses computed column top")
	has(beside, "_besideChatColumnRightX", "beside-chat stores column right after clamp")
	local setPointAt = beside:find('SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT"', 1, true)
	local applyAt = beside:find("FluxChatFrame_ApplyPrimaryPosition", 1, true)
	if not setPointAt or not applyAt or applyAt < setPointAt then
		failures[#failures + 1] = "pos2 must apply chat after micromenu SetPoint"
	end
end

local borderAt = chat:find("local function GetBorderTop", 1, true)
local insetAt = chat:find("function _G.FluxChatFrame_GetPrimaryBottomInsetY", 1, true)
if not borderAt or not insetAt or borderAt > insetAt then
	failures[#failures + 1] = "GetBorderTop must be declared before GetPrimaryBottomInsetY"
end
has(chat, "function _G.FluxChatFrame_GetPrimaryColumnTopY", "computed column top export")
has(chat, "FluxStatusBar_GetLocation2MinBottomOffset", "chat floor includes status pos2 lift")
has(chat, "local yBottom = GetChatFloorAboveActionStrip()", "pos1/3 chat sits above the action strip")
has(chat, "local function GetChatFloorAboveActionStrip", "pos1/3 share pos2 strip floor")
has(chat, "local function GetActionStripTopY", "pos1/3 floor uses action-strip top")
has(chat, "local function EstimateBesideChatColumnWidth", "pos2 X from micro options not live GetWidth")
has(chat, "local function GetStripClearanceTop", "chat Y uses strip clearance not border GetTop=0")
has(chat, "ignoreFramePositionManager", "chat ignores UIParent action-bar parking")
has(chat, "C_Timer.NewTicker(1, RepinChatIfDrifted)", "chat puts itself back if UIParent parks it")
hasNot(chat, 'hooksecurefunc("UIParent_ManageFramePositions"', "chat must not hook UIParent_ManageFramePositions (Classic Edit Mode open/close call it)")
hasNot(chat, "chBtn.ClearAllPoints = function", "chat must not replace ChatFrameChannelButton.ClearAllPoints")
has(chat, "local lastChatPin = nil", "chat caches last Flux layout for combat")
has(chat, "PLAYER_REGEN_DISABLED", "chat re-pins when combat starts")
has(chat, "keep the last OOC layout", "combat does not recompute chat from extras")
if chat:find("consider(ShownFrameTop(_G.FluxCombatManager", 1, true) then
	failures[#failures + 1] = "chat floor must not lift for combat extras"
end
has(chat, "return 2", "missing options defaults to micromenu pos2")
has(chat, "BESIDE_CHAT_COLUMN_LEFT_INSET + width + MICROMENU_CHAT_GAP", "pos2 X is inset+column+gap")
has(chat, "local function GetPos2ChatVertical", "pos2 chat height matches micromenu column")
has(chat, "mmH - tabH - editH", "pos2 log leaves room for tab row and edit box")
has(chat, "return mmBottom + editH, h", "pos2 log sits above the edit box")
hasNot(chat, "local function LengthInUIParent", "chat floor does not rescale GetTop")

local status = read("../StatusBars/FluxStatusBar.lua")
if status == "" then
	failures[#failures + 1] = "read FluxStatusBar.lua failed"
else
	has(status, "FluxMicroMenu_GetBesideChatColumnRightX", "status loc2 inset uses column right")
end

local constStart = micro:find("local BESIDE_CHAT_LEFT_INSET", 1, true)
local clampEnd = micro:find("\nlocal function EnsureMicroMenuScrollParts", 1, true)
if not constStart or not clampEnd then
	failures[#failures + 1] = "clamp helpers extractable"
else
	local chunk = micro:sub(constStart, clampEnd - 1)
	local env = { math = math, type = type, pcall = pcall }
	local loader = loadstring or load
	local fn, err
	if setfenv then
		fn, err = loadstring(chunk .. "\nreturn ClampBesideChatColumn", "ClampBesideChatColumn")
		if fn then
			setfenv(fn, env)
		end
	else
		fn, err = load(chunk .. "\nreturn ClampBesideChatColumn", "ClampBesideChatColumn", "t", env)
	end
	if not fn then
		failures[#failures + 1] = "load ClampBesideChatColumn: " .. tostring(err)
	else
		local ok, clamp = pcall(fn)
		if not ok or type(clamp) ~= "function" then
			failures[#failures + 1] = "ClampBesideChatColumn callable"
		else
			local function eq(a, b, label)
				if math.abs(a - b) > 0.01 then
					failures[#failures + 1] = label .. " got " .. tostring(a)
				end
			end
			local x, y, w, h = clamp(2, 80, 64, 200, 1920, 1080)
			eq(x, 2, "on-screen x")
			eq(y, 80, "on-screen y")
			eq(w, 64, "on-screen w")
			eq(h, 200, "on-screen h")

			x, y, w, h = clamp(-400, -50, 64, 200, 1920, 1080)
			eq(x, 0, "negative x clamped")
			eq(y, 0, "negative y clamped")

			x, y, w, h = clamp(2, 80, 64, 5000, 1920, 1080)
			if h > 1080 then
				failures[#failures + 1] = "tall column must clamp to UIParent height"
			end
			if y + h > 1080 + 0.01 then
				failures[#failures + 1] = "clamped column must fit vertically"
			end

			x, y, w, h = clamp(3000, 80, 80, 200, 800, 600)
			if x + w > 800 + 0.01 then
				failures[#failures + 1] = "right edge must stay on screen"
			end
		end
	end
end

local ui = read("../Core/FluxAPI/UI.lua")
if ui == "" then
	failures[#failures + 1] = "read Core/FluxAPI/UI.lua failed"
else
	has(ui, "local function FluxClientIsForever()", "Forever micromenu helper")
	has(ui, "local function FluxClientHasLFDMicroFeature()", "Forever LFD micro uses a client-specific probe")
	has(ui, "PlayerSpellsMicroButton = function()", "PlayerSpells gated as optional feature")
	has(ui, "function FluxClientUsesSplitTalentSpellbookMicros()", "PlayerSpells hidden only when split talent/spellbook buttons exist")
	has(ui, "if FluxClientUsesSplitTalentSpellbookMicros() then return false end", "live keeps PlayerSpellsMicroButton")
	has(ui, "HousingMicroButton = function()", "Housing gated as optional feature")
	has(ui, "if FluxClientIsForever() then return false end", "Forever hides live leftover micromenu frames")
	has(ui, "return ToggleGroupFinderFrame ~= nil or LFGVanilla_ToggleFrame ~= nil", "Forever LFD micro does not require LFDParentFrame")
	has(ui, "return LFDParentFrame ~= nil", "live/classic LFD micro still requires LFDParentFrame")
	has(ui, "LFDMicroButton = FluxClientHasLFDMicroFeature", "LFDMicroButton feature is the Forever-aware probe")
end

has(micro, '"LegacyMicroButton"', "LegacyMicroButton in default unified order")
has(micro, '"PlayerSpellsMicroButton"', "PlayerSpells listed so live still discovers it")
has(micro, '"HousingMicroButton"', "Housing parked when feature gate is false")
has(micro, "ParkLeftoverMicroMenuLayoutChildren", "parks leftover MicroMenu layoutIndex children")
hasNot(micro, 'hooksecurefunc(em, "InitSystemAnchors"', "must not post-hook InitSystemAnchors (runs before ResetTargetAndFocus)")
has(micro, "FluxAfterEditMode(ParkLeftoverMicroMenuLayoutChildren)", "parks MicroMenu leftovers after Edit Mode closes")
has(micro, '"EditMode.Exit"', "MicroMenu park is driven by EditMode.Exit")
has(micro, "HelpOpenWebTicketButton", "parks HelpOpenWebTicketButton off MicroMenu")
hasNot(micro, "MicroMenuContainer:EnableMouse", "must not EnableMouse MicroMenuContainer")
hasNot(micro, "_fluxMicroMenuSanitizeHooked", "must not write EditModeManagerFrame flags")
hasNot(micro, "MicroMenu.GetEdgeButton =", "must not assign MicroMenu.GetEdgeButton")
hasNot(micro, "function MicroMenu:GetEdgeButton", "must not replace MicroMenu:GetEdgeButton")

local cfg = read("FluxMicroMenuConfig.lua")
if cfg == "" then
	failures[#failures + 1] = "read FluxMicroMenuConfig.lua failed"
else
	has(cfg, "local UNIFIED_ORDER_LAYOUT_VERSION = 9", "unified order layout version 9")
	has(cfg, "function C:InsertDefaultRowAtCanonicalPosition", "new canonical natives insert at default slot")
end

local m2m = read("FluxMinimapToMicro.lua")
if m2m == "" then
	failures[#failures + 1] = "read FluxMinimapToMicro.lua failed"
else
	has(m2m, "collectedButtons", "MinimapToMicro scans Addon (+) collectedButtons")
	has(m2m, "GetMinimapScanRoots", "MinimapToMicro uses extra minimap scan roots")
	has(m2m, "HarvestNamedMinimapButtons", "Forever named harvest is rare, not per scan")
	has(m2m, "_harvestedNames", "harvest cache reused on cheap scans")
	has(m2m, "C_Timer.After(2", "delayed Forever harvest at 2s")
	has(m2m, "LibMapButton-1.1", "MinimapToMicro scans LibMapButton")
	has(m2m, 't ~= "table" and t ~= "userdata"', "MinimapToMicro accepts userdata frames")
	has(m2m, "local function SafeGetRegions", "GetButtonIcon does not assume GetRegions")
	hasNot(m2m, 'RegisterEvent("ADDON_LOADED")', "no per-addon rebuild")
end

local addonBtn = read("FluxAddonMicroButton.lua")
if addonBtn == "" then
	failures[#failures + 1] = "read FluxAddonMicroButton.lua failed"
else
	has(addonBtn, "function FluxAddonSystem.GetMinimapScanRoots()", "Addon (+) exposes minimap scan roots")
	has(addonBtn, "MinimapBackdrop", "scan roots include MinimapBackdrop")
	hasNot(addonBtn, "for name, obj in pairs(_G) do", "Addon (+) scan does not walk _G")
end

local lfgBtn = read("FluxLFGMicroButton.lua")
if lfgBtn == "" then
	failures[#failures + 1] = "read FluxLFGMicroButton.lua failed"
else
	has(lfgBtn, 'local VANILLA_LFG_ADDON = "Blizzard_GroupFinder_VanillaStyle"', "Forever loads Vanilla Group Finder")
	has(lfgBtn, "local function ToggleForeverGroupFinder()", "Forever micromenu toggles Vanilla LFG")
	has(lfgBtn, "LFGVanilla_ShowFrame", "Forever opens LFGParentFrame via LFGVanilla_ShowFrame")
	has(lfgBtn, "local function WireForeverLFDMicroButton()", "Forever wires LFDMicroButton click")
	has(lfgBtn, "if IsForeverClient() then", "Forever LFG path does not run on other clients")
	has(lfgBtn, "Load only when the player clicks the LFG button", "Forever does not load Who list at login")
	if lfgBtn:find("mixin.SetupMenu", 1, true) or lfgBtn:find("DropdownButtonMixin.SetupMenu", 1, true) then
		failures[#failures + 1] = "Flux must not assign DropdownButtonMixin.SetupMenu"
	end
	hasNot(lfgBtn, "LoadForeverVanillaLFG()\n        WireForeverLFDMicroButton()", "login event must not load Vanilla Group Finder")
	do
		local foreverAt = lfgBtn:find("if IsForeverClient() then", 1, true)
		local foreverEnd = foreverAt and lfgBtn:find("\n    return\nend", foreverAt, true)
		local foreverBlock = foreverAt and lfgBtn:sub(foreverAt, foreverEnd or #lfgBtn) or ""
		if foreverBlock == "" or foreverBlock:find("LoadForeverVanillaLFG()", 1, true) then
			failures[#failures + 1] = "Forever gamepad must not load Vanilla Group Finder from Flux (Blizzard loads it on entering the world)"
		end
	end
	local wireAt = lfgBtn:find("local function WireForeverLFDMicroButton()", 1, true)
	local wireGate = wireAt and lfgBtn:find("if ForeverGamepadUI() then", wireAt, true)
	local setClick = wireAt and lfgBtn:find('btn:SetScript("OnClick"', wireAt, true)
	if not wireGate or not setClick or wireGate > setClick then
		failures[#failures + 1] = "Forever gamepad must not replace LFDMicroButton OnClick"
	end
	local wrapAt = lfgBtn:find("local function WrapForeverToggleGroupFinderFrame()", 1, true)
	local wrapGate = wrapAt and lfgBtn:find("if ForeverGamepadUI() then", wrapAt, true)
	local replaceAt = wrapAt and lfgBtn:find("_G.ToggleGroupFinderFrame = function", wrapAt, true)
	if not wrapGate or not replaceAt or wrapGate > replaceAt then
		failures[#failures + 1] = "Forever gamepad must not replace ToggleGroupFinderFrame"
	end
end

local macroBtn = read("FluxMacroMicroButton.lua")
if macroBtn == "" then
	failures[#failures + 1] = "read FluxMacroMicroButton.lua failed"
else
	local clickAt = macroBtn:find("OnClick = function(self)", 1, true)
	local gateAt = clickAt and macroBtn:find("if ForeverGamepadUI() then", clickAt, true)
	local slashAt = clickAt and macroBtn:find('SlashCmdList["MACRO"]', clickAt, true)
	if not gateAt or not slashAt or gateAt > slashAt then
		failures[#failures + 1] = "Forever gamepad macro button must not call SlashCmdList MACRO"
	end
	has(macroBtn, 'macrotext = "/macro"', "Forever gamepad macro button opens via secure /macro")
end

-- Forever gamepad UI: Blizzard's bag and Character panel run gamepad binding code
-- that ends in the protected SetPreferredGamepadInteractTarget().
local bagHeader = read("FluxCombinedBagHeader.lua")
if bagHeader == "" then
	failures[#failures + 1] = "read FluxCombinedBagHeader.lua failed"
else
	hasNot(bagHeader, "_G.CloseBag =", "bag header must not replace CloseBag (taints CloseAllBags / ESC)")
	hasNot(bagHeader, "FluxCombinedReopenHooked", "CloseBag override flag is gone")
	has(bagHeader, 'hooksecurefunc(settings, "OnBagClosed"', "unequip reopen is a post-hook on OnBagClosed")
	has(bagHeader, "if not RetailHeaderClient() or Off() then", "bag header skips Forever gamepad UI at load")
	has(bagHeader, "return UsesAltBag() or ForeverGamepadUI()", "bag header gate covers Forever gamepad UI")
	hasNot(bagHeader, '"InitializeGamepad"', "bag header must not hook the gamepad bag init")
end

local bagButton = read("FluxBagMicroButton.lua")
if bagButton == "" then
	failures[#failures + 1] = "read FluxBagMicroButton.lua failed"
else
	local toggleAt = bagButton:find("local function ToggleOpenBags()", 1, true)
	local gateAt = toggleAt and bagButton:find("if ForeverGamepadUI() then", toggleAt, true)
	local openAt = toggleAt and bagButton:find("ToggleAllBags()", toggleAt, true)
	if not gateAt or not openAt or gateAt > openAt then
		failures[#failures + 1] = "Flux bag button must not open Forever's gamepad bag from addon code"
	end
	has(bagButton, "SecureClickProxy.Attach(btn", "Forever bag button opens the gamepad bag by secure click")
	local hideAt = bagButton:find("local function HideBlizzardBags()", 1, true)
	local bagGate = hideAt and bagButton:find("FluxUI_IsForeverGamepadUI", hideAt, true)
	local hookAt = hideAt and bagButton:find('hooksecurefunc(bar, "Layout"', hideAt, true)
	if not bagGate or not hookAt or bagGate > hookAt then
		failures[#failures + 1] = "Forever gamepad must not hook BagsBar:Layout (VARIABLES_LOADED SetPreferredGamepadInteractTarget)"
	end
end

local chatMicros = read("../Other/FluxChatColumnMicros.lua")
if chatMicros == "" then
	failures[#failures + 1] = "read FluxChatColumnMicros.lua failed"
else
	local guardAt = chatMicros:find("local function InstallCharacterShowGuard()", 1, true)
	local earlyAt = guardAt and chatMicros:find("if IsCamelotClient() then", guardAt, true)
	local bindAt = guardAt and chatMicros:find('BindCharacterHandler(frame, "OnShow"', guardAt, true)
	if not earlyAt or not bindAt or earlyAt > bindAt then
		failures[#failures + 1] = "Character guard must return before touching CharacterFrame on Forever"
	end
	has(chatMicros, "proxy.Attach(btn, {", "chat bag button opens Forever's gamepad bag by secure click")
	local bagAt = chatMicros:find("local function CreateBagButton", 1, true)
	local clickGateAt = bagAt and chatMicros:find("if ForeverGamepadUI() then", bagAt, true)
	local clickAt = bagAt and chatMicros:find("src:Click(button)", bagAt, true)
	if not clickGateAt or not clickAt or clickGateAt > clickAt then
		failures[#failures + 1] = "chat bag button must not open Forever's gamepad bag from addon code"
	end
	local watchAt = chatMicros:find("local function WatchCharacterFrame", 1, true)
	local watchGateAt = watchAt and chatMicros:find("if IsCamelotClient() then", watchAt, true)
	local watchHookAt = watchAt and chatMicros:find('frame:HookScript("OnShow"', watchAt, true)
	if not watchGateAt or not watchHookAt or watchGateAt > watchHookAt then
		failures[#failures + 1] = "Forever must not HookScript CharacterFrame from the chat character button"
	end
end

do
	local portraitAt = micro:find('hooksecurefunc("SetPortraitTexture"', 1, true)
	local camelotAt = micro:find("local camelotPortrait = ", 1, true)
	if not camelotAt or not portraitAt or camelotAt > portraitAt then
		failures[#failures + 1] = "Forever must not hook SetPortraitTexture (taints CharacterFrame secret health)"
	end
	local glowAt = micro:find("btn._fluxPortraitGlowHooked = true", 1, true)
	local postAt = glowAt and micro:find('hooksecurefunc(btn, "OnEnter", ShowCharacterPortraitGlow)', glowAt, true)
	local scriptAt = glowAt and micro:find('btn:HookScript("OnEnter"', glowAt, true)
	if not postAt or not scriptAt or postAt > scriptAt then
		failures[#failures + 1] = "character portrait glow must post-hook OnEnter before any HookScript"
	end
	local camelotAt = glowAt and micro:find("not camelot and not protected", glowAt, true)
	if not camelotAt or not scriptAt or camelotAt > scriptAt then
		failures[#failures + 1] = "Forever must not HookScript CharacterMicroButton for the portrait glow"
	end
end

if #failures > 0 then
	io.stderr:write("micromenu pos2 smoke FAILED (" .. tostring(#failures) .. ")\n")
	for i = 1, #failures do
		io.stderr:write("  " .. failures[i] .. "\n")
	end
	os.exit(1)
end
print("micromenu pos2 smoke OK")
