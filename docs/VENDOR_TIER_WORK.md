# Repeated vendor tier work — PERF-005

The user confirms a major Classic Era spike on every reopening of the same vendor.
Read-only checks found the previous junk and chat fixes present in the Era install.
This batch reproduces redundant tier usability work; native hitch attribution and
resolution remain unverified. Era's saved Config.wtf contains scriptProfile=1.
That is a saved preference, not a runtime trace or proof of the spike's cause.

## Correction and retained behavior

The vendor's best-tier and status loops checked every listing's level/ownership/
usability before finding whether it matched the requested tier. A food/water vendor
leaves other reference families empty, so those families repeat the full checks on
each open. [Match](../Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua) and
[Vendor](../Inventory/Restock/Core/Tiers/FluxRestockTiers_Vendor.lua) now classify
first and run the existing live usability gate only for matching positive candidates.
The best-item loop also skips contenders that cannot improve its current best.

No usability verdict is cached. Live level/skill gates, unknown merchant data,
thresholds, cheaper equal-value choices, Well Fed exclusion, food/water conventions,
reference seeding and index refresh remain. Skipping the merchant index wholesale
would suppress discovery/reference seeding, so that was not selected. No UI,
settings, profiles, bindings, automation timing, frames, hooks or timers changed.

Classification precedes the level gate now. The measured ready-classification case
does not add classification calls. Cold classification of items later rejected by
level can have a different cost; native cold-tooltip overhead remains pending.
Existing warming, scan budgets and retry paths are retained. No native FPS or
complete spike-resolution claim follows from fewer service calls.

## Source identities and reproduction

- Baseline `af5eee0d7a4c4693bf30124855a40a4c5e50981f`, tree
  `f5ab638b4c42a67f4b3f73e5e3fa4428b56022bc`.
- Runtime correction `17628269f0e3b7fbeb1b8c2d7f9c7196829e67f3`, tree
  `0c681c46987fc5b136274bba59e5e5bb3dd90990`.
- Candidate with the repeated-open regression `e7ec46a4070c132ff8bf6033d6bef5e2c92f90aa`,
  tree `4507ccd1456e42f9acdea0e2be4aaad073ff72ae`.
- [Baseline identity](validation/vendor-tier-baseline-identity-2026-10-29.json)
  verifies all 728 pre-edit Lua hashes against the prior 87-script suite.
  [Recovery](RECOVERY.md) records a verified external source/history/private-settings
  checkpoint at 13:04 Copenhagen, with WoW closed. No sync was performed.

```powershell
lua tests/vendor_tier_work.lua --baseline --measure
lua tests/vendor_tier_work.lua
python tests/run_validation.py --output docs/validation/vendor-tier-full-2026-10-29.json --sync-docs
```

The [regression](../tests/vendor_tier_work.lua) reuses the existing merchant fixture,
runs production buyer events/index/post-index seeding, complete tier modules and
Score.IsUsableForVendor. Classification facts, native APIs/widgets and external
integrations are modeled. Baseline: **340 checks, 12 expected failures**; measure
mode exits zero. Candidate: **340 checks pass**. Existing bag-tier controls pass
16,527 checks, merchant identity/stock 837, and junk availability 265. The
[complete suite](validation/vendor-tier-full-2026-10-29.json) passes **88 scripts
and 729 Lua syntax files**.

## Matched measurements

Five alternating fresh-process pairs cover legacy merchant tuples and modern item
tables, with 20 and 200 listings. Ten items match five tracked tier kinds. Automation
is off and empty reference seeding remains active. Capture seeding after one modeled
second, then separate best/status queries. These are cold references with ready
modeled classification, not native cold-start tooltip measurements.

| Scenario, per API route | Item-info service lookups before → after | Ownership lookups before → after |
|---|---:|---:|
| 20 listings, initial reference seed | 100 → 9 | 100 → 9 |
| 200 listings, initial reference seed | 1,000 → 10 | 1,000 → 10 |
| 20 listings, separate best/status pass | 200 → 19 | 200 → 19 |
| 200 listings, separate best/status pass | 2,000 → 20 | 2,000 → 20 |
| 25 reopens, 20 listings, three unoffered families | 1,500 → 0 | 1,500 → 0 |
| 25 reopens, 200 listings, three unoffered families | 15,000 → 0 | 15,000 → 0 |

Reopens retain the food/water references and the same inventory, close/show/update
events and one modeled second per open. Unoffered families remain empty. Every
count range is zero across pairs. Classification calls remain 100/1,000 for seeds,
200/2,000 for status and 1,500/15,000 for 25 reopens. Each buyer retains one event
frame and makes zero purchases. These counts are service calls, not native API
cache misses, allocations or CPU time.

[Baseline](validation/vendor-tier-baseline-2026-10-29.txt),
[candidate](validation/vendor-tier-candidate-2026-10-29.txt) and
[matched samples](validation/vendor-tier-comparison-2026-10-29.json) retain commands,
source/configuration hashes, full output, count variation and process durations.
Windows 10.0.26200, Lua/luac 5.4.6, Python 3.10.6 and i7-12700F/20 logical processors
are recorded; GPU/RAM and the affected runtime build/settings/addon list are unknown.
Profiling is off in the desktop fixture. Process durations include fixture setup
and all controls; they are not merchant-open latency. Native CPU/memory/resources,
latency/frame times/FPS, pixels, secure behavior and taint remain pending.

## Native checks — pending

Start with repeated opens on Era. Preserve the same vendor, bag contents, profile,
addons, resolution/UI scale and automation settings. Record GetBuildInfo and exact
source identity. Compare revisions sequentially using the same addon folder.
Use at least five matched pairs of first opens and 25 repeated opens, including
food/water, non-consumable, limited-stock and cold/high-level-item vendors. Verify
reference values, target quantities, cheaper equal-value selection, level/skill
changes, missing item data, prices, button geometry/input and combat/taint.

For CPU attribution, keep scriptProfile=1, warm up, run `/fluxperf capture 30`, reopen
the same vendor several times after capture setup, then retain `/fluxperf last`.
For unprofiled hitch comparison use `/console scriptProfile 0`, `/reload`, and the
same repeated-open sequence. Preserve raw frame-time evidence where available and
restore the original profiling preference afterward. Do not combine the two profiler
modes or treat coarse FPS samples as hitch tails. See [protocol](PERFORMANCE_PROTOCOL.md).

Repeat native checks on other available clients; the two API fixtures certify no
native build. If the Era hitch remains, trace the remaining classification work,
Already Known tooltip scans, reagent-name harvesting and layout retries with actual
CPU evidence. Auction, guild-bank and void-storage callbacks remain deferred.
