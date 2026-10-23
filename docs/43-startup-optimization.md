# Startup and safety optimization — 23 October 2026

This report describes implemented changes in the existing working tree. Existing local compatibility changes were retained. No player SavedVariables files were opened or edited, no bindings were changed in a running game, and no commits were made. Native WoW acceptance remains pending; desktop tests cannot certify taint, hardware input, secret values, rendering, or in-game performance.

## Findings and implemented phases

Before this change, kernel modules enabled in registration order at login, with Inventory preceding action infrastructure. Forever had a variable/gamepad barrier plus an unverified one-second late-load fallback. Binding boot waited one second. Player frames and extra grids depended on world entry; a first combat load could leave the Combat Grid permanently uninitialized. Bars hid native controls before completing replacement input setup. Several constructors and the module registry latched success before initialization finished. Repeated layout watchers, tab destruction, meter label creation and post-combat structural request replacement added unnecessary work or lost requests.

The existing module registry, event bus, scheduler, timer, range and ticker services remain in use. This is an extension of those services, rather than a replacement kernel.

| Phase | Trigger and ordering | Implemented behavior |
|---|---|---|
| Saved configuration | Own `ADDON_LOADED`, after eligible TOC/XML files execute | Ensure declared stores; bootstrap AceDB inside `AfterLoad`; finish queued configuration callbacks before offering secure modules. A failed profile bootstrap gates the pipeline and can retry on world/regen events without configuring controls from fallback defaults. |
| A: secure | Same `ADDON_LOADED` transaction where legal | Priorities: Extra Button engine, 19-column bar/minis, Pet, Stance, NonCombat Grid, Combat Grid, trinkets, supported unit frames, raid headers and Extra Ability host. Protected modules queue individually if locked down. |
| Forever barrier | Blizzard `EventUtil.ContinueOnVariablesLoaded`, then next frame | All Forever clients retain the required gamepad barrier. Late addon loading uses the actual EventUtil readiness contract. The old one-second guess is removed. |
| B: HUD | Kernel login, including already-logged-in addon loading | Binding boot immediately requests its existing combat-checked apply; Flux Window shell, Micro Menu, status, minimap, bottom border/layout initialize. Permitted status/display work continues during combat. Native Micro Menu hijacking and restricted anchors wait. |
| C: nonessential | Next frame after the immediate HUD phase | Inventory provider/cache startup, character overlays, equipment flyout, window discovery and optional Baganator/BigDebuffs work. Existing lazy options/editor builders remain lazy. |
| Recovery | `PLAYER_REGEN_ENABLED`, dependency events and world transitions | Named structural jobs coalesce; completed modules are skipped; partial constructors reuse their frames/buttons. A false result or exception does not mark a module enabled. |

`phase`, `priority` and `protected` are additive module metadata. Unannotated modules retain the HUD phase. Public `Module.Enable` also checks the phase barrier. Failures are exposed through `Module.List().error`. `Flux.Safecall` now returns the protected-call success/result, allowing callers to distinguish an attempted initialization from completion.

`PLAYER_REGEN_DISABLED` still drives existing combat state, range and display behavior. Every deferred structural stage checks lockdown again when it executes. Combat beginning inside a queue/bucket pauses remaining work without dropping it. The structural scheduler now retains all callers' tokens/functions instead of replacing earlier callers with the latest combat callback.

## Native fallback and secure readiness

Action surfaces, minirows, paging drivers, click registration, key proxies and override bindings must complete before the action-strip handoff. An incomplete strip stays hidden. Native collector suppression starts at that handoff. Pet and Stance have separate readiness gates, so a complete main bar cannot prematurely suppress an incomplete native Pet/Stance replacement. Partial frame/header/button records survive retry.

Unit-frame native suppression checks completed replacements. Raid concrete secure headers moved from unconditional XML instantiation into the protected startup phase; the virtual templates remain XML. All nine headers reuse their original names and IDs. Native raid/party hiding waits for successful secure configuration. The pet-battle driver is installed once.

Grids build in layout batches instead of relayout after every button and repeated startup timers. Initial registrations and key routing run before detailed inventory reconciliation. The teleport/portal slot can precreate empty secure infrastructure when spell data is cold, without showing a false action or consuming its key. Consumables apply their existing active-preset facts and bindings immediately, then reconcile when inventory settles. Unknown inventory/spell facts are not reported as usable input.

On a fresh addon load under lockdown, frames that have not legally been created/configured cannot be made combat-ready by this code. Flux queues that structural work and retains native controls where feasible. No insecure protected-action workaround was introduced. Actual fallback/input/taint behavior must be checked in each game client.

## Correctness and data ownership

- Automatic F5 verification and `UPDATE_BINDINGS` recovery no longer reset bindings or use the F5 sentinel to trigger a CVar reset. Explicit reset-to-Flux-defaults remains available. Existing first-install setup behavior is separate from this verification fix.
- Failed, rejected, thrown, invalid or legacy spell-binding restores end Respec application with failure and retain the binding recovery checkpoint. Success is emitted only once on a successful path. Pending restores are detached from mutable input, support supersession/cancellation, and do not apply after their owner cancels.
- Baganator no longer replaces `C_Item.GetItemGUID` or `C_Item.DoesItemExist`. Gear mapping first selects relevant live items locally, then asks native APIs only for those candidates, without an Armor/Weapon class restriction.
- Restock migration V1 retains `VendorAuto` and bank snapshots, imports only validated legacy preferences when current Restock is absent, and keeps `_FluxUI_CharSavedVars._restockMigrationV1` rollback data. Undeclared legacy account data found in memory is archived there. Current Restock settings remain authoritative; bank snapshots do not become live topology facts. Existing already-lost data cannot be reconstructed.
- Malformed non-table SavedVariables roots are retained in `FluxUI_DB.__fluxRootRecoveryV1` before repairing their shape. Table records are preserved; this is not validation of every feature's internal schema.
- MirrorTimer hooks are idempotent across login/world events. Existing Forever global aliases/restricted-handler policies remain where shared consumers still require them. Forever remains distinguishable through `Client.branch == "forever"` and its existing flags; it is not reduced to the Live client.

## Runtime work and integrations

Flux Window tab contents persist across switches. Meter status text is reused. Tab-scoped delayed work is cancelled or invalidated when the active tab changes. Native-meter combat retry uses one post-combat request rather than a repeating timer. Meter editor requests coalesce; hidden tabs cannot resurface from stale callbacks. Provider-owned map hooks retain their existing ownership rules.

Assisted Combat consumers share one frame-scoped manager-rate sample while retaining their original paint cadence. Existing responsive range/proc/cooldown/mouseover and true animation drivers remain intact. No broad replacement of frame-synchronous work with slower timers was made; no in-game profile justified such a replacement.

Micro Menu and status startup polling was replaced with immediate phase work and event-driven reconciliation. Actual FCF restoration, chat size/show and Edit Mode exit events request one coalesced Micro Menu layout. The status missing-menu path no longer indexes a Lua function as a table. Native status hiding waits for replacement layout, and status fill/text remains available during combat.

Nonessential companion addons no longer appear in TOC `OptionalDeps`. Late initialization is event-driven and provider `ADDON_LOADED` restoration finishes before deferred integration work. Syndicator can hand off from immediate builtin facts on its `Ready` event; it no longer creates a three-second inventory blackout. Baganator, BigDebuffs, TacoTip, Questie, ConsolePort and SpellActivationOverlay retain late-load integration paths. Details Forever patches install idempotently in either normal addon order before provider login startup. Flux does not invoke Details' private startup function: genuinely manual post-login Details loading still requires the provider to initialize itself before it can supply a usable meter.

## Startup diagnostics

Use `/fluxstartup on`, then `/reload`, then `/fluxstartup`. Disable with `/fluxstartup off`. Recording is opt-in via `FluxUI_DB.startupDiagnostics`; normal operation adds no diagnostic ticker or global API wrappers.

Two samples in the first TOC file precede embedded libraries. Recorded milestones distinguish saved configuration, module completion, action infrastructure, visible action buttons, successful spell-binding input apply, supported unit infrastructure, visible essential unit frames, initial bottom layout and initial layout stability. Initial stability requires unchanged frame boundaries, no pending structural/layout work, and completed eligible essential modules; it is not a guarantee that no later world/dependency event will change layout.

Counters record named combat deferrals, managed timer callbacks and instrumented layout passes. Direct legacy/provider `C_Timer` calls are not globally intercepted, so the timer count is explicitly **managed callbacks**, not all timers in the client. Optional readiness timestamps are first observations, rather than a claim to own provider initialization. Lua heap delta is process-wide and affected by other addons/GC; it is not addon-attributed allocation. Missing readiness marks remain missing rather than being inferred from visibility.

## Before/after evidence

| Repeatable desktop fixture | Before | After | Boundary |
|---|---:|---:|---|
| Binding boot fixed wait | 1 second | Removed | Source ordering; no measured in-game latency claim. |
| MirrorTimer repositions after three lifecycle events | 3 per native show/event | 1 | Mock legacy timer callbacks. |
| Additional meter FontStrings during retry fixture | 29 | 0 | Fixed widget fixture. |
| Detached tab objects during switch fixture | 32 | 0 | Fixed window fixture. |
| Gear rebuild, 100 bag slots | 100 GUID + 119 existence queries | 1 GUID + 1 existence query | Synthetic allocation set; same selected result. |
| Assisted manager-rate reads, 600 frames | 1,200 | 600 | Executed Git HEAD vs working production Watch code; both consumers still paint 85 times. |
| Meter editor, 100 refresh requests | Repeated scheduled work | 1 layout | Current coalescing fixture; no native meter timing claim. |
| Existing smoke baseline | 26 passing / 2 failing scripts | 44 passing / 0 failing | Follow-up investigation and four additional regression scripts; native acceptance remains pending. |

The initial smoke capture is [before-startup-2026-10-23.json](validation/before-startup-2026-10-23.json). The first optimization run compiled **677 Lua files** and passed **38 of 40 scripts**; its two failures and outputs are preserved in [before-test-failure-resolution-2026-10-23.json](validation/before-test-failure-resolution-2026-10-23.json). The [follow-up investigation](44-test-failure-resolution.md) fixes the underlying runtime defects and replaces stale source-text expectations with production-path tests and mutation controls. The final run compiles **681 Lua files** with no syntax errors and passes **44 of 44 scripts**. Whitespace and generated documentation/source-evidence checks pass. A dedicated luacheck executable is not installed; no luacheck pass is claimed. Final results and normalized Lua hashes are in [startup-2026-10-23.json](validation/startup-2026-10-23.json). Run `python -B tests/run_validation.py --output docs/validation/startup-2026-10-23.json --sync-docs` from the addon root. The Bars benchmark additionally accepts `lua tests/bars_startup_retry.lua --baseline`; its baseline is Git HEAD, not a matched WoW session.

## Client source checks and required game acceptance

The actual variable-readiness contracts were fetched from [live](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/EventUtil.lua), [classic_era](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_SharedXML/EventUtil.lua), [classic_anniversary](https://github.com/Gethe/wow-ui-source/blob/classic_anniversary/Interface/AddOns/Blizzard_SharedXML/EventUtil.lua), [classic](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_SharedXML/EventUtil.lua) and [forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/EventUtil.lua). Classic uses its `AreVariablesLoaded`/UIParent contract; Live and Forever use their CVar readiness contract. Forever's local `Blizzard_GamepadActionBars/MainActionBarFrame.lua` confirms `PostVariableSetUp` is reached through that barrier. Details ordering was checked against [the provider's parser lifecycle](https://github.com/Tercioo/Details-Damage-Meter/blob/d1e8ad7226616b4a796eebc6ca3ed905ef410b64/core/parser.lua).

The five-client automated policy fixtures cover cold combat loading, out-of-combat loading, missing repeated login, protected-write guards, partial failures, retry reuse, phase barriers, rapid world events, migrations and late dependencies. Existing fixtures add native-source-backed Forever paging/control actions, range/auras, grid events, bank/container behavior, inventory, character panels and trackers. Some existing tests need sibling reference/backup trees; the new standalone tests use mocked APIs and require no WoW installation.

All rows below still require actual client runs. Record the exact client/build, addons, clean/upgraded configuration, resolution/UI scale, keyboard/gamepad mode, errors, `/fluxstartup` observations and matched `/fluxperf` captures.

| Scenario | Live | Era | Anniversary | Progression | Forever |
|---|---|---|---|---|---|
| Fresh login, already-in-combat login, reconnect; reload during combat where permitted | Pending | Pending | Pending | Pending | Pending |
| Combat starts/ends during initialization; repeated regen and rapid transitions | Pending | Pending | Pending | Pending | Pending |
| Paging/modifiers, stance/forms, pet, mouseover/click-casting, raid combat | Pending | Pending | Pending | Pending | Pending |
| Vehicle/override/control bars where available, grids, trinkets, flyouts and proc/cooldown responsiveness | Pending | Pending | Pending | Pending | Pending |
| Late optional addons, rapid Flux Window switches, Details and native meter fallback | Pending | Pending | Pending | Pending | Pending |
| Low scale, ultrawide squeeze, saved profile upgrade and rollback inspection | Pending | Pending | Pending | Pending | Pending |
| Forever gamepad initialization, bank tabs/sentinels, swing/threat and character behavior | N/A | N/A | N/A | N/A | Pending |

There is no matched in-game startup/idle CPU/allocation/frame-time baseline in this environment. Capture those measurements before release; the desktop operation counts above must not be presented as FPS improvements or proof of complete native acceptance.
