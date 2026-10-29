# Baseline protocol and currency evidence

The frozen cumulative baseline is commit
`7436820453d2248c84c99fff71507553efc47c19`, tree
`6e3af8d646a09ce2182ffd6d2cc287890584825a`, plus the complete actual-file recovery
archive described in [RECOVERY.md](RECOVERY.md). The original full suite was run
before runtime edits: 81 passing scripts, 722 syntax files, zero failures in
[modernization-baseline-2026-10-29.json](validation/modernization-baseline-2026-10-29.json).

BUG-001 candidate runtime commit: `2a7de26052e1b9662deef1b606b5ec95ebefe3aa`, tree
`86ed71c06dc9bc2117fb60e30d5417976506912a`. This first candidate suite records
82 passing scripts, 723 syntax files, zero failures in
[modernization-candidate-2026-10-29.json](validation/modernization-candidate-2026-10-29.json).
Later BUG-002/BUG-003 commits, baselines and the final 84-script/725-file suite are
recorded in [provider handoff lifecycle](PROVIDER_HANDOFF_LIFECYCLE.md). Historical
candidate hashes remain pinned to their own commits rather than relabeled current.

## Currency provider scenario

`tests/currency_provider_handoff.lua` executes production Store, Currency and
Syndicator readiness/currency builders. Other inventory regions, events, scheduling,
provider data and native APIs are modeled. It covers absent provider, pending Ready,
late handoff, initially ready provider, duplicate starts/Ready, standalone synchronous
money, token and warband refresh, retained saved ledger and external currency updates.
Its five configurations model Era/Anniversary (no tokens/warband), Mists (tokens),
and Retail/Forever (tokens/warband); these are capability fixtures, not native builds.

Each fresh process runs startup and pre-handoff operations as warm-up, then five
repetitions per capability configuration. A repetition restores provider facts and
dispatches 100 rounds of PLAYER_MONEY, CURRENCY_DISPLAY_UPDATE, ACCOUNT_MONEY and
BANKFRAME_OPENED, followed by builtin Refresh. Capture is operation-count bounded,
not a timed 30-second native run. Match five alternating baseline/candidate process
pairs; preserve each output and process duration in the comparison JSON. CPU timers
and scriptProfile are off. Startup correctness is checked separately from burst
counts; no steady-state or startup speedup is inferred.

The baseline fixture `tests/fixtures/currency_provider_before.txt` was copied before
the edit and matches the checkpoint source byte-for-byte (SHA-256
`bc8efcd0265113188f5fff9268dd7656f8c41345adaf6627e9f27f28dc5736c5`). It is not loaded
by the addon. Reproduce a matched pair from the existing addon root:

```powershell
lua tests/currency_provider_handoff.lua --source tests/fixtures/currency_provider_before.txt --measure
lua tests/currency_provider_handoff.lua
```

`--measure` reports assertion failures without failing exit so broken baseline
samples can be retained. Normal candidate execution must exit successfully.
The initial pre-edit reproduction is preserved in
[currency-provider-baseline-2026-10-29.txt](validation/currency-provider-baseline-2026-10-29.txt).
Full-add-on desktop validation uses `python tests/run_validation.py --output <path>`.

Five alternating process pairs completed: 25 repetitions per variant per capability
model, with zero range for each reported operation count. The candidate passed all
150 checks in every invocation; baseline recorded 50 expected regression failures.
Raw samples, commands, hashes and per-model medians/min/max are in
[currency-provider-comparison-2026-10-29.json](validation/currency-provider-comparison-2026-10-29.json).

| Per 400-event burst | Baseline measured | Candidate measured |
|---|---:|---:|
| Builtin GetMoney calls after handoff | 100 | 0 |
| Redundant scheduler requests, no warband | 300 | 0 |
| Redundant scheduler requests, warband | 400 | 0 |
| Unauthorized snapshot generation increments | 100 | 0 |
| Provider money after burst | overwritten to 654 | remains 999 |
| Builtin event subscriptions retained | 4 | 4 |

Four permanent shared-bus handlers still dispatch and check ownership. This batch
does not claim zero dispatch overhead or remove global events needed by other
consumers. Counts measure requests, not completed scheduler passes. Snapshot data
and standalone cadence are correctness gates. The fix does not change layout,
fonts, textures, colors, animation or secure input code. Native parity is pending.

Environment: Windows NT 10.0.26200.0, Intel Core i7-12700F, 20 logical processors;
Lua/luac 5.4.6, Python 3.10.6. CPU name read from registry; RAM/GPU details were not
available through sandbox CIM. No WoW process ran during the baseline. No enabled
native addon list, live settings/scene, native CPU, attributed allocations, latency,
frame-time stream or screenshot baseline was captured. Desktop whole-process times
are advisory and include startup/harness work; they are not addon CPU or FPS.

## Native procedure for each meaningful change

1. Preserve source/settings while WoW is closed. Record exact GetBuildInfo results,
   project/interface, baseline and candidate hashes, CPU/GPU/RAM/driver, resolution,
   UI scale/profile/fonts, graphics/VSync/FPS caps, foreground status, scene/class,
   addon list and exact versions. Installed executable versions alone are insufficient.
2. Compare sequentially in this same addon identity. Use five alternating matched
   baseline/candidate pairs, 30 seconds warm-up and 60 seconds capture as a starting
   protocol. Separate login/reload, settled idle and the affected burst/interaction.
   Restore only the intended code/settings between runs; never install a second addon.
3. For CPU runs: record original scriptProfile, use `/console scriptProfile 1`,
   `/reload`, warm up, `/fluxperf capture 60`, then `/fluxperf last`. Capture
   `/fluxstartup on` + reload + `/fluxstartup` separately for startup readiness;
   turn it off afterward if originally off. Retain raw FluxPerfCaptureDB privately
   and publish only sanitized measurements. These commands exist in current code.
4. Repeat unprofiled captures with `/console scriptProfile 0` and reload for frame
   performance. Restore the original diagnostic state afterward. Do not use
   `/fluxperf probe` as parity evidence: it hides features. Sampled FPS does not
   yield p95/p99 frame times; obtain a suitable stream before reporting tails.
5. Capture lossless matching screenshots before and after, including currency/gold
   tooltip and status regions for this batch. Record geometry, fonts, hit areas,
   dynamic masks/phase and interaction timing; explain every static pixel difference.
6. Currency cases: absent Syndicator; installed/ready at login; real delayed Ready
   with builtin started first; money/token and account-bank changes; repeated Ready
   if reproducible; logout/reload saved-ledger retention. Use `/fluxinv` to record
   provider/source. Do not fake provider readiness on live saved data. If delayed
   readiness cannot be reproduced, keep that native case pending.
7. Report raw samples, median/range, equivalent outcomes, profiler overhead and
   pass/fail/inconclusive. Do not sum inclusive CPU rankings or equate lower Lua
   cost with higher FPS. Run complete-addon and optional-provider scenarios as well
   as the changed subsystem. Secure/combat/taint and Retail secrets need native runs.

All native cases above remain **pending**. The current measurements justify removal
of stale currency work and snapshot corruption only.

## Later Windows lifecycle evidence

BUG-004/PERF-003 has a separate matched baseline/candidate and complete-addon suite
in [WINDOW_MOVER_LIFECYCLE.md](WINDOW_MOVER_LIFECYCLE.md). Five alternating pairs
record disabled discovery/polling and gesture resource counts; enabled scale/frame/
hook controls remain equal. Latest suite passes 85 scripts/726 syntax files. Native
startup/idle/burst CPU, allocations, latency, frame times and parity remain pending;
do not relabel the earlier currency/provider samples as this candidate's baseline.

## Merchant purchase identity evidence

[BUG-005](VENDOR_PURCHASE_IDENTITY.md) records a separate matched production-code
replay and full 86-script/727-file candidate. Invalid purchases drop to zero; the
correctness guard adds one identity lookup per valid purchase. Stable cadence and
resource controls remain equal. These are operation counts, not a native CPU/FPS
speedup. Native startup/idle/purchase-burst profiling and parity remain pending.

## Finite merchant stock evidence

[BUG-006](VENDOR_STOCK_BUDGET.md) records a separate matched baseline/candidate and
full 86-script/727-file validation. Five pairs remove modeled stock-limit rejections
and correct quantities/accounting, retaining unlimited cadence and existing event
frames. No merchant-info reads/timers were added. These operation counts are not
native CPU/FPS evidence; native acceptance and asynchronous acknowledgement remain pending.

## Vendor-open availability evidence

[BUG-007/PERF-004](VENDOR_OPEN_WORK.md) separates a cold open from 25 unchanged
reopens across five alternating pairs and seven API fixtures. Era slot-info reads
fall from 300/5,000 to 200/zero; Retail/Forever from 360/6,000 to 240/zero. Count range
is zero; existing buyer frame/native queries remain. This measured fallback path
excludes native rendering/layout and other integrations. Generation/reliability
queries precede reuse; native overhead is unmeasured. Full suite: 87 scripts/728
syntax files pass. Native resolution of the Era hitch, CPU/allocations/resource
totals/latency/frame times/FPS and parity remain pending; fewer reads do not prove
higher FPS. Retain first-open, steady idle and repeated-open traces separately.

## Chat anchor correctness evidence

[BUG-008](CHAT_QUICKJOIN_ANCHOR.md) has five alternating fresh-process replay pairs.
For each Live/Forever side, three queued callbacks formerly trigger three cycle
rejections; candidate triggers none. Retry deadlines/count (three) and new burst
frames (zero) remain. Candidate reaches the existing combat waiter that baseline
exceptions abort before queuing. The complete suite passes 87 scripts/728 syntax
files; 1,819 combined column checks pass. These error/resource controls establish
correctness, not native latency/CPU/FPS. Native startup/idle/layout bursts, allocation,
frame-time and visual/security acceptance remain pending.

## Repeated tier usability evidence

[PERF-005](VENDOR_TIER_WORK.md) separates initial reference seeding, tier best/status,
and 25 repeated same-vendor opens. Five matched pairs reduce large-vendor info/
ownership service lookups from 1,000 to 10 each for seed, 2,000 to 20 for status,
and 15,000 to zero for reopens with three unoffered families. Classification counts
remain equal in the modeled ready-fact case. Native cold classification before
level rejection can differ; memory/CPU/latency/frame-time/FPS/parity remain pending.
Era saves scriptProfile=1. Separate profiled attribution from an unprofiled hitch
comparison; preserve that preference and do not sum overlapping inclusive timings.
Full 88 scripts/729 syntax files pass. No live hitch resolution is claimed.

## Native Era tier count evidence

[PERF-006](TIER_COUNT_WORK.md) records an actual Era 1.15.9.70576 four-reopen baseline
with a 333 ms maximum UI interval and about 320 ms per restock target build. One
profiled attribution pilot is not five matched whole-window pairs. A separate
background native comparison uses five alternating getter pairs, one warm pass and
existing query-cache invalidation; identical quantities, median CPU per five kinds
132.199 -> 15.237 ms bags and 118.897 -> 22.517 ms cached personal bank. Exact
source identities, hardware, addon list, profiler/settings, raw samples, ranges and
source-derived local probe are retained. No public/native API replacement.

Desktop five-model pairs preserve quantities and bank reads while eliminating
unrelated live checks; full 89 scripts/730 syntax passes. Native bank outputs are
all zero; positive/warband parity is desktop-only. Raw net memory deltas are not
allocation bytes. No runtime resources added by source inspection; native resource
enumeration was not performed. Full vendor after, startup/cold work, unprofiled
frame/FPS traces and visual/security acceptance remain pending. User requested
background PC use; leave the window there until foreground testing is convenient.
Inclusive CPU rows overlap and must not be summed or translated into FPS.

## Whole-addon Retail CPU and retained-resource audit

[Current audit](RETAIL_PERFORMANCE_AUDIT.md) maps 577 loaded files/26 domains, native
Retail 12.1.5.70575 background idle, and two reproduced resource defects. Native
baseline: 30-second warm-up, five20-second windows, eight-second gaps, ten full-GC
endpoint memory/frame censuses outside CPU windows. Median CPU30.772 ms/s; frame
and sampled public-cache sizes stable. Rising requested-diagnostic memory requires
separating retained capture snapshots/harness/profiling from ordinary UI behavior.

BUG-009/PERF-007 five desktop pairs reduce loot watcher allocations203->3 without
geometry/timing changes. BUG-010/PERF-008 pairs reduce full retained snapshots20->0
per model while retaining compact reports. Baseline actual-file checkpoint includes
pending tracker work; commits alone are not the complete measured tree. Current
92 scripts/733 syntax pass. Native after data is scoped separately; truncated
private-module compilation is discarded. Preserve original profile0 and background
PC use. Inclusive CPU overlaps; allocations, foreground FPS/tails, combat/taint,
private-cache/long-session churn and multi-client acceptance remain pending.

## Shared chat column follow-up

BUG-011 [five alternating pairs](CHAT_COLUMN_ALIGNMENT.md) record intentional layout correctness:100 stable layouts retain identical point counts and zero new frames;103/203 shared tab-height reads including3 scale probes are explicit overhead. Native Retail gap/tab geometry passes; no native CPU/FPS improvement claimed. Current actual-file suite92 scripts/733 syntax; pending tracker state identified separately from commit.
