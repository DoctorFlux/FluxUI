# Window mover disabled lifecycle — BUG-004 / PERF-003

The 29 October 2026 user continuation excludes auction, guild-bank and void-storage
callback work. This batch instead fixes the existing Windows enable option. It
uses the current mover and saved records; no new infrastructure or reference code.

## Failure, intended behavior and change

Before the fix, `WindowMover.Start()` calls `Scan()` even when the selected Windows
settings have `enabled=false`. The delayed startup and ADDON_LOADED scans do the
same. `Attach` installs permanent native mouse/show/layout hooks and may create drag
strips before `Apply` checks the option. Thus the disabled option still modifies
native interaction setup. The PlayerSpellsFrame visibility watcher continues its
0.1-second polling while disabled. Separately, the existing public
`SetEnabled(false)` does not call Refresh, so an active scale gesture keeps its
driver and continues updating saved scale, although Apply suppresses visible writes.
The ordinary options setter already calls Refresh and stops that gesture.

The intended behavior is that disabled discovery installs no new hooks, the existing
panel watcher sleeps, and both enable entrypoints stop active gestures on disable.
Re-enabling must discover missing panels and resume normal saved geometry and input.

[Engine.lua](../WindowMover/Engine.lua) now returns zero from Scan before catalog
access when disabled, and Refresh hides/shows the existing watcher according to the
selected settings. [Init.lua](../WindowMover/Init.lua) calls the existing Refresh on
both SetEnabled outcomes. The runtime diff adds seven lines and moves one call.
The native restriction guards, enabled cadence, assets, options/defaults/scopes,
saved roots, commands and saved frame records are preserved.

Existing native hooks remain installed and guarded after attachment; WoW hooks
cannot be removed by hiding the watcher. Startup keeps its two event subscriptions,
two bounded delayed callbacks and reusable proxy/driver. Those scan callbacks now
return before discovery while disabled. This is not complete module teardown.

## Identities and recovery

- Baseline commit `f1a3bc7488a904e075264794e080a00c8fceba23`, tree
  `8dbef40c11d122a47d238c0445e936d1894d28a8`.
- Candidate runtime commit `19c40a0c84212b24fdf221a9653a4116d32f9020`, tree
  `92973edadfdd5ebfc5935621bc2b77f1e0655066`.
- [Baseline identity](validation/window-mover-baseline-identity-2026-10-29.json)
  verifies all 725 Lua hashes equal the previous complete 84-script test corpus
  before reusing that full baseline. Retained `.txt` fixtures preserve the two
  pre-edit sources and are not loaded by the addon.
- [Recovery](RECOVERY.md) records the fresh external verified source/history/private
  settings checkpoint made before edits while WoW was closed.

## Desktop regression and measurements

[The test](../tests/window_mover_disabled.lua) executes production Catalog, Engine,
Init and Windows options. Native frame/event/timer/cursor/combat behavior is modeled.
It exercises actual module startup, options disable/enable, public SetEnabled,
delayed startup scans, addon events, Player Spells visibility transitions, saved
scale recovery, combat-deferred Apply and 100 enable/disable cycles. Real catalogue
filtering runs, but only CharacterFrame and PlayerSpellsFrame resolve in the model.
Native UI assets/rendering, secure VM and real secret values are not modeled.

```powershell
lua tests/window_mover_disabled.lua --baseline --measure
lua tests/window_mover_disabled.lua
lua WindowMover/_tmp_charactercombatsmoke.lua
python tests/run_validation.py --output docs/validation/window-mover-full-2026-10-29.json --sync-docs
```

`--measure` deliberately exits zero while retaining assertion failures for baseline
capture. Normal execution must have zero failures. Baseline has **108 failures in
220 checks**; candidate passes all **220 checks**. The existing character combat
smoke passes. [The full candidate suite](validation/window-mover-full-2026-10-29.json)
passes **85 scripts and 726 Lua syntax files**, zero failures.

Five alternating baseline/candidate process pairs use six modeled seconds of startup,
twenty addon-load events, a ten-second disabled capture at 0.1 seconds per frame,
and 100 toggle cycles. CPU profiling is off. Capture is operation bounded. Each
process is fresh, and enabled behavior is checked separately. Every count has zero
range across the five runs per variant.

| Scenario/operation | Before | After |
|---|---:|---:|
| Disabled startup plus 20 addon events: catalog calls | 24 | 0 |
| Same: frame resolution calls | 2,546 | 0 |
| Same: native hook registrations | 7 | 0 |
| Same: attached panels | 2 | 0 |
| Disable after enabled startup: 20 event scans | 20 | 0 |
| Same: frame resolution calls | 2,120 | 0 |
| Same: visibility polls in 10 modeled seconds | 100 | 0 |
| Public disable during scale: update callbacks in 1 modeled second | 20 | 0 |
| Same: saved scale changed after disable (boolean) | 1 | 0 |
| Frames after 100 cycles in the enabled-start fixture | 7 | 7 |
| Permanent hooks after those cycles | 7 | 7 |
| Retained Player Spells saved scale | 1.2 | 1.2 |

The seven frames include two modeled native panels, the options registration frame,
proxy/driver, discovery event frame and panel watcher. Hook counts are harness
observations, not native resource measurements. No allocation/memory or native CPU,
operation latency, frame time or FPS measurements were available. Process durations
in the raw JSON include the harness and process startup; no speedup is inferred.

[Raw baseline](validation/window-mover-baseline-2026-10-29.txt),
[candidate](validation/window-mover-candidate-2026-10-29.txt) and
[matched comparison](validation/window-mover-comparison-2026-10-29.json) preserve
commands, outputs, samples, variation, source/config hashes and environment. The
desktop environment is Windows 10.0.26200, Lua/luac 5.4.6, Python 3.10.6, i7-12700F
with 20 logical processors. GPU/RAM and a live addon list/profile/scene were
unavailable. No native client was launched. Result: **PASS for modeled lifecycle and
operation counts; native parity/performance pending**.

## Required native checks — all pending

Use the [native protocol](PERFORMANCE_PROTOCOL.md) and [client matrix](CLIENT_VALIDATION.md).
Record exact GetBuildInfo, hardware, addon versions, profile/scope, resolution,
UI scale/fonts and input mode. Use this same addon identity sequentially, preserving
current code/settings before any baseline swap; do not install another addon copy.

1. With Windows disabled before reload, open Character, Player Spells (where present)
   and a load-on-demand panel. Verify native clicks, close buttons and default native
   dragging work; no Flux drag strip is newly attached. Check errors/taint.
2. Enable through the Windows options without another reload. Match baseline enabled
   screenshots/geometry and verify title left-drag, right-drag scaling, middle reset,
   saved position/scale, lock/modifier/snap/clamp and independent account/character
   scope. Repeat reload and save-off session behavior.
3. Disable after attachment. Open/close Player Spells, trigger a normal addon load,
   and verify the watcher is dormant with a narrow native resource trace. Re-enable
   and confirm saved geometry and subsequent panel show transitions recover at the
   original cadence. Permanent native hooks remain installed and guarded.
4. For the public API path, stop a controlled scale gesture with
   `Flux.WindowMover.SetEnabled(false)` and verify the proxy/driver stop and saved
   scale stays fixed. Restore the prior option normally. Also test combat entry,
   pending Apply followed by disable, and re-enable after combat without taint.
5. Run five matched baseline/candidate pairs for startup, settled disabled idle and
   enable/disable bursts, using `/fluxstartup` and `/fluxperf capture` as appropriate.
   Preserve raw samples, repeat unprofiled frame captures and follow the overhead
   rules. Equivalent screenshots/input and native secure behavior remain mandatory.

All installed client targets retain their previous native acceptance status. This
batch does not certify pixel parity, secure execution or a native performance gain.
