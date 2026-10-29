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
