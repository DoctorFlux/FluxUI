# Repeated vendor-open tier counts — PERF-006

The Era hitch is reproduced on the current baseline. Four same-vendor reopenings
produced a 333 ms maximum UI update interval; the restock target builder spent
about 320 ms per call. Bag and cached personal-bank tier counts checked live
usability, including tooltips, before rejecting unrelated items. The fix matches
the tier first and keeps the live gate for every matching item.

## Sources and recovery

Baseline commit `d3bce5baa01d8dff2aa6372de27afe1680da7b31`, tree
`c9a97bf07e7b267925d3b63bc8a827ea8ad99ebc`. Candidate runtime/test commit
`013bf40db1d5b57c238ac3ac377e8ced98446fd1`, tree
`4f0d827bb26bba3ee8b20e21de891596fad0e98b`.
[Baseline identity](validation/tier-count-baseline-identity-2026-10-29.json),
[desktop pairs](validation/tier-count-comparison-2026-10-29.json), and
[native samples](validation/tier-count-native-2026-10-29.json) pin source hashes.

The verified external checkpoint `FluxUI-recovery-20261029T123516Z` covers all
1,234 actual files, history and 403 private WTF files. Both clients were running:
the settings archive preserves on-disk files, not a quiescent in-memory snapshot.
See [recovery](RECOVERY.md). Main remains unchanged. No external code/assets copied.

## Native baseline attribution

Actual `GetBuildInfo()` is Era **1.15.9, build 70576, interface 11509**, build date
22 October 2026. Character: level 60 Mage, Soolie Berryfizz in Ironforge, UI scale
0.75. Loaded addons: `_FluxUI` 0.0.1, !BugGrabber v12.1.1, BugSack v12.1.9,
FPS_MS_Monitor 12.15; external Syndicator/Baganator were absent from the load list.
Hardware: i7-12700F (12 cores/20 logical processors), 32 GiB RAM, RTX 3060 driver
32.0.16.1692, Windows NT 10.0.26200. Parsec Virtual Display Adapter 0.45.0.0 is
also installed; the active renderer was not independently identified.

Profiling was already enabled (`scriptProfile=1`). Temporarily disabled auto-sell,
auto-repair and auto-restock to avoid transactions; all three originally true
values were restored. The clean foreground capture used a 1436 x 754 client area,
`maxFPS=120`, `maxFPSBk=30`, `maxFPSLoading=10`, `vsync=0`, `targetFPS=60`,
`useTargetFPS=0`, `gxMaxFrameLatency=3`. These CVar values do not prove an active
frame cap. Other graphics/font/profile details were not exported: equivalent
future full-window pairs must record them. No settings reset was performed.

Used the existing 20-second capture with a temporary bounded OnUpdate sampler.
Discarded its first two seconds and stopped sampling at 18 seconds, before endpoint
scans. Its 5,784 UI intervals have median 2 ms, p95 3 ms, p99 10 ms and maximum
333 ms. These quantized UI intervals are not a GPU/presentation trace. Four normal
open/close cycles generated 12 merchant events; money was unchanged. Action focus
guards passed and the final 32 foreground observations had no other-window sample.
Earlier interrupted pilots are excluded from acceptance. This is one attribution
capture, not five matched whole-vendor pairs. The diagnostic sampler and profiling
add overhead; an unprofiled full-window result is pending.

| Inclusive native function | Calls | CPU ms in capture |
|---|---:|---:|
| UpdateMerchantUI | 12 | 1,297.469 |
| GetRestockTargetItems | 4 | 1,281.123 |
| GetRestockVendorItems | 4 | 1,281.645 |
| Score.IsUsable | 4,988 | 890.169 |
| GetTooltipText | 5,250 | 757.085 |
| GetTierCount | 20 | 707.280 |
| GetBankCountForKind | 20 | 457.873 |

The capture reports 114.413 addon CPU ms/second. These inclusive rows overlap;
do not sum them or infer an FPS improvement. Attribution justifies removing the
unrelated live gates in the two count paths without changing merchant UI cadence.

## Change and parity

Only runtime file changed: `Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua`.
GetTierCount rejects nonmatching classifications before live usability and the
existing inferior-item shield. GetBankCountForKind establishes strict/loose tier
membership before live usability. Matching candidates still receive fresh level/
skill checks. Quantities, positive/zero query-cache behavior, vendor-first
deduplication, live bag fallback, conjured/Well Fed rules, protections and merged
personal/warband counts remain covered. Bank-store reads are unchanged.

No new runtime cache, event, timer, hook, frame, setting or framework is introduced.
This is cached personal/warband count work; auction, guild-bank and void-storage
callbacks remain outside scope. Classification now precedes level rejection, so
cold-item work can shift and needs separate native validation.

## Repeated native function comparison

After the user requested background PC use, comparison ran inside Era without
activating its window. Original loaded baseline function references were retained
before editing. Candidate local functions were compiled from the exact current
helper prefix and two count bodies; comments were removed and public declarations
made local. No public or native API was replaced. The
[recorded probe](validation/tier-count-native-probe-2026-10-29.txt) and source/chunk
hashes make this narrower scope reviewable. The user's existing sync delivered the
candidate source to Era; source equality was verified and a normal reload loaded it.

One warm pass per function preceded five alternating baseline/candidate pairs,
with reverse order in pairs two/four. Each domain pass invalidated the existing
query cache and queried food, water, bandage, healPotion and manaPotion. Actual
inventory, classification and native usability were shared. No forced garbage
collection or transactions. CPU uses GetFunctionCPUUsage with subroutines; elapsed
uses debugprofilestop. Each getter was called five times per pass. Ordinary PC
workload remained uncontrolled; the alternating order reduces rather than eliminates
that source of variation. Capture duration here is synchronous call time, retained
per sample, rather than a fixed frame window.

| Per five kinds | Baseline median (range) | Candidate median (range) |
|---|---:|---:|
| Bag getter CPU ms | 132.199 (129.199–156.132) | 15.237 (13.819–18.922) |
| Cached-bank getter CPU ms | 118.897 (115.706–125.330) | 22.517 (21.256–28.357) |
| Bag getter elapsed ms | 132.207 (129.205–156.141) | 15.244 (13.824–18.931) |
| Cached-bank getter elapsed ms | 118.905 (115.714–125.338) | 22.527 (21.263–28.371) |
| Bag tooltip calls | 455 (455–455) | 5 (5–5) |
| Cached-bank tooltip calls | 450 (450–450) | 5 (5–5) |
| Bag usability calls | 790 (790–790) | 6 (6–6) |
| Cached-bank usability calls | 448 (448–448) | 3 (3–3) |

**Pass for this function-level CPU/result comparison.** Every pair returned the same
bag quantities `[0,0,5,5,4]` and cached-bank quantities `[0,0,0,0,0]`. Positive bank
and warband quantities are covered only by desktop fixtures. Raw samples include
net memory deltas; these contain harness allocations and GC effects and do not
measure allocation bytes or establish a memory improvement. No native resource
enumeration was performed. Background results do not certify foreground vendor
latency, pixels, security or FPS. The window was later observed at 1207 x 634,
so the saved screenshots are not a matched before/after geometry pair.

## Desktop regression and measurements

`tests/tier_count_work.lua` reuses the existing tier boot fixture and full production
Match source. Five models cover Era, Anniversary, progression Classic, Live and
Forever; they are capability fixtures, not native client certification. Each has
120 bag IDs and 150 personal-bank IDs; modern models add overlapping warband IDs.
Checks cover quantities after 25 generation changes, live rejection, thresholds,
inferior protection, delayed facts, vendor-first deduplication, snapshot/live
fallback and absent stores. The frozen original source is a nonloaded fixture.

Five alternating fresh-process pairs reproduce these deterministic counts:

| Live usability calls, bags and cached banks | Baseline | Candidate |
|---|---:|---:|
| Initial legacy reconciliation | 1,350 | 17 |
| 25 legacy reconciliations | 33,750 | 425 |
| Initial modern reconciliation | 1,500 | 18 |
| 25 modern reconciliations | 37,500 | 450 |

Count ranges are zero. Bank reads across first + 25 repeats remain 19,500 legacy /
23,400 modern. Full-process desktop elapsed samples include fixture startup; they
are not vendor latency. Baseline has ten expected performance-budget failures among
1,710 checks; candidate passes all 1,710. Existing tier controls pass 16,527 checks,
vendor tier checks 340, merchant stock/identity 837 and junk availability 265.
Full suite: **89 desktop scripts, 730 Lua syntax files, zero failures** in the
[full report](validation/tier-count-full-2026-10-29.json).

```powershell
lua tests/tier_count_work.lua --source tests/fixtures/tier_count_match_before.txt --measure
lua tests/tier_count_work.lua
lua tests/idle_tiers.lua
lua tests/vendor_tier_work.lua
python tests/run_validation.py --output docs/validation/tier-count-full-2026-10-29.json --sync-docs
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Measure mode intentionally exits zero for the known failing baseline. All current
Lua hashes must match the report before reusing its result.

## Pending native acceptance

WoW is left in the background at the user's request. Original automation booleans
and profiler preference are restored; temporary sampler/namespaces were cleared by
reload and temporary diagnostic SavedVariable exports removed. No further foreground
access is needed for repository work.

When foreground testing is convenient, use the same NPC/profile/resolution/scale/
inventory/addon list, warm 30 seconds, disable automation temporarily, and capture
five matched baseline/candidate 20-second runs with four normal reopenings per run,
alternating order. Preserve each raw capture before replacement. Repeat with
scriptProfile=0 after reload, then restore original profiling and automation.
Separate first cold open, idle-open and repeated-open bursts; compare affected
functions and whole addon. Do not compare background frame cadence to foreground.

Capture equivalent vendor screenshots/geometry and check buttons, targets, bank
badges, tooltips, reference discovery, late/level-gated items and interaction timing.
Check normal allowed transactions separately with controlled quantities, standalone
and external Syndicator/Baganator readiness, positive cached-bank counts, combat/
taint and errors. Repeat available client rows, including Retail secret-value gates;
original Wrath remains unverified. Foreground after hitch resolution, unprofiled
FPS, startup/cold cost, native allocation/resource totals and visual/security parity
are **pending**, not inferred from the getter comparison.
