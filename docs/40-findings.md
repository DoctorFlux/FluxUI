# Findings, mismatches and unresolved questions

Initial audit: **2026-10-22**; current source/evidence refresh: **2026-10-23**. These are observations from the current working tree, including pre-existing uncommitted code/test edits. This documentation pass changes documentation only. A source mismatch or failed text assertion is not automatically a reproducible in-game bug.

## Current compatibility work and check status

The 23 October complete run passed **26 of 28** smoke scripts; all **662 publishable Lua files** passed desktop syntax checking. The same two source-contract scripts still fail, as detailed below. See the [current verification record](41-verification.md#current-verification-23-october-2026) and [per-script results](reference/verification.json). New control/grid/pin/tracker fixtures passed without changing addon Lua or relaxing expectations during this documentation refresh.

Recent implementation changes separate Forever's probed bar paging from its legacy no-wrap input policy, preserve native collectors, reserve the twelve control columns, suppress only stock grid event subscriptions, route Questie's own World Map pins alongside Forever's native providers, and guard saved native tracker callbacks even when Questie owns the visible dock. These are current source behaviors, not proof that the reported native taint issue is solved on all clients. Fresh-login combat/hardware-input tests remain pending. [Bars](11-action-bars.md), [binding](13-binding-system.md), [map](10-flux-window.md), [trackers](18-minimap-and-trackers.md).

The stock grid dispatch explains how bag pickup can reach native Edit Mode layout; it does not establish the first taint writer. A successful secure setup probe establishes that snippet execution worked at setup, not that every later protected interaction is safe. Ordinary main-page mappings, temporary control-page bypasses, pet visibility and native gamepad navigation must be evaluated separately.

## Existing smoke failures

The initial desktop Lua 5.4.6 run passed **20 of 22** then-existing smoke scripts. The two failures were rerun at that audit stage with identical results:

| Script | Observed result |
|---|---|
| [Core/_tmp_coresmoke.lua](../Core/_tmp_coresmoke.lua) | One failing source assertion: "salvage overlay has a visible fill when Forever lacks the proc atlas". |
| [Bars/_tmp_barsmoke.lua](../Bars/_tmp_barsmoke.lua) | SlotMath stage completes; subsequent source-contract stage reports 26 failures. |

The 26 bar source assertions cover:

- State clearing of pressAndHoldAction.
- Raid OnEnter token guard and alpha-zero MT/MA mini mouse handling.
- Vehicle Apply refreshing count/cooldown/equipped border.
- Classic-only stance parent selection.
- SetScript checks on identifiers named watch and healthBits.
- Form/page promotion restamping and repaint of count/cooldown/usable/equipped border.
- Context requests during burst/settle, cooldown/equipped settle repaint and shared Extra-face refresh.
- bars.icon registration of SPELLS_CHANGED and SPELL_UPDATE_ICON.
- Extra badgeMode question-mark fallback, SpellFX authoring size 44, native stance widget size and live SlotFrame button_size.

After that baseline, external work changed CharacterInfo source/tests and WindowMover, adding [WindowMover/_tmp_charactercombatsmoke.lua](../WindowMover/_tmp_charactercombatsmoke.lua). That intermediate corpus contained **23 smoke harnesses**. Targeted reruns of the changed [CharacterInfo/_tmp_foreverstatssmoke.lua](../CharacterInfo/_tmp_foreverstatssmoke.lua) and new WindowMover harness both passed. This is an incremental record; the full 23-harness suite was not rerun, so the original 20/22 result is historical. The mover harness models real attachment/layout code with mocked hooks and combat state, not WoW's secure execution VM.

These scripts mix source-text expectations with executable mock/logic checks. Some expectations can be stale after implementation changes; others can indicate a missing behavior. The correct classification requires examining each assertion and reproducing the intended scenario. No assertion or runtime code was relaxed to obtain a green report.

## Automatic defaults and imperfect verification semantics

Source: [FluxDefaultSettings.lua](../FluxDefaultSettings.lua), `ApplyKeybinds`, `GetState`, `VerifyPostLoginDefaults` and the login/reset event handlers.

- First account application automatically changes game settings **and replaces the keyboard layout**. ApplyKeybinds clears bindings outside its template. Later new-character setup is narrower.
- Official Blizzard Settings reset callbacks can restore Flux packs and keys, with modern deferral. The former docs' optional-setup wording understated actual effects.
- GetState compares a critical sample to Blizzard defaults, not to the Flux recommendation map. "Fresh/modified" is narrower than a Flux configuration audit.
- VerifyPostLoginDefaults lists three sentinel names and requires mismatchCount ≥ 4 for a sentinel-only CVar reapply. One listed name, deselectOnClick, is absent from FLUX_DEFAULTS, further reducing counted candidates. The sentinel-only condition cannot meet its current threshold. A wrong F5 Flux reload binding still triggers key and CVar reapply.
- accountDefaultsApplied is recorded after scheduling/attempting several guarded operations; it is not proof every deferred write succeeded.

These are source-confirmed semantics. Whether the threshold affects a reported user problem remains untested.

## Deliberate legacy-store deletion

Source: [FluxRestockSettings.lua](../Inventory/Restock/Core/FluxRestockSettings.lua), `DropLegacyStores`, called on this addon's ADDON_LOADED.

The function removes character VendorAuto, top-level bankSnapshot/bankSnapshotTime, the same snapshot fields under Restock, and global FluxRestockDB. The separate Bank branch is retained. The code describes a fresh-reset/rewrite transition; this is deletion, not a general old-to-new schema migration. The documentation records it so existing data is not mistakenly promised to survive untouched. No saved data was modified during this audit. The active Consumables Chronoboon helper can later recreate VendorAuto with restockItems and off automation defaults; see [Consumables.lua](../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua), InitRestockSavedVars. Deletion at addon load is therefore not proof of no later consumer.

## Respec binding failure can finish with a success event

Source: [FluxRespec_Apply.lua](../Respec/FluxRespec_Apply.lua), `StepSpellBindings`, its `afterBindings` callback and `FinishSuccess`.

A false binding callback warns that bindings could not apply, sets status to "Load failed.", then calls FinishSuccess. FinishSuccess emits `APPLY_DONE(true, "DONE")`. A synchronous noncombat binding rejection can also warn and continue through StepDone. Thus a warning/status and the orchestration completion boolean can disagree. This is confirmed control flow; downstream impact and live reproduction were not measured.

## Companion integrations have broad ownership

Source: [BaganatorCompat/Loader.lua](../BaganatorCompat/Loader.lua), `InstallItemIdentityCache`, installed when Baganator's API is ready.

The integration globally replaces C_Item.GetItemGUID and C_Item.DoesItemExist with bag/slot caches. GUID queries for identifiable non-Armor/non-Weapon classes return nil rather than forwarding, and cache invalidation follows bag/bank events. These semantics affect other consumers of those globals after installation, not only calls made by Baganator.

Additional active effects:

- [Protection.lua](../BaganatorCompat/FluxBaganator_Protection.lua), InstallSellCursorBlock, globally wraps SellCursorItem for protected gear.
- [CategoryVendorBlock.lua](../BaganatorCompat/FluxBaganator_CategoryVendorBlock.lua) wraps transfer/action/category handlers.
- [GearSetShield.lua](../BaganatorCompat/FluxBaganator_GearSetShield.lua) removes/replaces built-in equipment-set corner indicators and changes active border config.
- [EquipmentSetSection.lua](../BaganatorCompat/FluxBaganator_EquipmentSetSection.lua) and [ConsumablesCategories.lua](../BaganatorCompat/FluxBaganator_ConsumablesCategories.lua) mutate Baganator category/section configuration.

These are implemented integration effects, not proof of incompatibility. They invalidate a broad claim that Flux merely decorates companions without changing shared APIs/configuration. See [24-baganator-compat.md](24-baganator-compat.md).

## Bank split memory and transfer ownership

Source: [FluxBankRestock.lua](../Inventory/Restock/Bank/FluxBankRestock.lua), `BR.Start`.

The header describes split rejection state surviving session restarts. Current Start clears persistentSplitState.noSplit/fails/lastFailAt/cooldownUntil after tasks are built. The execution body therefore has narrower persistence than that comment implies.

[FluxItemMover.lua](../Inventory/FluxItemMover.lua) describes a single transfer owner, but active [MoveContext.lua](../Inventory/Restock/Bank/FluxBankRestockMoveContext.lua) and [MoveExec.lua](../Inventory/Restock/Bank/FluxBankRestockMoveExec.lua) also contain whole/split/place lanes. Documentation follows actual orchestration rather than treating that header as an exclusive ownership guarantee. Detailed behavior is in [20-vendor-restock-junk.md](20-vendor-restock-junk.md).

## Mirror-timer wrapper installation can repeat

Source: [Other/FluxDurationBars.lua](../Other/FluxDurationBars.lua), `InitializeDurationBars` and `HookMirrorTimerEvents`.

Both PLAYER_LOGIN and PLAYER_ENTERING_WORLD invoke initialization. HookMirrorTimerEvents wraps the current MirrorTimer_Show and current frame OnEvent handlers without installation guards, so later world entries can wrap previously installed wrappers. This is a source-level repeat-install observation; no CPU cost or visible failure is established. Repositioning itself returns for side-by-side player/target placement 2. See [25-other-qol.md](25-other-qol.md).

## Nameplate and window client gates exceed older prose

[NamePlates/Core.lua](../NamePlates/Core.lua) begins with a no-Blizzard-writes claim, but TintPlateChrome/ResetPlateChrome modify native regions. Later code reanchors modern health/CC/LoC elements, fades native Forever level text and hides live level frames. IsThreatSupported checks only C_NamePlate availability; IsLevelSupported excludes live Midnight but allows Forever. Earlier concept docs claiming no live threat path/no Forever level path were stale. The current matrix follows these bodies; native combat/preview safety still needs in-game evidence.

[WindowMover/Catalog.lua](../WindowMover/Catalog.lua), ShouldSkip, returns true for every entry when IsForeverGamepadUI is true. This is a whole-catalog exclusion, not merely a bag exception. The keyboard-mode dynamic bank behavior remains separate.

## Architecture and comment mismatches

- The TOC's old statement that bars/binding/grids remain unloaded contradicts its current file entries.
- Not all feature folders use Flux.Module. The registry has eight loaded registrations; many other systems own direct event/timer/global lifecycle.
- Module.Enable records enabled before calling protected OnEnable. A logged error does not clear the flag or generically undo setup. Required addon eligibility is not automatically retried by the registry on later addon load.
- New Flux.Timer avoids global C_Timer mutation; the legacy timer facade can install missing members.
- Flux.Client.isClassic and FLUX_API.isClassic mean different families.
- MouseoverCast opening comments say the Forever toggle drives a CVar, while current SyncCVar deliberately skips its write. Current GetForeverFrameDisplay uses scaled-percentage logic despite older raw/lead header prose.
- The old reference chapter described inspiration only/no vendoring; explicit ports, copied strings and embedded libraries exist.

These documentation discrepancies are corrected in [architecture](07-runtime-architecture.md), [services](08-shared-services.md), [client matrix](02-multi-client-matrix.md) and [provenance](90-reference-inspirations.md). The documentation work did not change runtime code/comments; external concurrent source edits are reflected in the updated subsystem chapters and incremental verification record.

## Remaining evidence limits

### Historical mock observation, 23 October: inactive Meter retry content

Historical simulator observation with a **missing native backend fixture**, not a reproduced live-client defect. The simulator has since been removed; its capture scenario is not an available current check. The source path remains reviewable: [FluxWindowFrame.lua](../Battlezonemap/FluxWindowFrame.lua), `InitializeWindowFrame` → Meter `TryEmbed`, queues retries without an active-tab/generation check. Meter onHide also shows its content frame after CleanupTabContent hid its regions. Opening Meter, switching to Map and advancing 0.4 seconds produces a new visible meter-loading label on the inactive tab in both Live/Forever lab profiles. This explains overlapping loading/error text in some lab captures.

When repairing addon behavior later, guard delayed callbacks against a changed active tab/window generation and cancel/ignore retries after leaving Meter. Test backend-not-ready, rapid tab changes and late native loading in game. This pass does not modify addon Lua or claim normal ready-backend gameplay is broken; the historical simulator is no longer available.

There was no interactive game session, native secure-engine test, screenshot comparison, release install/reset test or performance capture in this documentation audit. Optional addons, in-combat secret values, gamepad panel behavior and recycled native UI objects require in-game evidence. Broad matrix availability is source routing, not blanket "Full" certification. Full upstream revision/license provenance is also incomplete.

Dated performance documents are historical reports; their paths/counts/fix claims should not be promoted into current measurements. The current checklist, harness commands and evidence standard are in [41-verification.md](41-verification.md).
