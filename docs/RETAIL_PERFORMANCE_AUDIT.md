# Retail performance and resource audit — 29 October 2026

The audit covers the current 577-file load closure and records recurring-driver
candidates across [26 source domains](PERFORMANCE_AUDIT.csv). It finds two
reproducible resource defects: loot-roll waiters accumulate native frames, and
optional performance captures retain full endpoint snapshots after completion or
cancellation. Both have focused fixes. This is not a declaration that every feature
is leak-free or that background FPS certifies gameplay performance.

## Actual baseline and recovery

HEAD was `e1132d0948906acef72be9e4c28dff60a5736931`, tree
`f0950ad82840e76ba076d791ae53d78393666e5e`, with an uncommitted objective-tracker
correction and its test/records. Those changes were preserved. The actual baseline
is that HEAD **plus the checkpoint's actual files**, not HEAD alone. Verified
external `Retail-audit-recovery-20261029T143824Z` contains 1,246 files, all history
and 403 on-disk WTF files. Retail was running; unsaved in-memory settings are not
covered. Source archive SHA-256:
`fcc345a42d493ad607d69f2df8b6efd956c118664c3e7c2f7d04fd1454c21bad`.

All 731 baseline Lua hashes match the preceding 90-script tracker report.
No new addon, repository, identity, framework, asset copy or settings reset.
Main remains `7436820453d2248c84c99fff71507553efc47c19`. Auction, guild-bank and
void-storage callback audits remain excluded. Census/profiling reads do not invoke
those callbacks. Original tracker source/test files remain byte-identical to the
checkpoint; their pending changes are kept out of the new runtime commits.

## Native context and baseline

Actual Retail `GetBuildInfo`: **12.1.5 / 70575 / interface 120105**, build date
22 October 2026, project ID 1. The advertised TOC remains 120100; no compatibility
declaration is changed. Level 81 Mage in Stormwind City, training-dummy nameplates
visible, embedded Map tab open, native World Map and Character panel closed.
Loaded addons: `_FluxUI` 0.0.1, BugTabs 1.4.9, FPS_MS_Monitor 12.15. No external
Syndicator/Baganator appears in this load list.

Recorded hardware: i7-12700F (12 cores/20 logical processors), 32 GiB RAM,
RTX 3060 driver 32.0.16.1692, Windows NT 10.0.26200. Parsec virtual display
0.45.0.0 is also installed; device selection is not independently verified.
Native renderer CVar is D3D12, physical client 1920 x 1009, UI scale 0.75 with
useUiScale=1, renderScale=1, graphicsQuality=0, native GameFontNormal
`Fonts\FRIZQT__.TTF` / 12 / empty flags. Existing character settings/profile are
preserved; private character/account names and raw settings are not published.

CVars: maxFPS=120, maxFPSBk=30, useMaxFPS=0, useMaxFPSBk=0, vsync=0,
targetFPS=60, useTargetFPS=0, gxMaxFrameLatency=2. Cap values alone do not imply
enabled caps. Original scriptProfile was **0**; it was temporarily enabled with
normal reload for CPU attribution. No graphics or automation preference changed.

The existing optional capture ran five 20-second background windows after a
30-second warm-up, with eight-second gaps. Ten endpoint samples forced supported
full Lua collection outside CPU windows, then read memory and enumerated frames.
The [raw before block](validation/retail-idle-native-before-2026-10-29.json) retains
build/settings, samples, variation, function/frame ownership and census data.
The [temporary probe](validation/retail-idle-probe-2026-10-29.txt) adds no permanent
hooks or global API replacements. Its timers, scans, report retention and collection
are measurement overhead. No foreground/mouse/clipboard control was used. PC
activity and camera were uncontrolled; native FPS/pixel/interaction acceptance is
not inferred. A timed reload was refused by the client; normal slash dispatch
saved the data. That refusal is recorded, not bypassed or attributed to ordinary
addon gameplay.

| Baseline observation | Measured result |
|---|---|
| Addon CPU ms/second | median 30.772; range 30.107–37.046 |
| All native frames | 14,742 at all ten endpoints |
| Frames with Flux creation source | 1,449 at all endpoints |
| Visible Flux-source frames | 458 at all endpoints |
| Flux-source registered OnUpdate scripts, including hidden | 212 at all endpoints |
| Visible OnUpdates, all addons | 36 before/after each capture |
| Shared Flux ticker subscribers | one, bars.assistant |
| Sampled public cache tables | eight; endpoint sizes unchanged |
| Addon post-collection memory | 24,115 -> 64,565 KiB during repeated diagnostics |

The stable frame count is evidence for this idle scene only. Rising memory during
captures is not proof that the ordinary HUD leaks at that rate: the capture source
retains large snapshots, the harness retains compact reports, and profiling itself
has overhead. Public-cache sampling cannot observe every module-local cache.

## CPU findings and source checks

The Flux nameplate driver is the largest owned OnUpdate, about 12.5–13.1 ms/s.
Its frame creation source is `NamePlates/Core.lua:485`. Source review confirms it
hides when activeUnits becomes empty; the visible training dummies keep it active.
Countdown polls at 0.1 seconds; level/threat at 0.25 seconds. Repeated add/remove,
option disable and same-fact repaint work need separate matched traces.

Assisted-action work is the sole shared ticker subscriber. Its callback ranges
about 6.7–11.9 ms/s; host traversal, painting and SyncColumn appear below it.
Those inclusive rows overlap. Native chat callbacks and the visible Blizzard map
also consume time outside Flux's addon bill. Do not sum rankings, disable features,
slow responses or equate lower addon CPU with higher FPS on this evidence alone.

Source checks also distinguish retained caches from reproduced defects:

- Binding availability removes records for deleted bindings. Extra macro parse
  caches clear on frame/condition changes. Spell caches reset on their existing
  invalidations. These are existing controls, not newly proven leaks.
- Cast-bar visual metadata already caps its cache at 1,024 entries. Equipment
  candidate/tooltip caches have inventory invalidation. Prior unit resource watcher
  reuse still passes 16,272 checks and seven mutation controls.
- The talent-tree inspection GUID cache has a freshness TTL without eviction in
  its source path. That is a long-session growth candidate, not a reproduced
  Retail leak; its writes require the older inspect-talents contract.
- Mirror-timer wrappers already have weak installation guards in current source.
  The old QoL paragraph claiming no guard was stale and is corrected. No duration
  runtime change is justified by that historical statement.

## BUG-009 / PERF-007: loot-roll waiter ownership

Failure: each combat episode creates a new PLAYER_REGEN_ENABLED frame. Completed
frames cannot be destroyed by WoW. Repeated world-entry initialization while the
player border is missing also creates overlapping readiness frames. A cleared
pending flag can leave the combat subscription armed.

Fix `6ac4389`: retain one waiter on each native loot frame and one module readiness
watcher; always disarm the combat waiter when regen fires. Preserve native show
ownership, the 50-update readiness deadline, immediate readiness positioning,
combat geometry guard and six-pixel BOTTOM-to-TOP anchor. No new setting or service.

`tests/loot_roll_lifecycle.lua` executes the real source against persistent native
frame identities. Five labels exercise two legacy/container routes, not five native
client certifications. Across 100 unavailable-player world entries, a timeout/
readiness retry, 100 combat cycles and one cleared request, allocations fall
**203 -> 3**. Combat waiter allocations **101 -> 1**. Hooks remain one; geometry
writes remain 101. Candidate passes 2,050 checks after 20 baseline failures.
Five alternating desktop pairs have zero count range in the
[comparison](validation/retail-lifecycle-comparison-2026-10-29.json).
Actual repeated combat/loot triggers, secure geometry and visual parity remain
pending; the idle native census does not exercise this leak trigger.

## BUG-010 / PERF-008: optional capture retention

Failure: the capture state retains its entire before.frames/functions snapshot and
timer handles after completion/cancellation. Expired/cancelled timer callbacks can
retain that state. This is requested diagnostic work, not an always-on capture.

Fix `3046478`: clear the full snapshot and both handle references after constructing
the compact report, and on cancellation. Rank limits, schema, safety checks, timer
deadlines, profiler preference and dormant behavior remain unchanged.

The regression deliberately retains timer callbacks after completion/cancellation,
with 500 modeled native frames and 20 cycles. Candidate retains **zero** full
snapshots/frame rows versus 20/10,000 per baseline model; 40 callback handles remain
in the fixture. This verifies release independently of native handle reclamation.
Candidate passes 400 checks after 200 baseline failures. Existing capture tests
pass 383 checks with 12 rejected mutations. Five alternating desktop pairs have
zero count range in the [comparison](validation/capture-retention-comparison-2026-10-29.json).

An attempted alternating native private-module probe was discarded: its long
chat-delivered source was truncated and the candidate did not compile. Only one
baseline run completed; none is acceptance evidence. Short direct calls to the
normal file-loaded capture API are used for the follow-up. No native API was
replaced. Native follow-up results and limitations are recorded separately below.

## Validation and remaining scope

Complete current actual-file suite: **92 desktop scripts, 733 Lua syntax files,
zero failures** in the [full report](validation/retail-lifecycle-full-2026-10-29.json).
It includes the preserved uncommitted tracker test; the checkpoint and manifest
identify that actual corpus. Runtime commits alone do not identify those pending
tracker files. No deployment/sync job, push or main update was performed.

```powershell
lua tests/loot_roll_lifecycle.lua --source tests/fixtures/loot_roll_position_before.txt --measure
lua tests/loot_roll_lifecycle.lua
lua tests/perf_capture_retention.lua --source tests/fixtures/perf_capture_retention_before.txt --measure
lua tests/perf_capture_retention.lua
lua tests/perf_capture.lua
python tests/run_validation.py --output docs/validation/retail-lifecycle-full-2026-10-29.json --sync-docs
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Measure mode deliberately exits zero for the known failing baselines. Verify all
current Lua hashes before reusing a complete-suite report.

Next: finish candidate capture memory checks, then attribute redundant nameplate/
assistant work without changing timing. Test options/bags/map/respec/bindings and
unit/raid/nameplate lifecycles through repeated open/close, add/remove and disable/
enable cycles. Compare retained objects after collection, bounded cache/pool high-
water levels, callbacks/subscriptions and queued work. Add combat, loading screens,
raid/instance, item/spell churn, standalone/external provider and multi-hour runs.
Separate startup, steady idle and bursts. Native allocations, foreground frame
tails/FPS, pixels/input/taint/secrets, other clients and exhaustive leak acceptance
remain pending. No universal compatibility or leak-free claim is made.

## Native release follow-up — partial evidence

Five direct, actual file-loaded candidate captures completed with scriptProfile=1.
Each CPU window is20 seconds; manual post-GC endpoints are90-235 seconds apart
before/after each capture, versus about22 seconds in the automatic before block.
The [raw after block](validation/retail-idle-native-after-2026-10-29.json) and
[direct commands](validation/retail-idle-direct-commands-2026-10-29.json) retain
actual timings, report schemas, memory samples, context and exact source hash.
Build, addon list, class/level, renderer/font/scale/caps match the recorded before
context. Camera/PC activity were uncontrolled; total native frames are14,588 after
versus14,742 before. A later scripted follow-up that did not export was also discarded.

Post-collection addon memory across five retained reports is24,105 ->24,928 KiB
(824 KiB growth), versus24,115 ->64,565 KiB (40,450 KiB growth) in the before block.
Median capture-associated addon delta is186 KiB versus7,860 KiB. Compact reports
and diagnostic bookkeeping remain retained. This supports the explicit snapshot
release; it does not measure allocation bytes or certify normal HUD leak freedom.
The endpoint-gap/scene/frame-count differences prevent a strict controlled native
CPU/FPS/gameplay-memory claim. After CPU median21.315 ms/s (20.911-21.493) is retained
as context, not attributed as a speedup from these changes.

Original profiler=0 was restored; temporary exports/namespaces were cleared by a
normal reload. WoW remains open in the background. No further game input is needed
for this batch. The next work is nameplate/assistant attribution and repeated real
feature/lifecycle/long-session stress, with all previously pending checks explicit.
