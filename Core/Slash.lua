-- Slash.lua — /fluxapi, /fluxperf and /fluxclick
local addonName, ns = ...
local Flux = ns.Flux

local function yn(v)
	return v and "yes" or "no"
end

local function PrintApi()
	local C = Flux.Client
	local Cap = Flux.Cap
	local S = Flux.Secrets
	Flux.Print("Detected APIs")
	print("  Version: " .. tostring(C.majorVersion) .. "." .. tostring(C.minorVersion) .. "." .. tostring(C.patchVersion)
		.. " | Build: " .. tostring(C.buildNumber) .. " | TOC: " .. tostring(C.uiVersion))
	print("  Flavor: " .. tostring(C.flavor) .. " | Expansion: " .. tostring(C.expansion)
		.. " | gameType: " .. tostring(C.gameType))
	print("  isRetail: " .. yn(C.isRetail) .. " | isCamelot/Forever: " .. yn(C.isCamelot)
		.. " | isLiveMidnight: " .. yn(C.isLiveMidnight)
		.. " | spellRanks: " .. yn(Cap.supportsPerRankSpellBarFeatures))
	print("  isEra: " .. yn(C.isEra) .. " | isAnniversary: " .. yn(C.isAnniversary)
		.. " | isMists: " .. yn(C.isMists))
	print("  isMidnight: " .. yn(C.isMidnight) .. " | isV12: " .. yn(C.isV12)
		.. " | isPostDF: " .. yn(C.isPostDF))
	print("  secrets API: " .. yn(Cap.hasSecretValueAPI)
		.. " | canaccessvalue: " .. yn(Cap.hasCanAccessValue)
		.. " | CanAccessSecrets: " .. yn(S and S.CanAccessSecrets and S.CanAccessSecrets()))
	print("  warband: " .. yn(Cap.hasWarbandBank)
		.. " | unifiedBank: " .. yn(Cap.hasUnifiedBankUI)
		.. " | keyring: " .. yn(Cap.hasKeyringContainer)
		.. " | focus: " .. yn(Cap.hasFocusUnit))
	print("  assistedCombat: " .. yn(Cap.hasAssistedCombat)
		.. " | skyriding: " .. yn(Cap.hasSkyriding)
		.. " | swingTimer: " .. yn(Cap.hasSwingTimer)
		.. " | cleu: " .. yn(Cap.hasCombatLogUnfiltered)
		.. " | editMode: " .. yn(Cap.hasEditMode))

	local Opt = Flux.Optional
	if Opt then
		local names = { "Syndicator", "Baganator", "Details", "BigDebuffs", "ConsolePort", "Questie", "TacoTip" }
		local bits = {}
		for i = 1, #names do
			local info = Opt.Get(names[i])
			bits[#bits + 1] = names[i] .. "=" .. (info.ready and "ready" or (info.loaded and "loaded" or "no"))
		end
		print("  optional: " .. table.concat(bits, " | "))
	end

	local mods = Flux.Module and Flux.Module.List() or {}
	print("  feature modules enabled: " .. tostring(#mods == 0 and 0 or (function()
		local n = 0
		for i = 1, #mods do
			if mods[i].enabled then
				n = n + 1
			end
		end
		return n
	end)()) .. " / " .. tostring(#mods))

	local Inv = Flux.Inventory
	local invEnabled = Flux.Module and Flux.Module.IsEnabled and Flux.Module.IsEnabled("Inventory")
	if Inv then
		print("  inventory: " .. (invEnabled and "enabled" or "disabled")
			.. " source=" .. tostring(Inv.GetSource and Inv.GetSource() or "none")
			.. " ready=" .. yn(Inv.IsReady and Inv.IsReady()))
	end

	local EBS = Flux.EBS
	local ebsEnabled = Flux.Module and Flux.Module.IsEnabled and Flux.Module.IsEnabled("ExtraButtons")
	local n = EBS and EBS.ActiveCount and EBS.ActiveCount() or 0
	print("  ebs: " .. (ebsEnabled and "enabled" or "disabled") .. " buttons=" .. tostring(n))
end

local function PrintPerf()
	local snap = Flux.Perf and Flux.Perf.Snapshot() or {}
	Flux.Print("Perf")
	print("  idle: " .. yn(snap.idle)
		.. " | tickerArmed: " .. yn(snap.tickerArmed)
		.. " | tickerCount: " .. tostring(snap.tickerCount)
		.. " | tickerTicks: " .. tostring(snap.tickerTicks))
	print("  timerPolyfill: " .. yn(snap.timerPolyfill)
		.. " | schedulerPending: " .. yn(snap.schedulerPending)
		.. " | paging: " .. yn(snap.paging))
	print("  combatLockdown: " .. yn(snap.combatLockdown)
		.. " | combatPending: " .. tostring(snap.combatPending))
	local st = snap.scheduler or {}
	local tf = st.tierFlushes or {}
	print("  scheduler flushes: " .. tostring(st.flushes or 0)
		.. " | layout=" .. tostring(tf.layout or 0)
		.. " eval=" .. tostring(tf.eval or 0)
		.. " structural=" .. tostring(tf.structural or 0)
		.. " inventory=" .. tostring(tf.inventory or 0))
	print("  deferredEval: " .. tostring(st.deferredEval or 0)
		.. " | deferredStructural: " .. tostring(st.deferredStructural or 0))
	if snap.idle then
		print("  OnUpdate drivers: none armed")
	else
		print("  OnUpdate drivers: ARMED (not idle)")
	end
end

-- ---------------------------------------------------------------------------
-- Secure click contract diagnostics.
--
-- OnClick is deliberately never hooked: it carries the SecureHandlers wrap, and
-- HookScript would replace the wrap closure that UnwrapScript looks for.
-- PreClick/PostClick bracket it safely, and UNIT_SPELLCAST_SENT confirms whether
-- the secure handler actually ran.

local traceLeft = 0
local traceHooked = {}
local traceEvents

local function Attrs(w)
	return "type=" .. tostring(w:GetAttribute("type"))
		.. " typerelease=" .. tostring(w:GetAttribute("typerelease"))
		.. " action=" .. tostring(w:GetAttribute("action"))
		.. " pressAndHold=" .. tostring(w:GetAttribute("pressAndHoldAction"))
		.. " useOnKeyDown=" .. tostring(w:GetAttribute("useOnKeyDown"))
		.. " empower=" .. tostring(w:GetAttribute("IsEmpowerSpell"))
end

local function ClickTargets()
	local out = {}
	local Bars = Flux.Bars
	if Bars and Bars.hosts then
		for col = 1, (Bars.NUM_COLUMNS or 0) do
			local c = Bars.hosts[col]
			local host = c and c.main
			if host and host.widget and #out < 3 then
				out[#out + 1] = { label = "strip col" .. col, widget = host.widget }
			end
		end
	end
	local EBS = Flux.EBS
	if EBS and EBS.buttons then
		for i = 1, #EBS.buttons do
			local b = EBS.buttons[i]
			if b and b.Widget and b.ActionType then
				out[#out + 1] = { label = "ebs#" .. i .. "/" .. tostring(b.ActionType), widget = b.Widget }
				break
			end
		end
	end
	return out
end

local function ArmTrace(targets)
	traceLeft = 10
	if not traceEvents then
		traceEvents = CreateFrame("Frame")
		traceEvents:SetScript("OnEvent", function(_, event, unit, _, spellID)
			if traceLeft > 0 and unit == "player" then
				print("    |cff44ff44" .. event .. "|r spellID=" .. tostring(spellID))
			end
		end)
	end
	traceEvents:RegisterEvent("UNIT_SPELLCAST_SENT")
	traceEvents:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	for i = 1, #targets do
		local label, w = targets[i].label, targets[i].widget
		if not traceHooked[w] then
			traceHooked[w] = true
			-- Raw mouse events are delivered independently of RegisterForClicks.
			-- If OnMouseUp fires but PreClick(down=false) does not, the up-click
			-- was suppressed rather than never reaching the button.
			w:HookScript("OnMouseDown", function(self)
				if traceLeft > 0 then
					print("  |cff888888OnMouseDown|r " .. label
						.. " state=" .. tostring(self.GetButtonState and self:GetButtonState()))
				end
			end)
			w:HookScript("OnMouseUp", function(self)
				if traceLeft > 0 then
					print("  |cff888888OnMouseUp|r " .. label
						.. " state=" .. tostring(self.GetButtonState and self:GetButtonState()))
				end
			end)
			w:HookScript("OnDragStart", function()
				if traceLeft > 0 then
					print("  |cffff8800OnDragStart|r " .. label .. " (drag cancels the click)")
				end
			end)
			w:HookScript("OnHide", function()
				if traceLeft > 0 then
					print("  |cffff0000OnHide|r " .. label .. " (hiding mid-click drops the up)")
				end
			end)
			w:HookScript("PreClick", function(self, button, down)
				if traceLeft > 0 then
					print("  |cffffcc00PreClick|r " .. label .. " button=" .. tostring(button)
						.. " down=" .. tostring(down) .. " | " .. Attrs(self))
				end
			end)
			w:HookScript("PostClick", function(self, button, down)
				if traceLeft > 0 then
					print("  |cff00ccffPostClick|r " .. label .. " button=" .. tostring(button)
						.. " down=" .. tostring(down) .. " | " .. Attrs(self))
					traceLeft = traceLeft - 1
					if traceLeft <= 0 then
						traceEvents:UnregisterAllEvents()
						Flux.Print("clickdiag trace finished")
					end
				end
			end)
		end
	end
end

local function PrintClick()
	local targets = ClickTargets()
	Flux.Print("Click contract")
	if #targets == 0 then
		print("  no buttons found (bars/ebs not built yet)")
		return
	end

	local lock = "n/a"
	if Settings and Settings.GetValue then
		local ok, v = pcall(Settings.GetValue, "lockActionBars")
		if ok then
			lock = tostring(v)
		end
	end
	print("  CVars: ActionButtonUseKeyDown=" .. tostring(GetCVarBool and GetCVarBool("ActionButtonUseKeyDown"))
		.. " empowerTapControls=" .. tostring(GetCVarBool and GetCVarBool("empowerTapControls"))
		.. " lockActionBars=" .. lock)

	for i = 1, #targets do
		local label, w = targets[i].label, targets[i].widget
		local onClick = w:GetScript("OnClick")
		print("  " .. label .. " (" .. tostring(w:GetName()) .. ")")
		print("    OnClick=" .. (onClick and "present" or "|cffff0000NIL - clicks cannot fire|r")
			.. (onClick == _G.SecureActionButton_OnClick and " [raw SecureActionButton_OnClick, NOT wrapped]" or "")
			.. " mouse=" .. tostring(w:IsMouseEnabled())
			.. " strata=" .. tostring(w:GetFrameStrata()) .. " level=" .. tostring(w:GetFrameLevel()))
		print("    " .. Attrs(w))
	end

	ArmTrace(targets)
	print("  |cffffff00Trace armed for 10 clicks. Click a button now.|r")
end

SLASH_FLUXAPI1 = "/fluxapi"
SlashCmdList["FLUXAPI"] = function()
	PrintApi()
end

SLASH_FLUXCLICK1 = "/fluxclick"
SlashCmdList["FLUXCLICK"] = function()
	PrintClick()
end

SLASH_FLUXCAST1 = "/fluxcast"
SlashCmdList["FLUXCAST"] = function()
	local Cast = Flux.ButtonFX and Flux.ButtonFX.Cast
	local d = Cast and Cast.Debug and Cast.Debug() or {}
	Flux.Print("Cast VFX")
	print("  started=" .. yn(d.started)
		.. " armed=" .. yn(d.armed)
		.. " entries=" .. tostring(d.entries)
		.. " owners=" .. tostring(d.owners)
		.. " hasOwner=" .. yn(d.hasOwner))
	print("  lastEvent=" .. tostring(d.lastEvent)
		.. " lastSpell=" .. tostring(d.lastSpell)
		.. " mode=" .. tostring(d.mode)
		.. " SpellCastAnimFrame=" .. yn(d.hasCastFrame))
	print("  active=" .. tostring(d.active)
		.. " interrupt=" .. tostring(d.interrupt)
		.. " finish=" .. tostring(d.finish))
	if not d.started then
		print("  dispatcher is not running — ActionBars/EBS Cast.Start never armed")
	elseif (d.entries or 0) == 0 then
		print("  no widgets registered — Overlay.Attach/Cast.Register did not run")
	end
end

SLASH_FLUXPERF1 = "/fluxperf"
SlashCmdList["FLUXPERF"] = function(msg)
	msg = type(msg) == "string" and msg:lower():match("^%s*(.-)%s*$") or ""
	local Perf = Flux.Perf
	if msg == "help" then
		Flux.Print("/fluxperf — idle drivers and scheduler counters")
		print("  /fluxperf burst — cost of the last shapeshift / page / bag-drag burst")
		print("  /fluxperf watch — print every burst as it settles")
		print("  /fluxperf reset — clear counters")
		print("  /fluxhop — live mouseover-hop + Shift/Ctrl overlay")
		print("  /fluxapi — client, capabilities, secrets, optional addons, inventory, ebs")
		print("  /fluxwindows — lock | unlock | reset Blizzard windows (not HUD)")
		print("  /fluxinv — inventory source / counts")
		print("  /fluxebs — extra button engine")
		print("  /fluxclick — secure click attributes + live click trace")
		print("  /fluxcast — last spellcast VFX owner")
		return
	end
	if msg == "form" or msg == "burst" then
		if Perf and Perf.PrintLastBurst then
			Perf.PrintLastBurst()
		end
		return
	end
	if msg == "watch" then
		if Perf then
			Perf.verbose = not Perf.verbose
			Flux.Print("burst watch " .. (Perf.verbose and "on" or "off"))
		end
		return
	end
	if msg == "reset" then
		if Perf and Perf.Reset then
			Perf.Reset()
			Flux.Print("perf counters cleared")
		end
		return
	end
	PrintPerf()
end
