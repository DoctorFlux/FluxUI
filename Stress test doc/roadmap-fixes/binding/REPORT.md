# Applied binding fixes and rapid modifier acceptance

The six `R2-BIND` groups and the reverse-index portion of `R2-MOD-01` are implemented. Runtime files and the permanent regression were frozen before the final central validation: **247/247 tests and 911 Lua syntax checks passed**. This report describes desktop production-code execution; native hardware input, the secure VM, actual secret values, rendering, taint and FPS remain untested.

The dated source/history/settings checkpoint is [checkpoint.json](../checkpoint.json). Exact consumed source hashes and behavioral rejection outputs are in [results.json](results.json); the original audit evidence remains in `Stress test doc/round-2/action-binding/`. No game, foreground, input, clipboard, WTF or profiler operations were used.

| Finding | Applied behavior | Production owner |
| --- | --- | --- |
| R2-BIND-01 | Multiple physical keys retain independent press owners; releasing Q cannot strand Q when E remains held. Both native binding keys are supported. All declared and absent modifier bits must match physical truth. Reassert work coalesces to one queued callback; original 0.08-second release grace and 1.5-second safety cap remain. | `Binding/Core/PushPress.lua:158`, `:336` |
| R2-BIND-02 | Recognized modifier prefixes are consumed without treating the literal minus base key as a separator. `-` and `SHIFT--` survive parsing and column lookup. | `Binding/Core/ChordMap.lua:40` |
| R2-BIND-03 | Each deferred respec request owns its completion and cancellation. A callback that queues a newer request cannot have that request overwritten or completed by the older stack. Revision ownership prevents an older rollback from replacing a newer successful document. | `Binding/Respec.lua:295`, `:330`, `:481` |
| R2-BIND-04 | Press shading uses validated public RGB owned by the painter. A range/usability repaint while held updates the base color and retains the existing 0.62 press multiplier; release restores the latest base. Nil, denied and opaque getter values cannot reach arithmetic. | `Binding/Core/PushPress.lua:208`; actual Bars/EBS painter integration |
| R2-BIND-05 | Removing the final logical slot program in combat retains a dirty-slot tombstone. Regeneration reconciles the latest model, including clears, replacement hosts and combat reentry. | `Bars/SlotProgram.lua:337`, `:370` |
| R2-BIND-06 | Free-chord pool names encode every nonalphanumeric byte, including underscore. Distinct punctuation/escape-like/UTF-8 chords retain separate world and hover frames and payloads. Removing one chord cannot clear its former collision peer. | `Binding/Core/Apply.lua:1659` |
| R2-MOD-01 | An unchanged unique reverse-index membership avoids removal/reinsertion. Real slot changes keep their original paint/badge/effect cadence; malformed duplicate memberships still repair. Immediate resolution is retained. | `Bars/Hosts.lua:117` |

`tests/binding_roadmap_regression.lua` passes **3,210 checks**, repeated three times. Its seven independent checkpoint controls reject at the corresponding behavioral assertion, and every fixed control passes. The controls exercise actual owners rather than source-pattern matching: overlapping keys, secondary native keys, grace/cap deadlines, every 8×8 declared/physical modifier mask, minus keys, nil/opaque RGB, actual complete Bars/EBS painters plus Range while keys are held, reentrant completion/rollback/regen, combat clears/replacement hosts, duplicate index repair and independent pool payloads. Existing binding respec behavior also retains its original 110-check regression.

The first captured BIND-06 baseline run lacked its `SecurePool.lua` dependency. That invalid rejection was replaced after extracting the exact dependency from the external checkpoint; the stored result now rejects at **“bijective chord frame identity including literal escape patterns”**. No missing-file failure is counted as evidence.

## Very fast Shift/Ctrl/Alt simulation

[modifier-spam.lua.txt](modifier-spam.lua.txt) changes the original defect-observation fixture into fixed acceptance: every scenario must finish with **zero** orphan press states. [modifier-results.json](modifier-results.json) records two complete repeated runs with stable before/after consumed-source hashes.

Each run executes **1,938,260 assertions across 8,640 scenarios** on Era, Anniversary, Retail, Forever and the existing progression identity, with both use-on-key-down settings. The matrix includes all eight held modifier chords; all six press orders; forward, reverse and deterministic random releases; overlapping Q/E holds; duplicate/reordered modifier messages with physical getter truth; same-frame and split-frame edges; mouseover transitions; and out-of-combat, combat and regeneration cycles.

| Per-run measurement | Result |
| --- | ---: |
| Modifier messages / derived physical modifier transitions | 1,399,680 / 267,840 |
| Physical state updates / route checks | 466,560 / 933,120 |
| Key-down / key-up events | 17,280 / 17,280 |
| Mouseover / regeneration events | 8,640 / 5,760 |
| Modeled updates / consumer callbacks | 760,320 / 2,819,520 |
| Orphan press states / attempted protected writes in combat | **0 / 0** |
| Reassert callbacks scheduled / maximum pending | 12,960 / **1** |
| Maximum deferred jobs | 3 |

Frame and hook counts stay fixed inside each client fixture: nine frames/three hooks for the classic and Retail identities; eleven/five for Forever. The original defect-observation run recorded 8,640 orphan cases; this is now zero without a manual all-clear. The model's ButtonFX click-policy stub and route assertions do not execute secure action bodies or establish native CVar edge behavior; the separate canonical click-wrapper controls cover their stated desktop scope.

## Modifier consumer work and repaired Forever paging

[consumer-index.lua.txt](consumer-index.lua.txt) executes complete current `Bars.State`/`SlotMath` with the actual Watch callback and IndexSlot function bodies. It separates **supported Forever secure paging** from an explicitly **unsupported fallback**. [consumer-results.json](consumer-results.json) captures a behavioral checkpoint rejection and three identical fixed passes: **330 assertions, 712,704 host visits and 149,226 real membership mutations per run**.

For 57 hosts and 1,024 repeated Shift messages in combat, 58,368 immediate host resolutions remain, while removals fall to **38 actual slot moves**. Gray-code chord changes retain all **24,320** actual moves and their paint/badge/effect notifications. Supported paging out of combat performs zero fallback host visits/attribute restamps. The deliberately unsupported out-of-combat path retains its existing 1,517,568 attribute writes in that 57-host scenario; combat always records zero attribute writes. Index membership stays exact and the four downstream paint buckets remain coalesced.

This fix removes redundant index mutation, not the immediate resolution cadence or unsupported fallback behavior. It introduces no broad modifier debounce, secure-capability bypass, extra driver or global native API replacement. Operation counts establish the measured work reduction only; native CPU/FPS and visual parity remain pending.

The public painter palette and ordering remain owned by the existing range/usability logic: out-of-range, mana and unusable colors, ordinary base colors and press darkening retain their priority. Unknown native color values are not cached or declassified. Native validation is still needed for secure input routing, real secret getter behavior, actual taint provenance, press appearance and combat/reload/client transitions.
