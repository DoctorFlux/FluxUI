# Round 2: Equipment completion and cancellation

Both narrowly requested leads reproduce with the complete current production equipment owner and profile orchestrator. This audit wrote only this new folder. It did not modify addon code, existing tests, TOCs, settings, profiler preferences or game state.

| ID | Priority | Confirmed result |
|---|---|---|
| R2-CORE-05 | P1 | Cancelling a profile load stops the orchestrator but leaves Equipment's pending/active mutation work alive. Gear changes after cancellation on regen or the next swap continuation. |
| R2-CORE-04 | P2 | Missing requested gear produces a warning, then `APPLY_DONE(true,"DONE")` and a cleared load checkpoint while the actual production owner still reports a mismatch. Partial availability has the same false completion after equipping the available item. |

These are application-state reproductions under native inventory mocks. No actual gear was moved, and no native taint or protected-action failure was observed or certified.

## R2-CORE-04: incomplete requested gear becomes full success

The real `BuildSwapList` in `Respec/FluxRespec_Equipment.lua:1441` separates missing requested items from actionable swaps. `ApplyInternalCore:1683` warns when items are missing, but `:1687` calls `EndApply(true)` when no swaps exist. If other items are available, the subsequent successful swap pass also ends with true without incorporating the missing set. `EndApply:1615` invokes the real gear-phase callback; `FluxRespec_Apply.lua:674` accepts its true result and joins the later profile stages. `FinishSuccess:105` clears the checkpoint and emits success.

The harness loads the complete Compat, Inv, Includes, EquipmentSets, Equipment and Apply modules in their relative TOC order. Equipment methods, swap-list generation, inventory comparison, mutation loop and orchestrator are not replaced. Native inventory access and public `Flux.Inventory` facts are modeled at their boundary. A head-slot request has a different equipped item and no matching bag item. The real owner reports a mismatch before and after the load; nevertheless the load reports success and clears its checkpoint. A second case adds an available requested item: it equips exactly once, leaves the other requested item missing, and still reports full success. Both cases reproduce in all five client labels.

Per run:10 false-success cases, including five partial-success cases. These are the same10 cases repeated three times, not30 unique scenarios. Positive controls retain one successful equip, an already-matched no-op, an explicitly disabled equipment section and an uncaptured section.

Proposed correction: preserve the existing ability to equip available items, but carry unsatisfied requested identities through completion. Complete the gear phase only when all included wants are satisfied; otherwise return an explicit missing/incomplete result, retain a useful retry checkpoint and report the incomplete section. If intentional partial loading is a supported product choice, represent that separately from full `APPLY_DONE(true)` and checkpoint deletion. Preserve enabled-slot masks, jewelry-peer/duplicate rules, two-handed off-hand handling, rune identity normalization and successful-swap cadence.

Acceptance must include all-missing, available-plus-missing, fully available, late bag metadata, bank withdrawal completion, full bags when an included slot must become empty, excluded slots, already-matched gear, and truthful profile status after partial changes. Confirm that missing gear cannot silently authorize later stages as a fully completed profile. The currently simulated snapshots use itemID identity; native bank/rune/enchanted-duplicate behavior remains outside this repro.

## R2-CORE-05: cancellation does not own equipment work

`FluxRespec_Apply.lua:116` clears the Apply state and cancels pending bars/bindings/talents/runes. It does not cancel Equipment. `Apply.Cancel:181` emits `APPLY_DONE(false,"CANCELLED")` and clears the checkpoint, while `Equipment._pending`, `_active`, `_swaps`, `_applyDoneCallback`, its combat watcher and deferred swap callbacks retain their independent lifetime.

Two actual owner paths reproduce:

1. Start a mismatched load while combat is modeled active. `Equipment.Apply:1742` stores the request and registers `PLAYER_REGEN_ENABLED`. Cancel the load, then end combat and deliver that event. The actual equipment owner picks up/equips the requested item once, after cancellation.
2. Start outside combat with a modeled temporarily unsuccessful first native equip. The actual owner retains `_active` swaps and schedules its existing continuation. Cancel, allow the next native equip to succeed and deliver the queued callback. It equips once after cancellation.

Per run:five pending and five active cases, one mutation after cancellation in each. The stale orchestrator callback's `IsCurrent(id)` guard works: it prevents a second `APPLY_DONE(true)` but does not prevent the inventory mutation. That guard should be retained.

Ordinary source routes exist: `FluxRespec_UI.lua:2359` invokes the main load action; `FluxRespec_Core.lua:535` delegates through `LoadProfile` to `Apply.Run`. The profile dropdown's “No profile” action at `FluxRespec_UI.lua:2026` calls `Apply.Cancel`; changing profiles also cancels a running load at `FluxRespec_Core.lua:525`. The reproduction executes the production Apply/Equipment APIs, not those native UI controls. Current visible-window availability in combat was not tested. The active continuation case begins outside combat.

Proposed correction: give the gear request an explicit owner/token and cancellation operation. Capture that owner in the Apply state, and cancel it from both user cancellation and abort cleanup. Retire only that request's pending snapshot, active swaps, completion callback, watcher and deferred continuations. Guard callbacks by generation so a cancelled request cannot advance a replacement. Preserve already committed gear changes; do not roll them back or clear an unrelated player/foreign cursor. Stop at a safe continuation boundary rather than interrupting a synchronous native pickup/equip sequence midway. Equipment preset operations with a different/new owner must remain valid.

Acceptance must cover cancel-before-regen, cancel-before-swap-continuation, abort after another parallel section fails, cancel then new profile, cancel then a direct equipment-preset request, late inventory-lock events, repeated cancel and normal completion. Add bank-withdraw cancellation ownership tests before claiming that the complete gear operation can be cancelled in every phase. Pending bank sequencing and native asynchronous inventory behavior were not exercised here.

## Evidence and identities

[equipment_pipeline.lua.txt](equipment_pipeline.lua.txt) executes six complete production modules. The production EquipmentSets bridge is present; native equipment-set APIs are absent in the Era/Anniversary fixtures and present with no linked set in the other fixtures, so the real bridge selects its bag fallback. Optional talents/runes/bars/consumables/utility/bindings are uncaptured in these gear-only profiles. The earlier tests with stubbed Equipment cannot establish these two results.

[results.json](results.json) records three deterministic repetitions,225 assertions per run /675 total, with zero changes in12 pinned source/harness/runner files. Each run contains five client labels: Era, Anniversary, Retail live, Forever and the additional progression model. The main source identities are:

| Source | Raw SHA-256 |
|---|---|
| `Respec/FluxRespec_Equipment.lua` | `b5e878a30a774c5d120f094a3ff20b496c53a5b32ee71c0bf94ded43663fdd66` |
| `Respec/FluxRespec_Apply.lua` | `891c77da3faf71d66204a47eb452dc0952c919c28beb9d63e5cb0370bed10ba3` |
| `Respec/FluxRespec_EquipmentSets.lua` | `63ebd97206a3d65eb2352558df2f0f2430ab2ac7c4359d85e9253714cd067831` |
| `Respec/FluxRespec_Inv.lua` | `e503b361a46b6aaed71eba763e20db228ece4f6a85801ee126e81438962bcac1` |

The report makes no native CPU/FPS, rendering, taint, bank-access or secure-input claim. Fresh client/source pins and the external worktree baseline remain in the parent round-2 records. Replay from the addon root:

```powershell
python "Stress test doc/round-2/core-equipment/run_equipment.py"
```
