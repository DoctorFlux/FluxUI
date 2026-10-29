# Nameplate countdown: repeated lookup and temporary allocation

PERF-009, 29 October 2026. The original plan's rendering/frame stages require
measured redundant work to be removed without changing appearance or cadence.
The preceding [Retail audit](RETAIL_PERFORMANCE_AUDIT.md) attributed about
12.5–13.1 ms/s to the inclusive nameplate driver in its particular profiled scene.
That historical number is a prioritization clue, not the cost of this countdown
function or the expected saving from this change.

## Source, checkpoint and scope

Baseline HEAD `38ea2673d2df2b4befe10f91aee85a56ae5e19e1`, tree
`ba965afc85d31707b8db6ef5a0b9328e30dbeac1`, plus the preserved pending objective-
tracker source/test/records. External `Nameplate-audit-recovery-20261029T162035Z`
contains 1,271 actual files, history and 403 on-disk WTF files. All archive entries
and history verify. Source archive SHA-256:
`b6e106842ba7af4c364252e05128c310ffb2d444630ce6470fd447a13167e5a6`.
Settings are an on-disk snapshot, not unsaved in-memory state or a quiescent backup.

The frozen [baseline source](../tests/fixtures/nameplate_countdown_before.txt) was
captured before the runtime edit. The [comparison](validation/nameplate-countdown-comparison-2026-10-29.json)
records normalized source/harness hashes, actual-file identity, all paired samples,
variation, environment and commands. Extended-harness paired replay occurred after
implementation against that frozen input; it is not presented as an earlier capture.
Main, addon identity, settings, native hooks, module driver and excluded auction/
guild-bank/void callbacks are unchanged. No external code/assets were copied.
Candidate commit `efca305c76a87f9db36db12a1a2400272a253633`, tree
`1aa4627d774e10515dc52681b0cb527dba4ab60b`; the complete tested workspace also
includes the separate pending tracker correction.

## Finding and change

Each successful visible aura update discovers Blizzard's countdown FontString in
ReadLabel, then discovers it again when fading native digits. On older clients
that fallback also allocates a table of GetRegions results twice. HostLevel creates
a temporary three-frame table on every update solely to read their levels.

The existing countdown owner now passes the current poll's FontString directly
to its label/alpha paths and reads the same three frame levels without a temporary
table. No FontString or level is cached across polls. Changed regions and levels
are reread immediately; native lookup fallback remains when no region was found.
All three native level reads and restricted-value guards remain.

This is a work/allocation optimization, not a visual bug correction. Labels,
12px outlined font, 28x18 host, centered zero-offset anchor, highest-readable-level
plus five, native-digit restoration, preview exclusion and 0.1-second timing stay
the same. Missing/inaccessible/expired/long-duration data and placement failure
still restore native digits. Permanent frame/event ownership is unchanged.

## Desktop before/after evidence

The actual pre-edit complete suite passes 92 scripts/733 syntax files in the
[baseline report](validation/nameplate-baseline-full-2026-10-29.json).
[Focused replay](../tests/nameplate_countdown_work.lua) loads the real Core and
Countdown sources with read-only native proxies. Five branch labels cover existing
client paths; these are not native client certifications.

Five fresh-process alternating pairs include startup, 20 warm-up polls, 100
steady polls with 100 auras (10,000 updates), plus 100 remove/re-add cycles and
inactive controls. The ten simulated seconds are not wall-clock native gameplay.
Operation/resource counts have zero range across pairs. Lua GC stops only during
the steady desktop heap window and resumes immediately.

| Steady scenario, per 10,000 updates | Before | Candidate |
|---|---:|---:|
| Modern font-region calls | 20,000 | 10,000 |
| Legacy GetRegions calls | 20,000 | 10,000 |
| Native frame-level reads | 30,000 | 30,000 |
| Text writes / anchor writes | 10,000 / 10,000 | 10,000 / 10,000 |
| Frames, including two core frames | 102 | 102 |
| Modern Lua heap growth, representative median KiB | 1,015.688 | 0.063 |
| Legacy Lua heap growth, median KiB | 3,046.938 | 1,015.688 |

Startup halves discovery calls for the same 100 labels/hosts. The 100-cycle case
halves modern/legacy discovery calls while retaining 300 text/anchor writes,
900 level reads and five total frames. Inactive driver work remains zero.
Heap figures include this desktop fixture's Lua costs; they are not native
allocation bytes, native memory savings or a demonstrated persistent leak rate.
Desktop CPU samples overlap and are advisory; no native FPS claim follows.

Candidate passes **1,160 checks**; frozen baseline has 15 unmet optimization
budgets with behavior controls passing. Five mutations are rejected: duplicate
lookup, stale cross-poll region, lost opaque label, slower polling and wrong level.
The existing broad source guard now accepts the helper's optional third argument
while retaining its label-before-fade ordering assertion. The new behavioral
regression checks native alpha restoration directly.

## In-game validation and remaining acceptance

Native results are recorded separately in
[the native report](validation/nameplate-countdown-native-2026-10-29.json).
The [temporary widget probe](validation/nameplate-native-probe-2026-10-29.txt)
records its construction, warm-up, geometry checks and alternating timing loop.
Retail is 12.1.5 / 70575 / interface 120105 / project 1. Current hardware is
i7-12700F (12 cores/20 logical processors), 34,164,105,216 reported RAM bytes,
RTX 3060 driver 32.0.16.1692, Windows 11 Home 10.0.26200. Parsec virtual display
is also installed; active adapter selection is not independently verified. Native
metadata records D3D12, 1920x1009 physical client, scale 0.75, renderScale 1,
graphicsQuality 0, VSync off, and the loaded _FluxUI/BugTabs/FPS_MS_Monitor versions.
Source/settings recovery preserves the existing character/account profile.

The five alternating native pairs use the same real WoW Frame/Cooldown/FontString
under a hidden root, 20 warm-up calls per variant, then 2,000 synchronous Poll calls
per variant/trial. Both closures come from recorded source; only header comment
punctuation changed during normal chat delivery. Exported executable source lines
and literals were verified identical, and the ASCII probe matched exactly.
The local test facade registers no production module or global/native API replacement.

| Native real-widget observation | Before | Candidate |
|---|---:|---:|
| Median elapsed ms per 2,000 updates | 33.371 | 31.712 |
| Observed elapsed range, ms | 32.790-38.333 | 31.267-33.021 |
| Retained fixture hosts per variant | 1 | 1 |
| Native digit alpha after successful label | 0 | 0 |
| Captured session errors | 0 | 0 |

One pair has a slower candidate. Owned-widget geometry matches exactly, including
font 12/OUTLINE, CENTER offsets 0/0, width 28, native-reported height
18.00000190734863 and level 8 in this fixture. Hide/show reuses its host. Native
heap/allocation bytes and operation latency/frame tails were not measured.
scriptProfile remains 0; debugprofilestop measures synchronous elapsed work,
not isolated addon CPU or FPS.

Complete-addon baseline/candidate each ran one 20-second capture after a scheduled
30-second warm-up. Frames remain stable within each window (14,632 / 14,752),
but camera, mount and plate density change; the candidate also includes five direct
temporary fixture frames. These are not matched whole-addon performance/pixel runs.
Legacy CPU zero means unavailable with profiling off. Modern recent samples are
retained as context only. Private 1936x1048 screenshots were inspected; they cannot
establish a controlled scene difference. No overall speedup or FPS gain is claimed.

The training-dummy scene has active plates but no visible aura countdowns.
Real-widget checks do not certify actual protected aura rendering, combat taint or
secret-value behavior. Those checks remain pending. Temporary frames/globals and
the diagnostic SavedVariables root were removed by normal reload; on-disk root nil
verified, original profile 0 retained and WoW left open in the background.

For real gameplay acceptance on each available client:

1. Record GetBuildInfo/project/interface, addon list, settings/profile, resolution,
   effective scales, fonts, hardware and scriptProfile preference. Preserve a
   fresh source/settings checkpoint and normal rollback source.
2. At the same nameplate and camera, show native buff/debuff/CC/LoC countdowns.
   Capture unscaled screenshots and host/cooldown geometry before changing source.
   Include ten-second and sub-ten-second labels, expiry, aura refresh/removal and reuse.
3. Use five matched alternating baseline/candidate 30–60-second windows after
   30 seconds of warm-up, separating cold setup and repeated aura bursts. Keep
   the complete addon and affected overlays enabled. Use existing /fluxperf capture;
   preserve raw reports and account for profiler/census overhead.
4. Verify 12px font/outline/alpha/anchors/levels and unchanged update timing;
   no double digits, stale digits or lost native fallback. Remove all plates and
   confirm the driver sleeps; re-add/reuse them repeatedly and compare resource counts.
5. Exercise combat, native restricted displays, Settings previews and supported
   plate styles. Never serialize/compare opaque labels or bypass restricted APIs.
   Restore the original profiler preference, remove diagnostic data and reload.

Other clients, foreground FPS/frame tails, actual aura pixels and combat/security
remain pending until those scenarios are run. Continue the
[original stage gates](MODERNIZATION_PROGRESS.md), not a blanket compatibility claim.
