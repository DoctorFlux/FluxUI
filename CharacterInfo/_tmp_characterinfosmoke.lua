-- CharacterInfo/_tmp_characterinfosmoke.lua — overlay contracts. No WoW required.
-- lua CharacterInfo/_tmp_characterinfosmoke.lua   (from the _FluxUI addon root)
local here = arg and arg[0]
local dir = "."
if type(here) == "string" then
	dir = here:gsub("[/\\][^/\\]+$", "")
	if dir == here then
		dir = "."
	end
end

local failures = {}

local function read(name)
	local f = io.open(dir .. "/" .. name, "r")
	if not f then
		f = io.open(dir .. "/../" .. name, "r")
	end
	if not f then
		return ""
	end
	local s = f:read("*a")
	f:close()
	return s
end

local function has(hay, needle, label)
	if hay == "" then
		failures[#failures + 1] = label .. " (file missing)"
		return
	end
	if not hay:find(needle, 1, true) then
		failures[#failures + 1] = label
	end
end

local shared = read("Shared.lua")
has(shared, "module.isClassicEra = Client and Client.isEra == true", "era flag from Flux.Client")
has(shared, "Client.isAnniversary or Client.isTBC or Client.isWrath", "anniversary/TBC/Wrath is progression CSC")
has(shared, "Client.isRetail or Client.isCamelot", "Forever is retail-mode (no CSC dropdown)")
has(shared, "module.useCscPanel = module.isClassicEra or module.isProgression", "CSC dropdown only Era/Progression")
has(shared, "module.useRetailPaneHooks = not module.useCscPanel", "Live/Forever/Cata use pane hooks")
if shared:find("CharacterStatsPaneScrollBox", 1, true) then
	failures[#failures + 1] = "Shared must not infer Forever from CharacterStatsPaneScrollBox"
end
if shared:find("module.isClassicEra = module.majorVersion == 1", 1, true) then
	failures[#failures + 1] = "Shared must not treat majorVersion 1 as Era"
end

local era = read("StatsEra.lua")
has(era, "if not CharacterFrame or not CharacterAttributesFrame then", "Era CSC needs attributes frame")
has(era, "function module.InstallClassicStatsPanel()", "Era exports frame-presence installer")
has(era, "module.IsCharacterUiAddon", "Era retries when character UI addon loads")

local prog = read("StatsProgression.lua")
has(prog, "if not (module and module.isProgression) then return end", "Progression CSC does not load on Live/Forever")
has(prog, "function module.InstallClassicStatsPanel()", "Progression exports installer")
has(prog, "if module.isRetail or not module.useCscPanel then", "Progression skips CSC panel on mainline")

local retail = read("RetailPane.lua")
has(retail, "if not (module and module.useRetailPaneHooks) then", "RetailPane skipped on Era/Anniversary CSC clients")
has(retail, "CharacterStatsPaneScrollBox", "Forever ScrollBox is hooked")
has(retail, "CharacterStatsPanePetScrollBox", "Forever pet stats are not pinned")
has(retail, "CharacterStatFrameScrollBoxBaseElementMixin", "Forever pin hooks ScrollBox row Init")
has(retail, 'HEALTH = "health"', "Forever PAPERDOLL_STATINFO names map to Info Frame keys")
has(retail, 'MAINHAND_DAMAGE = "weaponDamage"', "Forever weapon damage maps to Info Frame")
has(retail, 'MOVESPEED = "speed"', "Forever movement speed maps to Info Frame")
has(retail, "function module.InstallRetailPane()", "RetailPane exports installer")
do
	local fnAt = retail:find("function module.InstallRetailPane()", 1, true)
	local gateAt = fnAt and retail:find("if IsForeverCharacterPane() then", fnAt, true)
	local retAt = gateAt and retail:find("return true", gateAt, true)
	local hookAt = fnAt and retail:find("InstallUpdateStatsHook()", fnAt, true)
	if not gateAt or not retAt or not hookAt or gateAt > retAt or retAt > hookAt then
		failures[#failures + 1] = "Forever pane must return before UpdateStats hooks (secret health on open)"
	end
end
has(retail, 'SetFormattedText("%.1f"', "ilvl shown as one decimal")

local quality = read("PaperDollQuality.lua")
has(quality, "function module.InstallQuality()", "quality borders wait for slots")
has(quality, "useClassicPaperDollChrome", "quality borders Classic-only")
has(quality, "CharacterAmmoSlot", "quality borders include ammo when present")

local vis = read("PaperDollVisibility.lua")
has(vis, "function module.InstallVisibility()", "helm/cloak waits for paperdoll")
has(vis, "ShowHelm", "helm/cloak uses Display APIs")

local secondary = read("PaperDollSecondaryName.lua")
has(secondary, "function module.InstallSecondaryName()", "secondary name waits for character frame")
has(secondary, "UnitSurnameOwn", "secondary name uses Forever surname CVar")
has(secondary, "UsesRegionalUniqueNames", "secondary name gated on regional unique names")
has(secondary, "ShouldDisplaySurname", "secondary name reads ShouldDisplaySurname")
has(secondary, "RefreshSelfDisplayNames", "secondary name refreshes unit frames")
has(secondary, "PortraitContainer", "secondary name sits next to the class/spec portrait")
has(secondary, "TitleContainer", "secondary name fits in the Character Info title bar")
has(secondary, "IsRightPaneCollapsed", "secondary name reflows when the side pane is hidden")
has(secondary, "BOTTOMLEFT", "secondary name drops under the title instead of covering the name")
has(secondary, "checkbox.text = labelText", "secondary name shows a visible label next to the checkmark")
has(secondary, "CHECK_SIZE = 20", "secondary name checkmark fits the top panel")
if secondary:find("cf:SetTitleOffsets", 1, true) or secondary:find("SetTitleOffsets,", 1, true) then
	failures[#failures + 1] = "secondary name must not move Blizzard title offsets"
end
do
	local hookFn = secondary:find("local function HookCharacterFrame()", 1, true)
	local gateAt = hookFn and secondary:find("if IsCamelotClient() then", hookFn, true)
	local retAt = hookFn and secondary:find("return", gateAt or 1, true)
	local showAt = hookFn and secondary:find('cf:HookScript("OnShow"', hookFn, true)
	local titleAt = hookFn and secondary:find('hooksecurefunc(cf, "UpdateTitle"', hookFn, true)
	if not gateAt or not retAt or not showAt or not titleAt or gateAt > retAt or retAt > showAt or retAt > titleAt then
		failures[#failures + 1] = "Forever secondary name must return before CharacterFrame OnShow hooks"
	end
end

local ilvl = read("ItemLevel.lua")
has(ilvl, "function module.InstallItemLevel()", "wrist ilvl waits for paperdoll")
has(ilvl, "useClassicPaperDollChrome", "wrist ilvl/GS Classic-only")

local fly = read("PaperDollEquipFlyout.lua")
has(fly, "CharacterAmmoSlot", "flyout includes ammo slot")
has(fly, "CharacterRangedSlot", "flyout includes ranged slot")

local init = read("Init.lua")
has(init, 'Flux.Module.Register("CharacterInfo"', "module registration")
has(init, "module.InstallClassicStatsPanel", "Init installs CSC")
has(init, "module.InstallRetailPane", "Init installs pane hooks")
has(init, "module.InstallSecondaryName", "Init installs Forever secondary name")
has(init, "InstallCharacterInfoPinHooks", "Init retries Info Frame pins")
has(init, "IsCharacterUiAddon", "Init retries on character UI addon load")

local toc = read("../_FluxUI.toc")
if toc == "" then
	toc = read("_FluxUI.toc")
end
has(toc, "CharacterInfo\\Init.lua", "TOC loads CharacterInfo")
has(toc, "CharacterInfo\\PaperDollSecondaryName.lua", "TOC loads secondary name paperdoll")
if toc:find("Other\\FluxCharacterStats\\FluxCharacterStatsShared.lua", 1, true) then
	failures[#failures + 1] = "TOC still loads old FluxCharacterStats dump"
end

if #failures > 0 then
	io.stderr:write("character info smoke FAILED (" .. tostring(#failures) .. ")\n")
	for i = 1, #failures do
		io.stderr:write("  " .. failures[i] .. "\n")
	end
	os.exit(1)
end

print("character info smoke OK")
print("  Era/Anniversary: CSC dropdown on CharacterAttributesFrame")
print("  Live/Forever: no CSC; pane/ScrollBox hooks + Info Frame pins")
print("  Forever pet ScrollBox is not pinned")
