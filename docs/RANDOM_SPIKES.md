# Random spike investigation

The user reports intermittent lag in Forever without a known trigger. The first
unprofiled watch and a later optional 120-second function-level profile have not
identified a specific cause. Other supported clients still need their own checks. Automatic Current selection for Blizzard meters
remains blocked by the user's decision to preserve every native feature.

One separate duplicate-work defect is reproduced and fixed. Repeated Extra
Button layout requests shared one scheduler token but each appended another
full refresh callback. A burst therefore refreshed and packed the same layout
repeatedly before the next frame. The candidate queues one callback while still
merging every request reason. Requests made during a refresh run next frame;
direct Flush calls, child-owned combat deferral and error reporting retain their
existing behavior.

| Same-frame stress, 1,000 requests | Baseline | Candidate |
|---|---:|---:|
| Full layout refreshes | 1,000 | 1 |
| Child refresh calls | 4,000 | 4 |
| Pack calls | 3,000 | 3 |
| Scheduled timers | 1 | 1 |

The loaded-module fixture passes 89 checks and rejects four mutations. Five
alternating baseline/candidate pairs, each with 20 warm-up bursts and 100
captured bursts, measured desktop Lua host-clock ranges of 85–135 ms and 18–30 ms;
medians were 108 ms and 23 ms. Child refresh/pack work is counted through stubs.
These measurements demonstrate duplicate dispatch removal, not native FPS,
secure layout, pixel parity or the cause of the user's random spikes.

## Capture an unpredictable spike

The optional watch extends the existing `/fluxperf` diagnostics. It does not
change profiler preferences, force garbage collection, replace native APIs or
inspect event payloads and private actor data. The first native watch completed
on Forever 70790 with profiling off; its seven gaps are recorded below. Watch
version 2 has desktop coverage but has not yet been armed in a verified native
run. The current startup error described below must be resolved before a fresh
watch can be treated as usable evidence.

1. Outside combat, run `/reload`, then `/fluxperf watch 600 200`.
2. Play normally. The watch runs for up to ten minutes and records frame gaps
   of at least 200 ms, plus observed Flux callbacks taking at least 10 ms.
3. After a noticeable spike, run `/fluxperf watch off`, then `/fluxperf spikes`.
   Keep the printed report and the approximate activity/time of the spike.
4. Run `/reload` or log out normally to write the report to the existing
   `FluxPerfCaptureDB.spikeWatch` SavedVariables field. Unsaved evidence can be
   lost in a client crash. Preserve the original diagnostic file when collecting
   it; keep private settings outside the repository.

`/fluxperf spikes` also prints an active watch or the last saved watch.
`/fluxperf cancel` stops an active watch or endpoint capture. Expiry and logout
finalize the watch automatically. Duration is clamped to 30–3,600 seconds and
the gap threshold to 50–5,000 ms. A watch and `/fluxperf capture` cannot run
together. Existing saved endpoint captures remain available through
`/fluxperf last`.

The watch retains at most 20 gaps, 64 slow callbacks and 512 function labels.
Initial label discovery has a 4,096-entry visit budget; scheduler-token summaries
visit at most 16 keys and retain four string names. Optional profiler, global
Lua-heap and BugTabs count context is sampled at gaps at most once per second.
Absent or restricted metrics are omitted. Stopping detaches the owned timing
observers, removes the watch's active scripts and releases function-label caches.

Version 2 also records the number of completed observed callbacks between watch
frames, the highest-duration callback even below 10 ms, and the four busiest
service/event keys. It retains at most 64 distinct keys per frame and records
key overflow rather than growing the table. Many small callbacks can therefore
be distinguished from one long callback; these counts do not measure CPU or
establish a culprit. A once-per-second global heap read supplies a recent value
and its age at a gap, without storing a heap time series. Short heap deltas may
be useful leads but cannot prove garbage collection or a memory leak. No new
timer or permanent driver is added; the existing optional watch frame handles
these samples.

## Interpret and compare the evidence

Callback coverage is limited to the observed Flux event dispatchers, shared
ticker and scheduler. Private frame scripts, arbitrary timers, native work and
other addons are not fully covered. A failing unit callback does not produce a
completed timing span. Existing trace ownership is preserved; a busy observer
rejects startup, while missing services permit a clearly reported frame-gap-only
watch. A reported callback label or scheduler token is a lead to reproduce, not
proof that it caused the surrounding frame gap.

Frame gaps can include rendering, loading, background throttling and work outside
Flux. Nearest `C_AddOnProfiler.LastTime` values are not exact attribution. Inclusive
callback spans can overlap and must not be summed. Heap KB is global Lua memory,
not addon allocation bytes or a leak test. BugTabs count deltas cover sampled
boundaries; inspect BugTabs separately for actual error stacks. Recorded diagnostic
section timings exclude the observer seam and fast-callback overhead.

For a suspected culprit, compare repeated matched scenarios on the exact client
build, hardware, addon list, profile, resolution, UI scale and foreground/background
state. Retain baseline/candidate source identities, warm-up, duration, repetitions,
raw samples, variation and profiler configuration. Prefer alternating runs and
check the affected module and the complete addon. Keep profiling optional and
measure its overhead separately. Do not infer FPS or leak removal from desktop
counts or an error-free capture.

The frozen version-2/stance stage passed 186 desktop scripts and 848 Lua syntax
checks with unchanged source membership/hashes during that run; its corpus is
`39ac9f231f19cdc8aa6a9c45cc2c8356c51bbefe1313e5ef7c88370fe5c9b54e`.
This is the scope of [the v2 manifest](validation/random-spike-diagnostics-v2-2026-11-06.json),
which fingerprints the capture source as
`c9deea4aaee79e0bfe60e2344200fa238e6cc021f37169d26678d3fd1bf320e0`
and the stance source as
`84c29a6c0e48c3ca39ccf8094f04ed0bce6f178b83f2e5d73394d634b6213578`.
The earlier 185-script/847-file run remains separate evidence for its own stage.
Later concurrent glow work has its own validation; neither run accepts the
current startup failure or proves a fresh native v2 watch.

Specific function attribution, causal reproduction, matched native performance,
secure behavior and all-client acceptance remain pending. Read-only leads in
MouseoverCast classification and the legacy timer fallback remain separate and
unmodified. The disconnected second Forever session was left untouched.

Evidence:

- [Layout baseline/candidate samples](validation/ebs-layout-coalescing-comparison-2026-11-06.json)
- [Owned timing observer comparison](validation/spike-observer-comparison-2026-11-06.json)
- [Bounded watch comparison](validation/spike-watch-comparison-2026-11-06.json)
- [Earlier complete working-tree validation](validation/random-spike-diagnostics-2026-11-06.json)
- [Version-2/stance source validation](validation/random-spike-diagnostics-v2-2026-11-06.json)
- [Version-2 diagnostic cost comparison](validation/spike-watch-v2-comparison-2026-11-06.json)
- [Stance aura text-cache comparison](validation/stance-aura-text-cache-comparison-2026-11-06.json)
- [Short native function profile](validation/forever-random-spikes-profile-120s-2026-11-06.json)
- [Short profile analysis](validation/forever-random-spikes-profile-analysis-2026-11-06.json)
- [Profiler restoration proof](validation/forever-random-spikes-profile-restoration-2026-11-06.json)
- [Performance protocol](PERFORMANCE_PROTOCOL.md)
- [Client validation](CLIENT_VALIDATION.md)

## First Forever watch

The user ran and saved a 600.005-second watch on Forever 1.60.1.70790 with
scriptProfile=0. All three observer services were active: 86,522 callbacks
completed, none individually at least 10 ms. Seven frame gaps were retained:
2,667 / 235 / 208 / 253 / 301 / 244 / 1,174 ms. Two nearest profiler ticks billed
214.1369 and 181.3057 ms to Flux. The longest gaps had little addon time in
their nearest samples, so these observations do not establish one shared cause.

Mail and WorldMap were closed, the auction frame absent, and the Flux tab was
Map. Error counts were zero at all sampled boundaries. Private callbacks/timers
and bursts of small central calls remain unobserved attribution possibilities;
zero slow central spans does not clear Flux. Global Lua heap changes are not
leak evidence. Recorded diagnostic sections peaked at 0.2765 ms, excluding
observer/fast-path costs. The user approved a short optional function-level
CPU capture to narrow the two Flux-heavy samples. It completed separately and
profiling was restored to zero, as recorded below.

[Native watch](validation/forever-random-spikes-watch-2026-11-06.json),
[sanitized analysis](validation/forever-random-spikes-analysis-2026-11-06.json).

## Short native function profile

The separate 120.003-second capture completed on Forever 1.60.1.70790 with
`scriptProfile=1`. Its finish timestamp is 16:25:27 Europe/Copenhagen, placing
the interval at approximately 15:23:27–15:25:27 UTC on 6 November. It is not the
earlier ten-minute watch and did not record exact frame gaps for attribution.
Flux's legacy addon CPU delta was 33.621 ms/s. Sampled FPS averaged 139.01 with
a minimum of 20.56; profiling overhead, startup settling and unmatched scene/
focus conditions prevent using those values as unprofiled acceptance.

Selected inclusive observations were:

| Function or owner source | ms/s | Calls |
|---|---:|---:|
| `Flux.Scheduler.Flush` | 15.798 | 912 |
| Mouseover context predicate | 9.375 | 122,818 |
| `Flux.Bars.Paint.Flush` | 9.025 | 682 |
| Private `Bars/ProgramFace.lua` driver | 8.546 | 16,604 |
| `Flux.EBS.Paint.FlushEval` | 6.101 | 790 |
| Private `Bars/Stance/Extras.lua` driver | 5.701 | 16,604 |

These rows overlap and must not be added. The profile motivates bounded checks
of frequent predicates, private frame drivers and refresh work; it does not
identify the function behind either earlier 214/181 ms Flux sample. Ten chat
edit-box owners report the same 1,926.4294 ms/three-call counter. The shared slash
handler can include diagnostic-command and endpoint-scan work; this is not ten
independent chat spikes. Identical aura-frame counters also share script work.

All-frame count grew 51,734 to 55,506, visible regions by 662, and visible
OnUpdate owners from 45 to 51. One startup-adjacent interval cannot distinguish
lazy loading or pools from a leak. The separately saved BugTabs history had zero
records at 15:27:40 UTC; that snapshot is not a fresh-memory or later-error pass.
[Raw profile](validation/forever-random-spikes-profile-120s-2026-11-06.json),
[analysis and limits](validation/forever-random-spikes-profile-analysis-2026-11-06.json),
[persisted error snapshot](validation/forever-random-spikes-profile-bugtabs-2026-11-06.json).

The user confirmed restoration to `scriptProfile=0`. A read-only background
probe at 15:57:36 UTC visibly printed `FXWATCH_PROBE false 0 false`: no active
watch, profiling zero, and out of combat. The captured output was inspected;
posted-message completion alone is not proof that a command executed. This
confirms those values at that instant, without proving that v2 was loaded or
armed. [Isolated restoration proof](validation/forever-random-spikes-profile-restoration-2026-11-06.json).

## Stance aura text updates

The profile's stance-driver rank justified a narrow repeated-write check. The
countdown helper rewrote its exclusively owned text even when the public display
string had not changed. It now caches only the last successful owned-text write;
changed text, clearing, failed-write retry and font retry remain covered. Clock,
remaining-time, ownership and expiry checks still run each tick. Native digit
visibility/font/color/alpha reconciliation is unchanged.

For 100,000 unchanged-display ticks, the fixture counts 100,000 owned SetText
calls before and one after. Clock reads, holder Show and native-digit operations
remain at 100,000 in both variants. Five alternating pairs with 1,000 warm-up
ticks measured host Lua clock medians of 141 ms before and 132 ms after, with
ranges 136–144 and 129–135 ms. The 2,075-check focused fixture passes and rejects
three mutations. One cached string field per existing owned FontString is added;
no frame, event, timer or per-frame table is added.

This proves duplicate owned-text writes were removed in the specified loaded
helper scenario. Stub counts and uncalibrated host clock intervals do not prove
native CPU, pixels, exact timing, FPS, leak removal or random-freeze improvement.
[Exact source identities and raw samples](validation/stance-aura-text-cache-comparison-2026-11-06.json).

## Version-2 cost and pending native checks

The added fan-out and coarse heap context have optional diagnostic cost. Five
alternating pairs per case compare the frozen v1 and v2 capture sources. The
following values are raw host Lua drive-clock milliseconds, not native CPU or
FPS. Enabled cases drive 20,000 synthetic frames; the fast case supplies 400,000
small spans. Disabled cases drive 100,000 frames.

| Scenario | v1 median | v2 median | Paired v2 minus v1 median |
|---|---:|---:|---:|
| Disabled | 9 | 9 | 0 |
| Quiet watch | 23 | 34 | 11 |
| Slow spans | 117 | 141 | 25 |
| Many small spans | 157 | 261 | 109 |
| Repeated gaps | 74 | 105 | 31 |

The disabled path retains zero frame, timer, observer and metric work. Enabled
cases reuse one watch frame, add no timers or frame enumeration, bound records/
labels/key maps and release observers and caches on stop. The isolated-process
report retains raw drive/start/stop clocks, whole-process wall and CPU values,
heap deltas and variation. Those measurements are not interchangeable, and
Windows host clock semantics and scheduling do not establish native overhead.
Positive enabled deltas are the cost of more diagnostic evidence, not a lag fix.
The v2 fixture passes 119 checks. A new native run was visibly confirmed
armed at 16:29:31 UTC, diagnosticVersion=2 and scriptProfile=0; completion,
saving and analysis are pending.
[Cost/resource comparison](validation/spike-watch-v2-comparison-2026-11-06.json).

## Grid startup verification

The user reported repeating `Paint.lua:3403` nil-call failures, also aborting
CombatGrid and NonCombatGrid initialization. Saved history contains three
records and 38 repetitions at 17:13:28–33 local, before the current Paint file
was written at 17:15:17. Locals retain only the outer error wrapper; the exact
nil callee and loaded source cannot be recovered from that history. No extra
runtime patch was justified by the current-source replay.

The new integration fixture loads the actual Paint and Glow modules, plus both
real grid startup owners, across seven capability profiles. It passes 237
checks and rejects three nil-call mutations. Inventory selection, geometry and
native secure widgets remain explicit fixtures.

At 16:27 UTC the actual Forever client visibly reported ExtraButtons,
CombatGrid and NonCombatGrid all enabled, current-session BugTabs errors zero,
scriptProfile=0 and out of combat. Historical errors were preserved. A preceding
read-only probe used unavailable debug.getinfo and failed separately; corrected
probes avoid it. Latest startup succeeds in this observed session, without
establishing the original nil callee, all-client native safety or long-run art.

The v2 watch was then visibly confirmed armed for 600 seconds at a 200 ms
threshold, with profiling still zero. Only the initial setup screenshot was
taken; account for that setup frame in analysis. No reload is requested while
it runs. The random-spike cause remains unknown.

[Saved error evidence](validation/ebs-glow-startup-saved-evidence-2026-11-06.json),
[startup integration comparison](validation/ebs-glow-startup-comparison-2026-11-06.json),
[native startup observations](validation/ebs-glow-startup-native-2026-11-06.json),
[v2 arming proof](validation/forever-random-spikes-v2-armed-2026-11-06.json).

## Synchronous aura refresh fan-out

A second loaded-production replay found that SyncAuraCountdown invoked the
whole active-set tick for every individual button refresh. Refreshing N active
buttons therefore repainted N squared timers synchronously, in addition to the
normal frame driver. Known timer writers already sync the changed button.

Sync now paints only its own button immediately using the same per-button
helper as the frame driver. The normal driver still checks all timers every
frame, including expiry, hidden buttons, font retries and ownership loss. An
unrelated button changed without its own Sync is reconciled by that existing
next-frame driver; the change no longer relies on incidental cross-button
painting. Last-entry cleanup still disarms the driver. The earlier successful
text-write cache is retained. No timer, native API wrapper or cache is added.

| One refresh batch | Before | Candidate |
|---|---:|---:|
| Holder writes, 16 active timers | 256 | 16 |
| Native digit-hide calls, 16 timers | 272 | 32 |
| Holder writes, 64 active timers | 4,096 | 64 |
| Driver frames | 1 | 1 |

The focused fixture passes 26 checks, rejects restoring the global sweep and
fails the saved baseline at its own-only assertion. Existing text-cache,
consumable-timer and stance-scale regressions pass. Five alternating pairs with
16 timers, 10 warm-up batches and 2,000 captured batches measured host clock
ranges of 767–827 ms before and 88–113 ms after. These are uncalibrated Windows
host intervals and fixture method counts, not native CPU/FPS or freeze removal.

External checkpoint: Aura-countdown-dispatch-20261106T163409Z; 1,653 actual
files, 184 settings, ZIPs and all-ref bundle verified. Baseline Extras SHA-256
84c29a6c0e48c3ca39ccf8094f04ed0bce6f178b83f2e5d73394d634b6213578;
candidate26bdef971675ece8388be025c324c3a337ca108bc61ea97da142df96d725e81f.
The v2 native run began before this candidate was written and does not validate
it. Native visual/secure/cadence and matched frame-time checks remain pending.
[Raw paired samples and regression](validation/stance-aura-sync-comparison-2026-11-06.json).

## Pause and interrupted v2 result

The user paused work on 6 November. No further native input, runtime patch or
publication is authorized until resumption. The final frozen desktop run
passes191 scripts and853 Lua syntax files with no source drift;
[report](validation/random-spike-aura-sync-2026-11-06.json).

V2 saved early at16:33:29UTC on a reload/logout boundary after239.516seconds.
One3185ms gap had nearest application3185ms, all-addons2.4681ms and Flux2.2509ms;
20 central callbacks, longest0.4898ms. Errors were zero then. A separate
10.2787ms scheduler eval listener occurred later. Twelve blocked map-action
errors followed at17:33:14local. None establishes the gap's cause. This native
capture predates the aura sync candidate. Exact freeze cause, leaks and native
candidate acceptance remain pending.

Read-only follow-up found an active global pin-mixin method replacement in
FluxBattlefieldMapProviders.lua's AcquirePin guard. This is an unsafe taint
candidate; removing it requires preserving every owned provider and its
combat-deferred lifecycle. No map runtime edit has been made. Exact next
steps and capture locations are retained in NEXT_SESSION.md and private notes.
