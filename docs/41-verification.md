# Verification record and in-game checklist

This reference separates what can be established by reading files, desktop harnesses and a live World of Warcraft client. Documentation generation/validation does not execute gameplay.

## Evidence levels

| Evidence | Establishes | Does not establish |
|---|---|---|
| TOC/XML reachability | Which files/includes can execute and in what order, including declared client filters. | Actual widget/API safety, optional-addon readiness or successful initialization. |
| Source inspection | Branches, interfaces, persistence writes, hooks/queues and intended failure handling. | Live visual behavior or secure taint outcomes. |
| Static source assertion | A specific expected text/pattern remains present. | Semantic correctness; assertions can become stale after refactors. |
| Mock/executable logic test | Selected code paths behave under supplied API stubs and synthetic data. | WoW native restrictions, real secrets, template rendering or performance. |
| Live scenario | Observed behavior for a recorded client/build/configuration. | Every other client/addon/state combination. |
| Matched capture/measurement | Comparable timings/FPS/CPU for the recorded scene/setup. | Automatic attribution of all native/GPU work to Lua source. |

Do not label source-supported matrix entries as live-verified. A successful pcall is not a complete taint test.

## Audit baseline: 2026-10-22

Desktop runtime: **Lua 5.4.6**. The initial 22 smoke scripts yielded **20 passing scripts, 2 failing scripts**. The two failures were independently rerun at that stage with the same Core 1/Bars 26 source-contract result. This is the initial baseline, not a fresh result for the later source state. The documentation work did not change runtime code or smoke expectations. [40-findings.md](40-findings.md) records failure categories.

| Area | Existing scripts |
|---|---|
| Kernel/client/modern compatibility | Core/_tmp_coresmoke.lua, _tmp_clientguardsmoke.lua, _tmp_buffdebuffsmoke.lua, _tmp_playeraurassmoke.lua, _tmp_foreveraurassmoke.lua, _tmp_forevercombosmoke.lua, _tmp_foreverbarstylesmoke.lua, _tmp_classpowerscalesmoke.lua, _tmp_minimaplayoutsmoke.lua, _tmp_stancehidesmoke.lua. |
| Bars | Bars/_tmp_barsmoke.lua. |
| Character Info | CharacterInfo/_tmp_characterinfosmoke.lua, _tmp_foreverstatssmoke.lua, _tmp_foreverstatussmoke.lua. |
| Buttons/inventory/junk | ExtraButtonSystem/CombatGrid/Buttons/_tmp_ammosmoke.lua, ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua, Inventory/_tmp_inventorylag_smoke.lua, Inventory/Restock/Junk/_tmp_junksmoke.lua. |
| Micro/nameplates/raid | MicroMenu/_tmp_micromenusmoke.lua, _tmp_bagslotssmoke.lua, NamePlates/_tmp_combosmoke.lua, RaidFrame/_tmp_raidaurassmoke.lua. |

### Incremental checks after concurrent source changes

External work during the audit changed CharacterInfo/InfoFrame/WindowMover source and the Forever stats harness, and added a WindowMover harness. There are now **23 existing smoke harnesses**. Only the following targeted reruns are recorded after those changes:

| Harness | Result and limit |
|---|---|
| [CharacterInfo/_tmp_foreverstatssmoke.lua](../CharacterInfo/_tmp_foreverstatssmoke.lua) | PASS, rerun on Lua 5.4.6 on 2026-10-22 after the latest concurrent Info Frame/harness changes. Real providers, pin handlers and stat-update loop; mocked APIs, secret tokens and native formatted-text output. Includes changing combat values with unchanged layout samples, merged lines, visible/hidden native totals, alias/order migration, tooltip rows and combat recovery. |
| [WindowMover/_tmp_charactercombatsmoke.lua](../WindowMover/_tmp_charactercombatsmoke.lua) | PASS for real mover attachment/layout code under mocked hooks/combat, covering Forever keyboard/gamepad and Retail isolation/deferred recovery. It does not execute WoW's secure VM. |

The complete 23-harness suite was **not** rerun after these changes. Do not derive an updated whole-suite pass count from the historical 20/22 baseline plus two targeted checks. [Status bars](16-status-bars.md), [Character Info](27-character-info.md) and [WindowMover](28-window-mover.md) describe the concurrently updated implementations.

The latest targeted Forever run exited 0 and printed `Forever shared stats OK: native values, live combat text/merged rows, native totals, saved order, row clicks/tooltips; Live/Era/Wrath isolated`. The following SHA-256 fingerprints identify the tested files; later source changes require another targeted run before carrying this result forward:

| Tested file | SHA-256 |
|---|---|
| [CharacterInfo/_tmp_foreverstatssmoke.lua](../CharacterInfo/_tmp_foreverstatssmoke.lua) | `cd54622d6dd9cdf32066b5172895cc8e7499730149cb8e907be8e92679707df6` |
| [StatusBars/FluxInfoFrame.lua](../StatusBars/FluxInfoFrame.lua) | `4d61a1bd193137cc4e0d8b912eb87d1b7c12e1ebd93e730ed1172ee6775fec91` |

Harnesses are not TOC-loaded features. Some were already untracked/edited in the supplied working tree. Their desktop runtime differs from the native game environment.

Reproduce script discovery/run from the addon root in PowerShell:

```powershell
$smokePaths = rg --files -g '*smoke*.lua' -g '!libs/**'
foreach ($smokePath in $smokePaths) {
    Write-Output $smokePath
    & lua $smokePath
    Write-Output ("exit=" + $LASTEXITCODE)
}
```

For an individual failure:

```powershell
lua Core/_tmp_coresmoke.lua
lua Bars/_tmp_barsmoke.lua
```

[30-source-coverage.md](30-source-coverage.md) and documentation tooling inventory current source/include coverage. Generated links/default/API/event indexes must be regenerated when their source changes, then checked for missing files and stale links. A documentation check passing is independent from gameplay smoke failures.

## Publication verification: 2026-10-23

The addon/documentation publishing snapshot excludes the local simulator, its extracted client assets and its dedicated documentation. The original working addon and local simulator remain separate from this snapshot. Generated inventory hashes describe the published source bytes.

All **42 changed/new Lua files** pass `luac -p` on desktop Lua 5.4.6. The complete **23 smoke scripts** were rerun from the source workspace with the supplied Blizzard reference trees available: **21 pass, 2 fail**. The failures are the existing Core source assertion (1) and Bars source-contract assertions (26) documented above; they are not reported as passing or repaired by publication.

Running the same scripts in the standalone publishing checkout gives 13 pass, 8 blocked by missing sibling Blizzard reference files, and those same 2 failures. The reference trees are local test inputs and are not part of the addon repository. These desktop checks do not establish native taint/security, secret-value behavior, live UI appearance or WoW performance. Run the in-game scenarios below for each supported client.

## Client test matrix and record format

Run relevant scenarios independently on **Era, Anniversary/TBC, Mists, live Midnight and Forever**. Retained Wrath/Cata branches need their own records if those builds are part of a release target. Record exact build/interface, addon revision/working-tree state, enabled companions and versions, player class/spec/level, input style, profile/scopes, UI scale/resolution, steps, expected/actual result, errors and screenshot/capture where applicable.

Use both a controlled clean-data setup and an upgraded copy of existing saved data. Preserve real settings/bindings before reset/migration experiments. No live setup, reset or saved-data migration was performed by this docs audit.

## Startup and persistence

- Fresh first account login: settings packs, keyboard replacement, flags, no duplicate startup windows/errors; wait through deferred initialization.
- A new character after account setup: narrow raid/chat defaults, existing keys preserved; identity/profile selection ready at world entry.
- Reload, relog, world transitions and mid-session addon load: distinguish kernel fallback from feature-owned PLAYER_LOGIN startup.
- Toggle General account/character profile; each independent bars/layout/windows/micro/raid/unit/status selector; verify copy direction and active branch after reload.
- Profile copy/reset callbacks; old Unknown profile repair; always-character item/currency lists, stance order and PVP state.
- Forever full-name/surname display and canonical identity; upgrade records with old first-name-only/surname-as-realm keys and existing canonical destination.
- Existing restock data deletion/reset behavior and binding-v3/legacy snapshot handling, using saved-data copies. Confirm actual behavior before promising migration.

## Settings and native UI

- First setup, forced full apply, keys-only, CVar-only, reset/resetchar and category/Reset All Settings flows.
- Apply during combat and while Settings is shown; close Settings/end combat and verify queued work settles.
- Nameplate/raid previews, enum bitfields, missing CVars and active compact raid profiles.
- F5 post-login verification, deliberate custom bindings and CVar changes; observe reapplication and warning/state output.
- Native Character/Spellbook/Talents/Bags/Bank/game menu openings, logout/quit dialogs and Edit Mode enter/exit/spec/level transitions.
- Forever gamepad style loaded on/off, hardware connected without gamepad style, style switch/reload prompt, secure panel proxies and classic Flux dropdowns.

## Layout and presentation

- All Micro Menu presets, columns 1–8, collapsed/expanded minimap strip and custom button order/sizes.
- All three status placements, Info's four placements and integrated start/middle/end, player-target and stance choices, disabled Flux player.
- Flux Window tabs independently enabled/hidden; map/meter swaps; absent Details; minimal/hidden grids.
- UI scale floor 0.75, normal scale,16:9/16:10/ultrawide; resolution changes that leave uiScale unchanged; native gamepad bar floor.
- Main/minirow expansion, drag-over/cursor leave, bars/grids/trinkets/Info gaps and borders; repeated world entry.
- Class/atlas/custom accent, profile switch, Forever gold atlas mode and no-atlas fallback art. Check fill layers, click occlusion and arrow visibility.

## Actions, bindings and feedback

- Fill all 19 columns and both modifier rows; empty-slot promotion, Shift/Control priority, drag swaps, action ranks, form/stealth/page/vehicle/override transitions.
- Mouse press/release, key-down/up, right-click conjures, sequences, items, macros, empowered spells and held/released inputs. Repeat on Forever alternate click route.
- Plain-action mouseover vs unit-frame hovercast vs compiled macro targeting, helpful/harmful/unknown spells/items and targetless cursor hops.
- Binding create/edit/delete, forms, load conditions, chord ordering, badges, multi-cast, free overrides, spellbook creation, respec snapshot/apply.
- Proc glow continuity across main/mini/badge/extra faces; spell/item counts, cooldowns, recharge edge, checked/pushed/autorepeat state.
- Cast/channel/empower/interrupt/reticle/start-success-stop ordering, rapid replacement, macro conditional identity flips and pet/player isolation.
- Combat configuration edits defer structure; displayed context can refresh without repeated full binding apply. Revisit all current 26 bar source contracts with actual scenarios.

## Unit, raid, nameplate and character displays

- Player/target/focus/ToT/focus-target/pet/pet-target acquire/loss/death/ghost/offline/phase visibility; Flux-vs-Blizzard toggles.
- Readable and secret health/power, incoming heals/absorbs, casts, threat, class resources/combo points; aura full/diff/no-op/recycled payloads.
- Party/raid/group changes, pets/MT/MA targets, alpha-zero minis, range/dispel/private auras, tooltip unit-token reuse and preview.
- Live vs Forever nameplate threat policy, idle/engaged mob states, tank/non-tank colors, numeric/rank text and aura countdown.
- Swing enabled clients, flight path progress, pet changes and supported resource scaling.
- Character stats pins/unpins/order/gear changes; native recycled ScrollBox rows; Forever shared Hit/Crit/Haste folds and item-level formatting.

## Inventory, economy and Respec

- Bags/equipment/mail/auctions/void/guild/currency and character/account bank events; cold item data, split/merge/lock/move and stored/offline facts.
- Era/TBC built-in combined bag with and without alternative bag addons; keyring/reagent bags where available.
- Live bank tabs vs Forever bags-in-bank/sentinels, tab purchases, search/restock anchors and bank grow/shrink/drag.
- ConsumableBest rank/tier changes, charged mana gems/healthstones, reagents/crafting/mount flyability and utility assignments.
- Vendor target buying, bank restock partial stacks/whole stacks/cursor recovery, cancellation/combat/vendor/bank close and protected gear.
- Junk rules/manual lists, inferior tiers, bulk sell/repair, BuyEmAll currency/confirmation behavior and Already Known.
- Salvage eligibility/modifier/cursor/tooltip/protected sets plus Forever missing-atlas fallback.
- Respec enabled sections, missing gear/talents/runes, delayed binds, combat deferral, cancellation/resume/checkpoints and mismatched status/completion behavior from findings.

## Optional addons and repeated installation

Test absent/present/later-loaded companion states: Syndicator readiness, Baganator views/config/categories/protection/global identity wrappers, Details embedding/meter settings, BigDebuffs recycling, Questie pins/tracker, TacoTip stats, ConsolePort coexistence and SpellActivationOverlay proc sources. Ensure repeated world entry or view recreation does not multiply hooks or leave stale state. Include a harmless third-party item GUID/DoesItemExist caller when testing Baganator's global changes.

## Performance verification

Existing [September performance audit](performance-audit-2026-09-19.md) and [driver inventory](performance-driver-inventory.md) are historical evidence. Do not reuse their counts/paths or reported FPS as current measurements.

For a new comparison, keep client/build, scene, camera, resolution/scale, graphics/foreground state and addons constant. Wait for startup/inventory settling. Capture idle, target/cursor/modifier activity, group/raid/combat, map/meter, bag and bank operations separately. Use the current [command reference](31-commands-and-bindings.md) for capture/last/cancel, hop traces and diagnostic probes.

CPU profiling requires its own enabled/reload state and adds overhead; restore it before final unprofiled FPS comparison. Shared ticker counts, named pass timings, frame CPU and function CPU overlap and must not be summed as independent costs. A kernel "idle" flag does not prove no legacy/native/GPU work. No FPS improvement is claimed by this documentation change.
