# Additional passive performance optimization

10 November 2026 — PASSIVE-PERFORMANCE-PASS2-20261110. The user requested more hotspots beyond the [first optimization](PASSIVE_PERFORMANCE_OPTIMIZATION.md) and [resource-effects follow-up](RESOURCE_EFFECTS_PERFORMANCE.md), with unchanged appearance, features and update speed and matched before/after simulations.

| Requirement | Acceptance |
| --- | --- |
| PP2-01 Find additional current work | Production-code replays establish new recurring/background or hidden-widget costs; already optimized paths are excluded |
| PP2-02 Preserve output and timing | Matched visible-state, identity, secret/error, native-reset, event and update-cadence checks |
| PP2-03 Reduce work without broad frameworks | Small changes using existing services and ownership; no blanket throttling or polling-interval increase |
| PP2-04 Show the difference | Exact checkpoint sources, three matched pairs per workstream, raw samples and harmful controls |
| PP2-05 Preserve compatibility/data | Five client families; no assets/defaults/bindings/SavedVariables/load-order changes; guild-bank/void callbacks excluded |
| PP2-06 Validate and retain evidence | Whole-module compilation, focused tests, full suite, source guards, generated inventories and continuity/ledgers |

The external `passive-performance-pass2/checkpoint-20261110T160229Z` preserves 2,543 files with a complete SHA256 manifest and verified Git history on main. All Lua files have exact external baseline copies. Available settings metadata was inspected read-only (53 entries); no private settings were copied and no quiescent backup is claimed.

Ten additional hotspots were optimized across eight runtime files. Three matched pairs cover each workstream, with 783 focused candidate checks per combined set and 60 rejected harmful controls. The full suite passes **295 scripts and 967 Lua syntax checks**. These are production-code simulations; they do not measure recovered native FPS or certify rendered pixels/taint.

The later [pass 3](PASSIVE_PERFORMANCE_PASS3.md) covers twelve further hotspots and passes 302 scripts / 974 syntax checks against the newer party/vendor/live-count baseline. Results below remain the original pass-2 workload evidence.

## Findings and changes

| Hotspot | Current owner | Change and preservation |
| --- | --- | --- |
| PP2-H01 Range probe closures | [Range](../Core/Engine/Range.lua) | Stable probe functions replace per-query closures, including cache hits; same memo keys, unit/frame invalidation, nil sentinel, native queries and item permission checks |
| PP2-H02 Protected helper closures | [Secrets](../Core/API/Secrets.lua) | Stable comparison/boolean functions receive the same operands; access guards, protected-operation order and existing fallback policies remain |
| PP2-H03 Combat retry chains | [Class power](../UnitFrames/FluxClassPower.lua) | Repeated power events coalesce protected position/visibility work in the existing combat queue; direct events and OOC recovery checks remain |
| PP2-H04 Duplicate cast clock reads | [Cast bar](../UnitFrames/FluxCastBar.lua) | Time text shares the successful synchronous sample at its original 50 ms gate; an owned clock revision detects same-stack replacement and forces a fresh read |
| PP2-H05 Severity arrays | [Raid prediction](../RaidFrame/FluxRaidPrediction.lua) | Four scalar results replace one new table per update; native/legacy queries, nil/false/secret results and sink order remain |
| PP2-H06 Parked checked polling | [Extra Button paint](../ExtraButtonSystem/Engine/Paint.lua) | Hidden faces no longer keep the dismiss/checked watcher alive; visible 0.5 s polling, 0.3 s settle and flash cleanup remain |
| PP2-H07 Parked count work | [Extra Button paint](../ExtraButtonSystem/Engine/Paint.lua) | Hidden inventory pulses skip count/usability/equipped work; reveal refreshes those three methods synchronously before queued full eval |
| PP2-H08 Hidden pending icons | [Extra Button paint](../ExtraButtonSystem/Engine/Paint.lua) | Parked unresolved icons no longer request useless metadata eval; visible unresolved icons retain all requests |
| PP2-H09 Collector scans | [Addon button collector](../MicroMenu/FluxAddonMicroButton.lua) | Fixed excluded-name lookup and stable callbacks reduce pattern/temporary work; all roots/libraries, linear child snapshots and original 10 s scans remain |
| PP2-H10 Meter timer election | [Meter skin](../Battlezonemap/FluxMeterSkin.lua) | Stable scalar election helper removes a per-sync closure; every visibility/coordinate/scale read and alpha/text write remains |

## Before and after

These are separate bounded synthetic workloads. Counts and heap differences must not be added into a total CPU/FPS percentage. Heap samples use paused desktop Lua 5.4 garbage collection after warmup; they measure temporary uncollected allocation, not WoW retained memory.

| Workload | Exact checkpoint | Candidate |
| --- | ---: | ---: |
| 600 player power events / 60 s combat: retry timers created | 36,300 | 0 |
| Same case: retry callbacks fired | 35,700 | 0 |
| Same case: layout calls during post-combat restoration | 1,200 | 2 |
| 60 s cast at 60 FPS: each duration/remaining getter | 4,800 | 3,600 |
| Same cast: time-text paints | 1,200 | 1,200 |
| 48,000 raid prediction updates: severity arrays, each native/legacy path | 48,000 | 0 |
| 40 parked mount faces / 60 s: watcher callbacks / journal queries | 120 / 4,800 | 0 / 0 |
| 1,000 inventory pulses: bag / usability queries | 52,000 / 52,000 | 4,000 / 4,000 |
| Same case: equipped / visible spell-count queries | 96,000 / 2,000 | 8,000 / 2,000 |
| 1,000 metadata events: hidden-only / visible pending icon requests | 1,000 / 1,000 | 0 / 1,000 |
| 10,000 core workloads: distinct range / protected callback functions | 30,000 / 50,006 | 3 / 9 |
| Same core workload: native range probes / uncollected Lua heap | 3 / 10,000.151 KiB | 3 / 0.026 KiB |
| 360 collector scans: pattern matches | 1,620,000 | 252,000 |
| Same scans: child-name reads / root enumeration | 72,000 / 720 | 72,000 / 720 |
| Same scans: uncollected Lua heap | 1,375.312 KiB | 1,164.402 KiB |
| 10,000 meter timer synchronizations: uncollected Lua heap | 3,437.531 KiB | 0.031 KiB |
| Same meter case: alpha / text writes | 30,000 / 10,000 | 30,000 / 10,000 |

Cast comparisons also cover 144 and 240 FPS. Each getter falls 9,720→8,640 and 15,508→14,400 respectively, while text paints remain 1,080 and 1,108. The original accumulator's frame quantization remains; no timer/text interval is slowed.

Class-holder restoration is an intentional bug fix: many independent half-second combat retries become one shared-regen restoration at the first legal opportunity. The 600 real power-event requests remain. Missing-service fallback keeps one half-second retry, and OOC 0.1/0.5/1 s recovery paths/native-reset checks remain. Native class bars continue owning their value events. Fresh native source found no ordinary combat-end holder reset; vehicle/art reset events retain the existing recovery paths.

Reveal now performs three bounded paint methods before the existing scheduler request. This preserves the first visible count/tint/equipped state after hidden inventory changes; hidden parents and stale widget owners stay gated. It trades a little reveal work for less background work and immediate correctness.

Collector child arrays are deliberately retained. A zero-table vararg traversal performed quadratic copying on large child lists and was rejected. The final implementation uses a linear child snapshot and preserves enumeration-error isolation and reparent-safe traversal. Additional 100/500/1,000-child CPU replays show named roots faster in the desktop model; unnamed-root samples are noisy/overlapping, so no CPU win is claimed for that case. Native CPU/FPS was not measured.

## Behavior and regression evidence

| Workstream | Candidate checks / matched pairs | Rejected controls |
| --- | --- | ---: |
| Core helpers and range | 233 / 3 | 12 |
| Class power, cast text and prediction | 96 / 3 | 14 |
| Parked Extra Buttons | 340 / 3 | 20 |
| Collector and meter timer | 114 / 3 | 14 |

Public/opaque/error traces, native clock/query counts, unit/frame invalidation, reentrant item-module ownership and same-stack cast changes are covered. Extra Button traces retain 95 visible samples across five client models, including assertions before the scheduler flush. Unit traces retain cast time, native/legacy prediction severity and ordinary OOC anchor behavior. Meter election retains donor/winner/order/scale and opaque text forwarding; collector tests retain external root providers, global-rebind snapshots, library callbacks, errors and late children.

Independent review found and corrected three candidate regressions before final validation: queued reveal painting could expose a stale count; synchronous cast replacement could reuse the preceding clock sample; and allocation-free collector traversal could cost quadratic CPU. Their controls and raw rejected-candidate evidence remain external.

Only the eight runtime owners above and five new tests change. All other runtime files, including the preceding combat-partition/resource-effect fixes, remain byte-identical to the checkpoint. All 252 appearance/XML/TOC files and 80 options/binding sources are unchanged. No existing test fixture was weakened or rewritten in this pass. Generated inventories and continuity/client/parity/performance ledgers record the current source.

Documentation validation also passes: 1,000 classified sources, 607 reachable files, 427 settings, 24 SavedVariables roots and 16,182 local links. The full validation and comparison source hashes match the final files.

Run the focused checks:

```text
lua tests/passive_core_allocation_work.lua
lua tests/passive_unit_updates.lua
lua tests/passive_ebs_visibility.lua
lua tests/passive_world_pass2.lua
lua tests/meter_timer_allocation.lua
python tests/run_validation.py --output <external-result.json>
python docs/tools/validate_docs.py
```

Exact baseline/candidate hashes, commands, samples, controls, peer reviews, source checks and full validation are retained in the [evidence record](validation/passive-performance-pass2-2026-11-10.json). The final world comparison supersedes its earlier select-based/zero-heap experiments.

The five source branches were resolved once for this pass. Forever advanced to `4cd0ab752a77164f654ccbca9d0c1fe8dafceebe`; its needed contracts are checked at that pin. The other four pins remain those in the preceding reports. Native FPS, pixels, secure operation permissions and memory impact remain unmeasured. WoW stays in the background; no client input, settings/profiler writes, manual sync or publication is part of this pass.

Twenty-five exact native records / twenty distinct Git blobs were independently verified. Native PlayerFrame combat-end handlers update hate/status, while vehicle/player-art paths and managed child layout have separate ownership. [Fresh Forever PlayerFrame](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_UnitFrame/Mainline/PlayerFrame.lua), [Retail counterpart](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_UnitFrame/Mainline/PlayerFrame.lua). This is source evidence; actual event/next-frame ordering remains a native acceptance item.

Repeated native meter row styling remains a measured work candidate, not an optimized result. Its getters are deliberately outside the existing native data/art ownership contract; this pass adds no native texture/atlas/color reads and leaves those setters intact. Likewise, the previously retained embedded-map and secure character-button mirroring costs remain for native attribution. Scoped raid work changes allocation only; broader party/raid feature work and native sessions remain paused.

## Native acceptance

Native frame time/FPS, memory, pixels, secure operation permissions and physical/controller input remain NOT RUN. These changes add no interactive controls or input/focus stops. Use the existing optional profiling protocol for matched native captures, preserving previous profiler preferences.

Check class resources through a busy fight and combat end; casts/channels/empower and immediate replacement; hidden Extra windows/badges with count/equipment/metadata changes before combat reveal; current raid prediction; addon-button collection and native/owned meter timer election. Include native resets and all five supported clients. Leave WoW in the background and retain the user-managed synchronization policy.
