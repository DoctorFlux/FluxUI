# Retail idle capture and shared hot paths — 23 October 2026

The user reports the FPS regression across all clients. This continues the [shared idle investigation](46-idle-followup.md) after the [stance/input corrections and v9 retention check](51-input-and-native-callbacks.md). All five installations use the changed source; native timing evidence in this phase is Retail only.

The next [unit-frame, portrait and open-map follow-up](53-unit-map-idle.md) retains these changes and adds owned-geometry controls and reusable map initialization watchers.

## Native baseline

The user captured Retail Midnight build **70529** at **16:58:25**, with `scriptProfile=1`, then saved the report through a normal reload and restored profiling to zero. [The complete exported capture](validation/retail-idle-profiled-2026-10-23.json) contains only `FluxPerfCaptureDB`, with no other player SavedVariables exported or edited.

The 20-second capture reports **288.82 FPS average / 240.00 minimum**, Flux CPU **13.78 ms/s**, 34 visible OnUpdates at both endpoints, and no shared ticker subscribers. The World Map and character panel are hidden; Flux Window's Map tab and embedded Battlefield Map are visible. It is not a matched enabled/disabled addon comparison or a cross-client performance claim. FPS under profiling must not be compared directly with unprofiled measurements.

| Inclusive function/owner | ms/s | Calls | Interpretation |
|---|---:|---:|---|
| Native `GlobalCallbackRegistry.lua:9` dispatcher | 11.74 | 5,590 | Shared callback work; ownership does not identify the individual contributor. |
| Native embedded map detail layer | 7.04 | 5,590 | Shared function with two registered owners, one visible. |
| Flux trinket press watcher | 6.36 | 5,590 | Directly attributed to `FluxTrinketMenu.lua:534`. |
| `FluxRestockTiers.RememberOwnedTiers` | 6.30 | 4 | Overlaps reference, bag tier, usability and tooltip work. |
| `FluxConsumableBest.Score.IsUsable` | 5.00 | 540 | Live usability checks; correctness depends on current item/player state. |
| `FluxItemClass.GetTooltipText` | 3.10 | 740 | Includes overlapping callers; not all calls belong to the tier scan. |

These rows overlap and must not be summed. The recent profiling metric separately reports Flux **0.08394 ms/tick**, all addons **0.09092**, application **3.42583**. Its sampling/window semantics differ from the legacy CPU counters; it is not an isolated GPU or native UI rendering measurement. The few tier scans and 72 item-data callbacks during this interval can include asynchronous settling, rather than permanent idle polling. No arbitrary delay or scan cadence change is introduced.

## Changes

[Trinket push feedback](../ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua) still checks physical keys and modifiers every frame while the existing watcher is active. It caches binding keys and parsed chord metadata on setup/visibility synchronization and `UPDATE_BINDINGS`, including during combat. It replaces two per-frame temporary tables with two held-widget locals and a reusable clearing buffer; mouse release has its own clearing buffer. The former `MODIFIER_STATE_CHANGED` subscription had an empty handler and is removed: modifier state still reads on the next rendered frame. Secure clicks, native binding ownership, action timing, wheel flash, mouse press shading, single-equipped-slot routing and the hold safety cap are unchanged. This avoids depending on key-down `OnClick` notifications that release-only secure bindings may not deliver.

[Bag tier selection](../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua) now classifies a bag item before testing its usability. Only matching, non-conjured, non-Well-Fed items whose rounded restore exceeds the current best can win the ladder; those candidates receive the same live usability check as before. Unrelated equipment, wrong kinds, excluded consumables and noncompetitive restores no longer generate usability tooltip queries for every tier kind. No usability result or bag answer is cached. Existing classification invalidation, immediate player-state changes, tie selection, snapshot/live fallback, carried-bag scope and saved reference rules remain authoritative. Merchant checks, bank topology and sell/restock behavior are unchanged.

Neither change replaces a Blizzard method, writes a keybinding, mutates a protected attribute or adds a native hook. No new timer, reduced animation frequency or player option is introduced.

The follow-up also coalesces simultaneous native chat button-side/alert hook requests into one retry batch per frame. The immediate next-frame pass and 100 ms/one-second late-anchor retries remain at their original deadlines; a subsequent frame can request its own batch. Existing Edit Mode deferral and optional QuickJoin/channel capability checks remain. Battlefield Map tab discovery now uses its existing event frame for bounded polling, instead of allocating a new frame on every login/world event. A known tab needs no discovery callback, and a delayed tab after optional addon load has a bounded retry. MapCanvas animation, pins, mouse input and map update cadence are unchanged.

## Deterministic controls

[Trinket replay](../tests/idle_trinkets.lua) executes the production watcher against its [retained earlier body](../tests/fixtures/trinket_push_before.txt). It compares visible push/icon/shade state across keyboard/mouse/wheel, modifiers, binding changes, release-only input, both or one equipped slot, hide/show, missing physical input responses and the safety cap. Four targeted mutations are rejected. Across 4,800 unchanged frames, repeated native binding lookups fall from **9,600 to zero** and temporary host Lua allocation from **1,275.09 KB to zero** with GC paused only in the fixture. Physical polling cadence is unchanged. These figures are operation counts, not measured native CPU/FPS gains.

[Tier replay](../tests/idle_tiers.lua) executes the complete matching module against the [prior bag selection body](../tests/fixtures/tier_owned_before.txt). Five client/adapter models compare returned restore values/item IDs and saved references, mutable usability without a bag event, delayed classification, zero counts, combo/pure water, conjured/Well-Fed exclusions, live fallback and older adapters. Three targeted mutations are rejected. A five-kind scan over 120 bag IDs reduces live usability calls from **600 to 8** in the fixture. This does not claim every inventory has that ratio.

[Layout retry replay](../tests/idle_layout_retries.lua) executes actual chat hook/scheduling and map tab discovery bodies against retained [chat](../tests/fixtures/chat_retries_before.txt) and [map](../tests/fixtures/map_tab_watch_before.txt) implementations. It covers all five client models, later layout changes, all three chat deadlines, absent/late optional controls, native Edit Mode deferral, late map addon/tab creation and bounded polling after rapid transitions. Six behavioral mutations are rejected. In the fixture, setup plus 300 same-frame chat hooks drops from **903 to 3 timers**; initial discovery plus 102 login/world events drops from **104 to 1 watcher frames**. These are allocation/operation controls, not measured FPS gains or evidence that transient callbacks explain the sustained idle gap.

[Full validation](validation/retail-idle-optimization-2026-10-23.json) records the syntax corpus and all regressions, including startup/combat queues, client guards, binding/respec, migrations, integrations and the previous idle fixtures. Tests preserve prior expected behavior; no assertion is relaxed to make these changes pass. Desktop mocks do not execute WoW's secure/taint VM or rendering engine.

## Native acceptance

### Comparison with the user's working baseline

The user identified [72fb194](https://github.com/DoctorFlux/FluxUI/commit/72fb194ffc79337a0c8f65591c9579f40be06ce2) as the commit that made the FPS drop less severe. Local `HEAD` is that exact commit; v9 was a comparison input, not a replacement checkout. [The runtime delta manifest](validation/runtime-since-72fb194-2026-10-23.json) fingerprints the 37 changed/new runtime files against it, separately from harnesses and documentation. The eight retained optimization regions were already compared against that same commit.

One material later suppression change is native party/raid roots using `keepParent=true`: alpha/input suppression preserves the parent/shown state consumed by native Edit Mode instead of reparenting under a hidden addon frame. That can retain native update work when grouped. It is a source-supported candidate for grouped profiling, not a measured explanation of this Retail capture's FPS gap. Reverting it blindly risks restoring the reported Edit Mode/secret-value errors. Modern native status roots already used alpha-zero suppression in 72fb194, and the baseline already hid `PlayerFrameContent`; neither behavior was newly introduced by the v9 comparison. The cast bar remains unchanged from 72fb194. The Battlefield Map change in this follow-up is bounded tab discovery/frame reuse; its ongoing MapCanvas update path remains unchanged.

The opt-in [capture tool](../Other/FluxPerfCapture.lua) now also ranks functions registered in native `EventRegistry.onUpdateCallbacksByOwner`. It reads that publicly inspectable table only at requested capture endpoints, labels known global owners, retains shared/anonymous owner lists, and invokes no callback. Missing, inaccessible and secret tables/values are excluded. Loading the addon or printing a saved report performs no registry scan, hook or idle work. [The capture fixture](../tests/perf_capture.lua) covers native callback identity, duplicate owners, absent/restricted registries, zero load/print scans and a new rejected attribution mutant. This prepares the next native capture to identify the approximately 12 ms/s shared dispatcher contribution instead of guessing from its frame name.

The user repeated the requested same-scene/tab/mouse protocol and saved [the after capture at 17:11:13](validation/retail-idle-profiled-after-2026-10-23.json). Map/tab/character endpoint states and recorded CVars match. There is no independent scene, mouse or foreground trace. The [comparison and operation-count manifest](validation/retail-idle-operation-counts-2026-10-23.json) records the source fingerprints and exact outputs.

| Metric | Before | After |
|---|---:|---:|
| Flux CPU (legacy, ms/s) | 13.78 | 5.56 |
| Trinket watcher (inclusive, ms/s) | 6.36 | 1.23 |
| Bag tier lookup (inclusive, ms/s) | 6.26 | 1.10 |
| Remember owned tiers (inclusive, ms/s) | 6.30 | 1.12 |
| Tooltip text (all callers, ms/s) | 3.10 | 1.30 |
| Average FPS, profiling enabled | 288.82 | 285.49 |

The Flux CPU reading is approximately 60% lower; the trinket and tier rows are approximately 81% and 82% lower. Calls to bag tier lookup remain 20 in each interval. The watcher runs on every frame in both intervals (5,590 versus 5,447 callbacks). Tooltip traffic, item-data events and other background work differ, so do not attribute the entire addon CPU delta to one code path or sum inclusive rows. The after capture still has substantial native callback-dispatcher and map work; a hidden registered World Map owner does not establish hidden-frame execution because its function can be called by the embedded map.

### Callback attribution and background capture

The [17:29:11 callback capture](validation/retail-idle-callbacks-2026-10-23.json) identifies `EventRegistry:FloatingChatFrameMixin` as the largest individual registry callback: **5.38 ms/s across 2,605 calls**. Native map detail/scroll/map work also follows the 2,605 rendered callbacks. Flux reports **5.55 ms/s**. The user confirmed using another application during this interval. Its **130.52 average FPS** is therefore excluded from comparison against the earlier approximately 285 FPS capture; application time rose to 7.96 ms/tick, and frame cadence/background activity changed. It does not demonstrate a new FluxUI FPS regression.

Source inspection of native `FCF_OnUpdate` shows cursor, chat hover/fade and scrollbar/input handling. Native MapCanvas and scroll-container updates perform distinct responsibilities. No evidence in this capture justifies throttling those callbacks or removing native animation/input. Shared function labels also do not establish execution of the hidden World Map. The new retry/frame reuse changes postdate this capture and require native acceptance separately.

**These samples demonstrate lower CPU readings, not an FPS improvement.** Average FPS is slightly lower in the after sample, with profiling enabled in both. The reported cross-client FPS gap remains unresolved. Restore `scriptProfile=0` and reload before final FPS comparisons. Native gameplay validation is still required on all clients: trinket keyboard/mouse/wheel and modifier input; both/single/no equipped slots; combat input and binding refresh; bag changes and late item data; level/skill changes; vendor/restock and protected junk handling. The first native Edit Mode taint writer is not established by these results.
