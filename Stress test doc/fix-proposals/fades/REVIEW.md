# Cast/swing fade proposals — not applied

These are concrete external candidates for USER-001's two conditional OUT-fade
suppliers and ALPHA-02. The user's actual fading frame remains unknown, so these
are **local fixes to demonstrated risks, not a confirmed resolution of the
reported native error**. No live addon, game, settings or profiler change was made.

Frozen baseline: external snapshot `fix-proposals-20261107T122821Z`, identified by
[workspace metadata](../workspace.json). Full candidate files are outside AddOns,
under that snapshot's `candidates/fades/UnitFrames/`. Exact raw identities are in
[candidate-identities.json](candidate-identities.json). The two live source files
still match the frozen baseline after verification; unrelated concurrent edits
are handled by the root checkpoint.

## Review in two stages

| Stage | Concrete proposal | Recommendation and preserved behavior |
|---|---|---|
| [01-minimal-first.patch](01-minimal-first.patch) | Cast fade uses public starting alpha1 after its existing `SetAlpha(1)`; remove the return-redundant alpha predicate in `CastBarIsBusy`. | Small first candidates. Existing cast0.75s/interrupt0.30s fades, hold times, callbacks and active-cast priority remain.84 public priority cases preserve the exact returned boolean. |
| [02-swing-ownership-prototype.patch](02-swing-ownership-prototype.patch) | Swing tracks its private public alpha and the native Out helper's just-created public fade record; derives restart midpoint from that record instead of `GetAlpha`. A new owner write retires the old fade, and completion checks the originating record identity. | Broader prototype held for native acceptance. Preserves ordinary alpha1, OOR0.4,1.0s duration and true fade-to-fade midpoint restart. It intentionally fixes the stale ownership cases listed below. |

Stage02 is relative to stage01. [Combined diff](candidate.patch) compares the
complete external candidate directly with the frozen baseline. These patches
have not been applied. [Stage identities](review-stages.json) retain each exact
review result, so later application can check for source drift first.

## How the swing prototype preserves alpha without a native getter

The swing frame is private and unnamed; the repository exposes no frame getter
or other established alpha writer. Its seven existing explicit alpha-write
sites now use one local setter. The existing native `UIFrameFadeOut` still
creates its usual record and uses its usual shared manager. Our call supplies
known public endpoints; the prototype retains that specific record by identity.
Only the native manager advances its public `fadeTimer`. A fade-to-fade restart
uses the same formula and elapsed value as the last native paint, avoiding both
secret alpha reads and wall-clock approximation.

No new frame, event, hook, ticker, polling loop or timer was added. The same one
completion timer and native fade record remain per start. There are two local
helpers, a public numeric alpha and a reference to that record; the existing
completion closure additionally retains the record identity. This is not a
native CPU/FPS measurement.

The prototype intentionally changes these ownership races:

- A new explicit show/reset/alpha write cancels the preceding fade's timer,
  removes only its queue entry and releases its record. The preceding fade can
  no longer repaint over the new owner's requested value.
- Disabling/re-enabling hides and clears owned fade work rather than retaining a
  hidden queue entry. Existing swing countdown and linger settings are retained.
- A cancelled old completion callback cannot hide a replacement fade: its
  original record identity must still be current.

These are intentional fixes, not claims of historical ordering parity. In
particular, a timer-value stamp alone was rejected during review: a native
zero-elapsed update can repaint without changing `fadeTimer`. Retiring the old
fade on owner override avoids that ambiguity. A dedicated control reproduces
the historical0.252 repaint over a newly requested0.4 and verifies the prototype
keeps0.4, including an elapsed0 update. True fade-to-fade restart still preserves
the current midpoint; there is no blanket restart at1.

## Evidence and limits

Run from the repository root:

```powershell
python 'Stress test doc/fix-proposals/fades/verify.py'
```

[Raw results](results.json) record:

- Five processes ×1,017 focused assertions:20 expected baseline opaque-getter
  rejections in total; the candidate passes those cases.40 assertions separately
  cover intentional ownership fixes, including zero elapsed, old timer delivery,
  hidden queue cleanup, re-enable and repeated show.
- Matched public alpha trajectories, exact restart midpoint, cancellation,
  ordinary/OOR state, existing timer delays, native-first/timer-first completion,
  repeated starts and preservation of another native fade owner.
- Five rejected in-memory regressions: forcing swing alpha1, losing the fade
  record, restoring cast/priority getters and allowing the stale completion.
- Existing complete cast/school fixture13,942 checks and timer synchronization
  fixture379 checks pass for both frozen baseline and candidate. Binary artwork
  is read from the same existing live files because the external code snapshot
  omits assets; those consumed asset hashes also remain unchanged.
- Both candidate Lua files pass `luac -p`. All consumed code/test/art/source
  hashes remain unchanged throughout final verification.

The focused harness executes real production function bodies and the pinned
Forever native fade manager from commit
`9dc84f0d3bbae1768ac3405b3716000bd93eda06`, FrameUtil blob
`a1fe94ae627fe3c694d5c38df9f0d1a54eecb84d`. Frames, timers and an opaque getter
are models; the existing fixtures cover their stated client models only.
Neither test route recreates native secret numbers, taint propagation, hardware
input, real rendering or server/instance restrictions.

Native checks remain pending for each client/build: identify the actual
USER-001 fade owner; verify normal/interrupt/channel/empower and cast→swing
handoff; compare OOR/range changes, restart/show/disable behavior and timing;
check simultaneous native chat/map fades, combat/world/dungeon/raid restrictions
and pixel parity. The broader Swing prototype should remain held until those
checks can establish its stated scope. Nothing was installed or applied.
