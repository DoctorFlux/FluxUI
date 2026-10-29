# Action-bar and player-aura audit

29 October 2026. Continue the original modernization plan in the existing addon;
preserve every feature, appearance and response cadence. This batch investigates
the action strip and the player's auras, with a bounded PERF-010 optimization.
It does not declare the entire addon fully optimized or leak-free.

## Baseline and requirements

Baseline HEAD `bda2d8a66fbc7c911783f5803822bf45cdaf868f`, tree
`4bace2ae6aacfdeba5e40332ebd7e7aa57658f26`, plus the preserved pending objective-
tracker correction and test/records. External `Bars-auras-recovery-20261029T170131Z`
captures 1,284 actual files, all history and 404 on-disk settings files, verified
entry-by-entry. The running clients' unsaved in-memory settings are not a quiescent
backup. Private settings/screenshots remain outside the repository.

The [original action-bar requirements](../new%20docs/docs/specs/11-action-bars.md),
[unit-frame requirements](../new%20docs/docs/specs/14-unit-frames.md) and
[minimap/aura placement requirements](../new%20docs/docs/specs/18-minimap-and-trackers.md)
remain governing inputs, alongside the current implementation and discrepancy
ledger. [Seven ownership groups](ACTION_AURA_AUDIT.csv) map the reviewed scope,
existing controls and remaining native scenarios. The initial complete workspace
passes 93 scripts/734 syntax files in the
[baseline report](validation/bars-auras-baseline-full-2026-10-29.json).

## PERF-010: one activation sample per paint batch

PaintAssistedHighlights already samples highlight activation and the next spell,
then UpdateAssistedHighlight repeats activation for each of 57 surfaces. Flush
does the same during icon/count repaint. This is duplicate same-pass work, including
when the feature is disabled and retained overlays merely need clearing.

The existing single-host painter now accepts an optional activation fact from its
batch caller. The batch passes an explicit boolean, including false. Standalone
calls still query current state; nothing is cached across batches or frames. The
client API's next-spell helper retains its independent activation/security guard.
No new frame, event, timer, hook, service, setting, subscription or persistent cache.

The same hosts and live slots are visited at the same cadence. Candidate spell
checks, next-spell reads, parked/empty cleanup, hide/show calls, combat animation
play/stop, native highlight template, font/texture/size/level/input behavior and
secure action attributes remain under their existing owners.

Five fresh-process alternating desktop pairs use 20 warm-up passes, then 100
synchronous 57-surface passes in disabled/enabled periodic and Flush scenarios.
The [raw comparison](validation/action-highlight-comparison-2026-10-29.json)
includes hashes, commands, every sample/range and mutation output.

| Per 100 passes / 57 surfaces | Before | Candidate |
|---|---:|---:|
| Activation queries, disabled | 5,800 | 100 |
| Activation queries, enabled | 5,900 | 200 |
| Next-spell queries, enabled | 100 | 100 |
| Candidate checks, enabled | 5,700 | 5,700 |
| Disabled hide / animation-stop calls | 5,700 / 5,700 | 5,700 / 5,700 |
| Retained fixture frames | 57 | 57 |

Operation/resource count ranges are zero across pairs. Desktop CPU samples are
advisory; native allocations and frame tails are not measured by this fixture.
[Regression](../tests/assisted_highlight_work.lua): 1,420 checks, including 100
enable/disable cycles per branch, minirow construction/reuse, direct-call freshness,
changed/opaque spell identity, parked faces, combat effects and missing APIs.
Frozen baseline has 20 unmet work budgets with behavior controls passing. Five
mutations reject lost batch facts, stale cross-pass state, lost direct refresh,
missing disabled cleanup and wrong geometry. Five branch labels are desktop paths,
not five native client certifications.

## Player auras: ownership and current findings

Top-right player BuffFrame/DebuffFrame are native Blizzard UI. Flux's
Minimap/FluxBuffDebuffFrames.lua owns their screen placement, one event watcher
and weak guarded ApplySystemAnchor hooks. It has no UNIT_AURA subscription,
OnUpdate aura scanner or replacement aura painter. Positioning defers in combat
and Edit Mode; native buttons, events, data, styling, expiry and cancellation stay
Blizzard-owned. Unused compatibility entry points are retained because current
callers still invoke them.

Player-cast debuffs on target/focus are a different subsystem: AuraOwn supplies
the ownership/filter policy to the custom and native-container renderers. Existing
debounce cancellation on disable and target/focus instance maps remain. Further
dense-aura/restricted-display, target reuse and long-session stress is pending;
source review alone does not prove every lifecycle safe.

The existing native-player aura smoke preserves original handlers and dispatches
600 combat UNIT_AURA updates per frame without touching payloads. It covers late
load, embed, native reanchor, combat, Edit Mode and scaling. Existing player-frame,
Forever aura, lifecycle and bar/paging/effect regressions remain controls.
There is no measured aura hotspot justifying a native aura rewrite in this batch.

## Native validation and limits

[Native results](validation/action-highlight-native-2026-10-29.json) separate
Retail and Era builds, characters matched to the user's request, addon/settings
metadata, original profiler preferences, exact source transport and actual captures.
The [temporary probe](validation/action-highlight-native-probe-2026-10-29.txt)
uses private source-derived batch functions delegating to the real current painter;
no global/native API or production function is replaced. Five alternating pairs
time 100 passes each after 20 warm-up calls. Geometry is sampled from all 57 real
button surfaces before and after the matched runs.

Runtime/test commit `677d85c0f0a476c252e65e5703ca20b78d98528b`, tree
`05fa9fc0de4f874a9c99cc7d49887890f610ba08`. Both clients' received source strings
match the recorded ASCII batch/probe source exactly. Current native highlight
activation is false on both clients; the enabled path has desktop coverage and
still needs actual native input/combat acceptance.

| Native matched observation | Retail | Era executable / SoD realm |
|---|---:|---:|
| Build / interface / project | 12.1.5.70575 / 120105 / 1 | 1.15.9.70576 / 11509 / 2 |
| Median before -> candidate ms per 100 passes | 5.303 -> 2.728 | 8.568 -> 3.079 |
| Before elapsed range, ms | 5.274-5.350 | 8.348-10.204 |
| Candidate elapsed range, ms | 2.668-2.782 | 2.973-4.542 |
| Activation calls per 100 passes | 5,800 -> 100 | 5,800 -> 100 |
| Real button geometries unchanged | 57 | 57 |
| Recorded session errors before / after matched runs | 0 / 0 | 0 / 0 |
| Original -> final scriptProfile | 0 -> 0 | 1 -> 1 |

These synchronous elapsed timings include profiling overhead and native API calls;
they are scoped to this paint path, not isolated whole-addon CPU or FPS. Hardware
is the same host recorded earlier today: i7-12700F, reported RAM 34,164,105,216 bytes,
RTX 3060 driver 32.0.16.1692, Windows 11 Home 10.0.26200, with Parsec virtual display
also installed. Per-client physical resolution, UI scale, graphics/CVars, font,
zone, loaded addons and source identities are in the raw native report. Existing
account/character settings are preserved in external recovery, not published.

Whole-addon CPU context is Retail 25.537 -> 25.794 ms/s, Era 8.494 -> 7.922 ms/s.
Do not interpret the differing directions as a proved overall regression or gain
from this single-window comparison. Retail's remaining assisted-host paint is
4.814 ms/s in the baseline ranking, overlapping its child calls; it is the next
attribution target. Idle native BuffFrame/DebuffFrame inclusive observations are
0.0385/0.0698 ms/s Retail and 0.0592/0.0867 ms/s Era. These short observations do
not cover dense aura bursts and must not be added to overlapping inclusive totals.
Both aura roots retain exactly matching before/after anchors, scale and visibility.
The baseline root OnEvent references remain unchanged during each observation.

Whole-addon baseline/candidate blocks are separate 20-second captures after
30-second scheduled warm-up. One block per version cannot establish an overall
CPU/FPS gain; repeated matched production scenes and real input remain required.
Do not sum inclusive function/frame timings. Native memory allocation/long-session
leak acceptance and foreground frame-time tails remain pending.

Both processes can remain open, but this account's sessions displace each other.
Tests run sequentially using normal warning dismissal, Reconnect and the selected
characters. No credentials, restriction bypass or repeated competing login loop.
Background window messages/captures never activate windows or take PC mouse,
keyboard focus or clipboard. Original profiling preferences and diagnostic roots
must be restored before stopping.

The user-owned continuous sync job is left unchanged. Its actual timeout is one
second although the text says 60; repeated mirroring is external load, not addon
Lua CPU. Source identities are verified at each test transition. If delivery lags,
only the known verified test file is copied to the existing Era addon; no second
addon/repository, broad manual deployment or new sync service is created.

## Next scenarios

Prioritize the remaining measured assisted-host icon/count/cooldown/usable work,
including repeated next-spell reads. Establish one-pass identity/readiness semantics
before sharing those facts. Keep physical input, secure paging and effects timely.
Exercise pet/stance/vehicle/possess/modifier changes, macro/badge promotion,
binding mode, no/many auras, expiry/reapply, player vehicle transfer, combat/Edit
Mode, optional integrations and repeated enable/disable/reload on exact clients.
Retain settings/options and native aura ownership throughout. Auction, guild-bank
and void-storage callback audits remain excluded; main stays untouched.
