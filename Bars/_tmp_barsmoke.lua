-- Bars/_tmp_barsmoke.lua — slot math + lockdown contract. No WoW required.
-- lua Bars/_tmp_barsmoke.lua   (from the _FluxUI addon root)
local here = arg and arg[0]
local dir = "."
if type(here) == "string" then
	dir = here:gsub("[/\\][^/\\]+$", "")
	if dir == here then
		dir = "."
	end
end
local path = dir .. "/SlotMath.lua"
local fn, err = loadfile(path)
if not fn then
	io.stderr:write("load SlotMath failed: " .. tostring(err) .. "\n")
	os.exit(1)
end
local M = fn("FluxUI", { Flux = { Bars = {} } })
if not M or not M.SelfTest then
	io.stderr:write("SlotMath.SelfTest missing\n")
	os.exit(1)
end

local failures = M.SelfTest()
if #failures > 0 then
	io.stderr:write("slot math FAILED (" .. tostring(#failures) .. ")\n")
	for i = 1, #failures do
		io.stderr:write("  " .. failures[i] .. "\n")
	end
	os.exit(1)
end

-- Lockdown contract: Layout.Apply / ApplyMappings / ApplyVisual must return
-- before Show/Hide/SetPoint. Smoke-check the source rather than WoW frames.
local function read(name)
	local f = io.open(dir .. "/" .. name, "r")
	if not f then
		return ""
	end
	local s = f:read("*a")
	f:close()
	return s
end

local function clearCacheChunk(src)
	local i = src:find("function Paint.ClearCache", 1, true)
	if not i then
		return src
	end
	local j = src:find("\nfunction ", i + 10, true)
	return src:sub(i, (j or (i + 900)) - 1)
end

local layout = read("Layout.lua")
local function has(hay, needle, label)
	if not hay:find(needle, 1, true) then
		failures[#failures + 1] = label
	end
end
has(layout, "function Layout.ApplyMappings", "ApplyMappings exists")
has(layout, "if InLockdown() then", "Layout lockdown guard")
has(layout, "function Layout.ApplyVisual", "ApplyVisual exists")
has(layout, "function Layout.RevealEmptyInCombat", "combat reveal exists")
has(layout, "Never unpack packed columns", "no combat unpack")

local clicks = read("Clicks.lua")
has(clicks, "SetOverrideBindingClick", "click-route keys")
has(clicks, "ActionButtonUseKeyDown", "CVar ActionButtonUseKeyDown")
has(clicks, '"KeyBind"', "KeyBind override click")
has(clicks, "FluxSlotClick_", "keys stay on the host; overlay clickbutton is the hidden SAB")
has(clicks, "UsesWrap", "ReassertEmpower pressAndHold is wrap-gated")
has(clicks, "FluxActionStripKey", "Forever keys click a hidden down-only proxy")
-- useparent-<name> recurses with the same modifier prefix and button suffix, so
-- the host's shift-action* / shift-type* twins resolve through the proxy.
has(clicks, "useparent-action", "Forever keyer inherits the host action")
has(clicks, "useparent-typerelease", "Forever keyer inherits the host typerelease")
has(clicks, 'prefix .. "IsEmpowerSpell*"', "ReassertEmpower gates each click set")
has(clicks, '{ "", "shift-", "ctrl-" }', "ReassertEmpower covers nomod as well as the modifiers")
has(clicks, '"AnyDown"', "Forever keyer registers key-down")
has(clicks, '"LeftButton"', "Forever keyer is clicked as LeftButton")
has(clicks, "EnsureBarButtonPushHooks", "Clicks.Start installs bar push hooks")
has(clicks, "HookKeyer", "Forever keyer paints the parent strip host")
if clicks:find("WrapScript", 1, true) then
	failures[#failures + 1] = "Clicks.lua must not WrapScript"
end
if clicks:find('SetAttribute("typerelease", "action")', 1, true) then
	failures[#failures + 1] = "Clicks.ReassertEmpower must not force typerelease=action (breaks type=click overlays)"
end
do
	local i = clicks:find("function Clicks.Start", 1, true)
	local body = i and clicks:sub(i, i + 900) or ""
	if body:find("PLAYER_REGEN_ENABLED", 1, true) then
		failures[#failures + 1] = "Clicks.Start must not ApplyRegistration on every regen"
	end
	has(body, "EnsureBarButtonPushHooks", "Clicks.Start hooks KeyBind push")
end

local hosts = read("Hosts.lua")
has(hosts, "typerelease", "strip typerelease action")
has(hosts, "Widget.Attach", "strip occupancy is a FluxButton")
has(hosts, 'kind = "strip"', "strip kind is occupancy, not dummy Extra")
has(hosts, "ActionBarButtonTemplate", "post-DF template")
has(hosts, "SetID", "ID=0")
if hosts:find("widget:SetID(column)", 1, true) then
	failures[#failures + 1] = "native mains must SetID(0); ID>0 ignores swapped action after vehicle"
end
if hosts:find('SetAttribute("useparent-actionpage", true)', 1, true) then
	failures[#failures + 1] = "strip hosts must not inherit actionpage (vehicle MainActionBar.bar hijack)"
end
if hosts:find("widget.bar =", 1, true) then
	failures[#failures + 1] = "must not set widget.bar (mixin UpdateFlyout GetSpellFlyoutDirection taints UseAction)"
end
local flyout = read("Flyout.lua")
has(flyout, "function Flyout.Hide", "Flyout.Hide for empty ActionButtonTemplate arrows")
has(flyout, "function Flyout.IsFlyoutSlot", "Flyout.IsFlyoutSlot")
has(flyout, "ClearPopup", "non-flyout slots ClearPopup (HasPopup drives mixin.Arrow)")
has(hosts, "Flyout.Hide", "strip create hides SpellFlyout arrow")
do
	local attachStart = flyout:find("function Flyout.Attach", 1, true)
	local attachEnd = flyout:find("function Flyout.IsFlyoutSlot", 1, true) or (attachStart and attachStart + 800)
	local attachBody = (attachStart and attachEnd and flyout:sub(attachStart, attachEnd)) or ""
	if attachBody:find("widget.SetPopup,", 1, true) or attachBody:find("widget.popup =", 1, true) then
		failures[#failures + 1] = "Flyout.Attach must not SetPopup (empty bars show mixin.Arrow)"
	end
end
local paint = read("Paint.lua")
has(paint, "Flyout.Update", "paint updates native flyout arrows")
local flyoutHits = 0
for _ in paint:gmatch("Flyout%.Update%(host%)") do
	flyoutHits = flyoutHits + 1
end
if flyoutHits < 2 then
	failures[#failures + 1] = "empty leftover paint must Flyout.Update (clear leftover arrows)"
end
has(hosts, "Flux.Action.DetachFromCollectors", "never stay registered")
has(hosts, "FX.Ensure", "strip creates chargeCooldown OOC")
has(hosts, "SweepFluxFromCollectors", "Hosts.Build vacuums collectors")
has(hosts, 'SetAttribute("checkmouseovercast", false)', "Hosts create-time native check stays off")
if hosts:find('SetAttribute("checkmouseovercast", true)', 1, true) then
	failures[#failures + 1] = "Hosts must not ungated-set checkmouseovercast true (engine stamps Forever only)"
end
has(hosts, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", "strip unregisters mixin glow SHOW")
has(hosts, "eventsRegistered = true", "strip stays off collector")
has(hosts, 'SetScript("OnEvent", nil)', "strip clears OnEvent script")
has(hosts, 'SetScript("OnAttributeChanged", OnActionAttribute)', "strip OnAttributeChanged replaces mixin (no secret SetCooldown)")
do
	local hook = hosts:find('SetScript("OnAttributeChanged", OnActionAttribute)', 1, true)
	local setType = hosts:find('widget:SetAttribute("type", "action")', 1, true)
	if hook and setType and hook > setType then
		failures[#failures + 1] = "OnAttributeChanged must replace mixin before CreateSurface SetAttribute"
	end
end
if hosts:find('HookScript, widget, "OnAttributeChanged"', 1, true)
	or hosts:find('HookScript(widget, "OnAttributeChanged"', 1, true) then
	failures[#failures + 1] = "Hosts must not HookScript OnAttributeChanged (mixin Update SetCooldown taint)"
end
if hosts:find("widget.OnEvent = function() end", 1, true) then
	failures[#failures + 1] = "Hosts must not Flux-noop OnEvent (collector taint)"
end
if hosts:find("widget.Update = function() end", 1, true) then
	failures[#failures + 1] = "Hosts must not Flux-noop mixin Update (collector taint)"
end
if hosts:find("widget.UpdateAction = function() end", 1, true) then
	failures[#failures + 1] = "Hosts must not Flux-noop UpdateAction (collector taint)"
end
if hosts:find("UpdateSpellAlert = function() end", 1, true) then
	failures[#failures + 1] = "Hosts must not Flux-noop UpdateSpellAlert (collector taint)"
end
if hosts:find("UpdateOverlayGlow = function() end", 1, true) then
	failures[#failures + 1] = "Hosts must not Flux-noop UpdateOverlayGlow (collector taint)"
end
if hosts:find("UpdateHotkeys = function() end", 1, true) then
	failures[#failures + 1] = "Hosts must not Flux-noop UpdateHotkeys (collector taint)"
end
has(hosts, "GetCursorInfo", "PreClick cursor guard")
has(hosts, 'SetScript("PreClick", function(w, button, down)', "PreClick takes button/down")
has(hosts, 'button == "KeyBind" or down', "PreClick skips keys and mouse-down")
has(hosts, "UsesWrap", "strip PreClick blanking is wrap-only")
has(hosts, "WrapClicks()", "strip PostClick PlaceAction is wrap-only")
if hosts:find('w:SetAttribute("type", nil)', 1, true) then
	failures[#failures + 1] = "Hosts PreClick must blank type with \"\", not nil"
end
has(hosts, "_fluxHadReticle", "PostClick arms reticle checked")
has(hosts, "NotePressed", "mouse-down notes PUSHED")
-- OnMouseUp runs before the click dispatch; resetting button state there
-- cancels the mouse-up click on every button.
if hosts:find('HookScript("OnMouseUp"', 1, true) then
	failures[#failures + 1] = "Hosts must not reset press state in OnMouseUp (kills the up-click)"
end
if hosts:find("UpdateState = function() end", 1, true) then
	failures[#failures + 1] = "Hosts must not Flux-noop UpdateState (collector taint)"
end
if hosts:find("WrapScript", 1, true) then
	failures[#failures + 1] = "Hosts.lua must not WrapScript"
end
if hosts:find('SetAttribute("useOnKeyDown", nil)', 1, true) then
	failures[#failures + 1] = "Hosts must not unset useOnKeyDown"
end
has(hosts, "function Hosts.LiveSlot", "page/form paint uses the indexed slot")
has(hosts, "function Hosts.MiniCountFontSize", "minirow count size is shared")
has(hosts, "Hosts.MINI_WIDGET_SCALE", "minirow widget scale is shared with badge counts")
has(hosts, "function Hosts.UpdateTooltip", "strip tooltip follows the shown overlay")
has(hosts, "FluxSetHUDTooltipOwner", "strip tooltips use the HUD anchor")
has(hosts, "FluxBindingTooltip", "strip tooltips append Binding peers")
has(hosts, "_fluxBarSlotIndex", "strip widgets are stamped for BindingTooltip")
has(hosts, "function Hosts.RefreshHoverTooltip", "overlay hops refresh the owned tooltip")
has(hosts, 'HL.Begin("attr.action", "root")', "action swaps time into hop/mod debug")
has(hosts, "contextOwns", "SHIFT skips NotifyModifierPaging when Context owns display")
has(hosts, "MarkDirty", "SHIFT does not RequestPaint per swapped host")
do
	local i = hosts:find("local function OnActionAttribute", 1, true)
	local j = i and hosts:find("local function DetachMixinEvents", i, true)
	local body = (i and j and hosts:sub(i, j - 1)) or ""
	has(body, "SP.ApplyLiveType", "action swaps rebind the live face")
	has(body, "host._fluxFaceSlot == slot", "form IndexSlot still ApplyLiveType")
	local applyAt = body:find("SP.ApplyLiveType", 1, true)
	local burstAt = body:find("if not bursting then", 1, true)
	if applyAt and burstAt and burstAt < applyAt then
		failures[#failures + 1] = "form burst must still ApplyLiveType so icons rebind"
	end
	local ownsAt = body:find("if not contextOwns then", 1, true)
	local prefix = ownsAt and body:sub(1, ownsAt - 1) or body
	has(prefix, "NotifyDisplay", "CHILDUPDATE rehomes badges before the Context-owned paging skip")
	if ownsAt then
		has(body:sub(ownsAt), "NotifyModifierPaging", "SHIFT still pages badges when Context does not own display")
		if body:sub(ownsAt):find("NotifyDisplay", 1, true) and not prefix:find("NotifyDisplay", 1, true) then
			failures[#failures + 1] = "NotifyDisplay must not live only inside the Context-owned skip"
		end
	end
end
do
	local i = hosts:find('widget:SetScript("OnEnter"', 1, true)
	local j = i and hosts:find('widget:SetScript("OnLeave"', i, true)
	local body = (i and j and hosts:sub(i, j - 1)) or ""
	has(body, "Hosts.UpdateTooltip", "OnEnter uses shown-face tooltip")
	if body:find("GameTooltip:SetAction(slot)", 1, true) then
		failures[#failures + 1] = "OnEnter must not SetAction native occupancy as the tooltip"
	end
	if body:find("ANCHOR_RIGHT", 1, true) then
		failures[#failures + 1] = "OnEnter must not ANCHOR_RIGHT; UpdateTooltip owns HUD placement"
	end
end
do
	local i = hosts:find("local function ShownFace", 1, true)
	local j = i and hosts:find("function Hosts.CreateSurface", i, true)
	local body = (i and j and hosts:sub(i, j - 1)) or ""
	has(body, "Identity.SlotKey", "tooltip prefers Identity over native occupancy")
	has(body, "_fluxFaceSlot", "tooltip ignores a face bound to a different slot")
	has(body, "NativeActionKindId", "native occupancy still uses SetAction")
	has(body, "GameTooltip.SetAction", "matching occupancy uses SetAction like LAB")
	has(body, "OnLabTooltip", "BindingTooltip appends after the Blizzard fill")
	has(body, "SetSpellByID", "shown spells use SetSpellByID")
	has(body, "SetAction", "native occupancy is the fallback when there is no overlay face")
end

local effects = read("Effects.lua")
has(effects, "Hosts.LiveSlot", "glow follows the indexed slot on form paging")
has(effects, "G.Want", "strip glow uses ButtonFX.Glow")
has(effects, "G.Start", "strip Glow.Start")
has(effects, "ButtonFX.Flash", "strip Flash.Start")
has(effects, "Paint.UpdateFlash", "combat/auto-repeat refreshes strip flash")
has(effects, "function Effects.SyncColumn", "SyncColumn")
has(effects, "FollowColumn", "SyncColumn follows cast VFX")
has(effects, "UPDATE_MACROS", "macro identity retriggers exclusive VFX")
has(effects, "MODIFIER_STATE_CHANGED", "SHIFT/CTRL paging retriggers exclusive VFX")
do
	local i = effects:find('FormStorm.OnBurst("bars.effects"', 1, true)
	local j = i and effects:find("local Ev = Flux.Events", i, true)
	local body = (i and j and effects:sub(i, j - 1)) or ""
	has(body, "ContextOwnsDisplay", "form burst VFX waits for Context Identity+vis")
end
has(effects, "PLAYER_REGEN_DISABLED", "combat macro condition retriggers VFX")
has(effects, "PLAYER_EQUIPMENT_CHANGED", "equipped macro condition retriggers VFX")
has(effects, "UpdateChecked", "SyncColumn paints checked after follow")
has(effects, "G.Transfer", "column glow transfer")
has(effects, "G.NotifySAO", "SyncColumn wakes SAO ActionButtons map")
has(effects, "GetVisibleBadgesForButton", "SyncColumn includes visible badges")
has(effects, "UncheckFace", "SyncColumn exclusive gold across strip and badges")
has(effects, "Timer.Defer", "coalesced Refresh")
has(effects, "FaceShowsSpell", "strip glow hides when icon left the proc")
has(effects, "ShouldSkipBirth", "strip skipBirth if that spell already intro'd")
do
	local j = effects:find("function Effects.RefreshAll", 1, true)
	local k = effects:find("function Effects.Start", 1, true)
	local body = (j and k and effects:sub(j, k - 1)) or ""
	has(body, "QueueFlush", "RefreshAll defers via QueueFlush")
	if body:find("FlushDirty", 1, true) then
		failures[#failures + 1] = "RefreshAll must QueueFlush only, not FlushDirty inline"
	end
end
if effects:find("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 1, true) then
	failures[#failures + 1] = "Effects must use ButtonFX.Glow events, not its own SHOW table"
end
do
	local i = effects:find("function Effects.Refresh(host)", 1, true)
	local j = effects:find("function Effects.RefreshAll", 1, true)
	local refresh = (i and j and effects:sub(i, j - 1)) or ""
	has(refresh, "dirtyCols", "Refresh dirties column")
	if refresh:find("G.Set", 1, true) or refresh:find("SetGlow", 1, true) then
		failures[#failures + 1] = "Refresh must only dirty column, not Set glow"
	end
end

local paint = read("Paint.lua")
has(paint, "Pickup / drop off the bar must not keep", "empty occupancy clears leftover item count")
has(paint, "GetActionDisplayCount", "Midnight display count")
has(paint, "local function OverlaySpellCount", "overlay spell digits follow the shown face")
has(paint, "local function OverlayItemCount", "overlay item digits follow the shown face")
has(paint, "Mana gem / emerald / potion: always show the digit", "overlay item count keeps 0")
has(paint, "local function OverlayItemEmptyUnusable", "strip darkens 0-count consumable items")
has(paint, "Unique gems can still sit in the stack snapshot", "strip gem 0 charges ignores leftover stack")
has(paint, "local function SlotCountUnusable", "strip darkens 0-count consumable actions")
has(paint, "local function ChargeState", "strip charge 0→1 does not stay gray")
has(paint, "local function DisplayedZero", "strip uses last painted 0 for combat dim")
has(paint, "function Paint.NotePlayerCast", "strip dims 0 charges/items on cast success")
has(paint, "keep last tint", "strip does not fail-open to bright when usable is secret")
has(paint, 'charge ~= "ready"', "0→1 charges override stale IsUsable false")
has(paint, "function Paint.ShownSpellId", "strip exposes the painted spell for rank gray")
has(paint, "local function ApplyRankDesat", "strip rank gray after usable vertex")
has(paint, "_fluxRankDesaturated and true or false", "strip keeps lower-rank grayscale")
has(paint, "Consumable 0: native display count is often blank", "strip keeps consumable 0 when display count is empty")
has(paint, "Overlay identity owns the count", "reverse swap does not keep the other face's count")
do
	local i = paint:find("local function CountLooksEmpty", 1, true)
	local j = paint:find("function SlotCountUnusable", 1, true)
	local body = (i and j and paint:sub(i, j - 1)) or ""
	has(body, "SafeLooksEmpty", "CountLooksEmpty uses SafeLooksEmpty")
	if body:find('display == ""', 1, true) then
		local secretAt = body:find("IsSecret(display)", 1, true)
		local eqAt = body:find('display == ""', 1, true)
		if eqAt and (not secretAt or eqAt < secretAt) then
			failures[#failures + 1] = "CountLooksEmpty must not == \"\" a secret display count"
		end
	end
end
do
	local i = paint:find("function Paint.UpdateCount", 1, true)
	local j = paint:find("local function HideFillCooldown", 1, true)
	local body = (i and j and paint:sub(i, j - 1)) or ""
	local kindAt = body:find('kind == "spell"', 1, true)
	local nativeAt = body:find("cab.GetActionDisplayCount", 1, true)
	if not kindAt or not nativeAt then
		failures[#failures + 1] = "UpdateCount must paint overlay identity before native display count"
	elseif not body:sub(kindAt, nativeAt):find("return", 1, true) then
		failures[#failures + 1] = "overlay count must not fall through to GetActionDisplayCount"
	end
end
has(paint, "function Paint.UpdateAssistedCombat", "strip assistant overlay")
has(paint, "function Paint.PaintAssistedHosts", "strip assistant next-cast flush")
has(paint, "function Paint.PaintAssistedHighlights", "strip assist highlight flush")
has(paint, "function Paint.UpdateAssistedHighlight", "strip assist highlight paint")
has(paint, "GetAssistedNextSpell", "strip paints from next-cast")
has(paint, "ActionBarButtonAssistedCombatHighlightTemplate", "strip highlight template")
do
	local i = paint:find("local function ApplyCountText", 1, true)
	local j = paint:find("Macro name (main row only)", i or 1, true)
	local body = (i and j and paint:sub(i, j - 1)) or ""
	has(body, "IsSecretValue", "strip count write-through detects secrets")
	has(body, "fs:SetText(value)", "strip SetText secrets instead of skipping")
	has(body, "_fxCountZero", "strip remembers last readable 0-count for combat dim")
	if body:find("host._count = nil", 1, true) then
		failures[#failures + 1] = "ApplyCountText must keep last readable count on secret writes"
	end
	if body:find("SafeCountKey", 1, true) then
		failures[#failures + 1] = "ApplyCountText must not SafeCountKey-skip secret digits"
	end
	if body:find("fs:Hide()", 1, true) then
		failures[#failures + 1] = "ApplyCountText must not Hide the count fontstring"
	end
	has(body, "fs:Show()", "blank count stays shown so the next digit can land")
	has(body, "CountRegionHidden", "cache hit rewrites a hidden count region")
end
has(paint, "AssistedNextSpellId", "strip stores next-cast id")
has(paint, "_fluxAssistedCombat", "strip marks assistant widgets")
if paint:find("C_ActionBar.ForceUpdateAction", 1, true) then
	failures[#failures + 1] = "Paint must not ForceUpdateAction (taints leftover stock cooldown)"
end
has(paint, "ActionBarButtonAssistedCombatRotationTemplate", "strip rotation template")
if paint:find('rot:SetScript("OnUpdate", show and AssistantRotationOnUpdate', 1, true) then
	failures[#failures + 1] = "assistant rotation frame must not duplicate bars.assistant OnUpdate"
end
has(paint, "SetCooldownFromDurationObject", "Midnight cooldown duration")
has(paint, "GetActionCooldown", "Classic cooldown fallback")
has(paint, "GetChargeDuration", "strip fetches charge duration objects")
has(paint, "Secret counts still need the duration object", "strip charge edge uses duration objects in combat")
has(paint, "HideFillCooldown", "strip cooldown paint skips live interrupt swipe")
has(paint, "widget:SetChecked(checked", "strip always SetChecked")
has(paint, "CheckedVisualOn", "strip checked skip requires the hilight to match")
has(paint, "function Paint.SweepLitChecked", "strip dismiss watch only walks gold hosts")
has(paint, "function Paint.ArmCheckedPoll", "strip dismiss watch arms on demand")
has(paint, "MountSpellStillActive", "strip mount spells drop gold after dismiss")
if paint:find("UNIT_SPELLCAST_STOP", 1, true) then
	failures[#failures + 1] = "strip Paint must not listen UNIT_SPELLCAST_STOP (cast-rate lag)"
end
has(paint, "Spell.IsCurrent", "checked uses Spell.IsCurrent")
has(paint, "SpellIdFromAction", "checked resolves slot spell")
has(paint, "ApplyChecked", "checked goes through Overlay.ApplyChecked")
has(paint, "slotCurrent", "unprogrammed strip still uses SlotIsCurrent")
has(paint, "kind == \"spell\" and shown", "overlay gold follows the live Extra face")
has(paint, "function Paint.UpdateFlash", "strip auto-attack/auto-shot red flash")
has(paint, "Paint.UpdateFlash(host)", "checked paint also drives the red flash")
has(paint, "WantSlot", "strip flash uses slot attack/auto-repeat")
has(paint, "WantSpell", "overlay flash follows the shown Extra spell")
has(paint, "WantItem", "overlay flash follows a shown Extra item")
has(paint, "widget._fluxParked", "parked minis do not keep the red flash")
if paint:find("if not checked and not spellId", 1, true) then
	failures[#failures + 1] = "strip checked must not skip SlotIsCurrent when spellId is set"
end
has(paint, "IsLiveReticle", "no checked stack while reticle up")
has(paint, "GetActionTexture", "strip icon uses GetActionTexture")
has(paint, "A.GetTexture", "strip icon uses Action.GetTexture")
has(paint, "SlotSpellTexture", "strip spell/macro fallback uses Spell.GetTexture")
-- No settle driver: eval is deferred past a layout now, never dropped, so a
-- repeating 50ms icon repaint of all 57 hosts has no reason to exist.
if paint:find("function Paint.RequestIcon", 1, true) then
	failures[#failures + 1] = "strip must not keep an icon settle driver (bars.icon lane carries it)"
end
if paint:find("ICON_TICK", 1, true) or paint:find("ICON_SETTLE", 1, true) then
	failures[#failures + 1] = "strip must not re-run icons on a settle timer"
end
has(paint, "No icon settle driver", "strip icon settle removal is explained")
has(paint, "local cooldownOpts", "cooldown options table is reused, not allocated per host")
has(paint, "BeginSlotPass", "paint brackets a slot-spell memo")
do
	local i = paint:find("function Paint.UpdateIcon", 1, true)
	local j = paint:find("function Paint.UpdateCount", 1, true)
	local body = (i and j and paint:sub(i, j - 1)) or ""
	if body:find("GetOverrideSpell", 1, true) then
		failures[#failures + 1] = "strip UpdateIcon must not GetOverrideSpell for normal slots"
	end
	local live = body:find("A.GetTexture", 1, true) or body:find("GetActionTexture", 1, true)
	local slotTex = body:find("SlotSpellTexture", 1, true)
	local overlay = body:find("ProgramShown", 1, true)
	if not live then
		failures[#failures + 1] = "strip UpdateIcon must GetActionTexture for the live face"
	end
	if slotTex and live and slotTex < live then
		failures[#failures + 1] = "strip UpdateIcon must not prefer SlotSpellTexture over GetActionTexture"
	end
	if overlay and live and overlay > live then
		failures[#failures + 1] = "strip UpdateIcon must prefer Extra identity before GetActionTexture"
	end
	has(body, "OccupancyKey", "form/bonus paging drops the previous occupant's icon")
	has(body, "occChanged", "same occupant may keep last texture; a new occupant must not")
	has(body, "slot and filled", "empty bonus slots skip noform overlay identity")
	if body:find("LAB overlay never blanks", 1, true) then
		failures[#failures + 1] = "UpdateIcon must not keep last face across a new occupant"
	end
end
has(paint, "Flux.Hotkey", "strip hotkeys use Core.Hotkey")
has(paint, "bars.hotkey", "hotkey paint lane")
has(paint, "_fluxHotkeyMod", "S-/C- overlay left of mouse glyph")
has(paint, "_hotkeyLive", "SHIFT/CTRL prefix invalidates the hotkey skip")
has(paint, "LivePrefix", "strip hotkeys follow Flux.Hotkey.LivePrefix")
do
	local i = paint:find("function Paint.UpdateHotkey", 1, true)
	local j = i and paint:find("\nfunction Paint.", i + 10, true)
	local body = (i and j and paint:sub(i, j - 1)) or ""
	if body == "" then
		failures[#failures + 1] = "Paint.UpdateHotkey exists"
	else
		has(body, "_hotkeyLive", "UpdateHotkey skip includes live S-/C-")
		has(body, 'host.row ~= "main"', "minis stay unlabeled")
		if body:find("if host._hotkeyRaw == key then", 1, true)
			and not body:find("host._hotkeyLive == live", 1, true)
		then
			failures[#failures + 1] = "UpdateHotkey must not skip on bind-only cache (S-/C- never updates)"
		end
	end
end
has(paint, "function Paint.UpdateName", "strip paints macro name on the main row")
has(paint, "function MacroNameForSlot", "strip macro name resolves the action slot")
has(paint, "A.GetText", "strip macro name uses Action.GetText")
has(paint, "GetMacroInfo", "strip macro name falls back to GetMacroInfo")
has(paint, "Paint.UpdateName(host)", "strip UpdateAll / flush paints Name")
do
	local i = paint:find("function Paint.UpdateName", 1, true)
	local j = i and paint:find("\nfunction Paint.", i + 10, true)
	local body = (i and j and paint:sub(i, j - 1)) or ""
	if not body:find('host.row ~= "main"', 1, true) then
		failures[#failures + 1] = "strip UpdateName must hide Name on minis"
	end
	if not body:find("host._count", 1, true) then
		failures[#failures + 1] = "strip UpdateName must hide Name when count is showing"
	end
end
has(paint, "function ProgramShown", "strip paints slot-program shown identity")
has(paint, "FaceBoundToSlot", "strip ignores a face bound to a different slot")
has(paint, "ShownFromBody", "strip program face uses Extra macro parse")
has(paint, "IsQuestionTex", "strip never keeps INV_Misc_QuestionMark as a live face")
has(paint, "elseif kind == \"item\"", "overlay item face is elseif, not a nested if")
do
	local pfn, perr = loadfile(dir .. "/Paint.lua")
	if not pfn then
		failures[#failures + 1] = "Paint.lua syntax: " .. tostring(perr)
	end
end
do
	local i = paint:find("local function ProgramShown", 1, true)
	local j = paint:find("local function SlotIsAssisted", 1, true)
	local body = (i and j and paint:sub(i, j - 1)) or ""
	if body:find("SecureCmdOptionParse", 1, true) then
		failures[#failures + 1] = "ProgramShown must not parse the full overlay body (bare #showtooltip is ?)"
	end
	if body:find("id or token", 1, true) then
		failures[#failures + 1] = "ProgramShown must not return an unresolved token as a spell"
	end
	has(body, "ProgramFace", "ProgramShown prefers Extra env identity")
	if body:find('GetAttribute("macrotext")', 1, true) then
		failures[#failures + 1] = "ProgramShown must not paint leftover type=macro macrotext"
	end
	has(body, "ProgramBody(slot)", "overlay face is the live slot program, not leftover macrotext")
end
has(paint, "skipDurationObject", "empty/ready strip CD skips GCD duration object")
has(paint, "FillActionCooldownOpts", "native CD uses action cooldown info")
has(paint, "FillSpellCooldownOpts", "overlay/assisted CD uses spell cooldown info")
has(paint, "GetActionChargeDuration", "native charge edge uses action charge duration")
has(paint, "GetActionCooldownDuration", "native swipe uses action cooldown duration")
if paint:find("pcall(cd.SetCooldown, cd, start, duration)", 1, true) then
	failures[#failures + 1] = "Paint must not SetCooldown secret start/duration"
end
do
	local i = paint:find("function Paint.Flush(", 1, true)
	local j = i and paint:find("\nfunction Paint.", i + 10, true)
	local body = (i and j and paint:sub(i, j - 1)) or (i and paint:sub(i)) or ""
	has(body, "hasDirty", "Flush tracks bars.dirty")
	has(body, "Paint.UpdateAll(host)", "Flush UpdateAll dirty hosts even with other lanes")
	has(body, "Paint.HostIsLive(host)", "value lanes skip empty surfaces")
	has(body, "leftover item-count digits", "empty hosts still clear leftover count")
	has(body, "CountLooksEmpty(fs:GetText())", "empty leftover GetText uses CountLooksEmpty")
	if body:find('t ~= ""', 1, true) or body:find('GetText() ~= ""', 1, true) then
		failures[#failures + 1] = "empty leftover GetText must not ~= \"\" a secret count"
	end
	has(body, "leftover noform icons", "empty hosts still clear leftover icons")
	has(body, "leftover equipped borders", "empty bonus/form slots still clear leftover equipped")
	has(body, "leftover form-page cooldown swipes", "empty form slots still clear leftover cooldown")
	has(body, "leftover dim", "empty form slots still clear leftover usable dim")
	if not body:find("if hotkey then", 1, true) then
		failures[#failures + 1] = "empty mains must still paint their key"
	end
	if body:find("dirtyOnly", 1, true) then
		failures[#failures + 1] = "Flush must not skip dirty UpdateAll when hotkey is coalesced"
	end
end
-- A bare host._checked skip goes stale the moment anything else unchecks the
-- widget (Effects, PlayReticle, badge hide). The skip is only safe paired with
-- _fluxCheckedApplied, which every Overlay.ApplyChecked caller stamps.
if paint:find("if host._checked == checked", 1, true)
	and not paint:find("if host._checked == checked and widget._fluxCheckedApplied == checked", 1, true)
then
	failures[#failures + 1] = "Paint must not skip SetChecked via a bare _checked cache"
end
has(paint, "_fluxCheckedApplied", "strip checked skip is paired with the widget stamp")
has(paint, "function Paint.MarkDirty", "SHIFT/CTRL can dirty without scheduling a paint")
has(paint, "function Paint.Dirty", "Dirty still requests bars.dirty")
has(paint, "function Paint.UpdateAll", "occupancy flush still Effects after display")
has(paint, "function Paint.HostIsLive", "Paint knows which surfaces are worth painting")
has(paint, "function Paint.UpdateEquipped", "strip paints equipped border")
has(paint, "shown == equipped", "equipped skip matches leftover WBorder shown-state")
has(paint, "host._fluxParked", "parked minis are not live for paint/range")
do
	local state = read("State.lua")
	local i = state:find("local CHILDUPDATE = ", 1, true)
	local j = i and state:find("local function RowId", i, true)
	local body = (i and j and state:sub(i, j - 1)) or ""
	-- A modifier edge ChildUpdates all 57 surfaces; most keep the slot they
	-- already show, and restamping them was ~7 restricted writes each.
	has(body, "flux-applied", "CHILDUPDATE skips a surface whose slot did not move")
	if not body:find("if applied == slot then", 1, true) then
		failures[#failures + 1] = "CHILDUPDATE must early-out on an unchanged slot"
	end
	local a = body:find('SetAttribute("flux-applied", slot)', 1, true)
	local b = body:find('SetAttribute("action", slot)', 1, true)
	if a and b and a > b then
		failures[#failures + 1] = "flux-applied must be stamped before the action write"
	end
	-- Anything that restamps has to drop the stamp first or the skip sticks.
	has(state, "_childupdate-fluxreset", "hosts can have their applied stamp cleared")
	has(state, 'control:ChildUpdate("fluxreset", 1)', "ForceApply clears the applied stamp")
	local force = state:find("local FORCE_RESET", 1, true)
	local staticForce = state:find("local STATIC_FORCE", 1, true)
	if not staticForce then
		failures[#failures + 1] = "static headers must also clear the applied stamp on ForceApply"
	end
	if not force then
		failures[#failures + 1] = "FORCE_RESET missing"
	end
	local watchSlot = read("Watch.lua")
	if not watchSlot:find('"flux-applied"', 1, true)
		or not watchSlot:find("InvalidateColumnStamps", 1, true)
	then
		failures[#failures + 1] = "slot-content changes must clear the applied stamp (IsEmpowerSpell)"
	end
end
do
	local src = read("Watch.lua")
	local i = src:find("local function AnyNeedsRange", 1, true)
	local j = i and src:find("local function EnableRangeAPI", i, true)
	local body = (i and j and src:sub(i, j - 1)) or ""
	if body:find("ForEachStatic", 1, true) then
		failures[#failures + 1] = "range need check must early-exit, not walk all 57"
	end
	has(body, "return true", "range need check short-circuits on the first hit")
end
do
			local clear = clearCacheChunk(paint)
	if clear:find("_glowing", 1, true) then
		failures[#failures + 1] = "Paint.ClearCache must not nil _glowing"
	end
end

local state = read("State.lua")
has(state, "IsPressHoldReleaseSpell", "empower trailer")
has(state, "[bonusbar:5] 11", "skyriding is a numeric page")
has(state, "[vehicleui][possessbar]", "vehicle/possess is a distinct driver clause")
has(state, "[overridebar] ", "override is a distinct numeric clause")
has(state, "[shapeshift]shapeshift", "shapeshift is its own token")
has(state, "GetVehicleBarIndex()", "secure pack still resolves leftover possess/shapeshift tokens")
if state:find("[overridebar][possessbar][shapeshift]possess", 1, true) then
	failures[#failures + 1] = "must not lump vehicle/override/shapeshift into one possess token"
end
if state:find("if not page or page < 1 then page = 12 end", 1, true) then
	failures[#failures + 1] = "RESOLVE_PAGE fallback must be page 1, not 12"
end
has(state, "function State.ApplySlotsInsecure", "insecure slot restamp exists")
has(state, "function State.IndexLiveSlots", "combat modifier indexes live slots")
do
	local i = state:find("function State.IndexLiveSlots", 1, true)
	local j = state:find("function State.ApplySlotsInsecure", i or 1, true)
	local body = (i and j and state:sub(i, j - 1)) or ""
	has(body, "NotifyDisplay", "combat slot index rehomes badges with the live occupant")
	has(body, "Effects.Refresh", "combat slot index follows identity VFX")
	has(body, "prev == slot", "combat index only dirties hosts whose slot moved")
end
has(state, "function State.OnModFallback", "restricted hub restamps after state-mod")
has(state, "SlotMath.Resolve", "insecure path uses SlotMath.Resolve")
-- SecureTemplates.lua: the modified-attribute form is "modifier-name-button",
-- "*" wildcards either half, and "Setting the attribute by itself is equivalent
-- to *attribute*". So bare "action" matches every modifier (which is why it
-- swallowed SHIFT presses) and bare "shift-action" is not a form the game reads.
-- Three explicit sets -- nomod / shift- / ctrl- -- each with the "*" button
-- wildcard so one write covers keys plus left/right/middle click.
has(state, "function StampSwapClick", "one writer for the three click sets")
has(layout, "Layout.SlotHasAction = SlotHasAction", "State reuses the secret-safe occupancy test")
has(state, "Bars.Layout.SlotHasAction", "insecure slot pick agrees with the stamped flags")
has(state, 'prefix .. "action*"', "click sets use the documented * button wildcard")
if state:find('SetAttribute("shift-action"', 1, true)
	or state:find('SetAttribute("ctrl-action"', 1, true)
then
	failures[#failures + 1] = "bare shift-action / ctrl-action is never read; use the * suffix form"
end
do
	local i = state:find("local function StampSwapClick", 1, true)
	local j = i and state:find("State.StampSwapClick", i, true)
	local body = (i and j and state:sub(i, j - 1)) or ""
	-- Any branch that leaves one of the four nil falls through to the bare live
	-- attribute, which under SHIFT fires whatever the main row is showing.
	has(body, 'prefix .. "type*"', "click set writes type")
	has(body, 'prefix .. "typerelease*"', "click set writes typerelease")
	has(body, 'prefix .. "macrotext*"', "click set writes macrotext")
	has(body, 'prefix .. "clickbutton*"', "click set writes clickbutton")
end
do
	local i = state:find("function State.ApplySlotsInsecure", 1, true)
	local j = state:find("function State.OnModFallback", 1, true)
	local body = (i and j and state:sub(i, j - 1)) or ""
	-- Insecure SetAttribute on a protected frame is blocked in combat
	-- (ADDON_ACTION_BLOCKED on FluxActionStripButtonN), and the block aborts the
	-- rest of the walk. The three click sets are pre-baked precisely so nothing
	-- has to run mid fight.
	if not body:find("if InLockdown() then", 1, true) then
		failures[#failures + 1] = "ApplySlotsInsecure must not SetAttribute a protected frame in combat"
	end
	has(body, 'StampSwapClick(widget, ""', "insecure path stamps the nomod set")
	has(body, 'StampSwapClick(widget, "shift-"', "insecure path stamps the shift set")
	has(body, 'StampSwapClick(widget, "ctrl-"', "insecure path stamps the ctrl set")
	has(body, "StampLiveClick(widget, live)", "Forever keypress stamps type1 and macrotext1")
end
do
	local i = state:find("function State.OnModFallback", 1, true)
	local j = state:find("function State.ForceApply", 1, true)
	local body = (i and j and state:sub(i, j - 1)) or ""
	has(body, "if InLockdown() then", "mod fallback cannot restamp in combat")
	has(body, "IndexLiveSlots", "mod fallback still reindexes for paint")
end
do
	local i = state:find("function State.ForceApply", 1, true)
	local j = state:find("function State.GetClassStances", 1, true)
	local body = (i and j and state:sub(i, j - 1)) or ""
	has(body, "if not SnippetsWork() then", "ForceApply restamps when snippets are off")
	has(body, "ApplySlotsInsecure", "ForceApply uses ApplySlotsInsecure when snippets are off")
	if not body:find("if InLockdown() then", 1, true) then
		failures[#failures + 1] = "ForceApply must not Execute or SetAttribute in combat"
	end
	has(body, "IndexLiveSlots", "ForceApply still keeps paint in step during combat")
end
has(layout, "ApplySlotsInsecure", "ApplyMappings restamps slots when snippets are off")
has(layout, "SafeBooleanTest", "occupancy uses secret-safe HasAction")
has(layout, "SP.GetIdle", "occupancy counts Binding overlay idle bodies")
do
	-- Occupancy / promotion flags are SetAttribute writes on protected frames,
	-- so they stay OOC. CHILDUPDATE reads live minirow occupancy itself instead
	-- of trusting them to be fresh after a fight started early.
	local i = layout:find("function Layout.ApplyMappings", 1, true)
	local j = i and layout:find("function Layout.RevealEmptyInCombat", i, true)
	local body = (i and j and layout:sub(i, j - 1)) or ""
	has(body, "if InLockdown() then", "ApplyMappings must not SetAttribute in combat")
end
do
	-- A slot whose content changed needs the next ChildUpdate to redo overlay
	-- type and empower rather than early-out on an unchanged slot number.
	local watchFlush = read("Watch.lua")
	has(watchFlush, "function Watch.InvalidateColumnStamps", "one writer drops a column's ChildUpdate guards")
	has(watchFlush, "flux-applied-mods", "slot changes drop the click-set guard too")
	has(watchFlush, "flux-live-sec", "slot changes drop the cached occupancy probe")
	local ii = watchFlush:find("function Watch.InvalidateColumnStamps", 1, true)
	local ij = ii and watchFlush:find("local function RegisterMany", ii, true)
	local iBody = (ii and ij and watchFlush:sub(ii, ij - 1)) or ""
	has(iBody, "if InLockdown() then", "stamp invalidation must not SetAttribute in combat")
	local wi = watchFlush:find("local function FlushSlotChanged", 1, true)
	local wj = wi and watchFlush:find('Ev.Register("ACTIONBAR_SLOT_CHANGED"', wi, true)
	local wBody = (wi and wj and watchFlush:sub(wi, wj - 1)) or ""
	-- A main-row host caches its column's minirow occupancy and is not indexed
	-- at the mini slot while no modifier is held, so invalidation is per column.
	has(wBody, "Watch.InvalidateColumnStamps(list[h].column)", "slot changes invalidate the whole column")
	has(layout, "Bars.Watch.InvalidateColumnStamps", "new occupancy flags drop the guards that would skip them")
	-- The click sets are baked from the per-slot overlay bodies, so a new body
	-- has to drop the guard and get a restamp of its own.
	local sp = read("SlotProgram.lua")
	has(sp, 'widget:SetAttribute("flux-applied-mods", nil)', "a new overlay body drops the click-set guard")
	has(sp, "QueueClickSetRestamp", "overlay writes queue one coalesced click-set restamp")
end
do
	local initSrc = read("Init.lua")
	has(initSrc, "local function DescribePaging", "/fluxbars page dumps the secure paging chain")
	has(initSrc, 'msg == "page"', "/fluxbars page is wired up")
	has(initSrc, "hub state-mod=", "paging dump reports the mod hub state")
	has(initSrc, 'h:GetChildren()', "paging dump reports ChildUpdate reach")
	has(initSrc, 'w:GetAttribute("shift-action*")', "surface dump reports the click-time shift slot")
	has(initSrc, 'w:GetAttribute("action*")', "surface dump reports the click-time nomod slot")
	has(initSrc, 'w:GetAttribute("flux-applied-mods")', "surface dump reports the click-set guard")
end
do
	local watch = read("Watch.lua")
	local i = watch:find('Ev.Register("MODIFIER_STATE_CHANGED"', 1, true)
	local j = watch:find('Ev.Register("UPDATE_BINDINGS"', i or 1, true)
	local body = (i and j and watch:sub(i, j - 1)) or ""
	has(body, "ApplySlotsInsecure", "Watch modifier restamps OOC when snippets are off")
	-- In combat this can only reindex for paint; the click resolves against the
	-- pre-baked nomod / shift- / ctrl- sets instead.
	has(body, "IndexLiveSlots", "Watch modifier reindexes for paint in combat")
	if body:find("Bars.RequestLayout", 1, true) then
		failures[#failures + 1] = "Watch modifier must not RequestLayout"
	end
end
local restrictedSrc = read("../Core/Engine/Restricted.lua")
has(restrictedSrc, "OnModFallback", "restricted hub calls Bars.State.OnModFallback")
local pushPress = read("../Binding/Core/PushPress.lua")
has(pushPress, 'button ~= "KeyBind" and button ~= "Keybind"', "PushPress accepts KeyBind and Keybind")
has(pushPress, "down == false", "PushPress ignores click-up")
has(pushPress, "function PushPress.HookKeyer", "Forever keyer paints the parent host")
has(pushPress, "commitMainRowPush", "keyer push uses the main-row visual")
has(state, 'SetAttribute("typerelease", "action")', "State typerelease action")
has(state, 'SetAttribute("pressAndHoldAction", true)', "State keeps pressAndHold")
has(state, "flux-click-", "CHILDUPDATE retargets hidden overlay clickbutton")
has(state, 'self:SetAttribute("macrotext", body)', "CHILDUPDATE stamps surface overlay macrotext")
has(state, 'self:SetAttribute("type", "macro")', "CHILDUPDATE uses type=macro for surface overlays")
has(state, 'self:SetAttribute("type", "click")', "CHILDUPDATE uses type=click for hidden overlays")
if state:find('clicker or mode == "h"', 1, true) then
	failures[#failures + 1] = "CHILDUPDATE must not type=click without a clicker frame"
end
has(state, 'self:SetAttribute("action", slot)', "CHILDUPDATE keeps action=slot for the live face")
do
	local i = state:find("local CHILDUPDATE = ", 1, true)
	local j = i and state:find("local function RowId", i, true)
	local body = (i and j and state:sub(i, j - 1)) or ""
	-- The click sets only move with page / promotion / occupancy, never on a
	-- modifier edge, so they get their own guard and holding SHIFT stays cheap.
	has(body, "flux-applied-mods", "click sets are guarded separately from the live face")
	has(body, 'pfx = "shift-"', "CHILDUPDATE stamps the shift set")
	has(body, 'pfx = "ctrl-"', "CHILDUPDATE stamps the ctrl set")
	has(body, 'pfx = ""', "CHILDUPDATE stamps the nomod set so a bare press cannot use the live face")
	has(body, 'pfx .. "action*"', "CHILDUPDATE uses the documented * button wildcard")
	has(body, 'pfx .. "type*"', "CHILDUPDATE stamps the per-set overlay type")
	has(body, 'pfx .. "macrotext*"', "CHILDUPDATE stamps the per-set overlay body")
	has(body, 'pfx .. "clickbutton*"', "CHILDUPDATE retargets the per-set hidden overlay")
	has(body, 'pfx .. "IsEmpowerSpell*"', "empower gate follows the per-set slot")
	has(body, "slotNomod * 1000000", "the click-set guard covers all three slots")
	-- Layout.ApplyMappings cannot stamp while structural work is locked down, so
	-- a fight entered before the first stamp left hasSec 0 and SHIFT never
	-- left the main row. HasAction is in the restricted env; sec/tert do not
	-- depend on the page, so the probe is cached off the modifier edge.
	has(body, "if not liveSec and HasAction then", "CHILDUPDATE probes live minirow occupancy once")
	has(body, 'self:SetAttribute("flux-live-sec", liveSec)', "the occupancy probe is cached")
	has(body, "if liveSec == 1 then hasSec = 1 end", "live occupancy only promotes the flag upward")
end
if state:find('SetAttribute("shift-actionpage"', 1, true) then
	failures[#failures + 1] = "shift-actionpage is dead on SetID(0) hosts (CalculateAction never reaches page math)"
end
has(state, "_childupdate-fluxreset", "hosts can have their applied stamps cleared")
do
	local i = state:find("local CHILDRESET = ", 1, true)
	local j = i and state:find("local CHILDUPDATE = ", i, true)
	local body = (i and j and state:sub(i, j - 1)) or ""
	has(body, "flux-applied-mods", "fluxreset drops the twin guard as well")
	has(body, "flux-live-sec", "fluxreset drops the cached occupancy probe")
end
if state:find("widget.bar =", 1, true) then
	failures[#failures + 1] = "State.Attach must not set widget.bar (UpdateFlyout GetSpellFlyoutDirection)"
end
if state:find("flux-p-idle-", 1, true) then
	failures[#failures + 1] = "CHILDUPDATE must not write idle macrotext onto the strip"
end
has(state, "function State.GetClassStances", "stance tokens for Binding forms")
has(state, "PACK_MINI", "SHIFT/CTRL minis keep live bonus/override page")
has(state, 'Drive(headers.sec, "native", native)', "SHIFT mini follows form/bonus page")
has(state, 'Drive(headers.tert, "native", native)', "CTRL mini follows form/bonus page")
if state:find("Resting mini row: form/bonus native flips must not ChildUpdate", 1, true)
	or state:find("if swap == 0 then", 1, true)
then
	-- ok: PACK_MINI skips resting ChildUpdate
else
	failures[#failures + 1] = "PACK_MINI must skip ChildUpdate while minis are at rest"
end
if state:find('SetAttribute("pressAndHoldAction", false)', 1, true) then
	failures[#failures + 1] = "State must not clear pressAndHoldAction (kills mouse-up)"
end
if state:find("action-%s*..%s*state", 1, false) and state:find("BakeMain", 1, true) then
	failures[#failures + 1] = "State still bakes action-state attrs"
end
if state:find("function State.BakeMain", 1, true) then
	failures[#failures + 1] = "BakeMain should be gone"
end

local slotProgram = read("SlotProgram.lua")
has(slotProgram, "function SlotProgram.ApplyMap", "SlotProgram bulk apply")
has(slotProgram, "FluxSlotClick_", "hidden SAB holds edge-case overlay bodies")
has(slotProgram, "programModes", "surface vs hidden overlay mode is tracked")
has(slotProgram, "SyncSurfaceFace", "surface overlay syncs the strip face env")
has(slotProgram, 'widget:SetAttribute("type", "macro")', "surface overlay is type=macro on the visible host")
has(slotProgram, 'widget:SetAttribute("type", "click")', "hidden overlay is type=click on the visible host")
has(slotProgram, "ArmMacroDelegate", "hidden clickers get typerelease so delegate:Click fires")
if slotProgram:find('clicker or mode == "hidden"', 1, true) then
	failures[#failures + 1] = "ApplyLiveType must not type=click without a clicker frame"
end
has(slotProgram, "hasOverlay", "overlay occupancy is distinct from plain action slots")
do
	local i = slotProgram:find("local function ApplyLiveType", 1, true)
	local j = i and slotProgram:find("SlotProgram.ApplyLiveType = ApplyLiveType", i, true)
	local body = (i and j and slotProgram:sub(i, j - 1)) or ""
	has(body, "PF.SyncHost", "plain swap rebinds the live slot without TranslateMacro")
	has(body, "host.slot or tonumber", "form IndexSlot is the live overlay slot")
	has(body, "PF.TranslateHost", "overlay swap still TranslateHost")
	has(body, "TranslateHost(host, true)", "overlay swap defers UpdateDisplay to the dirty flush")
	has(body, "ApplyNativeCheck", "ApplyLiveType restamps Forever native check after type swaps")
	if body:find("hasOverlay or not ContextOwnsDisplay", 1, true) then
		failures[#failures + 1] = "ApplyLiveType must SyncHost plain occupancy even when Context owns"
	end
end
has(slotProgram, "function SlotProgram.GetAllHover", "hover-only overlay bodies are enumerable")
has(slotProgram, "function SlotProgram.ClickButtonName", "hidden clicker name is enumerable")
has(slotProgram, "programs[slot] == text", "SlotProgram skips unchanged bodies")
has(slotProgram, 'ATTR = "flux-p-"', "SlotProgram stamps flux-p-<slot>")
has(slotProgram, "function SlotHost.GetAllBarSlots", "implicit Binding scan has bar slots")
has(slotProgram, "function SlotProgram.GetIdle", "display/index uses idle overlay without factory mouseover")
has(slotProgram, "idlePrograms", "factory mouseover is not a macro comment")

local badgeHost = read("BadgeHost.lua")
has(badgeHost, "Hosts.LiveSlot", "badges follow the indexed slot on form paging")
has(badgeHost, "local MAX_BADGES = 3", "three corner badges")
has(badgeHost, "function BadgeHost.ApplyMap", "BadgeHost bulk apply")
has(badgeHost, "function BadgeHost.RefreshFormVisibility", "form visibility retranlates reverse")
has(badgeHost, "conditionalMacro", "conditional reverse badges use ephemeral macrotext")
has(badgeHost, "local function TranslateConditionalBadge", "badge reverse parse is shared")
has(badgeHost, 'badge:SetAction("macrotext"', "conditional badges carry live macrotext")
has(badgeHost, "Identity.SlotKey", "hiddenSwap reads Flux.Identity")
has(badgeHost, "function BadgeHost.EachIndexedBody", "badge reverse bodies join the cond index")
has(badgeHost, "function BadgeHost.OnIdentityChange", "identity change alphas one column")
has(badgeHost, "function BadgeHost.SyncShownFaces", "vis settles after overlay and reverse publish")
has(badgeHost, "PaintBadgeFace", "reverse swap paints item/spell count on the new face")
has(badgeHost, "RestoreWantDefault", "empty reverse parse restores the configured idle face")
has(badgeHost, "BarPublishedFace", "flip-back compares reverse to published bar identity")
has(badgeHost, "ArmTrailingFaces", "badge vis has a one-tick SecureCmdOptionParse catch")
has(badgeHost, "Paint.UpdateIcon", "restored default face paints the idle icon")
if badgeHost:find("cdNumber == false and badge.WCount", 1, true) then
	failures[#failures + 1] = "cdNumber must not Hide stack/charge count"
end
do
	local i = badgeHost:find("function BadgeHost.OnIdentityChange", 1, true)
	local j = i and badgeHost:find("function BadgeHost.SyncShownFaces", i, true)
	local body = (i and j and badgeHost:sub(i, j - 1)) or ""
	has(body, "pendingVis", "bar identity does not hiddenSwap-hide against a stale badge")
	has(body, "ParseSlotKey", "slot keys are deferred vis")
	has(body, "ArmTrailingFaces", "bar paint identity change retranlates reverse")
end
do
	local i = badgeHost:find("local function RestoreWantDefault", 1, true)
	local j = i and badgeHost:find("local function PublishBadgeIdentity", i, true)
	local body = (i and j and badgeHost:sub(i, j - 1)) or ""
	has(body, "SameShownFace", "reverse still matching the bar restores the idle face")
	has(body, "BarPublishedFace", "same-as-bar restore reads overlay identity, not ShownForSlot cache")
end
do
	local i = badgeHost:find("local function RunTrailingFaces", 1, true)
	local j = i and badgeHost:find("local function ArmTrailingFaces", i, true)
	local body = (i and j and badgeHost:sub(i, j - 1)) or ""
	has(body, "InvalidateMacroParseCache", "trailing reverse does not reuse a lagged parse cache")
end
do
	local i = badgeHost:find("local function TranslateConditionalBadge", 1, true)
	local j = i and badgeHost:find("local function ApplyWant", i, true)
	local body = (i and j and badgeHost:sub(i, j - 1)) or ""
	has(body, 'ActionType = "macrotext"', "combat still arms the reverse env")
	has(body, "TranslateMacro", "conditional badges reparse without SetAction")
	local lock = body:find("if not InLockdown()", 1, true)
	local trans = body:find("pcall(Action.TranslateMacro", 1, true)
	if lock and trans and trans < (body:find("else", lock, true) or trans) then
		failures[#failures + 1] = "TranslateMacro must run in combat, not only inside the OOC SetAction guard"
	end
end
has(badgeHost, "GetVisibleBadgesForButton", "visible badges are listed for column VFX")
has(badgeHost, "_fluxBadgeCombatVisHidden", "alpha-0 corners stamp combat vis hidden")
do
	local i = badgeHost:find("function SyncHost", 1, true)
	local j = i and badgeHost:find("function SyncSlot", i, true)
	local body = (i and j and badgeHost:sub(i, j - 1)) or ""
	local lock = body:find("if InLockdown() then", 1, true)
	local afterLock = lock and body:sub(lock, lock + 500) or ""
	if afterLock:find("SetParent", 1, true) or afterLock:find("SetPoint", 1, true) then
		failures[#failures + 1] = "BadgeHost combat path must not SetParent/SetPoint"
	end
	if not afterLock:find("PaintCorners", 1, true) then
		failures[#failures + 1] = "BadgeHost combat path must alpha-show existing stacks"
	end
	has(body, "if not full and set then", "paging/form do not reparent existing stacks")
end
has(badgeHost, "function BadgeListFingerprint", "unchanged badge lists skip SetSlotBadges")
do
	local i = badgeHost:find("function BadgeHost.SetSlotBadges", 1, true)
	local j = i and badgeHost:find("function BadgeHost.ApplyMap", i, true)
	local body = (i and j and badgeHost:sub(i, j - 1)) or ""
	has(body, "BadgeListFingerprint(slotBadges[slot]) == BadgeListFingerprint(badgeList)", "SetSlotBadges no-ops when the list fingerprint is unchanged")
end

local bindApply = read("../Binding/Core/Apply.lua")
has(bindApply, "function FluxBinding.RequestApplyAll", "Binding apply API")
local bindTip = read("../Binding/Core/BindingTooltip.lua")
has(bindTip, "function BT.AppendForButton", "BindingTooltip appends peers/badges/multi-cast")
has(bindTip, "FluxActionStripButton", "BindingTooltip recognizes strip hosts")
has(bindTip, "function BT.OnLabTooltip", "BindingTooltip retries after TooltipDataProcessor")
has(bindTip, "TooltipDataProcessor", "retail BindingTooltip uses PostCall")
has(bindTip, "SetAction", "BindingTooltip hooks SetAction")
has(bindApply, "FluxActionBarPeekSlotOccupancyChanged", "occupancy peek skips texture-only ASC")
has(bindApply, "lastPlanSig", "Apply skips unchanged plan signature")
do
	local i = bindApply:find("local function BuildOccupancyKey", 1, true)
	local j = i and bindApply:find("function _G.FluxActionBarPeekSlotOccupancyChanged", i, true)
	local body = (i and j and bindApply:sub(i, j - 1)) or ""
	has(body, "GetActionInfo", "occupancy is action type+id")
	if body:find("GetMacroSpell", 1, true) or body:find("GetMacroItem", 1, true) then
		failures[#failures + 1] = "occupancy key must not include GetMacroSpell (mouseover flips)"
	end
end
has(bindApply, "FluxActionBarPeekSlotOccupancyPrevious", "peek keeps the previous occupant for relocate")
has(bindApply, "prevSlotSpellCache[slotNum] = lastSlotSpellCache[slotNum]", "peek stores the prior occupancy key")
has(bindApply, "occupancyDirty[slotNum] = true", "peek dirty survives Extra's earlier peek")
has(bindApply, "function _G.FluxActionBarConsumeOccupancyDirty", "Watch consumes occupancy dirty after flush")
has(bindApply, "function FluxBinding.NotifyOccupancyChanged", "occupancy drag/drop has a targeted notify")
has(bindApply, "local function RelocatePlaceIds", "ab: placeIds follow a unique occupant move")
has(bindApply, "occ = BuildOccupancyKey(slot)", "relocate peeks live occupancy on dirty dest slots")
has(bindApply, "local function FilterBucketForBarSlot", "moved spells are not peer overlays on the old chord")
has(bindApply, "function BindingOccupiesOtherSlot", "occupancy overlay excludes a spell that lives elsewhere")
has(bindApply, "not NativeMatchesBinding(SlotNative(placeSlot), b)", "stale ab: pin still overlays the live occupant")
do
	local i = bindApply:find("local function SpellNativeFromId", 1, true)
	local j = i and bindApply:find("local function SlotNative", i, true)
	local body = (i and j and bindApply:sub(i, j - 1)) or ""
	has(body, 'kind = "spell"', "uncached bar spell stays a spell slot")
	has(body, "RequestSpellData", "missing spell name requests spell data")
	if body:find('kind = "empty"', 1, true) then
		failures[#failures + 1] = "SpellNativeFromId must not treat a missing name as an empty slot"
	end
end
has(bindApply, "SPELL_DATA_LOAD_RESULT", "spell data load schedules binding apply")
has(bindApply, "unread = true", "unreadable bar spell stays in the binding plan")
has(bindApply, "native.actionKey or native.unread", "static badge installs when the bar spell cannot be read")
local bindAction = read("../Binding/Core/Action.lua")
has(bindAction, "function Action.SpellDataCached", "rank subtext waits for cached spell data")
has(bindAction, "IsSpellDataCached", "SpellDataCached uses C_Spell when present")
has(bindAction, "Action.SpellDataCached(desc.id)", "MacroToken skips rank text until cached")
has(bindAction, "PlayerSpellBook", "spellbook rows keep a rank binding available")
do
	local i = bindApply:find("local function SchedulePeekWaveClear", 1, true)
	local j = i and bindApply:find("local function BuildOccupancyKey", i, true)
	local body = (i and j and bindApply:sub(i, j - 1)) or ""
	has(body, "wipe(peekWaveResult)", "After(0) only drops the per-wave occupancy memo")
	if body:find("wipe(prevSlotSpellCache)", 1, true) then
		failures[#failures + 1] = "After(0) must not wipe prev occupancy before Watch/Binding consume it"
	end
	if body:find("wipe(occupancyDirty)", 1, true) then
		failures[#failures + 1] = "After(0) must not wipe occupancyDirty before Watch Flush"
	end
end
do
	local i = bindApply:find("function FluxBinding.NotifyOccupancyChanged", 1, true)
	local j = i and bindApply:find("function FluxBinding.NotifyBarSlotChanged", i, true)
	local body = (i and j and bindApply:sub(i, j - 1)) or ""
	has(body, "dirtySet, relocated", "occupancy notify uses relocate result")
	has(body, "interesting = relocated", "relocated pins always Binding-Apply")
end
has(bindApply, "local function RunOccupancyApply", "drag/drop stamps dirty slots without a full-bar apply")
has(bindApply, "SlotIsInteresting", "unrelated default occupancy does not Binding-Apply")
do
	local i = bindApply:find("local function RunOccupancyApply", 1, true)
	local j = i and bindApply:find("local function PlanSignature", i, true)
	local body = (i and j and bindApply:sub(i, j - 1)) or ""
	if body:find("FluxActionBarSeedSlotOccupancyCache", 1, true) then
		failures[#failures + 1] = "occupancy apply must not reseed 180 occupancy keys"
	end
	if body:find("ApplyMap", 1, true) and body:find("clearMissing", 1, true) then
		failures[#failures + 1] = "occupancy apply must not ApplyMap(clearMissing) globally"
	end
	has(body, "ComputePlan(slotSet)", "occupancy apply recomputes only dirty slots")
end
do
	local i = bindApply:find("-- 2. occupancy overlays", 1, true)
	local j = i and bindApply:find("local SlotHost", i, true)
	local body = (i and j and bindApply:sub(i, j - 1)) or ""
	if body:find("if not b.key and Action.IsAvailable", 1, true) then
		failures[#failures + 1] = "occupancy overlay must index keyed customized rows by actionKey"
	end
	has(body, "Action.IsAvailable(b.action)", "occupancy overlay indexes customized docs by actionKey")
end
has(bindApply, "OverlayIdleBody", "factory mouseover is stripped off the click body for display")
has(bindApply, "StripOverlayMode", "Binding installs surface vs hidden strip overlays")
has(bindApply, "conditionalMacro", "badges flag conditional reverse macrotext")
do
	local i = bindApply:find("local function PreferModEntriesFirst", 1, true)
	local j = i and bindApply:find("local function BuildGroupsForSlot", i, true)
	local body = (i and j and bindApply:sub(i, j - 1)) or ""
	has(body, "SubHasMacroCondition", "[combat] peers sort before unrestricted overlays")
	if body:find("SubHasModCondition", 1, true) and not body:find("SubHasMacroCondition", 1, true) then
		failures[#failures + 1] = "PreferModEntriesFirst must sort all baked-macro peers, not only mods"
	end
end
do
	local i = bindApply:find("local function BuildGroupsForSlot", 1, true)
	local j = i and bindApply:find("local function BuildBadges", i, true)
	local body = (i and j and bindApply:sub(i, j - 1)) or ""
	has(body, "SubOverlaySig", "form groups collapse by overlay settings")
	has(body, "SplitFormConds", "subset forms merge into compact [form:1/3]")
	has(body, "formCond = nil", "all-forms overlay omits [form:] gates")
	if body:find("tostring(sub)", 1, true) then
		failures[#failures + 1] = "BuildGroupsForSlot must not key form groups on sub table identity"
	end
end
do
	local i = bindApply:find("local function RefreshBadgeForms", 1, true)
	local j = i and bindApply:find("function FluxBinding.HasActiveWork", i, true)
	local body = (i and j and bindApply:sub(i, j - 1)) or ""
	if body:find("ScheduleApply", 1, true) or body:find("RequestApplyAll", 1, true) then
		failures[#failures + 1] = "Binding must not Apply on form/stealth"
	end
	if not body:find("RefreshFormVisibility", 1, true) then
		failures[#failures + 1] = "form event must alpha-refresh badges only"
	end
	has(body, "HasSubscribers", "Binding form vis yields to Context display pass")
	-- Blizzard repeats UPDATE_SHAPESHIFT_FORM for one shapeshift; the raw
	-- listener walked every badge slot on each repeat.
	if not body:find('FormStorm.OnBurst("binding.badgeforms"', 1, true) then
		failures[#failures + 1] = "Binding badge form refresh must ride the FormStorm edge filter"
	end
end
local bindCond = read("../Binding/Core/Conditions.lua")
has(bindCond, "Do NOT reapply secure macros on UNIT_PET", "Binding must not reapply on UNIT_PET")
has(bindCond, "function Conditions.SubHasMacroCondition", "combat/stealth count as overlay conditionals")
local bindForms = read("../Binding/Core/Forms.lua")
has(bindForms, "function Forms.ConditionGroupsForTokens", "subset forms share one [form:1/3] gate")
has(bindForms, 'table.concat(parts, "/")', "form indexes OR-merge")
local bindChord = read("../Binding/Core/ChordMap.lua")
has(bindChord, "SlotMath.Resolve", "chords resolve live strip slots")
if bindChord:find("GetEffectiveActionSlot", 1, true) then
	failures[#failures + 1] = "ChordMap must not use LAB GetEffectiveActionSlot"
end
has(bindApply, "FluxActionStripButton", "bar-mod click-through targets the strip")
has(bindApply, '"KeyBind"', "bar-mod click-through uses KeyBind")
if bindApply:find('SetOverrideBindingClick(overrideOwner, false, nk, btnName, "Keybind")', 1, true) then
	failures[#failures + 1] = "Binding click-through must use KeyBind (ButtonFX), not Keybind"
end
if bindApply:find("ArmMacroDelegate", 1, true) then
	failures[#failures + 1] = "Binding override SABs must not ArmMacroDelegate (typerelease double-cast)"
end
do
	local pool = read("../Binding/Core/SecurePool.lua")
	has(pool, "function Pool.ArmMacroDelegate", "hidden clicker delegates get typerelease")
	has(pool, '"useOnKeyDown", true', "pool useOnKeyDown spelling")
	if pool:find("useOnkeyDown", 1, true) then
		failures[#failures + 1] = "SecurePool must not typo useOnkeyDown"
	end
	local i = pool:find("function Pool.Acquire", 1, true)
	local j = pool:find("function Pool.ArmMacroDelegate", 1, true)
	local acquire = (i and j and pool:sub(i, j - 1)) or ""
	if acquire:find('SetAttribute("typerelease"', 1, true) then
		failures[#failures + 1] = "Binding override pool Acquire must not set typerelease (double-cast)"
	end
end

local toc = read("../_FluxUI.toc")
has(toc, "Binding\\Core\\Apply.lua", "TOC loads Binding apply")
has(toc, "Binding\\Core\\BindingTooltip.lua", "TOC loads action-bar Binding tooltips")
has(toc, "Binding\\Boot.lua", "TOC loads Binding boot")
has(toc, "Binding\\UI\\Editor\\Core.lua", "TOC loads Binding editor")
has(toc, "AddonOptions\\FluxOptionsBinding.lua", "TOC loads Binding options tab")
has(toc, "Bars\\BadgeHost.lua", "TOC loads BadgeHost")
has(toc, "Bars\\SlotProgram.lua", "TOC loads SlotProgram")
has(toc, "Bars\\ProgramFace.lua", "TOC loads ProgramFace")
do
	local sp = toc:find("Bars\\SlotProgram.lua", 1, true)
	local pf = toc:find("Bars\\ProgramFace.lua", 1, true)
	if not (sp and pf) or pf < sp then
		failures[#failures + 1] = "ProgramFace must TOC-load after SlotProgram"
	end
end
local programFace = read("ProgramFace.lua")
has(programFace, "_fluxStripFace", "strip face env is Extra-shaped, no widget")
has(programFace, "pcall(Action.TranslateMacro", "strip TranslateMacro cannot abort the bar")
has(programFace, "function ProgramFace.TranslateHost", "per-host Extra TranslateMacro")
has(programFace, "host._fluxFaceSlot", "face identity is bound to the live action slot")
has(programFace, "Hosts.LiveSlot", "form paging face uses the indexed slot")
has(programFace, "InvalidateShownSlot", "slot swap drops the per-slot shown cache")
has(programFace, "deferPaint", "paging TranslateHost can skip UpdateDisplay")
has(programFace, "face.MacroTarget = nil", "plain occupancy drops leftover MacroTarget")
has(paint, "keeps the last good face", "filled overlay slots never hide to empty")
has(programFace, "function ProgramFace.TranslateAll", "strip faces refresh together")
has(programFace, "function ProgramFace.RequestConditionalRefresh", "condition flips paint the strip, not just Extra")
has(programFace, "function ProgramFace.Request", "kinded cond hub")
has(programFace, "function ProgramFace.FlushPending", "eval flushes cond before paint")
has(programFace, '"flux.cond"', "condition refresh is scheduler-coalesced")
has(programFace, "function ProgramFace.ClassifyBody", "bodies are indexed by condition kind")
has(programFace, "BodyHasUserMouseover", "factory native mouseover-cast tails do not arm cond.mo")
has(programFace, "FACTORY_NO_MO", "Binding #flux-no-mo is ignored for mouseover kind")
do
	local i = programFace:find("function ProgramFace.RebuildIndex", 1, true)
	local j = i and programFace:find("function ProgramFace.Needs", i, true)
	local body = (i and j and programFace:sub(i, j - 1)) or ""
	has(body, "SP.GetAll", "RebuildIndex indexes SlotProgram overlays")
	has(body, "EachIndexedBody", "RebuildIndex indexes badge reverse")
	has(body, "IdleMacro", "overlay index uses IdleMacroText")
	has(body, "GetIdle", "index prefers idle overlay without factory mouseover")
end
has(programFace, "MOUSEOVER", "mouseover cond is token-gated")
has(programFace, "MOUSEOVER_COALESCE", "mouseover parse is trailing-coalesced")
has(programFace, "lastKindSig", "every cond kind has a snapshot skip")
has(programFace, "lastAllFrame", "Request all is at most once per frame")
has(programFace, "local function SameKind", "unchanged mod/combat/target snapshots skip parse")
has(programFace, "local function ModSig", "[mod] skip is shift/ctrl/alt bits")
has(programFace, "local function CombatSig", "[combat]/[mounted]/[group]/[channel] share one snapshot")
has(programFace, "local function TargetSig", "[harm]/[help]/[@focus]/[@pet] skip on same reaction")
has(programFace, "function ProgramFace.ArmMouseoverPoll", "leave-to-empty is a reaction-class poll")
has(programFace, "function ProgramFace.NoteMouseoverEvent", "UMU stamps the poll so it sleeps during a sweep")
has(programFace, "MO_POLL_INTERVAL", "leave-to-empty poll is not per-frame")
has(programFace, "function ProgramFace.EachExtraMatching", "Extra cond flush uses cached kind lists")
has(programFace, "function ProgramFace.EachBody", "strip overlay bodies arm Extra's condition ticker")
has(programFace, "GetActionInfo", "strip re-parses Blizzard slot macros like Extra")
has(programFace, "SP.HasHover", "hover-only overlays still translate")
do
	local i = programFace:find("function ProgramFace.RequestConditionalRefresh", 1, true)
	local j = i and programFace:find("\nfunction ProgramFace.", i + 10, true)
	local body = (i and j and programFace:sub(i, j - 1)) or ""
	if body:find("Paint.Flush", 1, true) then
		failures[#failures + 1] = "RequestConditionalRefresh must not Paint.Flush (scheduler only)"
	end
	if body:find("TranslateAll", 1, true) then
		failures[#failures + 1] = "RequestConditionalRefresh must not TranslateAll (kinded flush)"
	end
	has(body, 'ProgramFace.Request("all")', "RequestConditionalRefresh is Request all")
end
do
	local i = programFace:find("function ProgramFace.NoteMouseoverEvent", 1, true)
	local j = i and programFace:find("function ProgramFace.ArmMouseoverPoll", i, true)
	local body = (i and j and programFace:sub(i, j - 1)) or ""
	has(body, "MOUSEOVER_COALESCE", "UMU parse waits until the hop burst ends")
	has(body, "moDueAt", "mouseover parse is trailing-debounced across hops")
	has(body, "indexDirty", "UMU uses the cached mouseover need, not RebuildIndex")
	if body:find("EnsureIndex", 1, true) then
		failures[#failures + 1] = "NoteMouseoverEvent must not RebuildIndex on every hop"
	end
	if body:find("Needs(", 1, true) then
		failures[#failures + 1] = "NoteMouseoverEvent must not Needs() on every hop"
	end
	if body:find('Scheduler.Request("eval", "flux.cond")', 1, true) then
		failures[#failures + 1] = "NoteMouseoverEvent must not schedule eval on the event"
	end
end
do
	local i = programFace:find("function ProgramFace.FlushPending", 1, true)
	local j = i and programFace:find("function ProgramFace.Request(", i, true)
	local body = (i and j and programFace:sub(i, j - 1)) or ""
	has(body, "mouseoverOnly", "mouseover flush is a dirty-host pass")
	has(body, "not mouseoverOnly", "mouseover must not NotifyModifierPaging")
	has(body, "badgeHit", "badge-only [mod]/[harm] still retranlates reverse")
	if body:find("BadgeHost.NotifyModifierPaging", 1, true) or body:find("BH.NotifyModifierPaging", 1, true) then
		failures[#failures + 1] = "FlushPending must not NotifyModifierPaging (races Identity)"
	end
	has(body, "SyncShownFaces", "cond flush settles badge vis after reverse")
end
has(programFace, "Paint.UpdateAll", "changed overlay faces FullRefresh that host only")
do
	local i = programFace:find("function ProgramFace.TranslateHost", 1, true)
	local j = i and programFace:find("\nfunction ProgramFace.ShownForSlot", i, true)
	local body = (i and j and programFace:sub(i, j - 1)) or ""
	if body:find("MacroTarget ~= beforeTarget", 1, true) then
		failures[#failures + 1] = "TranslateHost must not FullRefresh on MacroTarget hops"
	end
	has(body, "face.SpellId ~= beforeSpell", "TranslateHost paints when the shown spell changes")
end
if programFace:find("n.mod = true\n\t\tn.combat = true", 1, true)
	or programFace:find("if not (n.mod or n.combat or n.mouseover or n.target)", 1, true)
then
	failures[#failures + 1] = "[form]-only bodies must not ride [mod]/[combat]/[target]"
end
has(programFace, "function ProgramFace.RequestTarget", "tab-target [harm] shares Request target skip")
has(programFace, 'string.find(u, "GROUP"', "[group]/[raid]/[party] ride the combat kind")
has(programFace, 'string.find(u, "CHANNEL"', "[channeling] rides the combat kind")
has(programFace, 'string.find(u, "VEHICLE"', "[vehicleui] rides the combat kind")
has(programFace, "ExtraParked", "Extra window parked skip still exists")
has(programFace, "btn.badgeMode", "alpha-0 badges still parse identity")
has(programFace, "function ProgramFace.OnContext", "ProgramFace rides Flux.Context")
has(programFace, "function ProgramFace.ContextOwnsDisplay", "Watch/Extra skip eval when Context is subscribed")
has(programFace, "function ProgramFace.Start", "ProgramFace subscribes Context at strip start")
has(programFace, "SP.GetAll()", "RebuildIndex covers SlotProgram overlays")
has(programFace, "EachIndexedBody", "RebuildIndex covers badge reverse")
has(programFace, "IdleMacro", "factory mouseover tails use IdleMacroText")
has(programFace, "Identity.SlotKey", "ShownForSlot prefers Identity")
do
	local i = programFace:find("function ProgramFace.OnContext", 1, true)
	local j = i and programFace:find("\nfunction ProgramFace.ContextOwnsDisplay", i, true)
	local body = (i and j and programFace:sub(i, j - 1)) or ""
	has(body, "ufPeekChanged", "strip display overrides only on UF peek edges")
	has(body, "stripHit", "badge reverse still refreshes when Extra-only is false")
	has(body, "SyncShownFaces", "badge vis settles after reverse publish")
	has(body, "kinds.mod", "SHIFT still SyncShownFaces when no overlay has [mod]")
	if body:find('Bars.RequestPaint("bars.icon")', 1, true) then
		failures[#failures + 1] = "OnContext must not 4-lane paint every hop"
	end
	if body:find("NotifyModifierPaging", 1, true) then
		failures[#failures + 1] = "OnContext must not NotifyModifierPaging (Identity + OnActionAttribute)"
	end
	if body:find("ApplyStripDisplayOverrides(info.ufPeek)", 1, true)
		and not body:find("info.ufPeekChanged and SP", 1, true)
	then
		failures[#failures + 1] = "ApplyStripDisplayOverrides must not walk 57 hosts on every hop"
	end
end
do
	local i = programFace:find("function ProgramFace.FlushPending", 1, true)
	local j = i and programFace:find("function ProgramFace.Request(", i, true)
	local body = (i and j and programFace:sub(i, j - 1)) or ""
	if body:find("bars.icon", 1, true) or body:find("CondPaintTokens", 1, true) then
		failures[#failures + 1] = "cond flush must not 6-lane every live host"
	end
end
do
	local i = programFace:find("function ProgramFace.RequestHoverPeek", 1, true)
	local body = i and programFace:sub(i) or ""
	has(body, "SP.HasHover", "peek no-ops without hover-only programs")
	has(body, "TranslateHoverSlots", "peek translates hover slots only")
	if body:find("TranslateAll", 1, true) then
		failures[#failures + 1] = "RequestHoverPeek must not TranslateAll"
	end
	if body:find("Effects.RefreshAll", 1, true) then
		failures[#failures + 1] = "RequestHoverPeek must not Effects.RefreshAll"
	end
end
do
	local i = programFace:find("function ProgramFace.Shown(host)", 1, true)
	local j = i and programFace:find("\nlocal function ArmPeekPoller", i, true)
	local body = (i and j and programFace:sub(i, j - 1)) or ""
	has(body, "face.MacroBody == body", "Shown reuses a cond-pass face instead of re-parsing")
	has(body, "_fluxCondStamp == condStamp", "Shown reuse is only valid for the current cond pass")
	has(body, "condBodies[slot]", "Shown does not GetActionInfo on plain spells")
end
has(programFace, "Action.SyncMacroProbes", "strip [flying]/[@mouseover] arms the Extra ticker")
has(programFace, "widget.FluxButton", "strip overlay is the occupancy FluxButton")
has(programFace, "badgeMode = false", "badgeMode is a rank flag, not the overlay env")
has(programFace, "ActionType = \"macrotext\"", "strip env is macrotext like Extra window macros")
if programFace:find("Widget.Create", 1, true) then
	failures[#failures + 1] = "ProgramFace must not create Extra widgets"
end
if programFace:find("IdentityDrive", 1, true) then
	failures[#failures + 1] = "ProgramFace must not use IdentityDrive"
end
do
	local pfn, perr = loadfile(dir .. "/ProgramFace.lua")
	if not pfn then
		failures[#failures + 1] = "ProgramFace.lua syntax: " .. tostring(perr)
	end
end
has(slotProgram, "SyncSurfaceFace", "SlotProgram apply syncs the live strip face env")
has(badgeHost, "PF.ShownForSlot", "hiddenSwap falls back to ShownForSlot")
do
	local i = badgeHost:find("function BadgeHost.NotifyModifierPaging", 1, true)
	local j = i and badgeHost:find("function BadgeHost.RefreshDisplays", i, true)
	local body = (i and j and badgeHost:sub(i, j - 1)) or ""
	has(body, "NotifyDisplay", "modifier paging is display/alpha only")
	if body:find("TranslateAll", 1, true) then
		failures[#failures + 1] = "NotifyModifierPaging must not TranslateAll"
	end
end
has(paint, "ProgramFace", "strip paint prefers Extra env identity")
has(paint, "host._fluxFace", "strip icon can use Extra MacroTexture")
has(paint, "Identity.SlotKey", "paint prefers Identity shown face")
if badgeHost:find("hooksecurefunc", 1, true) then
	failures[#failures + 1] = "BadgeHost must not hooksecurefunc Frame C methods"
end
if slotProgram:find("hooksecurefunc", 1, true) then
	failures[#failures + 1] = "SlotProgram must not hooksecurefunc Frame C methods"
end
if bindApply:find("IdentityDrive", 1, true) or bindApply:find("FluxActionBarSmart", 1, true) then
	failures[#failures + 1] = "Binding Apply must not use LAB IdentityDrive / FluxActionBarSmart"
end

has(toc, "Binding\\Input\\FluxMouseoverKeybind.lua", "TOC loads UF hovercast installer")
do
	local applyAt = toc:find("Binding\\Core\\Apply.lua", 1, true)
	local kbAt = toc:find("Binding\\Input\\FluxMouseoverKeybind.lua", 1, true)
	if not (applyAt and kbAt) or kbAt < applyAt then
		failures[#failures + 1] = "FluxMouseoverKeybind must TOC-load after Binding Apply"
	end
end
local keybind = read("../Binding/Input/FluxMouseoverKeybind.lua")
has(keybind, "FluxActionStripButton", "Keybind bar targets are strip hosts")
has(keybind, "function FluxMouseoverKeybind:IsHovercastPeekMouseContext", "UF peek is registered-frame geometry")
has(keybind, "RequestHoverPeek", "UF enter/leave peeks rewrite display")
has(keybind, "ufHoverCount", "hovercast unit-exists driver arms only while a UF is hovered")
has(keybind, "HookUfHoverDriver", "UF hover count follows owner and wrapped children")
has(keybind, "WrapHovercastMouseChildren(frame)", "children wrap once at RegisterFrame")
do
	local i = keybind:find("if not frame._fluxMacrotextPeekHooked", 1, true)
	local j = i and keybind:find("table.insert(registeredFrames", i, true)
	local body = (i and j and keybind:sub(i, j - 1)) or ""
	if body:find("WrapHovercastMouseChildren", 1, true) then
		failures[#failures + 1] = "hovercast children must not wrap on every OnEnter"
	end
end
if keybind:find("if HasActiveRoutingData() then", 1, true) then
	failures[#failures + 1] = "unit-exists driver must not register at login with zero UF hover"
end
has(keybind, "SetPassThroughButtons", "Edit Mode passthrough")
has(keybind, "SetBindingClick", "UF hover arms SetBindingClick")
has(keybind, 'return "LeftButton"', "spell-hover clicks _HC as LeftButton")
has(keybind, 'mbtn or "LeftButton"', "spell-hover binding fallback is LeftButton")
has(bindApply, "local function ArmHovercastClick", "hover _HC click contract")
has(bindApply, 'btn.RegisterForClicks, btn, "AnyDown", "AnyUp"', "hover _HC hears key-up")
has(bindApply, '"macrotext1", body', "hover _HC sets macrotext1")
has(bindApply, '"pressAndHoldAction", false', "hover _HC is not press-and-hold")
has(bindApply, '"useOnKeyDown", true', "hover _HC still casts on classic key-down")
has(keybind, "typeN", "Classic inline typeN")
has(keybind, "RegisterFluxUnitFrames", "registers Flux UF outers")
has(keybind, "IsClickedLoaded", "Clicked coexistence")
local raidFrameSrc = read("../RaidFrame/FluxRaidFrame.lua")
do
	local i = raidFrameSrc:find("function FluxRaidUnit_OnEnter", 1, true)
	local j = i and raidFrameSrc:find("function FluxRaidUnit_OnLeave", i, true)
	local body = (i and j and raidFrameSrc:sub(i, j - 1)) or ""
	has(body, 'type(self.unit) == "string"', "raid OnEnter skips SetUnit without a unit token")
end
do
	local i = raidFrameSrc:find("local function FluxRaid_MTMAApplySecureVisual", 1, true)
	local j = i and raidFrameSrc:find("local function FluxRaid_MTMASafeHideTargetFrame", i, true)
	local body = (i and j and raidFrameSrc:sub(i, j - 1)) or ""
	has(body, "EnableMouse", "MTMA alpha-0 minis disable mouse")
end
local raidUnitSrc = read("../RaidFrame/FluxRaidUnit.lua")
has(raidUnitSrc, "local function FluxRaidUnit_UpdateTooltip(self)", "raid buttons use a Flux tooltip that skips a nil unit")
has(raidUnitSrc, 'type(unit) ~= "string"', "raid tooltip requires a unit string")
if keybind:find("FluxActionButton", 1, true) then
	failures[#failures + 1] = "Keybind must not target leftover FluxActionButton names"
end
if keybind:find("FluxMacrotextDisplay", 1, true) then
	failures[#failures + 1] = "Keybind must not call leftover FluxMacrotextDisplay"
end
do
	local i = slotProgram:find("function SlotProgram.ApplyHoverMap", 1, true)
	local j = slotProgram:find("function SlotProgram.GetHover", i or 1, true)
	local body = (i and j and slotProgram:sub(i, j - 1)) or ""
	has(body, "WriteAllHosts", "ApplyHoverMap writes flux-h hosts")
end
has(programFace, "GetHover", "ProgramFace peeks hover body")
has(programFace, "IsHovercastPeekMouseContext", "ProgramFace gates peek on UF geometry")
has(programFace, "function ProgramFace.RequestHoverPeek", "UF peek refresh")
has(programFace, "PEEK_POLL = 0.05", "leave-frame peek poller")
has(badgeHost, "hoverMacrotext", "badges peek hover reverse")
has(badgeHost, "IsHovercastPeekMouseContext", "badge peek gated on UF")
has(badgeHost, "Visual face is combat-legal", "badge face updates without live macrotext")
has(badgeHost, "function BadgeHost.RefreshDisplays", "badge context display refresh")
has(badgeHost, "function BadgeHost.RefreshMouseoverDisplays", "badge mouseover-only display path")
has(slotProgram, "function SlotProgram.RefreshDisplays", "strip fingerprint display refresh")
has(slotProgram, 'mode == "display"', "native tail keeps type=action click")
has(toc, "Bars\\MacrotextDisplay.lua", "TOC still loads MacrotextDisplay alias")
local macroDisplay = read("MacrotextDisplay.lua")
has(macroDisplay, "Flux.Context", "display Request aliases Context")
has(macroDisplay, "function Display.Request", "MacrotextDisplay.Request still exists")
if macroDisplay:find('RegisterEvent("UPDATE_MOUSEOVER_UNIT"', 1, true) then
	failures[#failures + 1] = "MacrotextDisplay must not own UPDATE_MOUSEOVER_UNIT (Context dual-run)"
end
if macroDisplay:find("ContextFingerprint", 1, true) then
	failures[#failures + 1] = "MacrotextDisplay must not keep a private hop fingerprint"
end
do
	local pos = 1
	while true do
		local i = bindApply:find("forceNativeTail = true", pos, true)
		if not i then
			break
		end
		local window = bindApply:sub(math.max(1, i - 280), i + 40)
		if window:find("mouseoverCast = mouseoverCast", 1, true) then
			failures[#failures + 1] = "forceNativeTail must not keep Action Bars mouseoverCast"
			break
		end
		pos = i + 1
	end
end
has(bindApply, "C.Request(true)", "Binding Apply asks Context to refresh faces")

-- ---------------------------------------------------------------------------
-- Range: one service for the strip, Extra buttons and badges.
--
-- The strip used to poll 57 hosts with a unit-less IsActionInRange while EBS ran
-- its own 0.2s loop over every button and badge. A compiled macrotext overlay
-- therefore painted its icon from the parsed spell but ranged the slot beneath
-- it, and an [@mouseover] / [@focus] macro never ranged at all.
-- ---------------------------------------------------------------------------

local rangeCore = read("../Core/Engine/Range.lua")
has(toc, "Core\\Engine\\Range.lua", "TOC loads the shared range service")
has(toc, "Core\\Engine\\HopLag.lua", "TOC loads hop/mod lag overlay")
do
	local sched = toc:find("Core\\Engine\\Scheduler.lua", 1, true)
	local rng = toc:find("Core\\Engine\\Range.lua", 1, true)
	if not (sched and rng) or rng < sched then
		failures[#failures + 1] = "Range must TOC-load after Scheduler"
	end
end
has(rangeCore, "function Range.ResolveUnit", "one unit-resolution rule")
has(rangeCore, "function Range.CheckSpell", "memoized spell probe")
has(rangeCore, "function Range.CheckItem", "memoized item probe")
has(rangeCore, "function Range.CheckAction", "memoized slot probe")
has(rangeCore, "function Range.RegisterSweep", "surfaces register their own walk")
has(rangeCore, "memoFrame", "probes share one answer per frame")
has(rangeCore, "MOUSEOVER_BURST = 0.2", "mouseover storms ignore per-slot range events")
has(rangeCore, "MouseoverReactionClass", "cond parse shares mouseover reaction class")
has(rangeCore, "TargetReactionClass", "same-reaction tab-target hops skip [harm] parse")
has(rangeCore, "UnitReactionClass", "reaction class is shared for target and mouseover")
has(rangeCore, "MouseoverCastOn", "range knows the mouseover-cast toggle")
has(rangeCore, "MC.IsEnabled", "toggle off ignores leftover mouseover unit")
has(rangeCore, "AllowUnit", "mouseover is gated unless the macro resolved it")
has(rangeCore, 'Ev.Register("PLAYER_TARGET_CHANGED"', "target swap resamples immediately")
do
	local i = rangeCore:find('Ev.Register("PLAYER_TARGET_CHANGED"', 1, true)
	local j = i and rangeCore:find("Ev.Register(", i + 10, true)
	local body = (i and j and rangeCore:sub(i, j - 1)) or ""
	has(body, "lastTargetReaction", "same-reaction tab-target hops skip Invalidate")
end
has(rangeCore, 'Ev.Register("ACTION_RANGE_CHECK_UPDATE"', "range service owns the Blizzard range event")
has(rangeCore, "NeedsMouseoverRange", "world mouseover does not walk 57 hosts unless needed")
has(rangeCore, "function Range.IsHopBurst", "Watch/Paint share the hop-burst clock")
has(paint, "R.IsHopBurst", "NeedsRange does not UnitExists mouseover 57 times during hops")
do
	local i = rangeCore:find('Ev.Register("UPDATE_MOUSEOVER_UNIT"', 1, true)
	local j = i and rangeCore:find("Ev.Register(", i + 10, true)
	local body = (i and j and rangeCore:sub(i, j - 1)) or ""
	has(body, "lastMoAt", "UMU only stamps the burst clock")
	if body:find("Invalidate", 1, true) then
		failures[#failures + 1] = "UPDATE_MOUSEOVER_UNIT must not Range.Invalidate"
	end
end
has(paint, "function Paint.ApplySlotRange", "per-slot range events do not Invalidate the whole bar")
do
	local i = rangeCore:find('Ev.Register("ACTION_RANGE_CHECK_UPDATE"', 1, true)
	local j = i and rangeCore:find("Ev.Register(", i + 10, true)
	local body = (i and j and rangeCore:sub(i, j - 1)) or ""
	has(body, "ApplySlotRange", "ACTION_RANGE_CHECK_UPDATE paints that slot only")
	has(body, "MouseoverBurst", "mouseover storms do not ApplySlotRange 57 times")
end
do
	-- Macros / overlays must range the winning @unit, not leftover hub mouseover.
	local i = rangeCore:find("function Range.ResolveUnit", 1, true)
	local j = rangeCore:find("-- Memoized probes", i, true)
	local body = (i and j and rangeCore:sub(i, j - 1)) or ""
	local mu = body:find("AllowUnit(macroUnit, macroUnit)", 1, true)
	local attr = body:find('GetAttribute, widget, "unit"', 1, true)
	if not mu or not attr or mu > attr then
		failures[#failures + 1] = "ResolveUnit must prefer the macro @unit over the hub unit"
	end
	if body:find("AllowUnit(u, macroUnit)", 1, true) then
		failures[#failures + 1] = "leftover hub mouseover must not ride a non-mouseover macroUnit"
	end
	has(body, "widget and MouseoverCastOn()", "plain spells/items range mouseover when the toggle is on")
end
do
	-- A no-range answer is unit-dependent (a harmful spell reports nil on a
	-- friendly), so it must never outlive the frame it was measured in.
	local i = rangeCore:find("function Range.CheckSpell", 1, true)
	local j = rangeCore:find("function Range.CheckItem", 1, true)
	local body = (i and j and rangeCore:sub(i, j - 1)) or ""
	if body:find("noRange", 1, true) then
		failures[#failures + 1] = "range must not cache no-range across frames"
	end
end
if rangeCore:find("IdentityDrive", 1, true) or rangeCore:find("LibActionButton", 1, true) then
	failures[#failures + 1] = "Range must not pull LAB / IdentityDrive"
end

-- Exactly one range ticker across the whole addon.
do
	local barsWatch = read("Watch.lua")
	local ebsRange = read("../ExtraButtonSystem/Engine/Range.lua")
	if barsWatch:find("bars.range.ticker", 1, true) then
		failures[#failures + 1] = "strip must not keep its own range ticker"
	end
	if ebsRange:find("Ticker.Add", 1, true) then
		failures[#failures + 1] = "EBS must not keep its own range ticker"
	end
	has(ebsRange, 'R.RegisterSweep("ebs"', "EBS registers a sweep on the shared service")
	has(ebsRange, "Range.RefreshFlags", "Watch callers keep their entry point")
	has(barsWatch, 'R.RegisterSweep("bars"', "strip registers a sweep on the shared service")
	has(barsWatch, "EnableActionRangeCheck", "strip can opt slots into the Blizzard checker")
	has(barsWatch, "BlizzardRangeBlocked", "mouseover-cast and user @mouseover gate the Blizzard checker off")
	has(ebsRange, "IsParked", "Extra range need skips parked/hidden buttons")
	if barsWatch:find('Ev.Register("ACTION_RANGE_CHECK_UPDATE"', 1, true) then
		failures[#failures + 1] = "ACTION_RANGE_CHECK_UPDATE belongs to Flux.Range, not Bars.Watch"
	end
end

-- The strip probe must follow the overlay face and its @unit.
do
	local i = paint:find("local function RangeUnit", 1, true)
	local j = i and paint:find("\nfunction Paint.UpdateChecked", i, true)
	local body = (i and paint:sub(i, j or #paint)) or ""
	has(body, "RangeUnit(host)", "strip range resolves a unit")
	has(body, "face.MacroTarget", "strip range follows the macro's own @unit")
	has(body, "_fluxStripFace", "overlay range does not inherit the mouseover hub")
	has(body, "R.CheckSpell(face.SpellId", "overlay slots range the shown spell")
	has(body, "GetActionInfo", "plain spell/item slots range the shown identity against mouseover")
	has(body, "R.CheckAction(slot, unit)", "plain slots pass the unit to IsActionInRange")
	if body:find('UnitExists("target")', 1, true) then
		failures[#failures + 1] = "strip range must not hardcode target"
	end
end
if paint:find("pcall(IsActionInRange, LiveSlot(host))", 1, true) then
	failures[#failures + 1] = "strip must not call IsActionInRange without a unit"
end
has(programFace, 'Bars.RequestPaint("bars.range")', "a UF hover peek re-ranges against the peeked body")
has(programFace, 'Bars.RequestPaint("bars.count")', "hover overlay count follows the peeked face")

do
	local ebsPaint = read("../ExtraButtonSystem/Engine/Paint.lua")
	has(ebsPaint, "R.ResolveUnit(widget, macroUnit)", "Extra buttons share the unit rule")
	has(ebsPaint, "IsMacroLike(btn) and nil or btn.Widget", "macro range does not inherit leftover hub unit")
	has(ebsPaint, "R.CheckSpell(ident, unit)", "Extra buttons share the range memo")
	local ebsWatch = read("../ExtraButtonSystem/Engine/Watch.lua")
	if ebsWatch:find('Ev.Register("UPDATE_MOUSEOVER_UNIT"', 1, true) then
		failures[#failures + 1] = "Extra Watch must not own UPDATE_MOUSEOVER_UNIT (Bars Watch / Range / ProgramFace)"
	end
	if ebsWatch:find('RequestCond("mouseover")', 1, true) then
		failures[#failures + 1] = "Extra Watch must not RequestCond mouseover"
	end
	do
		local i = ebsWatch:find("local function OnUnitConditional", 1, true)
		local j = i and ebsWatch:find('Ev.Register("UNIT_FLAGS"', i, true)
		local body = (i and j and ebsWatch:sub(i, j - 1)) or ""
		if body:find('"mouseover"', 1, true) then
			failures[#failures + 1] = "Extra UNIT_FLAGS/FACTION/TARGET must not treat mouseover as a [harm] parse"
		end
	end
end

-- ---------------------------------------------------------------------------
-- Mouseover cast: click-time unit only. Static unit=mouseover is the hop hitch.
-- ---------------------------------------------------------------------------

local mo = read("../Core/Engine/MouseoverCast.lua")
has(toc, "Core\\Engine\\MouseoverCast.lua", "TOC loads the mouseover cast engine")
has(toc, "AddonOptions\\FluxOptionsActionBars.lua", "TOC loads the Action Bars tab")
has(mo, "FluxActionStripMouseoverHub", "one hub owns classification and the click wrap")
has(mo, "UNIT_PRECLICK", "click picks mouseover or target on every client")
has(mo, "UNIT_POSTCLICK", "click-time unit is cleared so hops cannot keep resolving it")
has(mo, 'self:SetAttribute("unit", "mouseover")', "PreClick still writes the mouseover unit token")
has(mo, "ParkLegacyDrivers", "legacy [@mouseover] state drivers stay unregistered")
has(mo, "WrapUnitPick", "PreClick wrap is installed once, not per hover")
has(mo, "PARK_GRACE = 0.75", "legacy constant kept for leftover driver park")
if mo:find('RegisterStateDriver, hub, "target-help"', 1, true)
	or mo:find('RegisterStateDriver, hub, "target-harm"', 1, true)
then
	failures[#failures + 1] = "mouseover cast must not RegisterStateDriver [@mouseover] (sweep hitch on all clients)"
end
if mo:find('Ev.Register("UPDATE_MOUSEOVER_UNIT"', 1, true) then
	failures[#failures + 1] = "MouseoverCast must not listen to UPDATE_MOUSEOVER_UNIT"
end
if mo:find("local function HubOnState", 1, true) or mo:find("function HubOnState", 1, true) then
	failures[#failures + 1] = "unused HubOnState host walks must be gone"
end
if mo:find("local function HostChildUpdate", 1, true) then
	failures[#failures + 1] = "unused header target ChildUpdate snippets must be gone"
end
do
	local i = mo:find("function MouseoverCast.SyncDrivers", 1, true)
	local j = i and mo:find("local function RefreshHeaderRefs", i, true)
	local body = (i and j and mo:sub(i, j - 1)) or ""
	has(body, "ParkLegacyDrivers", "SyncDrivers only unregisters leftover drivers")
	if body:find("RegisterStateDriver", 1, true) then
		failures[#failures + 1] = "SyncDrivers must not re-arm [@mouseover] drivers"
	end
end
has(mo, "CLASSIFY_DEBOUNCE = 0.15", "spellbook classification is debounced")
has(mo, "function MouseoverCast.UsesNativeCVar", "Forever native CVar path is gated")
has(mo, "function MouseoverCast.ApplyNativeCheck", "native checkmouseovercast is stamped from the engine")
has(mo, "hasRestrictedClosures == false", "native CVar path requires missing WrapScript")
has(mo, 'SetCVar, "enableMouseoverCast", "0"', "wrap clients keep native CVar off")
do
	local i = mo:find("local function SyncCVar", 1, true)
	local j = i and mo:find("local function CVarIsOn", i, true)
	local body = (i and j and mo:sub(i, j - 1)) or ""
	has(body, "UsesNativeCVar", "SyncCVar Forever branch is gated")
	if body:find('MouseoverCast.IsEnabled() and "1" or "0"', 1, true) then
		failures[#failures + 1] = "Forever must not SetCVar enableMouseoverCast (gamepad UseAction taint)"
	end
	has(body, 'SetCVar, "enableMouseoverCast", "0"', "wrap clients still force CVar off")
end
has(mo, "CVAR_UPDATE", "Forever Combat checkbox stays in lockstep with the Flux toggle")
has(mo, "nativeCVar=", "/fluxbars mo reports whether native CVar is in use")
has(mo, "NotifySettingsChanged", "toggling rebuilds the Binding macro tails")
has(mo, "R.Invalidate", "toggling re-ranges immediately so leftover mouseover OOR drops")
has(mo, "FluxMouseoverCastCheckbox", "spellbook carries the Mouseover Cast toggle")
has(mo, "function MouseoverCast.RefreshSpellBookCheckbox", "options and spellbook stay in lockstep")
has(mo, "SpellBookChrome", "spellbook Mouseover Cast uses the shared chrome layout")
if mo:find("ScrollBox", 1, true) or mo:find("BOTTOMLEFT\", spellBookFrame, \"BOTTOMLEFT\", 50, 55", 1, true) then
	failures[#failures + 1] = "MouseoverCast must not fall back to ScrollBox / BOTTOMLEFT 50,55"
end
has(mo, "IsHelpfulSpell", "pre-Dragonflight classification fallback")
has(mo, "function MouseoverCast.SetButtonItem", "Extra items get the same mouseover-cast unit as bar items")
has(mo, "flux-mo-item-", "bar items are published onto the hub")
has(mo, "ClassifyItem", "items are classified help/harm/all")
has(mo, "tt = 3", "unclassified Extra spells/items still mouseover-cast at click")
has(mo, "type=click hosts=", "/fluxbars mo reports overlay click hosts")
has(mo, "hidden clickers with MOUSEOVER=", "/fluxbars mo reports hidden SAB mouseover bodies")
do
	-- Classification inside the restricted environment is what silently broke
	-- mouseover cast on Classic; it has to stay in ordinary Lua.
	local i = mo:find("local HOST_APPLY", 1, true)
	local j = mo:find("local HOST_RECOMPUTE", 1, true)
	local snippet = (i and j and mo:sub(i, j - 1)) or ""
	if snippet == "" then
		failures[#failures + 1] = "host apply snippet missing"
	end
	has(snippet, 'self:GetAttribute("type") ~= "action"', "a compiled overlay keeps targeting off the strip")
	if snippet:find('SetAttribute("unit", "mouseover")', 1, true) then
		failures[#failures + 1] = "HOST_APPLY must not SetAttribute unit=mouseover (click wrap only)"
	end
	has(snippet, 'self:SetAttribute("unit", nil)', "HOST_APPLY leaves unit nil between clicks")
	local preI = mo:find("local UNIT_PRECLICK", 1, true)
	local preJ = mo:find("local UNIT_POSTCLICK", 1, true)
	local pre = (preI and preJ and mo:sub(preI, preJ - 1)) or ""
	if pre:find('SetAttribute("macrotext"', 1, true) then
		failures[#failures + 1] = "PreClick must not SetAttribute macrotext on shown hosts"
	end
	if pre:find('SetAttribute("unit", "mouseover")', 1, true) then
		has(pre, 't == "click"', "type=click skips unit pick (hidden SAB owns the body)")
		has(pre, 'self:SetAttribute("unit", nil)', "overlay PreClick clears leftover unit")
		has(pre, 'UnitExists("target")', "PreClick must not stamp unit=target when target is missing")
		has(pre, 'button == "ConjureBind"', "conjure keys skip mouseover unit pick")
		has(pre, 'button == "RightButton"', "right-click conjure skips mouseover unit pick")
	end
	-- ChildUpdate must be issued by the header running the snippet, never on a
	-- frame reference, so a recompute goes through a counter attribute.
	has(mo, 'h:SetAttribute("state-fluxmo", tick)', "recompute bounces through the header state")
	has(mo, 'control:ChildUpdate("fluxmo", 1)', "the header issues its own ChildUpdate")
	if mo:find('h:SetAttribute("state-%s", raw)', 1, true) then
		failures[#failures + 1] = "hub must not ChildUpdate every header child on a mouseover hop"
	end
	if snippet:find("IsSpellHelpful", 1, true) or snippet:find("IsHelpfulSpell", 1, true) then
		failures[#failures + 1] = "secure snippet must not classify spells"
	end
end
do
	local i = mo:find("function MouseoverCast.RegisterButton", 1, true)
	local body = (i and mo:sub(i, i + 700)) or ""
	has(body, "WrapUnitPick", "Extra buttons get the click wrap, not a static unit token")
end
do
	local i = mo:find("local function ApplyButtonTargetType", 1, true)
	local j = i and mo:find("function MouseoverCast.SetButtonSpell", i, true)
	local body = (i and j and mo:sub(i, j - 1)) or ""
	if body:find('SetAttribute("unit", "mouseover")', 1, true) then
		failures[#failures + 1] = "Extra flux-smart must not stamp unit=mouseover"
	end
end
has(read("../ExtraButtonSystem/Engine/Widget.lua"), "config.badgeMode", "badges stay off the mouseover cast hub")
do
	local factory = read("../Binding/Core/MacroFactory.lua")
	has(factory, "function Factory.IdleMacroText", "display parse can drop factory [@mouseover]")
	has(factory, "function Factory.IsFactoryMouseover", "factory mouseover tails are not a macro comment")
	has(factory, "forceStrip", "IdleMacroText strips factory tails without a comment")
	has(factory, "function Factory.NeedsHiddenClick", "sequences/petattack/multi-cast stay on hidden clicker")
	has(factory, "function Factory.StripOverlayMode", "peer overlays install as surface macrotext; native tails as display")
	has(factory, "function Factory.HasPeerOverlay", "peer clause detection")
	if factory:find('"#flux-no-mo\\n"', 1, true) or factory:find('return "#flux-no-mo', 1, true) then
		failures[#failures + 1] = "compiled macros must not insert #flux-no-mo"
	end
	if factory:find("function MarkNativeMouseoverCast", 1, true) then
		failures[#failures + 1] = "MarkNativeMouseoverCast must not inject a comment into macrotext"
	end
	has(factory, "leave fallthrough to native tail", "fully default peers still skip the keyboard row")
	has(factory, "function Factory.MacrotextMax", "overlay length follows the client macro cap")
	has(factory, "return 255", "Classic overlay bodies stay at 255")
	has(factory, "ConditionGroupsForTokens", "native tails reuse compact form gates")
	do
		local i = factory:find("local ufOnlyDefault = preferNativeTail", 1, true)
		local j = i and factory:find("-- Regular rows:", i, true)
		local body = (i and j and factory:sub(i, j - 1)) or ""
		has(body, "#baked == 0", "combat/stealth peers still emit keyboard clauses")
		if body:find("SubHasModCondition", 1, true) and not body:find("#baked", 1, true) then
			failures[#failures + 1] = "ufOnlyDefault must punch through baked combat tokens, not only mods"
		end
	end
end
do
	local stateLua = read("State.lua")
	has(stateLua, "MC.RegisterHeader", "the six strip headers fan mouseover state to their hosts")
	has(stateLua, "flux-mo-apply", "paging recomputes the mouseover unit")
	has(stateLua, "MC.AttachHost", "hosts get the mouseover snippets when they attach")
end
do
	local defaults = read("../FluxDefaultSettings.lua")
	if defaults:find('["enableMouseoverCast"] = "1"', 1, true) then
		failures[#failures + 1] = "the CVar pack must not force enableMouseoverCast on every login"
	end
	local i = defaults:find("function FluxDefaultSettings.ApplyCombatDefaultsPack", 1, true)
	local j = i and defaults:find("function FluxDefaultSettings.", i + 10, true)
	local body = (i and j and defaults:sub(i, j - 1)) or ""
	has(body, 'setCVar("enableMouseoverCast", "0")', "defaults keep Blizzard mouseover-cast off on every client")
	if body:find("UsesNativeCVar", 1, true) or body:find('on and "1" or "0"', 1, true) then
		failures[#failures + 1] = "combat pack must not follow the Action Bars mouseover toggle"
	end
end
do
	local abBar = read("../AddonOptions/FluxOptionsActionBars_Bar.lua")
	has(abBar, "UsesNativeCVar", "options copy splits Forever native CVar from wrap clients")
	has(abBar, "This client uses Blizzard mouseover-cast", "Forever options text names the native CVar path")
	has(abBar, "CVar stays off so world nameplate sweeps", "wrap-client options text keeps the hitch note")
end
do
	local extraAction = read("../ExtraButtonSystem/Engine/Action.lua")
	has(extraAction, "ApplyNativeCheck", "Extra WriteAttributes restamps Forever native check")
	has(extraAction, "UsesWrap", "Extra WriteAttributes pressAndHold is wrap-gated")
end
do
	local abTab = read("../AddonOptions/FluxOptionsActionBars.lua")
	local abBar = read("../AddonOptions/FluxOptionsActionBars_Bar.lua")
	has(abTab, 'RegisterModuleOptions("actionbars"', "the actionbars tab OpenToActionBarsTab targets exists")
	has(abTab, 'childGroups = "tab"', "Action Bars uses nested Bar / Bindings / Extra / Stance tabs")
	has(abBar, "mouseoverCast", "the tab carries the Mouseover cast toggle")
	has(abBar, "autoRankUp", "the tab carries Auto rank up")
	has(abBar, "FluxSpellBlacklistPanel", "the tab hosts the rank-up blacklist panel")
	has(read("../AddonOptions/FluxOptions.lua"), "MC.Apply()", "scope / profile changes re-apply mouseover cast")
	has(read("../AddonOptions/FluxOptions.lua"), "ApplyActionbarsOptions", "scope refresh retargets Flux.Bars not FluxActionBarModule")
	has(toc, "Bars\\SpellRank.lua", "TOC loads spell rank")
	has(toc, "AceGUIWidget-FluxSpellBlacklistPanel.lua", "TOC loads the rank-up blacklist widget")
	has(toc, "LibKeyBound-1.0", "TOC loads LibKeyBound")
	has(toc, "Bars\\BindingMode.lua", "TOC loads Binding Mode")
	has(toc, "FluxNCFlyoutOptions.lua", "TOC loads NC flyout options")
	has(toc, "UtilitySlots\\Assign.lua", "TOC loads utility slot assign")
	has(toc, "UtilitySlots\\Manager.lua", "TOC loads utility slot manager")
	has(toc, "AceGUIWidget-FluxNCFlyoutPanel.lua", "TOC loads NC flyout panel")
	has(toc, "AceGUIWidget-FluxSpellBookSlotsPanel.lua", "TOC loads utility slots panel")
	has(toc, "AceGUIWidget-FluxStanceBarOrderPanel.lua", "TOC loads stance order panel")
	local iLib = toc:find("LibKeyBound-1.0", 1, true)
	local iBM = toc:find("Bars\\BindingMode.lua", 1, true)
	if iLib and iBM and iBM < iLib then
		failures[#failures + 1] = "BindingMode must load after LibKeyBound"
	end
	if (read("../AddonOptions/FluxOptions.lua") or ""):find("FluxActionBarModule", 1, true) then
		failures[#failures + 1] = "FluxOptions must not call FluxActionBarModule"
	end
	local bindMode = read("BindingMode.lua")
	has(bindMode, "FluxActionStripButton", "Binding Mode registers strip hosts")
	has(bindMode, "ShouldForceShowAllExtraSlots", "Binding Mode force-shows Extra placeholders")
	has(bindMode, "LibKeyBound-1.0", "Binding Mode uses LibKeyBound")
	has(read("../AddonOptions/FluxOptionsActionBars_Bindings.lua"), "Enter Binding Mode", "Bindings sub-tab has Enter Binding Mode")
	has(read("../AddonOptions/FluxOptionsActionBars_Extra.lua"), "FluxExtraButtonVisibilityPanel", "Extra sub-tab hosts visibility panel")
	has(read("../AddonOptions/FluxOptionsActionBars_Stance.lua"), "FluxStanceBarOrderPanel", "Stance sub-tab hosts order panel")
	has(read("Stance/Init.lua"), "function Stance.GetSlotOrderDescriptors", "stance editor descriptors exist")
	has(read("../ExtraButtonSystem/NonCombatGrid/GridInit.lua"), "OnNonCombatGridReady", "NC grid init creates utility slots")
	has(abBar, "Forever, Classic Era, and Anniversary", "rank-up copy includes Forever/Era/Anniversary")
	has(abBar, "Not on live Midnight", "rank-up copy stays off live Midnight")
	local rank = read("SpellRank.lua")
	has(rank, "function SpellRank:ApplyRankDesaturation", "SpellRank applies lower-rank grayscale")
	has(rank, "RankUpStanceCustomSpells", "auto rank-up includes stance custom spells")
	has(rank, "ReplaceCustomSpellId", "rank-up writes the stance slot")
	has(rank, "RewriteSavedStanceSpellId", "rank-up writes saved stance profiles")
	has(rank, "Bars.ForEachHost", "rank desat walks rewrite strip hosts")
	has(rank, "EBS.buttons", "rank desat walks Extra buttons")
	has(rank, "isLiveMidnight", "SpellRank stays off live Midnight")
	has(rank, "SpellBookChrome", "rank UI uses the shared spellbook chrome layout")
	has(rank, "CreateShowAllRanksCheckbox", "Forever PlayerSpells surfaces Blizzard Show All Ranks")
	has(rank, "SpellBookItemMixin", "rank labels hook PlayerSpells items")
	has(rank, "EnsureBlizzardShowAllRanks", "Forever registers Blizzard ShowAllSpellRanks before the book opens")
	has(rank, "_fluxCreatedShowAllRanks", "Flux-created Show All Ranks is marked so Classic XML is never hidden")
	has(rank, 'CreateFrame("CheckButton", "ShowAllSpellRanksCheckbox"', "Forever gets the Blizzard Show All Ranks CVar checkbox")
	if rank:find("function mixin:SetupAllRanksCheckbox", 1, true) then
		failures[#failures + 1] = "SpellRank must not replace Blizzard SetupAllRanksCheckbox"
	end
	if rank:find("SearchBox", 1, true) then
		failures[#failures + 1] = "SpellRank must not parent rank chrome to SearchBox"
	end
	if rank:find("IdentityDrive", 1, true) then
		failures[#failures + 1] = "SpellRank must not use IdentityDrive"
	end
	if rank:find("LibActionButton", 1, true) or rank:find("FluxActionBarModule", 1, true) then
		failures[#failures + 1] = "SpellRank must not hook LAB / FluxActionBarModule"
	end
	if rank:find("FluxActionButton", 1, true) then
		failures[#failures + 1] = "SpellRank must not target leftover FluxActionButton names"
	end
	local spellbookBind = read("../Binding/UI/SpellbookBindingHooks.lua")
	has(spellbookBind, "SetPassThroughButtons", "spellbook right-click overlay passes left clicks to Blizzard")
	has(spellbookBind, "CastSpellBookItem", "spellbook binding hooks keep CastSpellBookItem off the addon click path")
	has(spellbookBind, "EnsureRightClickCatcher", "spellbook right-click uses an addon overlay")
	if spellbookBind:find("SafeRegisterForClicks", 1, true) then
		failures[#failures + 1] = "SpellbookBindingHooks must not RegisterForClicks on Blizzard spell buttons"
	end
	if spellbookBind:find('RegisterForClicks("LeftButtonUp")', 1, true) then
		failures[#failures + 1] = "SpellbookBindingHooks must not RegisterForClicks LeftButtonUp on spellbook items"
	end
	if spellbookBind:find('HookScript("OnMouseUp"', 1, true) then
		failures[#failures + 1] = "SpellbookBindingHooks must not HookScript OnMouseUp on Blizzard spell buttons"
	end
end

local function slotPickBlock(src, untilPlain)
	local i = src:find("local slot = mainRest", 1, true)
	if not i then
		return nil
	end
	local j = src:find(untilPlain, i, true)
	if not j then
		return nil
	end
	return src:sub(i, j - 1)
end

local function normalizePick(s)
	s = s:gsub("%-%-[^\n]*", "")
	s = s:gsub("rowId", "row")
	s = s:gsub("%s+", " ")
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

do
	local mathSrc = read("SlotMath.lua")
	local fromMath = normalizePick(slotPickBlock(mathSrc, "return slot") or "")
	-- CHILDUPDATE runs the same pick for swap 0/1/2 (nomod / shift-action /
	-- ctrl-action). Compare the loop body, not the wrapper.
	local childPick = slotPickBlock(state, "slotNomod = slot") or ""
	childPick = childPick:gsub("\n%s*if sw == 0 then%s*$", "")
	local fromChild = normalizePick(childPick)
	fromChild = fromChild:gsub("%f[%w]sw%f[%W]", "swap")
	if fromMath == "" or fromChild == "" then
		failures[#failures + 1] = "CHILDUPDATE / SlotMath.Resolve slot pick missing"
	elseif fromMath ~= fromChild then
		failures[#failures + 1] = "CHILDUPDATE must match SlotMath.Resolve"
	end
	has(mathSrc, "hasSec == 1 and hasTert == 0", "lone sec xor invert")
	has(mathSrc, "hasTert == 1 and hasSec == 0", "lone tert xor invert")
	has(mathSrc, "Leftover mini is the tert widget", "promote-both leftover tert")
end

has(hosts, 'RegisterForDrag("LeftButton", "RightButton")', "strip drag L+R")
if hosts:find("lockActionBars", 1, true) then
	failures[#failures + 1] = "strip drag must not require lockActionBars/Shift"
end
if hosts:find("PICKUPACTION", 1, true) then
	failures[#failures + 1] = "strip drag must not require PICKUPACTION"
end
if hosts:find("RegisterActionUIButton", 1, true) then
	failures[#failures + 1] = "Hosts must not RegisterActionUIButton"
end
has(hosts, "Widget.Attach", "strip Overlay/Cast attach through FluxButton")
do
	local i = hosts:find("function Hosts.CreateSurface", 1, true)
	local j = hosts:find("function Hosts.FinishSurface", 1, true)
	local body = (i and j and hosts:sub(i, j - 1)) or ""
	local hideName = body:find("widget.Name:Hide()", 1, true)
	local rowGuard = body:find('if row ~= "main" then', 1, true)
	if hideName and (not rowGuard or hideName < rowGuard) then
		failures[#failures + 1] = "Hosts must not hide Name on the main row"
	end
end
has(hosts, "overlay.Name", "strip Name prefers TextOverlayContainer")
has(hosts, "host.btn", "FinishSurface keeps the occupancy FluxButton")
has(hosts, "InCombatLockdown", "combat no pickup")
has(hosts, "NotifyOccupancyChanged", "strip drag/drop notifies Binding occupancy")
do
	local i = hosts:find("local function AfterCursorChange", 1, true)
	local j = i and hosts:find('widget:SetScript("OnDragStart"', i, true)
	local body = (i and j and hosts:sub(i, j - 1)) or ""
	has(body, "FluxActionBarPeekSlotOccupancyChanged", "drag/drop peeks occupancy before Binding notify")
	has(body, "NotifyOccupancyChanged({ slot })", "pickup/place Binding-Applies without waiting on Watch Flush")
end
has(hosts, "G.InstallSAO", "strip InstallSAO after skin")
has(hosts, "G.SilenceMixin", "strip SilenceMixin after skin")

local strip = read("Strip.lua")
has(strip, "function Strip.GetBottomScreenOffset", "status-bar Y helper")
has(strip, "FluxActionBar_GetBottomScreenOffset", "export bottom Y")
has(strip, "function Strip.ComputeExtraScale", "extra upscale")
has(strip, "function Strip.ComputeXFactor", "horizontal squeeze")
has(strip, "SetLastHorizontalSqueezeFactor", "publish squeeze for grids")
has(strip, "SetClassColor", "strip class/accent fill")
has(strip, "FluxActionBar_ApplyAppearanceAccent", "accent refresh helper")
do
	local i = strip:find("function Strip.Metrics", 1, true)
	local j = i and strip:find("\nfunction ", i + 10, true)
	local body = (i and j and strip:sub(i, j - 1)) or ""
	has(body, "local chromeH = C.buttonSize * 1.5", "outer chrome reserved 1.5")
	has(body, "chromeH * C.scale + C.margin * 2 + C.heightTweak", "outer height uses 1.5 chrome")
	if body:find("contentH * C.scale", 1, true) then
		failures[#failures + 1] = "0-mini outer must not collapse to inner height"
	end
end
has(strip, 'inner:SetPoint("CENTER", frame, "CENTER"', "inner CENTER when not expanding")
has(strip, "Flux strip stays shown in vehicle/override", "strip does not follow MainActionBar hide")
has(strip, "IsGamepadUIEnabled", "gamepad HUD is the only strip hide")
has(strip, "INPUT_DEVICE_INTERFACE_TRANSITION", "gamepad HUD listens on our frame")
has(strip, "function Strip.WatchGamepad", "gamepad HUD applies when bars start")
if strip:find("bar:IsShown()", 1, true) then
	failures[#failures + 1] = "Strip.SyncVisibility must not hide the Flux strip when MainActionBar hides"
end
if strip:find("RegisterGamepadInit", 1, true) then
	failures[#failures + 1] = "strip must not RegisterGamepadInit (secure transition taint)"
end
if strip:find("function InputUtil.IsGamepadUIEnabled", 1, true) then
	failures[#failures + 1] = "strip must not replace InputUtil.IsGamepadUIEnabled"
end
if strip:find("hooksecurefunc", 1, true) or strip:find("HookScript", 1, true) then
	failures[#failures + 1] = "strip must not hook the gamepad bar or its secure path"
end
if strip:find("GamepadMainActionBarFrame", 1, true) then
	failures[#failures + 1] = "strip must not touch GamepadMainActionBarFrame"
end

local blizzard = read("Blizzard.lua")
has(blizzard, "UI-Backpack-EmptySlot", "empty backpack slot")
has(blizzard, "SizeRing", "ring via Style.SizeRing")
has(blizzard, "KillPagerMouse", "pager leftover mouse")
has(blizzard, "KillLeftoverMouse", "stock leftover mouse")
has(blizzard, "EnableMouse(false)", "leftover EnableMouse false")
has(blizzard, "Never Hide() MainActionBar", "do not Hide MainActionBar")
has(blizzard, "Never SetParent unused Blizzard action bars", "do not reparent unused action bars")
has(blizzard, "StanceButton1:SetShown", "stance shown-state taint")
has(blizzard, "UnparkIfNeeded", "unpark leftover bars back to UIParent")
has(blizzard, "PossessActionBar", "hide Blizzard PossessActionBar")
has(blizzard, "no objective-tracker calls", "leftover pass is layout-free")
local vehicleSrc = read("Vehicle.lua")
has(vehicleSrc, "never Hide / SetParent", "vehicle OverrideActionBar is never Hidden")
has(vehicleSrc, "SweepFluxFromCollectors", "vehicle enter vacuums Flux widgets off collectors")
has(vehicleSrc, "UNIT_ENTERED_VEHICLE", "vehicle watch on enter")
has(vehicleSrc, "Timer.Defer", "vehicle work is off the enter event stack")
has(vehicleSrc, "Flux strip stays shown", "vehicle path keeps the Flux strip")
has(vehicleSrc, "not InLockdown()", "vehicle ForceApply is OOC only")
has(vehicleSrc, "pendingCombatApply", "vehicle regen Apply only if a vehicle event queued")
has(vehicleSrc, "applyQueued", "vehicle Apply coalesces to one After(0)")
has(vehicleSrc, 'RequestPaint("bars.count")', "vehicle Apply refreshes count")
has(vehicleSrc, 'RequestPaint("bars.cooldown")', "vehicle Apply refreshes cooldown")
has(vehicleSrc, 'RequestPaint("bars.equipped")', "vehicle Apply refreshes equipped border")
has(vehicleSrc, "ACTIONBAR_SLOT_CHANGED", "vehicle gates collector SLOT_CHANGED")
has(vehicleSrc, "ACTIONBAR_UPDATE_COOLDOWN", "vehicle gates collector UPDATE_COOLDOWN (secret SetCooldown)")
has(vehicleSrc, "UnregisterAllEvents", "vehicle mutes ActionBarActionEventsFrame (SPELL_UPDATE_ICON Update)")
has(vehicleSrc, "PLAYER_REGEN_DISABLED", "vehicle unregisters collector events undeferred on lockdown")
has(vehicleSrc, "UnregisterEvent", "combat collector gate unregisters SLOT_CHANGED")
has(vehicleSrc, "HoldCollectorEvents()", "file load drops collector protected events")
if vehicleSrc:find("collector.RegisterEvent", 1, true)
	or vehicleSrc:find("RegisterEvent, collector, SLOT_CHANGED", 1, true)
	or vehicleSrc:find("buttonEvents:RegisterEvent", 1, true)
	or vehicleSrc:find("actionEvents:RegisterEvent", 1, true) then
	failures[#failures + 1] = "Vehicle must never re-register collector ACTIONBAR events"
end
if vehicleSrc:find("slotChangedHeld", 1, true) then
	failures[#failures + 1] = "Vehicle must not re-arm collector SLOT_CHANGED after combat"
end
if vehicleSrc:find("SetAlpha(0)", 1, true) then
	failures[#failures + 1] = "Vehicle.lua must not alpha-hide OverrideActionBar (Blizzard vehicle UI stays visible)"
end
if vehicleSrc:find("EnableMouse(false)", 1, true) then
	failures[#failures + 1] = "Vehicle.lua must not EnableMouse OverrideActionBar (Blizzard vehicle UI stays clickable)"
end
if vehicleSrc:find("ReclaimMicroMenu", 1, true) or vehicleSrc:find("SuppressOverrideBar", 1, true) then
	failures[#failures + 1] = "Vehicle.lua must not suppress OverrideActionBar or reclaim its MicroMenu"
end
if vehicleSrc:find("widget.bar =", 1, true) then
	failures[#failures + 1] = "Vehicle must not set widget.bar (UpdateFlyout GetSpellFlyoutDirection)"
end
if vehicleSrc:find("BindHostBars", 1, true) then
	failures[#failures + 1] = "Vehicle must not BindHostBars onto Flux headers"
end
do
	local watchSrc = read("Watch.lua")
	if watchSrc:find('Ev.Register("UPDATE_VEHICLE_ACTIONBAR"', 1, true)
		or watchSrc:find('Ev.Register("UNIT_ENTERED_VEHICLE"', 1, true) then
		failures[#failures + 1] = "Watch must not own vehicle enter (Bars.Vehicle.QueueApply owns it)"
	end
	if watchSrc:find("local function OnBarState", 1, true) then
		failures[#failures + 1] = "Watch must not keep a duplicate vehicle OnBarState apply"
	end
end
if vehicleSrc:find("Bars.State.ForceApply()", 1, true) then
	local i = vehicleSrc:find("function Vehicle.Apply", 1, true)
	local j = i and vehicleSrc:find("\nfunction Vehicle.QueueApply", i, true)
	local body = (i and j and vehicleSrc:sub(i, j - 1)) or ""
	if body:find("Bars.State.ForceApply()", 1, true) and not body:find("not InLockdown()", 1, true) then
		failures[#failures + 1] = "Vehicle.Apply must not Execute ForceApply in combat"
	end
	if body:find("SweepFluxFromCollectors", 1, true) and not body:find("SweepCollectorsOOC", 1, true) then
		failures[#failures + 1] = "Vehicle.Apply must not Sweep collectors in combat"
	end
end
do
	local code = vehicleSrc:gsub("%-%-[^\n]*", "")
	if code:find(":Hide()", 1, true) then
		failures[#failures + 1] = "Vehicle.lua must not Hide OverrideActionBar"
	end
	if code:find("OverrideActionBar:SetParent", 1, true) or code:find("bar:SetParent", 1, true) then
		failures[#failures + 1] = "Vehicle.lua must not SetParent OverrideActionBar"
	end
	if code:find("SetAlpha", 1, true) then
		failures[#failures + 1] = "Vehicle.lua must not alpha-hide OverrideActionBar (Blizzard vehicle UI stays visible)"
	end
	if code:find("EnableMouse", 1, true) or code:find("SetMouseClickEnabled", 1, true) then
		failures[#failures + 1] = "Vehicle.lua must not EnableMouse OverrideActionBar (Blizzard vehicle UI stays clickable)"
	end
	if code:find("HookScript", 1, true) then
		failures[#failures + 1] = "Vehicle.lua must not HookScript OverrideActionBar OnShow"
	end
	if code:find("hooksecurefunc", 1, true) then
		failures[#failures + 1] = "Vehicle.lua must not hooksecurefunc (UpdateAll taints RightManagedFrameContainer)"
	end
	if code:find("ForceCooldownPaint", 1, true) or code:find("ActionButton_UpdateCooldown", 1, true) then
		failures[#failures + 1] = "Vehicle.lua must not paint OverrideActionBar cooldowns"
	end
	if code:find("ignoreFramePositionManager", 1, true) or code:find("RemoveManagedFrame", 1, true) then
		failures[#failures + 1] = "Vehicle.lua must not pull OverrideActionBar off the bottom manager (hide-equivalent)"
	end
	local sweep = vehicleSrc:find("local function SweepCollectorsOOC", 1, true)
	local sweepEnd = sweep and vehicleSrc:find("\nlocal function ShowFluxStrip", sweep, true)
	local sweepBody = (sweep and sweepEnd and vehicleSrc:sub(sweep, sweepEnd - 1)) or ""
	if sweepBody == "" or not sweepBody:find("InLockdown()", 1, true) then
		failures[#failures + 1] = "SweepCollectorsOOC must skip collector writes in combat"
	end
end
local tocRoot
do
	local f = io.open(dir .. "/../_FluxUI.toc", "r")
	if f then
		tocRoot = f:read("*a")
		f:close()
	else
		tocRoot = ""
	end
end
has(tocRoot, "Bars\\Vehicle.lua", "TOC loads Bars Vehicle")
has(tocRoot, "Bars\\BlizzardOptions.lua", "TOC loads Blizzard Options 13-19")
do
	local hostsPos = tocRoot:find("Bars\\Hosts.lua", 1, true)
	local optsPos = tocRoot:find("Bars\\BlizzardOptions.lua", 1, true)
	if not (hostsPos and optsPos) or optsPos < hostsPos then
		failures[#failures + 1] = "BlizzardOptions must TOC-load after Hosts"
	end
end
local blizzardOpts = read("BlizzardOptions.lua")
has(blizzardOpts, "Hosts.BorrowedBindingOrder", "13-19 labels use Hosts borrowed commands")
has(blizzardOpts, 'fmt("Action Button %d", 12 + i)', "labels are Action Button 13-19")
has(blizzardOpts, "Never replace GetBinding", "Live/Forever skip comment")
has(blizzardOpts, "Client.isRetail and Client.isPostDF", "post-DF skips Settings replacements")
has(blizzardOpts, "classic_style", "Classic-family reshapes the keybind list")
has(blizzardOpts, "PROXY_SHOW_ACTIONBAR_2", "Classic-family hides extra-bar checkboxes")
has(blizzardOpts, "Combat.Defer", "extra-bar toggles defer in combat")
has(blizzardOpts, "SetActionBarToggles", "extra bars are forced off")
if blizzardOpts:find("AddInitializer", 1, true) then
	failures[#failures + 1] = "BlizzardOptions must not hook Settings AddInitializer (taints pooled rows)"
end
do
	local i = blizzardOpts:find("local function InstallHooks", 1, true)
	local j = i and blizzardOpts:find("\nlocal function ForceExtraActionBarsOff", i, true)
	local body = (i and j and blizzardOpts:sub(i, j - 1)) or ""
	has(body, "SkipSettingsReplace", "InstallHooks returns on post-DF before Settings replace")
	if body:find("InstallBindingUiHooks", 1, true) == nil then
		failures[#failures + 1] = "Classic-family InstallHooks must call InstallBindingUiHooks after the skip"
	end
end
has(blizzardOpts, "GetBinding = FluxGetBinding", "Classic-family remaps GetBinding")
has(blizzardOpts, "KeybindingsOverrides.AddBindingCategories =", "Classic-family hides extra-bar keybind sections")
local hostsSrc = read("Hosts.lua")
has(hostsSrc, "Hosts.BorrowedBindingOrder", "Hosts exports borrowed 13-19 commands")
has(hostsSrc, "Hosts.BorrowedBindingSet", "Hosts exports borrowed command set")
has(bindChord, "Hosts.BindingCommand", "ChordMap uses Hosts for columns 13-19")
if bindChord:find("MULTIACTIONBAR2BUTTON8", 1, true) then
	failures[#failures + 1] = "ChordMap must not duplicate borrowed 13-19 command names"
end
has(blizzard, "function Blizzard.QueueLeftoverMouse", "leftover mouse is queued, not hooked on UpdateAll")
if blizzard:find('hooksecurefunc("ActionBarController_UpdateAll"', 1, true) then
	failures[#failures + 1] = "must not hooksecurefunc ActionBarController_UpdateAll (RightManagedFrameContainer SetSize taint)"
end
if blizzard:find('hooksecurefunc("ActionBarController_ResetToDefault"', 1, true) then
	failures[#failures + 1] = "must not hook ActionBarController_ResetToDefault (MainActionBar SetAttribute taint)"
end
has(blizzard, "frame == _G.MainActionBar", "KillMouse never EnableMouse MainActionBar")
do
	local i = blizzard:find("local function NeutralizeMainBar", 1, true)
	local j = i and blizzard:find("\nlocal function SilenceStockButton", i, true)
	local body = (i and j and blizzard:sub(i, j - 1)) or ""
	if body:find("AlphaHide(bar)", 1, true) or body:find("KillMouse(bar)", 1, true) then
		failures[#failures + 1] = "NeutralizeMainBar must not EnableMouse MainActionBar"
	end
	has(body, "SetAlpha", "MainActionBar leftover is alpha only")
	has(body, "PassThroughClicks", "post-DF leftover MainActionBar passes clicks")
	if body:find("SetMouseClickEnabled", 1, true) then
		failures[#failures + 1] = "NeutralizeMainBar must not SetMouseClickEnabled MainActionBar"
	end
end
has(blizzard, "SetPropagateMouseClicks", "post-DF leftover MainActionBar passes clicks")
has(blizzard, "SetHitRectInsets", "post-DF leftover MainActionBar hit rect collapsed")
has(blizzard, "SetIgnoreParentAlpha", "EditMode Selection follows parent alpha")
has(blizzard, "IconIntroTracker", "spell fly-in does not land on leftover ActionButton")
has(blizzard, "function IsRetailPostDF", "post-DF leftover chrome is retail-gated")
has(blizzard, "NeutralizePostDFBarChrome", "post-DF leftover chrome pass")
has(blizzard, "if InLockdown() then", "EnableMouse skips lockdown")
has(blizzard, "local function ParkUnusedBar", "unused bars alpha only")
has(blizzard, "local function SilenceUnusedBar", "unused bars unregister visibility events")
has(blizzard, "Never EnableMouse unused-bar SecureFrame buttons", "do not EnableMouse StanceButton1")
has(blizzard, "PetActionBar:SetShownBase", "pet Hide must not SetShownBase")
if blizzard:find("bar.Hide = Noop", 1, true) then
	failures[#failures + 1] = "unused bars must not replace Hide (EditMode SetSize taint)"
end
has(blizzard, "IsControllerUpdateBar", "StanceBar/PossessActionBar keep stock Update for UpdateAll")
has(blizzard, "HideStockStanceBars", "stock stance/form bar is still hidden")
has(blizzard, "STOCK_STANCE_VISIBILITY", "stock StanceBar visibility driver is named")
has(blizzard, 'RegisterStateDriver, bar, "visibility", STOCK_STANCE_VISIBILITY', "stock StanceBar uses secure visibility hide")
has(blizzard, "[form:", "stock StanceBar driver re-hides on form change")
has(blizzard, "BackgroundArtLeft", "classic shapeshift wood art is hidden")
has(blizzard, "FluxStanceHider", "classic stance uses a dedicated hidden parent")
has(blizzard, "isAnyClassic", "classic stance parent is gated off retail")
do
	local i = blizzard:find("local function HideStockStanceBars", 1, true)
	local j = i and blizzard:find("\nlocal function NeutralizePostDFBarChrome", i, true)
	local body = (i and j and blizzard:sub(i, j - 1)) or ""
	if body == "" then
		failures[#failures + 1] = "HideStockStanceBars exists"
	else
		if not body:find("InLockdown", 1, true) then
			failures[#failures + 1] = "HideStockStanceBars must not RegisterStateDriver in combat (SecureStateDriverManager SetAttribute)"
		end
		has(body, "SecureStateDriverManager:SetAttribute", "stance driver cites the combat SetAttribute block")
		if body:find("SetAlpha", 1, true) then
			failures[#failures + 1] = "HideStockStanceBars must not SetAlpha StanceBar (EditMode SetSize taint)"
		end
		if body:find("bar.Hide = Noop", 1, true) then
			failures[#failures + 1] = "HideStockStanceBars must not replace Hide"
		end
		has(body, "RegisterStateDriver", "HideStockStanceBars RegisterStateDriver")
		has(body, "ParkStockStanceBar", "HideStockStanceBars parks classic stance")
		has(body, "HideClassicStanceArt", "HideStockStanceBars hides classic stance art")
	end
end
do
	local i = blizzard:find("local function ParkStockStanceBar", 1, true)
	local j = i and blizzard:find("\nlocal function HideClassicStanceArt", i, true)
	local body = (i and j and blizzard:sub(i, j - 1)) or ""
	if body == "" then
		failures[#failures + 1] = "ParkStockStanceBar exists"
	else
		has(body, "IsClassicFamily", "classic stance parent is classic-only")
		has(body, "SetParent", "classic stance parent is SetParent")
		has(body, "InLockdown", "classic stance parent skips combat")
		if body:find("UnregisterAllEvents", 1, true) then
			failures[#failures + 1] = "ParkStockStanceBar must not UnregisterAllEvents StanceBar"
		end
		if body:find("ClearAllPoints", 1, true) then
			failures[#failures + 1] = "ParkStockStanceBar must not ClearAllPoints StanceBar"
		end
	end
end
do
	local i = blizzard:find("local function HideClassicStanceArt", 1, true)
	local j = i and blizzard:find("\nlocal function HideStockStanceBars", i, true)
	local body = (i and j and blizzard:sub(i, j - 1)) or ""
	if body == "" then
		failures[#failures + 1] = "HideClassicStanceArt exists"
	else
		has(body, "SetAlpha", "classic shapeshift wood art stays alpha 0")
		has(body, "STOCK_STANCE_ART", "classic art keys")
	end
end
do
	local i = blizzard:find("local function UnparkIfNeeded", 1, true)
	local j = i and blizzard:find("\nlocal UNUSED_VISIBILITY_EVENTS", i, true)
	local body = (i and j and blizzard:sub(i, j - 1)) or ""
	if body == "" then
		failures[#failures + 1] = "UnparkIfNeeded exists"
	elseif not body:find("IsControllerUpdateBar", 1, true) then
		failures[#failures + 1] = "UnparkIfNeeded must not restore StanceBar to UIParent"
	end
end
do
	local i = blizzard:find("local STOCK_STANCE_LEFTOVER_EVENTS", 1, true)
	local j = i and blizzard:find("\nlocal function NeutralizeMainBar", i, true)
	local body = (i and j and blizzard:sub(i, j - 1)) or ""
	if body == "" then
		failures[#failures + 1] = "leftover watches stock stance controller events"
	else
		has(body, "UPDATE_SHAPESHIFT_FORM", "leftover watches UPDATE_SHAPESHIFT_FORM")
		has(body, "UPDATE_SHAPESHIFT_FORMS", "leftover watches UPDATE_SHAPESHIFT_FORMS")
		has(body, "UPDATE_POSSESS_BAR", "leftover watches UPDATE_POSSESS_BAR")
		has(body, "UPDATE_VEHICLE_ACTIONBAR", "leftover watches UPDATE_VEHICLE_ACTIONBAR")
		has(body, "UPDATE_OVERRIDE_ACTIONBAR", "leftover watches UPDATE_OVERRIDE_ACTIONBAR")
		has(body, "QueueLeftoverMouse", "stance leftover queues next-tick leftover")
		if body:find('hooksecurefunc("ActionBarController_UpdateAll"', 1, true) then
			failures[#failures + 1] = "stance leftover must not hook ActionBarController_UpdateAll"
		end
	end
end
if blizzard:find("bar.UpdateVisibility = Noop", 1, true) then
	failures[#failures + 1] = "unused bars must not replace UpdateVisibility (EditMode SetSize taint)"
end
has(blizzard, "ActionButton8:SetAttribute", "leftover ActionButton SetAttribute taint")
local defaultsSrc = read("../FluxDefaultSettings.lua")
has(defaultsSrc, "BlizzardSettings.Nameplates.Apply(force)", "nameplate pack goes through BlizzardSettings/Nameplates.lua")
has(defaultsSrc, "BlizzardSettings.Raid.Apply(", "raid pack goes through BlizzardSettings/Raid.lua")
if defaultsSrc:find("Settings.SetValue(", 1, true) or defaultsSrc:find("Settings.NotifyUpdate, ", 1, true)
	or defaultsSrc:find("proxy:SetValue(", 1, true) then
	failures[#failures + 1] = "FluxDefaultSettings must route Settings.SetValue / NotifyUpdate through BlizzardSettings.Write"
end
if defaultsSrc:find("WithNameplateCVarSecretGuard", 1, true) then
	failures[#failures + 1] = "nameplate CVar secret guard must stay removed (restoring a slot does not untaint it)"
end
if defaultsSrc:find("ApplyNameplateDefaultsPack)", 1, true) then
	failures[#failures + 1] = "post-login verify must not re-apply the nameplate pack every login"
end
has(defaultsSrc, "BlizzardSettings.Write.Run(\"resetCategory:\"", "category Defaults reapply now and again after Options closes")
local cvarSrc = read("../Core/API/CVar.lua")
has(cvarSrc, "Client.isRetail and Client.isPostDF == false", "post-DF blocks nameplate SetCVar")
has(cvarSrc, "UpdateAuraScale → RefreshAuras → Layout → GetScaledRect", "CVar block cites nameplate aura Layout")
local legacyCvarSrc = read("../Core/FluxAPI/CVars.lua")
has(legacyCvarSrc, "api.isRetail and api.isPostDF == false", "legacy FluxSetCVar blocks post-DF nameplate")
local ebsUtil = read("../ExtraButtonSystem/Engine/Util.lua")
has(ebsUtil, "NEVER hooksecurefunc SetCooldown / CooldownFrame_Set", "no shared Cooldown hook (nameplate SetAura)")

local np = {}
for _, name in ipairs({ "Core", "Threat", "Level", "Countdown" }) do
	np[name] = read("../NamePlates/" .. name .. ".lua")
	if np[name] == "" then
		failures[#failures + 1] = "NamePlates/" .. name .. ".lua missing"
	end
end
if read("../Other/FluxNamePlates.lua") ~= "" then
	failures[#failures + 1] = "Other/FluxNamePlates.lua must stay removed (replaced by NamePlates/)"
end
has(np.Countdown, "FLUX_NAMEPLATE_AURA_COUNTDOWN_SCALE = 0.75", "aura countdown stays 75 percent of pinned 16px")
has(np.Countdown, "FLUX_NAMEPLATE_AURA_COUNTDOWN_BASE_PX = 16", "aura countdown uses pinned 16px base")
has(np.Countdown, "if NP.IsSecret(txt) then", "countdown GetText secrets pass through to SetText")
has(np.Countdown, "CanBeAccessedInContext", "countdown skips aura items Flux cannot access")
do
	local i = np.Countdown:find("local function UpdateAuraItem(", 1, true)
	local j = np.Countdown:find("local function UpdateList(", 1, true)
	local body = (i and j and np.Countdown:sub(i, j - 1)) or ""
	local labelAt = body:find("ReadLabel", 1, true)
	local fadeAt = body:find("SetBlizzardDigitsAlpha(cooldown, 0)", 1, true)
	if not labelAt or not fadeAt or fadeAt < labelAt then
		failures[#failures + 1] = "must not hide blizzard countdown digits before Flux has a label"
	end
	if not body:find("HideHost", 1, true) then
		failures[#failures + 1] = "no-label path must restore blizzard digits"
	end
end
has(np.Level, "\"Lvl. \"", "Classic Modern plates keep Flux Lvl overlay")
do
	local i = np.Core:find("function NP.IsLevelSupported()", 1, true)
	local body = i and np.Core:sub(i, i + 280) or ""
	if not body:find("return C_NamePlate ~= nil", 1, true) or not body:find("NP.IsLiveClient()", 1, true) then
		failures[#failures + 1] = "level overlay stays on Forever, Era, and Anniversary, not Live"
	end
end
has(np.Core, "function NP.CreateClientPlate(", "level and threat use the client nameplate art")
has(np.Core, "UI-HUD-CoolDownManager-Bar-BG", "modern plates use the nameplate backdrop")
if np.Core:find("UI-HUD-Nameplates-Selected", 1, true) then
	failures[#failures + 1] = "level and threat plates must not use the selection-ring atlas"
end
has(np.Core, "Interface\\\\Tooltips\\\\Nameplate-Border", "classic plates use the game nameplate border texture")
if np.Core:find("SetColorTexture(0, 0, 0", 1, true) then
	failures[#failures + 1] = "level and threat must not use a blank color box"
end
has(np.Core, "function NP.TintPlateChrome(", "threat tint goes through TintPlateChrome")
has(np.Core, "diff.playerLevelDiffIcon", "threat tints the level-indicator border")
has(np.Level, "NP.CreateClientPlate(\"level\")", "level uses the client level plate")
has(np.Threat, "NP.CreateClientPlate(\"threat\")", "threat uses the client nameplate art")
if np.Core:find("SetTextureSliceMargins(14, 6, 14, 6)", 1, true) then
	failures[#failures + 1] = "nameplate chrome must not be a sliced border box"
end
has(np.Threat, "NP.ShowPlate(state.host, state.unit)", "threat plate tints from selection and threat")
has(np.Level, "NP.ShowPlate(overlay.host, unit)", "level plate tints from selection and threat")
has(np.Core, "NAMEPLATE_BORDER_TARGET_COLOR", "selected plates use the target border color")
has(np.Threat, "NP.TintPlateChrome(healthBar, r, g, b)", "threat tints the main nameplate border")
has(np.Threat, "ThreatAPI.IsNameplateThreatTarget", "nameplate threat hides on units the player is not fighting")
has(np.Threat, "ThreatAPI.GetNumericDisplay", "nameplates use Flux.Threat numeric display")
has(np.Threat, "ThreatAPI.GetForeverFrameDisplay", "Forever nameplates use the client threat read")
has(np.Threat, "ThreatAPI.GetTintColor", "nameplate border uses Flux tint (100%/rank 1 red)")
if np.Threat:find("r, g, b = 1, 1, 0", 1, true) then
	failures[#failures + 1] = "nameplates must not hardcode yellow when percent is secret or 100%"
end
if np.Threat:find("IsWarningEnabled", 1, true) then
	failures[#failures + 1] = "nameplates must not hide for Threat.IsWarningEnabled"
end
if np.Threat:find("SetAllPoints", 1, true) or np.Threat:find("SetDesaturated", 1, true) or np.Threat:find("CopyArt", 1, true) then
	failures[#failures + 1] = "threat must not recolor by copying a full-plate texture over the health bar"
end

-- NamePlates/, BlizzardSettings/, and Blizzard/Hide.lua never write into Blizzard code.
do
	local npAll = table.concat({ np.Core, np.Threat, np.Level, np.Countdown }, "\n")
	local bsAll = table.concat({
		read("../BlizzardSettings/Write.lua"),
		read("../BlizzardSettings/Nameplates.lua"),
		read("../BlizzardSettings/Raid.lua"),
	}, "\n")
	local hideSrc = read("../Blizzard/Hide.lua")
	if bsAll == "\n\n" or hideSrc == "" then
		failures[#failures + 1] = "BlizzardSettings/ or Blizzard/Hide.lua missing"
	end
	local forbidden = {
		"TextStatusBarMixin.", "NamePlateHealthBarMixin.", "NamePlateAurasMixin.", "NamePlateAuraItemMixin",
		"CastingBarMixin.", "CompactUnitFrameProfiles.", "_G[", "_G.CompactUnitFrame", "function CompactUnitFrame_",
		"hooksecurefunc(", "Settings.Register", "SetCountdownFont(", "SetFrameStrata(", "NamePlatePreviewMixin",
		"CUF_HORIZONTAL_GROUPS",
	}
	for _, needle in ipairs(forbidden) do
		if npAll:find(needle, 1, true) then
			failures[#failures + 1] = "NamePlates/ must not contain " .. needle
		end
		if bsAll:find(needle, 1, true) then
			failures[#failures + 1] = "BlizzardSettings/ must not contain " .. needle
		end
		if hideSrc:find(needle, 1, true) then
			failures[#failures + 1] = "Blizzard/Hide.lua must not contain " .. needle
		end
	end
	local owned = { driver = true, events = true, flusher = true, waiter = true }
	for line in (npAll .. "\n" .. bsAll .. "\n" .. hideSrc):gmatch("[^\n]+") do
		local obj = line:match("([%w_%.]+):SetScript%(")
		if obj and not owned[obj] then
			failures[#failures + 1] = "SetScript on a non-Flux frame: " .. obj
		end
	end
	if bsAll:find("Settings.SetValue", 1, true) and not bsAll:find("if not Write.MayUseSettingsAPI()", 1, true) then
		failures[#failures + 1] = "Settings.SetValue / NotifyUpdate must be gated to Era / Anniversary"
	end
end

-- Raid / Edit Mode / class power: hide Blizzard frames by reparenting, never by writing them.
do
	local raidLayout = read("../RaidFrame/FluxRaidLayout.lua")
	for _, needle in ipairs({ ".TryUpdate = ", ".RefreshMembers = ", ':SetScript("OnEvent"', "frame.unit = nil", "SetRaidProfileOption(profile, \"autoActivate" }) do
		if raidLayout:find(needle, 1, true) then
			failures[#failures + 1] = "FluxRaidLayout must not write Blizzard compact frames: " .. needle
		end
	end
	has(raidLayout, "Blizz.Hide(frame, { keepEvents = true })", "Blizzard raid grid is hidden by reparenting")
	if read("../RaidFrame/FluxRaidCompat.lua"):find("_G.UnitFrame_UpdateTooltip =", 1, true) then
		failures[#failures + 1] = "must not replace UnitFrame_UpdateTooltip"
	end
	local legacyUI = read("../Core/FluxAPI/UI.lua")
	for _, needle in ipairs({ "WithSecretCUFSkipped", "GuardExitEditMode", "ApplyMultipleToFrames = ", "ScaleTextToFit = " }) do
		if legacyUI:find(needle, 1, true) then
			failures[#failures + 1] = "Edit Mode must not swap compact-frame functions: " .. needle
		end
	end
	local classPower = read("../UnitFrames/FluxClassPower.lua")
	if classPower:find('frame:SetScript("OnEvent", nil)', 1, true) or classPower:find("frame.OnEvent = function", 1, true) then
		failures[#failures + 1] = "alternate power bars must be hidden with Flux.Blizz.Hide"
	end
end
local classPowerSrc = read("../UnitFrames/FluxClassPower.lua")
has(classPowerSrc, "local function LockFrameScale", "class power SetScale is instance wrap")
if classPowerSrc:find('hooksecurefunc(', 1, true) then
	failures[#failures + 1] = "FluxClassPower must not hooksecurefunc C methods (nameplate Layout)"
end
local blizzUnitSrc = read("../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua")
if blizzUnitSrc:find('hooksecurefunc(frame, "Show"', 1, true) or blizzUnitSrc:find('hooksecurefunc(frame, "SetParent"', 1, true) then
	failures[#failures + 1] = "unit-frame guards must not hooksecurefunc Show/SetParent"
end
has(blizzUnitSrc, "frame:SetAlpha(0)", "unit-frame mute is SetAlpha not Hide/SetParent")
has(blizzUnitSrc, "muteBlizzardUnitFrameVisuals", "muted Blizzard frames hide bars/portraits")
has(blizzUnitSrc, "ClearModel", "muted Blizzard portraits ClearModel")
has(blizzUnitSrc, "ShouldSkipMuteChild", "player mute must not walk PetFrame/TargetFrame")
has(blizzUnitSrc, '"OnUpdate"', "muted health bars drop OnUpdate before the secret heal-absorb compare")
if blizzUnitSrc:find('HookScript("OnShow"', 1, true) then
	failures[#failures + 1] = "unit-frame guards must not OnShow-Hide (Edit Mode SetClampRectInsets taint)"
end
if blizzUnitSrc:find("frame.SetParent = function", 1, true) then
	failures[#failures + 1] = "unit-frame guards must not wrap SetParent (Edit Mode ApplySystemAnchor taint)"
end
local extraHud = read("../Other/FluxExtraAbilityHUD.lua")
if extraHud:find('hooksecurefunc(container, "SetPoint"', 1, true) then
	failures[#failures + 1] = "ExtraAbilityContainer must not hooksecurefunc SetPoint"
end
if extraHud:find("container.SetPoint = function", 1, true) then
	failures[#failures + 1] = "ExtraAbilityHUD must not wrap SetPoint (Layout SetSize taint)"
end
if extraHud:find('hooksecurefunc(container, "ApplySystemAnchor"', 1, true) then
	failures[#failures + 1] = "ExtraAbilityHUD must not hook ApplySystemAnchor (InitSystemAnchors SetPointBase taint)"
end
do
	local extraCode = extraHud:gsub("%-%-[^\n]*", "")
	if extraCode:find("showingFrames", 1, true) then
		failures[#failures + 1] = "ExtraAbilityHUD must not write showingFrames"
	end
	if extraCode:find("RemoveManagedFrame", 1, true) then
		failures[#failures + 1] = "ExtraAbilityHUD must not RemoveManagedFrame"
	end
	if extraCode:find("container.SetPoint = nil", 1, true) then
		failures[#failures + 1] = "ExtraAbilityHUD must not nil SetPoint (Edit Mode InitSystemAnchors SetPointBase taint)"
	end
end
has(extraHud, "ignoreInLayout", "ExtraAbility HUD uses ignoreInLayout")
has(extraHud, "PLAYER_SPECIALIZATION_CHANGED", "ExtraAbility re-anchors after spec, not inside ApplySystemAnchor")
has(extraHud, "lastSpecToken", "ExtraAbility skips spec re-anchor when Forever dings keep the same spec")
if extraHud:find('RegisterEvent("PLAYER_LEVEL_UP")', 1, true) then
	failures[#failures + 1] = "ExtraAbilityHUD must not layout on PLAYER_LEVEL_UP"
end
if extraHud:find('SetScript("OnShow", nil', 1, true) then
	failures[#failures + 1] = "ExtraAbilityHUD must not nil OnShow (Edit Mode layout taint)"
end
local talkingHead = read("../Other/FluxTalkingHead.lua")
if talkingHead:find("isBottomManagedFrame = false", 1, true) then
	failures[#failures + 1] = "TalkingHead must not write isBottomManagedFrame (InitSystemAnchors SetPointBase taint)"
end
if talkingHead:find("isManagedFrame = false", 1, true) then
	failures[#failures + 1] = "TalkingHead must not write isManagedFrame (InitSystemAnchors SetPointBase taint)"
end
if talkingHead:find("LoadTalkingHeadAddon", 1, true) or talkingHead:find('Load("Blizzard_TalkingHeadUI")', 1, true) then
	failures[#failures + 1] = "TalkingHead must not LoadAddOn Blizzard_TalkingHeadUI (registeredSystemFrames taint)"
end
has(talkingHead, "ContinueOnAddOnLoaded", "TalkingHead waits for Blizzard load instead of LoadAddOn")
local microSrc = read("../MicroMenu/FluxMicroMenu.lua")
if microSrc:find("MicroMenuContainer:SetParent(", 1, true) then
	failures[#failures + 1] = "MicroMenuContainer must not SetParent addon frame (InitSystemAnchors SetPointBase taint)"
end
if microSrc:find("MicroMenuContainer:Hide(", 1, true) then
	failures[#failures + 1] = "MicroMenuContainer must not Hide() (InitSystemAnchors SetPointBase taint)"
end
if microSrc:find("MicroMenuContainer:EnableMouse", 1, true) then
	failures[#failures + 1] = "MicroMenuContainer must not EnableMouse (InitSystemAnchors SetPointBase taint)"
end
local bagSrc = read("../MicroMenu/FluxBagMicroButton.lua")
if bagSrc:find("BagsBar:EnableMouse", 1, true) then
	failures[#failures + 1] = "BagsBar must not EnableMouse (InitSystemAnchors SetPointBase taint)"
end
if bagSrc:find("BagsBar:Hide(", 1, true) then
	failures[#failures + 1] = "BagsBar must not Hide (InitSystemAnchors SetPointBase taint)"
end
if bagSrc:find("BagsBar:SetParent(", 1, true) then
	failures[#failures + 1] = "BagsBar must not SetParent (InitSystemAnchors SetPointBase taint)"
end
has(bagSrc, "CharacterReagentBag0Slot", "reagent bag slot is detached from the HUD")
has(bagSrc, "ParkBlizzardBagChrome", "bag slots are removed from the HUD, not only alpha-muted")
has(bagSrc, "CollapseBagsBarShell", "BagsBar shell is collapsed after slot buttons are removed")
local windowMoverSrc = read("../WindowMover/Engine.lua")
has(windowMoverSrc, "local function IsEditModeSystem", "WindowMover detects Edit Mode systems")
if windowMoverSrc:find('HookLayout(frame, name, "SetPointBase")', 1, true) then
	failures[#failures + 1] = "WindowMover must not hook SetPointBase (InitSystemAnchors MainActionBar:SetPointBase taint)"
end
local statusBarsSrc = read("../StatusBars/FluxStatusBar.lua")
if statusBarsSrc:find("DurabilityFrame:SetParent(FluxHiddenParent)", 1, true) then
	failures[#failures + 1] = "DurabilityFrame must not SetParent addon frame (InitSystemAnchors SetPointBase taint)"
end
do
	local stockDurability = statusBarsSrc:gsub("FluxDurabilityFrame:EnableMouse", "")
	if stockDurability:find("DurabilityFrame:EnableMouse", 1, true) then
		failures[#failures + 1] = "DurabilityFrame must not EnableMouse (InitSystemAnchors SetPointBase taint)"
	end
end
local minimapSrc = read("../Minimap/FluxMinimap.lua")
if minimapSrc:find('hooksecurefunc(questTracker, "SetHeight"', 1, true) then
	failures[#failures + 1] = "quest tracker must not hooksecurefunc SetHeight (nameplate Layout taint)"
end
if minimapSrc:find("questTracker.SetHeight = function", 1, true) then
	failures[#failures + 1] = "quest tracker must not wrap SetHeight (vehicle SetSize taint)"
end
if minimapSrc:find("function EditModeManagerFrame:UnregisterSystem", 1, true) then
	failures[#failures + 1] = "must not patch EditModeManagerFrame.UnregisterSystem (vehicle SetSize taint)"
end
if minimapSrc:find("EditModeManagerFrame:UnregisterSystem(", 1, true) then
	failures[#failures + 1] = "must not call EditModeManagerFrame:UnregisterSystem"
end
has(minimapSrc, "FluxRemoveFrameFromEditMode", "quest tracker does not patch EditModeManagerFrame.UnregisterSystem")
if minimapSrc:find("isInDefaultPosition = false", 1, true) then
	failures[#failures + 1] = "quest tracker must not write isInDefaultPosition (InitSystemAnchors SetPointBase taint)"
end
local otScrollSrc = read("../Minimap/FluxObjectiveTrackerScroll.lua")
if otScrollSrc:find("isInDefaultPosition = false", 1, true) then
	failures[#failures + 1] = "scroll adapter must not write isInDefaultPosition (InitSystemAnchors SetPointBase taint)"
end
has(otScrollSrc, "PinTopModulePadding", "scroll adapter pins Forever topModulePadding")
has(otScrollSrc, "PinLayoutHeight", "scroll adapter pins a tall Forever layout height")
has(otScrollSrc, "RecoverStuckDirty", "scroll adapter recovers Forever stuck dirty after gamepad Update errors")
has(otScrollSrc, "CollapseModuleTopGap", "scroll adapter pulls first Forever module under the header")
has(otScrollSrc, "DockQuestTimer", "scroll adapter docks Forever QuestTimerFrame")
has(otScrollSrc, "UpdateHeaderPosition", "scroll adapter restores header after Forever UpdateHeaderPosition")
has(otScrollSrc, "wrapUpdateSingle", "Forever UpdateSingle continues after pcall failure")
has(otScrollSrc, "StartForeverLoginPulse", "Forever login pulse recovers stuck dirty")
has(otScrollSrc, "function FluxObjectiveTrackerScroll:EnsureViewport", "live and Forever share the scroll viewport")
has(otScrollSrc, "FOREVER_CLIP_LEFT_BLEED", "Forever viewport is wider on the left so NineSlice/POI are not cut off")
has(otScrollSrc, "local function scrollByWheel", "wheel scrolls the objective body with SetVerticalScroll")
has(otScrollSrc, "kickForeverQuestLayout", "Forever login kick uses SortQuestWatches")
has(minimapSrc, "Viewport scroll: PinLayoutHeight inside the scroll child, never SetHeight", "Forever dock does not SetHeight the tracker")
has(minimapSrc, "leave Blizzard parent/anchors until Manager.Init", "Forever dock waits for Manager.Init")
has(minimapSrc, "Embedded and floating minimap both size", "embedded and floating minimap share the scroll viewport")
has(minimapSrc, "_fluxForeverPewTracker", "Forever first PEW docks after Manager.Init")
has(minimapSrc, "Flux.AfterLogin", "Forever tracker dock covers /reload")
if minimapSrc:find('RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED"', 1, true) then
	failures[#failures + 1] = "quest tracker must not re-dock on PLAYER_SPECIALIZATION_CHANGED (level-up InitSystemAnchors)"
end
do
	local i = minimapSrc:find("function FluxMinimap:RunEnforcerPass", 1, true)
	local j = i and minimapSrc:find("function FluxMinimap:RequestEnforcerBurst", i, true)
	if i and j and minimapSrc:sub(i, j):find("UpdateQuestTrackerPosition", 1, true) then
		failures[#failures + 1] = "enforcer must not re-dock the tracker (EDIT_MODE_LAYOUTS_UPDATED / level-up)"
	end
end
has(minimapSrc, "Position only updates on: initial load, embed toggle, tab switch, EditMode.Exit.", "tracker stays static on spec/level")
has(minimapSrc, "_fluxDockSnap", "tracker dock snapshot skips unchanged tab-switch relayout")
do
	local i = minimapSrc:find("function FluxMinimap:UpdateQuestTrackerPosition", 1, true)
	local j = i and minimapSrc:find("function FluxMinimap:HandleEditMode", i, true)
	if i and j and minimapSrc:sub(i, j):find("C_QuestLog.SortQuestWatches", 1, true) then
		failures[#failures + 1] = "UpdateQuestTrackerPosition must not SortQuestWatches (tab-switch tracker flicker)"
	end
end
has(otScrollSrc, "isAnchoredTopRight", "scroll dock skips ClearAllPoints when already TOPRIGHT")
if otScrollSrc:find("function FluxObjectiveTrackerScroll:EnsureForeverClip", 1, true) then
	failures[#failures + 1] = "Forever clip dock must be gone; both clients use EnsureViewport"
end
if otScrollSrc:find("NineSlice:GetBottom()", 1, true) then
	failures[#failures + 1] = "content height must not use NineSlice GetTop/GetBottom (viewport scale clips quests)"
end
if otScrollSrc:find("function ObjectiveTrackerFrame:GetAvailableHeight()", 1, true) then
	failures[#failures + 1] = "must not replace GetAvailableHeight (ShouldShowMawBuffs taint)"
end
if otScrollSrc:find("function InputUtil.IsGamepadUIEnabled", 1, true) then
	failures[#failures + 1] = "must not replace InputUtil.IsGamepadUIEnabled (SetPreferredGamepadInteractTarget taint)"
end
if otScrollSrc:find('hooksecurefunc(ObjectiveTrackerFrame, "SetHeight"', 1, true) then
	failures[#failures + 1] = "objective tracker scroll must not hooksecurefunc SetHeight"
end
if otScrollSrc:find("ObjectiveTrackerFrame.SetHeight = function", 1, true) then
	failures[#failures + 1] = "objective tracker scroll must not wrap SetHeight"
end
local pvpSrc = read("../StatusBars/FluxPVPObjectiveMover.lua")
if pvpSrc:find("captureBarFrame.SetPoint = function", 1, true) then
	failures[#failures + 1] = "capture bar must not wrap SetPoint (right Layout SetSize taint)"
end
if pvpSrc:find("objectiveFrame.SetPoint = function", 1, true) then
	failures[#failures + 1] = "top-center widget must not wrap SetPoint"
end
local statusSrc = read("../StatusBars/FluxStatusBar.lua")
if statusSrc:find("DurabilityFrame.FluxHideHooked", 1, true) then
	failures[#failures + 1] = "DurabilityFrame must not OnShow-Hide (right Layout SetSize taint)"
end
has(statusSrc, "isEditModeStatus", "post-DF status tracking bars skip Hide/SetParent")
has(statusSrc, "useHudStatusBarArt", "HUD vs classic EXP/REP art gate")
has(statusSrc, "isAnyClassic", "classic clients keep vertex-colored UI-StatusBar")
has(statusSrc, "UI-HUD-ExperienceBar-Fill-Experience", "HUD unrested XP fill atlas")
has(statusSrc, "UI-HUD-ExperienceBar-Fill-Rested", "HUD rested XP fill atlas")
has(statusSrc, "UI-HUD-ExperienceBar-Background", "HUD XP background atlas")
has(statusSrc, "UI-HUD-ExperienceBar-Fill-Prediction", "HUD rest prediction atlas")
has(statusSrc, "UI-HUD-ExperienceBar-Frame-Pip", "HUD exhaustion pip atlas")
has(statusSrc, "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Blue", "HUD renown/major rep atlas")
has(statusSrc, "UI-HUD-ExperienceBar-Fill-Reputation-Faction-Green", "HUD friendly rep atlas")
has(statusSrc, "UI-ExhaustionTickNormal", "classic exhaustion tick file")
has(statusSrc, "GetRestState", "rested inn state repaints EXP fill")
has(statusSrc, "function ApplyExpBarFill", "EXP fill goes through HUD/classic helper")
has(statusSrc, "function ApplyRepBarFill", "REP fill goes through HUD/classic helper")
has(statusSrc, "SetStatusBarColor(1, 1, 1, 1)", "HUD fills keep white vertex")
has(statusSrc, "ui-hud-experiencebar-divider", "Forever HUD EXP/REP segment divider atlas")
has(statusSrc, "STATUS_BAR_NUM_SEGMENTS", "segment count is documented against Blizzard constants")
has(statusSrc, "UI-XP-Bar", "classic EXP/REP ticks use UI-XP-Bar")
has(statusSrc, "function UpdateBarDividers", "EXP/REP bars layout native segment ticks")
has(statusSrc, "function GetStatusBarSegmentCount", "segment count is per-client")
has(statusSrc, "_fluxSegmented", "only EXP/REP bars get segment ticks")
if statusSrc:find("SetStatusBarColor(EXP_COLOR.r", 1, true) then
	failures[#failures + 1] = "EXP must not always tint purple; HUD art uses white vertex"
end
if statusSrc:find('SetTexture("Interface\\MainMenuBar\\UI-ExhaustionTick")', 1, true) then
	failures[#failures + 1] = "classic exhaustion pip must use UI-ExhaustionTickNormal"
end
local chatSrc = read("../Other/FluxChatFrame.lua")
if chatSrc:find("pcall(EditModeManagerFrame.UpdateSystemAnchorInfo", 1, true) then
	failures[#failures + 1] = "chat must not call EditModeManagerFrame.UpdateSystemAnchorInfo"
end
local ufShared = read("../UnitFrames/FluxUnitFrames_Shared.lua")
has(ufShared, "FluxUI_PlayerPvpTimerDriver", "player PvP timer driver is named for FluxPerf")
has(ufShared, "SyncPvpTimerDriver", "PvP timer OnUpdate hides when the flag timer is 0")
has(ufShared, "local function ClassColorForUnit", "unit class color skips secret keys")
local windowSrc = read("../Battlezonemap/FluxWindowFrame.lua")
has(windowSrc, "_fluxMapWasActive", "hiding the window pauses an active battlefield map")
local infoSrc = read("../StatusBars/FluxInfoFrame.lua")
has(infoSrc, "C_Timer.NewTicker(2", "InfoFrame actionStrip poll is a 2s ticker")
local restockInferior = read("../Inventory/Restock/Core/Tiers/FluxRestockTiers_Inferior.lua")
has(restockInferior, "passRefs", "inferior resume reuses refs from the pass start")
has(restockInferior, "pendingAfterInferiorPass", "Best notifies do not restart an in-flight inferior pass")
has(restockInferior, "refs._canConjure", "inferior canConjure is once per kind")
local restockMatch = read("../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua")
has(restockMatch, "if stacks == 0 then", "GetBagOwnedTier live-walks only when unique counts are empty")
has(restockMatch, "P.tierRefCache", "effective/inferior tiers are cached per bag generation")
do
	local i = ufShared:find("function UF.UpdateBorderColors", 1, true)
	local body = i and ufShared:sub(i, i + 1200) or ""
	if body:find("RAID_CLASS_COLORS[class]", 1, true) then
		failures[#failures + 1] = "UpdateBorderColors must not index RAID_CLASS_COLORS with raw UnitClass"
	end
	has(body, "ClassColorForUnit", "UpdateBorderColors uses ClassColorForUnit")
end
has(blizzard, "local function SilenceStockButton", "leftover ActionButtons are silenced")
has(blizzard, "Flux.Action.NilFromCollector", "leftover ActionButtons drop off ActionBarButtonEventsFrame")
do
	-- Blizzard's collector walks pairs(self.frames) calling frame:OnEvent. A Flux
	-- function on a stock button taints the rest of that loop, so the next
	-- protected button (OverrideActionBarButton2) blocks on
	-- Update -> UpdatePressAndHoldAction -> SetAttribute in combat.
	local i = blizzard:find("local function SilenceStockButton", 1, true)
	local j = i and blizzard:find("\nlocal function NeutralizeStockButton", i, true)
	local body = (i and j and blizzard:sub(i, j - 1)) or ""
	if body == "" then
		failures[#failures + 1] = "SilenceStockButton exists"
	end
	if body:find("_fluxStockSilenced then", 1, true) then
		failures[#failures + 1] = "SilenceStockButton must re-nil leftovers every leftover pass"
	end
	for _, method in ipairs({ "UpdatePressAndHoldAction", "UpdateAction", "Update" }) do
		if body:find("%." .. method .. "%s*=%s*Noop") then
			failures[#failures + 1] = "SilenceStockButton must not Noop stock " .. method
		end
	end
end
local actionSrc = read("../Core/API/Action.lua")
has(actionSrc, "function Action.NilFromCollector", "shared collector detach helper")
has(actionSrc, "function Action.GetAssistedHighlightSpell", "highlight-mode next-cast API")
has(actionSrc, "function Action.SpellForAssistedHighlight", "highlight occupancy matches Blizzard")
has(actionSrc, "function Action.IsAssistedHighlightActive", "highlight CVar/manager gate")
has(actionSrc, "never table.remove", "collector detach nils in place")
has(actionSrc, "function Action.SweepFluxFromCollectors", "vacuum Flux widgets off collectors")
has(actionSrc, "IsFluxActionWidget", "sweep only Flux action widgets")
has(actionSrc, 'name:find("^Flux")', "sweep matches Flux* names as a pattern")
has(actionSrc, "_fluxOccupancy", "sweep strip occupancy widgets")
has(actionSrc, "FluxCombat", "sweep combat-grid widgets")
has(actionSrc, "_fluxIsPresetGrid", "sweep preset Extra hosts")
if actionSrc:find('name:find("^FluxAction", 1, true)', 1, true) then
	failures[#failures + 1] = "IsFluxActionWidget must not plain-find ^Flux prefixes (caret never matches)"
end
for _, path in ipairs({
	"../Core/API/Action.lua",
	"../Bars/Hosts.lua",
	"../Bars/Blizzard.lua",
	"../Core/ButtonFX/Overlay.lua",
	"../ExtraButtonSystem/Engine/Widget.lua",
}) do
	local src = read(path)
	if src:find("tremove%s*%(%s*frames") or src:find("table%.remove%s*%(%s*frames") then
		failures[#failures + 1] = path .. " must not tremove from a collector frames list"
	end
end
has(blizzard, "local function SilenceProtectedLeftovers", "possess/multibar leftovers leave the collector")
has(blizzard, "PossessButton", "leftover mute covers PossessButton")
has(blizzard, "MultiBarBottomLeftButton", "leftover mute covers MultiBar buttons")
do
	local leftovers = blizzard:find("local function SilenceProtectedLeftovers", 1, true)
	local leftoversEnd = leftovers and blizzard:find("\nlocal function NeutralizeStockButton", leftovers, true)
	local body = (leftovers and leftoversEnd and blizzard:sub(leftovers, leftoversEnd - 1)) or ""
	if body:find("OverrideActionBarButton", 1, true) then
		failures[#failures + 1] = "SilenceProtectedLeftovers must leave OverrideActionBarButton on the collector"
	end
end
do
	-- Never Hide / SetParent / SetAlpha / EnableMouse the OverrideActionBar frame.
	local code = blizzard:gsub("%-%-[^\n]*", "")
	if code:find("OverrideActionBar:Hide", 1, true)
		or code:find("OverrideActionBar:SetParent", 1, true)
		or code:find("OverrideActionBar:SetAlpha", 1, true)
		or code:find("OverrideActionBar:EnableMouse", 1, true) then
		failures[#failures + 1] = "Blizzard leftover must not Hide/SetParent/SetAlpha/EnableMouse OverrideActionBar"
	end
end
if blizzard:find('hooksecurefunc(widget, "UpdateButtonArt"', 1, true) then
	failures[#failures + 1] = "HookButtonArt must instance-wrap UpdateButtonArt, not hooksecurefunc"
end
has(blizzard, "widget.UpdateButtonArt = function", "HookButtonArt is instance wrap")
if blizzard:find('hooksecurefunc(bar, "Show"', 1, true) then
	failures[#failures + 1] = "must not hook MainActionBar Show (taints ActionBarController)"
end
if blizzard:find('HookScript("OnShow"', 1, true) then
	failures[#failures + 1] = "must not OnShow-hook MainActionBar (taints ActionBarController)"
end
if blizzard:find("statehidden", 1, true) then
	failures[#failures + 1] = "leftover stock buttons must not SetAttribute statehidden"
end
do
	-- Stock leftover buttons must keep their Blizzard event registration.
	-- A waiter frame UnregisterEvent is fine; UnregisterAllEvents on the bar is not.
	if blizzard:find("UnregisterAllEvents", 1, true) then
		failures[#failures + 1] = "leftover stock buttons must not UnregisterAllEvents"
	end
end
if blizzard:find("PRE_DF_RING", 1, true) or blizzard:find("1.65", 1, true) then
	failures[#failures + 1] = "action-bar chrome must not apply 1.65 ring after SizeRing"
end
if blizzard:find("self:Hide()", 1, true) then
	failures[#failures + 1] = "Blizzard leftover must not Hide() stock bars on Show"
end
if blizzard:find("ParkFrame(", 1, true) then
	failures[#failures + 1] = "unused bars must not SetParent onto an addon hider"
end
do
	local i = blizzard:find("local UNUSED_VISIBILITY_EVENTS", 1, true)
		or blizzard:find("local function SilenceUnusedBar", 1, true)
	local j = i and blizzard:find("\nlocal function ParkUnusedBar", i, true)
	local silence = (i and j and blizzard:sub(i, j - 1)) or ""
	if silence == "" then
		failures[#failures + 1] = "SilenceUnusedBar exists"
	else
		if silence:find("KillMouse", 1, true) or silence:find("EnableMouse", 1, true) then
			failures[#failures + 1] = "SilenceUnusedBar must not EnableMouse unused bars"
		end
		if silence:find("SetParent", 1, true) or silence:find("ClearAllPoints", 1, true) then
			failures[#failures + 1] = "SilenceUnusedBar must not SetParent/SetPoint unused bars"
		end
		if silence:find("UpdateVisibility", 1, true) then
			failures[#failures + 1] = "SilenceUnusedBar must not replace UpdateVisibility (EditMode SetSize taint)"
		end
		if silence:find("HideOverride", 1, true) then
			failures[#failures + 1] = "SilenceUnusedBar must not replace HideOverride"
		end
		if silence:find("actionButtons", 1, true) then
			failures[#failures + 1] = "SilenceUnusedBar must not Hide unused actionButtons"
		end
		if silence:find("UpdateShownButtons", 1, true) then
			failures[#failures + 1] = "SilenceUnusedBar must not replace UpdateShownButtons"
		end
		if not silence:find("UPDATE_SHAPESHIFT_COOLDOWN", 1, true) then
			failures[#failures + 1] = "SilenceUnusedBar must UnregisterEvent stance cooldown"
		end
		if not silence:find("PET_BAR_UPDATE", 1, true) then
			failures[#failures + 1] = "SilenceUnusedBar must UnregisterEvent PET_BAR_UPDATE"
		end
		if not silence:find("IsControllerUpdateBar", 1, true) then
			failures[#failures + 1] = "SilenceUnusedBar must skip StanceBar/PossessActionBar (UpdateAll SetAttribute taint)"
		end
		if silence:find("bar.Hide = Noop", 1, true) or silence:find("bar.Show = Noop", 1, true) then
			failures[#failures + 1] = "SilenceUnusedBar must not replace Hide/Show"
		end
	end
end
do
	local i = blizzard:find("local function ParkUnusedBar", 1, true)
	local j = i and blizzard:find("\nlocal function AlphaUnusedBars", i, true)
	local park = (i and j and blizzard:sub(i, j - 1)) or ""
	if park == "" then
		failures[#failures + 1] = "ParkUnusedBar exists"
	else
		if park:find("KillMouse", 1, true) or park:find("EnableMouse", 1, true) then
			failures[#failures + 1] = "ParkUnusedBar must not EnableMouse unused bars"
		end
		if park:find("NeutralizeStockButton", 1, true) then
			failures[#failures + 1] = "ParkUnusedBar must not NeutralizeStockButton"
		end
		if park:find("ClearAllPoints", 1, true) or park:find("SetPoint", 1, true) then
			failures[#failures + 1] = "ParkUnusedBar must not SetPoint unused bars"
		end
		if park:find("SetParent", 1, true) then
			failures[#failures + 1] = "ParkUnusedBar must not SetParent"
		end
		if not park:find("IsControllerUpdateBar", 1, true) then
			failures[#failures + 1] = "ParkUnusedBar must skip StanceBar/PossessActionBar (UpdateAll SetSize taint)"
		end
		local skipAt = park:find("IsControllerUpdateBar(bar)", 1, true)
		local alphaAt = park:find("SetAlpha", 1, true)
		if skipAt and alphaAt and skipAt > alphaAt then
			failures[#failures + 1] = "StanceBar/PossessActionBar skip must be before SetAlpha"
		end
	end
end
do
	local i = blizzard:find("local function NeutralizeUnusedBar", 1, true)
	local j = i and blizzard:find("\nfunction Blizzard.HideStockButtons", i, true)
	local body = (i and j and blizzard:sub(i, j - 1)) or ""
	if body == "" then
		failures[#failures + 1] = "NeutralizeUnusedBar exists"
	elseif body:find("KillMouse", 1, true) or body:find("EnableMouse", 1, true) or body:find("NeutralizeStockButton", 1, true) then
		failures[#failures + 1] = "NeutralizeUnusedBar must not EnableMouse unused actionButtons"
	end
end
do
	local i = blizzard:find("function Blizzard.HideStockButtons", 1, true)
	local j = i and blizzard:find("\nfunction Blizzard.KillLeftoverMouse", i, true)
	local body = (i and j and blizzard:sub(i, j - 1)) or ""
	if body:find("MultiBarBottomLeftButton", 1, true) then
		failures[#failures + 1] = "HideStockButtons must not EnableMouse MultiBar buttons"
	end
	if not body:find("SilenceStockButton", 1, true) then
		failures[#failures + 1] = "HideStockButtons must SilenceStockButton before leftover mouse"
	end
	if not body:find("SilenceProtectedLeftovers", 1, true) then
		failures[#failures + 1] = "HideStockButtons must mute override/possess/multibar leftovers"
	end
end
do
	local i = blizzard:find("function Blizzard.KillLeftoverMouse", 1, true)
	local j = i and blizzard:find("\nfunction Blizzard.HideUnusedBars", i, true)
	local body = (i and j and blizzard:sub(i, j - 1)) or ""
	if body:find("MultiBarBottomLeftButton", 1, true) then
		failures[#failures + 1] = "KillLeftoverMouse must not EnableMouse MultiBar buttons"
	end
	if not body:find("SilenceStockButton", 1, true) then
		failures[#failures + 1] = "KillLeftoverMouse must SilenceStockButton before leftover mouse"
	end
	if not body:find("SilenceProtectedLeftovers", 1, true) then
		failures[#failures + 1] = "KillLeftoverMouse must mute override/possess/multibar leftovers"
	end
	if not body:find("SweepFluxFromCollectors", 1, true) then
		failures[#failures + 1] = "KillLeftoverMouse must sweep Flux widgets off collectors before EnableMouse"
	end
	if not body:find("not InLockdown()", 1, true) then
		failures[#failures + 1] = "KillLeftoverMouse must not Sweep collectors in combat"
	end
end

has(layout, "FluxUnifiedBorder.UpdateBorder", "UnifiedBorder after layout")
has(layout, "ComputeLook", "layout uses squeeze/upscale")

local parkStart = layout:find("local function ParkMini", 1, true)
local parkEnd = parkStart and layout:find("\nlocal function AnchorPair", parkStart, true)
local park = parkStart and parkEnd and layout:sub(parkStart, parkEnd)
if not park then
	failures[#failures + 1] = "ParkMini exists"
else
	if park:find(":Hide()", 1, true) then
		failures[#failures + 1] = "ParkMini must stay shown"
	end
	if not park:find(":Show()", 1, true) then
		failures[#failures + 1] = "ParkMini must Show off-screen"
	end
end
has(layout, "_fluxParked = true", "ParkMini flags parked")
has(layout, "leftover face is the tert widget", "promote-both leftover is tert widget")
has(layout, "function Layout.HasContentOnMain", "HasContentOnMain exists")
has(layout, "function Layout.InvalidateMappings", "InvalidateMappings exists")
do
	local i = layout:find("function Layout.GetPromotedMode", 1, true)
	local j = i and layout:find("function Layout.IsExpanding", i, true)
	local body = (i and j and layout:sub(i, j - 1)) or ""
	has(body, "HasContentInAnyState", "promotion blocked when any form has a main-row action")
	if body:find("HasContentOnMain", 1, true) then
		failures[#failures + 1] = "GetPromotedMode must not promote from a current-page empty if another form has main content"
	end
end
do
	local i = layout:find("function Layout.ApplyMappings", 1, true)
	local j = i and layout:find("function Layout.RevealEmptyInCombat", i, true)
	local body = (i and j and layout:sub(i, j - 1)) or ""
	has(body, "HasContentInAnyState", "mapping stamps any-state occupancy, not the current page")
	if body:find("MainHasAction", 1, true) or body:find("GetCurrentPage", 1, true) then
		failures[#failures + 1] = "ApplyMappings must not promote from current-page occupancy"
	end
end

local watchSrc = read("Watch.lua")
-- Blizzard sends one slot-changed per slot; a form change sends a dozen. They
-- are collected and flushed once, or SyncRange alone costs 12 x 57 HasAction.
do
	local i = watchSrc:find('Ev.Register("ACTIONBAR_SLOT_CHANGED"', 1, true)
	local j = i and watchSrc:find("Ev.Register(", i + 10, true)
	local slotEv = (i and j and watchSrc:sub(i, j - 1)) or ""
	if slotEv:find("SyncRange", 1, true) then
		failures[#failures + 1] = "slot change must not SyncRange per event (batch it)"
	end
	has(slotEv, "slotQueued", "slot change is batched into one deferred flush")
end
has(watchSrc, "local function FlushSlotChanged", "batched slot flush exists")
has(watchSrc, "InHopBurst", "usable paint skips world mouseover hops")
has(watchSrc, "OnUsableEvent", "ACTIONBAR_UPDATE_USABLE is hop-gated")
has(watchSrc, "OnCooldownEvent", "ACTIONBAR_UPDATE_COOLDOWN is hop-gated")
has(watchSrc, "cooldownHeld", "cooldown storms during hops are held")
has(watchSrc, "OnCheckedEvent", "ACTIONBAR_UPDATE_STATE is hop-gated")
has(watchSrc, "checkedHeld", "checked storms during hops are held")
do
	local i = watchSrc:find("local function FlushSlotChanged", 1, true)
	local j = i and watchSrc:find('Ev.Register("ACTIONBAR_SLOT_CHANGED"', i, true)
	local body = (i and j and watchSrc:sub(i, j - 1)) or ""
	local peekAt = body:find("FluxActionBarPeekSlotOccupancyChanged", 1, true)
	local dirtyAt = body:find("Paint.Dirty", 1, true)
	if not peekAt or not dirtyAt or peekAt > dirtyAt then
		failures[#failures + 1] = "FlushSlotChanged must occupancy-peek before Paint.Dirty"
	end
	has(body, "if #changed == 0 then", "texture-only SLOT_CHANGED does not repaint the strip")
	local sameAt = body:find("same[#same + 1] = slot", 1, true)
	local countAt = body:find("Paint.UpdateCount", 1, true)
	local changedAt = body:find("if #changed == 0 then", 1, true)
	if not sameAt or not countAt or not changedAt or sameAt > countAt or countAt > changedAt then
		failures[#failures + 1] = "unchanged occupancy still UpdateCount before the early return"
	end
	has(body, "UpdateUsable", "unchanged occupancy still updates usable so a new stack can undim")
	if body:find("same[#same + 1] = slot", 1, true) then
		local sameBody = body:sub(sameAt, changedAt)
		if sameBody:find("Paint.Dirty", 1, true) or sameBody:find("Layout.Request", 1, true)
			or sameBody:find("NotifyOccupancyChanged", 1, true) then
			failures[#failures + 1] = "unchanged occupancy count refresh must not Dirty, layout, or notify Binding"
		end
	end
	has(body, "hopping", "slot=0 during hops is not a full bar rewrite")
	local hopAt = body:find("if hopping then", 1, true)
	local notifyAt = body:find("NotifyOccupancyChanged", 1, true)
		or body:find("NotifyBarSlotChanged", 1, true)
	if not hopAt or not notifyAt or hopAt > notifyAt then
		failures[#failures + 1] = "FlushSlotChanged must skip Binding Apply during mouseover hops"
	end
	has(body, "NotifyOccupancyChanged", "FlushSlotChanged passes dirty slots in one occupancy notify")
	has(body, "ConsumeOccupancyDirty", "FlushSlotChanged consumes occupancy dirty after Binding notify")
	has(body, "consumeTouched", "hop skip still consumes occupancy dirty so Extra peek is not sticky")
end
has(watchSrc, 'Layout.Request("page")', "form/page restamps promotion")
has(watchSrc, "SPELLS_CHANGED", "strip icon refreshes on SPELLS_CHANGED")
-- Form, bonus bar and page arrive together: one FormStorm burst, not three
-- to five separate relayout + repaint passes.
has(watchSrc, 'FormStorm.OnBurst("bars.page"', "strip page work rides the form burst")
has(watchSrc, 'FormStorm.OnSettled("bars.page"', "strip gets one trailing settle pass")
do
	local i = watchSrc:find("local function OnPageOrForm", 1, true)
	local j = i and watchSrc:find("local FormStorm", i, true)
	local body = (i and j and watchSrc:sub(i, j - 1)) or ""
	has(body, 'RequestPaint("bars.count")', "page/form burst re-paints count")
	has(body, 'RequestPaint("bars.cooldown")', "page/form burst re-paints cooldown")
	has(body, 'RequestPaint("bars.usable")', "page/form burst re-paints usable")
	has(body, 'RequestPaint("bars.equipped")', "page/form burst re-paints equipped border")
end
has(watchSrc, "FluxActionBarPeekSlotOccupancyChanged", "occupancy peek skips texture-only ASC")
has(watchSrc, "BadgeHost.RefreshFormVisibility", "form settle retranlates badge reverse")
has(watchSrc, 'C.Request(true, { form = true })', "form settle requests Context display")
has(watchSrc, "HasSubscribers", "Watch UMU defers to Context when subscribed")
has(watchSrc, "ContextOwnsDisplay", "Watch hops skip eval when Context is subscribed")
has(watchSrc, "BadgeHost.NotifyModifierPaging", "SHIFT/CTRL pages badges without Apply")
has(watchSrc, "PF.Request", "Watch condition faces go through the cond hub")
has(watchSrc, "local function RequestCond", "Watch shares one kinded cond request")
has(watchSrc, "PLAYER_TARGET_CHANGED", "strip [harm] flips on target change, not only Extra")
has(watchSrc, "RequestTarget", "tab-target [harm] is reaction-gated")
do
	local i = watchSrc:find('Ev.Register("PLAYER_TARGET_CHANGED"', 1, true)
	local body = i and watchSrc:sub(i, i + 420) or ""
	has(body, "ContextOwnsDisplay", "tab-target rides Context, not a second eval walk")
end
do
	local i = watchSrc:find('Ev.Register("MODIFIER_STATE_CHANGED"', 1, true)
	local body = i and watchSrc:sub(i, i + 1800) or ""
	has(body, "ContextOwnsDisplay", "SHIFT rides Context; Watch must not NotifyModifierPaging first")
	has(body, "IndexLiveSlots", "Watch modifier reindexes for paint in combat")
end
do
	local i = watchSrc:find('FormStorm.OnSettled("bars.page"', 1, true)
	local body = i and watchSrc:sub(i, i + 700) or ""
	has(body, "ContextOwnsDisplay", "form settle does not TranslateFaces on top of Context")
	has(body, 'C.Request(true, { form = true })', "form settle still requests Context display")
	has(body, 'RequestPaint("bars.count")', "form settle re-paints count")
	has(body, 'RequestPaint("bars.cooldown")', "form settle re-paints cooldown")
	has(body, 'RequestPaint("bars.equipped")', "form settle re-paints equipped border")
end
has(watchSrc, "UPDATE_MOUSEOVER_UNIT", "strip [@mouseover] flips without Extra window macros")
do
	local i = watchSrc:find('Ev.Register("GROUP_ROSTER_UPDATE"', 1, true)
	local body = i and watchSrc:sub(i, i + 160) or ""
	has(body, 'RequestCond("combat")', "roster flips [group]/[raid], not a [harm] parse")
	if body:find('RequestCond("target")', 1, true) then
		failures[#failures + 1] = "GROUP_ROSTER_UPDATE must not Request target"
	end
	if body:find('RequestCond("all")', 1, true) then
		failures[#failures + 1] = "GROUP_ROSTER_UPDATE must not Request all"
	end
end
has(watchSrc, "local function TranslateFaces", "Watch shares one Extra-face refresh")
do
	local i = watchSrc:find('Ev.Register("UPDATE_MOUSEOVER_UNIT"', 1, true)
	local body = i and watchSrc:sub(i, i + 280) or ""
	has(body, "NoteMouseoverEvent", "UMU only stamps the trailing mouseover parse")
	if body:find('RequestCond("mouseover")', 1, true) then
		failures[#failures + 1] = "UPDATE_MOUSEOVER_UNIT must not RequestCond on every hop"
	end
	if body:find("OnMacroConditional", 1, true) then
		failures[#failures + 1] = "UPDATE_MOUSEOVER_UNIT must not full OnMacroConditional"
	end
end
do
	local i = watchSrc:find("local function OnUnitConditional", 1, true)
	local j = i and watchSrc:find('Ev.Register("UNIT_FLAGS"', i, true)
	local body = (i and j and watchSrc:sub(i, j - 1)) or ""
	if body:find('"mouseover"', 1, true) then
		failures[#failures + 1] = "UNIT_FLAGS/FACTION/TARGET must not treat mouseover as a [harm] parse"
	end
	has(body, "InHopBurst", "UNIT_FLAGS/FACTION/TARGET skip [harm] during nameplate hops")
end
do
	local i = watchSrc:find("local function FlushSlotChanged", 1, true)
	local j = i and watchSrc:find('Ev.Register("ACTIONBAR_SLOT_CHANGED"', i, true)
	local body = (i and j and watchSrc:sub(i, j - 1)) or ""
	if body:find('RequestCond("all")', 1, true) then
		failures[#failures + 1] = "FlushSlotChanged must not RequestCond all (Blizzard owns surface macros)"
	end
	if body:find("InvalidateIndex", 1, true) then
		failures[#failures + 1] = "FlushSlotChanged must not InvalidateIndex on slot storms"
	end
end
if watchSrc:find("RequestApplyAll", 1, true) or watchSrc:find("ScheduleApply", 1, true) then
	failures[#failures + 1] = "Bars Watch must not Binding-Apply on form/page"
end
do
	local i = watchSrc:find("local function OnCheckedEvent", 1, true)
	local j = i and watchSrc:find("local function RequestCond", i, true)
	local block = (i and j and watchSrc:sub(i, j - 1)) or ""
	if not block:find("ACTIONBAR_UPDATE_STATE", 1, true) then
		failures[#failures + 1] = "bars.checked must still listen for ACTIONBAR_UPDATE_STATE"
	end
	if block:find("UPDATE_SHAPESHIFT_FORM", 1, true)
		or block:find("UPDATE_BONUS_ACTIONBAR", 1, true)
		or block:find("ACTIONBAR_PAGE_CHANGED", 1, true) then
		failures[#failures + 1] = "bars.checked must not duplicate the form burst events"
	end
	if block:find("UNIT_SPELLCAST_STOP", 1, true)
		or block:find("UNIT_SPELLCAST_SUCCEEDED", 1, true)
	then
		failures[#failures + 1] = "bars.checked must not listen to per-cast UNIT_SPELLCAST (use lit poll)"
	end
	has(block, "PLAYER_LEAVE_COMBAT", "auto-attack gold drops on leave combat")
	has(block, "PLAYER_MOUNT_DISPLAY_CHANGED", "bar mount gold drops on dismiss")
end
do
	local i = watchSrc:find("local function SyncNativeHostSlots", 1, true)
	local j = i and watchSrc:find("local FormStorm", i, true)
	local block = (i and j and watchSrc:sub(i, j - 1)) or ""
	if block:find("Layout.InvalidateMappings()", 1, true) then
		failures[#failures + 1] = "form/page must not InvalidateMappings (ApplyMappings reads live occupancy)"
	end
	if not block:find('Bars.RequestPaint("bars.icon")', 1, true) then
		failures[#failures + 1] = "form/page must request the icon lane"
	end
	has(block, 'C.Request(true, { form = true })', "form burst requests Context so overlay icons flip now")
	has(block, "SP.ApplyLiveType", "form IndexSlot rebinds the live face before CHILDUPDATE")
	if block:find("if not (FS and FS.OnBurst)", 1, true) then
		failures[#failures + 1] = "form burst must not skip Context.Request when FormStorm exists"
	end
end
do
	local i = watchSrc:find('RegisterMany(Ev, "bars.icon"', 1, true)
	local j = i and watchSrc:find("RegisterMany", i + 10, true)
	local block = (i and j and watchSrc:sub(i, j - 1)) or ""
	if not block:find("SPELLS_CHANGED", 1, true) then
		failures[#failures + 1] = "bars.icon must include SPELLS_CHANGED"
	end
	if not block:find("SPELL_UPDATE_ICON", 1, true) then
		failures[#failures + 1] = "bars.icon must include SPELL_UPDATE_ICON"
	end
end

local ub = read("../Layout/UnifiedBorder.lua")
has(ub, 'NamedFrame("FluxActionStrip"', "unified envelope uses FluxActionStrip")
has(ub, "FluxActionStripSensing", "unified envelope uses strip sensing")
has(ub, "FluxActionStripSec", "unified envelope uses strip minis")
has(ub, "_fluxParked", "unified envelope skips parked minis")

local ebsLayout = read("../ExtraButtonSystem/Layout.lua")
has(ebsLayout, "FluxActionStrip or _G.FluxMainActionBar", "EBS dock prefers FluxActionStrip")

local coreDir = dir .. "/../Core"
local function readCore(rel)
	local f = io.open(coreDir .. "/" .. rel, "r")
	if not f then
		return ""
	end
	local s = f:read("*a")
	f:close()
	return s
end

local actionSrc = readCore("API/Action.lua")
has(actionSrc, "function Action.UnpackCharges", "Action.UnpackCharges")
has(actionSrc, "function Action.IsAttack", "Action.IsAttack")
has(actionSrc, "function Action.IsAutoRepeat", "Action.IsAutoRepeat")
has(actionSrc, "function Action.IsCurrent", "Action.IsCurrent")
has(actionSrc, "function Action.UnpackCooldown", "Action.UnpackCooldown")
has(actionSrc, "function Action.GetChargeDuration", "Action.GetChargeDuration")
has(actionSrc, "GetActionChargeDuration", "charge duration object from C_ActionBar")
has(actionSrc, "currentCharges", "unpack Midnight charge table")
has(actionSrc, "function Action.GetAssistedNextSpell", "Action.GetAssistedNextSpell")
has(actionSrc, "function Action.GetText", "Action.GetText wraps GetActionText")
has(actionSrc, "function Action.OccupancyKey", "Action.OccupancyKey is type+id occupancy")
do
	local i = actionSrc:find("function Action.OccupancyKey", 1, true)
	local j = actionSrc:find("function Action.GetText", i or 1, true)
	local body = (i and j and actionSrc:sub(i, j - 1)) or ""
	if body:find("GetMacroSpell", 1, true) or body:find("GetMacroItem", 1, true) then
		failures[#failures + 1] = "Action.OccupancyKey must not call GetMacroSpell"
	end
end

-- ---------------------------------------------------------------------------
-- Form / stance change must not hitch.
--
-- One shift emits form + bonus bar + page (+ stealth) and a dozen slot-changed
-- events. Every module used to answer all of them, the layout pass restamped
-- and full-repainted unconditionally, and both paint engines then re-ran on a
-- 50ms settle loop with their caches wiped each tick.
-- ---------------------------------------------------------------------------

local schedSrc = readCore("Engine/Scheduler.lua")
do
	local i = schedSrc:find("function Scheduler.Request", 1, true)
	local j = schedSrc:find("function Scheduler.HasPending", 1, true)
	local body = (i and j and schedSrc:sub(i, j - 1)) or ""
	has(body, "deferredEval", "eval requested while paging is deferred, not dropped")
	if body:find("pending.eval = nil", 1, true) then
		failures[#failures + 1] = "a layout request must not throw away pending eval"
	end
end
do
	local i = schedSrc:find("function Scheduler.Flush", 1, true)
	local body = (i and schedSrc:sub(i)) or ""
	has(body, 'RunBucket("display", display)', "flush runs display after layout")
	has(body, 'RunBucket("eval", eval)', "flush runs eval after display")
	if body:find("ranLayout", 1, true) then
		failures[#failures + 1] = "flush must not skip eval because a layout ran"
	end
end

local stormSrc = readCore("Engine/FormStorm.lua")
has(read("../_FluxUI.toc"), "Core\\Engine\\FormStorm.lua", "TOC FormStorm coalescer")
has(stormSrc, "function FormStorm.OnBurst", "FormStorm.OnBurst")
has(stormSrc, "function FormStorm.OnSettled", "FormStorm.OnSettled")
has(stormSrc, "function FormStorm.IsBursting", "FormStorm.IsBursting")
has(stormSrc, "function FormStorm.IsSettling", "FormStorm.IsSettling")
has(stormSrc, "function FormStorm.GetSnapshot", "FormStorm.GetSnapshot")
has(stormSrc, "formstorm.ignored", "an unchanged form index / page costs nothing")
has(stormSrc, "GetShapeshiftForm", "form edge is read, not assumed")
has(stormSrc, "GetBonusBarOffset", "bonus bar edge is read, not assumed")
has(stormSrc, "UPDATE_STEALTH", "stealth opens the same burst")

local initSrc = read("Init.lua")
has(initSrc, "CHEAP_REASON", "page and slot layouts are the cheap path")
has(initSrc, "FlushPending", "eval runs cond translate before Paint.Flush")
has(initSrc, 'tokens["flux.cond"]', "eval listens for the cond hub token")
has(initSrc, "ProgramFace.Start", "strip start subscribes the display bus")
do
	local i = initSrc:find("function Bars.ApplyLayout", 1, true)
	local j = initSrc:find("function Bars.Start", 1, true)
	local body = (i and j and initSrc:sub(i, j - 1)) or ""
	has(body, "if structural and Bars.Blizzard", "stock-frame sweep is off the page path")
	has(body, "if fullPaint and Bars.Paint", "a page layout does not full-paint 57 hosts")
end

has(layout, "stampedP", "promotion flags stamp only the columns that changed")
if layout:find('"P" .. tostring(page)', 1, true) then
	failures[#failures + 1] = "mapping signature must not key on the page number"
end
do
	local i = layout:find("function Layout.ApplyMappings", 1, true)
	local j = layout:find("function Layout.RevealEmptyInCombat", 1, true)
	local body = (i and j and layout:sub(i, j - 1)) or ""
	has(body, "if changed then", "ForceApply only when a promotion flag actually moved")
	has(body, "ApplySlotsInsecure", "ApplyMappings restamps even when ForceApply is a no-op")
end
do
	local i = layout:find("function Layout.Apply()", 1, true)
	local j = layout:find("function Layout.Request", 1, true)
	local body = (i and j and layout:sub(i, j - 1)) or ""
	has(body, "if not moved then", "pet restack and stance rebuild need the strip to have moved")
end

local secretsSrc = readCore("API/Secrets.lua")
has(secretsSrc, "function Secrets.SafeCountKey", "SafeCountKey")
has(secretsSrc, "Never tostring+compare a secret", "SafeCountKey skips secrets")
do
	local sfn, serr = loadfile(coreDir .. "/API/Secrets.lua")
	if not sfn then
		failures[#failures + 1] = "load Secrets.lua: " .. tostring(serr)
	else
		local ns = { Flux = {} }
		sfn("FluxUI", ns)
		local keyFn = ns.Flux.Secrets and ns.Flux.Secrets.SafeCountKey
		if not keyFn then
			failures[#failures + 1] = "Secrets.SafeCountKey missing"
		else
			if keyFn(nil) ~= "" or keyFn("") ~= "" then
				failures[#failures + 1] = "SafeCountKey empty"
			end
			if keyFn(3) ~= "3" then
				failures[#failures + 1] = "SafeCountKey number"
			end
			local emptyFn = ns.Flux.Secrets.SafeLooksEmpty
			if not emptyFn then
				failures[#failures + 1] = "Secrets.SafeLooksEmpty missing"
			else
				if emptyFn(nil) ~= true or emptyFn("") ~= true then
					failures[#failures + 1] = "SafeLooksEmpty empty"
				end
				if emptyFn("2") ~= false then
					failures[#failures + 1] = "SafeLooksEmpty text"
				end
			end
			local boolFn = ns.Flux.Secrets.SafeBooleanTest
			if not boolFn then
				failures[#failures + 1] = "Secrets.SafeBooleanTest missing"
			else
				if boolFn(true, false) ~= true or boolFn(false, true) ~= false then
					failures[#failures + 1] = "SafeBooleanTest plain bool"
				end
				if boolFn(nil, true) ~= true then
					failures[#failures + 1] = "SafeBooleanTest nil default"
				end
			end
			local noopFn = ns.Flux.Secrets.AuraUpdateInfoIsNoop
			if not noopFn then
				failures[#failures + 1] = "Secrets.AuraUpdateInfoIsNoop missing"
			else
				if noopFn(nil) ~= false then
					failures[#failures + 1] = "AuraUpdateInfoIsNoop nil"
				end
				if noopFn({ isFullUpdate = true }) ~= false then
					failures[#failures + 1] = "AuraUpdateInfoIsNoop full"
				end
				if noopFn({ isFullUpdate = false }) ~= true then
					failures[#failures + 1] = "AuraUpdateInfoIsNoop empty diff"
				end
				if noopFn({ isFullUpdate = false, addedAuras = { 1 } }) ~= false then
					failures[#failures + 1] = "AuraUpdateInfoIsNoop added"
				end
			end
		end
	end
end

local capSrc = readCore("Capabilities.lua")
has(capSrc, "function Cap.HasAtlas", "Cap.HasAtlas")
has(capSrc, "C_Texture.GetAtlasInfo", "HasAtlas uses C_Texture.GetAtlasInfo")

local spellSrc = readCore("API/Spell.lua")
has(spellSrc, "function Spell.GetChargeDuration", "Spell.GetChargeDuration")
has(spellSrc, "GetSpellChargeDuration", "C_Spell.GetSpellChargeDuration")
has(spellSrc, "chargeActive", "GetCharges keeps isActive when charge counts are secret")
has(spellSrc, "Client.isCamelot or Client.isEra or Client.isAnniversary or Client.isTBC or Client.isWrath", "Spell.GetInfo keeps Classic rank subtext on Forever/Era/Anniversary")
has(spellSrc, "RequestLoadSpellData", "cold spell info requests the record")
has(spellSrc, "SPELL_DATA_LOAD_RESULT", "spell data load clears the info miss and repaints badges")
has(spellSrc, "function Spell.IsCurrent", "Spell.IsCurrent")
has(spellSrc, "function Spell.IsAutoRepeat", "Spell.IsAutoRepeat")
has(spellSrc, "GetOverrideSpell", "Spell.IsCurrent tries override id")
has(spellSrc, "FormatCastAttribute", "Spell.IsCurrent tries Classic name+rank")
has(spellSrc, "Client.isCamelot or Client.isForever", "Forever cast attributes keep Name(Rank N)")
local ebsCore = read("../ExtraButtonSystem/Engine/Core.lua")
has(ebsCore, "FLUX_API.isCamelot or FLUX_API.isForever", "Forever button casts use rank names, not numeric ids")
has(capSrc, "hasSkyriding = Client.isRetail and Client.isPostDF and not Client.isCamelot", "Forever does not take the live skyriding bar page")
has(spellSrc, "function Spell.GetTexture", "Spell.GetTexture is uncached live icon")
has(spellSrc, "function Spell.GetConditionalIcon", "Spell.GetConditionalIcon is the on-state face")
has(spellSrc, "conditionalIconID", "Spell.GetTexture uses conditional/form icon")
do
	local i = spellSrc:find("function Spell.GetTexture", 1, true)
	local j = spellSrc:find("function Spell.GetSubtext", 1, true)
	local body = (i and j and spellSrc:sub(i, j - 1)) or ""
	local ov = body:find("GetOverrideSpell", 1, true)
	local base = body:find("GetBaseSpell", 1, true)
	if not ov then
		failures[#failures + 1] = "Spell.GetTexture must query GetOverrideSpell"
	end
	if ov and base and ov > base then
		failures[#failures + 1] = "Spell.GetTexture must query override before base"
	end
	-- pcall(fn, ident) already forwards every return; the closure form was
	-- pure garbage on a hot path. The helpers live at file scope so the icon
	-- lane does not build three closures per button per paint.
	if not spellSrc:find("pcall(fn, ident)", 1, true) then
		failures[#failures + 1] = "Spell.GetTexture must pcall with arguments, not a closure"
	end
	if body:find("local function", 1, true) then
		failures[#failures + 1] = "Spell.GetTexture must not define closures per call"
	end
	has(spellSrc, "local function PullIcon", "icon pull helper is hoisted")
	has(spellSrc, "local function TextureFor", "icon lookup helper is hoisted")
end
has(spellSrc, "FindSpellOverrideByID", "Classic override fallback")
has(spellSrc, "function Spell.GetLiveFace", "Spell.GetLiveFace is the Extra Button on-state face")
has(spellSrc, "FindSpellActionButtons", "GetLiveFace probes action-bar GetActionTexture")
has(spellSrc, "FindSpellBookSlotForSpell", "GetLiveFace probes spellbook texture")
has(spellSrc, "FindSpellBookSlotForSpell, spellId, false, false", "SpellBookFace does not include flyouts")
if spellSrc:find("FindSpellBookSlotForSpell, spellId, false, true", 1, true) then
	failures[#failures + 1] = "SpellBookFace must not include flyouts (parent flyout icon)"
end
has(spellSrc, 'actionType == "flyout"', "ActionBarFace skips flyout bar slots")
has(spellSrc, "BookSlotIsFlyout", "spellbook face skips flyout book slots")
has(spellSrc, "function Spell.FindFlyoutSlotCastID", "popup drag resolves inner flyout slot id")
has(spellSrc, "Spell_Nature_WispSplode", "active form extras use Blizzard action-button wisp")
has(spellSrc, "MatchesActiveForm", "GetLiveFace matches the active shapeshift spell")
has(spellSrc, "function Spell.ClearLiveFaceCache", "live face cache clears on icon flush")
if spellSrc:find("WispSpellIds", 1, true) then
	failures[#failures + 1] = "Spell.GetLiveFace must not use a WispSpellIds table"
end
has(spellSrc, 'Register("SPELL_UPDATE_ICON"', "SPELL_UPDATE_ICON clears Spell cache")
has(spellSrc, "function Spell.GetFlyoutInfo", "Spell.GetFlyoutInfo")
has(spellSrc, "function Spell.GetFlyoutSlotInfo", "Spell.GetFlyoutSlotInfo")
has(spellSrc, "function Spell.FlyoutSlotCastID", "Spell.FlyoutSlotCastID prefers override > 0")
has(spellSrc, "function Spell.FlyoutHasSpell", "Spell.FlyoutHasSpell")
has(spellSrc, "C_Spell.GetFlyoutInfo", "flyout info falls back to C_Spell")
has(spellSrc, "C_Spell.GetFlyoutSlotInfo", "flyout slot falls back to C_Spell")

local itemSrc = readCore("API/Item.lua")
has(itemSrc, "function Item.GetCooldown", "Item.GetCooldown")
has(itemSrc, "function Item.IsCurrent", "Item.IsCurrent")
has(itemSrc, "function Item.IsConsumable", "Item.IsConsumable covers mana gems")
has(itemSrc, "local MANA_GEM_IDS", "Item.IsConsumable knows mana gem ids")
has(itemSrc, "function Item.IsEquipped", "Item.IsEquipped")
has(itemSrc, "rankOrId", "Item.GetSpell keeps Classic spellID (not rank)")
has(itemSrc, "C_Item.GetItemCooldown", "item CD prefers C_Item (post-DF ButtonForge)")
has(itemSrc, "C_Container.GetItemCooldown", "item CD prefers C_Container (Classic/TBC ButtonForge)")
has(itemSrc, "longest remaining", "item CD picks unique timer over a GCD stub")

local chargesSrc = readCore("ButtonFX/Charges.lua")
has(chargesSrc, "widget.chargeCooldown", "dual chargeCooldown")
has(chargesSrc, "SetDrawSwipe", "charge edge no swipe")
has(chargesSrc, "GetChargeDuration", "charge duration object")
has(chargesSrc, "IdleHide", "idle cooldown hides instead of flashing")
has(chargesSrc, "do not Hide", "idle cooldown must stay shown for main↔mini VFX")
has(chargesSrc, "NeedDurationObject", "ready spells do not fetch a GCD duration object")
has(chargesSrc, "SetDrawBling", "bling off before clearing a ready cooldown")
has(chargesSrc, "skipDurationObject", "item/spell CD is not replaced by the GCD duration object")
has(chargesSrc, "itemCooldown", "item cooldown does not fetch spell GetCooldownDuration")
has(chargesSrc, "chargeDur <= 2", "charge edge is not used for GCD-length recharge")
has(chargesSrc, "NeverSecret true", "charge isActive still shows the recharge edge in combat")
has(chargesSrc, "keep the last recharge edge", "secret charge counts do not Hide the edge")
has(chargesSrc, "hideCooldownFrame = nil", "CD paint clears leftover hideCooldownFrame")
has(chargesSrc, "ov.HideCooldownCover(widget, false)", "CD paint restores cover when interrupt is over")
has(chargesSrc, "local function SetTimer", "Charges paints Cooldown:SetCooldown")
has(chargesSrc, "SetCooldownFromExpirationTime", "Charges can set aura remaining from expirationTime")
has(chargesSrc, "opts.expirationTime", "Charges.Apply forwards expirationTime")
if chargesSrc:find("hooksecurefunc", 1, true) then
	failures[#failures + 1] = "Charges must not hooksecurefunc"
end

local overlaySrc = readCore("ButtonFX/Overlay.lua")
has(overlaySrc, "function Overlay.Attach", "Overlay.Attach")
has(overlaySrc, "Charges.Ensure", "Overlay.Attach creates chargeCooldown OOC")
has(overlaySrc, "ActionButtonCastingAnimFrameTemplate", "cast template")
has(overlaySrc, "ActionButtonInterruptTemplate", "interrupt template")
has(overlaySrc, "ActionButtonTargetReticleFrameTemplate", "reticle template")
has(overlaySrc, "BuildInterruptFrame", "lua interrupt clone when mask atlas missing")
has(overlaySrc, "BuildReticleFrame", "lua reticle clone when mask atlas missing")
has(overlaySrc, "UI-HUD-ActionBar-Interrupt-Mask", "probes interrupt mask atlas")
has(overlaySrc, "UI-HUD-ActionBar-Target-Mask", "probes target mask atlas")
has(overlaySrc, "Media\\\\ActionBar\\\\", "spellfx mask media folder")
has(overlaySrc, "INTERRUPT_MASK_FILE", "interrupt mask addon texture")
has(overlaySrc, "TARGET_MASK_FILE", "target mask addon texture")
has(overlaySrc, "EnsureInterruptDisplay", "interrupt create skips XML when atlas missing")
has(overlaySrc, "EnsureReticleFrame", "reticle create skips XML when atlas missing")
do
	local function media(name)
		local f = io.open(dir .. "/../Media/ActionBar/" .. name, "rb")
		if not f then
			failures[#failures + 1] = "missing Media/ActionBar/" .. name
			return
		end
		f:close()
	end
	media("UI-HUD-ActionBar-Interrupt-Mask.tga")
	media("UI-HUD-ActionBar-Target-Mask.tga")
end
has(overlaySrc, "PlayClassicFill", "Classic cast fill")
has(overlaySrc, "INTERRUPT_HOLD", "interrupt hold 0.35")
has(overlaySrc, "GLOBAL_MOUSE_UP", "stuck PUSHED fallback")
do
	-- GLOBAL_MOUSE_UP lands before the button dispatches its mouse-up click,
	-- so the pushed-state cleanup must be deferred a frame.
	local watch = overlaySrc:match("EnsurePressWatch%(%)(.-)\nend") or ""
	if not watch:find("C_Timer.After(0", 1, true) then
		failures[#failures + 1] = "GLOBAL_MOUSE_UP ReleasePress must be deferred (cancels the up-click)"
	end
end
has(overlaySrc, "BURST_DURATION", "finish burst 0.45")
has(overlaySrc, "PlayClassicFinish", "Classic finish burst")
has(overlaySrc, "MatchesActiveButtonSpellID", "silence mixin reticle on dummy slots")
has(overlaySrc, "SilenceMixinVFX", "Overlay silences Blizzard spellcast collector")
has(overlaySrc, "DetachFromCollectors", "Overlay.Attach drops every action-button collector")
has(overlaySrc, "GlowMod.SilenceMixin", "Overlay silences mixin proc glow")
has(overlaySrc, "FlashMod.Ensure", "Overlay sizes the auto-attack flash")
if overlaySrc:find("widget.CheckNeedsUpdate = function", 1, true) then
	failures[#failures + 1] = "Overlay must not Flux-noop CheckNeedsUpdate (collector taint)"
end
if overlaySrc:find("widget.RegisterActionBarButtonCheckFrames = function", 1, true) then
	failures[#failures + 1] = "Overlay must not Flux-noop RegisterActionBarButtonCheckFrames (collector taint)"
end
has(overlaySrc, "function Overlay.ClearReticle", "Overlay.ClearReticle")
has(overlaySrc, "function Overlay.ApplyChecked", "Overlay.ApplyChecked")
has(overlaySrc, "function Overlay.CheckedVisualOn", "checked skip sees leftover hilight")
do
	local i = overlaySrc:find("function Overlay.CheckedVisualOn", 1, true)
	local j = overlaySrc:find("function Overlay.ApplyChecked", i, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if body:find("return shown and true or false", 1, true) then
		failures[#failures + 1] = "CheckedVisualOn must not treat a hidden gold overlay as unchecked"
	end
	has(body, "if ok and shown then", "CheckedVisualOn still checks the native hilight")
	has(body, "GetChecked", "CheckedVisualOn sees C++ GetChecked")
end
has(overlaySrc, "function Overlay.EnsureCheckedTexture", "Overlay.EnsureCheckedTexture")
has(overlaySrc, "function Overlay.IsCheckedSuppressed", "craft RC can suppress gold while First Aid opens")
has(overlaySrc, "_fluxPaintOwnsShow", "C++ checked Show is owned by Extra paint")
has(overlaySrc, "CheckButtonHilight", "gold checked texture")
has(overlaySrc, "_fluxGoldChecked", "extra gold overlay independent of CheckButton")
has(overlaySrc, "_fluxExtraButton", "gold overlay is extra-only")
has(overlaySrc, "1, 0.82, 0, 0.55", "checked uses the same gold tint on strip and extras")
do
	local i = overlaySrc:find("local function EnsureGoldOverlay", 1, true)
	local j = overlaySrc:find("function Overlay.EnsureCheckedTexture", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if not body:find("SkinCheckedTexture", 1, true) then
		failures[#failures + 1] = "extra gold overlay must use the same SkinCheckedTexture as the strip"
	end
	if body:find("level + 8", 1, true) then
		failures[#failures + 1] = "extra gold must not sit on a raised holder above cooldown/count"
	end
	if body:find("SetAllPoints(holder)", 1, true) then
		failures[#failures + 1] = "extra gold must size/center like strip checked, not SetAllPoints holder"
	end
end
has(overlaySrc, "_fluxReticleLive", "live reticle stamp not idle template")
do
	local i = overlaySrc:find("function Overlay.ApplyChecked", 1, true)
	local j = overlaySrc:find("function Overlay.IsPushed", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if body:find("already ~= checked", 1, true) then
		failures[#failures + 1] = "ApplyChecked must not skip SetChecked via GetChecked"
	end
	if not body:find("EnsureCheckedTexture", 1, true) then
		failures[#failures + 1] = "ApplyChecked must install gold CheckButtonHilight"
	end
	if not body:find("SetChecked", 1, true) then
		failures[#failures + 1] = "ApplyChecked must SetChecked after installing the texture"
	end
	has(body, "widget._fluxCheckedApplied = checked", "ApplyChecked stamps the applied state")
end
do
	local i = overlaySrc:find("local function SkinCheckedTexture", 1, true)
	local j = overlaySrc:find("local function EnsureGoldOverlay", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	has(body, "_fluxSkinOwner", "checked skin is stamped, not re-applied every paint")
	has(body, "_fluxSkinW", "checked skin re-runs when the button resizes")
end
do
	local i = overlaySrc:find("function Overlay.EnsureCheckedTexture", 1, true)
	local j = overlaySrc:find("function Overlay.ApplyChecked", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	has(body, "_fluxCheckedTex", "SetCheckedTexture installs once per button")
end
do
	local i = overlaySrc:find("function Overlay.IsLiveReticle", 1, true)
	local j = overlaySrc:find("function Overlay.IsLiveInterrupt", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if body:find("return FrameShown(widget.TargetReticleAnimFrame)", 1, true) then
		failures[#failures + 1] = "IsLiveReticle must not treat idle reticle template as live"
	end
	if not body:find("_fluxReticleLive", 1, true) then
		failures[#failures + 1] = "IsLiveReticle must use _fluxReticleLive"
	end
	if not body:find("FrameShown(rf)", 1, true) then
		failures[#failures + 1] = "IsLiveReticle anim path must require the reticle frame shown"
	end
end
do
	local i = overlaySrc:find("function Overlay.ResetTargetChrome", 1, true)
	local j = overlaySrc:find("local function NoMouse", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if body:find("ApplyChecked(widget, false)", 1, true) then
		failures[#failures + 1] = "ResetTargetChrome must not ApplyChecked false"
	end
	if body:find("widget.HighlightTexture", 1, true) then
		failures[#failures + 1] = "ResetTargetChrome must not Hide slot HighlightTexture"
	end
end
has(overlaySrc, "Do not tear down the live fill to show the reticle.", "PlayReticle does not kill a live channel fill")
do
	local i = overlaySrc:find("function Overlay.PlayReticle", 1, true)
	local j = overlaySrc:find("local function StopReticleHighlight", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if not body:find("ApplyChecked(widget, false)", 1, true) then
		failures[#failures + 1] = "PlayReticle must hide gold checked under the AOE reticle"
	end
	has(body, "LayoutReticle(widget, reticle)", "PlayReticle sizes reticle to 128*(w/44) x 128*(h/44)")
end
has(overlaySrc, "function Overlay.ReleasePress", "Overlay.ReleasePress")
has(overlaySrc, "function Overlay.FollowChrome", "Overlay.FollowChrome")
do
	local i = overlaySrc:find("function Overlay.FollowChrome", 1, true)
	local j = overlaySrc:find("function Overlay.ResetTargetChrome", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if body:find("ApplyChecked(from, false)", 1, true) then
		failures[#failures + 1] = "FollowChrome must not uncheck source gold"
	end
	if body:find("ApplyChecked(to, true)", 1, true) then
		failures[#failures + 1] = "FollowChrome must not transfer gold checked"
	end
	if not body:find("IsPushed", 1, true) then
		failures[#failures + 1] = "FollowChrome still transfers PUSHED"
	end
end
has(overlaySrc, "function Overlay.WatchNativeFill", "native fill ticker")
has(overlaySrc, "function Overlay._tickNativeFill", "manual CastFill progress")
has(overlaySrc, "VfxUnit(widget)", "fill times use widget VFX unit")
has(overlaySrc, "widget._fluxVfxUnit", "Overlay reads _fluxVfxUnit")
has(overlaySrc, "Pet fill must not stamp player", "pet NoteChannelTimes stays off the player bag")
has(overlaySrc, "Keep _fluxVfxUnit so fill times stay on pet vs player", "PlayCast keeps _fluxVfxUnit")
has(overlaySrc, "function Overlay._tickFinish", "finish burst timeout")
has(overlaySrc, "function Overlay.TickFill", "tick dest fill after transfer")
has(overlaySrc, "Overlay._transferring", "transfer skips OnHide swipe clear")
has(overlaySrc, "GLOBAL_MOUSE_UP", "press watch GLOBAL_MOUSE_UP")
has(overlaySrc, "HighlightAnim", "stop looping reticle highlight")
do
	local i = overlaySrc:find("function Overlay.PlayCast", 1, true)
	local j = overlaySrc:find("function Overlay.StopCast", 1, true)
	local playCast = (i and j and overlaySrc:sub(i, j - 1)) or ""
	has(playCast, "cf.Setup", "PlayCast native SpellCastAnimFrame:Setup")
	has(playCast, "not skipSetup", "PlayCast skipSetup for mid-cast appear")
	has(playCast, "WatchNativeFill", "PlayCast drives fill after Setup")
	has(playCast, "LayoutCastFrame(widget, cf, true)", "PlayCast raises fill above the cooldown swipe")
	if playCast:find("HideCooldownCover", 1, true) then
		failures[#failures + 1] = "PlayCast must keep cooldown running under channel fill"
	end
	has(playCast, "PlayClassicFill", "PlayCast Classic fill fallback")
	has(playCast, "Channel/empower: no fake 0.0001s duration.", "channel fill waits for UnitChannelInfo")
	has(playCast, "pre-DF classic fill when channel atlas missing", "pre-DF uses classic fill without DF atlas")
	has(overlaySrc, "SetUsingParentLevel", "SpellFX uses parent level so fill sits under the ring")
	has(overlaySrc, "local FILL_ALPHA = 0.80", "cast fill is readable, not fully solid")
	has(overlaySrc, "local CHANNEL_FILL_ALPHA = 0.62", "classic channel fill denser than the old wash")
	has(overlaySrc, "local CHANNEL_UNDER_ALPHA = 0.38", "native channel body is a tint, not a slab")
	has(overlaySrc, "ApplyChannelUnderlay", "native channel paints a body under the atlas")
	has(overlaySrc, "_fluxChannelUnder", "channel body lives on SpellCastAnimFrame")
	has(overlaySrc, "RETICLE_ABOVE_RING", "AOE reticle sits above the button ring")
	has(overlaySrc, "LayoutInterruptDisplay", "InterruptDisplay CENTER 128-scale")
	has(overlaySrc, "function OverlayTemplateSize", "overlay chrome size is 128 per axis")
	has(overlaySrc, "OVERLAY_TEMPLATE * (w / CAST_REF_W), OVERLAY_TEMPLATE * (h / CAST_REF_W)", "interrupt/cast/reticle size is 128*(w/44) x 128*(h/44)")
	has(overlaySrc, "function OverlayButtonHeight", "overlay Y uses GetHeight")
	has(overlaySrc, "function ScaleNativeRegion", "atlas art scales from native size not 128")
	has(overlaySrc, "function LayoutReticle", "reticle layout uses OverlayTemplateSize")
	has(overlaySrc, "OverlayButtonWidth(widget) / CAST_REF_W", "fill travel is GetWidth/44")
	if overlaySrc:find("widget._fluxStanceButtonSize", 1, true) then
		failures[#failures + 1] = "Overlay must not prefer stance visual width over GetWidth"
	end
	if overlaySrc:find("function Overlay.SyncSize", 1, true) then
		failures[#failures + 1] = "Overlay.SyncSize must be removed; stance uses widget SetScale"
	end
	if overlaySrc:find("StampedSqueezeRatio", 1, true) or overlaySrc:find("SqueezeRegion(fill.CastFill", 1, true) then
		failures[#failures + 1] = "Overlay must not SetSize CastFill after atlas"
	end
	do
		local i = overlaySrc:find("local function ApplyNativeFillProgress", 1, true)
		local j = overlaySrc:find("local function HideChannelUnderlay", 1, true)
		local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
		has(body, "elseif fill and fill.CastFill then", "NativeFillOffset SetPoint is not combined with ApplyCastBarLayoutFromButton")
		local slot = body:find("ApplyCastBarLayoutFromButton", 1, true)
		local setPoint = body:find("NativeFillOffset", 1, true)
		if slot and setPoint then
			local between = body:sub(math.min(slot, setPoint), math.max(slot, setPoint))
			if not between:find("elseif", 1, true) then
				failures[#failures + 1] = "ApplyNativeFillProgress must not call ApplyCastBarLayoutFromButton together with NativeFillOffset SetPoint"
			end
		end
	end
	do
		local i = overlaySrc:find("local function ApplyInterruptLayers", 1, true)
		local j = overlaySrc:find("local function ApplyReticleLevel", 1, true)
		local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
		has(body, "RETICLE_ABOVE_RING", "interrupt sits above the cooldown")
		has(body, "SetUsingParentLevel, frame, false", "InterruptDisplay is not parent-level under the cooldown")
	end
	has(overlaySrc, "sub > 7", "SetDraw clamps texture sublevel to 7")
	if overlaySrc:find('CreateTexture(nil, "OVERLAY", nil, 8)', 1, true) then
		failures[#failures + 1] = "CreateTexture OVERLAY sublevel must be <= 7"
	end
	if overlaySrc:find("level + 25", 1, true) or overlaySrc:find("+ 25)", 1, true) then
		failures[#failures + 1] = "Overlay must not raise SpellFX by +25 over the ring"
	end
	local stop = overlaySrc:find("function Overlay.StopCast", 1, true)
	local stopEnd = overlaySrc:find("function Overlay.PlayInterrupt", 1, true)
	local stopCast = (stop and stopEnd and overlaySrc:sub(stop, stopEnd - 1)) or ""
	has(stopCast, "FinishAnimAndPlayBurst", "LAB finish burst when fill playing")
	has(stopCast, "NativeFillPlaying", "no instant native burst")
	has(stopCast, "HideCastFill", "interrupt removes fill immediately")
end
has(overlaySrc, "function Overlay.IsLiveCast", "Overlay.IsLiveCast")
has(overlaySrc, "function Overlay.IsLiveBurst", "Overlay.IsLiveBurst")
has(overlaySrc, "function Overlay.ForceClear", "Overlay.ForceClear")
do
	local i = overlaySrc:find("function Overlay.ForceClear", 1, true)
	local j = overlaySrc:find("function Overlay.SyncCast", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	has(body, "ClearReticle", "ForceClear hides leftover reticle on the old face")
end
has(overlaySrc, "function Overlay.SyncCast", "Overlay.SyncCast")
has(overlaySrc, "function Overlay.SyncInterrupt", "Overlay.SyncInterrupt")
has(overlaySrc, "function Overlay.PlayBurst", "Overlay.PlayBurst")
	has(overlaySrc, "KickInterruptAnim", "interrupt plays AnimIn without Stop/OnFinished hide")
	has(overlaySrc, "HideCooldownCover", "HideCooldownCover still restores swipe after kick")
	has(overlaySrc, "function Overlay.ShouldHideCooldown", "ShouldHideCooldown API")
	has(overlaySrc, "ShownCooldownLevel", "fill/interrupt use shown cooldown level")
	has(overlaySrc, "full-dark slab", "cleared cooldown is not shown as a frozen slab")
	has(overlaySrc, "ApplyFillAboveCooldown", "channel fill sits above the cooldown swipe")
	has(overlaySrc, "FILL_ABOVE_COOLDOWN", "fill is one level above cooldown")
do
	local i = overlaySrc:find("function Overlay.ShouldHideCooldown", 1, true)
	local j = overlaySrc:find("function Overlay.ForceClear", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if body:find("return widget._fluxCdCoverHidden", 1, true) then
		failures[#failures + 1] = "ShouldHideCooldown must not sticky-hide Extra Button cooldown"
	end
	if not body:find("return false", 1, true) then
		failures[#failures + 1] = "interrupt must keep cooldown visible"
	end
	if body:find("InterruptDisplay", 1, true) then
		failures[#failures + 1] = "ShouldHideCooldown must not hide CD while interrupt chrome is up"
	end
end
	has(overlaySrc, "_fluxCdCoverHidden", "cooldown hide snapshot is idempotent")
	has(overlaySrc, "function Overlay.HideCooldownCover", "Charges/Paint can keep the cover down")
	has(overlaySrc, "already shown, do not Hide", "PlayInterrupt is idempotent Show-if-not-shown")
do
	local i = overlaySrc:find("function Overlay.PlayInterrupt", 1, true)
	local j = overlaySrc:find("function Overlay.PlayReticle", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if body:find("AnimIn:Stop(", 1, true) or body:find("AnimIn.Stop(", 1, true) then
		failures[#failures + 1] = "PlayInterrupt must not AnimIn:Stop (mixin OnFinished hides the kick)"
	end
	has(body, "LayoutInterruptDisplay", "PlayInterrupt lays out InterruptDisplay CENTER 128")
	if body:find("HideCooldownCover(widget, true)", 1, true) then
		failures[#failures + 1] = "PlayInterrupt must not hide cooldown under the kick"
	end
end
do
	local i = overlaySrc:find("function Overlay.PlayClassicInterrupt", 1, true)
	local j = overlaySrc:find("local function ClearFillForBurst", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if body:find("HideCooldownCover(widget, true)", 1, true) then
		failures[#failures + 1] = "classic interrupt must not hide cooldown"
	end
	has(body, "HideCooldownCover(widget, false)", "classic interrupt keeps cooldown")
end
do
	local i = overlaySrc:find("local function ApplyFillAboveCooldown", 1, true)
	local j = overlaySrc:find("local RETICLE_ABOVE_RING", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if body:find("cd.Show", 1, true) or body:find("pcall(cd.Show", 1, true) then
		failures[#failures + 1] = "ApplyFillAboveCooldown must not Show a cleared cooldown"
	end
end
do
	local i = overlaySrc:find("function Overlay.Attach", 1, true)
	local j = overlaySrc:find("local castFrame = widget.SpellCastAnimFrame", 1, true)
	local attachInt = (i and j and overlaySrc:sub(i, j - 1)) or ""
	has(attachInt, "LayoutInterruptDisplay", "Attach InterruptDisplay uses CENTER 128 layout")
	if attachInt:find("SetAllPoints", 1, true) then
		failures[#failures + 1] = "Attach must not SetAllPoints InterruptDisplay (backup is CENTER 128)"
	end
end
has(overlaySrc, "function Overlay.HideCastFill", "HideCastFill before finish burst")
has(overlaySrc, "EndBurstShown", "burst live requires EndBurst shown")
has(overlaySrc, "Overlay._clearing", "ForceClear skips OnHide reticle wipe")
has(overlaySrc, "function Overlay.IsLiveReticle", "Overlay.IsLiveReticle")
has(overlaySrc, "function Overlay.IsLiveInterrupt", "Overlay.IsLiveInterrupt")
has(overlaySrc, "function Overlay.TransferCast", "Overlay.TransferCast")
has(overlaySrc, "function Overlay.Transfer", "Overlay.Transfer")
has(overlaySrc, "ReparentedTo", "transfer verifies SetParent before swapping Lua refs")
has(overlaySrc, "Pre-create the classic fill driver OOC", "Attach precreates classic fill so combat SyncCast does not CreateFrame")
do
	local i = overlaySrc:find("function Overlay.TransferCast", 1, true)
	local j = overlaySrc:find("function Overlay.TransferReticle", 1, true)
	local body = (i and j and overlaySrc:sub(i, j - 1)) or ""
	if body:find("cf.Setup", 1, true) or body:find(":Setup(", 1, true) then
		failures[#failures + 1] = "TransferCast must not call Setup (restarts fill)"
	end
	if body:find("FinishAnimAndPlayBurst", 1, true) then
		failures[#failures + 1] = "TransferCast must not FinishAnimAndPlayBurst"
	end
end

local clickSrc = readCore("ButtonFX/Click.lua")
has(clickSrc, "button == \"KeyBind\"", "Click wrap KeyBind")
has(clickSrc, "button == \"ConjureBind\"", "Click wrap ConjureBind")
has(clickSrc, "elseif (down) then", "mouse-down swallow")
has(clickSrc, "CLICK_SNIPPET_ON_DOWN", "HUD extras can fire on mouse-down")
has(clickSrc, "elseif (not down) then", "onDown wrap swallows mouse-up")
has(clickSrc, "pressAndHoldAction", "ButtonForge pressAndHoldAction")
has(clickSrc, "function Click.Apply", "Click.Apply")
has(clickSrc, "function Click.MirrorTypeRelease", "typerelease mirrors type")
has(clickSrc, '"type1"', "MirrorTypeRelease copies type1")
has(clickSrc, '"type2"', "MirrorTypeRelease copies type2")
has(clickSrc, "typerelease2", "hold-release reads typerelease2")
-- Strip paging writes type* / shift-type* / ctrl-type*; without the mirror a
-- held SHIFT would cast on down and never resolve the hold-release path.
has(clickSrc, '"type*"', "MirrorTypeRelease copies the nomod paging type")
has(clickSrc, '"shift-type*"', "MirrorTypeRelease copies the shift paging type")
has(clickSrc, '"ctrl-type*"', "MirrorTypeRelease copies the ctrl paging type")
-- The empower gate has to follow the slot the press will actually use.
has(clickSrc, 'GetAttribute("shift-IsEmpowerSpell*")', "empower gate follows SHIFT paging")
has(clickSrc, 'GetAttribute("ctrl-IsEmpowerSpell*")', "empower gate follows CTRL paging")
has(clickSrc, 'GetAttribute("IsEmpowerSpell*")', "empower gate follows the nomod set")
do
	local snippet = clickSrc:match("CLICK_SNIPPET%s*=%s*%[%[(.-)%]%]") or ""
	has(snippet, "IsShiftKeyDown()", "click snippet resolves the modifier itself")
	if not snippet:find('IsEmpowerSpell = self:GetAttribute("IsEmpowerSpell")', 1, true) then
		failures[#failures + 1] = "click snippet must fall back to the bare IsEmpowerSpell (Extra widgets)"
	end
end
has(clickSrc, "WrapScript", "Click wrap lives in ButtonFX")
has(clickSrc, '"pressAndHoldAction", true', "Click.Apply pressAndHold always on")
has(clickSrc, "function Click.UsesWrap", "Click.UsesWrap gates Forever")
has(clickSrc, "Click.UsesWrap()", "Click.Apply consults UsesWrap")
has(clickSrc, 'widget:RegisterForClicks("AnyUp")', "Forever mouse is up-only")
has(clickSrc, '"useOnKeyDown", false', "Forever mouse ignores UseKeyDown")
has(clickSrc, '"pressAndHoldAction", false', "Forever mouse is not hold-release")
if clickSrc:find("ForeverOnClick", 1, true) then
	failures[#failures + 1] = "Forever must not SetScript OnClick (taints UseAction)"
end
if clickSrc:find("SecureActionButton_OnClick(self", 1, true) then
	failures[#failures + 1] = "Click.lua must not call SecureActionButton_OnClick from addon OnClick"
end
if clickSrc:find('widget:RegisterForClicks("AnyDown")', 1, true) then
	failures[#failures + 1] = "Forever Click.Apply must not register AnyDown only"
end
-- Wrapped_Click only runs a post-body when the pre-body returned a message, so
-- a wrap that clears attributes on mouse-up can never restore them.
if clickSrc:find("CLICK_POST", 1, true) then
	failures[#failures + 1] = "Click must not pass a WrapScript post-body (never runs)"
end
if clickSrc:find('self:SetAttribute("pressAndHoldAction"', 1, true) then
	failures[#failures + 1] = "Click snippet must not write pressAndHoldAction"
end
if clickSrc:find('self:SetAttribute("useOnKeyDown"', 1, true) then
	failures[#failures + 1] = "Click snippet must not write useOnKeyDown (ButtonForge never does)"
end
do
	local snippet = clickSrc:match("CLICK_SNIPPET%s*=%s*%[%[(.-)%]%]") or ""
	if not snippet:find("elseif (down) then", 1, true) then
		failures[#failures + 1] = "Click snippet must swallow mouse-down"
	end
	if not snippet:find('button == "ConjureBind"', 1, true) then
		failures[#failures + 1] = "Click snippet must remap ConjureBind to RightButton"
	end
	if snippet:find("SetAttribute", 1, true) then
		failures[#failures + 1] = "Click snippet must not set attributes"
	end
end
do
	local onDownSnippet = clickSrc:match("CLICK_SNIPPET_ON_DOWN%s*=%s*%[%[(.-)%]%]") or ""
	if not onDownSnippet:find("elseif (not down) then", 1, true) then
		failures[#failures + 1] = "onDown Click snippet must swallow mouse-up"
	end
	if onDownSnippet:find("SetAttribute", 1, true) then
		failures[#failures + 1] = "onDown Click snippet must not set attributes"
	end
	if not onDownSnippet:find('button == "ConjureBind"', 1, true) then
		failures[#failures + 1] = "onDown Click snippet must remap ConjureBind"
	end
	local i = onDownSnippet:find('button == "ConjureBind"', 1, true)
	local j = i and onDownSnippet:find("elseif (not down)", i, true)
	local chunk = (i and j and onDownSnippet:sub(i, j - 1)) or ""
	if chunk:find("ActionButtonUseKeyDown", 1, true) then
		failures[#failures + 1] = "HUD ConjureBind must fire on press, not follow UseKeyDown"
	end
	if not chunk:find('return "RightButton"', 1, true) then
		failures[#failures + 1] = "HUD ConjureBind must return RightButton on down"
	end
end

local glowSrc = readCore("ButtonFX/Glow.lua")
has(glowSrc, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", "Glow SHOW event")
has(glowSrc, "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", "Glow HIDE event")
has(glowSrc, "function Glow.Want", "Glow.Want")
has(glowSrc, "function Glow.SaoMembership", "Glow SAO membership")
has(glowSrc, "function Glow.InstallSAO", "InstallSAO exists")
has(glowSrc, "function Glow.NotifySAO", "NotifySAO exists")
has(glowSrc, "useExternalGlow = true", "SAO does not paint LBG ants")
has(glowSrc, "AddGlowNumber", "Glow hooks SAO AddGlowNumber")
has(glowSrc, "hooksecurefunc", "SAO/LBG membership is hooksecurefunc after original")
has(glowSrc, "SpellActivationOverlayAddonFrame", "binds unpublished SAO ns")
has(glowSrc, "LibButtonGlow-1.0", "hooks SAO LibButtonGlow")
has(glowSrc, "_fluxLbgGlowSpell", "LBG hide decrements the spell stamped on show")
has(glowSrc, "_fluxProcAlert", "Flux proc overlay is not SpellActivationAlert")
has(glowSrc, "IsSpellOverlayed", "native overlay API is membership authority")
has(glowSrc, "GetAtlasInfo", "skip missing proc atlas")
has(glowSrc, "CaptureSao", "Era SAO table is captured without _G.ipairs")
has(glowSrc, "getupvalue", "SAO ns from OnEvent upvalues")
has(glowSrc, "setfenv", "OOC setfenv proxy if getupvalue is missing")
has(glowSrc, "SPELLS_CHANGED", "setfenv capture uses SPELLS_CHANGED")
has(glowSrc, "PLAYER_REGEN_ENABLED", "retry SAO bind after combat")
has(glowSrc, "AutoCastShineTemplate", "Era FlipBook miss falls back to AutoCastShine")
has(glowSrc, "MarkGlow", "tracks AddGlowNumber locally")
has(glowSrc, "_G.FluxEffectGlow = Glow", "FluxEffectGlow alias")
has(glowSrc, "GetOverrideSpell", "Glow override match")
has(glowSrc, "function Glow.Set", "Glow.Set")
has(glowSrc, "function Glow.IsLive", "Glow.IsLive")
has(glowSrc, "function Glow.Transfer", "Glow.Transfer")
do
	local i = glowSrc:find("function Glow.Transfer", 1, true)
	local j = i and glowSrc:find("function Glow.ShouldSkipBirth", i, true)
	local body = (i and j and glowSrc:sub(i, j - 1)) or ""
	has(body, "GetParent", "glow transfer verifies SetParent before stealing the overlay")
end
has(glowSrc, "function Glow.ShouldSkipBirth", "Glow skipBirth if intro already ran")
has(glowSrc, "function Glow.FaceShowsSpell", "Glow drops when the icon left the spell")
has(glowSrc, "function Glow.NoteShown", "Glow stamps birth spell")
has(glowSrc, "function Glow.NoteHidden", "Glow clears face without losing birth while proc lives")
has(glowSrc, "function Glow.SilenceMixin", "Glow.SilenceMixin")
has(glowSrc, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", "SilenceMixin unregisters mixin glow SHOW")
do
	local i = glowSrc:find("function Glow.SilenceMixin", 1, true)
	local j = i and glowSrc:find("local function ResolveGlowSpell", i, true)
	local body = (i and j and glowSrc:sub(i, j - 1)) or ""
	if body == "" then
		failures[#failures + 1] = "Glow.SilenceMixin body"
	end
	local code = body:gsub("%-%-[^\n]*", "")
	if code:find("UpdateSpellAlert", 1, true) then
		failures[#failures + 1] = "Glow.SilenceMixin must not assign UpdateSpellAlert"
	end
	if code:find("UpdateOverlayGlow", 1, true) then
		failures[#failures + 1] = "Glow.SilenceMixin must not assign UpdateOverlayGlow"
	end
	has(code, "UnregisterEvent", "SilenceMixin unregisters mixin glow events")
end
has(glowSrc, "EnsureOwnAlert", "Glow paints ActionButtonSpellAlertTemplate")
has(glowSrc, "skipBirth", "Glow.Set skipBirth")
has(glowSrc, "startAnim = false", "transfer does not replay ProcStart")
has(glowSrc, "SnapClassicAnimIn", "Classic animIn snap")
has(glowSrc, "ProcGlow_Start", "LCG ProcGlow is the missing-template fallback")
if glowSrc:find("LibActionButton", 1, true) then
	failures[#failures + 1] = "Glow must not use LAB"
end
do
	local setI = glowSrc:find("function Glow.Set", 1, true)
	local setJ = setI and glowSrc:find("function Glow.Transfer", setI, true)
	local setBody = (setI and setJ and glowSrc:sub(setI, setJ - 1)) or ""
	if setBody == "" then
		failures[#failures + 1] = "Glow.Set body"
	end
	if setBody:find("ProcAtlasExists", 1, true) then
		failures[#failures + 1] = "Glow.Set must not be ProcAtlasExists-only"
	end
	has(setBody, "ProcGlow_Start", "Glow.Set tries LCG ProcGlow")
	has(setBody, "StartShine", "Glow.Set AutoCastShine fallback")
	has(setBody, "_fluxProcAlert", "Glow.Set stores _fluxProcAlert")
end
do
	local glowCode = glowSrc:gsub("%-%-[^\n]*", "")
	if glowCode:find("ShowAlert", 1, true) then
		failures[#failures + 1] = "Glow must not call spell-alert manager ShowAlert"
	end
	if glowCode:find("activeAlerts", 1, true) then
		failures[#failures + 1] = "Glow must not write spell-alert manager activeAlerts"
	end
	if glowCode:find("ActionButton_ShowOverlayGlow", 1, true) or glowCode:find("ActionButton_HideOverlayGlow", 1, true) then
		failures[#failures + 1] = "Glow must not call ActionButton_*OverlayGlow"
	end
	if glowCode:find("SAO.AddGlow = function", 1, true) or glowCode:find("lib.ShowOverlayGlow = function", 1, true) then
		failures[#failures + 1] = "Glow must not replace SAO/LBG glow functions"
	end
	if glowCode:find("_G.ipairs", 1, true) then
		failures[#failures + 1] = "Glow must never assign _G.ipairs (nameplate/collector taint)"
	end
	if glowCode:find("SpellActivationOverlay_OnEvent%s*=", 1, true) then
		failures[#failures + 1] = "Glow must not replace SpellActivationOverlay_OnEvent"
	end
	if glowCode:find('SetScript("OnEvent"', 1, true) then
		failures[#failures + 1] = "Glow must not SetScript OnEvent on SAO"
	end
	if glowCode:find("widget.SpellActivationAlert = created", 1, true) then
		failures[#failures + 1] = "Glow must not write widget.SpellActivationAlert"
	end
	for _, method in ipairs({ "SetHeight", "SetWidth", "SetSize", "SetScale", "SetParent", "Show", "SetPoint" }) do
		if glowCode:find('hooksecurefunc%([^)]*"' .. method .. '"', 1, false) then
			failures[#failures + 1] = "Glow must not hooksecurefunc Frame C method " .. method
		end
	end
	has(glowSrc, "local function CaptureSao", "CaptureSao exists")
	local capI = glowSrc:find("local function CaptureSao", 1, true)
	local capJ = capI and glowSrc:find("local function WrapSaoOnEvent", capI, true)
	local capBody = (capI and capJ and glowSrc:sub(capI, capJ - 1)) or ""
	if capBody == "" then
		failures[#failures + 1] = "CaptureSao body"
	elseif capBody:find("_G.ipairs", 1, true) then
		failures[#failures + 1] = "CaptureSao must not write _G.ipairs"
	end
end
do
	local i = glowSrc:find("function Glow.NotifySAO", 1, true)
	local j = i and glowSrc:find("function Glow.Start", i, true)
	local body = (i and j and glowSrc:sub(i, j - 1)) or ""
	if body:find("UpdateActionButton", 1, true) then
		failures[#failures + 1] = "NotifySAO must not call SAO.UpdateActionButton"
	end
end
if glowSrc:find("LBG.ShowOverlayGlow", 1, true) or glowSrc:find("ShowOverlayGlow(self)", 1, true) then
	failures[#failures + 1] = "SAO EnableGlow must not call LibButtonGlow ants"
end

local flashSrc = readCore("ButtonFX/Flash.lua")
has(flashSrc, "function Flash.Ensure", "Flash.Ensure")
has(flashSrc, "function Flash.Set", "Flash.Set")
has(flashSrc, "function Flash.WantSlot", "Flash.WantSlot")
has(flashSrc, "function Flash.WantSpell", "Flash.WantSpell")
has(flashSrc, "function Flash.WantItem", "Flash.WantItem")
has(flashSrc, "PLAYER_ENTER_COMBAT", "melee flash starts on enter combat")
has(flashSrc, "PLAYER_LEAVE_COMBAT", "melee flash stops on leave combat")
has(flashSrc, "START_AUTOREPEAT_SPELL", "auto-shot flash starts on auto-repeat")
has(flashSrc, "STOP_AUTOREPEAT_SPELL", "auto-shot flash stops with auto-repeat")
has(flashSrc, "UI-QuickslotRed", "Classic/pre-DF red flash file")
has(flashSrc, "UI-HUD-ActionBar-IconFrame-Flash", "Forever/Retail HUD flash atlas")
has(flashSrc, "ATTACK_BUTTON_FLASH_TIME", "flash period matches Blizzard")
has(flashSrc, "Flux.Ticker", "flash blink is demand-armed")
has(flashSrc, "buttonfx.flash", "flash ticker key")
has(flashSrc, "6603", "Attack spell id for Extra faces")
has(flashSrc, "function Flash.InMeleeCombat", "melee flag follows enter/leave combat")
if flashSrc:find("UnitAffectingCombat", 1, true) then
	failures[#failures + 1] = "Flash must not use UnitAffectingCombat for auto-attack"
end
if flashSrc:find("LibActionButton", 1, true) then
	failures[#failures + 1] = "Flash must not use LAB"
end

local castSrc = readCore("ButtonFX/Cast.lua")
has(castSrc, "function Cast.FollowColumn", "Cast.FollowColumn")
has(castSrc, "FollowChrome", "FollowColumn FollowChrome pushed")
has(castSrc, "ForceClear", "FollowColumn clears faces that left the spell")
has(castSrc, "FaceSpell(source)", "empty face does not keep burst")
has(castSrc, "Keep a live kick on source even when FaceSpell is nil", "strip FollowColumn keeps channel interrupt on lag")
has(castSrc, "ov.SyncBurst", "FollowColumn does not restart PlayBurst")
has(castSrc, "SyncCast", "FollowColumn appears at live progress")
has(castSrc, "OwnerScore", "owner pick live/pressed over rank")
has(castSrc, "local function MovePaint", "dest slot match always receives VFX")
has(castSrc, "ColumnIdentityLag", "nil slot identity retries instead of painting the wrong row")
has(castSrc, "C_Timer.After(0, pass)", "FollowColumn retry at 0")
has(castSrc, "C_Timer.After(0.05, pass)", "FollowColumn retry at 0.05s")
has(castSrc, "Cast._active", "live cast bag for mid-cast appear")
has(castSrc, "Cast._interrupt", "interrupt window follows paging")
has(castSrc, "Cast._finish", "finish burst window follows paging")
has(castSrc, "KnownOtherSpell", "live conflict clears rather than sticky keep")
has(castSrc, "Do not fall through to C_ActionBar.GetSpell", "macro id must not keep a stale proc glow")
has(castSrc, "_fluxInterruptSpell", "interrupt stamp for paging")
has(castSrc, "_fluxCastSpell", "in-flight spell stamp")
has(castSrc, "Cast.PickOwner", "exclusive owner")
has(castSrc, "Cast.PickOwners", "per-column exclusive")
has(castSrc, "GetVisibleBadgesForButton", "FollowColumn includes visible badges")
has(castSrc, "RANK_BADGE", "bar-hosted badges share column VFX")
do
	local i = castSrc:find("local function OwnerKey", 1, true)
	local j = i and castSrc:find("local function FaceIsLive", i, true)
	local body = (i and j and castSrc:sub(i, j - 1)) or ""
	has(body, "RANK_BADGE", "OwnerKey col for bar-hosted badges")
	has(body, '"ebs:"', "Extra window RANK_EBS stays ebs owner")
	if not body:find("rank == Cast.RANK_BADGE", 1, true) then
		failures[#failures + 1] = "OwnerKey must treat RANK_BADGE as a strip column owner"
	end
	local ebsLine = body:find('return "ebs:"', 1, true)
	local badgeBranch = body:find("rank == Cast.RANK_BADGE", 1, true)
	if ebsLine and badgeBranch and ebsLine < badgeBranch then
		failures[#failures + 1] = "RANK_EBS ebs: must not catch RANK_BADGE"
	end
end
do
	local i = castSrc:find("local function BestFace", 1, true)
	local j = i and castSrc:find("local function ColumnIdentityLag", i, true)
	local body = (i and j and castSrc:sub(i, j - 1)) or ""
	has(body, "RANK_BADGE", "BestFace allows bar-hosted badges")
end
has(castSrc, "UNIT_SPELLCAST_START", "cast start")
has(castSrc, "UNIT_SPELLCAST_RETICLE_TARGET", "reticle events")
has(castSrc, "Cast._reticle", "reticle spell bag for paging")
has(castSrc, "SpellIsTargetingNow", "reticle window retriggers FollowColumn")
has(castSrc, "function Cast.NoteTargeting", "clicked button owns reticle")
has(castSrc, "function Cast.PickAllMatching", "reticle keeps every matching face")
has(castSrc, "local function PickReticleOwners", "reticle owners are same-identity")
has(castSrc, "local function ClaimReticle", "reticle claim is exclusive")
has(castSrc, "A different identity clears", "different AOE click does not keep the first reticle")
has(castSrc, "function Cast.SpellBlockedAsCurrent", "block stale current after reticle")
has(castSrc, "Paint.RequestCheckedSettle", "cast dirty settles EBS gold after reticle")
has(castSrc, "ResetTargetChrome", "reticle clear resets press+reticle")
do
	local i = castSrc:find('event == "CURRENT_SPELL_CAST_CHANGED"', 1, true)
	local snippet = i and castSrc:sub(i, i + 420) or ""
	if snippet:find("OnReticleClear", 1, true) then
		failures[#failures + 1] = "CURRENT_SPELL_CAST_CHANGED must not OnReticleClear when not targeting"
	end
end
has(castSrc, "Do not treat STOP as interrupt", "STOP vs SUCCEEDED")
has(castSrc, "PickPressed", "pressed button owns fill when id match fails")
has(castSrc, "LiveCastName", "UnitCastingInfo name match")
has(castSrc, "RanksCompatible", "spell ranks stay distinct")
has(castSrc, "#matched == 0", "instant SUCCEEDED has no fill")
has(castSrc, "Do not play the finish burst", "instant must not EndBurst")
has(castSrc, "if InterruptWindowLive(unit) then", "STOP/cancel does not wipe a live interrupt")
has(castSrc, "CHANNEL_STOP is a kick, not a finish burst", "channel stop without duration is interrupt")
has(castSrc, "Cast._active.endTime", "CHANNEL_STOP early check uses unit endTime on the cast bag")
has(castSrc, "endTime / 1000", "channel endTime is milliseconds")
has(castSrc, "function Cast.NoteChannelTimes", "native fill ticker refreshes channel times")
has(castSrc, "local function CollectInterruptOwners", "OnInterrupt paints every matching strip column")
has(castSrc, "BestFace", "interrupt owners include column BestFace")
has(castSrc, "Do not FollowWidgets immediately", "OnInterrupt does not settle before Extra Buttons would")
has(castSrc, "RegisterUnitEvent", "interrupt/channel events register as unit events")
has(castSrc, '"player", "pet"', "dispatcher registers player and pet")
has(castSrc, 'unit == "pet"', "dispatcher handles pet unit")
has(castSrc, "ClearPetUnitVfx", "UNIT_PET ForceClear pet faces")
has(castSrc, "OnReticleClear(UNIT_PET)", "AOE cancel clears pet-bar reticle VFX")
has(castSrc, "KeepUnitReticle(UNIT_PET)", "pet reticle stays while SpellIsTargeting")
do
	local i = castSrc:find("function Cast.NoteTargeting", 1, true)
	local j = i and castSrc:find("function Cast.Debug", i, true)
	local body = (i and j and castSrc:sub(i, j - 1)) or ""
	has(body, "StartReticleWatch()", "pet NoteTargeting watches targeting so cancel can clear VFX")
end
if castSrc:find("if unit ~= \"pet\" then\n\t\t\t\t\tStartReticleWatch()", 1, true) then
	failures[#failures + 1] = "pet RETICLE_TARGET must StartReticleWatch so cancel can clear VFX"
end
has(castSrc, "EntryUnit(e) == unit", "PickOwners filters entry.unit")
has(castSrc, "w._fluxVfxUnit ~= UNIT_PET", "FollowWidgets skips pet-unit widgets")
has(castSrc, "function Cast.Register(widget, getSpellId, rank, unit)", "Cast.Register takes unit")
has(castSrc, "function Cast.AdoptFace", "Cast.AdoptFace moves Extra fill between faces")
has(castSrc, "widget._fluxVfxUnit = unit", "Register stamps _fluxVfxUnit")
has(castSrc, "Cast._petActive", "pet active bag is isolated from player")
do
	local i = castSrc:find('f:SetScript("OnEvent"', 1, true)
	local body = (i and castSrc:sub(i, i + 500)) or ""
	if body:find('if unit and unit ~= "player" then', 1, true) then
		failures[#failures + 1] = "dispatcher must not drop unit pet with a player-only return"
	end
	if not body:find('unit ~= "player" and unit ~= "pet"', 1, true) then
		failures[#failures + 1] = "dispatcher must accept player and pet units"
	end
end
has(castSrc, "_fluxInterruptFace", "interrupt stamps the face id so dest-nil lag cannot ForceClear")
do
	local i = castSrc:find("local function OnInterrupt", 1, true)
	local j = castSrc:find("local function OnChannelStop", 1, true)
	local body = (i and j and castSrc:sub(i, j - 1)) or ""
	has(body, "CollectInterruptOwners", "OnInterrupt owner list is strip columns plus activeCasts")
	if body:find("FollowWidgets(", 1, true) then
		failures[#failures + 1] = "OnInterrupt must not FollowWidgets immediately"
	end
end
do
	local i = castSrc:find("local function CollectInterruptOwners", 1, true)
	local j = castSrc:find("local function MaybeAdoptChannel", 1, true)
	local body = (i and j and castSrc:sub(i, j - 1)) or ""
	has(body, "PickStartOwners", "interrupt owners include PickStartOwners")
	has(body, "PickSmart", "interrupt owners include PickOwners/PickSmart")
	has(body, "BestFace", "interrupt owners include column BestFace")
	has(body, "NUM_COLUMNS", "interrupt paints all 19 strip columns")
end
has(castSrc, "SUCCEEDED stops CAST fills only", "SUCCEEDED does not finish channel fills")
has(castSrc, "local function OnChannelStop", "CHANNEL_STOP is the channel finish event")
has(castSrc, "CHANNEL_START always starts fill", "CHANNEL_START is not a reticle event")
has(castSrc, "if LiveFillKind(unit) then", "SUCCEEDED/STOP skip live channel")
has(castSrc, "local function PickStartOwners", "ground channel falls back to reticle owners")
has(castSrc, "local function MaybeAdoptChannel", "SUCCEEDED can start a live channel fill")
has(castSrc, "Do not settle that as reticle", "live channel wins over SpellIsTargeting")
do
	local i = castSrc:find('event == "UNIT_SPELLCAST_CHANNEL_START"', 1, true)
	local j = castSrc:find('event == "UNIT_SPELLCAST_CHANNEL_STOP"', 1, true)
	local startCh = (i and j and castSrc:sub(i, j - 1)) or ""
	if startCh:find("OnReticle", 1, true) then
		failures[#failures + 1] = "CHANNEL_START must not divert to reticle"
	end
	if not startCh:find("OnStart", 1, true) then
		failures[#failures + 1] = "CHANNEL_START must OnStart CHANNEL"
	end
	local stopI = j
	local stopJ = castSrc:find('event == "UNIT_SPELLCAST_RETICLE_TARGET"', 1, true)
	local stopCh = (stopI and stopJ and castSrc:sub(stopI, stopJ - 1)) or ""
	if stopCh:find("OnSucceeded", 1, true) then
		failures[#failures + 1] = "CHANNEL_STOP must not reuse OnSucceeded"
	end
	if not stopCh:find("OnChannelStop", 1, true) then
		failures[#failures + 1] = "CHANNEL_STOP must call OnChannelStop"
	end
end
if castSrc:find("C_ActionBar.RegisterActionUIButton", 1, true)
	or castSrc:find("RegisterActionUIButton,", 1, true)
then
	failures[#failures + 1] = "Cast must not RegisterActionUIButton"
end
if castSrc:find("ActionBarActionEventsFrame:RegisterFrame", 1, true)
	or castSrc:find("ActionBarActionEventsFrame.RegisterFrame", 1, true)
then
	failures[#failures + 1] = "Cast must not use ActionBarActionEventsFrame"
end

local actionFn, actionErr = loadfile(coreDir .. "/API/Action.lua")
if not actionFn then
	failures[#failures + 1] = "load Action.lua: " .. tostring(actionErr)
else
	local ns = { Flux = {} }
	actionFn("FluxUI", ns)
	local unpackFn = ns.Flux.Action and ns.Flux.Action.UnpackCharges
	if not unpackFn then
		failures[#failures + 1] = "Action.UnpackCharges missing"
	else
		local cur, maxC, start, duration, rate, active = unpackFn({
			currentCharges = 2,
			maxCharges = 3,
			cooldownStartTime = 10,
			cooldownDuration = 12,
			chargeModRate = 1,
			isActive = true,
		})
		if cur ~= 2 or maxC ~= 3 or start ~= 10 or duration ~= 12 or active ~= true then
			failures[#failures + 1] = "UnpackCharges table"
		end
		local c2, m2, s2, d2 = unpackFn(1, 4, 5, 6, 1)
		if c2 ~= 1 or m2 ~= 4 or s2 ~= 5 or d2 ~= 6 then
			failures[#failures + 1] = "UnpackCharges tuple"
		end
		local unpackCd = ns.Flux.Action.UnpackCooldown
		if not unpackCd then
			failures[#failures + 1] = "Action.UnpackCooldown missing"
		else
			local st, dur, en, active = unpackCd({
				startTime = 1,
				duration = 2,
				isEnabled = 1,
				isActive = true,
			})
			if st ~= 1 or dur ~= 2 or en ~= 1 or active ~= true then
				failures[#failures + 1] = "UnpackCooldown table"
			end
			local st2, dur2, en2, active2 = unpackCd(3, 4, 5, 6)
			if st2 ~= 3 or dur2 ~= 4 or en2 ~= 5 or active2 ~= nil then
				failures[#failures + 1] = "UnpackCooldown tuple"
			end
		end
	end
end

local toc = read("../_FluxUI.toc")
has(toc, "Core\\ButtonFX\\Charges.lua", "TOC Charges")
has(toc, "Core\\ButtonFX\\Click.lua", "TOC Click wrap")
has(toc, "Core\\ButtonFX\\Glow.lua", "TOC Glow")
has(toc, "libs\\LibCustomGlow-1.0\\LibCustomGlow-1.0.lua", "TOC LibCustomGlow ProcGlow fallback")
has(toc, "SpellActivationOverlay", "TOC OptionalDeps SAO")
has(toc, "Core\\ButtonFX\\Overlay.lua", "TOC Overlay")
has(toc, "Core\\ButtonFX\\Cast.lua", "TOC Cast")
has(toc, "Core\\ButtonFX\\Flash.lua", "TOC Flash")
has(toc, "Core\\API\\Pet.lua", "TOC Pet API")
has(toc, "Core\\API\\Shapeshift.lua", "TOC Shapeshift API")
has(toc, "Bars\\Pet\\Init.lua", "TOC Pet Init")
has(toc, "Bars\\Pet\\Layout.lua", "TOC Pet Layout")
has(toc, "Bars\\Pet\\Keys.lua", "TOC Pet Keys")
has(toc, "Bars\\Pet\\Watch.lua", "TOC Pet Watch")
has(toc, "Bars\\Stance\\Init.lua", "TOC Stance Init")
has(toc, "Bars\\Stance\\Order.lua", "TOC Stance Order")
has(toc, "Bars\\Stance\\Extras.lua", "TOC Stance Extras")
has(toc, "Bars\\Stance\\Forms.lua", "TOC Stance Forms")
has(toc, "Bars\\Stance\\Layout.lua", "TOC Stance Layout")
has(toc, "Bars\\Stance\\Watch.lua", "TOC Stance Watch")
if toc:find("Engine\\VFX.lua", 1, true) then
	failures[#failures + 1] = "TOC must not load old Extra Button VFX"
end
if toc:find("Actionbars\\Pet", 1, true) or toc:find("Actionbars\\Stance", 1, true) then
	failures[#failures + 1] = "TOC must not load backup Actionbars Pet/Stance"
end
if toc:find("Engine\\Button.lua", 1, true) or toc:find("Engine\\Core.lua", 1, true) then
	failures[#failures + 1] = "TOC must not load old Extra Button Button/Core"
end
if not toc:find("ExtraButtonSystem\\CombatGrid\\Grid.lua", 1, true) then
	failures[#failures + 1] = "TOC must load CombatGrid Grid"
end
if not toc:find("ExtraButtonSystem\\CombatGrid\\GridManager.lua", 1, true) then
	failures[#failures + 1] = "TOC must load CombatGrid GridManager"
end
has(toc, "CombatGrid\\Buttons\\Bandage.lua", "TOC CombatGrid Bandage")
has(toc, "CombatGrid\\Buttons\\HealPotion.lua", "TOC CombatGrid HealPotion")
has(toc, "CombatGrid\\Buttons\\ManaPotion.lua", "TOC CombatGrid ManaPotion")
has(toc, "CombatGrid\\Buttons\\ManaGem.lua", "TOC CombatGrid ManaGem")
has(toc, "CombatGrid\\Buttons\\Healthstone.lua", "TOC CombatGrid Healthstone")
has(toc, "CombatGrid\\Buttons\\Ammo.lua", "TOC CombatGrid Ammo")
if not toc:find("ExtraButtonSystem\\NonCombatGrid\\Grid.lua", 1, true) then
	failures[#failures + 1] = "TOC must load NonCombatGrid"
end
if toc:find("ExtraButtonSystem\\Flyout\\FluxFlyoutFrame", 1, true) then
	failures[#failures + 1] = "TOC must not load old ExtraButtonSystem Flyout this pass"
end
if toc:find("Inventory\\FluxInv\\", 1, true) then
	failures[#failures + 1] = "TOC must not load old Inventory\\FluxInv scanner"
end
has(toc, "Inventory\\SpellReagents.lua", "TOC SpellReagents")
has(toc, "libs\\C_Everywhere\\C_Everywhere.xml", "TOC C_Everywhere")
has(toc, "libs\\CustomSearch-1.0\\CustomSearch-1.0.lua", "TOC CustomSearch")
has(toc, "libs\\ItemSearch-1.3\\ItemSearch-1.3.xml", "TOC ItemSearch")
has(toc, "libs\\SecureTabs-2.0\\SecureTabs-2.0.lua", "TOC SecureTabs")
has(toc, "Inventory\\Restock\\FluxRestock_Inv.lua", "TOC FluxRestock.Inv facade")
has(toc, "Inventory\\FluxItemMover.lua", "TOC FluxItemMover")
has(toc, "Inventory\\Restock\\Junk\\FluxJunk.lua", "TOC FluxJunk")
has(toc, "Inventory\\Restock\\Core\\FluxRestockList.lua", "TOC FluxRestockList")
has(toc, "Inventory\\Restock\\Vendor\\FluxVendorBuy.lua", "TOC FluxVendorBuy")
has(toc, "Inventory\\Restock\\Bank\\FluxBankRestock.lua", "TOC FluxBankRestock")
has(toc, "Inventory\\Restock\\Vendor\\FluxVendorAutoMerchantUI.lua", "TOC merchant restock UI")
local vendorMerchantSrc = read("../Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua")
if vendorMerchantSrc == "" then
	failures[#failures + 1] = "read FluxVendorAutoMerchantUI.lua failed"
else
	local fromAtlases = vendorMerchantSrc:find("local function SetIconTextureFromAtlases", 1, true)
	local applySell = vendorMerchantSrc:find("local function ApplySellJunkButtonIcon", 1, true)
	if not fromAtlases or not applySell or fromAtlases > applySell then
		failures[#failures + 1] = "SetIconTextureFromAtlases must be declared before ApplySellJunkButtonIcon"
	end
end
has(toc, "Inventory\\Restock\\Bank\\FluxBankRestockButton.lua", "TOC bank restock button")
has(toc, "AddonOptions\\AceGUIWidget-FluxRestockPanel.lua", "TOC restock options widget")
has(toc, "AddonOptions\\FluxOptionsVendor.lua", "TOC Vendor & restock options")
has(toc, "FlyoutEngine\\Init.lua", "TOC FlyoutEngine Init")
has(toc, "FlyoutEngine\\Attach.lua", "TOC FlyoutEngine Attach")
has(toc, "FlyoutEngine\\Arrow.lua", "TOC FlyoutEngine Arrow")
has(toc, "FlyoutEngine\\Chrome.lua", "TOC FlyoutEngine Chrome")
has(toc, "FlyoutEngine\\Favorites.lua", "TOC FlyoutEngine Favorites")
has(toc, "Engine\\ConsumableBind.lua", "TOC ConsumableBind")
has(toc, "Shared\\FluxTooltipGuard.lua", "TOC isolated consumable tooltip guard")
has(toc, "Shared\\FluxMacroClickProxies.lua", "TOC click proxies for NC /click macros")
has(toc, "Inventory\\CreateSpells.lua", "TOC CreateSpells")
has(toc, "Inventory\\MountFlyable.lua", "TOC MountFlyable")
has(toc, "Inventory\\Professions.lua", "TOC Professions recipe cache")
has(toc, "Inventory\\Craft.lua", "TOC Craft consumables")
has(toc, "NonCombatGrid\\GridInit.lua", "TOC NC GridInit last")
has(toc, "Shared\\FluxConsumablesGridUI.lua", "TOC ConsumablesGridUI")
has(toc, "ExtraButtonSystem\\Shared\\HotkeyUtil.lua", "TOC TrinketMenu hotkey util")
has(toc, "ExtraButtonSystem\\Shared\\FluxExtraButtonVisibility.lua", "TOC Extra Button visibility")
has(toc, "ExtraButtonSystem\\TrinketMenu\\FluxTrinketMenu.lua", "TOC TrinketMenu")
has(toc, "ExtraButtonSystem\\TrinketMenu\\FluxTrinketMenuManager.lua", "TOC TrinketMenu Manager")
has(toc, "AddonOptions\\AceGUIWidget-FluxExtraButtonVisibility.lua", "TOC trinket visibility options widget")
has(toc, "ExtraButtonSystem\\ExtraButtons\\Core.lua", "TOC ExtraButtons Core")
has(toc, "ExtraButtonSystem\\ExtraButtons\\UI.lua", "TOC ExtraButtons UI")
has(toc, "ExtraButtonSystem\\ExtraButtons\\Categories.lua", "TOC ExtraButtons Categories")
has(toc, "ExtraButtonSystem\\ExtraButtons\\Buttons.lua", "TOC ExtraButtons Buttons")

local ebsDir = dir .. "/../ExtraButtonSystem"
local function readEbs(rel)
	local f = io.open(ebsDir .. "/" .. rel, "r")
	if not f then
		return ""
	end
	local s = f:read("*a")
	f:close()
	return s
end
local widgetSrc = readEbs("Engine/Widget.lua")
local ebsHostButtons = readEbs("ExtraButtons/Buttons.lua")
local ebsHostCore = readEbs("ExtraButtons/Core.lua")
local ebsHostUI = readEbs("ExtraButtons/UI.lua")
local ebsHostCategories = readEbs("ExtraButtons/Categories.lua")
local hearthCfg = readEbs("NonCombatGrid/FluxSmartHearthConfig.lua")
local trinketMenu = readEbs("TrinketMenu/FluxTrinketMenu.lua")
local trinketMgr = readEbs("TrinketMenu/FluxTrinketMenuManager.lua")
has(trinketMenu, "snapshots.bags.byBag", "TrinketMenu scans Flux.Inventory bag snapshots")
if trinketMenu:find("GetUniqueItems", 1, true) and not trinketMenu:find("snapshots.bags.byBag", 1, true) then
	failures[#failures + 1] = "TrinketMenu must prefer inventory snapshots over GetUniqueItems"
end
do
	local i = trinketMenu:find("function TM.FindTrinketInBags", 1, true)
	local j = i and trinketMenu:find("function TM.IsPlayerReallyDead", i, true)
	local body = (i and j and trinketMenu:sub(i, j - 1)) or ""
	has(body, "Inv.Find", "FindTrinketInBags uses Flux.Inventory.Find")
end
has(trinketMenu, "skipScripts = true", "HUD trinkets skip Extra-window scripts")
has(trinketMenu, "DetachFromCollectors", "trinket ActionButtonTemplate fallback leaves collectors")
has(trinketMenu, "skipMouseover = true", "HUD trinkets keep their own click wrap")
has(trinketMenu, "onDown = true", "HUD trinkets use on mouse-down")
has(trinketMenu, 'SetOverrideBindingClick(widget, false, key, widgetName, "KeyBind")', "both-equipped trinket KeyBind")
has(trinketMenu, 'SetOverrideBindingClick(targetWidget, false, key, targetWidget:GetName(), "KeyBind")', "one-equipped trinket KeyBind")
has(trinketMenu, "function TM.HookTrinketClickScripts", "HUD trinkets hook click scripts")
has(trinketMenu, "function TM.SyncKeybindPushWatch", "HUD trinkets poll bind keys for PUSHED")
has(trinketMenu, "HOLD_SAFETY_CAP", "HUD trinket push has a hold safety cap")
has(trinketMenu, 'SetButtonState, widget, "PUSHED", false', "HUD trinket push does not lock PUSHED")
has(trinketMenu, 'button == "RightButton"', "HUD trinkets open flyout on right mouse-down")
if trinketMenu:find('SetOverrideBindingClick(widget, false, key, widgetName, "LeftButton")', 1, true) then
	failures[#failures + 1] = "trinket keybinds must use KeyBind, not LeftButton"
end
has(trinketMenu, "EBS.Action.SetAction", "HUD trinkets SetAction macrotext /use slot")
has(trinketMenu, "EBS.Widget.Create", "HUD trinkets use Widget.Create")
has(trinketMenu, "EBS.Style.Apply", "HUD trinkets use Style.Apply")
if trinketMenu:find("(FLUX_API.majorVersion or 0) >= 10", 1, true) then
	failures[#failures + 1] = "trinket squeeze must not treat Forever 1.x as pre-DF"
end
has(trinketMenu, "FLUX_API.isPostDF", "trinket squeeze uses isPostDF")
has(trinketMenu, "function TM.SyncEquippedFace", "paperdoll item pins Extra paint")
has(trinketMenu, "UpdateLiveFace", "HUD trinkets use Extra live face paint")
has(trinketMenu, "NotifySAO", "HUD trinkets register with SAO")
has(trinketMgr, "FluxActionStrip", "TrinketMenu anchors to the rewrite strip")
has(trinketMgr, "Inv.Register", "TrinketMenu listens on Flux.Inventory")
has(trinketMgr, "ctx.regions.bags", "inventory pulses filter bags/equip")
has(trinketMenu, "adoptHostCast = false", "trinket flyout kids do not steal HUD slot VFX")
has(trinketMenu, 'NoteTrinketPushed(self, "click")', "HUD trinkets paint push on KeyBind click")
has(trinketMgr, "function Manager.UpdateKeybindings", "manager exposes UpdateKeybindings for login flush")
has(trinketMenu, "local function FrameMouseOver", "TrinketMenu hover uses Frame:IsMouseOver")
if trinketMenu:find("MouseIsOver(TM.Frame)", 1, true) then
	failures[#failures + 1] = "TrinketMenu must not call the missing MouseIsOver global"
end
has(ebsHostButtons, "local function FrameMouseOver", "ExtraButtons hover uses Frame:IsMouseOver")
if ebsHostButtons:find("MouseIsOver(", 1, true) then
	failures[#failures + 1] = "ExtraButtons must not call the missing MouseIsOver global"
end
has(ebsHostCategories, "local function FrameMouseOver", "ExtraButtons categories hover uses Frame:IsMouseOver")
if ebsHostCategories:find("MouseIsOver(", 1, true) then
	failures[#failures + 1] = "ExtraButtons categories must not call the missing MouseIsOver global"
end
has(hearthCfg, "local function FrameMouseOver", "hearth config hover uses Frame:IsMouseOver")
if hearthCfg:find("MouseIsOver(", 1, true) then
	failures[#failures + 1] = "hearth config must not call the missing MouseIsOver global"
end
has(trinketMenu, "arrowTint", "TrinketMenu keeps green equipment arrow tint")
has(trinketMenu, 'placePoint = "BOTTOMRIGHT"', "trinket flyout sits above both slots")
if trinketMenu:find('chrome = "border"', 1, true) then
	failures[#failures + 1] = "trinket flyout must use SpellFlyout TGA chrome, not tooltip-border"
end
has(trinketMenu, "n > 18", "trinket flyout grows to a 4-column form")
if trinketMenu:find("FluxFlyoutFrame.ConfigureArrowLayer", 1, true) then
	failures[#failures + 1] = "TrinketMenu must not depend on FluxFlyoutFrame.ConfigureArrowLayer"
end
local flyAttach = readEbs("FlyoutEngine/Attach.lua")
local flyArrow = readEbs("FlyoutEngine/Arrow.lua")
local flyChrome = readEbs("FlyoutEngine/Chrome.lua")
local flyPopup = readEbs("FlyoutEngine/Popup.lua")
local flySecure = readEbs("FlyoutEngine/Secure.lua")
has(flyAttach, "function Flyout.BindHost", "Flyout.BindHost")
has(flyAttach, "function Flyout.SetButtons", "Flyout.SetButtons")
has(flyAttach, "function Flyout.ApplyAppearanceAccent", "Flyout.ApplyAppearanceAccent")
has(flyArrow, "function Arrow.ApplyAccent", "Flyout.Arrow.ApplyAccent")
has(flyArrow, "ARROW_YELLOW_R", "default flyout arrow is yellow")
has(flyArrow, "classColorArrow", "class teleport can request a class-colored arrow")
if flyArrow:find("GetThemedVertexRGB", 1, true) then
	failures[#failures + 1] = "default flyout arrow must not use appearance/class accent"
end
do
	local i = flyArrow:find("function Arrow.Anchor", 1, true)
	local j = flyArrow:find("function Arrow.SetTint", i or 1, true)
	local body = (i and j and flyArrow:sub(i, j - 1)) or ""
	has(body, "Flyout.InLockdown()", "Arrow.Anchor skips SetSize in combat")
end
do
	local i = flyArrow:find("function Arrow.Show", 1, true)
	local j = flyArrow:find("function Arrow.Hide", i or 1, true)
	local body = (i and j and flyArrow:sub(i, j - 1)) or ""
	has(body, "Flyout.InLockdown()", "Arrow.Show skips Show in combat")
	has(body, "flyout.arrow.vis.", "Arrow.Show defers visibility until regen")
end
has(trinketMenu, "trinket.arrow.vis", "trinket arrow vis defers in combat")
has(flyAttach, "favoriteCategory", "SetButtons honors favoriteCategory")
local flyFav = readEbs("FlyoutEngine/Favorites.lua")
has(flyFav, "function Favorites.RegisterButton", "Favorites.RegisterButton")
has(flyFav, "function Favorites.GetFavorite", "Favorites.GetFavorite")
has(flyFav, "function Favorites.ToggleFavorite", "Favorites.ToggleFavorite")
has(flyFav, "function Favorites.GetBestAvailableFavorite", "Favorites.GetBestAvailableFavorite")
has(flyFav, "function Favorites.AppendTooltip", "flyout kids append right-click favorite hints")
has(flyFav, "SameFavoriteId", "Teleport/Portal favorite stars match paired destinations")
has(flyFav, "function Favorites.IsFavoritedAnyMod", "Favorites.IsFavoritedAnyMod")
has(flyFav, "CoerceFavoriteToCategory", "legacy same-ID Teleport/Portal favorites coerce on read")
has(flyPopup, "Favorites.AppendTooltip", "spell flyout tooltips show right-click to favorite")
has(flyPopup, "OnKidRightClick", "popup right-click stars a favorite")
has(flyPopup, "PaintKidStar", "popup paints favorite stars")
has(flyPopup, 'RegisterForClicks("AnyDown", "AnyUp")', "flyout kids register down+up so retail left-click uses")
has(flyPopup, '*type1"', "flyout kids use left-click only secure type")
has(flyPopup, "function AdoptKidCastOnHost", "flyout kid use pins Extra VFX on the host")
has(flyPopup, "_fluxAdoptedByHost", "adopted kids do not keep the fill after the popup hides")
has(flyPopup, "Cast.AdoptFace", "flyout transfers live fill onto the host")
has(flyPopup, "Paint.UpdateGlow", "flyout kids use Extra glow")
has(flyPopup, "Glow.NotifySAO", "flyout kids register with SAO")
has(flyPopup, "NoteTargeting", "flyout kids note Extra reticle on cast")
has(flyPopup, "Overlay.Attach", "flyout kids attach ButtonFX overlay VFX")
has(flyPopup, "Cast.Register", "flyout kids register for spell-cast VFX")
has(flyPopup, "NotePressed", "flyout kids note press so fill/reticle can pick them")
has(flyPopup, "isReagent", "flyout reagent rows skip use and open restock edit")
has(flyPopup, "ToggleRestockEdit", "flyout reagent click toggles restock target box")
has(flyPopup, "Left- or right-click: set restock target", "flyout reagent tooltip restock hint")
has(flySecure, "self:GetAttribute(\"doCloseOnClick\") == false", "reagent kids do not close the flyout")
has(readEbs("FlyoutEngine/Def.lua"), "isReagent", "flyout defs keep isReagent")
has(readEbs("NonCombatGrid/Buttons/TeleportPortal.lua"), "isReagent = isReagent", "class teleport runes are reagent flyout rows")
has(flySecure, "if isDown then", "kid close script waits for mouse up so the use can fire")
local ncGrid = readEbs("NonCombatGrid/Grid.lua")
has(ncGrid, "Widget.Create", "NC grid uses Widget.Create")
has(ncGrid, 'kind = "extra"', "NC grid extra kind")
has(ncGrid, "skipScripts = true", "NC grid skipScripts")
has(ncGrid, "BindLockedExtraHost", "NC grid flyout hosts use Extra press/checked/CD/glow")
has(ncGrid, "ebs.Action.OnEnter", "NC grid tooltip uses Action.OnEnter, not ShowTooltip flag")
has(widgetSrc, "ApplyTooltipScripts", "skipScripts extras still get Lua tooltip OnEnter")
has(widgetSrc, "not config.skipHover", "skipHover can skip Extra tooltip scripts")
has(widgetSrc, "not config.skipMouseover", "skipScripts extras still get mouseover-cast")
has(widgetSrc, "function Widget.AfterClickPaint", "Extra PostClick paint is shared")
has(widgetSrc, "function Widget.BindLockedExtraHost", "locked Extra hosts share press/CD/checked")
has(widgetSrc, "onDown = true", "NC/combat HUD extras use on mouse-down")
has(widgetSrc, 'button == "RightButton"', "locked Extra hosts clear checked on RightButton")
has(widgetSrc, "SuppressCheckedVisualSettle", "RightButton craft RC settles gold after First Aid/Alchemy open")
has(widgetSrc, "Do not AfterClickPaint", "RightButton must not RequestCheckedSettle after craft RC")
if widgetSrc:find("ApplyHighlightHooks", 1, true) then
	failures[#failures + 1] = "Extra hover must be C++ CheckButton, not ApplyHighlightHooks"
end
do
	local i = widgetSrc:find("local function BindChrome", 1, true)
	local j = widgetSrc:find("local function BindParts", 1, true)
	local body = (i and j and widgetSrc:sub(i, j - 1)) or ""
	if not body:find("SpellHighlightTexture:Hide", 1, true) then
		failures[#failures + 1] = "BindChrome must still Hide SpellHighlightTexture"
	end
	if body:find("hl:Hide()", 1, true) then
		failures[#failures + 1] = "BindChrome must not Hide HighlightTexture (C++ mouseover)"
	end
end
if ncGrid:find("FluxButton.New", 1, true) then
	failures[#failures + 1] = "NC Grid must not call FluxButton.New"
end
has(ncGrid, "utility = 4", "NC grid orders utility columns")
has(ncGrid, 'grp = "utility"', "NC grid infers utility slots")
has(ncGrid, 'a.group == "utility" or b.group == "utility"', "NC grid does not merge leftover utility singles")
local ncUtilMgr = readEbs("NonCombatGrid/UtilitySlots/Manager.lua")
local ncUtilAssign = readEbs("NonCombatGrid/UtilitySlots/Assign.lua")
has(ncUtilMgr, "Click.Apply(w)", "utility slots re-apply Extra-window click wrap")
has(ncUtilMgr, '"KeyBind"', "utility slot overrides use KeyBind")
has(ncUtilMgr, "FormatCastAttribute", "utility slots format spell cast names")
has(ncUtilMgr, "MirrorTypeRelease", "utility macros mirror typerelease")
has(ncUtilMgr, "typerelease1", "utility user macros set typerelease1")
has(ncUtilMgr, "FluxBindingMode", "utility slots register Binding Mode")
has(ncUtilMgr, "NotifyActiveChanged", "utility visibility arms modifier preview")
has(ncUtilAssign, "FormatCastAttribute", "utility assign formats spell names")
has(ncUtilAssign, "AssignFromCursor", "utility assign accepts cursor drops")
if ncUtilMgr:find('RegisterForClicks("AnyUp")', 1, true) then
	failures[#failures + 1] = "utility slots must not reset clicks to AnyUp (undoes Extra wrap)"
end
if ncUtilMgr:find('"LeftButton")', 1, true) and ncUtilMgr:find("SetOverrideBindingClick", 1, true) then
	local i = ncUtilMgr:find("function Manager.UpdateBindings", 1, true)
	local body = i and ncUtilMgr:sub(i, i + 800) or ""
	if body:find('"LeftButton"', 1, true) then
		failures[#failures + 1] = "utility slot keybinds must use KeyBind, not LeftButton"
	end
end
if ncUtilMgr:find("FluxButtonCore.FormatSpellCastAttribute", 1, true) then
	failures[#failures + 1] = "utility slots must not call unloaded FluxButtonCore"
end
if ncUtilAssign:find("FluxButtonCore.FormatSpellCastAttribute", 1, true) then
	failures[#failures + 1] = "utility assign must not call unloaded FluxButtonCore"
end
has(ncGrid, "FluxNonCombatAPI.DefaultGrid", "NC appearance accent paints the NC grid")
if ncGrid:find("FluxCombatManager", 1, true) then
	failures[#failures + 1] = "NC Grid must not paint CombatManager for appearance accent"
end
local combatGrid = readEbs("CombatGrid/Grid.lua")
has(combatGrid, "Widget.Create", "CombatGrid uses Widget.Create")
has(combatGrid, 'kind = "extra"', "CombatGrid extra kind")
has(combatGrid, "skipScripts = true", "CombatGrid skipScripts")
has(combatGrid, "BindLockedExtraHost", "CombatGrid Extra press/checked/CD/glow")
has(combatGrid, "ebs.Action.OnEnter", "CombatGrid tooltip uses Action.OnEnter")
has(combatGrid, "_fluxIsPresetGrid", "CombatGrid marks preset hosts")
has(combatGrid, "_fluxCraftBindKey = nil", "CombatGrid placeholder wipes craft bind memo")
if combatGrid:find("FluxButton.New", 1, true) then
	failures[#failures + 1] = "CombatGrid must not call FluxButton.New"
end
local combatAmmo = readEbs("CombatGrid/Buttons/Ammo.lua")
has(combatAmmo, "Flux.Inventory", "ammo counts use Flux.Inventory")
has(combatAmmo, "equipped = true", "ammo counts include equipped thrown/ammo")
has(combatAmmo, "bags = true", "ammo counts include bag/quiver stacks")
has(combatAmmo, "StripSecureItemUse", "ammo is display-only")
has(combatAmmo, "_lastGoodAmmoID", "ammo keeps last item across load screens")
has(combatAmmo, "ShouldHoldItemIdentity()", "ammo load-screen hold uses shared item identity")
local combatManaGem = readEbs("CombatGrid/Buttons/ManaGem.lua")
has(combatManaGem, "SoftHoldOwned", "mana gem holds identity across portal")
has(combatManaGem, "GetPreferredManaGemItemID", "mana gem falls back to last/preferred id")
has(combatManaGem, "latest item, not the generic placeholder", "sticky mana gem keeps the latest item")
has(combatManaGem, "Vanilla paid / no sticky id: placeholder", "vanilla mana gem placeholders when none owned")
has(combatManaGem, "function BindGemFace", "mana gem binds the real item face")
has(combatManaGem, "btn:UpdateUsable()", "mana gem re-tints after writing count 0")
has(combatManaGem, "DisplayItemCount", "mana gem display uses Extra DisplayItemCount")
has(combatManaGem, "preferCopies = true", "mana gem two copies show bag copies not summed uses")
has(combatManaGem, "GemUses", "mana gem still counts remaining uses when copies <= 1")
do
	local i = combatManaGem:find("local function ShouldShow", 1, true)
	local j = i and combatManaGem:find("local function GemUses", i, true)
	local body = (i and j and combatManaGem:sub(i, j - 1)) or ""
	has(body, "KnowsAnyConjureSpell", "mana gem ShouldShow requires a conjure gem spell")
	if body:find("GetOwnedLadder", 1, true) then
		failures[#failures + 1] = "mana gem ShouldShow must not use bag ownership"
	end
	if body:find("SoftHoldOwned", 1, true) then
		failures[#failures + 1] = "mana gem ShouldShow must not use portal hold"
	end
end
has(combatManaGem, '"SPELLS_CHANGED"', "mana gem visibility retranlates when the conjure spell is learned")
local combatHealthstone = readEbs("CombatGrid/Buttons/Healthstone.lua")
has(combatHealthstone, "charges = true", "healthstone Refresh.Attach uses charges")
has(combatHealthstone, "StoneUses", "healthstone counts remaining uses")
has(combatHealthstone, "DisplayItemCount", "healthstone display uses Extra DisplayItemCount")
has(combatHealthstone, "preferCopies = true", "healthstone two copies show bag copies not summed uses")
has(combatHealthstone, 'GetBestOwned("healthstone", { charges = true })', "healthstone best owned uses charges")
has(combatHealthstone, "BagCount(bestID, { charges = true })", "healthstone latch counts remaining charges")
has(combatHealthstone, "_forcedCountLive", "healthstone keeps live charge count")
has(combatHealthstone, "KeepConsumableSlot", "healthstone visibility holds across load screens")
has(combatHealthstone, "ApplyUseAndConjureBindings", "healthstone use+create binds")
has(combatGrid, "_forcedCountLive", "CombatGrid SetCount honors live charge counts")
has(combatGrid, "self._forcedCount = count", "CombatGrid SetCount keeps 0 for Paint")
has(ncGrid, "self._forcedCount = count", "NC Grid SetCount keeps 0 for Paint")
local ncTeleport = readEbs("NonCombatGrid/Buttons/TeleportPortal.lua")
has(ncTeleport, "SafeAccessibleString", "teleport reagent tooltip skips secret strings")
has(ncTeleport, "RUNE_OF_TELEPORTATION", "teleport falls back to known rune item IDs")
has(ncTeleport, "_lastGoodTeleportSpells", "class teleport keeps last spells across load screens")
has(ncTeleport, "Module._fluxSeenPew", "class teleport login reset is not every load screen")
local ncConsumables = readEbs("NonCombatGrid/Buttons/Consumables.lua")
has(ncConsumables, "PlayerHelpfulAura", "consumables aura scan uses Flux.Aura")
has(ncConsumables, "ShouldHoldItemIdentity()", "consumables keep last item across load screens")
has(ncConsumables, "Module._fluxSeenPew", "consumables login refresh is not every load screen")
if ncConsumables:find('C_UnitAuras.GetAuraDataByIndex("player"', 1, true) then
	failures[#failures + 1] = "consumables must not call GetAuraDataByIndex directly"
end
local stanceExtras = read("Stance/Extras.lua")
has(stanceExtras, "AurasRestricted", "stance extras skip aura name-scan when secrets are blocked")
has(stanceExtras, "GetPlayerAuraBySpellID", "stance extras prefer known-spell aura lookup")
has(stanceExtras, "GetCooldownAuraBySpellID", "stance extras map cast id to cooldown aura")
do
	local i = stanceExtras:find("local function AuraFromSpellId", 1, true)
	local j = stanceExtras:find("local function ArmorNameMatch", i or 1, true)
	local body = (i and j and stanceExtras:sub(i, j - 1)) or ""
	if body:find("CanAccessSecrets", 1, true) then
		failures[#failures + 1] = "stance AuraFromSpellId must not gate on CanAccessSecrets"
	end
end
do
	local i = stanceExtras:find("local function AuraFromHelpfulScan", 1, true)
	local j = stanceExtras:find("local function NormalizeArmor", i or 1, true)
	local body = (i and j and stanceExtras:sub(i, j - 1)) or ""
	if not body:find("AurasRestricted", 1, true) then
		failures[#failures + 1] = "stance aura name-scan must still gate on AurasRestricted"
	end
	if body:find("CanAccessSecrets", 1, true) then
		failures[#failures + 1] = "stance aura name-scan must not use CanAccessSecrets (tainted combat default)"
	end
end
local bindSrc = readEbs("Engine/ConsumableBind.lua")
has(bindSrc, "function Bridge.KnowsManaGemConjureSpell", "mana gem visibility is spell-known, not bag-owned")
has(bindSrc, "function Bridge.KeepConsumableSlot", "grid slots keep identity while bags flicker empty")
has(bindSrc, "function Bridge.ShouldHoldItemIdentity", "extra buttons share one load-screen item hold")
has(bindSrc, "HoldLatchedDisplay()", "consumable bind does not placeholder on collapsed bags")
has(bindSrc, "Still own the latched stack", "consumable bind keeps bag food after combat")
has(bindSrc, "Leaving combat: food/water IsUsableItem", "consumable bind drops combat usable cache on regen")
has(bindSrc, "local n = BagCount(id, true)", "healthstone tier walk uses charges")
has(bindSrc, "if fromBest and not opts.needLadder and SoftHolding()", "GetBestOwned freezes all kinds on portal")
has(bindSrc, "Charge APIs return 0 on zone load", "BagCount does not let live 0 hide gem stacks")
has(bindSrc, "function Bridge.DisplayItemCount", "ConsumableBind DisplayItemCount")
has(bindSrc, "if uses > copies then", "ConsumableBind charged copies show remaining uses")
has(bindSrc, "preferCopies", "ConsumableBind gem/HS display can prefer bag copies")
has(bindSrc, "keep live tracking at 0 so Paint does not blank the digit", "consumable bind live-tracks 0")
has(bindSrc, "if SoftHolding() then", "Refresh BagsReliable uses portal hold first")
if bindSrc:find("kind ~= \"managem\" and kind ~= \"healthstone\" and not allowComboDrinks then\n        local inv = Inv()\n        local reliable = true") then
	failures[#failures + 1] = "GetBestOwned must not skip mana gem/healthstone during portal hold"
end
has(bindSrc, "function Bridge.GetOwnedLadder", "ConsumableBind GetOwnedLadder")
has(bindSrc, "local function FilterLiveOwned", "owned ladders drop 0-count items")
has(bindSrc, "walk the owned ladder so another item of this kind can take the slot", "empty tracked item promotes the next owned")
has(bindSrc, "Vanilla mana gems are single-use", "vanilla jade/agate bag copies count as owned uses")
has(bindSrc, "Reliable: live 0 is last charge", "BagCount treats leftover 0-charge gems as empty")
has(bindSrc, "Reliable empty must not fabricate a count-1 leftover", "mana gem ladder does not keep empty gems")
has(bindSrc, "function Bridge.PromoteIfBetter", "ConsumableBind PromoteIfBetter")
has(bindSrc, "function Bridge.ApplyRightClickSpell", "ConsumableBind ApplyRightClickSpell")
has(bindSrc, 'SetClickType(w, "type2"', "right-click conjure sets typerelease2")
has(bindSrc, '"ConjureBind"', "conjure keys click as ConjureBind")
has(bindSrc, "OverrideClickButtons", "Forever consumable keys use real mouse buttons")
has(bindSrc, 'return "LeftButton", "RightButton"', "no-wrap consumable keys click Left/Right")
has(bindSrc, "function Bridge.DeleteOneConjuredOwned", "ConsumableBind DeleteOneConjuredOwned")
has(bindSrc, '"KeyBind"', "ConsumableBind KeyBind overrides")
has(bindSrc, "_fluxTooltipExtras", "ConsumableBind tooltip extras survive SetAction")
has(bindSrc, "_fluxIsolatedTooltip = true", "consumable extras isolate tooltips from other addons")
local tooltipGuard = readEbs("Shared/FluxTooltipGuard.lua")
has(tooltipGuard, "function Guard.FillBlizzardItem", "TooltipGuard fills Blizzard item lines")
has(tooltipGuard, "function Guard.FillBlizzardSpell", "TooltipGuard fills Recuperate without GameTooltip")
has(tooltipGuard, "C_TooltipInfo.GetItemByID", "retail item fill skips TooltipDataProcessor")
has(bindSrc, "local function CraftApi()", "ConsumableBind Craft prefers Flux.Inventory")
has(bindSrc, "function Bridge.GetBestCraftable", "ConsumableBind GetBestCraftable")
has(bindSrc, "function Bridge.ApplyCraftOrRestockRightClick", "ConsumableBind craft RC")
has(bindSrc, "BindHardwareCraftClick", "craft RC binds hardware click on the HUD widget")
has(bindSrc, 'HookScript("OnMouseDown"', "craft RC OnMouseDown is hardware (not /click)")
has(bindSrc, 'HookScript("PostClick"', "craft RC PostClick retries after opening the profession")
has(bindSrc, "_fluxHardwareCraftKind", "craft kind lives on the HUD widget")
if bindSrc:find("craft:open:", 1, true) then
	failures[#failures + 1] = "craft RC must not bind craft:open when the top recipe is unaffordable"
end
has(bindSrc, "function Bridge.SuppressCheckedVisual", "ConsumableBind SuppressCheckedVisual")
has(bindSrc, "function Bridge.SuppressCheckedVisualSettle", "craft RC re-clears gold after tradeskill open")
has(bindSrc, "_fluxSuppressCraftCheckedUntil", "craft RC guards C++ checked texture OnShow")
has(bindSrc, "TRADE_SKILL_SHOW", "opening First Aid/Alchemy re-clears combat craft gold")
has(bindSrc, "GetTime() + 1.5", "craft RC suppress lasts through profession open")
has(bindSrc, "keepButtonState", "craft RC mouse-up must not SetButtonState NORMAL")
if bindSrc:find("function BindHardwareCraftClick", 1, true) then
	local i = bindSrc:find("function BindHardwareCraftClick", 1, true)
	local j = bindSrc:find("\nfunction Bridge.", i + 10, true)
	local chunk = (i and j and bindSrc:sub(i, j)) or ""
	if not chunk:find('HookScript("OnMouseUp"', 1, true) then
		failures[#failures + 1] = "hardware craft must clear checked on RightButton mouse-up"
	end
	if not chunk:find("keepButtonState", 1, true) then
		failures[#failures + 1] = "hardware craft mouse-up must keep button state so the up-click is not killed"
	end
end
has(bindSrc, "_fluxCheckedFromPaint", "SuppressCheckedVisual clears Extra gold checked")
has(bindSrc, "_fluxBindMemo", "consumable binds skip ClearOverrideBindings when identity matches")
has(bindSrc, 'sp.HasCreateKind("managem")', "mana-gem known-check uses CreateSpells cache")
if bindSrc:find("RefreshConjureSharedBindingName()", 1, true) then
	failures[#failures + 1] = "ApplyUseAndConjureBindings must not refresh Key Bindings labels per button"
end
local ncFood = readEbs("NonCombatGrid/Buttons/Food.lua")
has(ncFood, "ApplyUseAndConjureBindings", "food use+conjure binds")
has(ncFood, "FLUXMAGE_CONJURE_FOOD", "food conjure binding name")
has(ncFood, "typerelease2", "food clears typerelease2 with type2")
has(ncFood, "btn._lastUsable = nil", "Recuperate bind does not keep leftover food unusable tint")
has(ncFood, "wasPrefer ~= true", "Recuperate must not Update water on every food refresh")
local ncWater = readEbs("NonCombatGrid/Buttons/Water.lua")
has(ncWater, "ApplyUseAndConjureBindings", "water use+conjure binds")
has(ncWater, "FLUXMAGE_CONJURE_WATER", "water conjure binding name")
has(combatManaGem, "ApplyUseAndConjureBindings", "mana gem use+conjure binds")
has(combatManaGem, "FLUXMAGE_CONJURE_MANAGEM", "mana gem conjure binding name")
has(combatHealthstone, "ApplyUseAndConjureBindings", "healthstone use+create binds")
has(combatHealthstone, "FLUXMAGE_CONJURE_MANAGEM", "healthstone shares gem create binding")
do
	local hotkeyUtil = readEbs("Shared/HotkeyUtil.lua")
	local i = hotkeyUtil:find("function HotkeyUtil.RefreshAfterBindingChange", 1, true)
	local j = i and hotkeyUtil:find("function HotkeyUtil.FlushAfterBulkBindings", i, true)
	local body = (i and j and hotkeyUtil:sub(i, j - 1)) or ""
	has(body, "FluxCombatManaGem", "light bind refresh rebinds combat gem")
	has(body, "FluxCombatHealthstone", "light bind refresh rebinds healthstone")
end
local ebsActionSrc = readEbs("Engine/Action.lua")
has(ebsActionSrc, "AppendTooltipExtras", "Action.OnEnter appends consumable tooltip extras")
has(ebsActionSrc, "UpdateIsolatedTooltip", "isolated consumables skip GameTooltip inject")
has(ebsActionSrc, "FillBlizzardItem", "isolated item body is Blizzard-only")
has(ebsActionSrc, "C++ CheckButton owns HighlightTexture", "Action.OnEnter is tooltip-only")
has(ebsActionSrc, "Empty food/water/hearth extras", "placeholder extras keep a tooltip title")
has(ebsActionSrc, "Extra Paint keeps empty-slot gray", "SetAction clears placeholder gray")
if bindSrc:find("Bridge.Attach = Refresh.Attach", 1, true) then
	failures[#failures + 1] = "ConsumableBind must not assign Attach on the Refresh Bridge() getter"
end
has(bindSrc, 'type(Bind) == "table"', "ConsumableBind Attach stays on the Bridge table")
has(ncGrid, "function btn:OnEnter()", "NC grid FluxButton OnEnter mixin")
has(ncGrid, "function btn:OnLeave()", "NC grid FluxButton OnLeave mixin")
has(ncGrid, "function btn:FullRefresh()", "NC grid FullRefresh → Paint.Update")
local ncMount = readEbs("NonCombatGrid/Buttons/Mount.lua")
if ncMount:find("FluxSafeRegisterEvent(eventFrame", 1, true) then
	failures[#failures + 1] = "Mount.lua must not call FluxSafeRegisterEvent (Legacy API is unused)"
end
has(ncMount, "Events.SafeRegister", "Mount zone events use Flux.Events.SafeRegister")
has(ncMount, "PinMountExtraFace", "mount host pins Extra face before paint")
has(ncMount, "PaintMountLiveFace", "mount host uses Extra live face paint")
has(ncMount, "_iconManagedByModule = false", "mount placeholder leaves icon protection off")
has(ncMount, "HasAnyMountInBags()", "mount button stays an item while bags still have mounts")
has(ncMount, "ShouldHoldMountIdentity()", "mount load screens keep last bag-item macro")
has(ncMount, "Module._fluxSeenPew", "mount login reset is not every load screen")
local ncMountItems = readEbs("NonCombatGrid/Buttons/MountItems.lua")
has(ncMountItems, "tonumber((select(8, GetInstanceInfo())))", "MountItems tonumber takes only instanceID")
has(ncMountItems, "Flux.Inventory.Flyable", "MountItems uses Inventory.Flyable for bag-item flyable")
has(ncMountItems, "PreferFlying", "MountItems PreferFlying when [flyable] is missing")
has(ncMountItems, "Items.GetBagMountItems(true)", "MountItems falls back to unfiltered bag items in instances")
has(ncMount, "GetMountFlyable", "Mount.lua settle uses Inventory.Flyable")
do
	local i = ncMount:find("function Module.BuildBagMountMacro", 1, true)
	local j = i and ncMount:find("\nfunction Module.", i + 10, true)
	local bagMacro = (i and j and ncMount:sub(i, j)) or ""
	if bagMacro:find("[nomod,flyable]", 1, true) or bagMacro:find("[flyable]", 1, true) then
		failures[#failures + 1] = "BuildBagMountMacro must not bake [flyable] (item IDs; Lua picks flying vs ground)"
	end
end
local ncHearth = readEbs("NonCombatGrid/Buttons/Hearthstone.lua")
has(ncHearth, "if btn.OnEnter then", "Hearthstone restores tooltip without assuming FluxButton:OnEnter")
has(ncHearth, "Paint.UpdateLiveFace", "hearth/teleport-item host uses Extra live face paint")
has(ncHearth, "PlayerHasItemInInventory = PlayerHasItemInInventory", "teleport scan stub can see bag hearthstones")
has(ncHearth, "[6948] = true", "scan matches default hearthstone by item id")
has(ncHearth, "droppedHearth", "stripped bag hearthstone is reinserted if config miss")
has(ncHearth, "btn:ClearPlaceholder()", "classic hearth clears placeholder gray when the stone returns")
has(ncHearth, "ShouldHoldItemIdentity()", "hearth keeps last item across load screens")
has(ncHearth, "_lastGoodTeleportItems", "hearth teleport scan does not drop to empty on load")
has(ncHearth, "_lastGoodHearthItemId", "classic hearth keeps last stone while bags flicker")
has(ncHearth, "api.GetLiveCount", "hearth bag count uses live bags, not a stale snapshot")
local ncTeleport = readEbs("NonCombatGrid/Buttons/TeleportPortal.lua")
has(ncTeleport, "function Module.SyncFlyoutEngine()", "class teleport fills FlyoutEngine buttons")
has(ncTeleport, "classColorArrow = true", "class teleport flyout arrow is class colored")
has(ncTeleport, "function Module.SetupClickHandlers", "class teleport mouse handlers")
has(ncTeleport, "MACRO_TELEPORT_TOGGLE_MODE", "class teleport middle-click /clicks the toggle proxy")
has(ncTeleport, 'SetAttribute("typerelease3", "macro")', "class teleport middle-up uses typerelease3")
has(ncTeleport, 'button == "MiddleButton"', "class teleport middle-click toggles on mouse-down")
local proxySrc = readEbs("Shared/FluxMacroClickProxies.lua")
has(proxySrc, "Flux.Inventory", "craft proxies prefer Flux.Inventory.Craft")
has(proxySrc, "ExecuteHealPotionCraft", "heal potion craft proxy")
has(proxySrc, "ExecuteManaPotionCraft", "mana potion craft proxy")
has(proxySrc, "ExecuteBandageCraft", "bandage craft proxy")
has(proxySrc, "LeftButton 1", "craft /click backup fires mouse-down")
has(proxySrc, "LeftButton 0", "craft /click backup fires mouse-up")
has(proxySrc, "b:Show()", "craft /click proxies stay shown off-screen")
has(proxySrc, "SuppressCombatCraftChecked", "craft proxies clear combat-grid gold checked")
has(proxySrc, "FluxCombatBandage", "bandage craft proxy clears bandage checked")
do
	local function craftProxyOnClick(name, nextName)
		local i = proxySrc:find('makeClickProxy("' .. name .. '"', 1, true)
		local j = nextName and proxySrc:find('makeClickProxy("' .. nextName .. '"', 1, true)
		if i and j then
			return proxySrc:sub(i, j)
		end
		return i and proxySrc:sub(i, i + 450) or ""
	end
	local pairs_ = {
		{ "FluxMacroProxy_CraftBandage", "FluxMacroProxy_CraftHealPotion" },
		{ "FluxMacroProxy_CraftHealPotion", "FluxMacroProxy_CraftManaPotion" },
		{ "FluxMacroProxy_CraftManaPotion", "FluxMacroProxy_ConsumablesConfig" },
	}
	for _, names in ipairs(pairs_) do
		local chunk = craftProxyOnClick(names[1], names[2])
		if chunk:find("if down == false then", 1, true) then
			failures[#failures + 1] = names[1] .. " must not ignore mouse-up (HUD /click often arrives as down == false)"
		end
	end
end
has(proxySrc, "FluxMacroProxy_TeleportToggleMode", "teleport toggle click proxy exists")
if proxySrc:find("FluxMacroProxy_TeleportToggleMode", 1, true) then
	local _, after = proxySrc:find("FluxMacroProxy_TeleportToggleMode", 1, true)
	local chunk = after and proxySrc:sub(after, after + 400) or ""
	if chunk:find("if down == false", 1, true) or chunk:find("if down == false then", 1, true) then
		failures[#failures + 1] = "teleport toggle proxy must not ignore mouse-up / keybind up clicks"
	end
end
has(ncTeleport, "function Module.ClearCheckedVisual", "class teleport clears CheckButton gold after toggle")
has(ncTeleport, "Keep Extra SpellCastAnimFrame", "class teleport lock does not hide cast fill")
if ncTeleport:find("function Module.UpdateLockedState", 1, true) then
	local i = ncTeleport:find("function Module.UpdateLockedState", 1, true)
	local j = ncTeleport:find("function Module.", i + 10, true)
	local body = i and j and ncTeleport:sub(i, j) or ""
	if body:find("ForceClearButtonCastVFX", 1, true) then
		failures[#failures + 1] = "UpdateLockedState must not Hide SpellCastAnimFrame (kills cast fill)"
	end
end
has(ncTeleport, "Paint.UpdateLiveFace", "class teleport host uses Extra live face paint")
has(ncTeleport, "IconOverrideTexture", "class teleport pins Extra icon override on mode swap")
has(ncTeleport, "_fluxManagedFaceSpellId", "class teleport pins Extra SpellId on mode swap")
has(ncTeleport, "_portalCacheTime", "class teleport portal spell cache is independent")
has(ncTeleport, "Module.InvalidateCache()", "class teleport invalidates spell cache on toggle")
local favSrc = readEbs("FlyoutEngine/Favorites.lua")
has(favSrc, 'partner = (category == "Teleport") and "Portal" or "Teleport"', "favorites pair teleport/portal on read")
has(ebsActionSrc, "_fluxManagedFaceSpellId", "TranslateMacro keeps class-teleport pinned face")
do
	local paintSrc = readEbs("Engine/Paint.lua")
	has(paintSrc, "override ~= nil and override ~= \"\"", "Paint icon override accepts file ids")
end
has(ncTeleport, "Flyout.SetButtons", "class teleport SetButtons on the engine")
has(ncTeleport, "Flyout.Toggle", "class teleport Toggle on the engine")
if ncTeleport:find("MACRO_TELEPORT_SHOW_FLYOUT", 1, true) then
	failures[#failures + 1] = "class teleport flyout must not depend on unloaded /click proxy macros"
end
local ebsActionProto = readEbs("Engine/Action.lua")
has(ebsActionProto, "function FluxButton:OnEnter()", "rewrite FluxButton has OnEnter")
has(ebsActionProto, "function FluxButton:OnLeave()", "rewrite FluxButton has OnLeave")
has(ebsActionProto, "function FluxButton:FullRefresh()", "rewrite FluxButton has FullRefresh")
local invDir = dir .. "/../Inventory"
local function readInv(rel)
	local f = io.open(invDir .. "/" .. rel, "r")
	if not f then
		return ""
	end
	local s = f:read("*a")
	f:close()
	return s
end
local invIndex = readInv("Index.lua")
has(invIndex, "function Index.GetUniqueItems", "Inventory GetUniqueItems")
has(invIndex, "local bank = opts.bank == true", "GetCount/GetLiveCount default bags-only")
has(invIndex, "Inv.IsReliable and not Inv.IsReliable()", "live counts skip GetItemCount while bags flicker")
has(invIndex, "if snap > 0 then", "live 0 does not hide snapshot stacks")
local invClassify = readInv("FluxConsumableClassify.lua")
has(invClassify, "function C.IsManaGemItem", "classify known mana gem ids")
has(invClassify, "function C.IsCombatUtilityPotion", "classify rejects combat-utility potions")
has(invClassify, "function C.IsHealingPotionName", "classify healing potion name helper")
has(invClassify, "function C.IsManaPotionName", "classify mana potion name helper")
has(invClassify, '"holy protection"', "classify denies Holy Protection Potion by name")
has(invClassify, "[6051] = true", "classify denies Holy Protection Potion by item ID")
has(invClassify, '"potion of mysterious"', "classify denies Mysterious Fortune potions")
has(invClassify, '"maximum health by"', "classify denies max-health buff potions")
has(invClassify, "PotionHasRestoreVerb", "potion tooltip heal/mana requires restores")
has(invClassify, "LineLooksLikeMaxHealthBuff", "percent parse skips max-health buff lines")
has(invClassify, "must not default to healPotion", "unmatched potions do not default to healPotion")
has(invClassify, "Absorb \"N to N", "bandage damage parse is bandage-only")
if invClassify:find("Potions: accept any positive restore", 1, true) then
	failures[#failures + 1] = "classify must not default unmatched potions to healPotion"
end
local invInit = readInv("Init.lua")
has(invInit, "function Inv.MarkUnreliable", "Inventory MarkUnreliable")
has(invInit, "function Inv.IsReliable", "Inventory IsReliable")
has(invInit, "function Inv.NoteRefreshSettling", "Inventory NoteRefreshSettling")
has(invInit, "function Inv.SnapshotLooksCollapsed", "Inventory SnapshotLooksCollapsed")
has(invInit, "PLAYER_LEAVING_WORLD", "Inventory arms hold before load-screen bag flicker")
has(invInit, "BeginLoadHold", "Inventory load hold starts on leaving world")
local invBestInit = readInv("FluxConsumableBest/Init.lua")
has(invBestInit, "Portal grace first", "soft-hold timer is not skipped by stub IsReliable")
has(invBestInit, "function Best.BeginLoadHold", "Best freezes owned identity when the load screen starts")
has(invBestInit, "SnapshotLooksCollapsed", "soft-hold stays on while bags look emptied by a load screen")
local invLegacy = readInv("LegacyBridge.lua")
has(invLegacy, "api.IsReliable", "FluxInv.Bags.IsReliable delegates to Inventory")
if invLegacy:find("IsReliable = function()\r\n\t\treturn true") or invLegacy:find("IsReliable = function()\n\t\treturn true") then
	failures[#failures + 1] = "FluxInv.Bags.IsReliable must not stub true"
end
local ncConsumables = readEbs("NonCombatGrid/Buttons/Consumables.lua")
has(ncConsumables, "includeBank = false", "consumable extra count is bags-only")
has(ncConsumables, "bank = false", "consumable extra ignores bank stacks")
if ncConsumables:find('RegisterForClicks("AnyUp")', 1, true) then
	failures[#failures + 1] = "NC consumable extra must not reset clicks to AnyUp"
end
local invScan = readInv("FluxConsumableBest/Scan.lua")
has(invScan, "GetUniqueItems", "Scan walks GetUniqueItems")
has(invScan, "Mana gem: hard-coded IDs", "scan keeps mana gem without tooltip mana")
has(invScan, "if count <= 0 then", "scan does not publish 0-count owned candidates")
has(invScan, "never situational IsUsableItem", "scan keeps combat-unusable food/water as owned")
has(invScan, "never keep a consumed", "scan pending drain drops empty owned best")
if invScan:find("FluxInv.Bags.GetUniqueItems", 1, true) then
	failures[#failures + 1] = "Scan must not call FluxInv.Bags.GetUniqueItems"
end
local invBest = readInv("FluxConsumableBest/FluxConsumableBest.lua")
local invScore = readInv("FluxConsumableBest/Score.lua")
has(invScore, "false in combat for food/water", "IsBlockedForBest ignores combat IsUsableItem")
has(invScore, "IsCombatUtilityPotion", "IsBlockedForBest rejects combat-utility potions")
has(invScore, "API is situational. Do not cache", "IsUsable does not cache combat false")
do
	local i = invScore:find("function Score.IsBlockedForBest", 1, true)
	local j = i and invScore:find("\nfunction Score.", i + 10, true)
	local body = (i and j and invScore:sub(i, j)) or ""
	if body:find("Score.IsUsable(", 1, true) then
		failures[#failures + 1] = "IsBlockedForBest must not use IsUsable (combat food/water placeholder)"
	end
end
has(invBest, "PLAYER_REGEN_ENABLED", "Best invalidates usable cache after combat")
has(invScore, "conjured always beats combo", "food/water conjured beats combo and vendor")
has(invScore, "4 = conjured pure", "FoodTier ranks conjured-pure first")
has(invScore, "4 = conjured water", "WaterDrinkTier ranks conjured water first")
if invScore:find("combo conjured > conjured", 1, true) then
	failures[#failures + 1] = "food score must not rank conjured combo above conjured food"
end
if invScore:find("higher heal → food tier", 1, true) then
	failures[#failures + 1] = "food score must apply conjured tier before heal amount"
end
has(invBest, "function Best.GetLadder", "Best.GetLadder")
has(invBest, "api.GetCount", "Best.GetLadder drops items bags no longer own")
has(invBest, "function Best.GetBestOwned", "Best.GetBestOwned")
has(invBest, "api.Find", "FindStacks uses Inventory.Find")
local invPersist = readInv("FluxConsumableBest/Persist.lua")
has(invPersist, "count = tonumber(candidate.count)", "persist bag count")
has(invPersist, "Score.IsBlockedForBest", "persist refs scrub blocked combat pots")
local ebsBind = readEbs("Engine/ConsumableBind.lua")
has(ebsBind, "Never keep a latched utility potion", "heal latch drops protection pots")
local createSpells = readInv("CreateSpells.lua")
has(createSpells, "GetPreferredFoodConjureSpell", "CreateSpells food conjure")
has(createSpells, "GetPreferredWaterConjureSpell", "CreateSpells water conjure")
has(createSpells, "Ritual of Refreshment", "CreateSpells ritual")
has(createSpells, "create.*healthstone", "CreateSpells healthstone")
has(createSpells, "^conjure mana gem", "CreateSpells mana gem")
has(createSpells, 'kind = "managem"', "CreateSpells managem kind")
has(createSpells, "knownByLowerName", "CreateSpells name index")
has(createSpells, 'SpellBook.OnChanged("inventory.createspells"', "CreateSpells invalidates on book-shape change")
local spellReagents = readInv("SpellReagents.lua")
has(spellReagents, "if scanned then", "SpellReagents rebuilds reagents only after a real scan")
if spellReagents:find('RegisterEvent("SPELLS_CHANGED")', 1, true) then
	failures[#failures + 1] = "SpellReagents must not listen to raw SPELLS_CHANGED"
end
local invCraft = readInv("Craft.lua")
has(invCraft, "function Craft.GetBestCraftable", "Craft GetBestCraftable")
has(invCraft, "Never falls back to a worse recipe", "Craft only crafts the top scanned recipe")
do
	local i = invCraft:find("function Craft.GetBestCraftable", 1, true)
	local j = i and invCraft:find("function Craft.CanCraftKind", i + 10, true)
	local body = (i and j and invCraft:sub(i, j)) or ""
	if not body:find("local top = list[1]", 1, true) then
		failures[#failures + 1] = "GetBestCraftable must only consider the top scanned recipe"
	end
	if body:find("for i = 1, #list do", 1, true) then
		failures[#failures + 1] = "GetBestCraftable must not walk down to a worse recipe"
	end
end
has(invCraft, "function Craft.HasProfessionForKind", "Craft HasProfessionForKind")
has(invCraft, "FillReagentsFromStatic", "Craft static ladders only fill scanned reagent IDs")
if invCraft:find("AppendStaticRecipes", 1, true) then
	failures[#failures + 1] = "Craft must not mix static ladders into the known-recipe list"
end
has(invCraft, "same click", "Craft retries DoTradeSkill in the click after opening")
has(invCraft, "CRAFT_CLICK_LOCK_SEC", "Craft one recipe per click lock")
has(invCraft, "lastCraftKind ~= kind", "Craft lock blocks a different kind in the same press")
has(invCraft, "lastCraftSucceeded", "Craft lock allows same-kind retry after a failed dispatch")
has(invCraft, "lastCraftAt = now", "Craft lock is set only when a recipe is dispatched")
do
	local i = invCraft:find("function Craft.TryFlushPendingCraft", 1, true)
	local j = i and invCraft:find("\nfunction Craft.", i + 10, true)
	local flush = (i and j and invCraft:sub(i, j)) or ""
	if flush:find("DoTradeSkill", 1, true) or flush:find("CraftRecipe", 1, true) then
		failures[#failures + 1] = "TryFlushPendingCraft must not craft from TRADE_SKILL events"
	end
end
has(invCraft, "function Craft.ExecuteHealPotionCraft", "Craft ExecuteHealPotionCraft")
has(invCraft, "function Craft.ExecuteManaPotionCraft", "Craft ExecuteManaPotionCraft")
has(invCraft, "function Craft.ExecuteBandageCraft", "Craft ExecuteBandageCraft")
has(invCraft, "healing potions live on First Aid", "Forever heal potion RC crafts First Aid recipes")
has(invCraft, "local function HealPotionsUseFirstAid", "Forever heal potions detect camelot First Aid")
has(invCraft, "kind == \"healPotion\" and HealPotionsUseFirstAid()", "heal potion RC opens First Aid on Forever")
has(invCraft, "local function UsesFirstAidProfession", "Forever keeps First Aid despite isPostDF")
has(invCraft, "GetProfessionSkillLineID", "Forever First Aid skill line comes from Enum.Profession")
has(invCraft, "GetFilteredRecipeIDs can run", "Forever RC opens the skill line to scan learned recipes")
has(invCraft, "Inv.GetCount", "Craft bag counts use Flux.Inventory")
if invCraft:find("_G.FluxInv = Inv", 1, true) then
	failures[#failures + 1] = "Craft must not replace the FluxInv facade"
end
local invProf = readInv("Professions.lua")
has(invProf, "Inv.Notify({ professions = true })", "Professions pulse Extra listeners")
has(invProf, "function Prof.ScheduleLoginScan", "Professions login scan")
has(invProf, "TRADE_SKILL_SHOW", "Professions scan when the profession UI opens")
has(invProf, "GetSkillLineInfo", "Professions Classic skill pane fallback")
has(invProf, "function Prof.HasProfessionName", "Professions HasProfessionName")
has(invProf, "function Prof.GetProfessionRank", "Professions GetProfessionRank")
has(invProf, "function Prof.GetItemSkillRequirement", "Professions GetItemSkillRequirement")
has(invProf, "function Prof.InvalidateSkillCaches", "Professions skill-rank cache wipe")
has(invProf, "SKILL_LINES_CHANGED", "Professions wipes rank cache on SKILL_LINES_CHANGED")
has(invProf, "function Prof.GetSkillRequirementFromTooltip", "Professions live tooltip skill requirement")
has(invProf, "C_SkillInfo.GetSkillLineInfo", "Forever skill ranks use C_SkillInfo")
has(invProf, "GetFilteredRecipeIDs", "Forever scans recipes with GetFilteredRecipeIDs")
has(invProf, "function Prof.GetOpenProfessionInfo", "Forever profession info uses child/base")
has(invProf, "GetChildProfessionInfo", "Forever GetChildProfessionInfo")
has(invProf, "GetProfessionSpells", "Forever merges GetProfessionSpells into the recipe list")
has(invProf, "IsDataSourceChanging", "Forever waits until profession data is ready")
has(invProf, "indices = { GetProfessions() }", "Forever GetProfessions first-aid slot is not live archaeology")
if invProf:find("_G.FluxInv = Inv", 1, true) then
	failures[#failures + 1] = "Professions must not replace the FluxInv facade"
end
local mountFlyable = readInv("MountFlyable.lua")
has(mountFlyable, "function Flyable.CanPreferFlyingMountItem", "MountFlyable CanPreferFlyingMountItem")
has(mountFlyable, "tonumber((select(8, GetInstanceInfo())))", "MountFlyable tonumber takes only instanceID")
has(mountFlyable, "function Flyable.HasFlyableMacroCondition", "MountFlyable detects missing [flyable]")
has(mountFlyable, "function Flyable.IsOutlandContinent", "MountFlyable Outland continent fallback")
has(mountFlyable, "PlayerHasFlyingSkill", "MountFlyable requires Expert Riding when IsFlyableArea is missing")
if mountFlyable:find("return flyableNow and true or false", 1, true) then
	failures[#failures + 1] = "MountFlyable must not require IsFlyableArea on TBC bag-item clients"
end
has(flyArrow, "function Arrow.ConfigureLayer", "Arrow.ConfigureLayer")
has(flyArrow, "FluxUnifiedBorderFrame", "arrow parents onto the unified border")
has(flyChrome, "ActionBarFlyoutButton", "owned TGA flyout cap")
has(flyChrome, "UI-Tooltip-Border", "backdrop fallback if flyout TGA is missing")
has(flyChrome, "GetThemedVertexRGB", "flyout chrome uses appearance accent")
has(flyChrome, "GetAccentColor", "TGA flyout tints from class/custom accent")
has(flyChrome, "KID_REF = 28", "TGA tube scales from CustomFlyout 28px kids")
has(flyChrome, "SetWidth(tubeW)", "TGA vert mid keeps native 37/28 aspect")
if flyChrome:find("ChromeFill", 1, true) then
	failures[#failures + 1] = "flyout chrome must not use a WHITE8x8 fill (CustomFlyout TGA only)"
end
if flyChrome:find('_fluxFlyoutChromeMode == "border"', 1, true) then
	failures[#failures + 1] = "wide flyouts must keep SpellFlyout TGA, not tooltip-border"
end
if flyChrome:find("FluxBorder:ApplyTo", 1, true) then
	failures[#failures + 1] = "flyout chrome must not FluxBorder.ApplyTo (BACKGROUND fill sits under chat)"
end
has(flyPopup, "SetItemByID", "flyout tooltip uses SetItemByID, not a raw name hyperlink")
has(flyPopup, "SetFrameLevel(5500)", "flyout popup sits above chat/micromenu")
has(flyPopup, "ApplySlotRing", "flyout kids keep a themed ring")
if flyPopup:find("KidHighlight", 1, true) then
	failures[#failures + 1] = "flyout kids must not Lua Show/Hide HighlightTexture"
end
has(flyPopup, "PAD = 6", "flyout long-axis pad")
has(flyPopup, "CELL = 40", "NC flyout cells are a bit smaller than the 44px host")
has(flyPopup, "_fluxFlyoutCell", "popup stores cell size for chrome scale")
has(flyPopup, "hang outside and wrap the rings", "cross-axis hugs cells so TGA wraps rings")
has(flyPopup, "matchAnchorScale ~= false", "flyout scale matches the host by default")
has(flyPopup, "opts.anchorFrame", "flyout Place can pin to an anchor frame")
has(flySecure, "flyoutPlacePoint", "opener honors custom place points")
has(widgetSrc, "function widget:UpdateFlyout()", "Extra widgets own native SpellFlyout chrome")
has(widgetSrc, "LayerNativeFlyoutArrow", "native Extra flyout arrows sit above the slot ring")
has(widgetSrc, "NATIVE_ARROW_DRAW", "native Extra flyout arrows use button OVERLAY, not UIParent")
if widgetSrc:find("ConfigureLayer", 1, true) then
	failures[#failures + 1] = "native Extra SpellFlyout arrows must not use custom HIGH-strata ConfigureLayer"
end
has(ebsHostButtons, "Flyout.BindHost", "ExtraButtons BindHost")
has(hosts, "Flyout.BindHost", "strip Hosts BindHost")
local minimapButtonsSrc = read("../Minimap/FluxMinimapButtons.lua")
has(minimapButtonsSrc, "ebs.Widget.Create", "minimap extras use EBS.Widget.Create")
has(minimapButtonsSrc, "Flyout.BindHost", "minimap extras BindHost")
if minimapButtonsSrc:find("FluxBtn.Create", 1, true) then
	failures[#failures + 1] = "minimap extras must not call FluxBtn.Create"
end
local visSrc = readEbs("Shared/FluxExtraButtonVisibility.lua")
has(visSrc, "EBV.GetOrderedIds()", "options ids come from live ordered hosts")
has(visSrc, 'id ~= "combat_assistedCombat"', "options skip unused assisted combat")
has(visSrc, "KnowsManaGemConjureSpell", "mana gem QuickGate requires a conjure gem spell")
has(visSrc, "Only with a conjure gem spell.", "mana gem auto help is the conjure spell")
if visSrc:find('return { "trinket_menu" }', 1, true) then
	failures[#failures + 1] = "options must list live combat and NC hosts, not trinket-only"
end
has(ebsHostButtons, "Widget.Create", "ExtraButtons uses Widget.Create")
has(ebsHostButtons, "Style.Apply", "ExtraButtons Style.Apply")
has(ebsHostButtons, "SetScale", "ExtraButtons visual size is widget SetScale")
has(ebsHostButtons, "SlotFrame", "ExtraButtons packs a SlotFrame")
has(ebsHostButtons, "NotifySAO", "ExtraButtons register with SAO")
has(ebsHostButtons, "size = native", "ExtraButtons create at native 44")
has(ebsHostCore, "return 44", "ExtraButtons native size is 44")
has(ebsHostUI, "Flux.Secrets", "ExtraButtons scroll uses Flux.Secrets")
if ebsHostButtons:find("FluxButtonUtil", 1, true) then
	failures[#failures + 1] = "ExtraButtons must not call FluxButtonUtil"
end
if ebsHostButtons:find("FluxButton.New", 1, true) then
	failures[#failures + 1] = "ExtraButtons must not FluxButton.New"
end
if ebsHostCore:find("FluxButtonEvents", 1, true) then
	failures[#failures + 1] = "ExtraButtons must not initialize FluxButtonEvents"
end
if ebsHostUI:find("FluxAPICompat", 1, true) then
	failures[#failures + 1] = "ExtraButtons must not use FluxAPICompat"
end
if ebsHostButtons:find('castUnit = "pet"', 1, true) then
	failures[#failures + 1] = "window Extra Buttons must stay default player cast unit"
end
do
	local i = ebsHostButtons:find("function B:CreateButton", 1, true)
	local j = ebsHostButtons:find("function B:CreateDeleteButton", 1, true)
	local body = (i and j and ebsHostButtons:sub(i, j - 1)) or ""
	if body:find("Widget:SetSize", 1, true) then
		failures[#failures + 1] = "ExtraButtons must not SetSize the widget to visual px"
	end
end
has(widgetSrc, "function Widget.Attach", "FluxButton attaches to existing occupancy hosts")
has(widgetSrc, "config.skipScripts or (kind == \"strip\")", "HUD extras can skip Extra-window scripts")
if widgetSrc:find("config.skipScripts = (kind == \"strip\") or (kind == \"badge\")", 1, true)
	and not widgetSrc:find("config.skipScripts or (kind == \"strip\")", 1, true)
then
	failures[#failures + 1] = "Widget.Create must honor explicit skipScripts"
end
has(widgetSrc, "function Widget.ResolveKind", "extra/badge/strip share one primitive")
has(widgetSrc, "EBS.RegisterBadge", "corner badges are not Extra-window buttons")
has(widgetSrc, 'kind == "strip"', "strip occupancy skips Extra RegisterButton")
has(widgetSrc, "Overlay.Attach", "EBS Overlay.Attach")
has(widgetSrc, "EBS.Paint.UpdateCooldown", "EBS UpdateCooldown paints the swipe")
has(widgetSrc, "Cast.Register", "EBS Cast.Register")
do
	local i = widgetSrc:find("local function BindOverlayCast", 1, true)
	local j = widgetSrc:find("local function ApplyTooltipScripts", i or 1, true)
	local body = (i and j and widgetSrc:sub(i, j - 1)) or ""
	has(body, "LiveSlot", "strip VFX follows the indexed slot, not the frozen combat action attribute")
	local strip = body:find('if self.kind == "strip" then', 1, true)
	local rest = strip and body:sub(strip) or body
	local liveAt = rest:find("LiveSlot", 1, true)
	local attrAt = rest:find('GetAttribute("action")', 1, true)
	if attrAt and (not liveAt or attrAt < liveAt) then
		failures[#failures + 1] = "strip Cast.Register must not prefer GetAttribute action over LiveSlot"
	end
end
has(widgetSrc, "config.castUnit", "Widget.Create passes castUnit to Cast.Register")
has(widgetSrc, "Click.Apply", "EBS uses ButtonFX.Click")
has(widgetSrc, "NotePressed", "EBS notes PUSHED")
has(widgetSrc, "NoteTargeting", "EBS clicked button owns reticle")
has(widgetSrc, "_fluxExtraButton", "EBS widgets marked extra")
has(widgetSrc, "_fluxPaintChecked", "EBS SetChecked locked to paint")
has(widgetSrc, "_fluxCheckedFromPaint", "EBS paint may SetChecked")
has(widgetSrc, "C_Timer.After(0", "empty extra click clears gold next frame")
has(widgetSrc, "not btn.ActionType or not btn.ActionValue", "empty extra PostClick has no current-spell face")
has(widgetSrc, "RequestCheckedSettle", "EBS PostClick settles gold after click-to-summon")
has(widgetSrc, "Flux.Action.DetachFromCollectors", "EBS collector nil-in-place")
if widgetSrc:find("function widget:OnEvent()", 1, true) then
	failures[#failures + 1] = "EBS must not Flux-noop OnEvent (collector taint)"
end
if widgetSrc:find("function widget:Update()", 1, true) then
	failures[#failures + 1] = "EBS must not Flux-noop mixin Update (collector taint)"
end
if widgetSrc:find("function widget:UpdateAction()", 1, true) then
	failures[#failures + 1] = "EBS must not Flux-noop UpdateAction (collector taint)"
end
if widgetSrc:find("table.remove(frames", 1, true) then
	failures[#failures + 1] = "EBS must not table.remove collector frames"
end
if widgetSrc:find("pressAndHold = true", 1, true) then
	failures[#failures + 1] = "EBS must not always set pressAndHoldAction"
end
if widgetSrc:find('HookScript("OnMouseUp"', 1, true) then
	failures[#failures + 1] = "EBS must not reset press state in OnMouseUp (kills the up-click)"
end
has(widgetSrc, 'SetScript("PreClick", function(w, button, down)', "EBS PreClick takes button/down")
has(widgetSrc, 'button == "KeyBind" or button == "ConjureBind" or down', "EBS PreClick skips keys and mouse-down")
has(widgetSrc, "UsesWrap", "Extra PreClick blanking is wrap-only")
if widgetSrc:find('w:SetAttribute("type", nil)', 1, true) then
	failures[#failures + 1] = "EBS PreClick must blank type with \"\", not nil"
end
local ebsButton = readEbs("Engine/Button.lua")
has(ebsButton, 'if button == "KeyBind" or button == "ConjureBind" then', "EBS Button PreClick skips keys")
has(ebsButton, "UsesWrap", "Button.lua PreClick blanking is wrap-only")
has(ebsButton, "ExtraDisplayItemCount", "Button.lua Extra items use DisplayItemCount")
has(ebsButton, "if uses > copies then", "Button.lua Extra items show remaining uses for charged copies")
do
	local i = ebsButton:find("function FluxButton:UpdateTextCount", 1, true)
	local j = ebsButton:find("function FluxButton:ForceRingBorderClassColor", i or 1, true)
	local body = (i and j and ebsButton:sub(i, j - 1)) or ""
	has(body, "ExtraDisplayItemCount", "Button.lua item digits use ExtraDisplayItemCount")
	local item = body:find('elseif self.ActionType == "item" then', 1, true)
	local macro = item and body:find('elseif self.ActionType == "macro" then', item, true)
	local itemBody = (item and macro and body:sub(item, macro - 1)) or ""
	if itemBody:find("charges = true", 1, true) then
		failures[#failures + 1] = "Button.lua must not always GetLiveCount charges for generic Extra items"
	end
end
local ebsPaint = readEbs("Engine/Paint.lua")
do
	local i = ebsPaint:find("function Paint.UpdateIcon", 1, true)
	local j = i and ebsPaint:find("local function SnapshotStackCount", i, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	local bm = body:find("if btn.badgeMode then", 1, true)
	local els = bm and body:find("else", bm, true)
	local branch = (bm and els and body:sub(bm, els - 1)) or ""
	if branch == "" or branch:find("QUESTION", 1, true) then
		failures[#failures + 1] = "Extra badgeMode must not stamp INV_Misc_QuestionMark"
	end
end
has(ebsPaint, "charge count is 0 while the stack is still in bags", "Paint count keeps gem stacks over live 0")
has(ebsPaint, "Paint.DisplayItemCount", "Extra DisplayItemCount")
do
	local i = ebsPaint:find("local function DisplayItemCount", 1, true)
	local j = ebsPaint:find("Paint.DisplayItemCount = DisplayItemCount", i or 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	has(body, "if uses > copies then", "Paint DisplayItemCount charged copies show remaining uses")
	has(body, "preferCopies", "combat gem/HS can prefer bag copies")
	has(body, "LiveChargeCount", "single copy still uses remaining charges")
	has(body, "Flux window / minimap", "DisplayItemCount covers Extra window and minimap slots")
end
do
	has(ebsPaint, "if btn._forcedCountLive and btn._liveCountItemId and KindItemCountFace(btn) then", "live forced count skips Recuperate spell face")
	has(ebsPaint, "preferCopies = ConsumableKindButton(btn)", "live forced count uses DisplayItemCount")
	local i = ebsPaint:find("if btn._forcedCountLive and btn._liveCountItemId and KindItemCountFace(btn) then", 1, true)
	local j = ebsPaint:find("if btn._forcedCount ~= nil and not btn.IsRecuperateMode", i or 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	if body:find("LiveChargeCount", 1, true) then
		failures[#failures + 1] = "forced live count must not raw-LiveChargeCount when copies > 1"
	end
end
has(ebsPaint, "use-spell reagent count of 1", "Paint prefers item charges over spell reagent 1")
has(ebsPaint, "Item 0 must win over spell 1", "Paint item 0 beats spell reagent 1")
has(ebsPaint, "_forcedCountLive", "Paint honors live charge counts from combat grid")
has(ebsPaint, "Forced / live digits (including 0)", "Paint keeps forced 0 through empty-action passes")
has(ebsPaint, "local function EmptyConsumableUnusable", "Paint darkens 0-count gems and consumables")
has(ebsPaint, "Recuperate (spell on the food Extra)", "Recuperate uses SpellUsable not empty-food darken")
has(ebsPaint, "local function KindItemCountFace", "food Recuperate skips consumable item count")
has(ebsPaint, "leftover stack of 1, 0 charges", "Paint darkens unique gems at 0 charges")
has(ebsPaint, "Missing conjure ranks", "owned jade stays lit while agate is still missing")
has(ebsPaint, "function AnyManaGemHasRemainingUse", "mana gem usable if any owned use remains")
has(ebsPaint, "skip KeepOr so a leftover true does not stay lit", "0-charge gem skips usable KeepOr")
has(ebsPaint, "Mana gem usable tint ignores item-use spell", "mana gem tint is count/charges not IsUsableItem")
has(ebsPaint, "charge == \"empty\" and not btn.IsManaGemButton", "mana gem ignores item-use spell charge empty")
has(ebsPaint, "function Paint.NotePlayerCast", "Extra dims 0 charges/items on cast success")
has(ebsPaint, "writes a secret count in combat", "Extra keeps last count on secret writes")
has(ebsPaint, "Firm 0-count wins even if a use-spell still looks charged", "Extra 0 stacks dim even if charge looks ready")
has(ebsPaint, "Item.IsUsable is false while GetItemCount is still 0", "Paint usable keeps bag items after loading screens")
has(ebsPaint, "function ApplyPlaceholderIcon", "Paint keeps gray placeholder icons")
has(ebsPaint, "local function ApplyIconDesat", "Extra usable tint keeps lower-rank grayscale")
has(ebsPaint, "SRM:ApplyRankDesaturation", "Extra usable applies rank desat before vertex")
has(ebsPaint, "Empty-slot placeholders keep the gray icon", "Paint hides class-tinted hole on placeholders")
has(ebsPaint, "function Paint.UpdateLiveFace", "EBS UpdateLiveFace for flyout hosts")
has(ebsPaint, "_fluxManagedFaceItemId", "macro item face honors pinned Extra item id")
has(ebsPaint, 'tokens["ebs.glow"]', "EBS glow eval lane")
has(ebsPaint, "SetChecked(checked)", "EBS always SetChecked")
has(ebsPaint, "function Paint.UpdateFlash", "EBS auto-attack/auto-shot red flash")
has(ebsPaint, "function Paint.FlushFlash", "EBS flash walks extras and badges")
has(ebsPaint, "Paint.UpdateFlash(btn)", "EBS checked paint also drives the red flash")
has(ebsPaint, "WantSpell", "EBS flash uses shown spell auto-repeat")
has(ebsPaint, "WantItem", "EBS flash uses item shoot/auto-repeat")
has(ebsPaint, "btn.kind == \"strip\"", "EBS flash does not clear the strip widget")
has(ebsPaint, "_fluxPaintChecked", "EBS paint writes checked lock")
has(ebsPaint, "_fluxCheckedFromPaint", "EBS paint SetChecked bypass")
has(ebsPaint, "_fluxCheckedApplied", "extra checked skip is paired with the widget stamp")
do
	local i = ebsPaint:find("function Paint.UpdateAllCooldowns", 1, true)
	local j = i and ebsPaint:find("\nlocal function CanAccess", i, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	has(body, "IsParked", "Extra cooldown sweep skips parked faces")
end
do
	local i = ebsPaint:find("function Paint.IsParked", 1, true)
	local j = i and ebsPaint:find("function Paint.RequestShown", i, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	has(body, "_fluxBadgeCombatVisHidden", "alpha-0 badges count as parked")
	has(body, "IsVisible", "parent-hidden Extra window children count as parked for range/need")
end
has(ebsPaint, "function Paint.RequestChecked", "EBS checked rides the eval lane")
has(ebsPaint, "function Paint.RequestCheckedSettle", "EBS checked re-checks once after activate")
has(ebsPaint, "IsCheckedSuppressed", "EBS checked paint honors craft RC suppress")
-- Standing in cat form used to hold a 4 Hz walk of every extra button open
-- forever. Only summon-style faces are watched, only while one is lit.
has(ebsPaint, "local POLL_PRONE", "EBS dismiss watch is limited to summon-style faces")
has(ebsPaint, "function Paint.ArmCheckedPoll", "EBS dismiss watch arms on demand")
has(ebsPaint, "AnyPollProneLit", "EBS dismiss watch idles when nothing summon-like is gold")
has(ebsPaint, "IsHopBurst", "EBS dismiss watch does not walk extras during hops")
if ebsPaint:find("CHECKED_ACTIVE_TICK", 1, true) then
	failures[#failures + 1] = "EBS must not keep a permanent gold tick over every button"
end
if ebsPaint:find("local CHECKED_TICK", 1, true) then
	failures[#failures + 1] = "EBS checked must not re-run on a 50ms settle loop"
end
has(ebsPaint, "SpellIsPersistSummon", "EBS pet/mount spells ignore sticky IsCurrentSpell")
has(ebsPaint, "ItemPersistSummon", "EBS pet/mount items ignore sticky IsCurrentItem")
has(ebsPaint, "summonedName", "EBS companion gold matches exact companion name")
has(widgetSrc, "_fluxGoldChecked", "EBS SetChecked keeps gold overlay in sync")
do
	local i = ebsPaint:find("function Paint.FlushChecked", 1, true)
	local j = ebsPaint:find("local function AnyPollProneLit", 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	has(body, "polledOnly", "EBS checked watch pass only touches lit summon faces")
	has(body, "companionCache = nil", "EBS checked pass rebuilds the companion cache once")
	has(body, "CheckedVisualOn", "EBS dismiss watch also clears leftover gold overlay")
	has(body, "Fully empty extras", "EBS checked pass also clears empty-slot gold")
end
do
	local i = ebsPaint:find("local function CompanionSpellIsSummoned", 1, true)
	local j = ebsPaint:find("local function SpellIsPersistSummon", 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	if body:find(":find(", 1, true) then
		failures[#failures + 1] = "EBS companion name match must be exact, not substring"
	end
end
has(ebsPaint, "GetMountFromSpell", "EBS mount-as-spell checked")
has(ebsPaint, "SpellIsActive", "EBS gold stays while spell/companion is active")
has(ebsPaint, "ItemIsActive", "EBS gold stays while item/pet/mount is active")
has(ebsPaint, "GetCompanionInfo", "EBS companion critter summoned is gold")
has(ebsPaint, "GetPetInfoByItemID", "EBS pet item summoned is gold")
has(ebsPaint, "GetMountFromItem", "EBS mount item stays gold while mounted")
has(ebsPaint, "IsLiveReticle", "EBS no checked stack while reticle up")
has(ebsPaint, 't == "item" or t == "toy"', "EBS toy is current item")
has(ebsPaint, "FlyoutIsOpen", "EBS flyout checked while open")
has(ebsPaint, "P.GetActionInfo", "EBS pet isActive every paint")
has(ebsPaint, "IsCurrentlySummoned", "EBS battle pet Classic IsCurrentlySummoned")
has(ebsPaint, "RANDOM_BATTLE_PET_ID", "EBS random favorite battle pet")
has(ebsPaint, 'MacroMode == "spell"', "EBS macro checked follows TranslateMacro")
has(ebsPaint, "Spell.GetLiveFace", "EBS spell icons use GetLiveFace")
has(ebsPaint, "Spell.GetTexture", "EBS spell icons fall back to GetTexture")
do
	local i = ebsPaint:find("local function ItemIcon", 1, true)
	local j = ebsPaint:find("local function ToyIcon", 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	has(body, "Item.GetIcon", "EBS item icons use the item texture")
	if body:find("GetLiveFace", 1, true) then
		failures[#failures + 1] = "EBS item icons must not use the item spell live face"
	end
	if body:find("GetSpell", 1, true) then
		failures[#failures + 1] = "EBS item icons must not resolve the item's spell"
	end
end
has(ebsPaint, "function Paint.IsParked", "EBS paint skips hidden buttons")
has(ebsPaint, "function Paint.RequestShown", "EBS repaints a button when it comes back")
-- GetLiveFace probes the action bars, the form list and the spellbook. Wiping
-- its cache inside the flush meant re-probing every spell on every pass.
do
	local i = ebsPaint:find("function Paint.FlushIcons", 1, true)
	local j = ebsPaint:find("function Paint.RequestIcon", 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	if body:find("ClearLiveFaceCache", 1, true) then
		failures[#failures + 1] = "EBS icon flush must not wipe the live-face cache every pass"
	end
	if body:find("_lastIcon = nil", 1, true) then
		failures[#failures + 1] = "EBS icon flush must not bust the per-button icon cache"
	end
end
do
	local i = ebsPaint:find("local function SpellIcon", 1, true)
	local j = ebsPaint:find("local function PaintSpell", 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	if not body:find("GetLiveFace", 1, true) then
		failures[#failures + 1] = "EBS SpellIcon must GetLiveFace"
	end
end
do
	local i = ebsPaint:find('elseif t == "shapeshift"', 1, true)
	local j = ebsPaint:find("if t == \"pet\"", i or 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	if not body:find("GetFormInfo", 1, true) then
		failures[#failures + 1] = "EBS shapeshift extras must GetFormInfo"
	end
	if body:find("GetLiveFace", 1, true) then
		failures[#failures + 1] = "EBS shapeshift extras must not GetLiveFace (keep form art)"
	end
	if body:find("SpellIcon", 1, true) then
		failures[#failures + 1] = "EBS shapeshift extras must not SpellIcon (would wisp stance)"
	end
end
has(ebsPaint, "function Paint.RequestIcon", "EBS icon request exists")
if ebsPaint:find("ICON_SETTLE", 1, true) or ebsPaint:find("ICON_TICK", 1, true) then
	failures[#failures + 1] = "EBS must not re-run icons on a settle timer"
end
has(ebsPaint, "FlyoutSlotCastID", "EBS flyout icon uses override-preferred slot id")
do
	local i = ebsPaint:find("local function MacroIcon", 1, true)
	local j = ebsPaint:find("local function UpdateMacroNameOverlay", 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	local shown = body:find("MacroShownSpell", 1, true)
	local saved = body:find("MacroTexture", 1, true)
	if not shown or not saved or shown > saved then
		failures[#failures + 1] = "EBS MacroIcon must prefer shown spell over GetMacroInfo"
	end
	if not body:find("SpellIcon", 1, true) then
		failures[#failures + 1] = "EBS MacroIcon must SpellIcon the shown spell"
	end
end
has(ebsPaint, 't == "equipmentset"', "EBS equipment set never gold")
do
	local i = ebsPaint:find("function Paint.UpdateChecked", 1, true)
	local j = ebsPaint:find("function Paint.UpdateGlow", 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	if not body:find("SpellNameRank", 1, true) then
		failures[#failures + 1] = "EBS UpdateChecked must use SpellNameRank"
	end
	if body:find("SpellBlockedAsCurrent", 1, true) then
		failures[#failures + 1] = "EBS UpdateChecked must not SpellBlockedAsCurrent"
	end
	has(body, "_fluxBadgeCombatVisHidden", "alpha-0 badges force unchecked")
end
do
	local i = ebsPaint:find("function Paint.UpdateGlow", 1, true)
	local j = i and ebsPaint:find("local EQUIP_R", i, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	has(body, "_fluxBadgeHost", "bar-hosted badge glow defers to SyncColumn")
end
if ebsPaint:find("checked = btn.PetIsActive and true or false", 1, true) then
	failures[#failures + 1] = "EBS pet must not gate GetActionInfo on PetIsActive"
end
has(ebsPaint, "fromItem", "EBS item CD does not use spell GCD duration object")
has(ebsPaint, "skipDurationObject", "EBS skips GCD duration object when a real timer exists")
has(ebsPaint, "Ready spells (0, 0)", "EBS ready spells do not fetch a GCD duration object")
has(ebsPaint, "d <= 2", "EBS does not paint GCD-length swipe on extras")
has(ebsPaint, "SpellCooldownForButton", "EBS paints unique spell CD from id or name")
has(ebsPaint, "Item.GetCooldown", "EBS item CD uses Item.GetCooldown")
has(ebsPaint, "RaiseCooldown", "EBS cooldown sits above count after paint")
has(ebsPaint, "SetUsingParentLevel", "badge cooldown ignores parent level so it sits above count")
has(ebsPaint, "_fluxCountHolder", "count leaves TextOverlayContainer under the cooldown")
has(ebsPaint, "EnsureCooldownFrame", "EBS creates/pins the cooldown swipe")
has(ebsPaint, "function Paint.UpdateAllCooldowns", "EBS paints every extra button CD")
has(chargesSrc, "hideWhenIdle", "Extra Button idle cooldown can hide (no frozen GCD slab)")
has(ebsPaint, "hideWhenIdle", "EBS hides idle cooldown so cast cannot show a frozen GCD slab")
has(ebsPaint, "frozen full-dark slab", "EBS skips GCD duration objects that do not progress")
has(ebsPaint, "fontString:SetText(value)", "EBS SetText secrets instead of skipping")
if ebsPaint:find("SafeCountKey", 1, true) then
	failures[#failures + 1] = "EBS SetCountText must not SafeCountKey-skip secret digits"
end
do
	local i = ebsPaint:find("local function SetCountText", 1, true)
	local j = ebsPaint:find("local function SpellCountText", i or 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	if body:find("fontString:Hide()", 1, true) then
		failures[#failures + 1] = "SetCountText must not Hide the count fontstring"
	end
	has(body, "fontString:Show()", "blank extra count stays shown")
	has(body, "fontString:SetText(value)", "SetCountText still writes secret digits")
end
do
	local i = ebsPaint:find("function Paint.FlushCounts", 1, true)
	local j = ebsPaint:find("function FluxButton:UpdateEmptyBackground", i or 1, true)
	local body = (i and j and ebsPaint:sub(i, j - 1)) or ""
	has(body, 'btn.ActionType == "spell"', "bag pulse refreshes spell reagent counts")
	has(body, "not spellFace", "spell reagents ignore changedItemIDs")
end
has(ebsPaint, "_fluxGlowSpell", "EBS keep-live glow spell")
has(ebsPaint, "FaceShowsSpell", "EBS glow hides when icon left the proc")
has(ebsPaint, "ShouldSkipBirth", "EBS skipBirth if that spell already intro'd")
has(ebsPaint, "G.IsLive", "EBS glow continue if live")
has(ebsPaint, "function Paint.EnsureAutocast", "EBS EnsureAutocast")
has(ebsPaint, "AutoCastOverlayTemplate", "EBS Retail autocast overlay")
has(ebsPaint, "AutoCastShineTemplate", "EBS Classic autocast shine")
has(ebsPaint, "function PetActionTexture", "EBS pet token textures")
has(ebsPaint, "GetFormCooldown", "EBS shapeshift cooldown path")
has(ebsPaint, "GetActionCooldown", "EBS pet cooldown path")
do
			local clear = clearCacheChunk(ebsPaint)
	if clear:find("_glowing", 1, true) then
		failures[#failures + 1] = "EBS Paint.ClearCache must not nil _glowing"
	end
end
local ebsStyle = readEbs("Engine/Style.lua")
has(ebsStyle, "CheckButtonHilight", "checked is gold hilight")
has(ebsStyle, "local function SizeHighlight", "highlight sized without OVERLAY layer")
do
	local i = ebsStyle:find("local function SizeHighlight", 1, true)
	local j = ebsStyle:find("local CLASSIC_SLOT", 1, true)
	local body = (i and j and ebsStyle:sub(i, j - 1)) or ""
	if body:find("SetDrawLayer", 1, true) then
		failures[#failures + 1] = "SizeHighlight must leave C++ HIGHLIGHT layer (no SetDrawLayer)"
	end
	if body:find(":Hide()", 1, true) then
		failures[#failures + 1] = "SizeHighlight must not Hide HighlightTexture"
	end
end
do
	local i = ebsStyle:find("local PRE_DF_RING_SCALE", 1, true)
		or ebsStyle:find("function Style.SizeRing", 1, true)
	local j = ebsStyle:find("function Style.Apply", 1, true)
	local body = (i and j and ebsStyle:sub(i, j - 1)) or ""
	if body:find("highlight:Hide()", 1, true) then
		failures[#failures + 1] = "SizeRing must not Hide highlight (C++ mouseover)"
	end
	if not body:find("SizeHighlight(highlight", 1, true) then
		failures[#failures + 1] = "SizeRing must SizeHighlight, not SizeChrome, the mouseover texture"
	end
	if not body:find("Flash.Ensure", 1, true) then
		failures[#failures + 1] = "SizeRing must size the auto-attack flash"
	end
	if not body:find("UI-HUD-ActionBar-IconFrame", 1, true) then
		failures[#failures + 1] = "SizeRing post-DF must use IconFrame atlas"
	end
	if not body:find("UI-Quickslot2", 1, true) then
		failures[#failures + 1] = "SizeRing pre-DF must assign UI-Quickslot2"
	end
	if not body:find("function SizePreDFRing", 1, true) then
		failures[#failures + 1] = "SizeRing pre-DF must size Quickslot2 without SetDrawLayer"
	end
	if not body:find("1.65", 1, true) then
		failures[#failures + 1] = "SizeRing pre-DF must use 1.65 ring overhang"
	end
	if not body:find("isPostDF", 1, true) then
		failures[#failures + 1] = "SizeRing must gate on isPostDF"
	end
	if not body:find("isAnyClassic", 1, true) then
		failures[#failures + 1] = "SizeRing must keep Quickslot2 on isAnyClassic"
	end
	if body:find("majorVersion < 10", 1, true) or body:find("majorVersion >= 10", 1, true) then
		failures[#failures + 1] = "SizeRing must not gate on majorVersion (Forever is 1.x)"
	end
	if not body:find("UI-Backpack-EmptySlot", 1, true) then
		failures[#failures + 1] = "SizeRing pre-DF must keep backpack empty plate"
	end
	if not body:find("UI-EmptySlot-Disabled", 1, true) then
		failures[#failures + 1] = "SizeRing extra buttons must keep EmptySlot-Disabled 1.5 plate"
	end
	if not body:find("_fluxQuickslotRing", 1, true) then
		failures[#failures + 1] = "SizeRing pre-DF must keep widget overlay ring"
	end
	if not body:find("UseQuickslotRing", 1, true) then
		failures[#failures + 1] = "SizeRing must share UseQuickslotRing"
	end
	if not body:find("SizePreDFDepress(pushed", 1, true) then
		failures[#failures + 1] = "SizeRing pre-DF must size PushedTexture to the slot, not PRE_DF_RING_SCALE"
	end
	if body:find("SizePreDFRing(pushed", 1, true) then
		failures[#failures + 1] = "SizeRing pre-DF must not 1.65-scale the depress"
	end
	if not body:find("function SizeIconFrame", 1, true) then
		failures[#failures + 1] = "SizeRing post-DF must SizeIconFrame 46x45 TOPLEFT"
	end
	if not body:find("DF_RING_W, DF_RING_H, DF_SLOT = 46, 45, 44", 1, true) then
		failures[#failures + 1] = "SizeRing post-DF uses native 46x45 scaled by slot/44"
	end
	if body:find("\tSizeChrome(tex, widget, w, h)", 1, true) then
		failures[#failures + 1] = "SizeRing post-DF must not SizeChrome the IconFrame"
	end
	if body:find('SizeChrome(ResolveSlotTex(widget, "PushedTexture"', 1, true) then
		failures[#failures + 1] = "SizeRing post-DF must not SizeChrome the depress"
	end
	if not body:find("HideSlotBackground", 1, true) then
		failures[#failures + 1] = "SizeRing must hide Classic SlotBackground (unwanted UI-Quickslot)"
	end
	if not body:find('HookScript("OnShow"', 1, true) then
		failures[#failures + 1] = "SizeRing pre-DF must re-size depress on OnShow"
	end
end
if ebsStyle:find("SetCheckedAtlas", 1, true) then
	failures[#failures + 1] = "EBS checked must not use SetCheckedAtlas mouseover"
end
local badgeSrc = readEbs("Engine/Badge.lua")
has(badgeSrc, "widget:SetScale(scale)", "badge visual size is SetScale on native 44")
has(badgeSrc, "CORNER_STACK_GAP = 0", "stacked badges have no gap")
has(badgeSrc, "function Badge.StackCount", "badge stack is three tiles on a button")
has(badgeSrc, "EnsureSlot", "badge packs a visual SlotFrame like Extra Buttons")
has(badgeSrc, 'SetPoint("CENTER", slot, "CENTER"', "badge widget is centered in the SlotFrame")
has(badgeSrc, "Anchoring the 44px widget on visual-size steps overlaps neighbors", "badge stack does not offset the native-44 box")
has(badgeSrc, "function Badge.SyncCountFont", "badge stack/charge/reagent digits are sized for the corner")
has(badgeSrc, "COUNT_FONT_SCALE = 0.75", "badge count is 25% smaller than minirow")
has(badgeSrc, "MiniCountFontSize", "badge count uses the minirow font size")
has(badgeSrc, "MINI_WIDGET_SCALE", "badge count compensates for mini vs corner scale")
if badgeSrc:find("2 / 3", 1, true) then
	failures[#failures + 1] = "badge count must not shrink to 2/3 of NumberFontNormal"
end
has(ebsPaint, "Badge.SyncCountFont", "Extra count paint sizes action-bar badge digits")
has(badgeSrc, "Do not SetSize to the", "SpellFX stays authored for 44")
has(badgeSrc, "SuppressBadgeChrome", "badge hides Extra ring chrome")
has(badgeSrc, "HostVfxCeiling", "badges sit above host SpellFX")
has(badgeSrc, "SpellCastAnimFrame", "badge level considers cast fill")
has(badgeSrc, "HOST_VFX_PAD", "badge level clears glow/text overlay band")
do
	local i = badgeSrc:find("function Badge.SyncFrameLevel", 1, true)
	local j = i and badgeSrc:find("local function NativeSize", i, true)
	local body = (i and j and badgeSrc:sub(i, j - 1)) or ""
	if body:find("cdLevel + idx", 1, true) then
		failures[#failures + 1] = "badge frame level must be above host VFX, not cooldown+idx"
	end
	has(body, "HostVfxCeiling", "SyncFrameLevel uses the host VFX ceiling")
end
if badgeSrc:find("badge.Widget:SetSize(size, size)", 1, true) then
	failures[#failures + 1] = "Badge must not SetSize to corner px (breaks ring/VFX scale)"
end
if badgeSrc:find("Charges.Ensure", 1, true) then
	failures[#failures + 1] = "Badge must not eagerly Charges.Ensure"
end
do
	local i = badgeSrc:find("function Badge.HideVisual", 1, true)
	local j = i and badgeSrc:find("\nfunction ", i + 10, true)
	local body = (i and j and badgeSrc:sub(i, j - 1)) or ""
	if body:find("Widget:Hide()", 1, true) then
		failures[#failures + 1] = "HideVisual must not Widget:Hide (combat taint)"
	end
	has(body, "SetAlpha(0)", "HideVisual is alpha only")
	has(body, "_fluxBadgeCombatVisHidden", "HideVisual stamps unused corners")
end
do
	local i = badgeSrc:find("function Badge.ShowVisual", 1, true)
	local j = i and badgeSrc:find("function Badge.HideVisual", i, true)
	local body = (i and j and badgeSrc:sub(i, j - 1)) or ""
	has(body, "InLockdown", "ShowVisual Show is OOC-only")
	has(body, "SetAlpha", "ShowVisual restores badge alpha")
	if body:find(":Show()", 1, true) and not body:find("InLockdown", 1, true) then
		failures[#failures + 1] = "ShowVisual must not Show() without an OOC guard"
	end
end
local ebsWatch = readEbs("Engine/Watch.lua")
has(ebsWatch, "Flux.Bars.ProgramFace", "Extra cond events share the strip hub")
has(ebsWatch, "RequestTarget", "Extra tab-target [harm] shares the reaction skip")
has(ebsWatch, "ContextOwnsDisplay", "Extra hops defer to Context when subscribed")
has(ebsWatch, "local function RequestCond", "Extra cond events coalesce through ProgramFace")
do
	local i = ebsWatch:find('Ev.Register("GROUP_ROSTER_UPDATE"', 1, true)
	local body = i and ebsWatch:sub(i, i + 160) or ""
	has(body, 'RequestCond("combat")', "Extra roster flips [group], not a full parse")
end
do
	local i = ebsWatch:find("local function OnPlayerUnit", 1, true)
	local j = i and ebsWatch:find('Ev.Register("UNIT_SPELLCAST_CHANNEL_START"', i, true)
	local body = (i and j and ebsWatch:sub(i, j - 1)) or ""
	has(body, 'RequestCond("combat")', "channel/vehicle cond is combat, not all")
	if body:find('RequestCond("all")', 1, true) then
		failures[#failures + 1] = "channel/vehicle must not Request all"
	end
end
do
	local i = ebsWatch:find('Ev.Register("CURRENT_SPELL_CAST_CHANGED"', 1, true)
	local body = i and ebsWatch:sub(i, i + 180) or ""
	has(body, 'RequestCond("combat")', "cast-changed cond is combat snapshot, not all")
	if body:find('RequestCond("all")', 1, true) then
		failures[#failures + 1] = "CURRENT_SPELL_CAST_CHANGED must not Request all"
	end
end
do
	local i = ebsWatch:find("local function RefreshMacros", 1, true)
	local j = i and ebsWatch:find("RegisterMany(Ev, \"ebs.usable\"", i, true)
	local body = (i and j and ebsWatch:sub(i, j - 1)) or ""
	if body:find("RequestConditionalRefresh", 1, true) then
		failures[#failures + 1] = "RefreshMacros must not drive the strip (Bars Watch / cond hub owns it)"
	end
end
has(ebsWatch, "OnUsableEvent", "Extra usable paint skips world mouseover hops")
has(ebsWatch, "IsHopBurst", "Extra usable hop gate shares Range.IsHopBurst")
has(ebsWatch, "cooldownHeld", "Extra cooldown storms during hops are held")
has(ebsWatch, "hopCheckedHeld", "Extra checked storms during hops are held")
if ebsWatch:find('Ev.Register("ACTIONBAR_SLOT_CHANGED"', 1, true) then
	failures[#failures + 1] = "Extra Watch must not RefreshMacros on ACTIONBAR_SLOT_CHANGED"
end
has(ebsWatch, 'RequestEval("ebs.glow")', "EBS glow OnChange")
has(ebsWatch, "Paint.RequestChecked", "EBS checked bypasses scheduler paging")
has(ebsWatch, "RequestCheckedSettle", "EBS activate events settle gold")
has(ebsWatch, "UNIT_SPELLCAST_SUCCEEDED", "EBS checked settles on spell land")
has(ebsWatch, "STOP_AUTOREPEAT_SPELL", "EBS checked STOP_AUTOREPEAT_SPELL")
has(ebsWatch, "TRADE_SKILL_SHOW", "EBS checked TRADE_SKILL_SHOW")
has(ebsWatch, "PLAYER_ENTER_COMBAT", "EBS checked PLAYER_ENTER_COMBAT")
has(ebsWatch, "PET_BATTLE_PET_CHANGED", "EBS checked PET_BATTLE_PET_CHANGED")
has(ebsWatch, "COMPANION_UPDATE", "EBS checked COMPANION_UPDATE")
has(ebsWatch, "UNIT_PET", "EBS checked UNIT_PET")
has(ebsWatch, "PET_BAR_UPDATE", "EBS checked PET_BAR_UPDATE")
has(ebsWatch, "Paint.RequestIcon", "EBS icon request is routed through Paint")
has(ebsWatch, "RequestIcon()", "EBS cast events refresh extra icons")
-- The form burst is subscribed once, not re-registered per event, and it drops
-- only the live-face cache: a shapeshift cannot change flyout contents, and
-- rebuilding that cache costs a full spellbook walk.
has(ebsWatch, 'FormStorm.OnBurst("ebs.form"', "EBS form work rides the form burst")
has(ebsWatch, 'FormStorm.OnSettled("ebs.form"', "EBS gets one trailing settle pass")
do
	local i = ebsWatch:find("local function OnForm", 1, true)
	local j = i and ebsWatch:find("local FormStorm", i, true)
	local block = (i and j and ebsWatch:sub(i, j - 1)) or ""
	has(block, "ClearLiveFaceCache", "form drops the live-face cache")
	if block:find("RefreshMacros", 1, true) or block:find("RequestMacroDisplay", 1, true) then
		failures[#failures + 1] = "form must not RequestMacroDisplay on top of RequestCond all"
	end
	if block:find("InvalidateSpellCaches", 1, true) then
		failures[#failures + 1] = "form must not wipe the flyout cache (full spellbook rescan)"
	end
end
do
	local i = ebsWatch:find('Ev.Register("SPELL_UPDATE_ICON"', 1, true)
	local j = ebsWatch:find("SPELL_UPDATE_CHARGES", 1, true)
	local block = (i and j and ebsWatch:sub(i, j - 1)) or ""
	if not block:find("InvalidateSpellCaches", 1, true) then
		failures[#failures + 1] = "EBS SPELL_UPDATE_ICON must invalidate flyout/spell caches"
	end
	if not block:find("RequestIcon()", 1, true) then
		failures[#failures + 1] = "EBS SPELL_UPDATE_ICON must still repaint the icon lane"
	end
	-- One registration per event: the bus appends handlers and runs them all.
	local _, n = ebsWatch:gsub('"SPELL_UPDATE_ICON"', "")
	if n > 1 then
		failures[#failures + 1] = "SPELL_UPDATE_ICON must have a single EBS owner"
	end
end
do
	local i = ebsWatch:find('RegisterMany(Ev, "ebs.checked"', 1, true)
	local j = ebsWatch:find("local function OnCheckedSettle", 1, true)
	local block = (i and j and ebsWatch:sub(i, j - 1)) or ""
	if not block:find("ACTIONBAR_UPDATE_STATE", 1, true) then
		failures[#failures + 1] = "EBS ACTIONBAR_UPDATE_STATE must stay one-frame checked"
	end
	if block:find("COMPANION_UPDATE", 1, true) then
		failures[#failures + 1] = "EBS COMPANION_UPDATE must settle, not one-frame RegisterMany"
	end
	if block:find("CURRENT_SPELL_CAST_CHANGED", 1, true) then
		failures[#failures + 1] = "EBS CURRENT_SPELL_CAST_CHANGED must settle, not one-frame RegisterMany"
	end
end
has(ebsWatch, "ButtonFX.Glow", "EBS Glow.Start")
has(ebsWatch, "ButtonFX.Flash", "EBS Flash.Start")
has(ebsWatch, "Paint.FlushFlash", "combat/auto-repeat refreshes Extra flash")
has(ebsWatch, "RequestCooldown", "EBS cooldown dirty does not wait on eval paging")
has(ebsWatch, 'RequestEval("ebs.cooldown")', "EBS cooldown rides the shared eval flush, not a second bus")
if ebsWatch:find("cooldownDriver", 1, true) then
	failures[#failures + 1] = "EBS cooldown must not own a private OnUpdate bus"
end
do
	local i = ebsWatch:find("SPELL_UPDATE_CHARGES", 1, true)
	local snippet = i and ebsWatch:sub(i, i + 400) or ""
	if not snippet:find("RequestCooldown", 1, true) then
		failures[#failures + 1] = "EBS SPELL_UPDATE_CHARGES must dirty cooldown"
	end
	if not snippet:find("ebs.count", 1, true) then
		failures[#failures + 1] = "EBS SPELL_UPDATE_CHARGES must dirty count"
	end
	if not snippet:find("ebs.usable", 1, true) then
		failures[#failures + 1] = "EBS SPELL_UPDATE_CHARGES must dirty usable"
	end
	if not snippet:find("formCountHeld", 1, true) then
		failures[#failures + 1] = "EBS SPELL_UPDATE_CHARGES during a form window must hold count"
	end
end
do
	local i = ebsWatch:find("local function ReleaseFormHeld", 1, true)
	local j = i and ebsWatch:find("local function OnForm", i, true)
	local body = (i and j and ebsWatch:sub(i, j - 1)) or ""
	has(body, "formCountHeld", "form settle replays a charge count")
	has(body, 'RequestEval("ebs.count")', "form settle requests ebs.count even when quiet")
end

-- Extra Button single-button assistant (live engine, not unused Engine/Button.lua)
local ebsAction = readEbs("Engine/Action.lua")
has(ebsAction, "function Action.ShownFromBody", "Extra parse is shared with strip/badges")
has(ebsAction, "Action.RouteMouseoverMacro", "Extra macros with [@mouseover] route through a hidden sibling")
has(ebsAction, "ArmMacroDelegate", "Extra hidden clickers get typerelease so delegate:Click fires")
has(ebsAction, "_MoClick", "Extra hidden clicker name suffix")
has(ebsAction, "_fluxStripFace", "TranslateMacro skips Extra paint for strip envs")
has(ebsAction, "Action.TranslateFace = Action.TranslateMacro", "one translate path for Extra/strip/badge")
has(ebsAction, "MC.SetButtonItem", "Extra items stamp the mouseover-cast unit")
has(ebsAction, "PF.EachBody", "Extra condition ticker also scans strip overlay bodies")
has(ebsAction, "function Action.TranslateMatching", "Extra cond flush translates only matching macros")
has(ebsAction, "PF.EachExtraMatching", "Extra TranslateMatching uses cached kind lists")
has(ebsAction, "faceUnchanged", "Extra TranslateMacro does not 6-lane paint on unit-name hops")
has(ebsAction, "CacheValuesEqual(tName, btn.MacroTargetName)", "macro target-name compare is secret-safe")
if ebsAction:find("tName == btn.MacroTargetName", 1, true) then
	failures[#failures + 1] = "TranslateMacro must not == secret unit names"
end
has(ebsAction, "PullProbeFlags", "display ticker uses index probe flags")
do
	local i = ebsAction:find("local function OnMacroDisplayTick", 1, true)
	local j = i and ebsAction:find("function Action.SyncMacroProbes", i, true)
	local body = (i and j and ebsAction:sub(i, j - 1)) or ""
	if body:find("ScanProbeNeed", 1, true) then
		failures[#failures + 1] = "OnMacroDisplayTick must not ScanProbeNeed every frame"
	end
	if body:find("EachBody", 1, true) then
		failures[#failures + 1] = "OnMacroDisplayTick must not walk overlay bodies every frame"
	end
	if body:find('UnitNameSafe("mouseover")', 1, true) or body:find('UnitName("mouseover")', 1, true) then
		failures[#failures + 1] = "OnMacroDisplayTick must not poll UnitName mouseover"
	end
	has(body, "DISPLAY_PROBE_INTERVAL", "combat probes are not every frame")
end
do
	local i = ebsAction:find("function Action.RefreshMacroDisplay", 1, true)
	local j = i and ebsAction:find("-- ButtonForge never TranslateMacro", i, true)
	local body = (i and j and ebsAction:sub(i, j - 1)) or ""
	if body:find("RequestConditionalRefresh", 1, true) then
		failures[#failures + 1] = "RefreshMacroDisplay must not drive the strip"
	end
	has(body, "RefreshDisplays", "macro display lag also retranlates badges")
	has(body, "SyncShownFaces", "macro display lag settles badge vis")
end
do
	local i = ebsAction:find("local function AlwaysTranslateMacro", 1, true)
	local j = i and ebsAction:find("local function ShownMacroSpellId", i, true)
	local body = (i and j and ebsAction:sub(i, j - 1)) or ""
	has(body, "badgeMode", "corner badges always reparse reverse")
	if body:find("isPostDF and true", 1, true) then
		failures[#failures + 1] = "AlwaysTranslateMacro must not force Retail to always parse"
	end
	if body:find("return true", 1, true) and not body:find("badgeMode", 1, true) then
		failures[#failures + 1] = "AlwaysTranslateMacro must not force every Extra macro to parse"
	end
end
has(ebsAction, 'string.match(line, "^%s*(/%a+)%s*(.-)%s*$")', "macro parse uses /cast option tails")
has(ebsAction, "GetSpellIDForSpellIdentifier", "Retail macro names resolve like LAB")
has(ebsAction, 'kind == "showtooltip"', "bare #showtooltip is skipped so parse cannot return ?")
do
	local i = ebsAction:find("local function ParseMacroBody", 1, true)
	local j = i and ebsAction:find("function Action.ShownFromBody", i, true)
	local body = (i and j and ebsAction:sub(i, j - 1)) or ""
	if body:find("StripHashLines", 1, true) then
		failures[#failures + 1] = "ParseMacroBody must not StripHashLines then parse /cast as a full command"
	end
	if not body:find("CommandOptions", 1, true) then
		failures[#failures + 1] = "ParseMacroBody must parse #showtooltip args and /cast tails"
	end
	has(body, "parseCacheAction", "same macro body parses once per frame")
	has(body, "parseCacheSig", "same-frame parse cache follows live condition state")
	has(body, "skipCache", "reverse badges skip the same-frame parse cache")
end
has(ebsAction, "function Action.InvalidateMacroParseCache", "trailing reverse can bust the same-frame parse cache")
do
	local i = ebsAction:find("function Action.TranslateMacro", 1, true)
	local j = i and ebsAction:find("Action.TranslateFace = Action.TranslateMacro", i, true)
	local body = (i and j and ebsAction:sub(i, j - 1)) or ""
	has(body, "ParseMacroBody(body, always)", "reverse TranslateMacro skips the same-frame parse cache")
end
do
	local afn, aerr = loadfile(ebsDir .. "/Engine/Action.lua")
	if not afn then
		failures[#failures + 1] = "EBS Action.lua syntax: " .. tostring(aerr)
	end
end
has(ebsAction, "GetActionSpell", "EBS GetActionSpell")
has(ebsAction, "GetNextCastSpell, false", "EBS GetNextCastSpell(false)")
has(ebsAction, "ActionBarButtonAssistedCombatRotationTemplate", "EBS rotation template")
has(ebsAction, "lastFlying", "macro display ticker only stays armed while flying/mounted/swimming")
has(ebsAction, "PLAYER_MOUNT_DISPLAY_CHANGED", "macro display probes mount from events")
has(ebsAction, "UI-HUD-RotationHelper-Inactive", "EBS RotationHelper atlas fallback")
has(ebsAction, 'SetScript("OnUpdate", nil)', "EBS replaces mixin OnUpdate")
has(ebsAction, "ClientSupportsSingleButtonAssistant", "EBS assistant capability gate")
has(ebsAction, "FLUX_ASSISTED_COMBAT", "EBS assistant bind command")
has(ebsAction, "SetOverrideBindingClick", "EBS assistant override click")
has(ebsAction, "NoteSpellName", "EBS stores SpellNameRank for Classic GetSpellCooldown")
has(ebsAction, "SpellNameRank", "EBS SpellNameRank identity")
has(ebsAction, "pet = true", "EBS KNOWN.pet")
has(ebsAction, "shapeshift = true", "EBS KNOWN.shapeshift")
has(ebsAction, "CompanionSpellID", "EBS Classic critter companion maps to summon spell")
has(ebsAction, 'return "spell", spellID', "EBS companion CRITTER drop stores the summon spell")
has(ebsAction, 'actionType == "pet"', "EBS FillEnv pet")
has(ebsAction, 'actionType == "shapeshift"', "EBS FillEnv shapeshift")
has(ebsAction, 'SetAttribute("type", "pet")', "EBS pet click type")
has(ebsAction, 'SetAttribute("action", slot)', "EBS pet click uses pet action slot")
do
	local i = ebsAction:find('actionType == "pet" then', 1, true)
	local j = ebsAction:find('actionType == "shapeshift"', 1, true)
	local body = (i and j and ebsAction:sub(i, j - 1)) or ""
	has(body, 'SetAttribute("type", "pet")', "pet WriteAttributes type")
	if body:find('SetAttribute("unit", "pet")', 1, true) then
		failures[#failures + 1] = "pet clicks must not SetAttribute unit=pet"
	end
end
has(ebsAction, 'SetAttribute("clickbutton", donor)', "EBS shapeshift click donor")
has(ebsAction, "PickupPetAction", "EBS pet pickup")
has(ebsAction, "MacroShownSpell", "EBS TranslateMacro keys shown spell")
has(ebsAction, "EBS.Paint.UpdateGlow", "macro condition paint settles glow")
has(ebsAction, 'string.find(body, "#show")', "EBS #show follows shown spell tooltip")
has(ebsAction, "local function OverrideSpell", "EBS tooltip uses override spell id")
has(ebsAction, "NoteFlyoutPopupSpell", "EBS stashes flyout popup spell on drag")
has(ebsAction, "FindFlyoutSlotCastID", "EBS popup drag uses inner slot cast id")
has(ebsAction, "PickupResolvedSpell", "EBS popup drag re-pickups the inner spell")
has(ebsAction, "NoteFlyoutPopupItem", "EBS stashes flyout popup item on drag")
has(ebsAction, "SpellFlyoutPopupButton", "EBS wires SpellFlyoutPopupButton drag")
has(ebsAction, 'HookScript("OnDragStart"', "EBS popup drag is a Lua HookScript")
do
	local i = ebsAction:find("local function CursorToAction", 1, true)
	local j = i and ebsAction:find("\nfunction Action.", i + 10, true)
	local body = (i and j and ebsAction:sub(i, j - 1)) or (i and ebsAction:sub(i)) or ""
	has(body, 'cursorSubType == "flyout"', "CursorToAction sees flyout-subtype spell pickups")
	has(body, 'return "spell", sid or cursorData', "popup spell+flyout subtype stores the spell")
	if body:find('return "flyout", cursorSubData or cursorData', 1, true) then
		failures[#failures + 1] = "CursorToAction must not map popup spell+flyout to type=flyout"
	end
	has(body, 'if stashed and stashKind == "spell"', "popup stash beats a misclassified flyout cursor")
end
local fluxFlyoutSrc = readEbs("Flyout/FluxFlyoutFrame.lua")
has(fluxFlyoutSrc, 'RegisterForDrag("LeftButton")', "Flux flyout buttons register drag")
has(fluxFlyoutSrc, "NoteFlyoutPopupSpell", "Flux flyout drag stashes spell id")
has(fluxFlyoutSrc, "$spellID", "Flux flyout drag uses $spellID")
has(fluxFlyoutSrc, "PickupSpell", "Flux flyout drag PickupSpell")

-- Pet bar + stance bar (Extra Button surfaces)
local petInit = read("Pet/Init.lua")
local petWatch = read("Pet/Watch.lua")
local petLayout = read("Pet/Layout.lua")
local petKeys = read("Pet/Keys.lua")
local stanceInit = read("Stance/Init.lua")
local stanceWatch = read("Stance/Watch.lua")
local stanceLayout = read("Stance/Layout.lua")
local stanceExtras = read("Stance/Extras.lua")
local stanceForms = read("Stance/Forms.lua")
local stanceOrder = read("Stance/Order.lua")
local blizzardSrc = read("Blizzard.lua")
has(petInit, "[pet,novehicleui]show;hide", "pet visibility driver")
has(petInit, "RegisterStateDriver", "pet RegisterStateDriver")
has(petInit, "SetBindingModeFrameOverride", "pet binding-mode visibility override")
has(petInit, "EBS.Widget.Create", "pet Extra Button widgets")
has(petInit, 'castUnit = "pet"', "pet Init castUnit=pet")
has(petInit, "G.NotifySAO", "pet extras register with SAO")
has(petInit, '"pet"', "pet SetAction pet")
has(petInit, "scale = 1.133", "pet bar scale")
has(petInit, "size = native", "pet Extra Buttons create at native 44")
has(petLayout, "FluxBorder:ApplyTo(frame, -2, -4, -2, -4)", "pet border -2/-4")
has(petLayout, "EnsureSlot", "pet packs a visual SlotFrame like Extra Buttons")
has(petLayout, "slotH / native", "pet visual size is widget SetScale")
has(petLayout, 'SetPoint("CENTER", slot, "CENTER"', "pet widget is centered in the SlotFrame")
has(petLayout, "slot:SetSize(slotW, slotH)", "pet SlotFrame keeps X-squeeze cell")
has(petKeys, "BONUSACTIONBUTTON", "pet BONUSACTIONBUTTON keys")
has(petKeys, '"KeyBind"', "pet KeyBind override click")
do
	local i = petWatch:find("PET_BAR_UPDATE_COOLDOWN", 1, true)
	local snippet = i and petWatch:sub(i, i + 180) or ""
	if snippet:find('ForAll("Update")', 1, true) then
		failures[#failures + 1] = "PET_BAR_UPDATE_COOLDOWN must not full Update"
	end
	if not snippet:find("UpdateCooldown", 1, true) then
		failures[#failures + 1] = "PET_BAR_UPDATE_COOLDOWN must UpdateCooldown"
	end
end
has(petWatch, "ScheduleFull", "pet coalesces full paint")
do
	local i = petWatch:find('Ev.Register("PLAYER_REGEN_ENABLED"', 1, true)
	local body = i and petWatch:sub(i, i + 400) or ""
	if body:find("LayoutButtons", 1, true) then
		failures[#failures + 1] = "pet regen must not LayoutButtons (Combat.Defer bars.pet.layout)"
	end
	if body:find("SetupKeybindings", 1, true) then
		failures[#failures + 1] = "pet regen must not SetupKeybindings (Combat.Defer bars.pet.keys)"
	end
	has(body, "FlushBindingModePending", "pet regen flushes binding-mode pending")
end
if stanceWatch:find("PLAYER_REGEN_ENABLED", 1, true) then
	local i = stanceWatch:find("PLAYER_REGEN_ENABLED", 1, true)
	local body = i and stanceWatch:sub(i, i + 220) or ""
	if body:find("RequestLayout", 1, true) or body:find("RequestDiscover", 1, true) or body:find("Discover()", 1, true) then
		failures[#failures + 1] = "stance Watch must not rebuild on every regen (Combat.Defer bars.stance.*)"
	end
end
has(stanceWatch, "UNIT_SPELLCAST_SUCCEEDED", "stance notes mage armor on cast success")
has(stanceWatch, "PLAYER_REGEN_DISABLED", "stance combat edge refreshes armor visual")
has(stanceWatch, "ArmorVisual", "stance regen/aura/cast share visual-only refresh")
has(blizzardSrc, "PetActionBar", "hide Blizzard PetActionBar")
has(blizzardSrc, "PetActionBarFrame", "hide Blizzard PetActionBarFrame")
has(blizzardSrc, "StanceBar", "hide Blizzard StanceBar")
has(blizzardSrc, "StanceBarFrame", "hide Blizzard StanceBarFrame")
has(blizzardSrc, "PossessBarFrame", "hide Blizzard PossessBarFrame")
has(stanceInit, "SecureHandlerStateTemplate", "stance SecureHandlerStateTemplate")
has(stanceInit, "SHAPESHIFTBUTTON", "stance SHAPESHIFTBUTTON keys")
has(stanceInit, "visibleBindWidgets", "stance keys follow visible order")
has(stanceInit, "FluxStanceBarDummyButton", "unused SHAPESHIFTBUTTON keys go to dummy")
has(stanceInit, '"KeyBind"', "stance KeyBind override click")
has(stanceLayout, "visibleBindWidgets", "layout publishes visible bind widgets")
has(stanceInit, "Flux_ReanchorToLayout", "stance reanchor shim")
has(stanceLayout, "dirty.layout", "stance layout dirty flag")
has(stanceLayout, "RequestFormsVisual", "stance form visual dirty")
has(stanceLayout, "RequestExtrasVisual", "stance extra visual dirty")
has(stanceLayout, "STANCE_WINDOW_GAP_X", "stance window gap")
has(stanceLayout, "STATUS_LOC2_STACK_GAP", "stance status stack gap")
has(stanceLayout, "Pet.UpdatePosition", "stance reanchors pet after layout")
has(stanceInit, "STANCE_ANCHOR_GAP = -4", "stance player-dock gap matches backup")
has(stanceInit, "STANCE_WINDOW_GAP_Y", "stance window Y gap")
has(stanceLayout, "clusterV", "stance metrics expose clusterV")
has(stanceLayout, "innerH", "stance metrics expose innerH")
has(stanceLayout, "matchPetTotalH", "detached stance height matches pet bar")
has(stanceForms, "AttachReorderControls", "stance left-drag reorder")
has(stanceForms, "G.NotifySAO", "stance extras register with SAO")
do
	local i = stanceLayout:find("function Stance.Anchor", 1, true)
	local j = i and stanceLayout:find("\nfunction Stance.", i + 10, true)
	local body = (i and j and stanceLayout:sub(i, j - 1)) or (i and stanceLayout:sub(i)) or ""
	has(body, 'SetPoint("TOPRIGHT", wf, "TOPLEFT"', "stance detached TOPRIGHT to Flux Window")
	has(body, "STANCE_WINDOW_GAP_Y", "stance detached uses window Y gap")
	if body:find("FluxActionStrip", 1, true) then
		failures[#failures + 1] = "stance detached must not pin to FluxActionStrip"
	end
end
do
	local i = petInit:find("function Pet.UpdatePosition", 1, true)
	local j = i and petInit:find("\nfunction Pet.", i + 10, true)
	local body = (i and j and petInit:sub(i, j - 1)) or (i and petInit:sub(i)) or ""
	has(petInit, "UsePetBarDetachedStanceLayout", "pet uses detached-stance layout helper")
	has(body, 'SetPoint("TOPRIGHT", windowFrame, "TOPLEFT"', "pet TOPRIGHT to Flux Window TOPLEFT")
	if body:find("FluxActionStrip", 1, true) then
		failures[#failures + 1] = "pet must not pin to FluxActionStrip"
	end
	if not petInit:find("not UsePetBarDetachedStanceLayout()", 1, true) then
		failures[#failures + 1] = "pet pos1 must not follow player-docked stance"
	end
end
has(stanceExtras, "InvalidateExtras", "stance extras cache invalidate")
has(stanceExtras, "mageArmorIds", "stance mage armor id cache")
has(stanceExtras, "spell_nature_wispsplode", "stance extra wisp icon")
has(stanceExtras, "GetConditionalIcon", "stance wisp prefers engine conditional icon")
has(stanceExtras, "PruneFrostIfIceKnown", "stance prune Frost when Ice known")
has(stanceExtras, "ApplyExtraActiveVisual", "stance extra active visual")
has(stanceExtras, "IdsMatch", "stance armor matches ranks by spell id")
has(stanceExtras, "function Stance.IsMageArmorSpell", "stance identifies mage armor form spells")
has(stanceExtras, "ArmorPollSignature", "stance armor poll signature is secret-safe")
has(stanceExtras, "lastArmor", "stance holds last-known mage armor through combat")
has(stanceExtras, "function Stance.NoteMageArmorCast", "stance notes mage armor from cast success")
has(stanceExtras, "AurasRestricted", "stance combat aura hold uses AurasRestricted")
has(stanceExtras, "GetAuraDuration", "stance refreshes held armor from duration object")
has(stanceExtras, "MergeHeldArmor", "stance keeps public armor times when combat secretes them")
has(stanceExtras, "FluxStanceManagedCooldown", "stance mage armor buff cooldown")
has(stanceExtras, "StanceBuffDurationObject", "stance mage armor can use a duration object")
has(stanceExtras, "EnsureAuraCountdown", "stance mage armor uses owned countdown text")
has(stanceExtras, "FormatAuraRemain", "stance aura countdown matches SecondsToTimeAbbrev")
has(stanceExtras, "if rem >= 90 then", "stance seconds use the same 90s abbrev threshold as auras")
has(stanceExtras, "math.floor(rem + 1e-6)", "stance second digit truncates like buff %d")
has(stanceExtras, "StanceBuffExpirationTime", "stance countdown uses aura expirationTime")
has(stanceExtras, "GetCooldownDisplayDuration", "stance digits can follow cooldown aura display time")
has(stanceExtras, "AuraCountdownSetText", "stance aura countdown never SetText before font")
has(stanceExtras, "NumberFontNormalSmall", "stance aura countdown inherits a font object")
has(stanceExtras, "_fluxStanceAuraText", "stance mage armor countdown fontstring")
has(stanceExtras, "noCooldownCount", "stance mage armor hides blizzard/OmniCC digits")
has(stanceExtras, "SyncAuraCountdown", "stance mage armor countdown sync")
has(stanceExtras, "ExpandSummonDemonFlyout", "stance expands Summon Demon flyout")
has(stanceExtras, "FlyoutSlotCastID", "stance flyout slots use override-preferred id")
has(stanceExtras, "IsSummonDemonFlyout", "stance detects Summon Demon flyout")
has(stanceExtras, "added > 0", "foundFlyout only if inner spells were added")
has(stanceForms, 'SetAction(btn, "spell"', "stance extras stay type=spell")
if stanceExtras:find('SetAction(btn, "flyout"', 1, true) then
	failures[#failures + 1] = "stance extras must not SetAction flyout"
end
do
	local k = stanceExtras:find("WARLOCK_SUMMON_IDS[i][1]", 1, true)
	local before = k and stanceExtras:sub(math.max(1, k - 160), k) or ""
	if not before:find("if not foundFlyout then", 1, true) then
		failures[#failures + 1] = "WARLOCK_SUMMON_IDS must be fallback-only when flyout added nothing"
	end
end
has(ebsPaint, "FluxStanceManagedCooldown", "EBS paints stance-managed buff cooldown")
has(ebsPaint, "StanceBuffDurationObject", "EBS paints stance aura duration object")
has(ebsPaint, "SetUseAuraDisplayTime", "EBS stance aura swipe uses aura display time")
has(ebsPaint, "SetCooldownFromExpirationTime", "EBS stance aura swipe can use expirationTime")
has(ebsPaint, "expirationTime = btn.StanceBuffExpirationTime", "EBS passes aura expiration into Charges")
has(ebsPaint, "modRate = btn.StanceBuffTimeMod", "EBS passes aura timeMod into Charges")
has(ebsPaint, "ACTION_BUTTON_SWIPE_A = 0.64", "stance aura swipe matches action-button overlay alpha")
has(ebsPaint, "ApplyStanceAuraSwipeLook", "stance aura swipe is applied after Charges tint")
has(ebsPaint, "skipDurationObject = not btn.StanceBuffDurationObject", "EBS skips GCD duration object unless an aura object exists")
has(stanceOrder, "stanceBarSlotOrder", "stance char order")
has(stanceOrder, "stanceBarHiddenSlots", "stance char hide")
has(stanceOrder, "stanceBarCustomSlots", "stance char custom slots")
has(stanceOrder, "function Stance.AddCustomFromCursor", "stance add from cursor")
has(stanceOrder, "function Stance.RemoveCustomSlot", "stance remove custom slot")
has(stanceOrder, "function Stance.ReplaceCustomSpellId", "stance custom spells can change rank")
has(stanceOrder, "FluxNCUtilitySlots", "stance add uses utility cursor parse")
has(stanceOrder, "custom:", "stance custom slot keys")
has(stanceLayout, "ShouldShowCustom", "stance layout can hide a duplicate custom")
has(stanceForms, "data.custom", "stance custom rows keep their action type")
has(stanceForms, 'actionType == "macro"', "stance custom macros pass the macro name")
has(stanceExtras, "function Stance.CustomTrackSpell", "stance custom buff tracking")
has(stanceExtras, "CustomRestingIcon", "stance custom slots keep the placed spell icon")
has(stanceExtras, "PlayerIsCastingSpell", "stance cast does not swap in the wisp")
has(stanceExtras, "Wisp only while this spell's buff is up", "stance custom buff uses the wisp")
has(stanceForms, "_fluxExactSpell", "stance custom spell buttons opt out of base-spell rewrite")
has(read("../ExtraButtonSystem/Engine/Action.lua"), "_fluxExactSpell", "exact stance spells skip GetBaseSpell")
has(stanceExtras, "function Stance.NoteCustomCast", "stance custom cast hold")
has(stanceExtras, "TryCustomAura", "stance custom aura lookup")
has(stanceExtras, "permanent", "stance custom toggle aura has no timer")
has(stanceExtras, "lastCustom", "stance custom aura hold is per spell")
has(stanceExtras, "Flux.Spell.IsCurrent", "stance custom toggle uses IsCurrent")
has(stanceExtras, "data.custom", "stance custom visual is separate from summons")
has(stanceWatch, "NoteCustomCast", "stance cast success notes custom buffs")
has(stanceWatch, "ACTIONBAR_UPDATE_STATE", "stance toggle refresh is visual-only")
has(stanceWatch, "IsTrackedCustomSpell", "stance cast of a custom spell repaints")
do
	local i = stanceWatch:find('Ev.Register("ACTIONBAR_UPDATE_STATE"', 1, true)
	local body = i and stanceWatch:sub(i, i + 280) or ""
	if body:find("RequestLayout", 1, true) or body:find("RequestDiscover", 1, true) then
		failures[#failures + 1] = "stance ACTIONBAR_UPDATE_STATE must not rebuild layout"
	end
	if not body:find("RequestExtrasVisual", 1, true) then
		failures[#failures + 1] = "stance ACTIONBAR_UPDATE_STATE must extras visual"
	end
end
local stancePanel = read("../AddonOptions/AceGUIWidget-FluxStanceBarOrderPanel.lua")
has(stancePanel, "Right-click remove.", "stance options remove custom slots")
has(stancePanel, "Right-click hide/show.", "stance options still hide built-in slots")
has(stancePanel, "RemoveCustomSlot", "stance options calls remove")
has(stancePanel, "ToggleStanceSlotHidden", "stance options still toggles hide")
has(stancePanel, "AddCustomFromCursor", "stance options drop adds a slot")
has(read("../AddonOptions/FluxOptionsActionBars_Stance.lua"), "Right-click remove added", "stance sub-tab describes remove")
local respecBars = read("../Respec/FluxRespec_ActionBars.lua")
has(respecBars, "stanceCustomSlots", "respec snapshots custom stance slots")
has(respecBars, "SetSavedCustomSlots", "respec applies custom stance slots")
has(respecBars, "CustomListsEqual", "respec matches custom stance slots")
has(respecBars, "function ActionBars.RewriteStanceSpellId", "respec stance snapshot can change spell rank")
has(respecBars, "function ActionBars.RewriteSavedStanceSpellId", "respec profiles follow stance rank-up")
has(read("../Respec/FluxRespec_UI.lua"), "stanceCustomSlots", "respec bars summary counts added slots")
has(read("../Respec/FluxRespec_UI.lua"), "%d added", "respec bars summary names added slots")
has(stanceForms, "shapeshift", "stance form Extra Buttons")
has(stanceForms, "StanceButtonTemplate", "stance hidden donors")
has(stanceForms, "TagFormArmor", "stance tags mage-armor form buttons")
has(stanceForms, "_fluxStanceMageArmorForm", "stance form mage-armor flag")
has(stanceForms, "ApplyExtraActiveVisual", "stance form mage armor uses extra active visual")
has(stanceLayout, "TagFormArmor", "stance layout tags mage-armor forms")
has(stanceLayout, "_fluxStanceMageArmorForm", "stance layout paints mage-armor form visuals")
if stanceForms:find("Right-click to hide", 1, true) then
	failures[#failures + 1] = "stance extra must not right-click hide"
end
if stanceForms:find('button ~= "RightButton"', 1, true) then
	failures[#failures + 1] = "stance extra must not hide on right click"
end
has(stanceLayout, "ApplyHiddenToShouldShow", "stance layout honors saved hidden keys")
has(stanceLayout, "_fluxStanceButtonSize = size", "stance layout stamps live button size")
has(stanceLayout, "SetSize(native, native)", "stance widgets stay native Extra Button size")
has(stanceLayout, "size / native", "stance visual size is widget SetScale")
has(stanceLayout, "EnsureSlot", "stance packs a visual SlotFrame like Extra Buttons")
has(stanceLayout, 'SetPoint("CENTER", slot, "CENTER"', "stance widget is centered in the SlotFrame")
has(stanceLayout, "slot:SetSize(size, size)", "stance SlotFrame is live button_size")
if stanceLayout:find("ov.SyncSize", 1, true) then
	failures[#failures + 1] = "stance must not Overlay.SyncSize"
end
has(stanceForms, "size = native", "stance Extra Buttons create at native 44")
do
	local i = ebsPaint:find("function Paint.UpdateCooldown", 1, true) or ebsPaint:find("ApplyButtonCountdownScale", 1, true)
	local body = ebsPaint
	local a = ebsPaint:find("cd._fluxForceDigitScale = true", 1, true)
	local b = ebsPaint:find("local ApplyStanceBuffCountdownScale", 1, true)
	body = (a and b and ebsPaint:sub(a, b - 1)) or ""
	if body:find("_fluxStanceButtonSize", 1, true) then
		failures[#failures + 1] = "countdown must use GetWidth, not stance visual size"
	end
	has(body, "widget.GetWidth", "countdown follows Extra Button GetWidth")
end
has(ebsPaint, "IconOverrideTexture", "EBS paints icon override")
has(ebsPaint, "StanceActiveVisual", "EBS stance active checked")
has(ebsPaint, "stanceActive", "stance active checked is not cleared by GCD/cast")
has(ebsPaint, "_fluxForceDigitScale", "stance mage armor digits keep scale after CooldownFrame_Set")
has(ebsPaint, "ApplyButtonCountdownScale", "all extra buttons scale countdown to the widget")
has(stanceInit, "COOLDOWN_COUNTDOWN_SIZE_FACTOR", "stance countdown size factor")
has(stanceInit, "COOLDOWN_COUNTDOWN_FONT_RATIO", "stance countdown font tracks button size")
local ebsUtil = readEbs("Engine/Util.lua")
has(ebsUtil, "_fluxForceDigitScale", "digit-scale watcher is not square-gated")
has(ebsUtil, "_fluxCountdownFontPx", "extra button countdown uses pixel font")
has(ebsUtil, "SetCountdownFont", "extra button countdown sets countdown font")
has(ebsUtil, "Style.SizeRing", "Util ring size delegates to Style.SizeRing")
do
	local i = ebsUtil:find("local function IsPreDragonflight()", 1, true)
	local j = ebsUtil:find("local PRE_DF_RING_BORDER_SCALE", 1, true)
	local body = (i and j and ebsUtil:sub(i, j - 1)) or ""
	if not body:find("isPreDF", 1, true) and not body:find("isPostDF", 1, true) then
		failures[#failures + 1] = "Util IsPreDragonflight must use isPreDF / isPostDF"
	end
	if body:find("return majorVersion < 10", 1, true) then
		failures[#failures + 1] = "Util IsPreDragonflight must not use majorVersion < 10 (Forever is 1.x)"
	end
end
has(stanceExtras, "UnitBuff", "stance armor scan includes UnitBuff")
has(stanceExtras, "NormalizeArmor", "stance armor remaining drops when expired")
has(stanceExtras, "ArmorCooldownTimes", "stance armor cooldown uses live remaining")
has(stanceForms, "_armorPollQueued", "stance armor remaining polls while the buff is up")
if stanceExtras:find("elseif not active and btn.StanceActiveVisual", 1, true) then
	failures[#failures + 1] = "stance armor must not keep stale visual when the buff is gone"
end
do
	local i = stanceWatch:find("local function ArmorVisual", 1, true)
	local body = i and stanceWatch:sub(i, i + 280) or ""
	if not body:find("RequestExtrasVisual", 1, true) then
		failures[#failures + 1] = "stance UNIT_AURA must extras visual"
	end
	if not body:find("RequestFormsVisual", 1, true) then
		failures[#failures + 1] = "stance UNIT_AURA must form visual for mage armor"
	end
	local j = stanceWatch:find('RegisterUnit("UNIT_AURA"', 1, true)
	local snippet = j and stanceWatch:sub(j, j + 480) or ""
	if snippet:find("RequestLayout", 1, true) or snippet:find("RequestDiscover", 1, true) then
		failures[#failures + 1] = "stance UNIT_AURA must not rebuild layout"
	end
	if not snippet:find("ArmorVisual", 1, true) then
		failures[#failures + 1] = "stance UNIT_AURA must extras visual"
	end
end
if petInit:find("FluxPetBarVFX", 1, true) or stanceInit:find("FluxPetBarVFX", 1, true) then
	failures[#failures + 1] = "pet/stance must not port FluxPetBarVFX"
end
do
	local texDir = dir .. "/../Texture/"
	local unused = { "FluxPetBarVFX.tga", "FluxStanceBarVFX.tga" }
	for i = 1, #unused do
		local f = io.open(texDir .. unused[i], "rb")
		if f then
			f:close()
		end
	end
end
local petApi = readCore("API/Pet.lua")
has(petApi, "function Pet.GetActionInfo", "Pet.GetActionInfo")
has(petApi, "function Pet.GetActionCooldown", "Pet.GetActionCooldown")
has(petApi, "GetPetActionsUsable", "Pet.IsSlotUsable fallback")
local formApi = readCore("API/Shapeshift.lua")
has(formApi, "function Shapeshift.GetNumForms", "Shapeshift.GetNumForms")
has(formApi, "function Shapeshift.GetFormInfo", "Shapeshift.GetFormInfo")
has(formApi, "function Shapeshift.GetFormCooldown", "Shapeshift.GetFormCooldown")
has(formApi, "function Shapeshift.MatchesActiveForm", "Shapeshift.MatchesActiveForm")
has(formApi, "IdsMatch", "active form match uses Spell.IdsMatch")
if formApi:find("WispSpellIds", 1, true) then
	failures[#failures + 1] = "Shapeshift must not use a WispSpellIds table"
end

has(ebsPaint, "AssistedNextSpellId", "EBS stores next-cast id")
has(ebsPaint, "GetAssistantNextSpell", "EBS paints from next-cast")
has(ebsWatch, "SyncAssistantTicker", "EBS assistant ticker")
has(ebsWatch, "GetUpdateRate", "EBS uses AssistedCombatManager rate")
has(ebsWatch, "assistedCombatIconUpdateRate", "EBS CVar update rate")
has(ebsWatch, "UNIT_SPELLCAST_SUCCEEDED", "EBS paints assistant on cast success")
has(ebsWatch, "RotationSpellsUpdated", "EBS listens for rotation updates")
if ebsWatch:find("not InCombat()", 1, true) then
	failures[#failures + 1] = "EBS assistant ticker must poll whenever an assistant button exists"
end
has(watchSrc, "SyncAssistantTicker", "strip assistant ticker")
has(watchSrc, "PaintAssistedHosts", "strip assistant tick paints next-cast")
has(watchSrc, "PaintAssistedHighlights", "strip assistant tick paints highlight")
has(watchSrc, "IsAssistedHighlightActive", "strip ticker arms for assist highlight")
has(watchSrc, "OnAssistedHighlightSpellChange", "strip listens for highlight spell")
has(watchSrc, "OnSetUseAssistedHighlight", "strip listens for highlight CVar")
has(watchSrc, "UNIT_SPELLCAST_SUCCEEDED", "strip paints assistant on cast success")
has(castSrc, "GetAssistedNextSpell", "Cast SpellIdFromAction uses next-cast")
has(castSrc, "ResolveProgramShownSpell", "Cast/glow follow slot-program conditionals")
has(castSrc, "PF.ShownForSlot", "Cast/glow follow Extra live identity")
has(glowSrc, "AssistedCombatRotation", "Glow OneButton assisted type")
has(glowSrc, "OneButton_ProcStart_Flipbook", "Glow OneButton start atlas")
has(glowSrc, "_fluxAssistedCombat", "Glow EBS assistant host")
has(overlaySrc, "_fluxAssistedCombat", "Overlay skips reticle on EBS assistant")
has(castSrc, "AssistedNextSpellId", "Cast follows next-cast id")
do
	local function forbidTrue(src, label)
		if src:find("GetNextCastSpell(true)", 1, true) or src:find("GetNextCastSpell, true", 1, true) then
			failures[#failures + 1] = label .. " must not GetNextCastSpell(true)"
		end
	end
	forbidTrue(ebsAction, "EBS Action")
	forbidTrue(ebsPaint, "EBS Paint")
	forbidTrue(ebsWatch, "EBS Watch")
	forbidTrue(paint, "Bars Paint")
	forbidTrue(watchSrc, "Bars Watch")
	forbidTrue(glowSrc, "Glow")
	forbidTrue(overlaySrc, "Overlay")
	forbidTrue(castSrc, "Cast")
	do
		local i = actionSrc:find("function Action.GetAssistedHighlightSpell", 1, true)
		local j = i and actionSrc:find("\nfunction Action.", i + 1, true)
		local body = (i and j and actionSrc:sub(i, j - 1)) or ""
		has(body, "GetNextCastSpell, true", "highlight-mode next-cast uses true")
		local rest = actionSrc
		if i and j then
			rest = actionSrc:sub(1, i - 1) .. actionSrc:sub(j)
		end
		forbidTrue(rest, "Action API")
	end
end
local bindingsSrc
do
	local f = io.open(dir .. "/../Bindings.xml", "r")
	if f then
		bindingsSrc = f:read("*a")
		f:close()
	else
		bindingsSrc = ""
	end
end
has(bindingsSrc, "FLUX_ASSISTED_COMBAT", "FLUX_ASSISTED_COMBAT binding")
has(bindingsSrc, "ExtraButtonSystem/Engine/Action.lua", "assistant bind points at live Action.lua")

local watch = read("Watch.lua")
has(watch, 'Ev.Register("SPELL_UPDATE_CHARGES"', "charges event")
has(watch, "ACTIONBAR_PAGE_CHANGED", "page change paints checked")
has(watch, "SweepFluxFromCollectors", "combat enter vacuums Flux widgets off collectors")
has(watch, "RightManagedFrameContainer:SetSize", "vehicle apply stays off the enter stack")
has(watch, "UPDATE_BONUS_ACTIONBAR", "bonus bar paints checked")
do
	local i = watch:find('Ev.Register("PLAYER_REGEN_ENABLED"', 1, true)
	local body = i and watch:sub(i, i + 450) or ""
	if body:find("ForceApply", 1, true) then
		failures[#failures + 1] = "PLAYER_REGEN_ENABLED must not ForceApply (Combat.Defer bars.state already flushes)"
	end
	has(body, "RequestCond", "regen still refreshes [combat] cond")
end
do
	local i = watch:find("SPELL_UPDATE_CHARGES", 1, true)
	local snippet = i and watch:sub(i, i + 400) or ""
	if not snippet:find("bars.cooldown", 1, true) then
		failures[#failures + 1] = "SPELL_UPDATE_CHARGES must dirty cooldown"
	end
	if not snippet:find("bars.count", 1, true) then
		failures[#failures + 1] = "SPELL_UPDATE_CHARGES must dirty count"
	end
	if not snippet:find("bars.usable", 1, true) then
		failures[#failures + 1] = "SPELL_UPDATE_CHARGES must dirty usable"
	end
end
do
	local i = watch:find('Ev.Register("MODIFIER_STATE_CHANGED"', 1, true)
	local j = i and watch:find("Ev.Register(", i + 10, true)
	local body = (i and j and watch:sub(i, j - 1)) or ""
	has(body, "bars.hotkey", "MODIFIER_STATE_CHANGED paints bars.hotkey")
	has(body, "bars.dirty", "one modifier paint flushes every swapped host")
	has(body, "bars.count", "SHIFT/CTRL re-paints count")
	has(body, "bars.cooldown", "SHIFT/CTRL re-paints cooldown")
	if body:find("bars.icon", 1, true) or body:find("bars.usable", 1, true)
		or body:find("bars.checked", 1, true)
	then
		failures[#failures + 1] = "MODIFIER_STATE_CHANGED must not 6-lane paint (ButtonForge RefConditional only)"
	end
	if body:find("RequestLayout(", 1, true) or body:find("Bars.Layout.Request", 1, true) then
		failures[#failures + 1] = "MODIFIER_STATE_CHANGED must not RequestLayout"
	end
end
do
	local i = watch:find('Ev.Register("UPDATE_BINDINGS"', 1, true)
	local j = i and watch:find("Ev.Register(", i + 10, true)
	local body = (i and j and watch:sub(i, j - 1)) or ""
	has(body, "bars.hotkey", "UPDATE_BINDINGS paints bars.hotkey")
end
do
	local i = watch:find('Flux.Inventory.Register("bars"', 1, true)
	local j = i and watch:find("if Bars.Effects", i, true)
	local body = (i and j and watch:sub(i, j)) or ""
	has(body, "bars.count", "bag pulse re-paints count")
	has(body, "bars.usable", "bag pulse re-paints usable so 0 stacks dim in combat")
	has(body, "sync = true", "first stack paints on the bag frame, not the heavy queue")
end

-- Backup mouse / scroll / space hotkey glyphs (no WoW UI)
do
	local fn, err = loadfile(coreDir .. "/Hotkey.lua")
	if not fn then
		failures[#failures + 1] = "load Hotkey.lua: " .. tostring(err)
	else
		local ns = { Flux = {} }
		fn("_FluxUI", ns)
		local H = ns.Flux.Hotkey
		if not H or not H.Format or not H.Path then
			failures[#failures + 1] = "Flux.Hotkey API missing"
		else
			local function expectIcon(key, file, label)
				local display, isIcon = H.Format(key)
				if not isIcon or type(display) ~= "string" or not display:find(file, 1, true) then
					failures[#failures + 1] = label
				end
			end
			expectIcon("BUTTON3", "MouseButton3.tga", "BUTTON3 uses MouseButton3")
			expectIcon("BUTTON4", "MouseButton4.tga", "BUTTON4 uses MouseButton4")
			expectIcon("BUTTON5", "MouseButton5.tga", "BUTTON5 uses MouseButton5")
			expectIcon("MOUSEWHEELUP", "MouseScrollUp.tga", "wheel up glyph")
			expectIcon("MOUSEWHEELDOWN", "MouseScrollDown.tga", "wheel down glyph")
			expectIcon("WU", "MouseScrollUp.tga", "WU short glyph")
			expectIcon("WD", "MouseScrollDown.tga", "WD short glyph")
			expectIcon("SPACE", "SpaceBarButton.tga", "space glyph")
			expectIcon("Sp", "SpaceBarButton.tga", "Sp short glyph")
			expectIcon("SHIFT-BUTTON3", "MouseButton3.tga", "SHIFT-BUTTON3 stays a mouse glyph")
			local texDir = dir .. "/../Texture/"
			local files = {
				"MouseButton3.tga", "MouseButton4.tga", "MouseButton5.tga",
				"MouseScrollUp.tga", "MouseScrollDown.tga", "SpaceBarButton.tga",
			}
			for i = 1, #files do
				local f = io.open(texDir .. files[i], "rb")
				if not f then
					failures[#failures + 1] = "missing Texture/" .. files[i]
				else
					f:close()
				end
			end
		end
	end
end

-- Glow.Transfer / skipBirth / SyncColumn (no WoW UI)
do
	local glowFn, glowErr = loadfile(coreDir .. "/ButtonFX/Glow.lua")
	if not glowFn then
		failures[#failures + 1] = "load Glow.lua: " .. tostring(glowErr)
	else
		local gns = { Flux = {} }
		glowFn("FluxUI", gns)
		local Glow = gns.Flux.ButtonFX and gns.Flux.ButtonFX.Glow
		if not Glow or not Glow.Transfer or not Glow.Set or not Glow.IsLive then
			failures[#failures + 1] = "Glow API missing Transfer/Set/IsLive"
		else
			local overlay = {
				shown = true,
				ProcLoopFlipbook = true,
				startAnim = true,
				ProcStartAnim = {
					IsPlaying = function()
						return true
					end,
					Stop = function(self)
						self.stopped = true
					end,
				},
				ProcLoop = {
					playing = true,
					IsPlaying = function(self)
						return self.playing
					end,
					Play = function(self)
						self.played = true
						self.playing = true
					end,
				},
				SetParent = function(self, host)
					self.parent = host
				end,
				ClearAllPoints = function() end,
				SetSize = function(self, w, h)
					self.sw, self.sh = w, h
				end,
				SetPoint = function() end,
				SetFrameLevel = function() end,
				Show = function(self)
					self.shown = true
				end,
				Hide = function(self)
					self.hidden = true
					self.shown = false
				end,
				IsShown = function(self)
					return self.shown
				end,
			}
			local from = {
				_fluxProcAlert = overlay,
				_fluxGlowSpell = 100,
				GetWidth = function()
					return 36
				end,
				GetHeight = function()
					return 36
				end,
				GetFrameLevel = function()
					return 1
				end,
			}
			local to = {
				GetWidth = function()
					return 40
				end,
				GetHeight = function()
					return 40
				end,
				GetFrameLevel = function()
					return 3
				end,
			}
			if not Glow.Transfer(from, to) then
				failures[#failures + 1] = "Glow.Transfer should succeed"
			else
				if overlay.parent ~= to then
					failures[#failures + 1] = "Transfer reparents overlay"
				end
				if from._fluxProcAlert ~= nil then
					failures[#failures + 1] = "Transfer clears source overlay ref"
				end
				if to._fluxProcAlert ~= overlay then
					failures[#failures + 1] = "Transfer assigns dest overlay"
				end
				if overlay.startAnim ~= false then
					failures[#failures + 1] = "Transfer sets startAnim false"
				end
				if overlay.hidden then
					failures[#failures + 1] = "Transfer must not Hide live overlay"
				end
				if not overlay.ProcStartAnim.stopped then
					failures[#failures + 1] = "Transfer stops ProcStartAnim"
				end
				if overlay.sw ~= (40 * 1.4) then
					failures[#failures + 1] = "Transfer sizes overlay 1.4x dest"
				end
			end
			local skipArg = "unset"
			local created
			local savedCreate = _G.CreateFrame
			_G.ActionButtonSpellAlertManager = {
				ShowAlert = function(_, _, skipBirth)
					skipArg = skipBirth
				end,
				HideAlert = function() end,
				activeAlerts = {},
			}
			_G.CreateFrame = function(_, _, parent, template)
				created = {
					template = template,
					parent = parent,
					shown = false,
					ProcLoopFlipbook = {},
					ProcStartAnim = {
						played = false,
						Play = function(self)
							self.played = true
						end,
						Stop = function() end,
					},
					ProcLoop = {
						looped = false,
						Play = function(self)
							self.looped = true
						end,
						Stop = function() end,
						IsPlaying = function()
							return false
						end,
					},
					Show = function(self)
						self.shown = true
					end,
					Hide = function(self)
						self.shown = false
					end,
					IsShown = function(self)
						return self.shown
					end,
					EnableMouse = function() end,
					SetAllPoints = function() end,
					SetParent = function(self, host)
						self.parent = host
					end,
					ClearAllPoints = function() end,
					SetSize = function() end,
					SetPoint = function() end,
					SetFrameLevel = function() end,
				}
				return created
			end
			local fresh = {
				GetWidth = function()
					return 36
				end,
				GetHeight = function()
					return 36
				end,
				GetFrameLevel = function()
					return 1
				end,
			}
			Glow.Set(fresh, true, true)
			if skipArg ~= "unset" then
				failures[#failures + 1] = "Glow.Set must not call manager ShowAlert"
			end
			if not created or created.template ~= "ActionButtonSpellAlertTemplate" then
				failures[#failures + 1] = "Glow.Set creates ActionButtonSpellAlertTemplate"
			end
			if not created or not created.ProcLoop.looped then
				failures[#failures + 1] = "skipBirth plays ProcLoop"
			end
			if created and created.ProcStartAnim.played then
				failures[#failures + 1] = "skipBirth must not Play ProcStart"
			end
			do
				local savedTex = _G.C_Texture
				_G.C_Texture = {
					GetAtlasInfo = function()
						return nil
					end,
				}
				created = nil
				local noAtlas = {
					GetWidth = function()
						return 36
					end,
					GetHeight = function()
						return 36
					end,
					GetFrameLevel = function()
						return 1
					end,
				}
				Glow.Set(noAtlas, true, true)
				if not created or created.template ~= "ActionButtonSpellAlertTemplate" then
					failures[#failures + 1] = "Glow.Set without proc atlas still paints template"
				end
				if not created or not created.ProcLoop.looped then
					failures[#failures + 1] = "skipBirth plays ProcLoop without proc atlas"
				end
				_G.C_Texture = savedTex
			end
			created = nil
			Glow.Set(to, true, false)
			if skipArg ~= "unset" then
				failures[#failures + 1] = "Set on live overlay must no-op"
			end
			if created then
				failures[#failures + 1] = "Set on live overlay must not CreateFrame"
			end
			local fresh2 = {
				GetWidth = function()
					return 36
				end,
				GetHeight = function()
					return 36
				end,
				GetFrameLevel = function()
					return 1
				end,
			}
			Glow.Set(fresh2, true, false)
			if skipArg ~= "unset" then
				failures[#failures + 1] = "Glow.Set must not call manager ShowAlert (birth)"
			end
			if not created or not created.ProcStartAnim.played then
				failures[#failures + 1] = "new glow plays ProcStart"
			end
			if created and created.ProcLoop.looped then
				failures[#failures + 1] = "new glow must not skip to ProcLoop"
			end
			_G.CreateFrame = savedCreate
			if not Glow.InstallSAO or not Glow.NotifySAO or not Glow.SaoMembership then
				failures[#failures + 1] = "Glow SAO API missing"
			else
				local stub = {}
				Glow.InstallSAO(stub)
				if not stub.__sao or stub.__sao.useExternalGlow ~= true then
					failures[#failures + 1] = "InstallSAO must set useExternalGlow"
				end
				if type(stub.__sao.EnableGlow) ~= "function" then
					failures[#failures + 1] = "InstallSAO EnableGlow"
				end
				_G.SpellActivationOverlayAddon = {
					AddGlow = function() end,
					AddGlowNumber = function() end,
					RemoveGlow = function() end,
					GlowingSpells = {},
				}
				Glow.Start()
				_G.SpellActivationOverlayAddon:AddGlowNumber(1, 5555)
				if not Glow.Want(5555) then
					failures[#failures + 1] = "Want must follow hooked AddGlowNumber"
				end
				_G.SpellActivationOverlayAddon = { GlowingSpells = { [4242] = { [1] = true } } }
				if not Glow.Want(4242) then
					failures[#failures + 1] = "Want must follow SAO GlowingSpells"
				end
				if Glow.Want(99) then
					failures[#failures + 1] = "Want must not glow an unknown spell"
				end
				_G.SpellActivationOverlayAddon = nil
			end
			if _G.FluxEffectGlow ~= Glow then
				failures[#failures + 1] = "FluxEffectGlow alias"
			end
		end
	end
end

-- Sticky GLOW_SHOW / LBG hide-after-macro-flip must not pin Want on every copy.
do
	local savedLibStub = _G.LibStub
	local savedSAO = _G.SpellActivationOverlayAddon
	local savedISO = _G.C_SpellActivationOverlay
	local glowFn, glowErr = loadfile(coreDir .. "/ButtonFX/Glow.lua")
	if not glowFn then
		failures[#failures + 1] = "load Glow.lua (membership): " .. tostring(glowErr)
	else
		local handlers = {}
		local lbg = {
			ShowOverlayGlow = function() end,
			HideOverlayGlow = function() end,
		}
		_G.LibStub = function(name)
			if name == "LibButtonGlow-1.0" then
				return lbg
			end
			return nil
		end
		_G.SpellActivationOverlayAddon = nil
		local gns = {
			Flux = {
				Client = { isPreDF = true, isAnyClassic = true },
				Events = {
					Register = function(ev, fn)
						if type(ev) ~= "string" or type(fn) ~= "function" then
							return
						end
						local t = handlers[ev]
						if not t then
							t = {}
							handlers[ev] = t
						end
						t[#t + 1] = fn
					end,
				},
				ButtonFX = {},
			},
		}
		glowFn("FluxUI", gns)
		local Glow = gns.Flux.ButtonFX and gns.Flux.ButtonFX.Glow
		local function fire(ev, ...)
			local t = handlers[ev]
			if not t then
				return
			end
			for i = 1, #t do
				t[i](nil, ...)
			end
		end
		if not Glow or not Glow.Start or not Glow.Want then
			failures[#failures + 1] = "Glow membership API missing"
		else
			Glow.Start()
			fire("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 888)
			if not Glow.Want(888) then
				failures[#failures + 1] = "GLOW_SHOW without SAO is native membership"
			end
			fire("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", 888)
			if Glow.Want(888) then
				failures[#failures + 1] = "GLOW_HIDE clears native membership"
			end
			_G.SpellActivationOverlayAddon = {
				AddGlow = function() end,
				AddGlowNumber = function() end,
				RemoveGlow = function() end,
				GlowingSpells = {},
			}
			fire("ADDON_LOADED", "SpellActivationOverlay")
			fire("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", 777)
			if Glow.Want(777) then
				failures[#failures + 1] = "sticky GLOW_SHOW must not Want when SAO owns hide"
			end
			_G.SpellActivationOverlayAddon:AddGlowNumber(1, 777)
			if not Glow.Want(777) then
				failures[#failures + 1] = "Want follows AddGlowNumber after SHOW"
			end
			_G.SpellActivationOverlayAddon:RemoveGlow(1)
			if Glow.Want(777) then
				failures[#failures + 1] = "Want must clear after RemoveGlow despite sticky SHOW"
			end
			local glowId = 111
			local frame = {
				__sao = {
					GetGlowID = function()
						return glowId
					end,
				},
			}
			lbg.ShowOverlayGlow(frame)
			if not Glow.Want(111) then
				failures[#failures + 1] = "LBG show counts membership"
			end
			if frame._fluxLbgGlowSpell ~= 111 then
				failures[#failures + 1] = "LBG show stamps glow spell"
			end
			glowId = 222
			lbg.HideOverlayGlow(frame)
			if Glow.Want(111) then
				failures[#failures + 1] = "LBG hide must decrement the stamped show id"
			end
			if Glow.Want(222) then
				failures[#failures + 1] = "LBG hide must not decrement the flipped macro face"
			end
		end
	end
	_G.LibStub = savedLibStub
	_G.SpellActivationOverlayAddon = savedSAO
	_G.C_SpellActivationOverlay = savedISO
end

do
	local savedISO = _G.C_SpellActivationOverlay
	local glowFn, glowErr = loadfile(coreDir .. "/ButtonFX/Glow.lua")
	if not glowFn then
		failures[#failures + 1] = "load Glow.lua (ISO): " .. tostring(glowErr)
	else
		local handlers = {}
		_G.C_SpellActivationOverlay = {
			IsSpellOverlayed = function()
				return false
			end,
		}
		local gns = {
			Flux = {
				Events = {
					Register = function(ev, fn)
						if type(ev) ~= "string" or type(fn) ~= "function" then
							return
						end
						local t = handlers[ev]
						if not t then
							t = {}
							handlers[ev] = t
						end
						t[#t + 1] = fn
					end,
				},
				ButtonFX = {},
			},
		}
		glowFn("FluxUI", gns)
		local Glow = gns.Flux.ButtonFX and gns.Flux.ButtonFX.Glow
		if not Glow or not Glow.Start or not Glow.Want then
			failures[#failures + 1] = "Glow ISO API missing"
		else
			Glow.Start()
			local t = handlers["SPELL_ACTIVATION_OVERLAY_GLOW_SHOW"]
			if t then
				for i = 1, #t do
					t[i](nil, 999)
				end
			end
			if not Glow.Want(999) then
				failures[#failures + 1] = "IsSpellOverlayed false must keep sticky GLOW_SHOW"
			end
		end
	end
	_G.C_SpellActivationOverlay = savedISO
end

-- Era 2.7.9: SAO table is file-local (not on _G.SAO). Capture via OnEvent
-- upvalues (or setfenv proxy). Must never write _G.ipairs.
do
	local savedSAO = _G.SpellActivationOverlayAddon
	local savedSAOGlobal = _G.SAO
	local savedFrame = _G.SpellActivationOverlayAddonFrame
	local savedOnEvent = _G.SpellActivationOverlay_OnEvent
	local savedCombat = _G.InCombatLockdown
	local savedIpairs = _G.ipairs
	local glowFn, glowErr = loadfile(coreDir .. "/ButtonFX/Glow.lua")
	if not glowFn then
		failures[#failures + 1] = "load Glow.lua (Era SAO): " .. tostring(glowErr)
	else
		local handlers = {}
		local saoNs = {
			AddGlow = function() end,
			AddGlowNumber = function() end,
			RemoveGlow = function() end,
			GlowingSpells = {},
		}
		local frame = {
			GetScript = function(_, name)
				if name == "OnEvent" then
					-- Closure upvalue is the unpublished SAO table (Era 2.7.9).
					local SAO = saoNs
					return function(self, event, ...)
						if SAO and event then
							return
						end
					end
				end
			end,
			HookScript = function() end,
		}
		_G.SpellActivationOverlayAddon = nil
		_G.SAO = nil
		_G.SpellActivationOverlayAddonFrame = frame
		_G.InCombatLockdown = function()
			return true
		end
		local gns = {
			Flux = {
				Client = { isPreDF = true, isAnyClassic = true },
				Events = {
					Register = function(ev, fn)
						if type(ev) ~= "string" or type(fn) ~= "function" then
							return
						end
						local t = handlers[ev]
						if not t then
							t = {}
							handlers[ev] = t
						end
						t[#t + 1] = fn
					end,
				},
				ButtonFX = {},
			},
		}
		glowFn("FluxUI", gns)
		local Glow = gns.Flux.ButtonFX and gns.Flux.ButtonFX.Glow
		if not Glow or not Glow.Start or not Glow.Want then
			failures[#failures + 1] = "Glow Era SAO API missing"
		else
			Glow.Start()
			if _G.ipairs ~= savedIpairs then
				failures[#failures + 1] = "SAO capture must not write _G.ipairs"
			end
			saoNs.AddGlowNumber(saoNs, 1, 4242)
			if not Glow.Want(4242) then
				failures[#failures + 1] = "upvalue capture Want without _G.SAO"
			end
			if _G.SAO ~= nil or _G.SpellActivationOverlayAddon ~= nil then
				failures[#failures + 1] = "Era capture must not publish SAO on _G"
			end
		end
	end
	_G.SpellActivationOverlayAddon = savedSAO
	_G.SAO = savedSAOGlobal
	_G.SpellActivationOverlayAddonFrame = savedFrame
	_G.SpellActivationOverlay_OnEvent = savedOnEvent
	_G.InCombatLockdown = savedCombat
	_G.ipairs = savedIpairs
end

-- Missing ActionButtonSpellAlertTemplate: LCG ProcGlow, then AutoCastShine.
do
	local savedCreate = _G.CreateFrame
	local savedLibStub = _G.LibStub
	local glowFn, glowErr = loadfile(coreDir .. "/ButtonFX/Glow.lua")
	if not glowFn then
		failures[#failures + 1] = "load Glow.lua (paint fallback): " .. tostring(glowErr)
	else
		local lcgOpts
		local lcgWidget
		_G.LibStub = function(name)
			if name == "LibCustomGlow-1.0" then
				return {
					ProcGlow_Start = function(widget, opts)
						lcgOpts = opts
						lcgWidget = widget
						widget._ProcGlow = {
							shown = true,
							Show = function(self)
								self.shown = true
							end,
							Hide = function(self)
								self.shown = false
							end,
							IsShown = function(self)
								return self.shown
							end,
							EnableMouse = function() end,
						}
					end,
					ProcGlow_Stop = function(widget)
						if widget and widget._ProcGlow then
							widget._ProcGlow.shown = false
						end
					end,
				}
			end
			return nil
		end
		_G.CreateFrame = function(_, _, _, template)
			if template == "ActionButtonSpellAlertTemplate" then
				error("missing template")
			end
			error("unexpected template " .. tostring(template))
		end
		local gns = { Flux = { ButtonFX = {} } }
		glowFn("FluxUI", gns)
		local Glow = gns.Flux.ButtonFX and gns.Flux.ButtonFX.Glow
		local host = {
			GetWidth = function()
				return 36
			end,
			GetHeight = function()
				return 36
			end,
			GetFrameLevel = function()
				return 1
			end,
		}
		if not Glow or not Glow.Set then
			failures[#failures + 1] = "Glow paint fallback API missing"
		else
			Glow.Set(host, true, true)
			if not lcgOpts or lcgWidget ~= host then
				failures[#failures + 1] = "missing template uses LCG ProcGlow_Start"
			end
			if lcgOpts and lcgOpts.startAnim ~= false then
				failures[#failures + 1] = "skipBirth LCG startAnim false"
			end
			if not host._ProcGlow or not host._ProcGlow.shown then
				failures[#failures + 1] = "LCG ProcGlow overlay is shown"
			end
		end
	end
	_G.CreateFrame = savedCreate
	_G.LibStub = savedLibStub
end

do
	local savedCreate = _G.CreateFrame
	local savedLibStub = _G.LibStub
	local savedShineStart = _G.AutoCastShine_AutoCastStart
	local savedShineStop = _G.AutoCastShine_AutoCastStop
	local glowFn, glowErr = loadfile(coreDir .. "/ButtonFX/Glow.lua")
	if not glowFn then
		failures[#failures + 1] = "load Glow.lua (shine fallback): " .. tostring(glowErr)
	else
		local shineStarted
		local created
		_G.LibStub = function()
			return nil
		end
		_G.AutoCastShine_AutoCastStart = function(shine)
			shineStarted = shine
		end
		_G.AutoCastShine_AutoCastStop = function() end
		_G.CreateFrame = function(_, _, parent, template)
			if template == "ActionButtonSpellAlertTemplate" then
				error("missing template")
			end
			if template == "AutoCastShineTemplate" then
				created = {
					template = template,
					parent = parent,
					shown = false,
					Show = function(self)
						self.shown = true
					end,
					Hide = function(self)
						self.shown = false
					end,
					IsShown = function(self)
						return self.shown
					end,
					SetAllPoints = function() end,
					EnableMouse = function() end,
				}
				return created
			end
			error("unexpected template " .. tostring(template))
		end
		local gns = { Flux = { ButtonFX = {} } }
		glowFn("FluxUI", gns)
		local Glow = gns.Flux.ButtonFX and gns.Flux.ButtonFX.Glow
		local host = {
			GetWidth = function()
				return 36
			end,
			GetHeight = function()
				return 36
			end,
			GetFrameLevel = function()
				return 1
			end,
		}
		if not Glow or not Glow.Set then
			failures[#failures + 1] = "Glow shine fallback API missing"
		else
			Glow.Set(host, true, false)
			if not created or created.template ~= "AutoCastShineTemplate" then
				failures[#failures + 1] = "FlipBook miss falls back to AutoCastShine"
			end
			if shineStarted ~= created then
				failures[#failures + 1] = "AutoCastShine_AutoCastStart on Flux widget"
			end
			if host._fluxProcShine ~= created then
				failures[#failures + 1] = "shine stored as _fluxProcShine"
			end
			if host.SpellActivationAlert ~= nil then
				failures[#failures + 1] = "shine must not write SpellActivationAlert"
			end
		end
	end
	_G.CreateFrame = savedCreate
	_G.LibStub = savedLibStub
	_G.AutoCastShine_AutoCastStart = savedShineStart
	_G.AutoCastShine_AutoCastStop = savedShineStop
end

do
	local mainW = {
		_fluxParked = true,
		_fluxGlowSpell = 100,
		_live = true,
		GetAttribute = function(_, key)
			if key == "action" then
				return 13
			end
		end,
	}
	local miniW = {
		_fluxParked = nil,
		_live = false,
		GetAttribute = function(_, key)
			if key == "action" then
				return 1
			end
		end,
	}
	local main = { column = 1, slot = 13, widget = mainW, _glowing = true }
	local mini = { column = 1, slot = 1, widget = miniW, _glowing = false }
	local transferred
	local followCol
	local checkedHosts = {}
	local setCalls = {}
	local ens = {
		Flux = {
			Bars = {
				NUM_COLUMNS = 19,
				GetHost = function()
					return { main = main, sec = mini, tert = nil }
				end,
				Paint = {
					UpdateChecked = function(host)
						checkedHosts[#checkedHosts + 1] = host
					end,
				},
			},
			ButtonFX = {
				Glow = {
					Want = function(id)
						return id == 100
					end,
					IsLive = function(w)
						return w._live and true or false
					end,
					Transfer = function(from, dest)
						transferred = { from, dest }
						from._live = false
						dest._live = true
						return true
					end,
					Set = function(w, on, skip)
						setCalls[#setCalls + 1] = { w = w, on = on, skip = skip }
						w._live = on and true or false
					end,
					Start = function() end,
					OnChange = function() end,
				},
				Cast = {
					FollowColumn = function(c)
						followCol = c
					end,
				},
			},
		},
	}
	_G.GetActionInfo = function(slot)
		if slot == 1 then
			return "spell", 100
		end
		if slot == 13 then
			return "spell", 50
		end
		return nil
	end
	local efn, eerr = loadfile(dir .. "/Effects.lua")
	if not efn then
		failures[#failures + 1] = "load Effects.lua: " .. tostring(eerr)
	else
		efn("FluxUI", ens)
		ens.Flux.Bars.Effects.SyncColumn(1)
		if not transferred or transferred[1] ~= mainW or transferred[2] ~= miniW then
			failures[#failures + 1] = "SyncColumn transfers main→mini"
		end
		if followCol ~= 1 then
			failures[#failures + 1] = "SyncColumn must FollowColumn"
		end
		if #checkedHosts < 2 then
			failures[#failures + 1] = "SyncColumn must UpdateChecked on column hosts"
		end
		if mini._glowing ~= true or main._glowing ~= false then
			failures[#failures + 1] = "SyncColumn exclusive flags after transfer"
		end
		if #setCalls > 0 then
			failures[#failures + 1] = "Transfer path must not Hide+Show"
		end
		-- First paint of a new proc: no live overlay, skipBirth false.
		mainW._live = false
		mainW._fluxParked = nil
		main._glowing = false
		miniW._live = false
		miniW._fluxParked = true
		mini._glowing = false
		transferred = nil
		setCalls = {}
		ens.Flux.ButtonFX.Glow.Want = function(id)
			return id == 50
		end
		ens.Flux.ButtonFX.Glow.Transfer = function()
			return false
		end
		ens.Flux.Bars.Effects.SyncColumn(1)
		local sawIntro = false
		for i = 1, #setCalls do
			local c = setCalls[i]
			if c.w == mainW and c.on == true and c.skip == false then
				sawIntro = true
			end
			if c.on == true and c.skip == true then
				failures[#failures + 1] = "first proc must not skipBirth"
			end
		end
		if not sawIntro then
			failures[#failures + 1] = "first proc Set(true, skipBirth=false)"
		end
		-- Same widget, macro still overlayed: keep the live loop (no Hide+Show).
		mainW._live = true
		mainW._fluxParked = nil
		main._glowing = true
		miniW._live = false
		miniW._fluxParked = true
		mini._glowing = false
		transferred = nil
		setCalls = {}
		ens.Flux.ButtonFX.Glow.Want = function(id)
			return id == 50
		end
		ens.Flux.Bars.Effects.SyncColumn(1)
		if transferred then
			failures[#failures + 1] = "same-widget macro keep must not Transfer"
		end
		if #setCalls > 0 then
			failures[#failures + 1] = "same-widget macro keep must not Hide+Show"
		end
		-- Same widget, macro left the proc: glow disappears.
		setCalls = {}
		ens.Flux.ButtonFX.Glow.Want = function()
			return false
		end
		ens.Flux.Bars.Effects.SyncColumn(1)
		local sawHide = false
		for i = 1, #setCalls do
			local c = setCalls[i]
			if c.w == mainW and c.on == false then
				sawHide = true
			end
			if c.on == true then
				failures[#failures + 1] = "macro leave must not Show glow"
			end
		end
		if not sawHide then
			failures[#failures + 1] = "macro leave Set(false)"
		end
		-- Same spell returns after a condition flip: skipBirth, do not replay intro.
		mainW._live = false
		main._glowing = false
		mainW._fluxGlowBirthSpell = 50
		setCalls = {}
		ens.Flux.ButtonFX.Glow.Want = function(id)
			return id == 50
		end
		ens.Flux.ButtonFX.Glow.ShouldSkipBirth = function(w, id)
			return w._fluxGlowBirthSpell == id
		end
		ens.Flux.ButtonFX.Glow.NoteShown = function(w, id)
			w._fluxGlowSpell = id
			w._fluxGlowBirthSpell = id
		end
		ens.Flux.Bars.Effects.SyncColumn(1)
		local sawSkip = false
		for i = 1, #setCalls do
			local c = setCalls[i]
			if c.w == mainW and c.on == true and c.skip == true then
				sawSkip = true
			end
			if c.on == true and c.skip == false then
				failures[#failures + 1] = "returning to the same proc must skipBirth"
			end
		end
		if not sawSkip then
			failures[#failures + 1] = "returning to the same proc Set(true, skipBirth=true)"
		end
	end
end

do
	local ovFn, ovErr = loadfile(coreDir .. "/ButtonFX/Overlay.lua")
	if not ovFn then
		failures[#failures + 1] = "load Overlay.lua: " .. tostring(ovErr)
	else
		local ons = { Flux = {} }
		ovFn("FluxUI", ons)
		local Overlay = ons.Flux.ButtonFX and ons.Flux.ButtonFX.Overlay
		if not Overlay or not Overlay.TransferCast or not Overlay.IsLiveCast then
			failures[#failures + 1] = "Overlay API missing TransferCast/IsLiveCast"
		else
			local setupCalled = false
			local frame = {
				shown = true,
				Setup = function()
					setupCalled = true
				end,
				Fill = {
					CastingAnim = {
						IsPlaying = function()
							return true
						end,
					},
				},
				SetParent = function(self, host)
					self.parent = host
				end,
				ClearAllPoints = function() end,
				SetPoint = function() end,
				SetFrameLevel = function() end,
				Show = function(self)
					self.shown = true
				end,
				Hide = function(self)
					self.shown = false
				end,
				IsShown = function(self)
					return self.shown
				end,
				EnableMouse = function() end,
			}
			local from = {
				SpellCastAnimFrame = frame,
				_fluxVfxMode = "native",
				_fluxCastSpell = 100,
				actionButtonCastType = 1,
				GetFrameLevel = function()
					return 1
				end,
			}
			local to = {
				GetFrameLevel = function()
					return 4
				end,
			}
			if not Overlay.TransferCast(from, to) then
				failures[#failures + 1] = "TransferCast should succeed"
			else
				if frame.parent ~= to then
					failures[#failures + 1] = "TransferCast reparents SpellCastAnimFrame"
				end
				if to.SpellCastAnimFrame ~= frame then
					failures[#failures + 1] = "TransferCast assigns dest cast frame"
				end
				if from.SpellCastAnimFrame == frame then
					failures[#failures + 1] = "TransferCast must not leave live frame on source"
				end
				if setupCalled then
					failures[#failures + 1] = "TransferCast must not call Setup"
				end
				if to._fluxCastSpell ~= 100 then
					failures[#failures + 1] = "TransferCast copies in-flight spell"
				end
				if from._fluxVfxMode ~= nil then
					failures[#failures + 1] = "TransferCast clears source vfx mode"
				end
			end
			local stuck = {
				parent = nil,
				shown = true,
				Fill = {
					CastingAnim = {
						IsPlaying = function()
							return true
						end,
					},
				},
				SetParent = function()
					-- Combat lockdown: SetParent is a no-op.
				end,
				GetParent = function(self)
					return self.parent
				end,
				ClearAllPoints = function() end,
				SetPoint = function() end,
				SetFrameLevel = function() end,
				Show = function(self)
					self.shown = true
				end,
				Hide = function(self)
					self.shown = false
				end,
				IsShown = function(self)
					return self.shown
				end,
				EnableMouse = function() end,
			}
			local lockedFrom = {
				SpellCastAnimFrame = stuck,
				_fluxVfxMode = "native",
				_fluxCastSpell = 200,
				actionButtonCastType = 1,
				GetFrameLevel = function()
					return 1
				end,
			}
			stuck.parent = lockedFrom
			local lockedTo = {
				GetFrameLevel = function()
					return 4
				end,
			}
			if Overlay.TransferCast(lockedFrom, lockedTo) then
				failures[#failures + 1] = "TransferCast must fail when SetParent cannot move the fill"
			elseif lockedFrom.SpellCastAnimFrame ~= stuck then
				failures[#failures + 1] = "failed TransferCast must keep the live frame on source"
			elseif lockedTo.SpellCastAnimFrame == stuck then
				failures[#failures + 1] = "failed TransferCast must not steal the live frame pointer"
			elseif lockedFrom._fluxVfxMode ~= "native" then
				failures[#failures + 1] = "failed TransferCast must not take source cast flags"
			end
			local src = {
				checked = true,
				GetChecked = function(self)
					return self.checked
				end,
				SetChecked = function(self, v)
					self.checked = v and true or false
				end,
				GetButtonState = function()
					return "PUSHED"
				end,
				SetButtonState = function(self, state)
					self.state = state
				end,
			}
			local dest = {
				checked = false,
				GetChecked = function(self)
					return self.checked
				end,
				SetChecked = function(self, v)
					self.checked = v and true or false
				end,
				SetButtonState = function(self, state)
					self.state = state
				end,
			}
			if not Overlay.FollowChrome(src, dest) then
				failures[#failures + 1] = "FollowChrome should move pushed"
			elseif dest.checked ~= false or src.checked ~= true then
				failures[#failures + 1] = "FollowChrome must not transfer gold checked"
			elseif dest.state ~= "PUSHED" or src.state ~= "NORMAL" then
				failures[#failures + 1] = "FollowChrome moves PUSHED to dest"
			end
			_G.GetTime = function()
				return 10
			end
			_G.UnitCastingInfo = function()
				return "Fireball", nil, nil, 10000, 20000
			end
			_G.C_Texture = {
				GetAtlasInfo = function()
					return { width = 64 }
				end,
			}
			local fillPoint
			local playWidget = {
				SpellCastAnimFrame = {
					Setup = function() end,
					Show = function() end,
					Fill = {
						Show = function() end,
						CastingAnim = {
							Stop = function() end,
							IsPlaying = function()
								return false
							end,
						},
						CastFill = {
							ClearAllPoints = function() end,
							SetPoint = function(_, _, ox)
								fillPoint = ox
							end,
							SetAlpha = function() end,
						},
					},
					EndBurst = {
						FinishCastAnim = {
							Stop = function() end,
						},
					},
				},
				GetWidth = function()
					return 44
				end,
			}
			Overlay.PlayCast(playWidget, 1)
			if playWidget._fluxVfxMode ~= "native" then
				failures[#failures + 1] = "PlayCast sets native fill mode"
			elseif not playWidget.vfxCastData then
				failures[#failures + 1] = "PlayCast seeds vfxCastData"
			elseif fillPoint == nil then
				failures[#failures + 1] = "PlayCast places CastFill"
			end
			local setupCount = 0
			playWidget.SpellCastAnimFrame.Setup = function()
				setupCount = setupCount + 1
			end
			Overlay.PlayCast(playWidget, 1, true)
			if setupCount ~= 0 then
				failures[#failures + 1] = "PlayCast skipSetup must not restart Setup"
			end
			local prevChannel = _G.UnitChannelInfo
			_G.UnitChannelInfo = function()
				return nil
			end
			local chWidget = {
				SpellCastAnimFrame = playWidget.SpellCastAnimFrame,
				GetWidth = playWidget.GetWidth,
			}
			Overlay.PlayCast(chWidget, Overlay.CHANNEL)
			if chWidget.vfxCastData then
				failures[#failures + 1] = "PlayCast CHANNEL must not seed fake duration without UnitChannelInfo"
			elseif chWidget._fluxVfxMode ~= "native" then
				failures[#failures + 1] = "PlayCast CHANNEL still starts native fill"
			end
			_G.UnitChannelInfo = prevChannel
		end
	end
end

do
	local transferred
	local chrome
	local mainW = {
		_fluxParked = nil,
		_live = true,
		_fluxCastSpell = 100,
		_fluxCastRegistered = nil,
	}
	local miniW = {
		_fluxParked = nil,
		_live = false,
		_fluxCastRegistered = nil,
	}
	mainW._fluxHost = { column = 1 }
	miniW._fluxHost = { column = 1 }
	local ens = {
		Flux = {
			Bars = {
				GetHost = function()
					return { main = { widget = mainW }, sec = { widget = miniW }, tert = nil }
				end,
			},
			ButtonFX = {
				Overlay = {
					IsLiveCast = function(w)
						return w._live and true or false
					end,
					IsLiveReticle = function()
						return false
					end,
					IsLiveInterrupt = function()
						return false
					end,
					Transfer = function(from, dest)
						transferred = { from, dest }
						from._live = false
						dest._live = true
						dest._fluxCastSpell = from._fluxCastSpell
						from._fluxCastSpell = nil
						return true
					end,
					FollowChrome = function(from, dest)
						chrome = { from, dest }
					end,
				},
			},
		},
	}
	local cfn, cerr = loadfile(coreDir .. "/ButtonFX/Cast.lua")
	if not cfn then
		failures[#failures + 1] = "load Cast.lua: " .. tostring(cerr)
	else
		_G.CreateFrame = function()
			return {
				SetScript = function() end,
				RegisterEvent = function()
					return true
				end,
			}
		end
		_G.GetTime = function()
			return 10
		end
		_G.UnitCastingInfo = function()
			return "Test", nil, nil, 10000, 20000, nil, nil, nil, 100
		end
		_G.UnitChannelInfo = nil
		cfn("FluxUI", ens)
		local Cast = ens.Flux.ButtonFX.Cast
		Cast.Register(mainW, function()
			return 50
		end, Cast.RANK_MAIN)
		Cast.Register(miniW, function()
			return 100
		end, Cast.RANK_MINI)
		Cast.FollowColumn(1)
		if not transferred or transferred[1] ~= mainW or transferred[2] ~= miniW then
			failures[#failures + 1] = "FollowColumn transfers fill main→mini"
		end
		if not chrome or chrome[1] ~= mainW or chrome[2] ~= miniW then
			failures[#failures + 1] = "FollowColumn must FollowChrome pushed"
		end
	end
end

do
	local prevBase, prevInfo = _G.FindBaseSpellByID, _G.GetSpellInfo
	_G.FindBaseSpellByID = function()
		return 2120
	end
	_G.GetSpellInfo = function()
		return "Flamestrike"
	end
	local ens = {
		Flux = {
			Spell = {
				GetOverrideSpell = function(id)
					if id == 50 then
						return 60
					end
					return id
				end,
				GetName = function()
					return "Flamestrike"
				end,
				GetSubtext = function(id)
					if id == 1022 then
						return "Rank 5"
					end
					if id == 1023 then
						return "Rank 6"
					end
					return nil
				end,
			},
			ButtonFX = {},
		},
	}
	local cfn, cerr = loadfile(coreDir .. "/ButtonFX/Cast.lua")
	if not cfn then
		failures[#failures + 1] = "SpellIdsMatch load Cast.lua: " .. tostring(cerr)
	else
		cfn("FluxUI", ens)
		local Match = ens.Flux.ButtonFX.SpellIdsMatch
		if not Match then
			failures[#failures + 1] = "SpellIdsMatch missing"
		else
			if Match(1022, 1023) then
				failures[#failures + 1] = "SpellIdsMatch must not treat different ranks as the same spell"
			end
			if not Match(1023, 1023) then
				failures[#failures + 1] = "SpellIdsMatch must match the same rank id"
			end
			if not Match(50, 60) then
				failures[#failures + 1] = "SpellIdsMatch must still match override morphs"
			end
			if not Match(100, 200) then
				failures[#failures + 1] = "SpellIdsMatch must match same-name unranked ids"
			end
		end
	end
	_G.FindBaseSpellByID = prevBase
	_G.GetSpellInfo = prevInfo
end

local function followColumnCase(label, opts)
	local transferred, chrome, synced, cleared, ticked, reticlePlayed
	local retries = {}
	local mainSid, miniSid = opts.mainSid, opts.miniSid
	local mainW = {
		_fluxParked = opts.mainParked,
		_live = opts.mainLive and true or false,
		_fluxCastSpell = opts.mainStamp,
		_fluxCastRegistered = nil,
		_pushed = opts.mainPressed and true or false,
	}
	local miniW = {
		_fluxParked = opts.miniParked,
		_live = opts.miniLive and true or false,
		_fluxCastSpell = opts.miniStamp,
		_fluxCastRegistered = nil,
		_pushed = opts.miniPressed and true or false,
		_reticle = opts.miniReticle and true or false,
	}
	mainW._reticle = opts.mainReticle and true or false
	mainW._kick = opts.mainKick and true or false
	miniW._kick = opts.miniKick and true or false
	mainW._fluxHost = { column = 1 }
	miniW._fluxHost = { column = 1 }
	local ens = {
		Flux = {
			Bars = {
				GetHost = function()
					return { main = { widget = mainW }, sec = { widget = miniW }, tert = nil }
				end,
			},
			ButtonFX = {
				Overlay = {
					CAST = 1,
					IsLiveCast = function(w)
						return w._live and true or false
					end,
					IsLiveBurst = function()
						return false
					end,
					IsLiveReticle = function(w)
						return w._reticle and true or false
					end,
					IsLiveInterrupt = function(w)
						return w._kick and true or false
					end,
					IsPushed = function(w)
						return w._pushed and true or false
					end,
					Transfer = function(from, dest)
						transferred = { from, dest }
						from._live = false
						dest._live = true
						dest._reticle = from._reticle
						from._reticle = false
						dest._kick = from._kick
						from._kick = false
						dest._fluxCastSpell = from._fluxCastSpell
						from._fluxCastSpell = nil
						return true
					end,
					FollowChrome = function(from, dest)
						chrome = { from, dest }
					end,
					SyncCast = function(w)
						synced = w
					end,
					SyncInterrupt = function(w)
						w._kick = true
					end,
					PlayReticle = function(w)
						reticlePlayed = w
						w._reticle = true
					end,
					ClearReticle = function(w)
						w._reticle = false
					end,
					TickFill = function(w)
						ticked = w
					end,
					ForceClear = function(w)
						cleared = cleared or {}
						cleared[#cleared + 1] = w
						w._live = false
						w._reticle = false
						w._kick = false
					end,
				},
			},
		},
	}
	local cfn, cerr = loadfile(coreDir .. "/ButtonFX/Cast.lua")
	if not cfn then
		failures[#failures + 1] = label .. " load Cast.lua: " .. tostring(cerr)
		return
	end
	_G.CreateFrame = function()
		return {
			SetScript = function() end,
			RegisterEvent = function()
				return true
			end,
		}
	end
	_G.GetTime = function()
		return 10
	end
	_G.UnitChannelInfo = nil
	if opts.unitSpell then
		local sid = opts.unitSpell
		_G.UnitCastingInfo = function()
			return "Test", nil, nil, 10000, 20000, nil, nil, nil, sid
		end
	else
		_G.UnitCastingInfo = nil
	end
	local prevTimer = _G.C_Timer
	local prevTargeting = _G.SpellIsTargeting
	local prevBase = _G.FindBaseSpellByID
	local prevInfo = _G.GetSpellInfo
	local function restore()
		if opts.captureRetry then
			_G.C_Timer = prevTimer
		end
		_G.SpellIsTargeting = prevTargeting
		_G.FindBaseSpellByID = prevBase
		_G.GetSpellInfo = prevInfo
	end
	if opts.diffNames then
		ens.Flux.Spell = ens.Flux.Spell or {}
		ens.Flux.Spell.GetName = function(id)
			return "Spell" .. tostring(id)
		end
		ens.Flux.Spell.GetOverrideSpell = function(id)
			return id
		end
		ens.Flux.Spell.GetSubtext = function()
			return nil
		end
	end
	if opts.sameSpellName then
		ens.Flux.Spell = {
			GetName = function()
				return opts.sameSpellName
			end,
			GetOverrideSpell = function(id)
				return id
			end,
			GetSubtext = function(id)
				if opts.subtext then
					return opts.subtext[id]
				end
				return nil
			end,
		}
		_G.FindBaseSpellByID = function()
			return 1
		end
		_G.GetSpellInfo = function()
			return opts.sameSpellName
		end
	end
	if opts.captureRetry then
		_G.C_Timer = {
			After = function(delay, fn)
				retries[#retries + 1] = delay
			end,
		}
	end
	if opts.targeting then
		_G.SpellIsTargeting = function()
			return true
		end
	end
	cfn("FluxUI", ens)
	local Cast = ens.Flux.ButtonFX.Cast
	if opts.active then
		Cast._active = opts.active
	end
	if opts.reticleSpell then
		Cast._reticle = { spellID = opts.reticleSpell }
	end
	if opts.interruptSpell then
		Cast._interrupt = { spellID = opts.interruptSpell, expires = 9999 }
	end
	Cast.Register(mainW, function()
		return mainSid
	end, Cast.RANK_MAIN)
	Cast.Register(miniW, function()
		return miniSid
	end, Cast.RANK_MINI)
	if opts.pickOwners then
		local owners = Cast.PickOwners(opts.pickOwners, nil)
		restore()
		return {
			main = mainW,
			mini = miniW,
			owners = owners,
		}
	end
	if opts.pickAllMatching then
		local owners = Cast.PickAllMatching(opts.pickAllMatching, nil)
		restore()
		return {
			main = mainW,
			mini = miniW,
			owners = owners,
		}
	end
	Cast.FollowColumn(1)
	restore()
	return {
		main = mainW,
		mini = miniW,
		transferred = transferred,
		chrome = chrome,
		synced = synced,
		ticked = ticked,
		reticle = reticlePlayed,
		retries = retries,
		cleared = cleared or {},
	}
end

do
	local r = followColumnCase("appear", {
		mainSid = 50,
		miniSid = 100,
		unitSpell = 100,
	})
	if r then
		if r.transferred then
			failures[#failures + 1] = "FollowColumn appear must not Transfer when no live source"
		end
		if r.synced ~= r.mini then
			failures[#failures + 1] = "FollowColumn appear paints mini at live progress"
		end
	end
end

do
	local r = followColumnCase("clear", {
		mainSid = 50,
		miniSid = 999,
		mainLive = true,
		mainStamp = 100,
		unitSpell = 100,
	})
	if r then
		local sawMain = false
		for i = 1, #r.cleared do
			if r.cleared[i] == r.main then
				sawMain = true
			end
		end
		if not sawMain then
			failures[#failures + 1] = "FollowColumn ForceClear when face shows a different spell"
		end
		if r.synced then
			failures[#failures + 1] = "FollowColumn must not appear on a column that left the spell"
		end
	end
end

do
	local r = followColumnCase("idle-stuck", {
		mainSid = 50,
		miniSid = 50,
		mainLive = true,
		mainStamp = 50,
	})
	if r then
		local sawMain = false
		for i = 1, #r.cleared do
			if r.cleared[i] == r.main then
				sawMain = true
			end
		end
		if not sawMain then
			failures[#failures + 1] = "FollowColumn ForceClear leftover fill when player is not casting"
		end
		if r.transferred then
			failures[#failures + 1] = "FollowColumn must not transfer leftover fill after the cast ended"
		end
	end
end

do
	local r = followColumnCase("no-rank-steal", {
		mainSid = 100,
		miniSid = 100,
		miniLive = true,
		miniStamp = 100,
		unitSpell = 100,
	})
	if r then
		if r.transferred then
			failures[#failures + 1] = "live matching mini must not be stolen by main rank"
		end
		if not r.mini._live or r.main._live then
			failures[#failures + 1] = "live matching mini must keep fill"
		end
	end
end

do
	local r = followColumnCase("pick-live-over-rank", {
		mainSid = 100,
		miniSid = 100,
		miniLive = true,
		pickOwners = 100,
	})
	if r and r.owners then
		if r.owners[1] ~= r.mini then
			failures[#failures + 1] = "PickOwners must keep live mini over main rank"
		end
	end
end

do
	local r = followColumnCase("pick-pressed-over-rank", {
		mainSid = 100,
		miniSid = 100,
		miniPressed = true,
		pickOwners = 100,
	})
	if r and r.owners then
		if r.owners[1] ~= r.mini then
			failures[#failures + 1] = "PickOwners must prefer pressed mini over main rank"
		end
	end
end

do
	local r = followColumnCase("pick-all-matching-same-spell", {
		mainSid = 100,
		miniSid = 100,
		pickAllMatching = 100,
	})
	if r and r.owners then
		if #r.owners ~= 2 then
			failures[#failures + 1] = "PickAllMatching must keep every face of the same spell"
		end
	end
end

do
	local r = followColumnCase("pick-all-matching-other-spell", {
		mainSid = 100,
		miniSid = 200,
		pickAllMatching = 100,
	})
	if r and r.owners then
		if #r.owners ~= 1 or r.owners[1] ~= r.main then
			failures[#failures + 1] = "PickAllMatching must not include a different spell"
		end
	end
end

do
	local r = followColumnCase("pick-all-matching-other-rank", {
		mainSid = 1023,
		miniSid = 1022,
		pickAllMatching = 1023,
		sameSpellName = "Flamestrike",
		subtext = { [1022] = "Rank 5", [1023] = "Rank 6" },
	})
	if r and r.owners then
		if #r.owners ~= 1 or r.owners[1] ~= r.main then
			failures[#failures + 1] = "PickAllMatching must not include a different spell rank"
		end
	end
end

do
	local r = followColumnCase("slot-swap", {
		mainSid = 100,
		miniSid = 50,
		miniLive = true,
		miniStamp = 100,
		unitSpell = 100,
	})
	if r then
		if not r.transferred or r.transferred[1] ~= r.mini or r.transferred[2] ~= r.main then
			failures[#failures + 1] = "FollowColumn transfers fill after slot swap mini→main"
		end
		if r.ticked ~= r.main then
			failures[#failures + 1] = "FollowColumn must TickFill dest after transfer"
		end
		local sawMini = false
		for i = 1, #r.cleared do
			if r.cleared[i] == r.mini then
				sawMini = true
			end
		end
		if not sawMini then
			failures[#failures + 1] = "FollowColumn ForceClear the old face after slot swap"
		end
	end
end

do
	local r = followColumnCase("dest-nil-retry", {
		mainSid = nil,
		miniSid = nil,
		unitSpell = 100,
		captureRetry = true,
	})
	if r then
		if r.synced then
			failures[#failures + 1] = "dest-nil lag must not paint a face that does not show the spell"
		end
		local saw0, saw05 = false, false
		for i = 1, #r.retries do
			if r.retries[i] == 0 then
				saw0 = true
			end
			if r.retries[i] == 0.05 then
				saw05 = true
			end
		end
		if not saw0 or not saw05 then
			failures[#failures + 1] = "dest-nil must retry FollowColumn at 0 and 0.05s"
		end
	end
end

do
	local r = followColumnCase("dest-nil-keep", {
		mainSid = nil,
		miniSid = nil,
		miniLive = true,
		miniStamp = 100,
		unitSpell = 100,
		captureRetry = true,
	})
	if r then
		if r.transferred then
			failures[#failures + 1] = "dest-nil lag must keep live source, not transfer"
		end
		if not r.mini._live then
			failures[#failures + 1] = "dest-nil lag must not ForceClear live source"
		end
		if #r.retries == 0 then
			failures[#failures + 1] = "dest-nil lag must retry until slot identity exists"
		end
	end
end

do
	local r = followColumnCase("interrupt-dest-nil-keep", {
		mainSid = nil,
		miniSid = nil,
		miniKick = true,
		miniStamp = 100,
		interruptSpell = 100,
		captureRetry = true,
	})
	if r then
		local sawMini = false
		for i = 1, #r.cleared do
			if r.cleared[i] == r.mini then
				sawMini = true
			end
		end
		if sawMini then
			failures[#failures + 1] = "strip FollowColumn must not ForceClear a live channel interrupt"
		end
		if not r.mini._kick then
			failures[#failures + 1] = "strip FollowColumn must keep live interrupt when slot id is lag/secret"
		end
	end
end

do
	local r = followColumnCase("interrupt-other-spell-clear", {
		mainSid = 50,
		miniSid = 50,
		miniKick = true,
		miniStamp = 100,
		interruptSpell = 100,
		diffNames = true,
	})
	if r then
		local sawMini = false
		for i = 1, #r.cleared do
			if r.cleared[i] == r.mini then
				sawMini = true
			end
		end
		if not sawMini then
			failures[#failures + 1] = "interrupt ForceClear when the face shows a different spell"
		end
		if r.mini._kick then
			failures[#failures + 1] = "interrupt must not stay on a different spell"
		end
	end
end

do
	local r = followColumnCase("lag-dest-resolved", {
		mainSid = 100,
		miniSid = nil,
		miniLive = true,
		miniStamp = 100,
		unitSpell = 100,
	})
	if r then
		if not r.transferred or r.transferred[1] ~= r.mini or r.transferred[2] ~= r.main then
			failures[#failures + 1] = "once dest slot matches, fill must move off the lagging source"
		end
	end
end

do
	local r = followColumnCase("macro-leave", {
		mainSid = 50,
		miniSid = 999,
		miniLive = true,
		miniStamp = 100,
		unitSpell = 100,
	})
	if r then
		local sawMini = false
		for i = 1, #r.cleared do
			if r.cleared[i] == r.mini then
				sawMini = true
			end
		end
		if not sawMini then
			failures[#failures + 1] = "macro condition leave ForceClear the old face"
		end
		if r.synced then
			failures[#failures + 1] = "macro leave must not appear on a different spell"
		end
		if r.transferred then
			failures[#failures + 1] = "macro leave must not transfer onto a non-matching face"
		end
	end
end

do
	local r = followColumnCase("macro-return", {
		mainSid = 50,
		miniSid = 100,
		unitSpell = 100,
	})
	if r then
		if r.synced ~= r.mini then
			failures[#failures + 1] = "macro condition return appears on the matching face"
		end
		if r.transferred then
			failures[#failures + 1] = "macro return with no live source must appear, not transfer"
		end
	end
end

do
	local r = followColumnCase("reticle-swap", {
		mainSid = 100,
		miniSid = 50,
		miniReticle = true,
		miniStamp = 100,
		targeting = true,
		reticleSpell = 100,
	})
	if r then
		if not r.transferred or r.transferred[1] ~= r.mini or r.transferred[2] ~= r.main then
			failures[#failures + 1] = "FollowColumn transfers AOE reticle after slot swap mini→main"
		end
		if r.mini._reticle or not r.main._reticle then
			failures[#failures + 1] = "AOE reticle must leave the old row after paging"
		end
	end
end

do
	local r = followColumnCase("reticle-leave", {
		mainSid = 50,
		miniSid = 999,
		miniReticle = true,
		miniStamp = 100,
		targeting = true,
		reticleSpell = 100,
	})
	if r then
		local sawMini = false
		for i = 1, #r.cleared do
			if r.cleared[i] == r.mini then
				sawMini = true
			end
		end
		if not sawMini then
			failures[#failures + 1] = "AOE reticle ForceClear when the face left the spell"
		end
		if r.mini._reticle then
			failures[#failures + 1] = "AOE reticle must not stay on a different spell"
		end
		if r.reticle then
			failures[#failures + 1] = "AOE reticle leave must not PlayReticle on a non-matching face"
		end
	end
end

do
	local r = followColumnCase("reticle-return", {
		mainSid = 50,
		miniSid = 100,
		targeting = true,
		reticleSpell = 100,
	})
	if r then
		if r.reticle ~= r.mini then
			failures[#failures + 1] = "AOE reticle return appears on the matching face"
		end
		if r.transferred then
			failures[#failures + 1] = "AOE reticle return with no live source must appear, not transfer"
		end
	end
end

-- Combat button surface: one FluxButton, one overlay owner, one display pass.
has(hosts, "Widget.Attach", "19-col hosts attach the FluxButton occupancy env")
has(slotProgram, "PF.TranslateHost", "SlotProgram stamps clicks; ProgramFace owns the shown face")
do
	local i = slotProgram:find("local function SyncSurfaceFace", 1, true)
	local j = i and slotProgram:find("local function WriteHostProgram", i, true)
	local body = (i and j and slotProgram:sub(i, j - 1)) or ""
	if body:find("face = {", 1, true) then
		failures[#failures + 1] = "SlotProgram must not allocate a second overlay face env"
	end
	has(body, "PF.TranslateHost", "SyncSurfaceFace delegates to ProgramFace")
end
has(programFace, "function ProgramFace.OnContext", "ProgramFace is the overlay display pass")
has(macroDisplay, "Ctx()", "MacrotextDisplay is a Context Request alias")
if watchSrc:find("RequestApplyAll", 1, true) or watchSrc:find("ScheduleApply", 1, true) then
	failures[#failures + 1] = "Watch must not Binding-Apply on form/hop"
end
has(badgeHost, "function BadgeHost.SyncShownFaces", "badge vis runs after both Identities")
has(ebsAction, "kind == \"strip\"", "Extra paint skips strip occupancy")
has(readEbs("Init.lua"), "function EBS.RegisterBadge", "badges have their own Extra list")

if #failures > 0 then
	io.stderr:write("source contract FAILED (" .. tostring(#failures) .. ")\n")
	for i = 1, #failures do
		io.stderr:write("  " .. failures[i] .. "\n")
	end
	os.exit(1)
end

print("bars smoke OK")
print("  slot math: rest/shift/ctrl/cat/bear/vehicle/static/promote/xor")
print("  lockdown: Layout guards, no combat unpack")
print("  clicks: ButtonForge wrap verbatim; no post-body; PreClick gated on button/down")
print("  leftover: stock ActionButtons off ActionBarButtonEventsFrame (mixins stay stock),")
print("            then EnableMouse false on MainActionBar/pager/ActionButton")
print("  drag: PreClick cursor + L+R without Shift; click fires on mouse up")
print("  checked: Paint owns SetChecked; gold hilight not mouseover atlas")
print("  flash: auto-attack/auto-shot/wand red blink on strip + Extra; Classic QuickslotRed, Forever atlas")
print("  paint: Midnight duration object + Classic GetActionCooldown")
print("  hotkey: MouseButton3-5 / scroll / space glyphs + S-/C- overlay")
print("  charges: UnpackCharges table+tuple, dual chargeCooldown")
print("  vfx: Transfer fill on swap; exclusive appear/clear; finish burst; no stuck fill")
print("  chrome: checked/pushed follow paging with fill/interrupt")
print("  glow: Transfer overlay on swap; skipBirth; ungated Set; Era OOC SAO capture; SyncColumn; ClearCache keeps _glowing")
print("  combat badges: alpha vis (no Hide taint); exclusive VFX/gold on the live Extra face")
print("  combat button: one FluxButton; Context hops; Binding Apply OOC only; vis after Identity")
print("  hovercast: TOC Keybind; strip hosts; UF peek only; no [@mouseover] on hover-only tail")
print("  range: one Flux.Range ticker for strip+Extra+badges; macros range their shown")
print("         spell against the macro's own @unit; frame-shared memo; 0.2s mouseover")
print("  mouseover cast: click-time unit only (no static unit=mouseover); factory tails")
print("         factory mouseover tails idle-stripped; Blizzard range-check gated; hovercast driver on UF hover")
print("  ebs assistant: GetNextCastSpell(false); rotation overlay; KeyBind override")
print("  assist morph: strip+EBS poll next-cast whenever the button exists")
print("  pet/stance: Extra Button surfaces; event-split paint; TOC-loaded")
print("  ingame: /reload; drag from book without Shift; pickup; click on release;")
print("          key on press; AOE cancel clears checked; SHIFT mini keeps proc loop;")
print("          macro condition drop glow when the face leaves; skipBirth on return;")
print("          VFX continues or appears/clears with the visible face")
