-- Core/_tmp_coresmoke.lua — kernel contracts. No WoW required.
-- lua Core/_tmp_coresmoke.lua   (from the _FluxUI addon root)
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
		return ""
	end
	local s = f:read("*a")
	f:close()
	return s
end

local function has(hay, needle, label)
	if not hay:find(needle, 1, true) then
		failures[#failures + 1] = label
	end
end

local function slice(src, startPat, endPat)
	local i = src:find(startPat, 1, true)
	if not i then
		return ""
	end
	local j = endPat and src:find(endPat, i + 10, true)
	return src:sub(i, (j or (#src + 1)) - 1)
end

local toc = read("../_FluxUI.toc")
if toc == "" then
	toc = read("../_FluxUI.toc")
end
-- coresmoke lives in Core/, toc is addon root
local tocPath = dir .. "/../_FluxUI.toc"
do
	local f = io.open(tocPath, "r")
	if f then
		toc = f:read("*a")
		f:close()
	end
end

has(toc, "Core\\Client_Camelot.lua [AllowLoadGameType camelot]", "Camelot client flag is game-type gated")
has(toc, "Core\\Engine\\Restricted.lua", "TOC loads Restricted")
do
	local camelot = toc:find("Core\\Client_Camelot.lua [AllowLoadGameType camelot]", 1, true)
	local client = toc:find("Core\\Client.lua", 1, true)
	if camelot and client and camelot > client then
		failures[#failures + 1] = "Client_Camelot.lua must load before Client.lua"
	end
	local caps = toc:find("Core\\Capabilities.lua", 1, true)
	local restricted = toc:find("Core\\Engine\\Restricted.lua", 1, true)
	if caps and restricted and restricted < caps then
		failures[#failures + 1] = "Restricted.lua must load after Capabilities.lua"
	end
	local chrome = toc:find("Core\\Engine\\SpellBookChrome.lua", 1, true)
	local mouseover = toc:find("Core\\Engine\\MouseoverCast.lua", 1, true)
	if chrome and mouseover and chrome > mouseover then
		failures[#failures + 1] = "SpellBookChrome.lua must load before MouseoverCast.lua"
	end
end
has(toc, "Core\\Engine\\Modifier.lua", "TOC loads Modifier")
has(toc, "Core\\Engine\\Context.lua", "TOC loads Context")
has(toc, "Core\\Engine\\Identity.lua", "TOC loads Identity")
has(toc, "Core\\Engine\\Scheduler.lua", "TOC loads Scheduler")
has(toc, "Core\\Engine\\FormStorm.lua", "TOC loads FormStorm")
has(toc, "Core\\Engine\\HopLag.lua", "TOC loads HopLag")
has(toc, "Core\\Engine\\SpellBookChrome.lua", "TOC loads SpellBookChrome")
has(toc, "Core\\Engine\\MouseoverCast.lua", "TOC loads MouseoverCast")
has(toc, "Inventory\\MountFlyable.lua", "TOC loads MountFlyable")
has(toc, "Core\\API\\Secrets_Midnight.lua [AllowLoadGameType mainline, camelot]", "Secrets Midnight loads on mainline and Forever")
has(toc, "Core\\API\\Threat.lua", "TOC loads Flux.Threat")
if toc:find("FluxBlizzardUnitFrameSecrets", 1, true) then
	failures[#failures + 1] = "Blizzard unit-frame secret patches must stay removed from the TOC"
end
has(toc, "Blizzard\\Hide.lua", "TOC loads the Blizzard hide helper")
do
	local caps = toc:find("Core\\Capabilities.lua", 1, true)
	local hide = toc:find("Blizzard\\Hide.lua", 1, true)
	if not caps or not hide or hide < caps then
		failures[#failures + 1] = "Blizzard/Hide.lua must load right after Core"
	end
	local write = toc:find("BlizzardSettings\\Write.lua", 1, true)
	local nameplates = toc:find("BlizzardSettings\\Nameplates.lua", 1, true)
	local raid = toc:find("BlizzardSettings\\Raid.lua", 1, true)
	local defaults = toc:find("\nFluxDefaultSettings.lua", 1, true)
	if not write or not nameplates or not raid or not defaults
		or not (write < nameplates and nameplates < raid and raid < defaults) then
		failures[#failures + 1] = "BlizzardSettings/Write, Nameplates, Raid must load before FluxDefaultSettings.lua"
	end
end
has(toc, "UnitFrames\\FluxUnitFrames_AurasOwn.lua", "own-debuff policy loads before aura painters")
has(toc, "UnitFrames\\FluxUnitFrames_AurasEngine.lua [AllowLoadGameType mainline, camelot]", "engine auras load on Forever")
do
	local ownI = toc:find("UnitFrames\\FluxUnitFrames_AurasOwn.lua", 1, true)
	local paintI = toc:find("UnitFrames\\FluxUnitFrames_Auras.lua", 1, true)
	if not ownI or not paintI or ownI > paintI then
		failures[#failures + 1] = "AurasOwn.lua must load before FluxUnitFrames_Auras.lua"
	end
end
do
	local tag = " [AllowLoadGameType vanilla, tbc, wrath, cata, mists, classic, camelot, mainline]"
	local last = 0
	for _, name in ipairs({ "Core", "Threat", "Level", "Countdown" }) do
		local line = "NamePlates\\" .. name .. ".lua" .. tag
		local at = toc:find(line, 1, true)
		if not at then
			failures[#failures + 1] = "TOC must load " .. line
		elseif at < last then
			failures[#failures + 1] = "NamePlates/Core.lua must load before the nameplate modules"
		else
			last = at
		end
	end
	if toc:find("Other\\FluxNamePlates.lua", 1, true) then
		failures[#failures + 1] = "Other/FluxNamePlates.lua must stay removed from the TOC"
	end
end
has(toc, "Core\\API\\Secrets_Classic.lua [AllowLoadGameType vanilla, tbc, wrath, cata, mists, classic]", "Secrets Classic is classic-gated")
if toc:find("LibActionButton", 1, true) and toc:find("Core\\Engine\\Modifier.lua", 1, true) then
	-- LAB may exist later in TOC for leftover libs; Core kernel block must not load it.
end
do
	local i = toc:find("Core\\Flux.lua", 1, true)
	local j = toc:find("Inventory\\Init.lua", 1, true)
	local kernel = (i and j and toc:sub(i, j - 1)) or toc:sub(1, 2500)
	if kernel:find("LibActionButton", 1, true) then
		failures[#failures + 1] = "Core TOC block must not load LibActionButton"
	end
	if kernel:find("FluxLABExtensions", 1, true) then
		failures[#failures + 1] = "Core TOC block must not load FluxLABExtensions"
	end
end

-- ---------------------------------------------------------------------------
-- Scheduler display tier
-- ---------------------------------------------------------------------------

local sched = read("Engine/Scheduler.lua")
has(sched, "display = 2", "display tier is 2")
has(sched, "eval = 3", "eval tier is 3 after display")
has(sched, '"layout", "display", "eval"', "flush order is layout then display then eval")
has(sched, "deferredDisplay", "display requested while paging is deferred")
has(sched, "deferredEval", "eval requested while paging is deferred, not dropped")
has(sched, 'RunBucket("display", display)', "flush runs display after layout")
has(sched, 'RunBucket("eval", eval)', "flush still runs eval")
do
	local body = slice(sched, "function Scheduler.Request", "function Scheduler.HasPending")
	if body:find("pending.eval = nil", 1, true) then
		failures[#failures + 1] = "a layout request must not throw away pending eval"
	end
	if body:find('Scheduler.Request("eval"', 1, true) then
		failures[#failures + 1] = "Request must not escalate display into eval"
	end
end
do
	local body = slice(sched, "function Scheduler.Flush", "function Scheduler.Stats")
	local d = body:find('RunBucket("display", display)', 1, true)
	local e = body:find('RunBucket("eval", eval)', 1, true)
	if not (d and e) or d > e then
		failures[#failures + 1] = "display bucket must run before eval"
	end
	local l = body:find('RunBucket("layout", layout)', 1, true)
	if not (l and d) or l > d then
		failures[#failures + 1] = "layout bucket must run before display"
	end
end

-- ---------------------------------------------------------------------------
-- Modifier bus
-- ---------------------------------------------------------------------------

local modifier = read("Engine/Modifier.lua")
has(modifier, "_G.FluxModifierTracker = Modifier", "Modifier aliases FluxModifierTracker")
has(modifier, "function Modifier.Register", "Modifier.Register")
has(modifier, "function Modifier.NotifyActiveChanged", "Modifier.NotifyActiveChanged")
has(modifier, "function Modifier.Unregister", "Modifier.Unregister")
has(modifier, "MODIFIER_STATE_CHANGED", "Modifier listens for modifier events")
has(modifier, "SetScript(\"OnUpdate\", nil)", "OnUpdate disarms when idle")
has(modifier, "function Modifier.SetTrace", "Modifier hop/mod debug trace")

-- ---------------------------------------------------------------------------
-- Context fingerprint bus (subscribe-only)
-- ---------------------------------------------------------------------------

local context = read("Engine/Context.lua")
has(context, "function Context.Subscribe", "Context.Subscribe")
has(context, "function Context.RequestMouseover", "Context.RequestMouseover")
has(context, "function Context.Fingerprint", "Context.Fingerprint")
has(context, "function Context.MouseoverReactionClass", "Context.MouseoverReactionClass")
has(context, "function Context.HasSubscribers", "Context.HasSubscribers")
has(context, "if not HasSubscribers() then", "Request is a no-op without subscribers")
has(context, 'Scheduler.Request("display"', "Context notifies on the display tier")
if context:find("RequestApply", 1, true) or context:find("RequestApplyAll", 1, true) then
	failures[#failures + 1] = "Context must not Binding Apply"
end
if context:find('Scheduler.Request("eval"', 1, true) then
	failures[#failures + 1] = "Context must not escalate into eval"
end
has(context, "AccessibleGUIDForUnit", "fingerprint uses accessible GUIDs only")
has(context, 'return 0.07', "world mouseover coalesce is 0.07s")
if context:find("ArmHopMoFlush", 1, true) then
	failures[#failures + 1] = "Context must not delay mouseover display (condition flips are instant)"
end
has(context, "local function DiffKinds", "Context notify is kinded")
has(context, "info.mods", "kinded notify reports modifier changes")
has(context, "opts.form", "FormStorm can force a display refresh")

-- ---------------------------------------------------------------------------
-- Identity shown-face publisher
-- ---------------------------------------------------------------------------

local identity = read("Engine/Identity.lua")
has(identity, "function Identity.Register", "Identity.Register")
has(identity, "function Identity.Publish", "Identity.Publish")
has(identity, "function Identity.Get", "Identity.Get")
has(identity, "function Identity.SoftSync", "Identity.SoftSync")
has(identity, "function Identity.OnChange", "Identity.OnChange")
has(identity, "function Identity.SlotKey", "Identity.SlotKey")
has(identity, "function Identity.BadgeKey", "Identity.BadgeKey")
has(identity, "lastSig", "Identity skips unchanged signatures")
if identity:find("RequestApply", 1, true) or identity:find("GetMacroSpell", 1, true) then
	failures[#failures + 1] = "Identity must not Binding Apply or use GetMacroSpell"
end

-- ---------------------------------------------------------------------------
-- Action occupancy
-- ---------------------------------------------------------------------------

local action = read("API/Action.lua")
has(action, "function Action.OccupancyKey", "Action.OccupancyKey")
do
	local body = slice(action, "function Action.OccupancyKey", "function Action.GetText")
	if body == "" then
		body = slice(action, "function Action.OccupancyKey", "function Action.HasAction")
	end
	has(body, "Action.GetInfo", "occupancy reads GetActionInfo via Action.GetInfo")
	if body:find("GetMacroSpell", 1, true) or body:find("GetMacroItem", 1, true) then
		failures[#failures + 1] = "OccupancyKey must not call GetMacroSpell / GetMacroItem"
	end
	has(body, "actionType", "occupancy is type+id")
end
has(action, "function Action.HasAction", "Action.HasAction")
has(action, 'Pick("HasAction"', "HasAction prefers C_ActionBar")

-- ---------------------------------------------------------------------------
-- FormStorm is the only form gate
-- ---------------------------------------------------------------------------

local storm = read("Engine/FormStorm.lua")
has(storm, "function FormStorm.IsBursting", "FormStorm.IsBursting")
has(storm, "function FormStorm.IsSettling", "FormStorm.IsSettling")
has(storm, "function FormStorm.GetSnapshot", "FormStorm.GetSnapshot")
has(storm, "function FormStorm.OnBurst", "FormStorm.OnBurst")
has(storm, "function FormStorm.OnSettled", "FormStorm.OnSettled")
has(storm, "formstorm.ignored", "unchanged form index / page costs nothing")
has(storm, "GetShapeshiftForm", "form edge is read")
has(storm, "GetBonusBarOffset", "bonus bar edge is read")
has(storm, "UPDATE_STEALTH", "stealth opens the same burst")
if storm:find("FluxButtonEvents.IsFormStormActive", 1, true) or storm:find("_G.FluxButtonEvents", 1, true) then
	failures[#failures + 1] = "FormStorm must not call FluxButtonEvents"
end

-- ---------------------------------------------------------------------------
-- MouseoverCast overlay models
-- ---------------------------------------------------------------------------

local mo = read("Engine/MouseoverCast.lua")
has(mo, "surface", "MouseoverCast documents surface overlay")
has(mo, "hidden", "MouseoverCast documents hidden overlay")
has(mo, "display", "MouseoverCast documents display overlay")
has(mo, "type=action", "plain slots stay type=action")
has(mo, "function MouseoverCast.UsesNativeCVar", "Forever native CVar path is gated")
has(mo, "function MouseoverCast.ApplyNativeCheck", "native checkmouseovercast is stamped from the engine")
has(mo, 'UnitExists("target")', "PreClick does not stamp a missing target unit")
has(mo, 't == "click" or t == "macro" or t == "macrotext"', "overlay types skip the native unit pick")
has(mo, 'button == "ConjureBind"', "conjure keys skip mouseover unit pick")
has(mo, 'button == "RightButton"', "right-click conjure skips mouseover unit pick")
has(mo, "hopRecomputeHeld", "MouseoverCast ignores slot storms during world hops")

-- ---------------------------------------------------------------------------
-- Hop/mod in-game debug
-- ---------------------------------------------------------------------------

local eventsSrc = read("Engine/Events.lua")
has(eventsSrc, "function Events.SetTrace", "Events hop/mod debug trace")
has(eventsSrc, "C_EventUtils.IsEventValid", "Events validity uses C_EventUtils")
has(eventsSrc, "return valid == true", "IsEventValid nil/false skips RegisterEvent probe")
has(eventsSrc, "majorVersion or 0) >= 11", "LEARNED_SPELL_IN_TAB skipped on Retail 11+")
if mo:find('Ev.Register("LEARNED_SPELL_IN_TAB"', 1, true) then
	failures[#failures + 1] = "MouseoverCast must not register LEARNED_SPELL_IN_TAB directly"
end
has(mo, "RegisterLearnedSpell", "MouseoverCast uses RegisterLearnedSpell")

local chromeSrc = read("Engine/SpellBookChrome.lua")
has(chromeSrc, "PagedSpellsFrame", "modern Mouseover Cast sits on the PagedSpellsFrame footer")
has(chromeSrc, "BOTTOMLEFT", "modern chrome uses the page footer, not SearchBox")
has(chromeSrc, "CLASSIC_TITLE_X, CLASSIC_TITLE_Y = 74, -38", "classic chrome uses the Blizzard ranks title slot")
has(chromeSrc, "EnsureBlizzardShowAllRanks", "Forever keeps Blizzard Show All Ranks CVar and locale")
has(chromeSrc, "SHOW_ALL_SPELL_RANKS", "Forever settings gear gets SHOW_ALL_SPELL_RANKS")
has(chromeSrc, "SettingsDropdown:Show", "Forever settings dropdown stays shown")
has(chromeSrc, "ShouldCreateFluxShowAllRanks", "Forever PlayerSpells may surface Blizzard's Show All Ranks CVar")
has(chromeSrc, "IsSpellBookItemLowRank", "live Midnight is detected by missing low-rank API")
has(chromeSrc, "_fluxCreatedShowAllRanks", "Flux never hides Classic's XML Show All Ranks checkbox")
if chromeSrc:find('function mixin:SetupAllRanksCheckbox', 1, true) then
	failures[#failures + 1] = "SpellBookChrome must not replace Blizzard SetupAllRanksCheckbox"
end

local capSrc = read("Capabilities.lua")
has(capSrc, "Cap.hasGamepadUI", "gamepad HUD probe is a capability")
has(capSrc, "function Cap.IsGamepadUIEnabled", "gamepad HUD is a live style check")
has(capSrc, "C_InputInterfaceStyle.GetCurrentStyle", "gamepad HUD uses GetCurrentStyle")
has(capSrc, "Enum.InputDeviceInterfaceType.Gamepad", "gamepad HUD compares the Gamepad style")
has(capSrc, "function Cap.GetGamepadActionBarFloor", "gamepad bar top is read-only clearance")
if capSrc:find("C_GamePad.IsEnabled", 1, true) then
	failures[#failures + 1] = "gamepad HUD must not use C_GamePad.IsEnabled"
end
if capSrc:find("Client.isCamelot", 1, true) and capSrc:find("hasGamepadUI", 1, true) then
	local i = capSrc:find("Cap.hasGamepadUI", 1, true)
	local j = i and capSrc:find("\nCap.has", i + 20, true)
	local body = (i and j and capSrc:sub(i, j)) or ""
	if body:find("isCamelot", 1, true) or body:find("isForever", 1, true) then
		failures[#failures + 1] = "hasGamepadUI must not be a flavor check"
	end
end
has(capSrc, "Cap.hasFlyableMacro", "Cap.hasFlyableMacro for bag-item clients")
has(capSrc, "Cap.hasIsFlyableArea", "Cap.hasIsFlyableArea")
has(capSrc, "Cap.disableSwingTimer = ((Client.isRetail and Client.isPostDF) and not Client.isCamelot) or Client.isCata or Client.isMists", "swing timer gated off post-DF live retail and post-Cata classic, not Forever")
has(capSrc, "Cap.hasSwingTimer = not Cap.disableSwingTimer", "hasSwingTimer derived from disableSwingTimer")
has(capSrc, "Cap.hasNativePlayerSwing", "Forever native PLAYER_SWING probe")
has(capSrc, "Enum.PlayerSwingType.Ranged", "native PLAYER_SWING probe requires Ranged")
has(capSrc, "C_SwingTimer.EnableRangeCheck", "native PLAYER_SWING probe requires EnableRangeCheck")
has(capSrc, "C_SwingTimer.IsTargetWithinSwingRange", "native PLAYER_SWING probe requires IsTargetWithinSwingRange")
has(capSrc, "Cap.hasCombatLogUnfiltered", "CLEU capability probe")
has(capSrc, "Cap.hasDurationUtil", "DurationUtil capability")
has(capSrc, "Cap.hasC_UnitAuras_GetAuraDuration", "GetAuraDuration capability")
has(capSrc, "Cap.hasC_UnitAuras_GetCooldownAuraBySpellID", "GetCooldownAuraBySpellID capability")
has(capSrc, "Cap.hasC_UnitAuras_GetPlayerAuraBySpellID", "GetPlayerAuraBySpellID capability")
has(capSrc, "Cap.hasStatusBarTimerDuration", "SetTimerDuration capability")
has(capSrc, "function Cap.GetFluxBlizzardActionBarUIMode", "Cap.GetFluxBlizzardActionBarUIMode")
do
	local body = slice(capSrc, "function Cap.GetFluxBlizzardActionBarUIMode", "function Cap.AllowBlizzardActionBarSettingsReplace")
	has(body, "Client.isMists", "MoP is classic_style")
	has(body, '"classic_style"', "Classic-family mode name")
	has(body, "Client.isRetail", "Live and Forever are mainline")
	if body:find("isMists") and body:find('return "unsupported"') then
		local mistsAt = body:find("Client.isMists", 1, true)
		local lastUnsup = body:match(".*()return \"unsupported\"")
		-- first unsupported is missing Settings; last is the else. Mists must be in classic_style.
		if mistsAt and lastUnsup and mistsAt > lastUnsup then
			failures[#failures + 1] = "MoP must not fall through to unsupported"
		end
	end
end
has(capSrc, "function Cap.AllowBlizzardActionBarSettingsReplace", "Settings replace is Classic-family only")
local legacyCap = read("../Legacy/API/Capabilities.lua")
has(legacyCap, "Cap.GetFluxBlizzardActionBarUIMode", "Legacy mode probe uses Core Cap")
has(legacyCap, "isMists", "Legacy fallback includes MoP")
has(legacyCap, "FLUX_API.skipFluxThreatMeterLayouts = isRetail and isPostDF and not isCamelot", "Forever keeps Details threat meter presets")
has(capSrc, "Cap.hasBlizzardObjectiveTrackerScroll = Client.isRetail and Client.isPostDF", "live and Forever share the objective-tracker scroll viewport")
has(legacyCap, "FLUX_API.hasBlizzardObjectiveTrackerScroll = isRetail and isPostDF", "Legacy live and Forever share the objective-tracker scroll viewport")
if capSrc:find("Cap.hasBlizzardObjectiveTrackerScroll = Client.isRetail and Client.isPostDF and not Client.isCamelot", 1, true) then
	failures[#failures + 1] = "Forever must not be excluded from the objective-tracker scroll viewport"
end
if legacyCap:find("FLUX_API.hasBlizzardObjectiveTrackerScroll = isRetail and isPostDF and not isCamelot", 1, true) then
	failures[#failures + 1] = "Legacy Forever must not be excluded from the objective-tracker scroll viewport"
end
do
	local legacyClient = read("../Legacy/API/Client.lua")
	has(legacyClient, "ns.API.hasBlizzardObjectiveTrackerScroll = isRetail and isPostDF", "Legacy Client live and Forever share the objective-tracker scroll viewport")
	if legacyClient:find("ns.API.hasBlizzardObjectiveTrackerScroll = isRetail and isPostDF and not isCamelot", 1, true) then
		failures[#failures + 1] = "Legacy Client must not exclude Forever from the objective-tracker scroll viewport"
	end
end
has(legacyCap, "FLUX_API.hasSwingTimer = not FLUX_API.disableSwingTimer", "Legacy hasSwingTimer derived from disableSwingTimer")
has(legacyCap, "FLUX_API.hasNativePlayerSwing", "Legacy mirrors native PLAYER_SWING probe")
has(legacyCap, "Enum.PlayerSwingType.Ranged", "Legacy native PLAYER_SWING probe requires Ranged")
has(legacyCap, "C_SwingTimer.EnableRangeCheck", "Legacy native PLAYER_SWING probe requires EnableRangeCheck")
has(legacyCap, "FLUX_API.hasC_UnitAuras_GetCooldownAuraBySpellID", "Legacy GetCooldownAuraBySpellID probe")
has(legacyCap, "FLUX_API.hasC_UnitAuras_GetPlayerAuraBySpellID", "Legacy GetPlayerAuraBySpellID probe")

local tickerSrc = read("Engine/Ticker.lua")
has(tickerSrc, "function Ticker.SetTrace", "Ticker hop/mod debug trace")

local hopLag = read("Engine/HopLag.lua")
has(hopLag, "SLASH_FLUXHOP1 = \"/fluxhop\"", "HopLag slash is /fluxhop")
has(hopLag, "HopLag.enabled = false", "HopLag is off by default")
has(hopLag, "function HopLag.Enable", "HopLag can be armed in-game")
has(hopLag, "face.OnContext", "HopLag times ProgramFace.OnContext")
has(hopLag, "attr.action", "HopLag times action-attribute swaps")
if hopLag:find("orig._fluxHopLag", 1, true) or hopLag:find("wrapped._fluxHopLag", 1, true) then
	failures[#failures + 1] = "HopLag must not index functions (Lua functions have no fields)"
end
if hopLag:find("HopLag.enabled = true", 1, true) and not hopLag:find("HopLag.enabled = false", 1, true) then
	failures[#failures + 1] = "HopLag must default to off"
end

local combatSrc = read("Engine/Combat.lua")
has(combatSrc, "function Combat.RegenDefer", "RegenDefer exists")
has(combatSrc, "FluxCombatRegenDeferQueue", "global light regen queue")
has(combatSrc, "FluxRegenDeferHeavyQueue", "global heavy regen queue")
has(combatSrc, "ScheduleRegenQueues", "regen defer drains next frame")
has(combatSrc, "NoteFlushKeys", "flush keys are recorded")
if combatSrc:find("pending[key] = fn", 1, true) and not combatSrc:find("lightQ", 1, true) then
	failures[#failures + 1] = "RegenDefer must not reuse same-key Defer for a list of fns"
end

local perfSrc = read("Engine/Perf.lua")
has(perfSrc, "Perf.Regen", "regen capture table")
has(perfSrc, "function Regen.Print", "regen dump")
has(perfSrc, "function Regen.OnRegen", "regen window opens on leave-combat")
has(perfSrc, "InstallHooks", "regen hooks ForceApply/Clicks/Relayout sites")

local perfDebug = read("../Other/FluxPerfDebug.lua")
has(perfDebug, "regen", "/fluxperf regen")
has(perfDebug, "Regen.Print", "slash dumps last regen")

local auraSrc = read("API/Aura.lua")
has(auraSrc, "CanAccessSecrets", "Aura gates on CanAccessSecrets")
has(auraSrc, "pcall(C_UnitAuras.GetAuraSlots", "Aura GetSlots is pcall'd")
has(auraSrc, "pcall(C_UnitAuras.GetAuraDataByIndex", "Aura GetDataByIndex is pcall'd")
has(auraSrc, "pcall(C_UnitAuras.GetAuraDataBySlot", "Aura GetDataBySlot is pcall'd")
has(auraSrc, "function Aura.GetPlayerAuraBySpellID", "Aura GetPlayerAuraBySpellID")
has(auraSrc, "function Aura.GetCooldownAuraBySpellID", "Aura GetCooldownAuraBySpellID")
has(auraSrc, "function Aura.GetAuraDuration", "Aura GetAuraDuration")
has(auraSrc, "return nil, false", "GetSlots access denied is nil,false")
do
	local body = slice(auraSrc, "function Aura.GetPlayerAuraBySpellID", "function Aura.GetCooldownAuraBySpellID")
	if body:find("CanAccessSecrets", 1, true) then
		failures[#failures + 1] = "GetPlayerAuraBySpellID must not gate on CanAccessSecrets"
	end
end
do
	local body = slice(auraSrc, "function Aura.GetCooldownAuraBySpellID", "function Aura.GetAuraDuration")
	if body:find("CanAccessSecrets", 1, true) then
		failures[#failures + 1] = "GetCooldownAuraBySpellID must not gate on CanAccessSecrets"
	end
end

local secretsSrc = read("API/Secrets.lua")
has(secretsSrc, "function Secrets.CanAccessSecrets", "CanAccessSecrets")
has(secretsSrc, "function Secrets.AurasRestricted", "AurasRestricted")
has(secretsSrc, "ShouldAurasBeSecret", "AurasRestricted prefers ShouldAurasBeSecret")
has(secretsSrc, "HasSecretRestrictions", "AurasRestricted respects HasSecretRestrictions")
do
	local body = slice(secretsSrc, "function Secrets.AurasRestricted", "function Secrets.IsSecretTable")
	if body:find("CanAccessSecrets()", 1, true) then
		failures[#failures + 1] = "AurasRestricted must not use CanAccessSecrets (tainted combat default)"
	end
end
do
	local body = slice(secretsSrc, "function Secrets.SafeAccessibleString", "function Secrets.SafeGetNumber")
	has(body, "Secrets.IsSecretValue(value)", "SafeAccessibleString rejects secret strings")
end
has(secretsSrc, "function Secrets.KeepLastNumber", "KeepLastNumber")
do
	local sfn, serr = loadfile(dir .. "/API/Secrets.lua")
	if not sfn then
		failures[#failures + 1] = "load Secrets.lua for KeepLastNumber: " .. tostring(serr)
	else
		local ns = { Flux = {} }
		sfn("FluxUI", ns)
		local keep = ns.Flux.Secrets and ns.Flux.Secrets.KeepLastNumber
		if not keep then
			failures[#failures + 1] = "Secrets.KeepLastNumber missing"
		else
			if keep(nil, 1.8, 2) ~= 1.8 then
				failures[#failures + 1] = "KeepLastNumber nil uses last"
			end
			if keep(2.5, 1.8, 2) ~= 2.5 then
				failures[#failures + 1] = "KeepLastNumber accessible uses value"
			end
			if keep(nil, nil, 2) ~= 2 then
				failures[#failures + 1] = "KeepLastNumber nil last uses fallback"
			end
		end
	end
end
has(secretsSrc, "function Secrets.SafeLooksEmpty", "SafeLooksEmpty")
has(secretsSrc, "function Secrets.AuraUpdateInfoIsNoop", "AuraUpdateInfoIsNoop")
has(secretsSrc, "function Secrets.AuraUpdateInfoHasSecrets", "AuraUpdateInfoHasSecrets")
has(secretsSrc, "function Secrets.IsSecretTable", "IsSecretTable")
has(secretsSrc, "function Secrets.CanAccessTable", "CanAccessTable")
do
	local body = slice(secretsSrc, "function Secrets.SafeBooleanTest", "function Secrets.NormalizeTriBool")
	has(body, "Secrets.IsSecretValue(value)", "SafeBooleanTest probes issecretvalue first")
	local secretAt = body:find("Secrets.IsSecretValue(value)", 1, true)
	local ifValueAt = body:find("if value then", 1, true)
	if ifValueAt and (not secretAt or ifValueAt < secretAt) then
		failures[#failures + 1] = "SafeBooleanTest must not if-test before issecretvalue"
	end
end
do
	local body = slice(secretsSrc, "function Secrets.AuraUpdateInfoIsNoop", "function Secrets.AuraUpdateInfoHasSecrets")
	has(body, "info.isFullUpdate", "AuraUpdateInfoIsNoop reads isFullUpdate")
	if body:find("if not info.isFullUpdate", 1, true) or body:find("if info.isFullUpdate", 1, true) then
		failures[#failures + 1] = "AuraUpdateInfoIsNoop must not boolean-test isFullUpdate directly"
	end
end
do
	local body = slice(secretsSrc, "function Secrets.AuraUpdateInfoHasSecrets", nil)
	has(body, "info.isFullUpdate", "AuraUpdateInfoHasSecrets reads isFullUpdate")
	if body:find("if not info.isFullUpdate", 1, true) or body:find("if info.isFullUpdate", 1, true) then
		failures[#failures + 1] = "AuraUpdateInfoHasSecrets must not boolean-test isFullUpdate directly"
	end
end

local legacyAuras = read("../Legacy/API/Auras.lua")
has(legacyAuras, "pcall(C_UnitAuras.GetAuraSlots", "Legacy SafeGetAuraSlots is pcall'd")
has(legacyAuras, "pcall(C_UnitAuras.GetAuraDataBySlot", "Legacy SafeGetAuraDataBySlot is pcall'd")
has(legacyAuras, "pcall(C_UnitAuras.GetAuraDataByAuraInstanceID", "Legacy GetAuraDataByAuraInstanceID is pcall'd")
if legacyAuras:find("local slots = C_UnitAuras.GetAuraSlots", 1, true) then
	failures[#failures + 1] = "Legacy SafeGetAuraSlots must not call GetAuraSlots raw"
end

local ufAuras = read("../UnitFrames/FluxUnitFrames_Auras.lua")
has(ufAuras, "AuraUpdateInfoIsNoop", "UNIT_AURA uses AuraUpdateInfoIsNoop")
has(ufAuras, "accessible == false", "denied aura slots keep last paint")
if ufAuras:find("if not unitAuraUpdateInfo.isFullUpdate", 1, true) then
	failures[#failures + 1] = "UNIT_AURA must not boolean-test isFullUpdate"
end
if ufAuras:find("#a > 0", 1, true) or ufAuras:find("#addedAuras", 1, true) then
	failures[#failures + 1] = "UNIT_AURA must not # secret addedAuras"
end

-- Blizzard player/party/tooltip/cast-bar secret patches were removed: Blizzard code
-- handles its own secrets once Flux stops writing into it.
if read("../UnitFrames/FluxBlizzardUnitFrameSecrets.lua") ~= "" then
	failures[#failures + 1] = "UnitFrames/FluxBlizzardUnitFrameSecrets.lua must stay removed"
end

local buffDebuffSrc = read("../Minimap/FluxBuffDebuffFrames.lua")
has(buffDebuffSrc, "Blizzard's BuffFrame and DebuffFrame", "minimap auras are the native BuffFrame")
has(buffDebuffSrc, "function M:PositionBuffFrames()", "PositionBuffFrames stays callable")
has(buffDebuffSrc, "function M:RefreshBlizzardAuraFrames()", "RefreshBlizzardAuraFrames stays callable")
if buffDebuffSrc:find("AttachEngineAuras", 1, true) or buffDebuffSrc:find("FluxTryInstallEnginePlayerAuras", 1, true) or buffDebuffSrc:find("_fluxBuffFrameArt", 1, true) then
	failures[#failures + 1] = "minimap must not install a second player aura row"
end
if buffDebuffSrc:find("SetAlpha", 1, true) then
	failures[#failures + 1] = "minimap must not alpha-hide BuffFrame"
end
if buffDebuffSrc:find("UpdateGridLayout", 1, true) then
	failures[#failures + 1] = "minimap must not wrap BuffFrame UpdateGridLayout"
end
if buffDebuffSrc:find("BuffFrame:Update", 1, true) or buffDebuffSrc:find("DebuffFrame:Update", 1, true) or buffDebuffSrc:find("BuffFrame_Update", 1, true) then
	failures[#failures + 1] = "minimap must not addon-force BuffFrame:Update"
end
if buffDebuffSrc:find("C_EditMode", 1, true) or buffDebuffSrc:find("SaveLayouts", 1, true) or buffDebuffSrc:find("SetActiveLayout", 1, true) or buffDebuffSrc:find("MakeNewLayout", 1, true) or buffDebuffSrc:find("SelectLayout", 1, true) then
	failures[#failures + 1] = "minimap must not write an Edit Mode layout (taints CompactUnitFrame_UpdateHealthColor)"
end
if buffDebuffSrc:find("RegisterStateDriver", 1, true) or buffDebuffSrc:find("SetPointBase", 1, true) or buffDebuffSrc:find("SecureHandlerSetFrameRef", 1, true) then
	failures[#failures + 1] = "minimap must not anchor BuffFrame or DebuffFrame (taints Edit Mode party-frame health colors)"
end
has(buffDebuffSrc, "AuraContainer", "buff row shift is on the icon container, not the Edit Mode system frame")
has(buffDebuffSrc, "editModeActive", "container shift does not run while Edit Mode is open")
if buffDebuffSrc:find("ReloadUI", 1, true) or buffDebuffSrc:find("C_UI.Reload", 1, true) then
	failures[#failures + 1] = "minimap must not call ReloadUI (ADDON BLOCKED from the enforcer)"
end
local bossPosSrc = read("../Other/FluxBossFramePosition.lua")
local arenaPosSrc = read("../Other/FluxArenaFramePosition.lua")
if bossPosSrc:find('"BOTTOMRIGHT", debuff', 1, true) or arenaPosSrc:find('"BOTTOMRIGHT", debuff', 1, true) or bossPosSrc:find("relativeTo == _G.DebuffFrame", 1, true) == nil then
	failures[#failures + 1] = "boss/arena must not anchor to DebuffFrame (taints combat DebuffFrame:SetSize)"
end
if buffDebuffSrc:find('RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED"', 1, true) or buffDebuffSrc:find("UNIT_AURA", 1, true) then
	failures[#failures + 1] = "buff frames must not re-anchor on PLAYER_SPECIALIZATION_CHANGED or UNIT_AURA"
end

local auraEngineSrc = read("../UnitFrames/FluxUnitFrames_AurasEngine.lua")
has(auraEngineSrc, "isCamelot", "engine auras enabled on Forever")
has(auraEngineSrc, "CreateFrame, \"AuraContainer\"", "engine auras create AuraContainer")
has(auraEngineSrc, "_fluxCancelAuras", "engine buttons honor the cancel-aura flag")
has(auraEngineSrc, "GetIconSizes", "engine own-debuff sizes come from shared policy")
has(auraEngineSrc, "GetOtherHarmfulFilter", "engine other-debuff group uses filter negation")
has(auraEngineSrc, "GetHarmfulFilter", "engine falls back to the full harmful filter")
has(auraEngineSrc, "GetOwnHarmfulFilter", "engine own-debuff group uses the shared own filter")
has(auraEngineSrc, "fullFilter", "a failed !PLAYER group is replaced by one full harmful group")
if auraEngineSrc:find('otherFilter = "HARMFUL|!PLAYER"', 1, true) then
	failures[#failures + 1] = "engine must not invent HARMFUL|!PLAYER when negation is missing"
end
if auraEngineSrc:find("own without other is still a visible combat display", 1, true) then
	failures[#failures + 1] = "engine must not keep a player-only debuff group when !PLAYER fails"
end
if auraEngineSrc:find("isFromPlayerOrPlayerPet = false", 1, true) then
	failures[#failures + 1] = "engine must not treat NPC-only auras as the other-debuff group"
end
if auraEngineSrc:find("ownMult = ownMult * minScale", 1, true) then
	failures[#failures + 1] = "engine must not apply min-scale while computing the lock-on boost"
end
if auraEngineSrc:find("_fluxBuffFrameArt", 1, true) or auraEngineSrc:find("InitializeBuffFrameArtButton", 1, true) or auraEngineSrc:find("GetBuffFrameDurationFormatter", 1, true) then
	failures[#failures + 1] = "engine must not keep a BuffFrame-art replica of the minimap aura row"
end

local auraOwnSrc = read("../UnitFrames/FluxUnitFrames_AurasOwn.lua")
has(auraOwnSrc, "HARMFUL|PLAYER", "own-debuff policy uses PLAYER filter")
has(auraOwnSrc, "BOOST = (42 / 35) * 1.15", "own-debuff boost stays ~1.38x")
has(auraOwnSrc, "nameplateShowPersonal", "own-debuff identity falls back to nameplateShowPersonal when caster is secret")
has(auraOwnSrc, "function AuraOwn.GetHarmfulFilter()", "harmful list helper exists")
has(auraOwnSrc, "IncludeNameplateOnly", "harmful list includes nameplate-only auras when the client has that token")
has(auraOwnSrc, "function AuraOwn.GetOwnHarmfulFilter()", "own harmful filter helper exists")
has(auraOwnSrc, "function AuraOwn.GetOtherHarmfulFilter()", "other harmful filter helper exists")
if auraOwnSrc:find("AuraDataTreatAsPlayerHarmful", 1, true) or auraOwnSrc:find("canApplyAura", 1, true) then
	failures[#failures + 1] = "own-debuff size must not use canApplyAura / shared-refresh"
end

local consumablesSrc = read("../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua")
has(consumablesSrc, "GetPlayerAuraBySpellID", "consumable extras look up auras by spell ID")
has(consumablesSrc, "GetCooldownAuraBySpellID", "consumable extras map item cast to self-buff")
has(consumablesSrc, "GetAuraDuration", "consumable extras use duration objects for timers")
has(consumablesSrc, "AurasRestricted", "consumable extras do not use CanAccessSecrets as the combat gate")
has(consumablesSrc, "FluxConsumableAuraCooldown", "consumable extras own aura remaining vs item CD")
has(consumablesSrc, "RefreshAuraTimerOverlay", "consumable extras refresh aura timers on UNIT_AURA")
has(consumablesSrc, "AuraUpdateInfoIsNoop", "consumable UNIT_AURA skips secret no-op payloads")
do
	local helper = slice(consumablesSrc, "local function PlayerHelpfulAura(index)", "local heldBuffByKey")
	if helper:find("CanAccessSecrets", 1, true) then
		failures[#failures + 1] = "PlayerHelpfulAura must not gate on CanAccessSecrets (Forever combat taint)"
	end
	has(helper, "AurasRestricted", "index aura scans skip when auras are secret")
end

local paintSrc = read("../ExtraButtonSystem/Engine/Paint.lua")
has(paintSrc, "FluxConsumableAuraCooldown", "extra Paint honors consumable aura timers")
has(paintSrc, "ClaimConsumableItemAura", "potion extras can claim self-buff remaining")
has(paintSrc, "IsEatDrinkExtra", "food/water extras keep item/spell cooldown")
if paintSrc:find("FindWellFedBuff", 1, true) then
	failures[#failures + 1] = "food extra must not paint Well Fed remaining over eat/drink cooldown"
end
if paintSrc:find("fromItem or btn.IsFoodButton", 1, true) then
	failures[#failures + 1] = "Paint must not aura-claim food extras (Recuperate/item CD)"
end

local gridUiSrc = read("../ExtraButtonSystem/Shared/FluxConsumablesGridUI.lua")
has(gridUiSrc, "GetBuffRemaining", "consumable config cells use shared remaining helper")

local ufShared = read("../UnitFrames/FluxUnitFrames_Shared.lua")
has(ufShared, "ClientUsesRealHealthNumbers", "health text does not treat Classic/Forever max<=100 as percent-scaled")
has(ufShared, "client.isCamelot or client.isAnyClassic", "Forever/Classic real HP skips percent-only health text")
has(ufShared, "ThreatAPI.GetNumericDisplay", "unit-frame threat bars use Flux.Threat numeric display")
has(ufShared, "ThreatAPI.GetForeverFrameDisplay", "Forever target bar uses the client raw/lead percent")
has(ufShared, "ShouldShowNumericOnUnit", "unit-frame threat % follows threatShowNumeric")
has(ufShared, "ThreatAPI.SetBarValue", "unit-frame threat bar SetValue is secret-safe")
has(ufShared, "ThreatAPI.UnitExists", "unit-frame threat exists check is secret-safe")
has(ufShared, "SetThreatPollArmed(InCombatLockdown and InCombatLockdown())", "threat poll arms from InCombatLockdown, not secret UnitAffectingCombat")
if ufShared:find('if not UnitExists(tu) or not UnitAffectingCombat("player")', 1, true) then
	failures[#failures + 1] = "UpdateThreatBar must not Lua-test UnitAffectingCombat/UnitExists"
end
has(ufShared, "IsCamelotPortraitClient", "Forever portrait client probe")
has(ufShared, "ApplyCamelotPortraitCamera", "Forever uses engine zoom then measured fallback")
has(ufShared, "SetPortraitZoom", "3D portraits use engine portrait zoom")
has(ufShared, "GetCameraDistance", "Forever only custom-frames when zoom left a far camera")
has(ufShared, "SetPortraitUnit", "shared SetUnit plus head framing")
if ufShared:find("PORTRAIT_HEAD_Z", 1, true) or ufShared:find("ApplyForcedHeadCamera", 1, true) then
	failures[#failures + 1] = "must not use guessed race-height portrait cameras"
end
if ufShared:find("ArmPortraitCameraWatch", 1, true) then
	failures[#failures + 1] = "must not OnUpdate-fight Forever portrait cameras"
end
if not ufShared:find("if IsCamelotPortraitClient() then", 1, true) then
	failures[#failures + 1] = "camelot must have its own portrait camera path"
end
do
	local camelotFn = slice(ufShared, "local function ApplyCamelotPortraitCamera", "local function ApplyPortraitCamera")
	if camelotFn:find("RefreshCamera", 1, true) then
		failures[#failures + 1] = "camelot portrait camera must not RefreshCamera (full-body bake)"
	end
	if camelotFn:find("SetCamera(0)", 1, true) then
		failures[#failures + 1] = "camelot portrait camera must not SetCamera(0)"
	end
end
local legacyUI = read("../Legacy/API/UI.lua")
has(legacyUI, "if FLUX_API.isCamelot or FLUX_API.isForever then", "Forever skips pre-DF SetupPortraitModel wrap")
has(legacyUI, "function FluxRemoveFrameFromEditMode", "FluxRemoveFrameFromEditMode")
has(legacyUI, "frame.ignoreFramePositionManager = true", "Edit Mode opt-out is ignoreFramePositionManager only")
has(legacyUI, "function FluxSilenceEditModeSpecLayoutRefresh", "spec/level Edit Mode refresh is unregistered")
has(legacyUI, 'UnregisterEvent, em, "PLAYER_SPECIALIZATION_CHANGED"', "Edit Mode spec event is UnregisterEvent only")
if legacyUI:find("InitSystemAnchors =", 1, true) then
	failures[#failures + 1] = "must not replace InitSystemAnchors (taints MainActionBar:SetPointBase worse)"
end
if legacyUI:find("C_EditMode.RemoveFrame", 1, true) then
	failures[#failures + 1] = "C_EditMode has no RemoveFrame; calling it is a no-op that hid SetIsInDefaultPosition taint"
end
if legacyUI:find("SetIsInDefaultPosition", 1, true) then
	failures[#failures + 1] = "must not SetIsInDefaultPosition (InitSystemAnchors MainActionBar:SetPointBase taint)"
end
has(legacyUI, "function FluxEditModeBusy()", "Edit Mode busy helper")
has(legacyUI, "function FluxAfterEditMode(", "after-Edit-Mode queue")
has(legacyUI, 'EventRegistry:RegisterCallback("EditMode.Enter"', "busy window opens on EditMode.Enter")
has(legacyUI, 'EventRegistry:RegisterCallback("EditMode.Exit"', "busy window closes on EditMode.Exit")
has(legacyUI, "C_Timer.After(0, SuppressOwnedEditModeChrome)", "owned selection mute is deferred off the open pass")
do
	local chrome = slice(legacyUI, "local function MuteEditModeChild", "local editModeCallbacksInstalled")
	has(chrome, "SetAlpha(0)", "owned Edit Mode selection goes alpha 0 in place")
	has(chrome, "EnableMouse(false)", "owned Edit Mode selection takes no mouse")
	if chrome:find(":Hide()", 1, true) then
		failures[#failures + 1] = "owned Edit Mode selection must not Hide (alpha + mouse only)"
	end
end
if legacyUI:find('em:HookScript("OnShow"', 1, true) then
	failures[#failures + 1] = "must not HookScript EditModeManagerFrame OnShow (use EditMode.Enter)"
end
if legacyUI:find("FCF_SetLocked(", 1, true) or legacyUI:find("_G.FCF_SetLocked", 1, true) then
	failures[#failures + 1] = "Edit Mode chrome must not call FCF_SetLocked (Blizzard chat code as Flux)"
end
if legacyUI:find('hooksecurefunc(frame, "HighlightSystem"', 1, true)
	or legacyUI:find('hooksecurefunc(frame, "SelectSystem"', 1, true)
	or legacyUI:find('hooksecurefunc(frame, "OnEditModeEnter"', 1, true) then
	failures[#failures + 1] = "must not hooksecurefunc Edit Mode system methods (taints TargetUnit and party health colors)"
end
if legacyUI:find("function obj:OnEvent", 1, true) then
	failures[#failures + 1] = "must not replace AccountSettings OnEvent"
end
if legacyUI:find("function obj:RefreshTargetAndFocus", 1, true) or legacyUI:find("function obj:ResetTargetAndFocus", 1, true) then
	failures[#failures + 1] = "must not replace RefreshTargetAndFocus or ResetTargetAndFocus (taints CompactUnitFrame_UpdateHealthColor)"
end
if legacyUI:find("function obj:RefreshPartyFrames", 1, true) or legacyUI:find("function obj:ResetPartyFrames", 1, true)
	or legacyUI:find("function obj:RefreshRaidFrames", 1, true) or legacyUI:find("function obj:ResetRaidFrames", 1, true) then
	failures[#failures + 1] = "must not wrap party or raid refresh (securecallfunction does not destain the callee)"
end
if legacyUI:find("securecallfunction(orig, self, ...)", 1, true) then
	failures[#failures + 1] = "must not securecallfunction a saved party/raid refresh upvalue"
end
if legacyUI:find("EditModeFrameSetup =", 1, true) or legacyUI:find("function obj:EditModeFrameSetup", 1, true) then
	failures[#failures + 1] = "must not replace EditModeFrameSetup"
end
local extraHud = read("../Other/FluxExtraAbilityHUD.lua")
if extraHud:find('hooksecurefunc(container, "HighlightSystem"', 1, true) then
	failures[#failures + 1] = "ExtraAbilityHUD must not hook HighlightSystem (taints Edit Mode party health colors)"
end
has(extraHud, "HideEditModeSelection()", "extra ability selection hides from the deferred layout")

-- Edit Mode reads multi-bar state on the direct path before TargetUnit. Flux must
-- not run MultiActionBar_Update or the PROXY_SHOW_ACTIONBAR_* setting callbacks.
local blizzardOptsSrc = read("../Bars/BlizzardOptions.lua")
local defaultsSrcCore = read("../FluxDefaultSettings.lua")
if blizzardOptsSrc:find("MultiActionBar_Update(", 1, true) then
	failures[#failures + 1] = "BlizzardOptions must not call MultiActionBar_Update (Edit Mode SetupActionBar taint)"
end
if defaultsSrcCore:find("MultiActionBar_Update(", 1, true) then
	failures[#failures + 1] = "FluxDefaultSettings must not call MultiActionBar_Update (Edit Mode SetupActionBar taint)"
end
if defaultsSrcCore:find('"PROXY_SHOW_ACTIONBAR_', 1, true) then
	failures[#failures + 1] = "FluxDefaultSettings must not write PROXY_SHOW_ACTIONBAR_* settings (bar SetShown as Flux)"
end
has(blizzardOptsSrc, "SetActionBarToggles(unpack(t))", "extra bars still forced off via toggles")
do
	local writeSrc = read("../BlizzardSettings/Write.lua")
	local shown = slice(writeSrc, "function Write.SetShownValue", "function Write.RefreshShown")
	local refresh = slice(writeSrc, "function Write.RefreshShown", "function Write.Notify")
	has(shown, "Write.MayUseSettingsAPI()", "SetShownValue skips Settings callbacks on Forever / live")
	has(refresh, "Write.MayUseSettingsAPI()", "RefreshShown skips Settings callbacks on Forever / live")
end

-- Flux hooks that fire inside an Edit Mode pass return while it is open and
-- re-apply once it closes.
do
	local busyFiles = {
		{ "../UnitFrames/FluxCastBar.lua", "cast bar mute" },
		{ "../Other/FluxVehicleSeats.lua", "vehicle seat mute" },
		{ "../MicroMenu/FluxMicroMenu.lua", "queue eye / micro hijack" },
		{ "../Minimap/FluxMinimap.lua", "queue eye / MinimapCluster" },
		{ "../Other/FluxChatFrame.lua", "chat pin / channel button / social layout" },
		{ "../Other/FluxChatCopyPaste.lua", "chat column restack" },
		{ "../Blizzard/Hide.lua", "Blizzard frame reparent" },
		{ "../RaidFrame/FluxRaidLayout.lua", "raid grid hide / manager" },
		{ "../Other/FluxTalkingHead.lua", "talking head position" },
		{ "../WindowMover/Engine.lua", "window mover apply" },
		{ "../MicroMenu/FluxBagMicroButton.lua", "BagsBar chrome" },
	}
	for i = 1, #busyFiles do
		local src = read(busyFiles[i][1])
		if not src:find("FluxEditModeBusy", 1, true) or not src:find("FluxAfterEditMode(", 1, true) then
			failures[#failures + 1] = busyFiles[i][2] .. " must wait while Edit Mode is open"
		end
	end
end
if ufShared:find("local function IsPercentScaledHealthMax(maxH)\n    if not UnitHealthPercent", 1, true) then
	failures[#failures + 1] = "IsPercentScaledHealthMax must skip camelot/Classic before max<=100 heuristic"
end

local swingSrc = read("../UnitFrames/FluxSwingTimer.lua")
has(swingSrc, "PLAYER_SWING", "Forever swing registers PLAYER_SWING")
has(swingSrc, "ParkBlizzardSwingTimerHud", "Flux parks Blizzard SwingTimer HUD when overlay is on")
has(swingSrc, "SwingTimerMainHandFrame", "Flux parks SwingTimerMainHandFrame")
has(swingSrc, "KeepLastNumber", "swing timer caches accessible attack speed")
has(swingSrc, "HasCombatLogUnfiltered", "swing timer gates CLEU on capability")
has(swingSrc, "SetTimerDuration", "Midnight swing uses DurationObject bars")
has(swingSrc, "PLAYER_ENTER_COMBAT", "Midnight tracks auto-attack via enter combat")
has(swingSrc, "UNIT_COMBAT", "Midnight melee resets on target UNIT_COMBAT")
has(swingSrc, "swingResetSpellIDs", "next-swing resets use spell IDs")
if swingSrc:find("if UseEngineSwingTimer() and meleeAutoAttacking and not isAutoShotActive then", 1, true) then
	failures[#failures + 1] = "Midnight melee must not loop while auto-attack is on"
end
if swingSrc:find("isAutoShotActive and rangedTimer <= 0.05", 1, true) then
	failures[#failures + 1] = "Midnight Auto Shot must not metronome when the shot timer hits 0"
end
has(swingSrc, "SwingTimerClientSupported", "swing timer client gate helper")
has(swingSrc, "if not SwingTimerClientSupported() then", "swing timer bootstrap skips gated clients")
if swingSrc:find("mainSpeed = UnitAttackSpeed(\"player\") or 2", 1, true) then
	failures[#failures + 1] = "swing timer must not assign UnitAttackSpeed raw"
end
if swingSrc:find("GetUnitSpeed(\"player\") >", 1, true) then
	failures[#failures + 1] = "swing timer must not compare GetUnitSpeed without secret check"
end
if swingSrc:find("if sourceGUID ~= playerGUID then return end", 1, true)
	and not swingSrc:find("IsSecret(sourceGUID)", 1, true) then
	failures[#failures + 1] = "CLEU GUID compare must probe IsSecret first"
end
has(swingSrc, 'subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED"', "native path skips CLEU swing resets")
has(swingSrc, "ResetRangedTimer", "Forever ranged clock is ResetRangedTimer from PLAYER_SWING")
has(swingSrc, '_, _, ranged = UnitAttackSpeed("player")', "native ranged speed from UnitAttackSpeed third return")
has(swingSrc, "EnableRangeCheck", "Forever swing uses C_SwingTimer.EnableRangeCheck")
has(swingSrc, "IsTargetWithinSwingRange", "Forever swing snapshots C_SwingTimer range")
has(swingSrc, "WEAPON_SLOT_CHANGED", "Forever swing listens WEAPON_SLOT_CHANGED")
has(swingSrc, "PLAYER_SWING_RANGE_UPDATE", "Forever swing listens PLAYER_SWING_RANGE_UPDATE")
has(swingSrc, "INVSLOT_RANGED", "Forever ranged labels use ranged slot")
has(swingSrc, "THROW_SPELL_ID = 2764", "Forever ranged maps Throw")
has(swingSrc, "rangedTimer = rangedTimer - elapsed", "Forever ranged decrements PLAYER_SWING duration")
has(swingSrc, "remaining countdown from PLAYER_SWING", "Forever ranged paint skips WST clip")
if swingSrc:find("MarkRangedShotFired(duration > 0 and duration or nil)", 1, true) then
	failures[#failures + 1] = "native PLAYER_SWING Ranged must ResetRangedTimer, not MarkRangedShotFired"
end
do
	local nativeFn = slice(swingSrc, "local function OnNativePlayerSwing", "local function OnEvent")
	if nativeFn:find("isAutoShotActive = true", 1, true) then
		failures[#failures + 1] = "native PLAYER_SWING must not latch isAutoShotActive (throw has no STOP_AUTOREPEAT)"
	end
	if nativeFn:find("GetEffectiveAutoCastTime", 1, true) or nativeFn:find("ResetRangedShotTimer", 1, true) then
		failures[#failures + 1] = "native PLAYER_SWING must not use WST clip / auto-cast wind-up"
	end
end

local defaultsSrc = read("../FluxDefaultSettings.lua")
has(defaultsSrc, '["showSwingTimer"] = "0"', "Forever Blizzard swing HUD CVar defaults off")

local ufOptSrc = read("../AddonOptions/FluxOptionsUnitFrames.lua")
has(ufOptSrc, "Forever", "unit-frame swing options mention Forever")
if ufOptSrc:find("Wrath Classic only", 1, true) then
	failures[#failures + 1] = "swing timer options must not say Era/Anniversary/Wrath only"
end

local clientSrc = read("Client.lua")
has(clientSrc, "isCamelot", "Client detects camelot/Forever")
has(clientSrc, "_isCamelotGameType == true", "TOC camelot game type is authoritative")
has(clientSrc, "NewTimedSignalMap", "Forever timer API is not treated as live Midnight")
has(clientSrc, "CharacterStatsPanePetScrollBox", "Forever stats pane is the ScrollBox pair from wow-ui-source-forever")
has(clientSrc, "majorVersion < 12", "12.x live ignores CharacterStatsPaneScrollBox")
has(clientSrc, "isLiveMidnight", "live Midnight is distinct from Forever")
has(clientSrc, "isForever = isCamelot", "Client aliases isForever")
has(clientSrc, "isPreDF = (majorVersion < 10) and not isCamelot", "camelot is not pre-DF despite 1.x build")
has(clientSrc, "isMidnight = (isRetail and isV12) or isCamelot", "camelot uses midnight UI family")

local perfCapSrc = read("../Other/FluxPerfCapture.lua")
has(perfCapSrc, "gameType", "FluxPerf prints live vs camelot, not the _retail_ folder")
has(perfCapSrc, "spellRanks", "FluxPerf prints whether per-rank spellbook features are on")

local slashSrc = read("Slash.lua")
has(slashSrc, "isLiveMidnight", "/fluxapi prints live Midnight vs Forever")
has(slashSrc, "spellRanks", "/fluxapi prints per-rank spellbook flag")

local camelotSrc = read("Client_Camelot.lua")
has(camelotSrc, "_isCamelotGameType = true", "camelot TOC file sets the flag")
has(camelotSrc, "SpellRankSubtext", "Forever GetSpellInfo keeps Classic rank subtext")

has(capSrc, "hasRestrictedClosures = not Client.isCamelot", "closures disabled on camelot")
has(capSrc, "Cap.hasSpellBookItemLowRank", "live vs Forever rank chrome uses IsSpellBookItemLowRank")
has(capSrc, "Client.isEra or Client.isAnniversary or Client.isTBC or Client.isWrath", "Era/Anniversary/Wrath get Classic per-rank spell bar features")
has(capSrc, "wow-ui-source-live", "live Midnight does not get per-rank spellbook controls")

local restrictedSrc = read("Engine/Restricted.lua")
has(restrictedSrc, "function Restricted.Works()", "Restricted.Works")
has(restrictedSrc, "function Restricted.Execute(", "Restricted.Execute")
has(restrictedSrc, "function Restricted.WrapScript(", "Restricted.WrapScript")
has(restrictedSrc, "function Restricted.SetSnippet(", "Restricted.SetSnippet")
has(restrictedSrc, "function Restricted.RegisterUnitWatch(", "Restricted.RegisterUnitWatch")
has(restrictedSrc, "RegisterUnitWatch = function", "camelot replaces RegisterUnitWatch global")
has(restrictedSrc, "Keep the button shown so combat can still alpha-toggle", "camelot unit watch stays shown in combat")
has(restrictedSrc, "UnitFrames.SyncWatchedUnitFrameVisibility owns hide via alpha", "camelot defers hide to unit-frame alpha")
if restrictedSrc:find("frame:Execute(", 1, true) and not restrictedSrc:find("Do not probe", 1, true) then
	-- Execute is wrapped in pcall after Works(); probing CreateFrame is forbidden.
end

local cscShared = read("../CharacterInfo/Shared.lua")
has(cscShared, "Client.isEra", "CSC era uses Flux.Client.isEra")
has(cscShared, "isCamelot", "CSC skips Forever camelot via Client.isRetail/isCamelot")
if cscShared:find("CharacterStatsPaneScrollBox", 1, true) then
	failures[#failures + 1] = "CSC must not infer Forever from CharacterStatsPaneScrollBox"
end
if cscShared:find("module.isClassicEra = module.majorVersion == 1", 1, true) then
	failures[#failures + 1] = "CSC must not treat majorVersion 1 as Era (Forever is 1.x mainline)"
end

local aurasSrc = read("../UnitFrames/FluxUnitFrames_Auras.lua")
has(aurasSrc, "if not UnitAura then", "aura pre-DF path requires UnitAura")
has(aurasSrc, "HasPackedAuraAPI", "aura collection prefers packed C_UnitAuras")
has(aurasSrc, "AuraOwn.IsOwnHarmful", "Lua painter uses shared own-debuff identity")
has(aurasSrc, "GetHarmfulFilter", "target/focus debuffs use the shared harmful filter")
has(aurasSrc, "for auraIndex = 1, debuffGatherLimit", "target/focus debuffs scan from index 1")
has(aurasSrc, "pcall(button.Icon.SetTexture", "secret aura icons are applied without a boolean test")
do
	local debuffScan = slice(aurasSrc, "Target/focus debuffs: index 1..N", "SortDebuffDataListPlayerFirst")
	if debuffScan == "" then
		failures[#failures + 1] = "target/focus debuff scan block is missing"
	end
	if debuffScan:find("for i = 2, #slots", 1, true) or debuffScan:find("SafeGetAuraSlots", 1, true) then
		failures[#failures + 1] = "target/focus debuffs must not skip the first GetAuraSlots entry"
	end
end

local ufSharedSrc = read("../UnitFrames/FluxUnitFrames_Shared.lua")
has(ufSharedSrc, "function UF.UnitTokenIsResolved(", "unit token resolved helper")
has(ufSharedSrc, "function UF.ShouldShowWatchedUnitFrame(", "watched unit show predicate")
if ufSharedSrc:find("pcall(UnitIsUnit, playerUnit, parent)", 1, true) then
	failures[#failures + 1] = "ToT / focus-target must stay visible when targeting yourself"
end
has(ufSharedSrc, 'self.nameText:SetPoint("CENTER", self.outerBorderFrame, "TOP", 0, -12)', "player/target names lift when Pet/ToT is shown")
has(ufSharedSrc, "C_PetInfo.GetPetHappiness", "pet happiness prefers Forever C_PetInfo.GetPetHappiness")
has(ufSharedSrc, "type(GetPetHappiness) == \"function\"", "pet happiness falls back to classic GetPetHappiness")
has(ufSharedSrc, "FluxSafeRegisterEvent(frame, \"UNIT_HAPPINESS\")", "player frame registers UNIT_HAPPINESS safely")
do
	local happy = slice(ufSharedSrc, "A nil happiness result hides the icon", "local icon = EnsurePetHappinessIcon")
	has(happy, "if happiness == nil then", "nil happiness hides the icon")
	has(happy, "HidePetHappinessIcon(frame)", "nil happiness hides the icon")
end
has(ufSharedSrc, "local totResolved = UF.UnitTokenIsResolved(\"targettarget\")", "placement 2 lifts the target name whenever ToT exists")
has(ufSharedSrc, "function UF.SyncWatchedUnitFrameVisibility(", "combat-safe watched unit visibility")
has(ufSharedSrc, "RegisterUnitWatch owns shown-state", "combat watched frames skip Show/Hide")
if ufSharedSrc:find("local hidden = pcall(frame.Hide, frame)", 1, true) then
	failures[#failures + 1] = "combat watched visibility must not pcall Hide (ADDON_ACTION_BLOCKED)"
end
do
	local clickable = slice(ufSharedSrc, "local function SetWatchedFrameClickable", "local function SetWatchedFrameAlpha")
	has(clickable, "C_Timer.After(0", "watched mouse waits until the secure handler returns")
	has(clickable, "InCombatLockdown", "deferred mouse skips combat lockdown")
	has(clickable, "_fluxMouseWanted", "watched mouse keeps the latest requested state")
	has(clickable, "IsShown", "watched mouse skips a hidden button")
	has(clickable, "_fluxMouseEnabled", "watched mouse skips a redundant EnableMouse")
	local afterAt = clickable:find("C_Timer.After(0", 1, true)
	local mouseAt = clickable:find(":EnableMouse", 1, true)
	if not afterAt or not mouseAt or mouseAt < afterAt then
		failures[#failures + 1] = "SetWatchedFrameClickable must not EnableMouse before the deferred tick"
	end
end
has(ufSharedSrc, "function UF.SyncTargetPlaceholderVisibility(", "empty-target placeholder follows resolved target")
has(ufSharedSrc, "function UF.HideEmptyUnitPortrait(", "empty unit portraits clear instead of leftover ?")
has(ufSharedSrc, "ApplyWatchedUnitChrome(", "atlas and separators follow watched visibility")
has(ufSharedSrc, "PaintUnitFrameNameText", "no Unknown name fallback for missing units")
has(ufSharedSrc, "local function TruncatePlainTextToWidth(", "unit names ellipsize when the strip is too narrow")
has(ufSharedSrc, "local compactName = (self.unit == \"targettarget\" or self.unit == \"focustarget\")", "ToT / focus-target names use a compact fit")
if ufSharedSrc:find('and FluxUnitFrames_ShouldUseFlux("targettarget")\r\n        then\r\n            maxSz = 12', 1, true)
	or ufSharedSrc:find('and FluxUnitFrames_ShouldUseFlux("targettarget")\n        then\n            maxSz = 12', 1, true) then
	failures[#failures + 1] = "placement 2 must not shrink the target name when ToT exists"
end
if ufSharedSrc:find("if not unit or not UnitExists(unit) then\r\n        ShowPortraitQuestionMark(self.Portrait)", 1, true)
	or ufSharedSrc:find("if not unit or not UnitExists(unit) then\n        ShowPortraitQuestionMark(self.Portrait)", 1, true) then
	failures[#failures + 1] = "missing units must not load TalkToMeQuestionMark"
end

local ufCastSrc = read("../UnitFrames/FluxCastBar.lua")
has(ufCastSrc, "function CB.RefreshCastForUnit(", "retarget starts secret-safe casts")
has(ufCastSrc, "local function CastLooksActive(", "cast start treats secret names as active")
has(ufCastSrc, "EventUnitMatchesRegistered(", "cast events pcall unit token compare")
has(ufCastSrc, "local function ApplyClientCastTiming(", "cast bar uses UnitCastingInfo start/end like Forever")
has(ufCastSrc, "local function PaintCastBarRemainingTime(", "cast bar keeps a remaining-seconds countdown")
has(ufCastSrc, "Forever CastingBarMixin:OnUpdate: tick cached start/end value", "OnUpdate ticks client timing instead of polling UnitCastingInfo")
has(ufCastSrc, "assume match so CHANNEL_STOP still finishes the bar", "secret spellIDs fail-open on channel stop")
has(ufCastSrc, "if interruptedBy == nil or IsSecretValue(interruptedBy)", "interrupt text does not boolean-test kicker GUID")
has(ufCastSrc, "local function UseClassicCastBarColorFinish(", "classic progression uses vertex color finish not atlas cap")
has(ufCastSrc, "FLUX_CASTBAR_FINISH_GREEN", "classic successful casts flash green on UI-StatusBar")
if ufCastSrc:find("local function CastDisplayLabel(", 1, true) then
	failures[#failures + 1] = "cast start must not strip secret names through CastDisplayLabel"
end
if ufCastSrc:find("return false -- Can't compare secret values", 1, true) then
	failures[#failures + 1] = "SafeCompareSpellID must not fail-closed on secret ids"
end
if ufCastSrc:find("if interruptedBy and not IsSecretValue", 1, true) then
	failures[#failures + 1] = "GetInterruptText must not boolean-test interruptedBy before IsSecretValue"
end
if ufSharedSrc:find('UnitDisplayName(self.unit) or "Unknown"', 1, true) then
	failures[#failures + 1] = "unit frames must not paint Unknown when the name is missing"
end

local actionsSrc = read("../Legacy/API/Actions.lua")
has(actionsSrc, "FLUX_API.isCamelot or FLUX_API.isForever", "legacy ComboFrame UI disabled on camelot")
has(actionsSrc, "FLUX_API.isCamelot and C_Spell.GetSpellSubtext", "legacy GetSpellInfo keeps Forever rank subtext")

has(read("../Legacy/API/Client.lua"), "IsSpellBookItemLowRank", "legacy per-rank spells follow the Forever low-rank API")
has(read("../Legacy/API/Client.lua"), "isClassicEra or isTBC or isWrath", "legacy Era/Anniversary/Wrath get per-rank spell bar features")
has(read("../Legacy/API/Client.lua"), "FluxClient.isCamelot ~= nil", "legacy camelot trusts Core Client on live Midnight")

local cscEra = read("../CharacterInfo/StatsEra.lua")
has(cscEra, "if not CharacterFrame or not CharacterAttributesFrame then", "Era CreateMenu guards missing attributes frame")

local salvage = read("../Salvage/FluxSalvage_Overlay.lua")
has(salvage, "local function SnippetsWork()", "salvage gates restricted snippets")
has(salvage, "if not SnippetsWork() then", "salvage skips RegisterAttributeDriver on camelot")
has(salvage, "function S.ApplySpellToBagSlot", "salvage overlay binds Forever bag/slot without ItemLocation")
has(salvage, "OverlayFill", "salvage overlay has a visible fill when Forever lacks the proc atlas")
has(salvage, "HintFromTooltipText", "salvage reads Requires Comprehension from live tooltip text")

local salvageClassify = read("../Salvage/FluxSalvage_Classify.lua")
has(salvageClassify, "function S.IsComprehensible", "salvage classifies Comprehend Scroll items")
has(salvageClassify, "function S.GetComprehendSpell()", "Comprehend Scroll resolves from a known mage spell name or ID")
has(salvageClassify, "GetSkillLineRank", "Comprehend uses secondary skill rank not a profession")
has(salvageClassify, "FindComprehendScrollInSpellBook", "Comprehend Scroll walks Forever spellbook skill lines")

has(camelotSrc, "AliasIfMissing(\"GetItemInfo\"", "camelot restores GetItemInfo from C_Item")
has(camelotSrc, "GetItemIcon", "camelot restores GetItemIcon from C_Item")
has(camelotSrc, "AliasIfMissing(\"GetZonePVPInfo\"", "camelot restores GetZonePVPInfo from C_PvP")
has(camelotSrc, "UnitAura =", "camelot restores UnitAura from C_UnitAuras")
has(camelotSrc, "ParkComboFrame", "camelot parks Blizzard ComboFrame")

local hoverSrc = read("../Binding/Input/FluxMouseoverKeybind.lua")
has(hoverSrc, "local function HeaderExecute(body)", "hovercast Execute is gated")
has(hoverSrc, "local function HeaderSetSnippet(name, body)", "hovercast snippet SetAttribute is gated")
has(hoverSrc, "Camelot: Restricted.Execute no-ops", "hover header runs when Restricted no-ops")
has(hoverSrc, "pcall(header.Execute, header, body)", "camelot hovercast Execute calls the header")
has(hoverSrc, 'pcall(header.WrapScript, header, frame, "OnEnter", ENTER_SNIPPET)', "camelot hovercast wraps OnEnter on the header")
has(hoverSrc, 'return "LeftButton"', "spell-hover clicks _HC as LeftButton")
if hoverSrc:find("if not SnippetsWork() then return false end", 1, true) then
	failures[#failures + 1] = "hovercast wrap must not skip camelot"
end
if hoverSrc:find("header:WrapScript(frame, \"OnEnter\"", 1, true) then
	failures[#failures + 1] = "hovercast must not WrapScript OnEnter without Restricted helper"
end
if hoverSrc:find('mbtn or "Keybind"', 1, true) then
	failures[#failures + 1] = "spell-hover SetBindingClick must use LeftButton"
end

local trinketSrc = read("../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua")
has(trinketSrc, "local function ItemInfo(item)", "trinket menu uses ItemInfo helper")
if trinketSrc:find("GetItemInfo(t.id)", 1, true) or trinketSrc:find("GetItemInfo(itemID)", 1, true) then
	failures[#failures + 1] = "trinket scan must not call global GetItemInfo"
end

local minimapSrc = read("../Minimap/FluxMinimap.lua")
has(minimapSrc, "FluxObjectiveTrackerScroll:InstallForeverCompat", "Forever tracker hooks install even without a ScrollFrame")
has(minimapSrc, "Viewport scroll: PinLayoutHeight inside the scroll child, never SetHeight", "Forever dock pins layout height inside the scroll child")
has(minimapSrc, "leave Blizzard parent/anchors until Manager.Init", "Forever does not unanchor the tracker before Manager.Init")
has(minimapSrc, "Embedded and floating minimap both size", "embedded and floating minimap share the scroll viewport")
has(minimapSrc, "_fluxForeverPewTracker", "Forever first PEW docks tracker after Manager.Init")
has(minimapSrc, "Flux.AfterLogin", "Forever tracker dock runs on login and /reload")
has(minimapSrc, "if landingBtn == ExpansionLandingPageMinimapButton and not ExpansionLandingPage then", "minimap hides landing button when ExpansionLandingPage is missing")
has(minimapSrc, "C_PvP.GetZonePVPInfo", "minimap zone PVP uses C_PvP")

local otScrollSrc = read("../Minimap/FluxObjectiveTrackerScroll.lua")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:PinTopModulePadding", "Forever tracker padding is pinned at 0 while Flux scroll is active")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:PinLayoutHeight", "scroll adapter pins a tall layout height so Forever GetAvailableHeight does not skip quests")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:RecoverStuckDirty", "Forever dirty flag is cleared if Frame:Update throws after layout")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:CollapseModuleTopGap", "Forever first module is pulled up under All Objectives")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:AnchorHeader", "Forever header re-anchor is restored after Blizzard padding providers")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:DockQuestTimer", "Forever QuestTimer is docked to the Flux viewport")
has(otScrollSrc, "applyLiveBlockHighlight", "Forever missing poiQuestID falls back to live highlight colors")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:InstallForeverCompat", "Forever tracker hooks install without a ScrollFrame viewport")
has(otScrollSrc, "deferDirtyUntilRegen(tracker, orig)", "combat tracker dirty update waits for regen")
if otScrollSrc:find("securecallfunction(orig)", 1, true) then
	failures[#failures + 1] = "combat tracker dirty update must not securecallfunction into RightManagedFrameContainer:SetSize"
end
has(otScrollSrc, "wrapBuildQuestWatchInfos", "Forever watch-info sort/classification throws fall back to the watch list")
has(otScrollSrc, "wrapUpdateSingle", "Forever UpdateSingle pcall keeps enumerating after a cold-login throw")
has(otScrollSrc, "wrapLayoutContents", "Forever LayoutContents is pcall-wrapped so Container.Update can finish")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:StartForeverLoginPulse", "Forever login pulse clears stuck dirty without calling Update")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:EnsureViewport", "live and Forever share the scroll viewport")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:ReadyForScrollDock", "Forever scroll dock waits for Manager.Init and a non-zero height")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:KickScrollLayoutOnce", "first pin kicks Blizzard layout without calling Update")
has(otScrollSrc, "local function scrollByWheel", "wheel scrolls the objective body with SetVerticalScroll")
has(otScrollSrc, "bindScrollWheel(tracker)", "wheel works over objective rows")
has(otScrollSrc, "bindScrollWheel(outerViewport)", "wheel works over the All Objectives header")
has(otScrollSrc, "UpdateScrollChildRect", "scroll range follows the module stack")
has(otScrollSrc, "WHEEL_STEP = 30", "wheel step matches ScrollFrame_OnLoad")
has(otScrollSrc, "isAnchoredTopRight", "scroll dock skips ClearAllPoints when already TOPRIGHT")
has(minimapSrc, "_fluxDockSnap", "tracker dock snapshot skips unchanged tab-switch relayout")
has(otScrollSrc, "kickForeverQuestLayout", "Forever login pulse nudges Blizzard via SortQuestWatches")
has(otScrollSrc, "hookForeverManagerInit", "Forever docks after ObjectiveTrackerManager.Init")
has(otScrollSrc, "FOREVER_CLIP_LEFT_BLEED", "Forever clip is wider on the left so NineSlice/POI are not cut off")
has(otScrollSrc, 'questLogDirtyWatch:RegisterEvent("QUEST_LOG_UPDATE")', "Forever QUEST_LOG_UPDATE watcher recovers stuck dirty before Blizzard MarkDirty")
has(otScrollSrc, 'EventUtil.ContinueOnAddOnLoaded("Blizzard_ObjectiveTracker"', "Forever guards install when Blizzard_ObjectiveTracker loads")
has(otScrollSrc, "tryInstallForeverCompat", "Forever guards install at file load if the tracker already exists")
if otScrollSrc:find("function InputUtil.IsGamepadUIEnabled", 1, true) then
	failures[#failures + 1] = "must not replace InputUtil.IsGamepadUIEnabled (SetPreferredGamepadInteractTarget taint)"
end
if otScrollSrc:find("function FluxObjectiveTrackerScroll:EnsureForeverClip", 1, true) then
	failures[#failures + 1] = "Forever clip dock must be gone; both clients use EnsureViewport"
end
if otScrollSrc:find("function FluxObjectiveTrackerScroll:ApplyForeverClipSize", 1, true) then
	failures[#failures + 1] = "Forever clip sizing must be gone; ApplyViewportSize sizes the shared viewport"
end
if otScrollSrc:find("NineSlice:GetBottom()", 1, true) then
	failures[#failures + 1] = "content height must not use NineSlice GetTop/GetBottom (viewport scale clips quests)"
end
if otScrollSrc:find("isInDefaultPosition = false", 1, true) then
	failures[#failures + 1] = "must not write isInDefaultPosition (InitSystemAnchors MainActionBar:SetPointBase taint)"
end
if otScrollSrc:find("function ObjectiveTrackerFrame:GetAvailableHeight()", 1, true) then
	failures[#failures + 1] = "must not replace GetAvailableHeight (ShouldShowMawBuffs GetAuraDataByIndex taint)"
end
if otScrollSrc:find("function ObjectiveTrackerFrame:UpdateTopPadding()", 1, true) then
	failures[#failures + 1] = "must not replace UpdateTopPadding (ShouldShowMawBuffs GetAuraDataByIndex taint)"
end
if otScrollSrc:find("ObjectiveTrackerContainerMixin.UpdateTopPadding =", 1, true) then
	failures[#failures + 1] = "must not replace mixin UpdateTopPadding"
end
if otScrollSrc:find("ObjectiveTrackerFrameMixin.Update =", 1, true) then
	failures[#failures + 1] = "must not replace ObjectiveTrackerFrameMixin.Update"
end
has(otScrollSrc, "function FluxObjectiveTrackerScroll:ReassertDock", "Edit Mode spec/level reparents the tracker; Flux reasserts the clip only")
has(otScrollSrc, 'hooksecurefunc(ObjectiveTrackerFrame, "ApplySystemAnchor"', "tracker dock reassert is after ApplySystemAnchor, not inside InitSystemAnchors")
has(otScrollSrc, "tracker:GetParent() == scrollContent", "PinLayoutHeight only while the scroll child still parents the tracker")
has(otScrollSrc, 'hooksecurefunc(ObjectiveTrackerFrame, "UpdateTopPadding"', "Forever UpdateTopPadding is after-only so Update stays untainted")
if minimapSrc:find("landingBtn:RefreshButton()", 1, true) and not minimapSrc:find("landingBtn.RefreshButton and ExpansionLandingPage", 1, true) then
	failures[#failures + 1] = "minimap RefreshButton must require ExpansionLandingPage"
end

local flyoutSecure = read("../ExtraButtonSystem/FlyoutEngine/Secure.lua")
has(flyoutSecure, "if Restricted and Restricted.Works and not Restricted.Works() then", "flyout kid WrapScript skipped on camelot")

local threatSrc = read("API/Threat.lua")
has(threatSrc, "function Threat.GetPercentageOfLead", "Flux.Threat wraps UnitThreatPercentageOfLead")
has(threatSrc, "function Threat.GetLeadSituation", "Flux.Threat wraps UnitThreatLeadSituation")
has(threatSrc, "function Threat.GetForeverFrameDisplay", "Forever frames use rawPercentage or lead % while tanking")
has(threatSrc, "function Threat.GetForeverNameplateStatus", "Forever nameplates use situation or lead situation")
has(threatSrc, "function Threat.IsNameplateThreatTarget", "nameplate threat requires the mob in combat and on the player threat list")
has(threatSrc, "function Threat.GetNumericDisplay", "Flux.Threat numeric display")
has(threatSrc, "tank-relative scaled %", "Flux.Threat uses tank-relative scaled % not lead %")
has(threatSrc, "function Threat.GetTintColor", "Flux.Threat nameplate tint: 100%/tanking/rank 1 is red")
has(threatSrc, "tankingSecret", "GetNumericDisplay must not force status 2 when isTanking is secret")
has(threatSrc, "function Threat.SetBarValue", "Flux.Threat SetValue path for secret percents")
has(threatSrc, "function Threat.GetPlayerRank", "Flux.Threat computes group placement")
has(threatSrc, 'NUMERIC_THREAT_CVAR = "threatShowNumeric"', "Flux.Threat reads threatShowNumeric")
has(threatSrc, "function Threat.NameplateDisplayEnabled", "Flux.Threat reads nameplateThreatDisplay")
has(threatSrc, "function Threat.SetNameplateDisplay", "Flux.Threat writes nameplateThreatDisplay bits")
has(threatSrc, "function Threat.GetNameplateDisplayMask", "Flux.Threat exposes nameplate threat mask")
has(threatSrc, "function Threat.HasWarningCVar", "Flux.Threat probes threatWarning CVar")
has(threatSrc, "Keeps secret threat rows", "GetPlayerRank keeps secret threat rows")
has(threatSrc, "tanking is always placement 1", "GetPlayerRank returns 1 while tanking")
has(threatSrc, "function Threat.ShouldDownscaleValues", "Flux.Threat skips Classic /100 on Midnight/Forever")
has(threatSrc, "SetFormattedText", "Flux.Threat displays secret percents via SetFormattedText")
has(threatSrc, "Assign inside the protected call", "Flux.Threat captures secret multi-returns inside pcall")
if threatSrc:find("string.format(\"%1.0f\"", 1, true) then
	failures[#failures + 1] = "Flux.Threat must not string.format secret threat percents"
end
do
	local start = threatSrc:find("function Threat.GetNumericDisplay", 1, true)
	local stop = threatSrc:find("function Threat.ShouldShowNumericOnUnit", 1, true)
	if start and stop then
		local body = threatSrc:sub(start, stop)
		if body:find("GetPercentageOfLead", 1, true) then
			failures[#failures + 1] = "GetNumericDisplay must not use UnitThreatPercentageOfLead (255% while tanking)"
		end
	else
		failures[#failures + 1] = "GetNumericDisplay smoke window missing"
	end
end
if threatSrc:find("return true  -- abort", 1, true) or threatSrc:find("abort entire rank", 1, true) then
	failures[#failures + 1] = "GetPlayerRank must not abort the whole list on secret threat"
end
local rankStart = threatSrc:find("function Threat.GetPlayerRank", 1, true)
local rankStop = threatSrc:find("function Threat.GetMeterRow", 1, true)
if rankStart and rankStop then
	local body = threatSrc:sub(rankStart, rankStop)
	if not body:find("HasThreatPayload", 1, true) then
		failures[#failures + 1] = "GetPlayerRank must keep secret threat payloads"
	end
	if body:find("if not value or value <= 0 then", 1, true) then
		failures[#failures + 1] = "GetPlayerRank must not drop secret/zero AccessibleNumber rows"
	end
end
local cvarSrc = read("API/CVar.lua")
has(cvarSrc, "function CVar.SetBitfield", "CVar.SetBitfield for nameplateThreatDisplay carve-out")
has(cvarSrc, "function CVar.IsThreatBitfieldCVar", "nameplateThreatDisplay is the only post-DF nameplate bitfield write")
if cvarSrc:find('string.lower(cvar) == "nameplatethreatdisplay"', 1, true) == nil then
	failures[#failures + 1] = "CVar threat bitfield carve-out must be nameplateThreatDisplay only"
end
do
	local threatI = toc:find("Core\\API\\Threat.lua", 1, true)
	local secretsI = toc:find("Core\\API\\Secrets.lua", 1, true)
	if threatI and secretsI and threatI < secretsI then
		failures[#failures + 1] = "Threat.lua must load after Secrets.lua"
	end
end

local addOnSrc = read("API/AddOn.lua")
has(addOnSrc, "function AddOn.Exists(", "AddOn.Exists probes DoesAddOnExist")
has(addOnSrc, "GetNumAddOns", "AddOn.Exists scans GetNumAddOns")
has(addOnSrc, "function AddOn.IsLoadable(", "AddOn.IsLoadable")

local meterLayoutSrc = read("../Battlezonemap/FluxMeterLayout.lua")
has(meterLayoutSrc, 'BLIZZARD_METER_ADDON = "Blizzard_DamageMeter"', "blizzard meter probe names Blizzard_DamageMeter")
has(meterLayoutSrc, "GetNumAddOns", "blizzard meter scans registered addon list")
has(meterLayoutSrc, "C_DamageMeter.IsDamageMeterAvailable", "blizzard meter requires C_DamageMeter")
has(meterLayoutSrc, "Details wins when both exist", "meter tab is Details XOR Blizzard")
if meterLayoutSrc:find("return _G.Details ~= nil", 1, true) then
	failures[#failures + 1] = "Details backend must require the Details addon to be loaded"
end
if meterLayoutSrc:find("FLUX_API.isMidnight == true", 1, true)
	or meterLayoutSrc:find("FLUX_API.isCamelot == true", 1, true)
	or meterLayoutSrc:find("FLUX_API.isV12 == true", 1, true) then
	failures[#failures + 1] = "HasBlizzardDamageMeterClient must probe Blizzard_DamageMeter, not version flags"
end

local blizzMeterSrc = read("../Battlezonemap/FluxBlizzardMeter.lua")
if blizzMeterSrc:find("FLUX_API.isMidnight == true", 1, true)
	or blizzMeterSrc:find("FLUX_API.isV12 == true", 1, true) then
	failures[#failures + 1] = "FluxBlizzardMeter must not use version flags for support"
end
has(blizzMeterSrc, "IsDetailsAddonLoaded()", "blizzard embed refuses Details")
has(blizzMeterSrc, "if ForeverGamepadEmbed() then\n            return false", "Forever gamepad does not create damage meter panes")
has(blizzMeterSrc, "if not ForeverGamepadEmbed() and dmFrame.SetSessionWindowLocked then", "Forever gamepad does not relock meter windows")
has(blizzMeterSrc, 'dmFrame:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)', "damage meter stays centered on the Flux window")
do
	local applyAt = blizzMeterSrc:find("local function ApplyRootScaleAndSize", 1, true)
	local nextAt = applyAt and blizzMeterSrc:find("local function ConfigureSessionWindowChrome", applyAt, true)
	local block = applyAt and nextAt and blizzMeterSrc:sub(applyAt, nextAt) or ""
	local foreverAt = block:find("if ForeverGamepadEmbed() then", 1, true)
	local pointAt = foreverAt and block:find('dmFrame:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)', foreverAt, true)
	local retAt = pointAt and block:find("\n        return\n", pointAt, true)
	local parentAt = block:find("dmFrame:SetParent(parentFrame)", 1, true)
	if not foreverAt or not pointAt or not retAt or not parentAt or not (foreverAt < pointAt and pointAt < retAt and retAt < parentAt) then
		failures[#failures + 1] = "Forever gamepad anchors the meter to the Flux window without SetParent"
	end
end
if blizzMeterSrc:find("PlaceSessionWindowUIParent", 1, true) or blizzMeterSrc:find("MeterCanvasUIParent", 1, true) then
	failures[#failures + 1] = "session windows must stay inside the damage meter, not on UIParent"
end
do
	local hookFn = blizzMeterSrc:find("local function HookSessionWindow", 1, true)
	local hookScript = hookFn and blizzMeterSrc:find("sessionWindow:HookScript", hookFn, true)
	local foreverAt = hookFn and blizzMeterSrc:find("if ForeverGamepadEmbed() then", hookFn, true)
	local retAt = foreverAt and hookScript and blizzMeterSrc:find("\n        return\n", foreverAt, true)
	if not foreverAt or not retAt or not hookScript or not (foreverAt < retAt and retAt < hookScript) then
		failures[#failures + 1] = "Forever gamepad must not HookScript a damage meter session window"
	end
end
local spellSlots = read("../AddonOptions/AceGUIWidget-FluxSpellBookSlotsPanel.lua")
do
	local fnAt = spellSlots:find("local function OpenContextMenu", 1, true)
	local gateAt = fnAt and spellSlots:find("if ForeverGamepadUI() then", fnAt, true)
	local menuAt = fnAt and spellSlots:find("MenuUtil.CreateContextMenu", fnAt, true)
	if not gateAt or not menuAt or gateAt > menuAt then
		failures[#failures + 1] = "Forever gamepad spell slots must not open a Blizzard context menu"
	end
end
local vehicleSrc = read("../Other/FluxVehicleSeats.lua")
has(vehicleSrc, "if not ForeverGamepadUI() and MenuUtil and MenuUtil.CreateContextMenu", "Forever gamepad vehicle seats skip the context menu")
if blizzMeterSrc:find('LoadAddOn("Blizzard_DamageMeter")', 1, true)
	or blizzMeterSrc:find('C_AddOns.LoadAddOn("Blizzard_DamageMeter")', 1, true) then
	failures[#failures + 1] = "must not LoadAddOn Blizzard_DamageMeter (InitSystemAnchors MainActionBar:SetPointBase taint)"
end

local optionsBz = read("../AddonOptions/FluxOptionsBattlezone.lua")
if optionsBz:find("C_DamageMeter or FluxBlizzardMeter", 1, true) then
	failures[#failures + 1] = "options must not treat FluxBlizzardMeter module as a live Blizzard meter"
end
has(optionsBz, "when this client ships Blizzard", "options copy matches addon-list detection")

local tocSrc = read("../_FluxUI.toc")
has(tocSrc, "CharacterInfo\\Init.lua", "TOC loads CharacterInfo module")
has(tocSrc, "## Dep: Blizzard_CombatLog [AllowLoadGameType camelot]", "Forever loads the combat log before FluxUI (login ClearEventFilters)")
if tocSrc:find("LoginAddonLoadGate", 1, true) or read("LoginAddonLoadGate.lua") ~= "" then
	failures[#failures + 1] = "login addon-load gate must stay removed"
end
do
	local fluxSrc = read("Flux.lua")
	has(fluxSrc, "function DeferModuleEnableForGamepadSetup()", "Forever defers module enable past VARIABLES_LOADED")
	has(fluxSrc, "FireDeferredModuleEnable", "deferred enable is the frame after the gamepad bar setup")
	if fluxSrc:find("Flux.loggedIn = true\n\t\t\tRunQueue(loginQueue)", 1, true) then
		failures[#failures + 1] = "reload must not enable modules inside ADDON_LOADED (SetPreferredGamepadInteractTarget)"
	end
	for _, src in ipairs({ fluxSrc, camelotSrc }) do
		if src:find("index.RegisterEvent", 1, true) or src:find("index.UnregisterEvent", 1, true)
			or src:find("InstallLoginAddonLoadWatch", 1, true) or src:find("RestoreLoginAddonLoads", 1, true) then
			failures[#failures + 1] = "Flux must not write shared frame methods or replay login events"
			break
		end
	end
end
has(tocSrc, "CharacterInfo\\RetailPane.lua", "TOC loads Live/Forever pane hooks")
if tocSrc:find("Other\\FluxCharacterStats\\FluxCharacterStatsShared.lua", 1, true) then
	failures[#failures + 1] = "TOC must not load the old FluxCharacterStats dump"
end

local ciInit = read("../CharacterInfo/Init.lua")
has(ciInit, 'Flux.Module.Register("CharacterInfo"', "CharacterInfo registers as a Flux.Module")
has(ciInit, "IsCharacterUiAddon", "CharacterInfo waits for the real character addon")

local ciShared = read("../CharacterInfo/Shared.lua")
has(ciShared, "Blizzard_CharacterFrame", "CharacterInfo recognizes Blizzard_CharacterFrame")
has(ciShared, "Blizzard_UIPanels_Game", "CharacterInfo recognizes Blizzard_UIPanels_Game")

local ciRetail = read("../CharacterInfo/RetailPane.lua")
has(ciRetail, "CharacterStatsPaneScrollBox", "Retail pane hooks Forever ScrollBox")
has(ciRetail, "CharacterStatsPanePetScrollBox", "Retail pane skips Forever pet stats")
has(ciRetail, 'statFrame.Value:SetFormattedText("%.1f"', "Retail pane formats ilvl as X.Y")

local infoSrc = read("../StatusBars/FluxInfoFrame.lua")
has(infoSrc, "InstallCharacterInfoPinHooks", "Info Frame pin installer is retryable")
has(infoSrc, "CharacterStatsPaneScrollBox", "Info Frame pins Forever ScrollBox rows")
has(infoSrc, "CharacterStatsPanePetScrollBox", "Info Frame does not pin Forever pet stats")
has(infoSrc, "HookForeverScrollBoxStatFrame", "Info Frame has Forever ScrollBox pin API")
has(infoSrc, "ReadForeverDisplayText", "Info Frame copies Forever paperdoll values when APIs are empty")
has(infoSrc, "INVTYPE_WEAPONMAINHAND", "Forever Main Hand maps to weapon damage")
has(infoSrc, "STAT_MOVEMENT_SPEED", "Forever movement speed maps off CR_SPEED")
has(infoSrc, "GetView", "Forever pin walk uses ScrollBox GetView/GetFrames")
has(infoSrc, "CharacterStatFrameScrollBoxBaseElementMixin", "Info Frame hooks Forever row Init")

local capSrc2 = read("Capabilities.lua")
has(capSrc2, "function Cap.RefreshCharacterInfo()", "Capabilities probe character-info frames")
has(capSrc2, "function Cap.UsesPlayerBagsInBank()", "Forever bags-in-bank is a capability")
has(capSrc2, "C_Bank.ShouldUsePlayerBagsInBank", "UsesPlayerBagsInBank probes the Camelot C_Bank API")
has(capSrc2, "function Cap.EnumerateBankTabIDs(", "bank tabs walk CharacterBankTab_N / AccountBankTab_N")
has(capSrc2, "for i = 1, 32 do", "tab enum walks until nil, not hardcoded 6/5")
has(capSrc2, "function Cap.HasReagentBankContainer()", "reagent bank is not Accountbanktab -3")
has(capSrc2, "function Cap.IsBankTabSentinel(", "Forever Characterbanktab/Accountbanktab are sentinels")
has(legacyCap, "function FLUX_API.UsesPlayerBagsInBank()", "Legacy forwards UsesPlayerBagsInBank")
has(legacyCap, "function FLUX_API.EnumerateBankTabIDs(", "Legacy forwards EnumerateBankTabIDs")
has(legacyCap, "function FLUX_API.HasReagentBankContainer()", "Legacy forwards HasReagentBankContainer")

local invContainers = read("../Inventory/Containers.lua")
has(invContainers, "Cap.EnumerateBankTabIDs", "inventory bank IDs use capability enumerator")
has(invContainers, "Cap.IsBankTabSentinel", "inventory skips Forever bank-tab sentinels")
if invContainers:find("REAGENTBANK_CONTAINER or -3", 1, true) then
	failures[#failures + 1] = "Containers must not treat -3 as reagent bank (Forever Accountbanktab)"
end
if invContainers:find("KEYRING_CONTAINER or -2", 1, true) then
	failures[#failures + 1] = "Containers must not treat missing KEYRING_CONTAINER as -2 on unified UI"
end
if invContainers:find("for i = 1, 6 do", 1, true) then
	failures[#failures + 1] = "Containers must not hardcode 6 character bank tabs"
end
if invContainers:find("for i = 1, 5 do", 1, true) then
	failures[#failures + 1] = "Containers must not hardcode 5 warband bank tabs"
end

local invWatch = read("../Inventory/Builtin/Watch.lua")
has(invWatch, "OnBankTabsChanged", "BANK_TABS_CHANGED invalidates container IDs")
has(invWatch, "IsUnifiedBankTabBag", "unknown unified tab bags are not scanned as carried bags")

local restockInv = read("../Inventory/Restock/FluxRestock_Inv.lua")
has(restockInv, "if Bank.IsModernBank() then", "HasLegacyBankBags is false on unified/Forever bank")
if restockInv:find("REAGENTBANK_CONTAINER or -3", 1, true) then
	failures[#failures + 1] = "FluxRestock_Inv must not fallback reagent bank to -3"
end

local restockBtn = read("../Inventory/Restock/Bank/FluxBankRestockButton.lua")
has(restockBtn, "GetBagsInBankButtonPlacement", "Camelot restock button has its own placement")
has(restockBtn, "BankItemSearchBox", "Camelot restock anchors by the bank search box")
has(restockBtn, "UsesPlayerBagsInBank()", "bags-in-bank placement is capability-gated")

local junkOverlay = read("../Inventory/Restock/Junk/FluxJunkOverlay.lua")
has(junkOverlay, "BankPanelMixin.PageSelected", "junk overlay repaints on Camelot page changes")
has(junkOverlay, "BankPanelMixin.PageInfoChanged", "junk overlay repaints after Camelot page info")
has(junkOverlay, "IsBankBagSlotButton", "junk overlay never paints equipped bank-bag slots")
has(junkOverlay, "Do not hook CamelotBankPanelItemButtonMixin.Refresh", "junk overlay must not hook Camelot atlas Refresh")
if junkOverlay:find("hooksecurefunc(CamelotBankPanelItemButtonMixin", 1, true)
	or junkOverlay:find("hooksecurefunc(_G.CamelotBankPanelItemButtonMixin", 1, true) then
	failures[#failures + 1] = "junk overlay must not hooksecurefunc CamelotBankPanelItemButtonMixin"
end

local wmEngine = read("../WindowMover/Engine.lua")
has(wmEngine, "function ResolveDynamicSize(", "window mover resolves catalog dynamicSize")
has(wmEngine, "if not dynamicSize then", "Camelot BankFrame skips SetPoint/SetScale wraps")
has(wmEngine, "NameIsDynamicSize(name)", "dynamic-size frames skip scale and layout reapply")

local wmCatalog = read("../WindowMover/Catalog.lua")
has(wmCatalog, "UsesPlayerBagsInBank", "BankFrame dynamicSize probes Camelot bags-in-bank")

-- Forever gamepad UI: Blizzard's panel/bag/binding flow ends in the protected
-- SetPreferredGamepadInteractTarget(). No Flux code may run inside it.
local capSrc = read("Capabilities.lua")
has(capSrc, "function Cap.IsForeverGamepadUI()", "Forever gamepad UI probe exists")
has(capSrc, "_G.FluxUI_IsForeverGamepadUI = Cap.IsForeverGamepadUI", "Forever gamepad probe exported for legacy-style files")
has(capSrc, '"INPUT_DEVICE_INTERFACE_TRANSITION"', "gamepad style switch asks for a reload")
if capSrc:find("InputUtil.Register", 1, true) then
	failures[#failures + 1] = "Capabilities must not use InputUtil's transition registry"
end
do
	local capAt = toc:find("Core\\Capabilities.lua", 1, true)
	local proxyAt = toc:find("Core\\SecureClickProxy.lua", 1, true)
	if not capAt or not proxyAt or proxyAt < capAt then
		failures[#failures + 1] = "TOC loads SecureClickProxy after Capabilities"
	end
end
local proxySrc = read("SecureClickProxy.lua")
has(proxySrc, '"SecureActionButtonTemplate"', "click proxy is a secure action button")
has(proxySrc, 'SetAttribute("type", "click")', "click proxy uses the secure click action")
has(proxySrc, 'CreateFrame, "Button", nil, UIParent', "click proxy is parented to UIParent")
has(proxySrc, 'SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT"', "click proxy is placed in UIParent space")
if proxySrc:find("SetAllPoints(owner", 1, true) or proxySrc:find(", owner, ", 1, true) then
	failures[#failures + 1] = "click proxy must not anchor to its FluxUI owner (makes it protected in combat)"
end
if proxySrc:find("button:SetScript", 1, true) or proxySrc:find("button:HookScript", 1, true) then
	failures[#failures + 1] = "click proxy must not set scripts on the secure button (taints CharacterFrame secret health)"
end
has(proxySrc, "watcher:SetScript(\"OnUpdate\", Poll)", "click proxy polls hover off the secure button")

if wmEngine:find("frame[method] = function", 1, true) then
	failures[#failures + 1] = "WindowMover must post-hook SetPoint/SetScale, not replace them (gamepad taint)"
end
has(wmEngine, "pcall(hooksecurefunc, frame, method,", "WindowMover hooks layout with hooksecurefunc")
has(wmEngine, "if suppressed[name] or ForeverGamepadBag(name) then", "WindowMover leaves Forever's gamepad bag alone")
has(wmCatalog, "if cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() then", "Forever gamepad UI skips WindowMover attach")
do
	local attachAt = wmEngine:find("function WindowMover.Attach(entry)", 1, true)
	local secretAt = attachAt and wmEngine:find('name == "CharacterFrame"', attachAt, true)
	local showHookAt = attachAt and wmEngine:find('frame:HookScript("OnShow"', attachAt, true)
	if not secretAt or not showHookAt or secretAt > showHookAt then
		failures[#failures + 1] = "Forever CharacterFrame must not HookScript OnShow (secret health text)"
	end
	local hookAt = wmEngine:find("local function HookLayout", 1, true)
	local gateAt = hookAt and wmEngine:find("cap.IsForeverGamepadUI()", hookAt, true)
	local wrapAt = hookAt and wmEngine:find("pcall(hooksecurefunc, frame, method,", hookAt, true)
	if not gateAt or not wrapAt or gateAt > wrapAt then
		failures[#failures + 1] = "WindowMover must not hook SetPoint while Forever gamepad UI is on"
	end
end

local flyoutSrc = read("../CharacterInfo/PaperDollEquipFlyout.lua")
do
	local installAt = flyoutSrc:find("local function InstallPanelHooks", 1, true)
	local gateAt = installAt and flyoutSrc:find("if not IsForeverClient() then", installAt, true)
	local hookAt = installAt and flyoutSrc:find('pd:HookScript("OnHide"', installAt, true)
	if not gateAt or not hookAt or gateAt > hookAt then
		failures[#failures + 1] = "Forever must not HookScript PaperDollFrame or CharacterFrame for the equip flyout"
	end
	has(flyoutSrc, "if IsForeverClient() and not PaperDollPanelShown() then", "equip flyout closes from the mouseover watcher on Forever")
end

local infoSrc = read("../StatusBars/FluxInfoFrame.lua")
do
	local fnAt = infoSrc:find("function InfoFrame.InstallCharacterInfoPinHooks()", 1, true)
	local gateAt = fnAt and infoSrc:find("client.isCamelot", fnAt, true)
	local hookAt = fnAt and infoSrc:find('_G.CharacterFrame:HookScript("OnShow"', fnAt, true)
	if not gateAt or not hookAt or gateAt > hookAt then
		failures[#failures + 1] = "Forever info pins must not HookScript CharacterFrame OnShow"
	end
end
local guardSrc = read("../Respec/FluxRespec_GearSetEquipGuard.lua")
do
	local fnAt = guardSrc:find("local function InstallCharacterShowHook()", 1, true)
	local gateAt = fnAt and guardSrc:find("if IsCamelotClient() then", fnAt, true)
	local hookAt = fnAt and guardSrc:find('frame:HookScript("OnShow"', fnAt, true)
	if not gateAt or not hookAt or gateAt > hookAt then
		failures[#failures + 1] = "Forever gear-set guard must not HookScript CharacterFrame OnShow"
	end
end

local function ForeverBefore(src, fnName, hookNeedle, label)
	local fnAt = src:find(fnName, 1, true)
	local gateAt = fnAt and src:find("client.isCamelot or client.isForever", fnAt, true)
	local hookAt = fnAt and src:find(hookNeedle, fnAt, true)
	if not gateAt or not hookAt or gateAt > hookAt then
		failures[#failures + 1] = label
	end
end

local spellRankSrc = read("../Bars/SpellRank.lua")
ForeverBefore(spellRankSrc, "local function BindSpellBookUI()", 'SpellBookFrame:HookScript("OnShow"', "Forever spell ranks must not HookScript SpellBookFrame")
local mouseoverSrc = read("Engine/MouseoverCast.lua")
ForeverBefore(mouseoverSrc, "local function BindSpellBookUI()", 'SpellBookFrame:HookScript("OnShow"', "Forever mouseover cast must not HookScript SpellBookFrame")
local bindingSpellSrc = read("../Binding/UI/SpellbookBindingHooks.lua")
ForeverBefore(bindingSpellSrc, "initFrame.__fluxBindingSpellbookHooks = true", 'SpellBookFrame:HookScript("OnShow"', "Forever binding spellbook must not HookScript SpellBookFrame")
local settingsSrc = read("../FluxDefaultSettings.lua")
ForeverBefore(settingsSrc, "local function FluxEnsureSettingsPanelNameplateFlushHook()", 'SettingsPanel:HookScript("OnHide"', "Forever defaults must not HookScript SettingsPanel")
local writeSrc = read("BlizzardSettings/Write.lua")
if writeSrc == "" then
	writeSrc = read("../BlizzardSettings/Write.lua")
end
ForeverBefore(writeSrc, "local function HookSettingsPanel()", 'SettingsPanel:HookScript("OnHide"', "Forever settings writes must not HookScript SettingsPanel")

has(junkOverlay, "if not frame or ForeverGamepadUI() then", "junk overlay paints no Blizzard bag in Forever gamepad UI")
do
	local refreshAt = junkOverlay:find("local function RefreshBagContainersForPaint", 1, true)
	local gateAt = refreshAt and junkOverlay:find("if ForeverGamepadUI() then", refreshAt, true)
	local updateAt = refreshAt and junkOverlay:find("pcall(_G.ContainerFrameCombinedBags.Update", refreshAt, true)
	if not gateAt or not updateAt or gateAt > updateAt then
		failures[#failures + 1] = "junk overlay must not call the bag's Update in Forever gamepad UI"
	end
end
local ledgerSrc = read("../StatusBars/FluxGoldLedger.lua")
has(ledgerSrc, "moneyFrame.FluxLedgerHooked or ForeverGamepadUI()", "gold ledger skips the bag money frame in Forever gamepad UI")

do
	local guardsAt = otScrollSrc:find("local function installForeverQuestLayoutGuards", 1, true)
	local gateAt = guardsAt and otScrollSrc:find("FluxUI_IsForeverGamepadUI()", guardsAt, true)
	local titleAt = guardsAt and otScrollSrc:find("_G.SetQuestTitleLevelAndDifficultyColor = function", guardsAt, true)
	if not gateAt or not titleAt or gateAt > titleAt then
		failures[#failures + 1] = "Forever quest-tracker wrappers must not install in gamepad UI"
	end
	local patchAt = otScrollSrc:find("local function installForeverHighlightPatch", 1, true)
	local patchGateAt = patchAt and otScrollSrc:find("FluxUI_IsForeverGamepadUI()", patchAt, true)
	local replaceAt = patchAt and otScrollSrc:find("function ObjectiveTrackerBlockMixin:UpdateHighlight", patchAt, true)
	if not patchGateAt or not replaceAt or patchGateAt > replaceAt then
		failures[#failures + 1] = "Forever block highlight patch must not install in gamepad UI"
	end
end

local statusSrc = read("../StatusBars/FluxStatusBar.lua")
has(statusSrc, "local function CanOpenCurrencyTab()", "gold bar currency shortcut is gated")
has(statusSrc, "and not IsForeverClient()", "Forever gold bar never calls ToggleCharacter")
has(statusSrc, "proxy.Attach(RepBar", "Forever rep bar opens Character Info by secure click")
do
	local openAt = statusSrc:find("local function OpenReputationFrame()", 1, true)
	local gateAt = openAt and statusSrc:find("if IsForeverClient() then", openAt, true)
	local toggleAt = openAt and statusSrc:find('ToggleCharacter("ReputationFrame")', openAt, true)
	if not gateAt or not toggleAt or gateAt > toggleAt then
		failures[#failures + 1] = "Forever rep bar must not call ToggleCharacter"
	end
end

local dropdownSrc = read("FluxBlizzardDropdown.lua")
has(dropdownSrc, "function DD.WantsGamepadMenu", "Flux dropdowns can request Blizzard's gamepad menu off Forever gamepad")
if dropdownSrc:find("TreatAsCore", 1, true) or dropdownSrc:find("function PromptedBindingFooterMixin:RefreshBindingGroup", 1, true) then
	failures[#failures + 1] = "Flux must not rewrite gamepad binding sets (taints secure bag open)"
end
has(dropdownSrc, "function DD.InstallGamepadClick", "shared dropdown click hook point")
do
	local wantsAt = dropdownSrc:find("function DD.WantsGamepadMenu", 1, true)
	local classicAt = wantsAt and dropdownSrc:find("if DD.UseClassicMenu() then", wantsAt, true)
	local respecAt = wantsAt and dropdownSrc:find('name:find("FluxRespec"', wantsAt, true)
	if not classicAt or not respecAt or classicAt > respecAt then
		failures[#failures + 1] = "Forever gamepad must not force Respec onto a DropdownButton"
	end
end
do
	local createAt = dropdownSrc:find("function DD.Create", 1, true)
	local gateAt = createAt and dropdownSrc:find("if DD.WantsGamepadMenu(name, opts) or not DD.UseClassicMenu() then", createAt, true)
	local frameAt = createAt and dropdownSrc:find('CreateFrame, "DropdownButton"', createAt, true)
	if not gateAt or not frameAt or gateAt > frameAt then
		failures[#failures + 1] = "dropdown create must keep the classic-menu gate before DropdownButton"
	end
end
if dropdownSrc:find("function mixin:OnMouseDown_Intrinsic", 1, true)
	or dropdownSrc:find("securecallfunction(intrinsicOrig", 1, true)
	or dropdownSrc:find('dropdown:SetScript("OnMouseDown"', 1, true) then
	failures[#failures + 1] = "Flux must not wrap DropdownButton OnMouseDown (securecallfunction still taints SetPreferredGamepadInteractTarget)"
end
if dropdownSrc:find("DD.ToggleSafeList", 1, true) or dropdownSrc:find("_fluxCover", 1, true) then
	failures[#failures + 1] = "Flux dropdown must stay on Blizzard's menu"
end
if dropdownSrc:find(":OpenMenu", 1, true) or dropdownSrc:find("OpenMenu(", 1, true) then
	failures[#failures + 1] = "Flux dropdown must not call OpenMenu"
end
local optionsWidgets = read("../AddonOptions/FluxOptionsWidgets.lua")
do
	local fnAt = optionsWidgets:find("local function CreateModernDropdown", 1, true)
	local guardAt = fnAt and optionsWidgets:find("cap.IsForeverGamepadUI()", fnAt, true)
	local frameAt = fnAt and optionsWidgets:find('CreateFrame, "DropdownButton"', fnAt, true)
	if not guardAt or not frameAt or guardAt > frameAt then
		failures[#failures + 1] = "Forever gamepad options must not create a DropdownButton"
	end
end
has(optionsWidgets, 'CreateFrame, "DropdownButton"', "options dropdowns create a DropdownButton off Forever gamepad")
local aceDropdown = read("../Binding/UI/Editor/Widgets/AceGUIWidget-FluxBlizzardDropdown.lua")
has(aceDropdown, "DD.UseClassicMenu", "binding dropdown uses the classic menu on Forever gamepad")
do
	local ctorAt = aceDropdown:find("local function Constructor()", 1, true)
	local gateAt = ctorAt and aceDropdown:find("if not classic then", ctorAt, true)
	local frameAt = ctorAt and aceDropdown:find('CreateFrame, "DropdownButton"', ctorAt, true)
	if not gateAt or not frameAt or gateAt > frameAt then
		failures[#failures + 1] = "Forever gamepad binding dropdown must not create a DropdownButton"
	end
end

if #failures > 0 then
	io.stderr:write("core smoke FAILED (" .. tostring(#failures) .. ")\n")
	for i = 1, #failures do
		io.stderr:write("  " .. failures[i] .. "\n")
	end
	os.exit(1)
end

print("core smoke OK")
print("  scheduler: layout → display → eval; paging defers eval/display")
print("  modifier: FluxModifierTracker alias, demand-driven OnUpdate")
print("  context: kinded fingerprint bus on display tier")
print("  identity: shown-face publish + last-sig skip")
print("  occupancy: type+id only, no GetMacroSpell")
print("  formstorm: IsBursting / IsSettling / GetSnapshot")
print("  hoplag: /fluxhop overlay, off by default")
print("  aura: slots/index gate on CanAccessSecrets; GetPlayerAuraBySpellID does not")
print("  secrets: SafeBooleanTest/SafeLooksEmpty/AuraUpdateInfoIsNoop/KeepLastNumber")
print("  swing: gated off live post-DF + post-Cata classic; Forever uses PLAYER_SWING; CLEU + DurationUtil probed")
