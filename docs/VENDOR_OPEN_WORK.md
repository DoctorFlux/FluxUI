# Vendor-open junk availability â€” BUG-007 / PERF-004

Opening a merchant without interacting produces a hitch reported on Classic Era.
The user's automation settings and whether this is first-open or repeated-open lag
are unknown. Native reproduction is pending. The source replay establishes one
contributor: the junk button's fallback repeatedly walks every carried bag even
when unchanged inventory contains no sellable junk.

## Correction and ownership

[FluxJunk.lua](../Inventory/Restock/Junk/FluxJunk.lua) now retains the existing
Blizzard-gray fallback's boolean result and reliable bag generation. Both positive
and negative results can be reused. Existing rule, per-item metadata, list and junk
slot invalidation clear the result; a new bag generation replaces it. Unavailable
or unreliable generation keeps the live fallback. A fresh native positive count
still takes precedence and clears the fallback cache before returning.

This cache belongs to the existing junk classifier and uses two scalar values.
There are no new frames, timers, subscriptions, hooks or settings. Existing merchant
callbacks, button updates, automation and storm-settle timing remain in place.
Generation and reliability queries now precede cache reuse; their native cost has
not been measured. This is not a zero-work vendor-open path.

Reusing a zero classified-junk count alone would lose the separate gray fallback
when item metadata is cold. The regression preserves that case, Useful marks and
their removal, bag identity changes, item-data arrival and rule invalidation. The
native-positive/zero transition and unready/unreliable inventory also retain live
behavior. Cold classification and one fallback walk remain necessary in this batch.

## Identities and reproducible scope

- Baseline `9e17e28310e14f571208c8ecddfa0e36ae616a13`, tree
  `69c039054c7d522a741ca6bb3a72682f1ca04b43`.
- Candidate runtime `e02139ab1c6b8099b02fb4506ff150a50d6555ef`, tree
  `0a23a38a04809c0a087089586cb5842496fb5c64`.
- [Baseline identity](validation/vendor-open-baseline-identity-2026-10-29.json)
  verifies every prior Lua source against the 86-script/727-file full report.
  [Recovery](RECOVERY.md) records the verified 11:14 UTC source/history/private
  settings checkpoint made outside AddOns with WoW closed.
- [Focused regression](../tests/vendor_open_work.lua) reuses the existing junk-smoke
  fixture. It runs production buyer merchant events/timers, the inventory facade and
  junk rules, plus unmodified availability, count, button-state and settle functions
  extracted from the production merchant UI. Rendering, layout, restock data and
  other integrations are modeled or excluded; it is not a complete merchant trace.
  The five legacy client labels share one tuple-container fixture route. Retail and
  Forever share the namespaced-container/native-button route. Seven labels do not
  establish seven distinct native API contracts or complete per-client coverage.

```powershell
lua tests/vendor_open_work.lua --source tests/fixtures/vendor_open_junk_before.txt --measure
lua tests/vendor_open_work.lua
python tests/run_validation.py --output docs/validation/vendor-open-full-2026-10-29.json --sync-docs
```

Baseline: **265 checks, seven expected failures**, one repeated-scan failure per
model; measure mode exits zero deliberately. Candidate: **265 checks pass**.
The [complete desktop suite](validation/vendor-open-full-2026-10-29.json) passes
**87 scripts and 728 Lua syntax files**. Existing merchant stock/identity and junk
seller regressions remain controls; this does not certify native sales or input.

## Before and after

All automation is disabled, targets empty, and each carried bag has 20 non-junk
slots. Capture the first open through 0.7 modeled seconds and close through 0.1;
then capture 25 unchanged open/close cycles separately. Five alternating baseline/
candidate pairs use fresh processes. Profiling is off; counters record calls to
the live inventory facade's slot-info accessor, not CPU time or native frame time.

| API fixture | Slots | First open, before â†’ after | 25 reopens, before â†’ after |
|---|---:|---:|---:|
| Era | 100 | 300 â†’ 200 | 5,000 â†’ 0 |
| Anniversary | 100 | 300 â†’ 200 | 5,000 â†’ 0 |
| Modern Wrath Classic legacy API | 100 | 300 â†’ 200 | 5,000 â†’ 0 |
| Cata legacy API | 100 | 300 â†’ 200 | 5,000 â†’ 0 |
| Mists | 100 | 300 â†’ 200 | 5,000 â†’ 0 |
| Retail native button | 120 | 360 â†’ 240 | 6,000 â†’ 0 |
| Forever native button | 120 | 360 â†’ 240 | 6,000 â†’ 0 |

Every operation-count range is zero across the five pairs. The buyer's event frame
remains one; this excludes base/native/rendering frames. Native junk-count queries
remain 182 per modern fixture capture and zero on the legacy fixtures. No additional
native-count polling is introduced. Raw [baseline](validation/vendor-open-baseline-2026-10-29.txt),
[candidate](validation/vendor-open-candidate-2026-10-29.txt) and
[matched samples](validation/vendor-open-comparison-2026-10-29.json) retain source/
configuration hashes, commands, durations and all counts.

Environment: Windows 10.0.26200, Lua/luac 5.4.6, Python 3.10.6, i7-12700F/20 logical
processors from prior registry evidence. GPU/RAM, exact native build/settings and
loaded addons for the reported hitch are unavailable. Process durations include
fixture startup and correctness checks; they are not merchant-open latency.
CPU, allocations, complete resource totals, latency, frame times, FPS, screenshots,
combat/taint and real secret-value checks are **pending**. Desktop count reduction
passes; resolution of the reported native hitch remains **unverified**. Original
Wrath 3.3.5 is not certified by the modern Wrath fixture.

## Native acceptance and next investigation â€” pending

1. Start with Era, where the symptom was reported. Record `/dump GetBuildInfo()`,
   actual loaded addons/versions, hardware, profile, bag contents, merchant, UI scale,
   resolution, automation and profiling settings. Record first-open versus repeated
   behavior before changing any settings. Keep source/settings checkpoints outside
   AddOns; compare the recorded revisions sequentially using the same addon identity.
2. With matched settings and bags, open the same vendor and do nothing. Measure
   first-open after reload separately from at least 25 close/reopen cycles. Repeat
   five matched pairs, alternating baseline/candidate. Test no-junk, gray junk,
   Useful marks, protected restock targets and delayed item data. Compare matched
   button/merchant screenshots, enabled state, click response and close/reopen timing.
3. Repeat controlled automation-off and original-automation scenarios, plus existing
   Shift bypass where applicable. Check standalone and external Syndicator/Baganator
   readiness through normal addon selection. Record any required sale/repair/restock
   separately; it must not contaminate the idle-open measurement.
4. Follow [profiling procedure](CLIENT_VALIDATION.md): warm up 30 seconds, use
   `/fluxperf capture 30` and `/fluxperf last`, and retain raw captures before the next
   overwrites them. Use `/fluxstartup` separately for startup. Compare profiled and
   unprofiled runs and restore profiling preferences; coarse FPS samples cannot
   establish hitch tails. Record an available native frame-time trace or leave it
   pending. Never equate fewer slot reads with an FPS improvement.
5. Repeat on Anniversary, Mists, Retail and Forever, recording actual runtime builds.
   Retained Wrath/Cata targets stay unavailable until a matching native client can
   be tested. Check errors, protected input/combat/taint and Retail secret behavior
   without replacing client APIs. No desktop fixture advances a native client row.

If the hitch persists, trace cold classification, merchant-index rebuilds,
Already Known and layout/paint retries independently. These are remaining source
candidates, not reproduced or measured defects. Auction, guild-bank and void-storage
callback audits remain deferred.
