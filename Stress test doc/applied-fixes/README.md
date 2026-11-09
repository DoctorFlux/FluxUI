# Applied stress fixes — 7 November 2026

The user's **“fix everything now”** instruction authorized implementation of the
earlier findings. The addon files were changed directly on `main`, after a fresh
[external source/history checkpoint](checkpoint.json). Existing dirty work and
all earlier audit/proposal evidence are retained. No settings reset, game input,
profiler change, commit or push was performed by this work.

[Current finding statuses](../FINDINGS.csv), [exact pre-edit/current identities](source-changes.json)
and the [combined test manifest](full-suite.json) are the current implementation
record. Original reports below the parent index describe their captured audit
baseline, including intentionally reproduced failures; they are historical.

Independent utility-key edits appeared during this work in `Core/ButtonFX/Click.lua`,
`ExtraButtonSystem/Engine/Action.lua` and the UtilitySlots manager. They were
preserved along with their `utility_secure_input` test update, and are identified
separately in the source-change record. The final
combined suite describes the captured combined files, without attributing those
utility changes to these stress fixes.

## Applied behavior

| Findings | Change and preserved behavior |
|---|---|
| USER-001 / ALPHA-02 | Cast-bar fades supply public endpoints. Swing fades track their own public trajectory, preserving midpoint restart, duration, priority and completion. A new owner cancels the prior fade/timer, so an old completion cannot hide a replacement. Neither supplier obtains fade alpha from an opaque frame getter. |
| SEC-01 | All seven native driver/watch globals retain their identities. Flux callers select the existing Forever fallback locally, preserving the repaired native paging probe and owned-frame policy. Other addons and unnamed native frames keep their native route. |
| SEC-02/03 | Respec propagates actual failure/defer/cancel results, retains recovery checkpoints on failure, detaches queued snapshots and rejects stale owners. Slot state is verified synchronously; stance saved-state writes and layout-request acceptance are checked. Existing deferred visual layout cadence remains. One watcher is reused during supersession storms. |
| INPUT-001/002 | Full context updates survive later narrow mouseover requests. Hover fallback consumes all child varargs, including first/last children; zero children and denied enumeration are safe. No per-scan child table is added. |
| LOGIC-01/02 / PERF-05 | Event removal preserves the remaining listeners. Inventory drains retain nested callbacks/tokens/reasons in FIFO order with a cursor. Stale timers cannot drain an extra batch after a regen wake. Older paused structural callbacks/listeners precede newer work, including repeated combat reentry. |
| PERF-SEC-01 / PERF-06 | Regen work runs at most 16 distinct jobs per frame, retaining order and pausing on combat reentry. Sustained mouseover no longer indefinitely postpones every shared range sweep; existing quiet cadence and disable cleanup remain. |
| PERF-01/02/03/04 | Raid paint arms once per outstanding merged batch. Public native nameplate state suppresses redundant alpha/anchor/hide writes; unknown state keeps repair writes. The hidden character-button watcher stops receiving OnUpdate. Visible native-state polling remains to preserve press/release/keybind/close behavior without unsafe hooks. |
| PERF-07 | After two invalidated auction scans, retry waits for the existing quiet interval instead of repeatedly discarding prefixes. Normal bounded scanning, query ownership, close/provider cancellation and atomic publication remain. An endlessly changing native list cannot supply a coherent final snapshot; quiet publication is intentionally retained. Guild-bank and void callbacks were not changed. |
| ALPHA-01/03/04/05 | Alpha access checks precede comparison. Narrowly guarded getter denial follows each feature's policy: the grid performs its permitted suppression write; cooldown tint/bling retains prior state and retries on normal paint; badge visibility can use public owner configuration. Missing legacy getters retain their prior compatibility policy. Unknown effective alpha is not fabricated as0 or1. |
| ALPHA-06 | Flux threat glow uses a private, MIT-attributed renderer and its public alpha/geometry state. Shared LibCustomGlow and existing ProcGlow remain unchanged; foreign winning libraries and overlays are never adopted. No arbitrary shared library minor-version override is added. |
| GEO-01/02 | Health prediction retains the original full-width/max-health normalization, including positive incoming heals and antiheal layers. Public dimensions come from existing owned size writes. Precreated clipping canvases preserve physical 32 px stripe phase while native fill geometry remains opaque. The rejected native remaining-span experiment was not applied. |

These fixes intentionally correct dropped work, false completion, secret-value
operations and avoidable repeated work. Commands, options, saved roots, artwork,
normal animation/input cadence and optional integrations remain part of the
regression requirements. The combat burst budget changes only how a large
backlog is spread across frames; distinct callbacks are retained.

The geometry change adds three clipping frames per modern health bar or two per
Classic health bar, created with the existing health factory and reused. The
private glow owns a separate reusable pool and retains the original active
animation driver. These are explicit resource costs; neither change is claimed
to improve native CPU time without a matched client measurement.

## Evidence

- [Security ownership/completion/cancellation](security/REVIEW.md), including six
  isolated checkpoint rejections, 264 driver checks, 320 Respec checks and 5,000
  supersessions across five client models. A further 200 checks cover related
  requested utility/consumable failure, deferral, cancellation and checkpoint
  ownership; disabled or uncaptured sections retain their skip behavior.
- [Alpha policies/private renderer](alpha-readers/REPORT.md), with three 647-check
  repetitions, eight old-code rejections per run, 240 public parity pairs and
  actual LibStub load-order controls. The public library source remains unchanged.
- [Final alpha/default-fade sweep](alpha-readers/FINAL_SWEEP.md), with 20 controls
  executing the four pinned native-source families and the remaining Classic
  shine callbacks. No additional alpha defect was reproduced in that bounded sweep.
- [Shared services and fades](shared-results.json), with repeated actual-owner
  fixtures, frozen baseline failures, five fade mutation rejections and the
  pinned native fade manager running under modeled frames/timers.
- [Independent queue review](security/SERVICE-REVIEW.md), including mixed
  structural/inventory requests and repeated combat reentry.
- [Geometry](geometry/REPORT.md), including factory/partition ownership,
  positive-heal paths, stripe phase, layout-only resizing and parent frame levels.
- [Performance budgets](performance/REPORT.md), with three 697-check repetitions
  and four checkpoint rejections covering raid/nameplate/watch lifecycle.
- [Complete validation](full-suite.json), which compiles the current Lua corpus
  and executes every registered standalone test. Source hashes distinguish it
  from earlier audit/proposal passes.

In the shared auction fixture, 200 events over 10 modeled seconds now discard 52
row reads for 32 rows and 50 for 1,024 rows, compared with 381/375 previously.
All eight client/size cases publish one coherent changed generation after quiet.
These are deterministic API call counts, not measured native CPU milliseconds.

Re-run `python -B tests/run_validation.py` for the permanent suite.
`run_shared_checks.py` also replays the focused shared/fade controls using the
dated external checkpoint and pinned local reference source. Some historical
audit harnesses deliberately assert or record the old defects; use current
acceptance scripts when checking the applied code.

## Remaining native acceptance

Era, Anniversary, Retail live and Forever use the four pinned Gethe source
identities in the [client ledger](../CLIENT_LEDGER.csv). The source versions
are references, not a capture of the user's running build. Extra progression
fixtures add coverage without pretending to emulate a whole client.

The user reported 13 `FrameUtil.lua:427/startAlpha` entries at seven timestamps.
The actual affected frame, preceding action and first taint cause remain unknown.
The public cast/swing suppliers and related conditional hazards are corrected
and pass the stated models; the native error's disappearance is **not yet
confirmed**. Editing a file does not clear prior in-memory taint. A normal
user-controlled reload is required to load these changes.

Native secure execution, real secret-value permissions, combat/instance rules,
pixels and hardware CPU/FPS remain **pending** under the user's simulation-only
testing instruction. Mock clocks, opaque tables, setter counts and public
geometry equations do not certify those native boundaries. Further native logs
can be added to the same error intake without replacing this evidence.
