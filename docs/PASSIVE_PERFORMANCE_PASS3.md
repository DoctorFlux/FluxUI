# Passive performance optimization, pass 3

10 November 2026 — PASSIVE-PERFORMANCE-PASS3-20261110. Continue the user's request to find more passive FPS/CPU hotspots and optimize them while preserving appearance, features and update speed. The [preceding pass](PASSIVE_PERFORMANCE_PASS2.md), newer party-debuff work, vendor Junk fixes and live-count corrections remain the baseline.

| Requirement | Acceptance |
| --- | --- |
| PP3-01 Identify new loaded work | Check TOC/runtime gates and replay current production paths before editing |
| PP3-02 Preserve behavior and cadence | Visible/animation/native-reset/identity/reentrant/secret/error traces; no interval increases |
| PP3-03 Reduce work with existing ownership | Small source changes; preserve native facts, dynamic overrides, input and saved data |
| PP3-04 Compare before/after | Exact checkpoint sources, three matched pairs per workstream, raw counters/allocation samples and harmful controls |
| PP3-05 Preserve supported clients and boundaries | Five existing client families and actual feature gates; guild-bank/void callbacks excluded |
| PP3-06 Validate the final files | Whole-module syntax, focused/full regressions, source guards, documentation and continuity ledgers |

The external `passive-performance-pass3/checkpoint-20261110T172656Z` preserves 2,561 files, a complete SHA256 manifest and verified Git history on main. All Lua files have exact external baseline copies. Settings metadata was inspected read-only (53 entries); no private settings were copied and no quiescent settings backup is claimed.

Work is bounded to additional core lookup/helper allocations, inventory indexing, active mana/swing styling, raid dirty buffers and loaded Classic character computations. Fresh party-debuff and vendor Junk implementations are preserved. Concurrent combat-grid count changes are retained and included in the combined integration checks. Historical unloaded character copies are excluded.

Twelve additional hotspots were optimized across eight runtime files. Four workstreams each have three matched before/after pairs. Their combined focused set passes 99,781 checks, largely the inventory option/region matrix, and rejects 57 harmful controls. The combined full suite passes **303 scripts and 975 Lua syntax checks**. These are simulated production-code work and behavior results, not recovered native FPS.

## Findings and changes

| Hotspot | Owner | Change and preservation |
| --- | --- | --- |
| PP3-H01 Checked spell lookup callbacks | [Spell](../Core/API/Spell.lua) | Hoist identifier/current/autorepeat callbacks; retain a fresh per-call dedup map, candidate order, native/global queries and reentrancy |
| PP3-H02 Numeric fallback/coercion closures | [Secrets](../Core/API/Secrets.lua) | Hoist last-number fallback and protected arithmetic operations; preserve conversion/default/access/error policy |
| PP3-H03 Aura payload guard closures | [Secrets](../Core/API/Secrets.lua) | Hoist list-length/list-secret helpers, with the same guards, field order and short-circuit policy; no additional aura updates skipped |
| PP3-H04 Count option tables | [Inventory index](../Inventory/Index.lua) | Read normalized scalar options without allocating a table in GetCount; preserve aliases, capability checks and property-read order |
| PP3-H05 Live-count conversion closures | [Inventory index](../Inventory/Index.lua) | Hoist conversion helper; retain dynamic Index.GetCount/backend seams, native arguments, loading/zero/charge semantics and one required normalized options table |
| PP3-H06 First-location full result construction | [Inventory index](../Inventory/Index.lua) | Return the first fresh location directly in the same region/pairs order; complete Find remains unchanged and overridden Find still runs |
| PP3-H07 Settled mana-tick layout writes | [MP5 overlay](../UnitFrames/FluxMP5Overlay.lua) | Cache owned attachment/level/spark-height writes; keep power/max/value and moving spark frame-synchronous |
| PP3-H08 Settled swing presentation | [Swing timer](../UnitFrames/FluxSwingTimer.lua) | Suppress unchanged owned level/label/alpha/color writes; retain live speed/value/time, fade cancellation, OOR behavior and native-reset recovery |
| PP3-H09 Raid dirty-flag allocation | [Raid unit](../RaidFrame/FluxRaidUnit.lua) | Recycle a cell's dirty table only after painting; active/reentrant buffers stay separate and all flags/paint timing remain |
| PP3-H10 Discarded level metadata | [GearScore](../CharacterInfo/GearScore.lua) | Remove GetItemInfo calls used solely by an unread LevelTotal local; primary scored-slot/cold-data/Titan Grip queries remain |
| PP3-H11 Discarded palette calculation | [GearScore](../CharacterInfo/GearScore.lua) | Remove private RGB calculations that are never returned or used; public tier/color getter and TacoTip precedence remain byte-identical |
| PP3-H12 Repeated quality names/helper allocation | [Paper-doll quality](../CharacterInfo/PaperDollQuality.lua) | Hoist immutable 20-slot names and helper; retain fresh widget lookup, duplicate traversal, every query/setter and the existing hidden-panel gate |

## Matched measurements

Each row describes its own workload. Counts must not be summed into an overall FPS/CPU percentage. Heap samples pause desktop Lua 5.4 garbage collection: they measure temporary uncollected allocation, not WoW retained memory.

| Workload | Exact checkpoint | Candidate |
| --- | ---: | ---: |
| 10,000 core workloads: checked / protected callback identities | 20,000 / 40,005 | 2 / 7 |
| Same workload: native spell queries / temporary Lua heap | 200,000 / 12,422.312 KiB | 200,000 / 3,594.062 KiB |
| 20,000 snapshot count queries: normalized option tables | 20,000 | 0 |
| 20,000 live count queries: normalized tables / conversion helper identities | 40,000 / 20,000 | 20,000 / 1 |
| Same live count queries: native calls | 20,000 | 20,000 |
| 1,000 first-location lookups with 100 matches: rows constructed / slots visited | 100,000 / 100,000 | 1,000 / 1,000 |
| 60 s at 144 FPS, active mana tick: anchor / level / spark-height writes after setup | 17,280 / 8,640 / 8,640 | 0 / 0 / 0 |
| Same mana tick: power / maximum / value / moving-spark work | 8,640 each | 8,640 each |
| 60 s at 144 FPS, in-range swing: level / label writes after setup | 17,280 / 8,640 | 0 / 0 |
| Same swing: alpha / text-color writes | 17,280 / 17,280 | 0 / 0 |
| Same swing: UnitAttackSpeed reads | 17,280 | 17,280 |
| 40 raid cells × 20 Hz × 60 s: distinct dirty-flag tables | 48,000 | 40 |
| Same raid case: health/status/prediction paints | 144,000 | 144,000 |
| 1,000 active legacy GearScore calculations: metadata / inventory-link reads | 36,000 / 18,000 | 19,000 / 18,000 |
| Same score case: discarded private palette calls | 17,000 | 0 |
| 10,000 visible legacy quality refreshes: quality queries / each texture/color/Show sink | 400,000 each | 400,000 each |
| Same quality case: temporary Lua heap | 4,143.817 KiB | 3.192–3.317 KiB |

Mana/swing comparisons also cover 60 and 240 FPS. The original tick, swing progress, frame-synchronous moving geometry and native speed queries remain. These costs occur only while the existing features are active. GearScore/Classic paper-doll chrome is gated off for Retail, Forever and Mists; within the five selected families its work applies to Era/Anniversary. Extra TBC/Wrath model checks preserve the module's existing gates without adding client support or installing copies.

## Preservation and tradeoffs

Owned UI caches accept only public readable keys; opaque inputs retain existing forwarding/fallback behavior. Cache invalidation before writes and public write revisions preserve transient failure and same-stack reentry. A nested attachment can leave the same transient mixed anchors as the baseline; invalidated caches repair them at the next original paint. Current owned frame-level reads remain to repair resets. No native GetAlpha read was added.

Native fade start/cancel/finish remains authoritative. The swing replay executes the pinned FrameUtil fade implementation against modeled widgets, including fade interruption by a new swing. Each raid cell retains at most one idle spare table; active and reentrant buffers are separate, and unbind/error cleanup cannot retain old-unit flags.

Spell lookups retain their per-call identifier map rather than sharing scratch state across reentrant calls. Inventory still builds one normalized table for live queries and a fresh location result. No result cache or native-fact suppression was added. First-location queries intentionally stop after the first result instead of visiting unused tail records; complete Find and its integration seam remain unchanged. Guild/void stored-fact options are covered, while their callback bodies remain excluded.

The character changes affect the loaded CharacterInfo owners. Historical Other copies remain raw-byte identical. Metadata queries still run for every scored slot, including uncached data; native cold-cache/event timing remains a client check. Public GearScore color calculations, formulas, outcomes and all quality query/paint traces match.

## Validation

| Workstream | Focused checks / matched pairs | Rejected controls |
| --- | --- | ---: |
| Core lookup and numeric/aura helpers | 173 / 3 | 12 |
| Inventory index | 99,237 / 3 | 15 |
| Mana/swing/raid dirty buffers | 119 / 3 | 16 |
| Loaded character computation/chrome | 252 / 3 | 14 |

Inventory retains 15,405 semantic trace samples; unit comparisons retain eight behavior groups; character score/color and quality query/paint traces match. Independent peers reviewed all four workstreams. Whole-module syntax passed before integration.

The initial full run passed 301 scripts but rejected an obsolete mutation in the raid rebind test: removing only the pending map entry no longer retains old work because the buffer is cleared too. The updated control removes the full current cleanup block and is rejected by the unchanged functional assertion. No runtime fix was needed. That initial result and the subsequent 302-script success are retained externally. Concurrent combat-grid edits added another test; the combined full run passes 303 scripts / 975 syntax checks with source stability checked before and after the run.

This pass owns eight runtime changes, four new tests and one updated negative control. Independently changed ConsumableBind, Paint and the combat-grid use-event test are preserved separately in the evidence; no performance result here is attributed to those changes. Every other runtime owner, including fresh party-debuff and vendor Junk fixes and unloaded historical character copies, remains byte-identical to the checkpoint. All 252 appearance/XML/TOC files and 80 options/binding sources are unchanged. Earlier protected comparison/count helpers also remain unchanged within Secrets. Generated inventories, continuity records and parity/client/performance ledgers record the combined final files.

```text
lua tests/passive_core_lookup_work.lua
lua tests/passive_inventory_index.lua
lua tests/passive_unit_styles.lua
lua tests/passive_character_work.lua
python tests/run_validation.py --output <external-result.json>
python docs/tools/validate_docs.py
```

Exact sources, commands, raw pairs, harmful controls, peer reviews, initial/final validation and native references are retained in the [evidence record](validation/passive-performance-pass3-2026-11-10.json).

Five Gethe branches were resolved once for this pass and match the preceding pins: Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`, Forever `4cd0ab752a77164f654ccbca9d0c1fe8dafceebe`, progression `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`, Era `4192ac60067fc55566182291bc67c85dd9b6794d`, Anniversary `68e0a2ec559d9761dfc4e7f864c3944f9d758a49`.

Native FPS/frame time, retained memory, pixels, actual secure permissions and physical/controller input remain separate acceptance checks. No client control, settings/profiler writes, manual synchronization or publication is part of this pass.

Twenty-one native source records / ten distinct Git blobs are verified, including the canonical [Forever FrameUtil](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua). Style setter declarations supply no Boolean-success return contract; this is distinct from the earlier status-bar texture loader. Those declarations do not certify instance permissions, silent failures, native fades or pixels.

Use the existing optional native profiling route for matched client captures, preserving prior preferences. Check active mana ticks and secondary mana, swing/fade/OOR/restarts, native level/size resets, combat raid rebinds and auras, live zero/charge count behavior, fresh first-location queries and Classic character gear/quality updates. Leave WoW in the background and keep the user-managed synchronization policy. Broader party/raid feature work remains outside this allocation/style pass.
