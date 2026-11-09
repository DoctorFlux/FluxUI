# GitHub history, retained P0 fixes and startup recovery — 23 October 2026

The user asked whether the v9 comparison had lost the original P0/performance fixes, and requested the GitHub commits around `72fb194` and afterward. The live GitHub connector returned eight commits and one branch (`main`); branch pagination was exhausted. Comparing `72fb194` with remote `main` returned **identical, zero commits ahead/behind**. There is no published commit after it at the time of this audit. Later work described in the [unit/map report](53-unit-map-idle.md) remains in the local working tree.

[Machine-readable history, source fingerprints and v9 negative controls](validation/github-history-p0-2026-10-23.json) preserve the evidence. GitHub was read only; no checkout, reset, cherry-pick, commit or push was performed by this audit.

## Published history

| Commit | Date | Relevant scope |
|---|---|---|
| [72fb194](https://github.com/DoctorFlux/FluxUI/commit/72fb194ffc79337a0c8f65591c9579f40be06ce2) | 23 October | Priority startup/combat fallback, four named P0 fixes, retryable initialization, persistent window content, shared idle optimizations and diagnostics. |
| [2cedce8](https://github.com/DoctorFlux/FluxUI/commit/2cedce8379b27d1bb01bdaa900c7b9bed82792c3) | 23 October | Compatibility/documentation publication, including Forever paging/input, stock grid, Questie map/tracker changes. Parent of `72fb194`. |
| [7882474](https://github.com/DoctorFlux/FluxUI/commit/788247499f0a75cfa438d6babef84ea20260ef57) | 23 October | Binding, consumable, inventory, raid, character-stat and window-movement changes and implementation references. |
| [bccfe9f](https://github.com/DoctorFlux/FluxUI/commit/bccfe9fa12ad4fb22555283b6cab95ce2438f20b) | 16 October | Cross-client auras, inventory, unit-frame and combo-point fixes. |
| [3a9cdab](https://github.com/DoctorFlux/FluxUI/commit/3a9cdaba9b303cf59f1de748aec0c721380ffd2d) | 16 October | Removal of the older local performance tests. |
| [000ac65](https://github.com/DoctorFlux/FluxUI/commit/000ac6529d4a7e7b2ecee35c2fb65509d911fcd9) | 13 October | Stop tracking the local ignore list. |
| [0807fd8](https://github.com/DoctorFlux/FluxUI/commit/0807fd857cc36cc0e06fb8193a5b3eebe7e7acf8) | 13 October | Move FLUX_API under Core. |
| [d0b5bf5](https://github.com/DoctorFlux/FluxUI/commit/d0b5bf516ab709357af58c1721d5b85f6667f8c6) | 13 October | Initial import; the earlier destructive restock cleanup and global item-identity overrides were already present. |

The local repository contains these same eight commits. `72fb194` changes 161 files in total, including 90 runtime Lua/XML/TOC files after excluding test/smoke files. Current source retains 75 of those runtime files identically and modifies 15. None is missing or wholly reverted to its pre-fix parent. That whole-file check does not by itself prove every individual optimization survives; the source deltas, prior [retention audit](validation/idle-retention-post-v9-2026-10-23.json), newer behavior tests and native acceptance boundaries remain relevant.

## P0 status in the current checkout

| Required fix | Current evidence |
|---|---|
| Customized binding safety | `VerifyPostLoginDefaults` has no F5-driven reset path, and automatic `UPDATE_BINDINGS` reapplication remains disabled. The explicit reset path remains available. |
| Respec failure/checkpoints | Failed, thrown, rejected or invalid spell-binding restores terminate with failure and preserve the recovery checkpoint; asynchronous ownership/cancellation and rollback remain. |
| Blizzard item API ownership | The global `C_Item.GetItemGUID`/`DoesItemExist` overrides are absent. Relevant gear candidates use native identity queries locally. |
| SavedVariables integrity | Versioned validated restock migration retains legacy originals/rollback data, honors current choices and preserves bank records. Malformed roots are archived before repair. |

All seven relevant source files are **identical to `72fb194`**: `FluxDefaultSettings.lua`, `Respec/FluxRespec_Apply.lua`, `Binding/Respec.lua`, `BaganatorCompat/Loader.lua`, `BaganatorCompat/FluxBaganator_GearSets.lua`, `Inventory/Restock/Core/FluxRestockSettings.lua` and `Core/DB.lua`. Their installed copies match across Retail, Forever, Era, Anniversary and progression Classic. No P0 restoration was needed.

Conversely, all seven v9 copies match the parent `2cedce8` for these files. The backup therefore contains the older P0 behavior; it is not a safe source for restoring these fixes. Read-only substitution of six v9 source files into isolated regression processes was rejected: customized binding writes, false Respec success, unhandled restore failure, changed native item API ownership, lost legacy preferences and missing malformed-root recovery. The normal [binding/Respec](../tests/binding_respec_regression.lua), [data-integrity](../tests/data_integrity.lua) and [startup](../tests/startup_lifecycle.lua) checks pass on current source. The backup and live player SavedVariables were not modified.

First-install defaults and explicit reset behavior are separate from automatic post-login verification; this audit does not claim the entire defaults subsystem never writes bindings.

## Review of later changes

The fifteen modified runtime files from the original optimization commit contain subsequent stance/possess suppression, Edit Mode barriers, native player-container/mouse suppression, shared bag count readiness, transmog refresh events, queue-eye ownership/coalescing, opt-in diagnostics, trinket binding/scratch reuse, portrait face framing and geometry, bounded map watcher reuse, plus the recovery-queue correction below. Existing secure startup, saved-configuration and Forever gamepad barriers remain.

Native party/raid roots now retain their parent/shown state with alpha/input suppression. That can retain native work when grouped, but avoids restoring an unverified hidden-parent path implicated in the reported Edit Mode failures. It remains a candidate for controlled native profiling, not a demonstrated explanation of the idle FPS gap. No published commit after `72fb194` supplies a later FPS fix to restore. The commit itself explicitly recorded the remaining native FPS gap as unresolved.

## Additional recovery fix

[Combat.Flush](../Core/Engine/Combat.lua) detaches the pending batch before executing it. Previously, callback A could replace later key B, yet old B would still execute from the detached batch and new B would execute next frame. Current code skips old B when a newer B is pending. New requests keep the existing next-frame boundary; currently running callbacks, self-retries, unrelated keys and combat-interrupted recovery retain their behavior. No protected API, new timer, polling loop or client flag is introduced.

[Production replay](../tests/combat_queue_supersession.lua) compares the [retained earlier queue](../tests/fixtures/combat_queue_before.txt) across five client models, with and without profiling wrappers. The replacement scenario performs **4 → 3 recovery job executions** with the same latest result. Tests also cover repeated regen, self-retry, combat beginning mid-batch or before the scheduled frame, exceptions, unrelated jobs and profiling key accuracy. A stale-execution mutation is rejected.

[Full validation](validation/history-startup-audit-2026-10-23.json) records the current corpus. Desktop fixtures do not certify the native taint/secure VM, hardware input or FPS. All five native startup/combat/gamepad/gameplay acceptance scenarios and a controlled foreground FPS comparison with the Map tab open remain necessary; no FPS recovery or complete native taint resolution is claimed.
