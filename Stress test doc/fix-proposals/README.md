# Fix proposals for review — not applied

<!-- STRESS-FIXES-20261107 -->
These proposals were followed by explicit implementation authorization. [Applied fixes and current evidence](../applied-fixes/README.md) supersede the earlier no-application status below. Rejected native remaining-span geometry remains rejected; final public-dimension/clipping design is recorded separately.
<!-- /STRESS-FIXES-20261107 -->

The smallest cast fix is concrete and tested: `StartCastBarFadeOut` already sets
alpha to1, so pass that known public1 into the native fade instead of calling
`GetAlpha()`. A second minimal change removes a swing-priority alpha read whose
two outcomes already returnfalse. Both preserve their ordinary public behavior.

The recurring native error also has a second direct candidate supplier: Swing's
fade. A broader isolated Swing prototype tracks its own public fade state,
preserves restart opacity, and retires old fades when a new owner show/hide/reset
supersedes them. It avoids the alpha getter and fixes stale completion races.
Those ownership changes are intentional and separately tested; they are not
described as identical historical race behavior.

**Nothing in the live addon has been changed by this phase.** The frozen baseline
and actual candidate `.lua` files are outside AddOns, at paths in
[workspace.json](workspace.json). The test/report/patch files here are not loaded
by the addon. No game input, native reload, settings, profiler, sync, branch,
commit or push action was performed.

## What is ready to review, and what is held

| Proposal | Concrete result | Decision before any application |
|---|---|---|
| Cast public fade endpoint + redundant swing-priority read | Minimal staged diff; baseline restricted-getter failures rejected; ordinary return/alpha behavior retained | First small review candidates. This alone does not remove Swing's separate fade getter or identify the actual USER-001 frame |
| Swing public fade ownership | Isolated prototype with midpoint restart,0/0.4/1, zero-elapsed events, show/hide/reset, stale timer and completion tests | Broader prototype held for native behavior/appearance acceptance; preserve its intentional ownership fixes explicitly |
| Alpha readers in grid/cast/badge/cooldowns | Public appearance comparisons and deferred unknown-state policy tested; stable public0 grid setter budget retained | Getter-call denial and exact appearance while effective alpha is private remain gates on general application |
| Glow alpha ledger + threat cache commit | Public recolor/animation/pool controls pass without texture alpha reads | Coupled gate: confirm a corrected winning LibStub renderer. Do not apply the Shared retry change alone with an unfixed external renderer |
| GEO-01 native remaining-span geometry | Initially passes matched-health math, but a valid stale-health counterexample changes50px to33.33px | **Rejected**. Experiment is archived outside selected candidates; no geometric change is selected |
| GEO-01 public-owner geometry alternative | Direction documented, including another existing positive-heal/secret-width boundary | Held: public width availability, initial unknown layout and complete owner policy remain unresolved |
| GEO-02 tiled overlay | No feature-preserving/native-permission proof for replacing UV arithmetic while preserving stripe frequency | Held; existing code/art remains unchanged |

The actual fading frame in the user's reported `FrameUtil.lua:427` stack remains
unconfirmed. Native chat/other owners share the manager, so the proposals do not
guarantee that applying only one suspected caller would end every report. No
candidate is marked as a native taint or pixel pass.

## Review artifacts

- [Fade review and staged patches](fades/REVIEW.md):
  [minimal first-stage diff](fades/01-minimal-first.patch) and
  [broader Swing prototype diff](fades/02-swing-ownership-prototype.patch).
  Stage2 is relative to stage1; inspect that ordering before any later application.
- [Alpha reader/glow policies and gates](alpha-readers/REPORT.md), with six
  per-file diffs, source identities, raw repetitions and upstream-library review.
- [Geometry rejection and remaining options](geometry/README.md), including the
  explicit50px→33.33px counterexample and separately gated threat-cache hunk.
- [All selected research prototypes as a text diff](ALL_PROTOTYPES_FOR_REVIEW.diff.txt).
  This includes held prototypes; it is **not an approved application bundle**.
- [Candidate paths and baseline/candidate hashes](candidate-files.json) and
  [packet verification](verification.json).

## Validation and its limits

The full unchanged existing desktop suite passes **222/222 on the frozen baseline
and222/222 on the combined external prototypes**, with unchanged source identities
during each run. The combined selected set has nine source files and no GEO-01/02
geometric edits. This passing mock suite is not acceptance of held native cases.

Focused fade tests: five processes ×1,017 assertions=5,085;20 expected baseline
rejections,40 intentional ownership checks and five rejected regression mutations.
Existing cast/school13,942 and timer379 checks also pass in both variants.
Focused alpha tests: three processes ×619 assertions=1,857; public parity,
unknown-return, retry, stock-queue work, animation/recolor and pool reuse are
covered. Getter-call-denial observations remain readiness gates, not passed fixes.
See each raw report for repeated versus unique cases and scopes.

The rejected geometry experiment's earlier4,453 assertions per matched-epoch
sample remain as scoped historical evidence. Five countermodels expose its
unacceptable snapshot mismatch; those passing constrained cases do not override
the rejection. The selected Shared code contains only the independently gated
glow-cache change and a correction to a misleading secrecy comment.

The test overlay routes reads to frozen source and external candidates while
preserving logical chunk names. Its first version changed names and caused two
debug-hook work counters to read zero; the adapter was corrected and the full
baseline rerun passed. Original assertions were not weakened, and the initial
adapter result is preserved separately. This was a test-adapter error, not a
discovered addon failure.

All four Gethe branch pins were rechecked for this phase and remain unchanged;
current geometry contracts are recorded in [upstream.json](upstream.json).
Actual native build/frame, true secret/secure VM, pixels, taint and FPS acceptance
remain pending under the existing simulation-only instruction.

## Reproduce without applying

From the live addon root, these commands only operate on isolated copies/reports:

```powershell
python -B 'Stress test doc/fix-proposals/fades/verify.py'
python -B 'Stress test doc/fix-proposals/alpha-readers/run_tests.py'
python -B 'Stress test doc/fix-proposals/geometry/run_geometry.py'
python -B 'Stress test doc/fix-proposals/run_existing_overlay.py' baseline
python -B 'Stress test doc/fix-proposals/run_existing_overlay.py' candidate
python -B 'Stress test doc/fix-proposals/verify_packet.py'
```

Do not copy these candidates into the addon, run a sync script, or apply a patch
as part of this phase. A later application must first reconcile current source
hashes and the stated readiness gates, retain existing licenses/settings/features,
and preserve any newer user work.
